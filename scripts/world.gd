extends Node2D

const Items = preload("res://scripts/items.gd")
const DungeonSystem = preload("res://scripts/dungeon_system.gd")
const TILE = 32
const WIDTH = 640
const HEIGHT = 96
const STREAM_CHUNK = 64
const MAX_STREAM_WIDTH = WIDTH
const WORLD_MIN_X = 0
const WORLD_MAX_X = WIDTH*TILE
const WORLD_MIN_Y = 0
const WORLD_MAX_Y = HEIGHT*TILE
const VILLAGE_MIN_X = 4
const VILLAGE_MAX_X = 66
const SNOW_START_X = 190
const SNOW_END_X = 292
const LAKE_MIN_CENTER_X = 120
const LAKE_MAX_CENTER_X = 150
var lake_center_x := 130
var lake_width := 48
var lake_depth := 16
var lake_start_x := 106
var lake_end_x := 154
var lake_water_y := 35
var lake_generated := false
var desert_start_x := 350
var desert_end_x := 500
var cells: Array = []
var surfaces: Array[int] = []
var rows: Dictionary = {}
var world_seed: int = 1
var camera: Camera2D
var dirty_rows: Dictionary = {}
var tile_textures: Dictionary = {}
var decor_atlas: Texture2D
var desert_decor: Dictionary = {}
const DECOR_CELL = Vector2(48,32)
const DECOR_INDEX = {
	"tree":0, "pine":1, "shrub":2, "flowers":3, "fence":4,
	"lampadao":5, "poste":6, "banner_red":7, "sign":8, "bench":9,
	"well":10, "crates":11, "barrels":12, "vase":13, "plants":14,
	"ivy":15, "lantern":16, "notice":17, "small_crate":18, "log":19,
	"stump":20, "hay_pile":21, "hay_bale":22, "white_flower":23, "tall_grass":24
}
const DECOR_ROLE_SCALE = {
	"tree":1.90,"pine":1.82,"shrub":0.86,"flowers":0.74,"fence":0.92,
	"lampadao":1.05,"poste":1.02,"banner_red":1.00,"sign":0.96,"bench":1.16,
	"well":1.22,"crates":0.94,"barrels":0.90,"vase":0.72,"plants":0.78,
	"ivy":0.86,"lantern":0.82,"notice":0.96,"small_crate":0.72,"log":0.94,
	"stump":0.86,"hay_pile":0.94,"hay_bale":0.98,"white_flower":0.70,"tall_grass":0.80
}
const LAKE_TEMPLE_SIZE = Vector2(420,220)
const LAKE_TEMPLE_DOOR_SIZE = Vector2(96,132)
var purity_realm := false
var dungeons:Array=[]
var dungeon_chests:Array=[]
var dungeon_secret_cells:Dictionary={}
var chest_visual_tiers:Dictionary={}
var chest_open_targets:Dictionary={}
var chest_open_amount:Dictionary={}

func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	for id in Items.TILE_TEXTURES:
		tile_textures[id] = load(Items.TILE_TEXTURES[id])
	decor_atlas=load("res://assets/decor/decor_atlas.png")
	for key in ["cactus","dry_bush","bones","desert_rock"]:
		var path="res://assets/decor/desert_"+key+".svg"
		if ResourceLoader.exists(path):
			desert_decor[key]=load(path)

func configure_biomes(seed_value:int) -> void:
	var shift=absi(seed_value)%46
	desert_start_x=330+shift
	desert_end_x=mini(WIDTH-70,desert_start_x+150)

func desert_strength(x:int) -> float:
	var transition=14.0
	if x<desert_start_x-transition or x>desert_end_x+transition:
		return 0.0
	if x<desert_start_x:
		return clampf((float(x)-float(desert_start_x)+transition)/transition,0.0,1.0)
	if x<=desert_end_x:
		return 1.0
	return clampf((float(desert_end_x)+transition-float(x))/transition,0.0,1.0)

func is_snow_biome(x:int) -> bool:
	return x>=SNOW_START_X and x<=SNOW_END_X

func is_desert_biome(x:int) -> bool:
	return desert_strength(x)>=0.62

func biome_at(x:int) -> String:
	if is_snow_biome(x):
		return "snow"
	var strength=desert_strength(x)
	if strength>=0.62:
		return "desert"
	if strength>0.0:
		return "desert_transition"
	return "forest"

func desert_center_cell() -> int:
	return int((desert_start_x+desert_end_x)/2)

func _uses_sand_surface(x:int) -> bool:
	var strength=desert_strength(x)
	if strength<=0.0:
		return false
	if strength>=0.98:
		return true
	var roll=absi((x*92821)^(world_seed*68917))%100
	return roll<int(strength*100.0)

