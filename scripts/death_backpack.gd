extends Node2D

var contents:Dictionary={}
var player:CharacterBody2D
var game:Node
var scope:String="overworld"
var age:=0.0
var pickup_delay:=0.7

func setup(p_contents:Dictionary,p_player:CharacterBody2D,p_game:Node,p_scope:String) -> void:
	contents=p_contents.duplicate(true)
	player=p_player
	game=p_game
	scope=p_scope

func _ready() -> void:
	z_index=35
	queue_redraw()

func _process(delta:float) -> void:
	age+=delta
	pickup_delay=maxf(0.0,pickup_delay-delta)
	var same_scope=is_instance_valid(game) and game.has_method("current_death_scope") and game.current_death_scope()==scope
	visible=same_scope
	if not same_scope:
		return
	if pickup_delay<=0.0 and is_instance_valid(player) and global_position.distance_to(player.global_position)<48.0:
		try_collect()
	queue_redraw()

func try_collect() -> void:
	if not is_instance_valid(player) or contents.is_empty():
		return
	if is_instance_valid(game) and game.has_method("current_death_scope") and game.current_death_scope()!=scope:
		return
	for raw_id in contents:
		var item_id=int(raw_id)
		player.inventory[item_id]=int(player.inventory.get(item_id,0))+int(contents[raw_id])
	contents.clear()
	if is_instance_valid(game) and game.has_method("on_death_backpack_collected"):
		game.on_death_backpack_collected()
	queue_free()

func serialize() -> Dictionary:
	var saved:Dictionary={}
	for raw_id in contents:
		saved[str(int(raw_id))]=int(contents[raw_id])
	return {"contents":saved,"position":[position.x,position.y],"scope":scope}

func _draw() -> void:
	var bob=sin(age*3.4)*2.0
	var o=Vector2(0,bob)
	# Dark medieval backpack drawn directly by the game.
	draw_circle(o+Vector2(0,3),23,Color(0,0,0,0.24))
	draw_rect(Rect2(o+Vector2(-18,-27),Vector2(36,34)),Color("2a1918"))
	draw_rect(Rect2(o+Vector2(-15,-24),Vector2(30,28)),Color("6c3f2f"))
	draw_rect(Rect2(o+Vector2(-12,-20),Vector2(24,7)),Color("8c5b3d"))
	draw_rect(Rect2(o+Vector2(-11,-10),Vector2(22,3)),Color("342223"))
	draw_rect(Rect2(o+Vector2(-3,-15),Vector2(6,13)),Color("c38a47"))
	draw_rect(Rect2(o+Vector2(-15,4),Vector2(30,5)),Color("241718"))
	draw_arc(o+Vector2(0,-25),13,PI,TAU,20,Color("bd8d58"),3)
	draw_circle(o+Vector2(0,-7),2.5,Color("e3b45e"))
