extends Node2D

const Items = preload("res://scripts/items.gd")
const TILE = 32
const WIDTH = 320
const HEIGHT = 96
const VILLAGE_MIN_X = 4
const VILLAGE_MAX_X = 66
const SNOW_START_X = 190
const LAKE_MIN_CENTER_X = 120
const LAKE_MAX_CENTER_X = 150
var lake_center_x := 130
var lake_width := 24
var lake_depth := 8
var lake_start_x := 118
var lake_end_x := 142
var lake_water_y := 35
var lake_generated := false
var cells: Array = []
var surfaces: Array[int] = []
var rows: Dictionary = {}
var world_seed: int = 1
var camera: Camera2D
var dirty_rows: Dictionary = {}
var tile_textures: Dictionary = {}
var purity_realm := false

func _ready() -> void:
	for id in Items.TILE_TEXTURES:
		tile_textures[id] = load(Items.TILE_TEXTURES[id])

func generate(seed_value: int) -> void:
	world_seed = seed_value
	configure_lake(seed_value)
	var noise = FastNoiseLite.new()
	noise.seed = world_seed
	noise.frequency = 0.027
	cells.clear()
	surfaces.clear()
	for y in HEIGHT:
		var row = []
		row.resize(WIDTH)
		row.fill(0)
		cells.append(row)
	for x in WIDTH:
		var height=_natural_surface_height(x,noise)
		if not purity_realm and is_lake_zone(x):
			height=lake_water_y+lake_floor_depth(x)
		surfaces.append(height)
		for y in range(height, HEIGHT):
			var id = 1 if y == height else 2 if y < height+4 else 3
			cells[y][x] = id
		for layer in 2:
			var center = 58 + layer*18 + int(sin(x*0.065+layer)*4)
			for y in range(center-3,center+4):
				if x > 60 and x < WIDTH-3:
					cells[y][x] = 0
	# Trees are a separate pass: later terrain columns cannot overwrite foliage.
	for x in range(72,WIDTH-5,11):
		if is_lake_zone(x):
			continue
		var blocked_by_village=false
		for village_x in [18,34,50]:
			if abs(x-village_x)<=8:
				blocked_by_village=true
		if blocked_by_village:
			continue
		var top = surfaces[x]-6
		for y in range(top, surfaces[x]):
			cells[y][x] = 4
		for dx in range(-2,3):
			for dy in range(-2,3):
				if abs(dx)+abs(dy)<4 and cells[top+dy][x+dx]==0:
					cells[top+dy][x+dx]=5
	# Walkable sloping mine entrances connect the surface to the first cave.
	for entry in [76,170,265]:
		for dx in range(28):
			var x = entry+dx
			var bottom = mini(60, surfaces[entry]+dx)
			for y in range(bottom-3,bottom+1):
				cells[y][x]=0
	generate_structures()
	generate_ores()
	rebuild_collision()
	queue_redraw()

func generate_structures() -> void:
	var rng=RandomNumberGenerator.new()
	rng.seed=world_seed ^ 0x71A5C0DE
	# Cavernas orgânicas extras: bolsões conectados em profundidades variadas.
	for cave_index in range(22):
		var cx=rng.randi_range(30,WIDTH-20)
		var cy=rng.randi_range(48,HEIGHT-10)
		var radius=rng.randi_range(3,7)
		for step in range(rng.randi_range(3,7)):
			for y in range(cy-radius,cy+radius+1):
				for x in range(cx-radius*2,cx+radius*2+1):
					if x>2 and x<WIDTH-2 and y>surfaces[x]+6 and y<HEIGHT-2:
						var nx=float(x-cx)/float(radius*2)
						var ny=float(y-cy)/float(radius)
						if nx*nx+ny*ny < 1.0+rng.randf_range(-0.18,0.18):
							cells[y][x]=0
			cx=clampi(cx+rng.randi_range(-7,7),8,WIDTH-8)
			cy=clampi(cy+rng.randi_range(-3,4),45,HEIGHT-8)
	# Estruturas visíveis são apenas sprites; não geramos minas/ruínas de blocos.
	# Keep the image-based village completely clear of trees/blocks around each house.
	for center_x in [18,34,50,118,238,292]:
		var ground=surfaces[center_x]
		for x in range(center_x-6,center_x+7):
			if x>1 and x<WIDTH-1:
				for y in range(maxi(0,ground-8),ground):
					if cells[y][x] in [3,4,5,8,9]:
						cells[y][x]=0