func generate(seed_value: int) -> void:
	world_seed = seed_value
	configure_biomes(seed_value)
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
		var sandy=not purity_realm and _uses_sand_surface(x) and not is_lake_zone(x)
		for y in range(height, HEIGHT):
			var id = (29 if y==height else 30 if y<height+5 else 3) if sandy else (1 if y==height else 2 if y<height+4 else 3)
			cells[y][x] = id
		for layer in 2:
			var center = 58 + layer*18 + int(sin(x*0.065+layer)*4)
			for y in range(center-3,center+4):
				if x > 60 and x < WIDTH-3:
					cells[y][x] = 0
	# Trees are a separate pass: later terrain columns cannot overwrite foliage.
	for x in range(72,WIDTH-5,11):
		if is_lake_zone(x) or desert_strength(x)>0.28:
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
	generate_dungeons()
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


func _cell_key(cell:Vector2i) -> String:
	return "%d,%d" % [cell.x,cell.y]

func _safe_set(cell:Vector2i,id:int) -> void:
	if cell.x<1 or cell.x>=WIDTH-1 or cell.y<1 or cell.y>=HEIGHT-1:
		return
	cells[cell.y][cell.x]=id

func _carve_room(rect:Rect2i,wall_id:int=3,floor_id:int=3) -> void:
	for y in range(rect.position.y,rect.end.y):
		for x in range(rect.position.x,rect.end.x):
			if x<=1 or x>=WIDTH-1 or y<=1 or y>=HEIGHT-1:
				continue
			var border=x==rect.position.x or x==rect.end.x-1 or y==rect.position.y or y==rect.end.y-1
			cells[y][x]=wall_id if border else 0
	for x in range(rect.position.x,rect.end.x):
		_safe_set(Vector2i(x,rect.end.y-1),floor_id)

func _carve_corridor(a:Vector2i,b:Vector2i,height:int=3) -> void:
	var x=a.x
	var y=a.y
	var step_x=1 if b.x>=a.x else -1
	while x!=b.x:
		for dy in range(height):
			_safe_set(Vector2i(x,y-dy),0)
		x+=step_x
	while y!=b.y:
		for dy in range(height):
			_safe_set(Vector2i(x,y-dy),0)
		y+=1 if b.y>y else -1
	for dy in range(height):
		_safe_set(Vector2i(x,y-dy),0)

func _register_dungeon_chest(cell:Vector2i,dungeon_id:String,kind:String,tier:String,salt:int) -> void:
	_safe_set(cell,28)
	dungeon_chests.append({
		"cell":cell,
		"dungeon_id":dungeon_id,
		"kind":kind,
		"tier":tier,
		"seed":world_seed ^ salt ^ cell.x*92821 ^ cell.y*68917
	})
	chest_visual_tiers[_cell_key(cell)]=tier

func _register_secret_wall(cell:Vector2i) -> void:
	dungeon_secret_cells[_cell_key(cell)]=true

func _generate_crypt(rng:RandomNumberGenerator) -> void:
	var x=302+rng.randi_range(0,8)
	var y=64+rng.randi_range(0,4)
	var id="crypt_01"
	var room_a=Rect2i(x,y,9,7)
	var room_b=Rect2i(x+11,y-3,10,9)
	var room_c=Rect2i(x+23,y,10,8)
	var secret=Rect2i(x+23,y+9,9,6)
	_carve_room(room_a,3,3)
	_carve_room(room_b,3,3)
	_carve_room(room_c,3,3)
	_carve_room(secret,3,3)
	_carve_corridor(Vector2i(room_a.end.x-2,room_a.end.y-2),Vector2i(room_b.position.x+1,room_b.end.y-2),3)
	_carve_corridor(Vector2i(room_b.end.x-2,room_b.end.y-2),Vector2i(room_c.position.x+1,room_c.end.y-2),3)
	# Sloped mine-like entrance from the surface into the first crypt room.
	var entry_x=x+2
	var surface_y=surfaces[entry_x]-1
	for step in range(maxi(1,y-surface_y+3)):
		var px=entry_x+int(step/3)
		var py=surface_y+step
		if px>=room_a.position.x+3:
			break
		for dy in range(3):
			_safe_set(Vector2i(px,py-dy),0)
	# The secret room remains sealed behind ordinary breakable stone.
	for sx in range(secret.position.x+2,secret.end.x-2):
		_register_secret_wall(Vector2i(sx,secret.position.y))
	_register_dungeon_chest(Vector2i(room_a.position.x+2,room_a.end.y-2),id,"crypt","common",101)
	_register_dungeon_chest(Vector2i(room_b.position.x+5,room_b.end.y-2),id,"crypt","dungeon",102)
	_register_dungeon_chest(Vector2i(secret.position.x+4,secret.end.y-2),id,"crypt","rare",103)
	_register_dungeon_chest(Vector2i(room_c.position.x+6,room_c.end.y-2),id,"crypt","boss",104)
	dungeons.append({
		"id":id,"kind":"crypt","rect":Rect2i(x-2,y-5,36,22),
		"center":Vector2i(room_b.position.x+5,room_b.position.y+4),
		"mob_spawns":[Vector2i(room_a.position.x+5,room_a.end.y-2),Vector2i(room_b.position.x+3,room_b.end.y-2)],
		"mob_kinds":["corrupted_skeleton","dark_slime"],
		"miniboss":Vector2i(room_c.position.x+4,room_c.end.y-2),
		"boss_chest":Vector2i(room_c.position.x+6,room_c.end.y-2)
	})

