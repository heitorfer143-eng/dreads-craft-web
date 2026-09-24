extends RefCounted

const FRAMES = {
	"skeleton": {"idle": [Rect2(28,189,248,344)], "walk": [Rect2(28,189,248,344),Rect2(305,211,259,324)], "attack": [Rect2(573,167,273,366)], "hurt": [Rect2(854,225,323,309)], "death": [Rect2(1154,311,269,226)]},
	"wolf": {"idle": [Rect2(23,651,270,259)], "walk": [Rect2(23,651,270,259),Rect2(299,668,279,241)], "attack": [Rect2(585,665,283,244)], "hurt": [Rect2(896,679,266,231)], "death": [Rect2(1178,698,225,214)]}
}

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

const PATHS = {"skeleton": "res://assets/image-003.png", "wolf": "res://assets/image-003.png"}

static func _add_player_frames(frames: SpriteFrames, kind: String) -> void:
	for action in PLAYER_FILES[kind]:
		frames.add_animation(action)
		frames.set_animation_speed(action, 8.0 if action == "walk" else 10.0)
		frames.set_animation_loop(action, action in ["idle","walk","jump"])
		for path in PLAYER_FILES[kind][action]:
			frames.add_frame(action, load(path) as Texture2D)

static func _add_mob_frames(frames: SpriteFrames, kind: String) -> void:
	var sheet=load(PATHS[kind]) as Texture2D
	for action in FRAMES[kind]:
		frames.add_animation(action)
		frames.set_animation_speed(action,8.0)
		frames.set_animation_loop(action,action in ["idle","walk"])
		for region in FRAMES[kind][action]:
			var texture=AtlasTexture.new()
			texture.atlas=sheet
			texture.region=region
			texture.margin=Rect2((360.0-region.size.x)/2.0,300.0-region.size.y,360.0-region.size.x,300.0-region.size.y)
			frames.add_frame(action,texture)

static func make(kind: String) -> AnimatedSprite2D:
	var visual_kind=kind
	if kind in ["corrupted_skeleton","undead_knight"]:
		visual_kind="skeleton"
	elif kind=="dark_slime":
		visual_kind="wolf"
	elif kind=="polar_bear":
		visual_kind="wolf"
	var sprite=AnimatedSprite2D.new()
	var frames=SpriteFrames.new()
	frames.remove_animation("default")
	if visual_kind in ["normal","demon"]:
		_add_player_frames(frames,visual_kind)
		sprite.scale=Vector2(0.16,0.16)
		# Normalized player frames use a 400x360 canvas with the feet at y=350.
		# Moving the centered texture up by ~27px anchors every animation to the floor.
		sprite.position.y=-27.2
	else:
		_add_mob_frames(frames,visual_kind)
		sprite.scale=Vector2(0.17,0.17) if visual_kind=="wolf" else Vector2(0.155,0.155)
		if kind=="corrupted_skeleton": sprite.modulate=Color("8f6bad")
		elif kind=="dark_slime": sprite.modulate=Color("5b8068")
		elif kind=="undead_knight": sprite.modulate=Color("707681")
		elif kind=="polar_bear":
			sprite.modulate=Color("eef4ff")
			sprite.scale=Vector2(0.30,0.30)
		sprite.position.y=-25.0
	sprite.sprite_frames=frames
	if visual_kind in ["normal","demon"]:
		var clean_mat=ShaderMaterial.new()
		var clean_shader=Shader.new()
		clean_shader.code="shader_type canvas_item; void fragment(){ vec4 c=texture(TEXTURE,UV); float bright=min(c.r,min(c.g,c.b)); if(UV.y>0.78 && bright>0.82 && abs(c.r-c.g)<0.10 && abs(c.g-c.b)<0.10){ discard; } COLOR=c; }"
		clean_mat.shader=clean_shader
		sprite.material=clean_mat
	sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered=true
	sprite.play("idle")
	return sprite
