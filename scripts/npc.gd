extends Area2D

signal interacted(npc)

var npc_name := "Aldeão"
var role := "aldeao"
var dialogue := ["Boa noite, viajante."]
var dialogue_index := 0
var player: CharacterBody2D
var accent := Color("b58b62")

func _ready() -> void:
	collision_layer=0
	collision_mask=0
	var shape=CollisionShape2D.new()
	var capsule=CapsuleShape2D.new()
	capsule.radius=16
	capsule.height=54
	shape.shape=capsule
	shape.position=Vector2(0,-26)
	add_child(shape)
	queue_redraw()

func setup(kind: String, display_name: String, lines: Array, target: CharacterBody2D) -> void:
	role=kind
	npc_name=display_name
	dialogue=lines
	player=target
	accent={
		"ferreiro":Color("c47b4e"),
		"mercador":Color("8e62b5"),
		"monge":Color("e2d8c2"),
		"cacador":Color("5f8b61"),
		"viajante":Color("6f526f"),
		"aldeao":Color("b58b62")
	}.get(role,Color("b58b62"))
	queue_redraw()

func can_interact() -> bool:
	return is_instance_valid(player) and global_position.distance_to(player.global_position)<105.0

func interact() -> void:
	if not can_interact():
		return
	interacted.emit(self)

func next_line() -> String:
	if dialogue.is_empty():
		return "..."
	var line=str(dialogue[dialogue_index%dialogue.size()])
	dialogue_index+=1
	return line

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	# Game-ready NPC silhouette rendered as an in-world character, with role-specific details.
	var near=can_interact()
	draw_circle(Vector2(0,-50),12,Color("d8b08c"))
	draw_rect(Rect2(-13,-38,26,34),accent)
	draw_rect(Rect2(-16,-7,11,8),Color("32252b"))
	draw_rect(Rect2(5,-7,11,8),Color("32252b"))
	draw_rect(Rect2(-16,-62,32,8),Color("241b25"))
	if role=="ferreiro":
		draw_rect(Rect2(-19,-38,7,30),Color("6f5545"))
		draw_line(Vector2(16,-30),Vector2(27,-10),Color("9ba0aa"),5)
	elif role=="mercador":
		draw_rect(Rect2(12,-37,12,26),Color("5a3e2d"))
		draw_circle(Vector2(18,-26),3,Color("ce5b76"))
	elif role=="monge":
		draw_rect(Rect2(-17,-39,34,36),Color("ddd7c9"))
		draw_line(Vector2(22,-48),Vector2(22,-5),Color("d2a84d"),3)
		draw_line(Vector2(16,-39),Vector2(28,-39),Color("d2a84d"),3)
	elif role=="cacador":
		draw_arc(Vector2(19,-27),13,-1.5,1.5,12,Color("8b603a"),3)
	elif role=="viajante":
		draw_circle(Vector2(0,-51),15,Color("201925"))
		draw_circle(Vector2(-5,-50),2,Color("df4d55"))
		draw_circle(Vector2(5,-50),2,Color("df4d55"))
	if near:
		draw_circle(Vector2(0,-82),12,Color("2b1838"))
		draw_string(ThemeDB.fallback_font,Vector2(-4,-77),"!",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("f3d77d"))