func _generate_tower(rng:RandomNumberGenerator) -> void:
	var x=548+rng.randi_range(0,22)
	var center=x+7
	var ground=surfaces[center]
	var top=maxi(7,ground-18)
	var id="tower_01"
	# Clear the tower silhouette, then build side walls and broken floors.
	for tx in range(x,x+15):
		for ty in range(top,ground):
			_safe_set(Vector2i(tx,ty),0)
	for ty in range(top,ground+1):
		_safe_set(Vector2i(x,ty),3)
		_safe_set(Vector2i(x+14,ty),3)
	for tx in range(x,x+15):
		_safe_set(Vector2i(tx,ground),3)
	for floor_y in [ground-5,ground-10,ground-15]:
		for tx in range(x+1,x+14):
			if tx not in [x+4+(floor_y%2),x+5+(floor_y%2)]:
				_safe_set(Vector2i(tx,floor_y),8 if floor_y==ground-10 else 3)
	# Broken crenellations.
	for tx in range(x,x+15,2):
		_safe_set(Vector2i(tx,top),3)
	# Small secret basement under the tower.
	var secret=Rect2i(x+7,ground+2,7,6)
	_carve_room(secret,3,3)
	for sy in range(secret.position.y+2,secret.end.y-1):
		_register_secret_wall(Vector2i(secret.position.x,sy))
	_register_dungeon_chest(Vector2i(x+3,ground-1),id,"tower","common",201)
	_register_dungeon_chest(Vector2i(x+9,ground-11),id,"tower","dungeon",202)
	_register_dungeon_chest(Vector2i(secret.position.x+3,secret.end.y-2),id,"tower","rare",203)
	_register_dungeon_chest(Vector2i(x+7,ground-16),id,"tower","boss",204)
	dungeons.append({
		"id":id,"kind":"tower","rect":Rect2i(x-2,top-2,19,ground-top+11),
		"center":Vector2i(center,ground-8),
		"mob_spawns":[Vector2i(x+4,ground-1),Vector2i(x+10,ground-6)],
		"mob_kinds":["corrupted_skeleton","wolf"],
		"miniboss":Vector2i(x+10,ground-1),
		"boss_chest":Vector2i(x+7,ground-16)
	})

func _generate_desert_ruin(rng:RandomNumberGenerator) -> void:
	var center=clampi(desert_center_cell()+rng.randi_range(-12,12),desert_start_x+18,desert_end_x-18)
	var x=center-10
	var ground=surfaces[center]
	var top=maxi(8,ground-9)
	var id="desert_ruin_01"
	# Flatten just the ruin footprint and build a worked-sandstone temple shell.
	for tx in range(x,x+21):
		surfaces[tx]=ground
		for ty in range(top,ground):
			_safe_set(Vector2i(tx,ty),0)
		_safe_set(Vector2i(tx,ground),30)
	for ty in range(top+2,ground):
		_safe_set(Vector2i(x,ty),31)
		_safe_set(Vector2i(x+20,ty),31)
	for tx in range(x,x+21):
		if tx not in [center-2,center-1,center,center+1,center+2]:
			_safe_set(Vector2i(tx,top+2),31)
	# Pillars and broken upper silhouette.
	for px in [x+4,x+8,x+12,x+16]:
		for ty in range(top+3,ground):
			if ty%5!=0:
				_safe_set(Vector2i(px,ty),31)
	# Basement secret chamber.
	var basement=Rect2i(x+2,ground+3,9,7)
	_carve_room(basement,30,30)
	for sx in range(basement.position.x+2,basement.end.x-2):
		_register_secret_wall(Vector2i(sx,basement.position.y))
	_register_dungeon_chest(Vector2i(x+3,ground-1),id,"desert_ruin","common",301)
	_register_dungeon_chest(Vector2i(x+15,ground-1),id,"desert_ruin","dungeon",302)
	_register_dungeon_chest(Vector2i(basement.position.x+4,basement.end.y-2),id,"desert_ruin","rare",303)
	_register_dungeon_chest(Vector2i(center,ground-1),id,"desert_ruin","boss",304)
	dungeons.append({
		"id":id,"kind":"desert_ruin","rect":Rect2i(x-2,top,25,ground-top+12),
		"center":Vector2i(center,ground-4),
		"mob_spawns":[Vector2i(x+5,ground-1),Vector2i(x+16,ground-1)],
		"mob_kinds":["dark_slime","corrupted_skeleton"],
		"miniboss":Vector2i(center+5,ground-1),
		"boss_chest":Vector2i(center,ground-1)
	})