func _natural_surface_height(x:int,noise:FastNoiseLite) -> int:
	var height=35+int(noise.get_noise_1d(x)*(6 if x<100 else 13))
	if x<70:
		height=35
	elif not purity_realm and x>=SNOW_START_X:
		height=37+int(noise.get_noise_1d(x*1.35)*6)
	return clampi(height,22,58)

func configure_lake(seed_value:int) -> void:
	if purity_realm:
		return
	var rng=RandomNumberGenerator.new()
	rng.seed=seed_value ^ 0x4C414B45
	var noise=FastNoiseLite.new()
	noise.seed=seed_value
	noise.frequency=0.027

	lake_width=rng.randi_range(20,28)
	lake_depth=rng.randi_range(7,11)

	# Choose a seeded low-slope stretch between the two mine entrances.
	# This keeps the water physically inside its banks instead of hanging in open air.
	var best_center=LAKE_MIN_CENTER_X
	var best_score=999999
	for attempt in range(16):
		var candidate=rng.randi_range(LAKE_MIN_CENTER_X,LAKE_MAX_CENTER_X)
		var start=clampi(candidate-int(lake_width/2),108,164-lake_width)
		var finish=start+lake_width
		var left_height=_natural_surface_height(start-1,noise)
		var right_height=_natural_surface_height(finish+1,noise)
		var center_height=_natural_surface_height(int((start+finish)/2),noise)
		var score=absi(left_height-right_height)*8+absi(center_height-left_height)+absi(center_height-right_height)
		if score<best_score:
			best_score=score
			best_center=int((start+finish)/2)

	lake_center_x=best_center
	lake_start_x=clampi(lake_center_x-int(lake_width/2),108,164-lake_width)
	lake_end_x=lake_start_x+lake_width
	lake_center_x=int((lake_start_x+lake_end_x)/2)
	var left_bank=_natural_surface_height(lake_start_x-1,noise)
	var right_bank=_natural_surface_height(lake_end_x+1,noise)
	lake_water_y=clampi(maxi(left_bank,right_bank)+1,26,56)
	lake_generated=true

func restore_lake_layout(center:int,width:int,depth:int) -> void:
	if purity_realm:
		return
	lake_width=clampi(width,20,28)
	lake_depth=clampi(depth,7,11)
	lake_center_x=clampi(center,LAKE_MIN_CENTER_X,LAKE_MAX_CENTER_X)
	lake_start_x=clampi(lake_center_x-int(lake_width/2),108,164-lake_width)
	lake_end_x=lake_start_x+lake_width
	lake_center_x=int((lake_start_x+lake_end_x)/2)
	lake_generated=true
	_anchor_lake_to_banks()

func _anchor_lake_to_banks() -> void:
	if surfaces.size()!=WIDTH:
		return
	var left_x=clampi(lake_start_x-1,0,WIDTH-1)
	var right_x=clampi(lake_end_x+1,0,WIDTH-1)
	var left_bank=int(surfaces[left_x])
	var right_bank=int(surfaces[right_x])
	# Larger Y means lower terrain. One tile below the lower bank guarantees
	# the water never renders above either shore.
	lake_water_y=clampi(maxi(left_bank,right_bank)+1,26,56)

func lake_floor_depth(x:int) -> int:
	if not is_lake_zone(x):
		return 0
	var half=maxf(1.0,float(lake_width)/2.0)
	var normalized=clampf(1.0-absf(float(x-lake_center_x))/half,0.0,1.0)
	var curve=sin(normalized*PI*0.5)
	var wobble=float(absi((x*37+world_seed*13)%5)-2)*0.22
	var depth=clampi(int(round(curve*float(lake_depth)+wobble)),0,lake_depth)
	if x==lake_center_x:
		depth=lake_depth
	return depth

