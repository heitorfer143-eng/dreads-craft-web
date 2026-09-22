extends Area2D

signal interacted(npc)

var npc_name := "Borin, o Ferreiro"
var role := "ferreiro"
var dialogue := ["Se quer descer fundo, não economize na picareta.","A bancada daqui está à sua disposição."]
var dialogue_index := 0
var player: CharacterBody2D
var sprite: Sprite2D

func setup(kind: String, display_name: String, lines: Array, target: CharacterBody2D) -> void:
	role=kind
	npc_name=display_name
	dialogue=lines
	player=target

func _ready() -> void:
	collision_layer=0
	collision_mask=0
	var shape=CollisionShape2D.new()
	var capsule=CapsuleShape2D.new()
	capsule.radius=18
	capsule.height=62
	shape.shape=capsule
	shape.position=Vector2(0,-30)
	add_child(shape)

	sprite=Sprite2D.new()
	var sprite_path="res://assets/npcs/monk_generated.png" if role=="monge" else "res://assets/npcs/blacksmith_generated.png"
	sprite.texture=load(sprite_path)
	sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale=Vector2(0.72,0.72)
	sprite.position=Vector2(0,-35)
	sprite.z_index=5
	add_child(sprite)
	set_process(true)

func can_interact() -> bool:
	return is_instance_valid(player) and global_position.distance_to(player.global_position)<120.0

func interact() -> void:
	if can_interact():
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
	if not can_interact():
		return
	var y=-116.0
	draw_circle(Vector2(0,y),16,Color("18121fe8"))
	draw_arc(Vector2(0,y),16,0,TAU,24,Color("e5b66f"),2)
	draw_string(ThemeDB.fallback_font,Vector2(-8,y+6),"!",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("ffe7a3"))
