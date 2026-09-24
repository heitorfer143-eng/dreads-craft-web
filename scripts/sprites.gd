extends RefCounted

const PLAYER_FILES = {
	"normal": {
		"idle": ["res://assets/sprites/normal_idle_0.png"],
		"walk": ["res://assets/sprites/normal_walk_0.png","res://assets/sprites/normal_walk_1.png"],
		"jump": ["res://assets/sprites/normal_jump_0.png"],
		"attack": ["res://assets/sprites/normal_attack_0.png"],
		"hurt": ["res://assets/sprites/normal_hurt_0.png"]
	},
	"demon": {
		"idle": ["res://assets/sprites/demon_idle_0.png"],
		"walk": ["res://assets/sprites/demon_walk_0.png","res://assets/sprites/demon_walk_1.png"],
		"jump": ["res://assets/sprites/demon_jump_0.png"],
		"attack": ["res://assets/sprites/demon_attack_0.png"],
		"hurt": ["res://assets/sprites/demon_hurt_0.png"]
	}
}

# One clean PNG generated specifically for the mobs.
# 5 columns: idle, walk, attack, hurt, death.
# 5 rows: skeleton, dark slime, undead knight, wolf, polar bear.
const MOB_SHEET = "res://assets/mobs/mobs_generated.png"
const MOB_ROWS = {
	"skeleton": 0,
	"corrupted_skeleton": 0,
	"dark_slime": 1,
	"undead_knight": 2,
	"wolf": 3,
	"polar_bear": 4
}
const ACTION_COLUMNS = {
	"idle": [0],
	"walk": [0,1],
	"attack": [2],
	"hurt": [3],
	"death": [4]
}
const CELL_SIZE = Vector2i(70,60)

static func _add_player_frames(frames: SpriteFrames, kind: String) -> void:
	for action in PLAYER_FILES[kind]:
		frames.add_animation(action)
		frames.set_animation_speed(action,8.0 if action=="walk" else 10.0)
		frames.set_animation_loop(action,action in ["idle","walk","jump"])
		for path in PLAYER_FILES[kind][action]:
			frames.add_frame(action,load(path) as Texture2D)

static func _mob_frame(sheet: Texture2D,row:int,column:int) -> Texture2D:
	var texture=AtlasTexture.new()
	texture.atlas=sheet
	texture.region=Rect2(column*CELL_SIZE.x,row*CELL_SIZE.y,CELL_SIZE.x,CELL_SIZE.y)
	return texture

static func _add_mob_frames(frames: SpriteFrames, kind: String) -> void:
	var sheet=load(MOB_SHEET) as Texture2D
	var row=int(MOB_ROWS.get(kind,0))
	for action in ACTION_COLUMNS:
		frames.add_animation(action)
		frames.set_animation_speed(action,9.0 if action=="walk" else 8.0)
		frames.set_animation_loop(action,action in ["idle","walk"])
		for column in ACTION_COLUMNS[action]:
			frames.add_frame(action,_mob_frame(sheet,row,int(column)))

static func make(kind: String) -> AnimatedSprite2D:
	var sprite=AnimatedSprite2D.new()
	var frames=SpriteFrames.new()
	frames.remove_animation("default")

	if kind in ["normal","demon"]:
		_add_player_frames(frames,kind)
		sprite.scale=Vector2(0.16,0.16)
		sprite.position.y=-27.2
	else:
		_add_mob_frames(frames,kind)
		match kind:
			"dark_slime":
				sprite.scale=Vector2(1.18,1.18)
				sprite.position.y=-29
			"undead_knight":
				sprite.scale=Vector2(1.38,1.38)
				sprite.position.y=-42
			"wolf":
				sprite.scale=Vector2(1.36,1.36)
				sprite.position.y=-34
			"polar_bear":
				sprite.scale=Vector2(1.62,1.62)
				sprite.position.y=-39
			"corrupted_skeleton":
				sprite.scale=Vector2(1.34,1.34)
				sprite.position.y=-42
			_:
				sprite.scale=Vector2(1.28,1.28)
				sprite.position.y=-40

	sprite.sprite_frames=frames
	if kind in ["normal","demon"]:
		var clean_mat=ShaderMaterial.new()
		var clean_shader=Shader.new()
		clean_shader.code="shader_type canvas_item; void fragment(){ vec4 c=texture(TEXTURE,UV); float bright=min(c.r,min(c.g,c.b)); if(UV.y>0.78 && bright>0.82 && abs(c.r-c.g)<0.10 && abs(c.g-c.b)<0.10){ discard; } COLOR=c; }"
		clean_mat.shader=clean_shader
		sprite.material=clean_mat
	sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered=true
	sprite.play("idle")
	return sprite