func generate_dungeons() -> void:
	if purity_realm or surfaces.size()<WIDTH:
		return
	dungeons.clear()
	dungeon_chests.clear()
	dungeon_secret_cells.clear()
	chest_visual_tiers.clear()
	var rng=RandomNumberGenerator.new()
	rng.seed=world_seed ^ 0x44554E47
	_generate_crypt(rng)
	_generate_tower(rng)
	_generate_desert_ruin(rng)

func repair_dungeons() -> void:
	# Used only when loading worlds created before dungeons existed.
	generate_dungeons()
	rebuild_collision()
	queue_redraw()

func dungeon_at_cell(cell:Vector2i) -> Dictionary:
	for dungeon in dungeons:
		var rect:Rect2i=dungeon.get("rect",Rect2i())
		if rect.grow(3).has_point(cell):
			return dungeon
	return {}

func dungeon_signature() -> String:
	var parts:Array[String]=[]
	for dungeon in dungeons:
		var center:Vector2i=dungeon.get("center",Vector2i.ZERO)
		parts.append("%s:%d:%d" % [str(dungeon.get("kind","")),center.x,center.y])
	return "|".join(parts)

func set_chest_visual_tier(cell:Vector2i,tier:String) -> void:
	chest_visual_tiers[_cell_key(cell)]=tier
	queue_redraw()

func set_chest_open(cell:Vector2i,opened:bool) -> void:
	var key=_cell_key(cell)
	chest_open_targets[key]=opened
	if not chest_open_amount.has(key):
		chest_open_amount[key]=0.0
	queue_redraw()

func chest_open_value(cell:Vector2i) -> float:
	return float(chest_open_amount.get(_cell_key(cell),0.0))

func world_width() -> int:
	return surfaces.size()

func ensure_generated_to(target_x:int) -> void:
	if purity_realm or cells.is_empty() or target_x<surfaces.size()-32:
		return
	var wanted=clampi(int(ceil(float(target_x+1)/float(STREAM_CHUNK)))*STREAM_CHUNK,WIDTH,MAX_STREAM_WIDTH)
	if wanted<=surfaces.size():
		return
	var old_width=surfaces.size()
	for y in range(cells.size()):
		var row=cells[y]
		row.resize(wanted)
		for x in range(old_width,wanted):
			row[x]=0
		cells[y]=row
	var noise=FastNoiseLite.new()
	noise.seed=world_seed
	noise.frequency=0.027
	for x in range(old_width,wanted):
		var height=_natural_surface_height(x,noise)
		surfaces.append(height)
		var sandy=_uses_sand_surface(x)
		for y in range(height,HEIGHT):
			cells[y][x]=(29 if y==height else 30 if y<height+5 else 3) if sandy else (1 if y==height else 2 if y<height+4 else 3)
		# Continue the two long cave bands used by the original generator.
		for layer in 2:
			var center=58+layer*18+int(sin(x*0.065+layer)*4)
			for cy in range(center-3,center+4):
				if cy>height+5 and cy<HEIGHT:
					cells[cy][x]=0
		# Deterministic ore field: every client with the same seed gets the same new chunks.
		for y in range(height+7,HEIGHT-2):
			if cells[y][x]!=3:
				continue
			var h=absi((x*73856093) ^ (y*19349663) ^ (world_seed*83492791))
			if y>=85 and h%4093==0:
				cells[y][x]=15
			elif y>=70 and h%521<3:
				cells[y][x]=14
			elif y>=54 and h%173<4:
				cells[y][x]=7
			elif y>=45 and h%109<6:
				cells[y][x]=6
	# Continue surface trees without touching the protected village/lake from the original map.
	for x in range(maxi(72,old_width),wanted):
		if (x-72)%11!=0 or desert_strength(x)>0.28:
			continue
		var top=surfaces[x]-6
		for y in range(maxi(0,top),surfaces[x]):
			if cells[y][x]==0:
				cells[y][x]=4
		for dx in range(-2,3):
			for dy in range(-2,3):
				var tx=x+dx
				var ty=top+dy
				if tx>=old_width and tx<wanted and ty>=0 and ty<HEIGHT and abs(dx)+abs(dy)<4 and cells[ty][tx]==0:
					cells[ty][tx]=5
	for y in range(HEIGHT):
		dirty_rows[y]=true
	queue_redraw()

func _natural_surface_height(x:int,noise:FastNoiseLite) -> int:
	var height=35+int(noise.get_noise_1d(x)*(6 if x<100 else 13))
	if x<70:
		height=35
	elif not purity_realm and is_snow_biome(x):
		height=37+int(noise.get_noise_1d(x*1.35)*6)
	if not purity_realm:
		var strength=desert_strength(x)
		if strength>0.0:
			var dune_height=37+int(noise.get_noise_1d(x*0.72)*3.0)+int(sin(float(x)*0.085)*2.0)
			height=int(round(lerpf(float(height),float(dune_height),strength)))
	return clampi(height,22,58)

