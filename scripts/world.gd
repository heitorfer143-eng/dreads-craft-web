extends Node2D

const Items = preload("res://scripts/items.gd")
const TILE = 32
const WIDTH = 320
const HEIGHT = 96
const VILLAGE_MIN_X = 4
const VILLAGE_MAX_X = 66
const SNOW_START_X = 230
var cells: Array = []
var surfaces: Array[int] = []
var rows: Dictionary = {}
var world_seed: int = 1
var camera: Camera2D
var dirty_rows: Dictionary = {}
var tile_textures: Dictionary = {}

func _ready() -> void:
	for id in Items.TILE_TEXTURES:
		tile_textures[id] = load(Items.TILE_TEXTURES[id])

func generate(seed_value: int) -> void:
	world_seed = seed_value
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
		var height = 35 + int(noise.get_noise_1d(x) * (6 if x < 100 else 13))
		if x < 70:
			height = 35
		elif x>=SNOW_START_X:
			height = 37 + int(noise.get_noise_1d(x*1.35)*6)
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
	for ore in [6,7,14,15,25]:
		var attempts=int({6:180,7:100,14:24,15:5,25:18}[ore])
		for attempt in attempts:
			var cell=Vector2i(rng.randi_range(3,WIDTH-4),rng.randi_range(int({6:43,7:55,14:72,15:85,25:76}[ore]),HEIGHT-4))
			var min_size=int({6:5,7:3,14:3,15:1,25:2}[ore])
			var max_size=int({6:11,7:7,14:5,15:1,25:4}[ore])
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
					if neighbor in [6,7,14,15,25] and neighbor!=ore:
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
				if count>=int({14:18,15:1,25:8}[ore]):
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
	var minimums={6:110,7:70,14:24,15:3,25:12}
	var min_depth={6:43,7:52,14:68,15:82,25:74}
	var rng=RandomNumberGenerator.new()
	rng.seed=world_seed ^ 0x2A7D91C3
	for ore in [6,7,14,15,25]:
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
				if neighbor in [6,7,14,15,25] and neighbor!=ore:
					clear=false
					break
			if not clear:
				continue
			cells[y][x]=ore
			count+=1
			# Coal/iron/diamond form small readable veins. Avarita stays extremely rare.
			if ore not in [15,25]:
				for offset in [Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT,Vector2i.UP]:
					if count>=int(minimums[ore]):
						break
					var p=Vector2i(x,y)+offset
					if p.x>2 and p.x<WIDTH-2 and p.y>surfaces[p.x]+8 and p.y<HEIGHT-2 and cells[p.y][p.x]==3 and rng.randf()<0.48:
						cells[p.y][p.x]=ore
						count+=1
	queue_redraw()

func is_village_protected(cell: Vector2i) -> bool:
	# The village is a safe/build-protected zone. Players can walk/interact,
	# but cannot mine or place blocks over/under its houses.
	return cell.x>=VILLAGE_MIN_X and cell.x<=VILLAGE_MAX_X

func is_snow_biome(cell_x: int) -> bool:
	return cell_x>=SNOW_START_X

func snow_spawn_cell() -> Vector2i:
	var x=282
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
	return get_cell(cell) not in [0,5,16]

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
				# Snow biome is rendered as a cold overlay on the same destructible terrain.
				if id in [1,2]:
					if y==surfaces[x]:
						draw_rect(Rect2(pos,Vector2(TILE,7)),Color("e8f1ffff"),true)
						draw_rect(Rect2(pos+Vector2(0,7),Vector2(TILE,TILE-7)),Color("9eb4c633"),true)
					else:
						draw_rect(Rect2(pos,Vector2(TILE,TILE)),Color("8ba7c522"),true)
				elif id==3:
					draw_rect(Rect2(pos,Vector2(TILE,TILE)),Color("7394bb28"),true)
				elif id in [4,5]:
					draw_rect(Rect2(pos,Vector2(TILE,TILE)),Color("dce8f51f"),true)
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
