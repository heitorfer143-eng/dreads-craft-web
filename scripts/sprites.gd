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

# Existing, valid PNG sheets already in the project.
# Each generated mob sheet is 6 frames wide (96x96 per frame):
# idle, walk1, walk2, attack, hurt, death.
const GENERATED_MOBS = {
	"corrupted_skeleton": "res://assets/sprites/mobs/corrupted_skeleton_sheet.png",
	"dark_slime": "res://assets/sprites/mobs/dark_slime_v2_sheet.png",
	"undead_knight": "res://assets/sprites/mobs/spectral_warden_sheet.png",
	"polar_bear": "res://assets/sprites/mobs/polar_bear_sheet.png"
}
const GENERATED_ACTIONS = {
	"idle": [0],
	"walk": [1,2],
	"attack": [3],
	"hurt": [4],
	"death": [5]
}

# Fallback atlas for the original skeleton and wolf.
const ATLAS_PATH = "res://assets/image-003.png"
const ATLAS_FRAMES = {
	"skeleton": {
		"idle": [Rect2(28,189,248,344)],
		"walk": [Rect2(28,189,248,344),Rect2(305,211,259,324)],
		"attack": [Rect2(573,167,273,366)],
		"hurt": [Rect2(854,225,323,309)],
		"death": [Rect2(1154,311,269,226)]
	},
	"wolf": {
		"idle": [Rect2(23,651,270,259)],
		"walk": [Rect2(23,651,270,259),Rect2(299,668,279,241)],
		"attack": [Rect2(585,665,283,244)],
		"hurt": [Rect2(896,679,266,231)],
		"death": [Rect2(1178,698,225,214)]
	}
}

static func _add_player_frames(frames: SpriteFrames, kind: String) -> void:
	for action in PLAYER_FILES[kind]:
		frames.add_animation(action)
		frames.set_animation_speed(action,8.0 if action=="walk" else 10.0)
		frames.set_animation_loop(action,action in ["idle","walk","jump"])
		for path in PLAYER_FILES[kind][action]:
			frames.add_frame(action,load(path) as Texture2D)

static func _add_generated_mob_frames(frames: SpriteFrames, kind: String) -> void:
	var sheet=load(GENERATED_MOBS[kind]) as Texture2D
	for action in GENERATED_ACTIONS:
		frames.add_animation(action)
		frames.set_animation_speed(action,10.0 if action=="walk" else 9.0)
		frames.set_animation_loop(action,action in ["idle","walk"])
		for index in GENERATED_ACTIONS[action]:
			var texture=AtlasTexture.new()
			texture.atlas=sheet
			texture.region=Rect2(int(index)*96,0,96,96)
			frames.add_frame(action,texture)

static func _add_atlas_mob_frames(frames: SpriteFrames, kind: String) -> void:
	var sheet=load(ATLAS_PATH) as Texture2D
	for action in ATLAS_FRAMES[kind]:
		frames.add_animation(action)
		frames.set_animation_speed(action,9.0 if action=="walk" else 8.0)
		frames.set_animation_loop(action,action in ["idle","walk"])
		for region in ATLAS_FRAMES[kind][action]:
			var texture=AtlasTexture.new()
			texture.atlas=sheet
			texture.region=region
			# Normalize each atlas crop to a stable square canvas so the sprite
			# does not jump/shrink between animations.
			var pad_x=maxf(0.0,380.0-region.size.x)
			var pad_y=maxf(0.0,380.0-region.size.y)
			texture.margin=Rect2(pad_x/2.0,pad_y,pad_x,pad_y)
			frames.add_frame(action,texture)

static func make(kind: String) -> AnimatedSprite2D:
	var sprite=AnimatedSprite2D.new()
	var frames=SpriteFrames.new()
	frames.remove_animation("default")

	if kind in ["normal","demon"]:
		_add_player_frames(frames,kind)
		sprite.scale=Vector2(0.16,0.16)
		sprite.position.y=-27.2
	elif GENERATED_MOBS.has(kind):
		_add_generated_mob_frames(frames,kind)
		match kind:
			"dark_slime":
				sprite.scale=Vector2(0.78,0.78)
				sprite.position.y=-24
			"corrupted_skeleton":
				sprite.scale=Vector2(0.95,0.95)
				sprite.position.y=-43
			"undead_knight":
				sprite.scale=Vector2(0.88,0.88)
				sprite.position.y=-36
			"polar_bear":
				sprite.scale=Vector2(1.28,1.28)
				sprite.position.y=-43
	else:
		var base_kind="wolf" if kind=="wolf" else "skeleton"
		_add_atlas_mob_frames(frames,base_kind)
		sprite.scale=Vector2(0.34,0.34) if base_kind=="wolf" else Vector2(0.32,0.32)
		sprite.position.y=-44

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