func configure_lake(seed_value:int) -> void:
	if purity_realm:
		return
	var rng=RandomNumberGenerator.new()
	rng.seed=seed_value ^ 0x4C414B45
	var noise=FastNoiseLite.new()
	noise.seed=seed_value
	noise.frequency=0.027

	lake_width=rng.randi_range(44,52)
	lake_depth=rng.randi_range(14,18)

	# Choose a seeded low-slope stretch between the two mine entrances.
	# This keeps the water physically inside its banks instead of hanging in open air.
	var best_center=LAKE_MIN_CENTER_X
	var best_score=999999
	for attempt in range(16):
		var candidate=rng.randi_range(LAKE_MIN_CENTER_X,LAKE_MAX_CENTER_X)
		var start=clampi(candidate-int(lake_width/2),100,174-lake_width)
		var finish=start+lake_width
		var left_height=_natural_surface_height(start-1,noise)
		var right_height=_natural_surface_height(finish+1,noise)
		var center_height=_natural_surface_height(int((start+finish)/2),noise)
		var score=absi(left_height-right_height)*8+absi(center_height-left_height)+absi(center_height-right_height)
		if score<best_score:
			best_score=score
			best_center=int((start+finish)/2)

	lake_center_x=best_center
	lake_start_x=clampi(lake_center_x-int(lake_width/2),100,174-lake_width)
	lake_end_x=lake_start_x+lake_width
	lake_center_x=int((lake_start_x+lake_end_x)/2)
	var left_bank=_natural_surface_height(lake_start_x-1,noise)
	var right_bank=_natural_surface_height(lake_end_x+1,noise)
	lake_water_y=clampi(maxi(left_bank,right_bank)+3,28,58)
	lake_generated=true

func restore_lake_layout(center:int,width:int,depth:int) -> void:
	if purity_realm:
		return
	lake_width=clampi(width,44,52)
	lake_depth=clampi(depth,14,18)
	lake_center_x=clampi(center,LAKE_MIN_CENTER_X,LAKE_MAX_CENTER_X)
	lake_start_x=clampi(lake_center_x-int(lake_width/2),100,174-lake_width)
	lake_end_x=lake_start_x+lake_width
	lake_center_x=int((lake_start_x+lake_end_x)/2)
	lake_generated=true
	_anchor_lake_to_banks()

func _anchor_lake_to_banks() -> void:
	if surfaces.size()<WIDTH:
		return
	var left_x=clampi(lake_start_x-1,0,WIDTH-1)
	var right_x=clampi(lake_end_x+1,0,WIDTH-1)
	var left_bank=int(surfaces[left_x])
	var right_bank=int(surfaces[right_x])
	# Larger Y means lower terrain. One tile below the lower bank guarantees
	# the water never renders above either shore.
	lake_water_y=clampi(maxi(left_bank,right_bank)+3,28,58)

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
	# This point represents the BOTTOM of the submerged temple. Keeping it on the
	# exact terrain surface prevents the structure from floating above the lake bed.
	return Vector2(lake_center_x*TILE+TILE/2.0,floor_y*TILE)

func lake_shore_spawn() -> Vector2:
	var x=maxi(VILLAGE_MAX_X+8,lake_start_x-3)
	return Vector2(x*TILE+TILE/2.0,surfaces[x]*TILE-2)

func is_near_lake_temple(pos:Vector2) -> bool:
	return is_lake_zone(int(pos.x/TILE)) and pos.distance_to(lake_temple_position())<190.0

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

func snow_spawn_cell() -> Vector2i:
	var x=int((SNOW_START_X+SNOW_END_X)/2)
	return Vector2i(x,surfaces[x])


func get_cell(cell: Vector2i) -> int:
	if cell.x<0 or cell.x>=surfaces.size() or cell.y>=HEIGHT:
		return 3
	if cell.y<0:
		return 0
	return int(cells[cell.y][cell.x])

func set_cell(cell: Vector2i, id: int) -> void:
	if cell.x>=surfaces.size() and not purity_realm:
		ensure_generated_to(cell.x+STREAM_CHUNK)
	if cell.x<0 or cell.x>=surfaces.size() or cell.y<0 or cell.y>=HEIGHT-1:
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
	var width=surfaces.size()
	var x = 0
	while x<width:
		if not is_solid(Vector2i(x,y)):
			x+=1
			continue
		var start=x
		while x<width and is_solid(Vector2i(x,y)):
			x+=1
		var shape = RectangleShape2D.new()
		shape.size = Vector2((x-start)*TILE,TILE)
		var collider = CollisionShape2D.new()
		collider.shape = shape
		collider.position = Vector2((start+x)*TILE/2.0,y*TILE+TILE/2.0)
		body.add_child(collider)

