extends CharacterBody2D

signal killed
const Sprites = preload("res://scripts/sprites.gd")
var player: CharacterBody2D
var kind = "skeleton"
var hp = 48.0
var damage = 6.0
var attack_timer = 0.0
var death_timer = -1.0
var sprite: AnimatedSprite2D
var hit_flash=0.0
var knockback=Vector2.ZERO

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
	shape.size=body_size
	var collider=CollisionShape2D.new()
	collider.shape=shape
	collider.position=Vector2(0,-body_size.y/2.0)
	add_child(collider)
	sprite=Sprites.make(kind)
	add_child(sprite)
	if kind=="wolf":
		hp=32
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
		hp=220
		damage=16

func _physics_process(delta: float) -> void:
	if death_timer>=0:
		death_timer-=delta
		if death_timer<=0:
			queue_free()
		return
	if not is_instance_valid(player):
		return
	attack_timer=maxf(0,attack_timer-delta)
	hit_flash=maxf(0,hit_flash-delta)
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
	sprite.flip_h=direction<0
	var distance=position.distance_to(player.position)
	var attack_range=82.0 if kind=="polar_bear" else 62.0 if kind in ["wolf","dark_slime"] else 58.0
	if distance<attack_range and attack_timer<=0:
		attack_timer=1.1
		player.take_damage(damage)
		player.velocity.x=direction*150
	sprite.play("attack" if attack_timer>.75 else "walk")
	sprite.modulate=Color(1.0,0.55,0.55) if hit_flash>0 else Color.WHITE
	if distance>1800:
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
		killed.emit()
