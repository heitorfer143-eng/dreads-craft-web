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

func _ready() -> void:
	collision_layer=4
	collision_mask=1
	var shape=RectangleShape2D.new()
	shape.size=Vector2(30,40)
	var collider=CollisionShape2D.new()
	collider.shape=shape
	collider.position=Vector2(0,-20)
	add_child(collider)
	sprite=Sprites.make(kind)
	add_child(sprite)
	if kind=="wolf":
		hp=32

func _physics_process(delta: float) -> void:
	if death_timer>=0:
		death_timer-=delta
		if death_timer<=0:
			queue_free()
		return
	if not is_instance_valid(player):
		return
	attack_timer=maxf(0,attack_timer-delta)
	var direction=signf(player.position.x-position.x)
	velocity.x=direction*(105 if kind=="wolf" else 60)
	velocity.y=minf(850,velocity.y+1500*delta)
	if is_on_wall() and is_on_floor():
		velocity.y=-430
	move_and_slide()
	sprite.flip_h=direction<0
	var distance=position.distance_to(player.position)
	if distance<48 and attack_timer<=0:
		attack_timer=1.1
		player.take_damage(damage)
	sprite.play("attack" if attack_timer>.75 else "walk")
	if distance>1800:
		queue_free()

func hit(amount: float) -> void:
	if death_timer>=0:
		return
	hp-=amount
	sprite.play("hurt")
	if hp<=0:
		death_timer=.45
		sprite.play("death")
		killed.emit()
