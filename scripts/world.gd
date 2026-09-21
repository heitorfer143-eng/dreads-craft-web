extends Node2D

const Items = preload("res://scripts/items.gd")
const TILE = 32
const WIDTH = 320
const HEIGHT = 96
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
		if x < 58:
			height = 35
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
	for x in range(62,WIDTH-5,11):
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
	for base in [110,215,294]:
		var ground = surfaces[base]
		for dx in range(-4,5):
			for y in range(ground-8,ground):
				cells[y][base+dx]=0
			cells[ground][base+dx]=3
			if abs(dx)==4:
				for y in range(ground-6,ground):
					cells[y][base+dx]=3
			if dx!=1:
				cells[ground-6][base+dx]=3
		cells[ground-1][base]=9
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
	# Minas abandonadas: corredores, vigas e pequenas câmaras.
	for center_x in [82,196,278]:
		var y=clampi(surfaces[center_x]+rng.randi_range(18,28),48,82)
		for x in range(center_x-16,center_x+17):
			for yy in range(y-3,y+2):
				if x>3 and x<WIDTH-3:
					cells[yy][x]=0
			if (x-center_x)%6==0:
				cells[y-3][x]=4
				cells[y-2][x]=4
				cells[y-1][x]=4
			cells[y+2][x]=8
	# Surface landmarks are scenery rather than solid block boxes.
	# Clear walkable village/ruin spaces; decorative structures are drawn separately below.
	for center_x in [40,118,238,292]:
		var ground=surfaces[center_x]
		for x in range(center_x-6,center_x+7):
			if x>1 and x<WIDTH-1:
				for y in range(maxi(0,ground-8),ground):
					if cells[y][x] in [3,4,5,8,9]:
						cells[y][x]=0

func generate_ores() -> void:
	var rng=RandomNumberGenerator.new()
	rng.seed=world_seed ^ 0x5F3759DF
	# Seeded connected clusters, with a stone buffer between different minerals.
	for ore in [6,7,14,15]:
		var attempts=int({6:180,7:100,14:24,15:5}[ore])
		for attempt in attempts:
			var cell=Vector2i(rng.randi_range(3,WIDTH-4),rng.randi_range(int({6:43,7:55,14:72,15:85}[ore]),HEIGHT-4))
			var target_size=rng.randi_range(5,11) if ore==6 else rng.randi_range(3,7) if ore==7 else rng.randi_range(3,5) if ore==14 else 1
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
				if count>=(18 if ore==14 else 1):
					break
				var point=Vector2i(x,y)
				if get_cell(point)!=3:
					continue
				var clear=true
				for offset in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
					if get_cell(point+offset) in [6,7,14,15]:
						clear=false
				if clear:
					cells[y][x]=ore
					count+=1

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
	# 2D landmarks: non-blocky silhouettes the player can walk through/around.
	for sx in [40,118,238,292]:
		if sx>=left-12 and sx<=right+12 and sx<surfaces.size():
			var gy=float(surfaces[sx]*TILE)
			var px=float(sx*TILE)
			var wall=Color("211b2a")
			var edge=Color("5b4967")
			var wood=Color("65422f")
			if sx==40:
				# Blacksmith hut
				draw_rect(Rect2(px-150,gy-150,300,150),wall)
				draw_colored_polygon(PackedVector2Array([Vector2(px-175,gy-150),Vector2(px,gy-250),Vector2(px+175,gy-150)]),Color("17131e"))
				draw_rect(Rect2(px-42,gy-88,84,88),Color("0b0910"))
				draw_rect(Rect2(px+75,gy-95,52,45),Color("d0733d"))
				draw_rect(Rect2(px+82,gy-88,38,31),Color("512b24"))
			elif sx==118:
				# Broken stone arch, scenery rather than a cube of tiles.
				draw_rect(Rect2(px-125,gy-170,38,170),edge)
				draw_rect(Rect2(px+87,gy-170,38,170),edge)
				draw_arc(Vector2(px,gy-168),106,PI,TAU,24,edge,32)
			elif sx==238:
				# Merchant tent
				draw_colored_polygon(PackedVector2Array([Vector2(px-145,gy),Vector2(px-105,gy-150),Vector2(px,gy-205),Vector2(px+105,gy-150),Vector2(px+145,gy)]),Color("3a2346"))
				draw_line(Vector2(px,gy-205),Vector2(px,gy),wood,8)
				draw_rect(Rect2(px-120,gy-18,240,18),Color("76523a"))
			elif sx==292:
				# Purity shrine
				draw_rect(Rect2(px-110,gy-150,220,150),Color("242335"))
				draw_colored_polygon(PackedVector2Array([Vector2(px-135,gy-150),Vector2(px,gy-235),Vector2(px+135,gy-150)]),Color("d5cfbd"))
				draw_rect(Rect2(px-34,gy-95,68,95),Color("11101a"))
				draw_line(Vector2(px,gy-205),Vector2(px,gy-165),Color("d2aa55"),5)
				draw_line(Vector2(px-16,gy-188),Vector2(px+16,gy-188),Color("d2aa55"),5)
	for y in range(top,bottom):
		for x in range(left,right):
			var id = get_cell(Vector2i(x,y))
			if id==0:
				continue
			var pos=Vector2(x,y)*TILE
			var texture: Texture2D = tile_textures.get(id)
			if texture:
				draw_texture_rect(texture,Rect2(pos,Vector2(TILE,TILE)),false)
			else:
				draw_rect(Rect2(pos,Vector2(TILE,TILE)),Items.COLORS.get(id,Color.GRAY))
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
