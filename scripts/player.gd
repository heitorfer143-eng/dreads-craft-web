extends CharacterBody2D

signal died

const Sprites = preload("res://scripts/sprites.gd")
const Items = preload("res://scripts/items.gd")
var creative = false
var hp = 100.0
var food = 100.0
var max_hp = 100.0
var face = 1
var inventory: Dictionary = {}
var attack_time = 0.0
var hurt_time = 0.0
var jump_buffer = 0.0
var coyote = 0.0
var sprite: AnimatedSprite2D
var camera: Camera2D
var weapon_sprite: Sprite2D
var weapon_tween: Tween
var armor_sprites: Dictionary = {}
var armor_reduction := 0.0
var spawn_position = Vector2(400,1000)
var max_fall_speed = 0.0
var was_grounded = false
var in_water := false
var submerged := false
var max_air := 18.0
var air := 18.0
var drown_tick := 0.0
var current_form := "spike"
var input_locked := false
var world_min_x:=0.0
var world_max_x:=320.0*32.0
var world_min_y:=0.0
var world_max_y:=96.0*32.0

const SAFE_FALL_SPEED = 650.0
const FALL_DAMAGE_DIVISOR = 12.0
const MAX_FALL_DAMAGE = 70.0

func _ready() -> void:
	collision_layer=2
	collision_mask=1
	var shape=RectangleShape2D.new()
	shape.size=Vector2(22,44)
	var collider=CollisionShape2D.new()
	collider.shape=shape
	collider.position=Vector2(0,-22)
	add_child(collider)
	_rebuild_form_sprite()
	_setup_armor_sprites()
	weapon_sprite=Sprite2D.new()
	weapon_sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	weapon_sprite.position=Vector2(18,-28)
	weapon_sprite.scale=Vector2(0.34,0.34)
	weapon_sprite.z_index=5
	weapon_sprite.hide()
	add_child(weapon_sprite)
	camera=Camera2D.new()
	camera.position=Vector2(0,-100)
	camera.position_smoothing_enabled=true
	camera.position_smoothing_speed=8
	camera.limit_left=0
	camera.limit_top=0
	camera.limit_right=8192*32
	camera.limit_bottom=96*32
	add_child(camera)
	was_grounded=is_on_floor()

func _physics_process(delta: float) -> void:
	attack_time=maxf(0,attack_time-delta)
	hurt_time=maxf(0,hurt_time-delta)
	_update_breath(delta)
	var controls_enabled=not input_locked
	var direction=Input.get_axis("left","right") if controls_enabled else 0.0
	velocity.x=direction*(155.0 if in_water and not creative else 220.0)
	if direction!=0:
		face=int(sign(direction))

	var grounded_before=is_on_floor()
	if creative:
		velocity.y=Input.get_axis("jump","down")*240 if controls_enabled else 0.0
		max_fall_speed=0.0
	elif in_water:
		max_fall_speed=0.0
		coyote=0.0
		jump_buffer=0.0
		velocity.y=minf(210.0,velocity.y+360.0*delta)
		if controls_enabled and Input.is_action_pressed("jump"):
			velocity.y=move_toward(velocity.y,-185.0,720.0*delta)
		elif controls_enabled and Input.is_action_pressed("down"):
			velocity.y=move_toward(velocity.y,185.0,620.0*delta)
		else:
			velocity.y=move_toward(velocity.y,38.0,220.0*delta)
		food=maxf(0,food-delta*.045)
	else:
		velocity.y=minf(900,velocity.y+1500*delta)
		if not grounded_before and velocity.y>0:
			max_fall_speed=maxf(max_fall_speed,velocity.y)
		coyote=0.12 if grounded_before else maxf(0,coyote-delta)
		jump_buffer=0.14 if controls_enabled and Input.is_action_just_pressed("jump") else maxf(0,jump_buffer-delta)
		if jump_buffer>0 and coyote>0:
			velocity.y=-545
			jump_buffer=0
			coyote=0
			max_fall_speed=0.0
		food=maxf(0,food-delta*.035)
	if not creative and food<=0:
		hp=maxf(1,hp-delta*.2)

	move_and_slide()

	if not creative:
		var grounded_after=is_on_floor()
		if grounded_after and not grounded_before:
			_apply_fall_damage(max_fall_speed)
			max_fall_speed=0.0
		elif grounded_after:
			max_fall_speed=0.0
		was_grounded=grounded_after

	var clamped_x=clampf(position.x,world_min_x+12.0,world_max_x-12.0)
	if not is_equal_approx(clamped_x,position.x):
		position.x=clamped_x
		velocity.x=0.0
	var clamped_y=clampf(position.y,world_min_y+44.0,world_max_y-4.0)
	if not is_equal_approx(clamped_y,position.y):
		position.y=clamped_y
		velocity.y=0.0
		max_fall_speed=0.0

	sprite.flip_h=face<0
	for armor_sprite in armor_sprites.values():
		if is_instance_valid(armor_sprite):
			armor_sprite.flip_h=face<0
	var animation="attack" if attack_time>0 else "hurt" if hurt_time>0 else "jump" if not is_on_floor() else "walk" if absf(velocity.x)>1 else "idle"
	if sprite.animation!=animation:
		sprite.play(animation)
	sprite.modulate=Color(1,.6,.6) if hurt_time>0 else Color.WHITE