func repair_lake_zone() -> void:
	if not lake_generated:
		configure_lake(world_seed)
	_anchor_lake_to_banks()
	for x in range(lake_start_x,lake_end_x+1):
		if x<0 or x>=surfaces.size():
			continue
		var ground=lake_water_y+lake_floor_depth(x)
		surfaces[x]=ground
		for y in range(maxi(0,lake_water_y-3),ground):
			cells[y][x]=0
		cells[ground][x]=1
		for y in range(ground+1,mini(ground+4,HEIGHT)):
			cells[y][x]=2
	rebuild_collision()
	queue_redraw()

func repair_village_zone() -> void:
	# Upgrade old saves to the new village layout too: flat ground and no trees/blocks over houses.
	for x in range(4,66):
		var ground=35
		if x>=surfaces.size():
			continue
		surfaces[x]=ground
		for y in range(0,ground):
			cells[y][x]=0
		cells[ground][x]=1
		for y in range(ground+1,mini(ground+4,HEIGHT)):
			cells[y][x]=2
		if ground+4<HEIGHT and cells[ground+4][x]==0:
			cells[ground+4][x]=3
	rebuild_collision()
	queue_redraw()

func generate_ores() -> void:
	var rng=RandomNumberGenerator.new()
	rng.seed=world_seed ^ 0x5F3759DF
	# Seeded connected clusters, with a stone buffer between different minerals.
	for ore in [6,7,14,15]:
		var attempts=int({6:180,7:100,14:24,15:5}[ore])
		for attempt in attempts:
			var cell=Vector2i(rng.randi_range(3,WIDTH-4),rng.randi_range(int({6:43,7:55,14:72,15:85}[ore]),HEIGHT-4))
			var min_size=int({6:5,7:3,14:3,15:1}[ore])
			var max_size=int({6:11,7:7,14:5,15:1}[ore])
			var target_size=rng.randi_range(min_size,max_size)
			var frontier: Array[Vector2i]=[cell]
			var visited: Dictionary={}
			var placed=0
			while not frontier.is_empty() and placed<target_size:
				var index=rng.randi_range(0,frontier.size()-1)
				var current=frontier[index]
				frontier.remove_at(index)
				if visited.has(current):
					continue
				visited[current]=true
				if current.x<2 or current.x>=WIDTH-2 or current.y<surfaces[current.x]+(7 if ore==6 else 15) or current.y>=HEIGHT-2:
					continue
				if cells[current.y][current.x]!=3:
					continue
				var mixed=false
				for offset in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
					var neighbor=get_cell(current+offset)
					if neighbor in [6,7,14,15] and neighbor!=ore:
						mixed=true
				if mixed:
					continue
				cells[current.y][current.x]=ore
				placed+=1
				for offset in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
					if not visited.has(current+offset):
						frontier.append(current+offset)

	for ore in [14,15]:
		var count=0
		for row in cells:
			count+=row.count(ore)
		for y in range(90,80,-1):
			for x in range(5,WIDTH-5,3):
				if count>=int({14:18,15:1}[ore]):
					break
				var point=Vector2i(x,y)
				if get_cell(point)!=3:
					continue
				var clear=true
				for offset in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
					if get_cell(point+offset) in [6,7,14,15,25]:
						clear=false
				if clear:
					cells[y][x]=ore
					count+=1
	ensure_ore_minimums()

func ensure_ore_minimums() -> void:
	# Keeps both new worlds and older saves populated with useful ore.
	# Only replaces deep stone, so caves/buildings/terrain remain untouched.
	var minimums={6:110,7:70,14:24,15:3}
	var min_depth={6:43,7:52,14:68,15:82}
	var rng=RandomNumberGenerator.new()
	rng.seed=world_seed ^ 0x2A7D91C3
	for ore in [6,7,14,15]:
		var count=0
		for row in cells:
			count+=row.count(ore)
		var attempts=0
		while count<int(minimums[ore]) and attempts<9000:
			attempts+=1
			var x=rng.randi_range(4,WIDTH-5)
			var y=rng.randi_range(int(min_depth[ore]),HEIGHT-3)
			if y<surfaces[x]+(6 if ore==6 else 11):
				continue
			if cells[y][x]!=3:
				continue
			var clear=true
			for offset in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
				var neighbor=get_cell(Vector2i(x,y)+offset)
				if neighbor in [6,7,14,15] and neighbor!=ore:
					clear=false
					break
			if not clear:
				continue
			cells[y][x]=ore
			count+=1
			# Coal/iron/diamond form small readable veins. Avarita stays extremely rare.
			if ore!=15:
				for offset in [Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT,Vector2i.UP]:
					if count>=int(minimums[ore]):
						break
					var p=Vector2i(x,y)+offset
					if p.x>2 and p.x<WIDTH-2 and p.y>surfaces[p.x]+8 and p.y<HEIGHT-2 and cells[p.y][p.x]==3 and rng.randf()<0.48:
						cells[p.y][p.x]=ore
						count+=1
	queue_redraw()

