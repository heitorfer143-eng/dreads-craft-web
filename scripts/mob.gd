extends CharacterBody2D

signal killed
const Sprites = preload("res://scripts/sprites.gd")
const DungeonArt = preload("res://scripts/dungeon_art.gd")
var player: CharacterBody2D
var kind = "skeleton"
var hp = 48.0
var damage = 6.0
var difficulty_level=1
var attack_timer = 0.0
var death_timer = -1.0
var sprite: AnimatedSprite2D
var hit_flash=0.0
var knockback=Vector2.ZERO
var world_min_x:=0.0
var world_max_x:=320.0*32.0
var world_min_y:=0.0
var world_max_y:=96.0*32.0
var despawn_distance:=1800.0
var is_dungeon_miniboss:=false
var dungeon_id:=""
var elite_name:=""
var guardian_aura:Sprite2D

func _ready() -> void:
	collision_layer=4
	collision_mask=1
	var shape=RectangleShape2D.new()
	var body_size=Vector2(38,54)
	if kind=="wolf":
		body_size=Vector2(48,38)
	elif kind=="dark_slime":
		body_size=Vector2(44,34)
	elif kind=="undead_knight":
		body_size=Vector2(46,62)
	elif kind=="polar_bear":
		body_size=Vector2(76,54)
	if is_dungeon_miniboss:
		body_size=Vector2(58,72)
	shape.size=body_size
	var collider=CollisionShape2D.new()
	collider.shape=shape
	collider.position=Vector2(0,-body_size.y/2.0)
	add_child(collider)
	if is_dungeon_miniboss and DungeonArt.atlas()!=null:
		guardian_aura=Sprite2D.new()
		guardian_aura.texture=DungeonArt.texture("guardian_aura")
		guardian_aura.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
		guardian_aura.position=Vector2(0,-42)
		guardian_aura.scale=Vector2(2.05,2.05)
		guardian_aura.modulate=Color(1,1,1,0.68)
		guardian_aura.z_index=-1
		add_child(guardian_aura)
		sprite=AnimatedSprite2D.new()
		sprite.sprite_frames=DungeonArt.guardian_frames()
		sprite.animation="idle"
		sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.position=Vector2(0,-43)
		sprite.scale=Vector2(1.95,1.95)
	else:
		sprite=Sprites.make(kind)
	add_child(sprite)
	if kind=="wolf":
		hp=32
		damage=6
	elif kind=="corrupted_skeleton":
		hp=58
		damage=8
	elif kind=="dark_slime":
		hp=38
		damage=5
	elif kind=="undead_knight":
		hp=110
		damage=12
	elif kind=="polar_bear":
		hp=300
		damage=20
	var index=clampi(difficulty_level,0,3)
	var hp_mult=[0.85,1.0,1.28,1.58][index]
	var damage_mult=[0.75,1.0,1.22,1.48][index]
	hp*=hp_mult
	damage*=damage_mult
	if is_dungeon_miniboss:
		hp*=2.8
		damage*=1.45
		despawn_distance=4200.0
		if guardian_aura==null:
			sprite.scale*=1.16
	queue_redraw()

func set_dungeon_miniboss(id:String,name:String) -> void:
	is_dungeon_miniboss=true
	dungeon_id=id
	elite_name=name

func set_world_bounds(min_x:float,max_x:float,min_y:float=0.0,max_y:float=96.0*32.0) -> void:
	world_min_x=min_x
	world_max_x=max_x
	world_min_y=min_y
	world_max_y=max_y

func _physics_process(delta: float) -> void:
	queue_redraw()
	if death_timer>=0:
		death_timer-=delta
		if death_timer<=0:
			queue_free()
		return
	if not is_instance_valid(player):
		return
	attack_timer=maxf(0,attack_timer-delta)
	hit_flash=maxf(0,hit_flash-delta)
	if is_instance_valid(guardian_aura):
		var pulse=1.0+sin(Time.get_ticks_msec()/150.0)*0.045
		guardian_aura.scale=Vector2(2.05,2.05)*pulse
		guardian_aura.modulate.a=0.58+sin(Time.get_ticks_msec()/190.0)*0.10
	var direction=signf(player.position.x-position.x)
	var speed=58.0 if kind=="polar_bear" else 105.0 if kind=="wolf" else 48.0 if kind=="undead_knight" else 72.0 if kind=="corrupted_skeleton" else 64.0
	velocity.x=direction*speed+knockback.x
	knockback=knockback.move_toward(Vector2.ZERO,700*delta)
	velocity.y=minf(850,velocity.y+1500*delta)
	if kind=="dark_slime" and is_on_floor() and attack_timer<=0:
		velocity.y=-360
	elif is_on_wall() and is_on_floor():
		velocity.y=-430
	move_and_slide()
	var clamped_x=clampf(position.x,world_min_x+16.0,world_max_x-16.0)
	if not is_equal_approx(clamped_x,position.x):
		position.x=clamped_x
		velocity.x=0.0
		knockback.x=0.0
	var clamped_y=clampf(position.y,world_min_y+8.0,world_max_y-2.0)
	if not is_equal_approx(clamped_y,position.y):
		position.y=clamped_y
		velocity.y=0.0
	sprite.flip_h=direction<0
	var distance=position.distance_to(player.position)
	var attack_range=82.0 if kind=="polar_bear" else 62.0 if kind in ["wolf","dark_slime"] else 58.0
	if distance<attack_range and attack_timer<=0:
		attack_timer=1.1
		player.take_damage(damage)
		player.velocity.x=direction*150
	sprite.play("attack" if attack_timer>.75 else "walk")
	sprite.modulate=Color(1.0,0.55,0.55) if hit_flash>0 else Color.WHITE
	if distance>despawn_distance:
		queue_free()

func hit(amount: float, force: float=240.0) -> void:
	if death_timer>=0:
		return
	hp-=amount
	hit_flash=.16
	if is_instance_valid(player):
		knockback.x=signf(position.x-player.position.x)*force
		velocity.y=-110
	sprite.play("hurt")
	if hp<=0:
		death_timer=.45
		sprite.play("death")
		if is_dungeon_miniboss and DungeonArt.atlas()!=null:
			sprite.position=Vector2(0,-20)
			if is_instance_valid(guardian_aura):
				guardian_aura.hide()
		killed.emit()

func _draw() -> void:
	if is_dungeon_miniboss and not is_instance_valid(guardian_aura):
		# Fallback only if the generated art atlas fails to decode.
		draw_circle(Vector2(0,-31),38,Color("8e58b526"))
		draw_arc(Vector2(0,-31),32,0,TAU,28,Color("d39cff99"),3)
		draw_polygon(PackedVector2Array([Vector2(-11,-76),Vector2(-5,-88),Vector2(0,-79),Vector2(6,-90),Vector2(12,-76)]),PackedColorArray([Color("d7b866"),Color("d7b866"),Color("d7b866"),Color("d7b866"),Color("d7b866")]))
	var radius=Vector2(28,7)
	if kind=="dark_slime":
		radius=Vector2(24,6)
	elif kind=="polar_bear":
		radius=Vector2(42,8)
	draw_ellipse_shadow(Vector2(0,-2),radius,Color(0,0,0,.24))

func draw_ellipse_shadow(center:Vector2,radius:Vector2,color:Color) -> void:
	var points=PackedVector2Array()
	for i in range(20):
		var angle=TAU*float(i)/20.0
		points.append(center+Vector2(cos(angle)*radius.x,sin(angle)*radius.y))
	draw_colored_polygon(points,color)
