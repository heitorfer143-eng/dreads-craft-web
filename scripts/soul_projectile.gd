extends Node2D

var direction:=1
var speed:=620.0
var damage:=36.0
var max_distance:=576.0
var start_position:=Vector2.ZERO
var world:Node2D
var enemies:Node2D
var game:Node2D
var sprite:Sprite2D

func setup(p_direction:int,p_world:Node2D,p_enemies:Node2D,p_game:Node2D) -> void:
	direction=1 if p_direction>=0 else -1
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
	add_child(sprite)

func _process(delta:float) -> void:
	position.x+=direction*speed*delta
	if global_position.distance_to(start_position)>=max_distance:
		queue_free()
		return
	if is_instance_valid(world):
		var cell=Vector2i(global_position/32.0)
		if world.is_solid(cell):
			queue_free()
			return
	if not is_instance_valid(enemies):
		return
	for mob in enemies.get_children():
		if not is_instance_valid(mob) or not mob.has_method("hit"):
			continue
		var radius=88.0 if is_instance_valid(game) and is_instance_valid(game.boss) and mob==game.boss else 42.0
		if global_position.distance_to(mob.global_position)>radius:
			continue
		if is_instance_valid(game) and is_instance_valid(game.boss) and mob==game.boss:
			mob.hit(damage)
		else:
			mob.hit(damage,220.0)
		if is_instance_valid(game) and game.has_method("show_damage_popup"):
			game.show_damage_popup(mob.global_position,int(damage),false)
		queue_free()
		return