func remove_ore(ore_id:int) -> void:
	for y in range(cells.size()):
		for x in range(cells[y].size()):
			if int(cells[y][x])==ore_id:
				cells[y][x]=3
	rebuild_collision()
	queue_redraw()

func generate_purity_realm(seed_value:int) -> void:
	purity_realm=true
	world_seed=seed_value ^ 0x51A7F00D
	var noise=FastNoiseLite.new()
	noise.seed=world_seed
	noise.frequency=0.031
	cells.clear()
	surfaces.clear()
	for y in HEIGHT:
		var row=[]
		row.resize(WIDTH)
		row.fill(0)
		cells.append(row)

	for x in WIDTH:
		var height=33+int(noise.get_noise_1d(x)*7.0)
		surfaces.append(height)
		for y in range(height,HEIGHT):
			cells[y][x]=3

	# Crystalline caverns.
	var rng=RandomNumberGenerator.new()
	rng.seed=world_seed
	for cave_index in range(34):
		var cx=rng.randi_range(14,WIDTH-14)
		var cy=rng.randi_range(49,HEIGHT-9)
		var rx=rng.randi_range(4,9)
		var ry=rng.randi_range(2,5)
		for y in range(cy-ry,cy+ry+1):
			for x in range(cx-rx,cx+rx+1):
				if x<=2 or x>=WIDTH-2 or y<=surfaces[x]+7 or y>=HEIGHT-2:
					continue
				var nx=float(x-cx)/float(rx)
				var ny=float(y-cy)/float(ry)
				if nx*nx+ny*ny<=1.0:
					cells[y][x]=0

	# Soul Ore exists only in this unlocked realm.
	for vein in range(34):
		var x=rng.randi_range(12,WIDTH-12)
		var y=rng.randi_range(60,HEIGHT-5)
		var amount=rng.randi_range(2,5)
		var p=Vector2i(x,y)
		for step in range(amount):
			if p.x>3 and p.x<WIDTH-3 and p.y>surfaces[p.x]+12 and p.y<HEIGHT-3 and cells[p.y][p.x]==3:
				cells[p.y][p.x]=25
			p+= [Vector2i.RIGHT,Vector2i.LEFT,Vector2i.UP,Vector2i.DOWN][rng.randi_range(0,3)]

	# Return portal at realm spawn.
	var portal_x=8
	var portal_y=surfaces[portal_x]-1
	cells[portal_y][portal_x]=16
	rebuild_collision()
	queue_redraw()


func is_village_protected(cell: Vector2i) -> bool:
	# The village is a safe/build-protected zone. Players can walk/interact,
	# but cannot mine or place blocks over/under its houses.
	return cell.x>=VILLAGE_MIN_X and cell.x<=VILLAGE_MAX_X

func is_lake_zone(cell_x: int) -> bool:
	return not purity_realm and cell_x>=lake_start_x and cell_x<=lake_end_x

func lake_temple_position() -> Vector2:
	var floor_y=surfaces[lake_center_x] if lake_center_x>=0 and lake_center_x<surfaces.size() else lake_water_y+lake_depth
	return Vector2(lake_center_x*TILE+TILE/2.0,floor_y*TILE-34)

func lake_shore_spawn() -> Vector2:
	var x=maxi(VILLAGE_MAX_X+8,lake_start_x-3)
	return Vector2(x*TILE+TILE/2.0,surfaces[x]*TILE-2)