func _process(_delta: float) -> void:
	var chest_anim_changed=false
	for key in chest_open_targets.keys():
		var target=1.0 if bool(chest_open_targets[key]) else 0.0
		var current=float(chest_open_amount.get(key,0.0))
		var updated=move_toward(current,target,_delta*7.0)
		if not is_equal_approx(updated,current):
			chest_open_amount[key]=updated
			chest_anim_changed=true
	if chest_anim_changed:
		queue_redraw()
	if camera and not purity_realm and not surfaces.is_empty():
		var ahead=int((camera.get_screen_center_position().x+get_viewport_rect().size.x)/TILE)+72
		ensure_generated_to(ahead)
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
	var right = mini(surfaces.size(),int((center.x+extent.x)/TILE)+1)
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
			elif id==9:
				# Workbench is rendered procedurally so the placed object looks like a
				# proper medieval crafting table instead of the old flat pedestal tile.
				draw_rect(Rect2(pos+Vector2(1,5),Vector2(30,8)),Color("2a1b19"))
				draw_rect(Rect2(pos+Vector2(2,4),Vector2(28,5)),Color("9a673f"))
				draw_rect(Rect2(pos+Vector2(4,5),Vector2(24,2)),Color("d0a05e"))
				draw_rect(Rect2(pos+Vector2(5,13),Vector2(5,18)),Color("4a2e27"))
				draw_rect(Rect2(pos+Vector2(22,13),Vector2(5,18)),Color("4a2e27"))
				draw_rect(Rect2(pos+Vector2(9,15),Vector2(14,4)),Color("684231"))
				draw_rect(Rect2(pos+Vector2(11,20),Vector2(10,3)),Color("302126"))
				draw_rect(Rect2(pos+Vector2(15,10),Vector2(3,8)),Color("b7b3b5"))
				draw_rect(Rect2(pos+Vector2(12,13),Vector2(9,3)),Color("6b6670"))
				draw_rect(Rect2(pos+Vector2(4,29),Vector2(7,3)),Color("21171a"))
				draw_rect(Rect2(pos+Vector2(21,29),Vector2(7,3)),Color("21171a"))
			elif id==28:
				var chest_cell=Vector2i(x,y)
				var chest_key=_cell_key(chest_cell)
				var tier=str(chest_visual_tiers.get(chest_key,"common"))
				var accent=Color("d0934d")
				if tier=="rare": accent=Color("6ca8ff")
				elif tier=="dungeon": accent=Color("b06bd0")
				elif tier=="boss": accent=Color("f0b85f")
				var open_amount=chest_open_value(chest_cell)
				var lid_offset=-6.0*open_amount
				# Animated medieval chest. Dungeon tiers get a distinct metal/rune accent.
				draw_rect(Rect2(pos+Vector2(2,17),Vector2(28,13)),Color("2b1b18"))
				draw_rect(Rect2(pos+Vector2(3,18),Vector2(26,11)),Color("744225"))
				draw_rect(Rect2(pos+Vector2(2,28),Vector2(28,3)),Color("1c1415"))
				draw_rect(Rect2(pos+Vector2(3,10+lid_offset),Vector2(26,8)),Color("a56632"))
				draw_rect(Rect2(pos+Vector2(3,16+lid_offset),Vector2(26,3)),accent)
				draw_rect(Rect2(pos+Vector2(14,16),Vector2(5,8)),accent.lightened(0.18))
				draw_rect(Rect2(pos+Vector2(15,18),Vector2(3,3)),Color("3a3030"))
			elif texture:
				draw_texture_rect(texture,Rect2(pos,Vector2(TILE,TILE)),false)
			else:
				draw_rect(Rect2(pos,Vector2(TILE,TILE)),Items.COLORS.get(id,Color.GRAY))
			if is_snow_biome(x):
				# Strong, unmistakable snow biome treatment. This is render-only, so old
				# saves instantly gain the biome without rewriting their terrain data.
				var deep_snow=x>=SNOW_START_X+22 and x<=SNOW_END_X-12
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
		draw_village_decor(left,right)


func _decor_base(x:int) -> Vector2:
	return Vector2(x*TILE+TILE/2.0,surfaces[x]*TILE)

func decor_scale_for(key:String) -> float:
	return float(DECOR_ROLE_SCALE.get(key,0.76))

func _draw_decor_sprite(base:Vector2,key:String,modifier:float=1.0) -> void:
	if decor_atlas==null or not DECOR_INDEX.has(key):
		return
	var index=int(DECOR_INDEX[key])
	var column=index%5
	var row=int(index/5)
	var source=Rect2(Vector2(column*int(DECOR_CELL.x),row*int(DECOR_CELL.y)),DECOR_CELL)
	var scale=decor_scale_for(key)*clampf(modifier,0.85,1.15)
	var draw_size=DECOR_CELL*scale*2.0
	var destination=Rect2(base+Vector2(-draw_size.x*0.5,-draw_size.y),draw_size)
	draw_texture_rect_region(decor_atlas,destination,source)

func _draw_desert_sprite(base:Vector2,key:String,scale:float=1.0) -> void:
	var texture:Texture2D=desert_decor.get(key)
	if texture==null:
		return
	var size=texture.get_size()*scale
	draw_texture_rect(texture,Rect2(base+Vector2(-size.x*0.5,-size.y),size),false)

