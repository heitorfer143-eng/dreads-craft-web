extends Area2D

signal interacted(mel)

var player: CharacterBody2D
var tamed := false
var sprite: Sprite2D
var home_position:=Vector2.ZERO
var wander_dir:=1.0
var wander_timer:=0.0
var anim_time:=0.0

func setup(target: CharacterBody2D, is_tamed: bool=false) -> void:
	player=target
	tamed=is_tamed

func _ready() -> void:
	collision_layer=0
	collision_mask=0
	var shape=CollisionShape2D.new()
	var capsule=CapsuleShape2D.new()
	capsule.radius=18
	capsule.height=34
	shape.shape=capsule
	shape.position=Vector2(0,-16)
	add_child(shape)
	sprite=Sprite2D.new()
	sprite.texture=load("res://assets/npcs/mel.png")
	sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale=Vector2(0.46,0.46)
	sprite.position=Vector2(0,-18)
	# Keep the user's Mel image, removing only its white background at render time.
	var shader=Shader.new()
	shader.code="shader_type canvas_item; void fragment(){ vec4 c=texture(TEXTURE,UV); if(c.r>.94 && c.g>.94 && c.b>.94) discard; COLOR=c; }"
	var material=ShaderMaterial.new()
	material.shader=shader
	sprite.material=material
	add_child(sprite)
	home_position=global_position
	wander_timer=randf_range(1.4,3.2)
	z_index=6

func can_interact() -> bool:
	return is_instance_valid(player) and global_position.distance_to(player.global_position)<125.0

func interact() -> void:
	if can_interact():
		interacted.emit(self)

func set_tamed(value: bool) -> void:
	tamed=value

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	anim_time+=delta
	wander_timer-=delta

	if tamed:
		var target=player.position+Vector2(-player.face*72,0)
		var distance=global_position.distance_to(target)
		if distance>420:
			global_position=target
		elif distance>58:
			global_position.x=move_toward(global_position.x,target.x,150.0*delta)
			global_position.y=move_toward(global_position.y,player.position.y,110.0*delta)
			sprite.flip_h=player.position.x<global_position.x
	else:
		# Before being tamed, Mel explores a small safe area near the village.
		if wander_timer<=0:
			wander_timer=randf_range(1.2,3.0)
			wander_dir=-wander_dir if randf()<0.7 else wander_dir
		var min_x=home_position.x-150.0
		var max_x=home_position.x+150.0
		if global_position.x<=min_x:
			wander_dir=1.0
		elif global_position.x>=max_x:
			wander_dir=-1.0
		global_position.x=clampf(global_position.x+wander_dir*42.0*delta,min_x,max_x)
		sprite.flip_h=wander_dir<0

	# Small pixel-art style idle/walk animation without changing the sprite asset.
	var moving=tamed and global_position.distance_to(player.position)>70.0 or not tamed
	sprite.position.y=-18.0+sin(anim_time*(9.0 if moving else 4.0))*(2.4 if moving else 1.2)
	var pulse=1.0+sin(anim_time*6.0)*0.018
	sprite.scale=Vector2(0.46*pulse,0.46/pulse)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if can_interact() and not tamed:
		draw_circle(Vector2(0,-64),13,Color("17111ee8"))
		draw_arc(Vector2(0,-64),13,0,TAU,20,Color("e5b66f"),2)
		draw_string(ThemeDB.fallback_font,Vector2(-5,-58),"!",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("ffe7a3"))