func is_near_lake_temple(pos:Vector2) -> bool:
	return is_lake_zone(int(pos.x/TILE)) and pos.distance_to(lake_temple_position())<118.0

func is_point_in_lake_water(pos:Vector2) -> bool:
	if purity_realm:
		return false
	var x=int(pos.x/TILE)
	if not is_lake_zone(x):
		return false
	var water_top=float(lake_water_y*TILE)
	var floor_y=float(surfaces[x]*TILE)
	return pos.y>=water_top-12.0 and pos.y<=floor_y+8.0

func lake_signature() -> String:
	return "%d:%d:%d:%d" % [lake_center_x,lake_width,lake_depth,lake_water_y]

func is_snow_biome(cell_x: int) -> bool:
	return cell_x>=SNOW_START_X

func snow_spawn_cell() -> Vector2i:
	# Keep the polar-bear encounter deep enough into the biome to feel earned,
	# while no longer hiding the entire snow region at the extreme edge of the map.
	var x=250
	return Vector2i(x,surfaces[x])


func get_cell(cell: Vector2i) -> int:
	if cell.x<0 or cell.x>=WIDTH or cell.y>=HEIGHT:
		return 3
	if cell.y<0:
		return 0
	return int(cells[cell.y][cell.x])

func set_cell(cell: Vector2i, id: int) -> void:
	if cell.x<0 or cell.x>=WIDTH or cell.y<0 or cell.y>=HEIGHT-1:
		return
	cells[cell.y][cell.x]=id
	dirty_rows[cell.y]=true
	queue_redraw()

func is_solid(cell: Vector2i) -> bool:
	# Terraria-style trees: wood and leaves remain mineable world cells, but never
	# become movement collision. Players can run through the whole tree.
	return get_cell(cell) not in [0,4,5,16]

func rebuild_collision() -> void:
	for body in rows.values():
		remove_child(body)
		body.queue_free()
	rows.clear()
	for y in HEIGHT:
		rebuild_row(y)

func rebuild_row(y: int) -> void:
	if rows.has(y):
		remove_child(rows[y])
		rows[y].queue_free()
	var body = StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	rows[y] = body
	var x = 0
	while x<WIDTH:
		if not is_solid(Vector2i(x,y)):
			x+=1
			continue
		var start=x
		while x<WIDTH and is_solid(Vector2i(x,y)):
			x+=1
		var shape = RectangleShape2D.new()
		shape.size = Vector2((x-start)*TILE,TILE)
		var collider = CollisionShape2D.new()
		collider.shape = shape
		collider.position = Vector2((start+x)*TILE/2.0,y*TILE+TILE/2.0)
		body.add_child(collider)

func _process(_delta: float) -> void:
	for y in dirty_rows:
		rebuild_row(y)
	dirty_rows.clear()
	if camera:
		queue_redraw()