func _rebuild_form_sprite() -> void:
	if is_instance_valid(sprite):
		remove_child(sprite)
		sprite.queue_free()
	var kind="demon" if creative else ("fox" if current_form=="fox" else "normal")
	sprite=Sprites.make(kind)
	_normalize_form_sprite(kind)
	add_child(sprite)

func _normalize_form_sprite(kind:String) -> void:
	if not is_instance_valid(sprite) or sprite.sprite_frames==null:
		return
	var texture=sprite.sprite_frames.get_frame_texture("idle",0)
	if texture==null:
		return
	var tex_size=texture.get_size()
	var target_height=68.0 if kind=="fox" else 62.0
	var factor=target_height/maxf(1.0,tex_size.y)
	sprite.scale=Vector2(factor,factor)
	sprite.position.y=-30.0 if kind=="fox" else -30.0

func _setup_armor_sprites() -> void:
	var layout={
		"head":{"position":Vector2(0,-45),"scale":0.42},
		"chest":{"position":Vector2(0,-29),"scale":0.42},
		"legs":{"position":Vector2(0,-14),"scale":0.34},
		"feet":{"position":Vector2(0,-3),"scale":0.33}
	}
	for slot in ["head","chest","legs","feet"]:
		var layer=Sprite2D.new()
		layer.name="Armor_"+slot
		layer.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
		layer.position=layout[slot].position
		layer.scale=Vector2.ONE*float(layout[slot].scale)
		layer.z_index=4
		layer.hide()
		add_child(layer)
		armor_sprites[slot]=layer

func _update_armor_visibility() -> void:
	var show_armor=current_form=="spike" and not creative
	for layer in armor_sprites.values():
		if is_instance_valid(layer):
			layer.visible=show_armor and layer.texture!=null

func set_armor_equipment(equipment:Dictionary) -> void:
	var paths={
		32:"res://assets/armor/avarita_helmet.png",
		33:"res://assets/armor/avarita_chest.png",
		34:"res://assets/armor/avarita_legs.png",
		35:"res://assets/armor/avarita_boots.png"
	}
	for slot in ["head","chest","legs","feet"]:
		var layer=armor_sprites.get(slot)
		if not is_instance_valid(layer):
			continue
		var item_id=int(equipment.get(slot,0))
		layer.texture=load(paths[item_id]) if paths.has(item_id) else null
	armor_reduction=Items.armor_reduction(equipment)
	_update_armor_visibility()

func set_world_bounds(min_x:float,max_x:float,min_y:float,max_y:float) -> void:
	world_min_x=min_x
	world_max_x=max_x
	world_min_y=min_y
	world_max_y=max_y
	if is_instance_valid(camera):
		camera.limit_left=int(min_x)
		camera.limit_right=int(max_x)
		camera.limit_top=int(min_y)
		camera.limit_bottom=int(max_y)
		camera.limit_smoothed=false
		camera.reset_smoothing()

func set_form(form_id:String) -> void:
	current_form="fox" if form_id=="fox" else "spike"
	_rebuild_form_sprite()
	_update_armor_visibility()

func set_water_state(value:bool,head_submerged:bool=false) -> void:
	in_water=value
	submerged=value and head_submerged
	if in_water:
		max_fall_speed=0.0
		velocity.y=minf(velocity.y,140.0)
	else:
		submerged=false

func _update_breath(delta:float) -> void:
	if creative:
		air=max_air
		drown_tick=0.0
		return
	if submerged:
		air=maxf(0.0,air-delta)
		if air<=0.0:
			drown_tick-=delta
			if drown_tick<=0.0:
				drown_tick=1.0
				take_damage(5.0)
	else:
		air=minf(max_air,air+delta*3.6)
		drown_tick=0.0

func _apply_fall_damage(impact_speed: float) -> void:
	if creative or in_water or impact_speed<=SAFE_FALL_SPEED:
		return
	var amount=clampf((impact_speed-SAFE_FALL_SPEED)/FALL_DAMAGE_DIVISOR,4.0,MAX_FALL_DAMAGE)
	take_damage(amount)

func take_damage(amount: float) -> void:
	if creative or hurt_time>0:
		return
	var final_damage=maxf(1.0,amount*(1.0-armor_reduction))
	hp-=final_damage
	hurt_time=.85
	if hp<=0:
		respawn()

func respawn() -> void:
	died.emit()
	hp=max_hp
	food=75
	air=max_air
	submerged=false
	in_water=false
	position=spawn_position
	velocity=Vector2.ZERO
	max_fall_speed=0.0

func body_rect() -> Rect2:
	return Rect2(position+Vector2(-11,-44),Vector2(22,44))


func play_weapon_attack(texture: Texture2D, duration: float=0.30) -> void:
	if texture==null or not is_instance_valid(weapon_sprite):
		return
	if is_instance_valid(weapon_tween):
		weapon_tween.kill()
	weapon_sprite.texture=texture
	weapon_sprite.show()
	weapon_sprite.flip_h=face<0
	weapon_sprite.position=Vector2(18*face,-30)
	weapon_sprite.rotation=(-1.15 if face>0 else 1.15)
	weapon_sprite.scale=Vector2(0.36,0.36)
	weapon_tween=create_tween()
	weapon_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	weapon_tween.tween_property(weapon_sprite,"rotation",(0.95 if face>0 else -0.95),duration*0.7)
	weapon_tween.parallel().tween_property(weapon_sprite,"position",Vector2(28*face,-20),duration*0.7)
	weapon_tween.tween_interval(duration*0.15)
	weapon_tween.tween_callback(func(): weapon_sprite.hide())
