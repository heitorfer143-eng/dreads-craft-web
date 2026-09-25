extends Node2D

var direction:=Vector2.RIGHT
var speed:=620.0
var damage:=36.0
var max_distance:=576.0
var start_position:=Vector2.ZERO
var world:Node2D
var enemies:Node2D
var game:Node2D
var sprite:Sprite2D

func setup(p_direction:Vector2,p_world:Node2D,p_enemies:Node2D,p_game:Node2D) -> void:
	direction=p_direction.normalized()
	if direction.length_squared()<0.01:
		direction=Vector2.RIGHT
	world=p_world
	enemies=p_enemies
	game=p_game

func _ready() -> void:
	start_position=global_position
	sprite=Sprite2D.new()
	sprite.texture=load("res://assets/items/soul_ore.svg")
	sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale=Vector2(0.42,0.42)
	sprite.modulate=Color("dff8ff")
	sprite.rotation=direction.angle()
	add_child(sprite)

func _process(delta:float) -> void:
	position+=direction*speed*delta
	if global_position.distance_to(start_position)>=max_distance:
		queue_free()
		return

	# The lake temple is a separate arena while 'world' still references the hidden
	# overworld. Checking overworld blocks here used to delete the orb instantly.
	var in_lake_arena=is_instance_valid(game) and bool(game.in_lake_temple)
	if is_instance_valid(world) and not in_lake_arena:
		var cell=Vector2i(global_position/32.0)
		if world.is_solid(cell):
			queue_free()
			return

	if not is_instance_valid(enemies):
		return
	for mob in enemies.get_children():
		if not is_instance_valid(mob) or not mob.has_method("hit"):
			continue
		var is_purity_boss=is_instance_valid(game) and is_instance_valid(game.boss) and mob==game.boss
		var is_lake_boss=is_instance_valid(game) and is_instance_valid(game.lake_boss) and mob==game.lake_boss
		var radius=132.0 if is_lake_boss else 88.0 if is_purity_boss else 42.0
		if global_position.distance_to(mob.global_position)>radius:
			continue
		# Both bosses expose hit(amount). Normal mobs expose hit(amount, knockback).
		if is_purity_boss or is_lake_boss:
			mob.hit(damage)
		else:
			mob.hit(damage,220.0)
		if is_instance_valid(game) and game.has_method("show_damage_popup"):
			game.show_damage_popup(mob.global_position,int(damage),false)
		queue_free()
		return