func _draw() -> void:
	if cells.is_empty():
		return
	var center = camera.get_screen_center_position() if camera else Vector2(640,1000)
	var extent = get_viewport_rect().size/2.0+Vector2(64,64)
	var left = maxi(0,int((center.x-extent.x)/TILE))
	var right = mini(WIDTH,int((center.x+extent.x)/TILE)+1)
	var top = maxi(0,int((center.y-extent.y)/TILE))
	var bottom = mini(HEIGHT,int((center.y+extent.y)/TILE)+1)
	# The Lake of Shadows is drawn behind terrain so the player can wade through it.
	if not purity_realm:
		draw_lake(left,right)
	# Village buildings are image assets spawned by main.gd; no procedural houses are drawn here.
	for y in range(top,bottom):
		for x in range(left,right):
			var id = get_cell(Vector2i(x,y))
			if id==0:
				continue
			var pos=Vector2(x,y)*TILE
			var texture: Texture2D = tile_textures.get(id)
			if id==16 and texture:
				# Portal da Pureza uses the generated artwork and is intentionally much
				# larger than its logical one-cell interaction point.
				var portal_size=Vector2(TILE*4.0,TILE*4.0)
				var portal_pos=pos+Vector2(TILE*0.5-portal_size.x*0.5,TILE-portal_size.y)
				draw_texture_rect(texture,Rect2(portal_pos,portal_size),false)
			elif texture:
				draw_texture_rect(texture,Rect2(pos,Vector2(TILE,TILE)),false)
			else:
				draw_rect(Rect2(pos,Vector2(TILE,TILE)),Items.COLORS.get(id,Color.GRAY))
			if x>=SNOW_START_X:
				# Strong, unmistakable snow biome treatment. This is render-only, so old
				# saves instantly gain the biome without rewriting their terrain data.
				var deep_snow=x>=SNOW_START_X+22
				if id==1:
					draw_rect(Rect2(pos,Vector2(TILE,TILE)),Color("bcd6e86e" if deep_snow else "afc8df52"),true)
					if y==surfaces[x]:
						draw_rect(Rect2(pos,Vector2(TILE,10)),Color("f4fbffff"),true)
						draw_rect(Rect2(pos+Vector2(0,10),Vector2(TILE,4)),Color("c9e4f2dd"),true)
				elif id==2:
					draw_rect(Rect2(pos,Vector2(TILE,TILE)),Color("a9c5dc55" if deep_snow else "92abc544"),true)
					if y<=surfaces[x]+1:
						draw_rect(Rect2(pos,Vector2(TILE,5)),Color("e7f4fccc"),true)
				elif id==3:
					draw_rect(Rect2(pos,Vector2(TILE,TILE)),Color("7699c148" if deep_snow else "6f8eaf35"),true)
				elif id==4:
					draw_rect(Rect2(pos,Vector2(TILE,TILE)),Color("dcebf733"),true)
					draw_rect(Rect2(pos,Vector2(TILE,4)),Color("edf8ffbb"),true)
				elif id==5:
					draw_rect(Rect2(pos,Vector2(TILE,TILE)),Color("dcebf742"),true)
					draw_rect(Rect2(pos,Vector2(TILE,6)),Color("f3fbffd0"),true)
			if id==25:
				# Soul Ore emits a soft white-blue glow while keeping the pixel-art tile readable.
				draw_circle(pos+Vector2(TILE/2.0,TILE/2.0),18,Color(0.82,0.95,1.0,0.10))
				draw_circle(pos+Vector2(TILE/2.0,TILE/2.0),10,Color(0.95,0.99,1.0,0.13))
			if id==4:
				# Bark detail is drawn procedurally too, so generated trees can never become flat brown columns.
				draw_rect(Rect2(pos+Vector2(5,0),Vector2(3,TILE)),Color("a56b43"))
				draw_rect(Rect2(pos+Vector2(19,0),Vector2(4,TILE)),Color("3b241d"))
				draw_rect(Rect2(pos+Vector2(10,7),Vector2(7,3)),Color("2c1b18"))
				draw_rect(Rect2(pos+Vector2(22,21),Vector2(6,3)),Color("8a5637"))
			if id==1:
				# Regiões continuam reconhecíveis sem trocar a linguagem visual do bloco.
				var tint=Color("ffffff") if x<100 else Color("d8c0db") if x<220 else Color("d9e2ef")
				draw_rect(Rect2(pos,Vector2(TILE,TILE)),tint*Color(1,1,1,0.08))
	if not purity_realm:
		draw_surface_decor(left,right)