func draw_surface_decor(left:int,right:int) -> void:
	if purity_realm or surfaces.is_empty():
		return
	for x in range(maxi(left,VILLAGE_MAX_X+7),mini(right,surfaces.size())):
		if x<0 or x>=surfaces.size() or is_lake_zone(x):
			continue
		if get_cell(Vector2i(x,surfaces[x]-1)) in [4,5]:
			continue
		var code=absi((x*73+world_seed*19+x*x*7)%137)
		var base=_decor_base(x)
		if desert_strength(x)>0.56:
			if code%17==0:
				_draw_desert_sprite(base,"cactus",0.72)
			elif code%13==0:
				_draw_desert_sprite(base,"dry_bush",0.72)
			elif code%19==0:
				_draw_desert_sprite(base,"bones",0.70)
			elif code%11==0:
				_draw_desert_sprite(base,"desert_rock",0.72)
			continue
		if code>10:
			continue
		match code:
			0: _draw_decor_sprite(base,"shrub",0.96)
			1: _draw_decor_sprite(base,"flowers",0.94)
			2: _draw_decor_sprite(base,"tall_grass",0.94)
			3: _draw_decor_sprite(base,"log",0.96)
			4: _draw_decor_sprite(base,"stump",0.95)
			5: _draw_decor_sprite(base,"hay_pile",0.96)
			6: _draw_decor_sprite(base,"white_flower",0.92)
			7: _draw_decor_sprite(base,"plants",0.95)
			8: _draw_decor_sprite(base,"crates",0.94)
			9: _draw_decor_sprite(base,"barrels",0.94)
			10: _draw_decor_sprite(base,"small_crate",0.92)

func draw_village_decor(left:int,right:int) -> void:
	if surfaces.size()<67:
		return
	# Exact art from the supplied decoration sheet; no procedural substitutes.
	var props=[
		[5,"tree",1.00],[8,"notice",0.98],[11,"flowers",0.95],[14,"lampadao",1.00],
		[26,"barrels",0.98],[29,"crates",0.98],[31,"poste",1.00],
		[40,"bench",1.04],[44,"well",1.00],[47,"flowers",0.95],
		[56,"lantern",0.98],[59,"banner_red",1.00],[62,"vase",0.96],[65,"pine",1.00]
	]
	for data in props:
		var x=int(data[0])
		if x<left or x>=right or x<0 or x>=surfaces.size():
			continue
		_draw_decor_sprite(_decor_base(x),str(data[1]),float(data[2]))

func _draw_lake_trident(center:Vector2,scale:float,color:Color) -> void:
	var width=maxf(2.0,4.0*scale)
	draw_line(center+Vector2(0,34)*scale,center+Vector2(0,-34)*scale,color,width)
	draw_line(center+Vector2(0,-10)*scale,center+Vector2(-20,-26)*scale,color,width)
	draw_line(center+Vector2(-20,-26)*scale,center+Vector2(-20,-9)*scale,color,width)
	draw_line(center+Vector2(0,-10)*scale,center+Vector2(20,-26)*scale,color,width)
	draw_line(center+Vector2(20,-26)*scale,center+Vector2(20,-9)*scale,color,width)

func _draw_lake_chain(a:Vector2,b:Vector2,links:int) -> void:
	for i in range(links):
		var f=float(i)/float(maxi(1,links-1))
		var p=a.lerp(b,f)+Vector2(0,sin(f*PI)*8)
		draw_arc(p,4,0,TAU,8,Color("2a252b"),2)

func _draw_lake_temple(temple:Vector2) -> void:
	var cyan=Color("32cbe9")
	var stone=Color("252d3b")
	var stone_hi=Color("465467")
	var width=LAKE_TEMPLE_SIZE.x
	var height=LAKE_TEMPLE_SIZE.y
	var left=temple.x-width*0.5
	var top=temple.y-height
	# Main symmetrical silhouette.
	draw_rect(Rect2(left+38,top+54,width-76,height-54),stone)
	draw_rect(Rect2(left+20,top+48,54,height-48),Color("2a3342"))
	draw_rect(Rect2(left+width-74,top+48,54,height-48),Color("2a3342"))
	draw_rect(Rect2(left+12,top+42,width-24,14),stone_hi)
	draw_rect(Rect2(left+30,top+32,58,18),stone_hi)
	draw_rect(Rect2(left+width-88,top+32,58,18),stone_hi)
	# Broken crown and central crest.
	draw_polygon(PackedVector2Array([
		Vector2(temple.x-116,top+55),Vector2(temple.x-76,top+12),Vector2(temple.x-36,top+42),
		Vector2(temple.x,top-18),Vector2(temple.x+38,top+42),Vector2(temple.x+78,top+8),
		Vector2(temple.x+116,top+55)
	]),PackedColorArray([stone,stone,stone,stone,stone,stone,stone]))
	draw_polygon(PackedVector2Array([
		Vector2(temple.x,top+25),Vector2(temple.x-38,top+54),Vector2(temple.x-24,top+96),
		Vector2(temple.x+24,top+96),Vector2(temple.x+38,top+54)
	]),PackedColorArray([Color("29364a"),Color("29364a"),Color("29364a"),Color("29364a"),Color("29364a")]))
	_draw_lake_trident(Vector2(temple.x,top+63),0.56,Color("9aafba"))
	# Proportional entrance: large enough to be important, still believable for the player.
	var door_pos=Vector2(temple.x-LAKE_TEMPLE_DOOR_SIZE.x*0.5,temple.y-LAKE_TEMPLE_DOOR_SIZE.y)
	draw_rect(Rect2(door_pos,LAKE_TEMPLE_DOOR_SIZE),Color("0d1420"))
	draw_arc(Vector2(temple.x,door_pos.y+3),LAKE_TEMPLE_DOOR_SIZE.x*0.5,PI,TAU,28,stone_hi,5)
	draw_line(Vector2(temple.x,door_pos.y+10),Vector2(temple.x,temple.y-12),cyan,3)
	_draw_lake_trident(Vector2(temple.x,temple.y-58),0.65,cyan)
	# Columns, chains and banners.
	for px in [left+54,left+122,left+width-122,left+width-54]:
		draw_rect(Rect2(px-13,top+70,26,height-70),Color("303949"))
		draw_rect(Rect2(px-19,top+66,38,9),stone_hi)
		draw_rect(Rect2(px-19,temple.y-10,38,10),stone_hi)
	_draw_lake_chain(Vector2(left+54,top+76),Vector2(temple.x-82,top+112),12)
	_draw_lake_chain(Vector2(left+width-54,top+76),Vector2(temple.x+82,top+112),12)
	for bx in [left+7,left+width-39]:
		draw_rect(Rect2(bx,top+88,32,76),Color("15344a"))
		draw_polygon(PackedVector2Array([Vector2(bx,top+164),Vector2(bx+16,top+188),Vector2(bx+32,top+164)]),PackedColorArray([Color("15344a"),Color("15344a"),Color("15344a")]))
		_draw_lake_trident(Vector2(bx+16,top+126),0.28,Color("93aeba"))
	# Cyan braziers.
	for fx in [temple.x-112,temple.x+112]:
		draw_circle(Vector2(fx,temple.y-60),16,Color("2dd7f02b"))
		draw_polygon(PackedVector2Array([
			Vector2(fx-8,temple.y-50),Vector2(fx-5,temple.y-66),Vector2(fx,temple.y-82),
			Vector2(fx+6,temple.y-65),Vector2(fx+8,temple.y-50)
		]),PackedColorArray([cyan,cyan,Color("9af2ff"),cyan,cyan]))
		draw_rect(Rect2(fx-11,temple.y-50,22,6),Color("161c26"))
	# Algae and coral-like accents.
	for ax in [left+42,left+102,temple.x-54,temple.x+62,left+width-98,left+width-40]:
		draw_line(Vector2(ax,top+54),Vector2(ax-3,top+92),Color("1d5d4d"),4)
		draw_line(Vector2(ax+5,top+58),Vector2(ax+10,top+101),Color("287661"),3)

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
		# Transparent water lets the real night sky/backdrop stay visible instead
		# of turning the entire lake valley into a flat blue rectangle.
		draw_rect(Rect2(px,water_top,TILE,depth),Color("123b586b"))
		draw_rect(Rect2(px,water_top,TILE,6),Color("70c8e6d8"))
		draw_rect(Rect2(px,water_top+6,TILE,minf(24.0,maxf(0.0,depth-6))),Color("3b8ca04a"))
		var wave_y=water_top+8.0+sin(time*2.2+float(x)*0.72)*2.0
		draw_line(Vector2(px+2,wave_y),Vector2(px+TILE-3,wave_y),Color("b7ecff99"),2)
		# Gentle horizontal caustics instead of the old vertical blue bars.
		if depth>54.0 and (x-lake_start_x)%3==0:
			var caustic_y=water_top+38.0+fmod(float((x-lake_start_x)*19),maxf(20.0,depth-44.0))
			draw_line(Vector2(px+6,caustic_y),Vector2(px+24,caustic_y+sin(time*1.7+x)*2.0),Color("62bdd34a"),1.5)
		if depth>90.0 and (x+world_seed)%7==0:
			var bubble_y=water_top+36.0+fmod(time*18.0+float((x*23)%70),maxf(28.0,depth-42.0))
			draw_circle(Vector2(px+16,bubble_y),2.0,Color("b8ebf36a"))
	for x in [lake_start_x+4,lake_start_x+10,lake_end_x-10,lake_end_x-4]:
		if x>=visible_left and x<visible_right:
			var px=float(x*TILE+16)
			draw_line(Vector2(px,water_top+20),Vector2(px-5,water_top-34),Color("183329"),5)
			draw_line(Vector2(px+7,water_top+18),Vector2(px+12,water_top-20),Color("285143"),3)
	if lake_center_x>=visible_left and lake_center_x<visible_right:
		_draw_lake_temple(lake_temple_position())