func draw_lake(left:int,right:int) -> void:
	var visible_left=maxi(left,lake_start_x-2)
	var visible_right=mini(right,lake_end_x+3)
	if visible_right<=visible_left:
		return
	var water_top=float(lake_water_y*TILE)
	var time=float(Time.get_ticks_msec())/1000.0
	for x in range(visible_left,visible_right):
		if not is_lake_zone(x):
			continue
		var px=float(x*TILE)
		var floor_y=float(surfaces[x]*TILE)
		var depth=maxf(0.0,floor_y-water_top)
		if depth<=0:
			continue
		draw_rect(Rect2(px,water_top,TILE,depth),Color("172846c8"))
		draw_rect(Rect2(px,water_top,TILE,4),Color("7b99c9dd"))
		var wave_y=water_top+6.0+sin(time*2.1+float(x)*0.8)*2.0
		draw_line(Vector2(px+3,wave_y),Vector2(px+TILE-4,wave_y),Color("9bb6dd77"),2)
	for x in [lake_start_x+3,lake_start_x+7,lake_end_x-7,lake_end_x-3]:
		if x>=visible_left and x<visible_right:
			var px=float(x*TILE+16)
			draw_line(Vector2(px,water_top+18),Vector2(px-3,water_top-24),Color("1c271f"),4)
			draw_line(Vector2(px+5,water_top+16),Vector2(px+10,water_top-13),Color("334037"),3)
	if lake_center_x>=visible_left and lake_center_x<visible_right:
		var temple=lake_temple_position()
		var glow=Color("a05cff")
		draw_rect(Rect2(temple.x-120,temple.y-88,240,88),Color("28283a"))
		draw_rect(Rect2(temple.x-145,temple.y-100,38,100),Color("343548"))
		draw_rect(Rect2(temple.x+107,temple.y-100,38,100),Color("343548"))
		draw_rect(Rect2(temple.x-152,temple.y-108,304,12),Color("4b3b66"))
		draw_rect(Rect2(temple.x-48,temple.y-68,96,68),Color("141522"))
		draw_rect(Rect2(temple.x-36,temple.y-56,72,56),Color("0b0d16"))
		draw_rect(Rect2(temple.x-7,temple.y-48,14,34),glow)
		draw_polygon(PackedVector2Array([Vector2(temple.x,temple.y-96),Vector2(temple.x-15,temple.y-75),Vector2(temple.x,temple.y-63),Vector2(temple.x+15,temple.y-75)]),PackedColorArray([glow,glow,glow,glow]))
		draw_string(ThemeDB.fallback_font,Vector2(temple.x-94,temple.y-114),"TEMPLO SUBMERSO",HORIZONTAL_ALIGNMENT_CENTER,188,11,Color("b9a2d9"))

func draw_surface_decor(left:int,right:int) -> void:
	if purity_realm or surfaces.is_empty():
		return
	for x in range(maxi(left,VILLAGE_MAX_X+7),mini(right,WIDTH-1)):
		if x<0 or x>=surfaces.size():
			continue
		if is_lake_zone(x):
			continue
		var ground_y=surfaces[x]*TILE
		# Do not paint decor over generated tree trunks/canopies.
		if get_cell(Vector2i(x,surfaces[x]-1)) in [4,5]:
			continue
		var code=absi((x*73+world_seed*19)%101)
		var base=Vector2(x*TILE+TILE/2.0,ground_y)
		if code%47==0:
			# Tiny ruined roadside arch / broken masonry.
			draw_rect(Rect2(base+Vector2(-17,-28),Vector2(7,28)),Color("3b3742"))
			draw_rect(Rect2(base+Vector2(10,-20),Vector2(7,20)),Color("45414c"))
			draw_rect(Rect2(base+Vector2(-17,-29),Vector2(34,6)),Color("5d5662"))
		elif code%37==0:
			# Fallen log: purely decorative, no physics body.
			draw_rect(Rect2(base+Vector2(-18,-8),Vector2(36,8)),Color("4c3028"))
			draw_rect(Rect2(base+Vector2(-14,-6),Vector2(27,3)),Color("81543a"))
			draw_circle(base+Vector2(18,-4),5,Color("2b1c1b"))
		elif code%29==0:
			# Rock cluster.
			draw_circle(base+Vector2(-7,-5),7,Color("4b4a55"))
			draw_circle(base+Vector2(5,-4),9,Color("5a5964"))
			draw_rect(Rect2(base+Vector2(-12,-3),Vector2(24,3)),Color("33323b"))
		elif code%23==0:
			# Dark shrub / small flower patch.
			draw_line(base+Vector2(0,-2),base+Vector2(0,-17),Color("40513e"),3)
			draw_line(base+Vector2(0,-10),base+Vector2(-8,-15),Color("40513e"),2)
			draw_line(base+Vector2(0,-9),base+Vector2(8,-14),Color("40513e"),2)
			var bloom=Color("b690c5") if x<SNOW_START_X else Color("d9edf8")
			draw_circle(base+Vector2(-8,-16),3,bloom)
			draw_circle(base+Vector2(8,-15),3,bloom)
