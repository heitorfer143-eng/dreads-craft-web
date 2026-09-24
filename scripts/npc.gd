extends Area2D

signal interacted(npc)

var npc_name := "Borin, o Ferreiro"
var role := "ferreiro"
var dialogue := ["Se quer descer fundo, não economize na picareta.","A bancada daqui está à sua disposição."]
var dialogue_index := 0
var player: CharacterBody2D
var sprite: Sprite2D
var quest_marker := ""
var visual_height := 86.0

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
	visual_height=94.0 if role=="monge" else 86.0
	if sprite.texture!=null:
		var tex_size=sprite.texture.get_size()
		var fit=visual_height/maxf(1.0,tex_size.y)
		sprite.scale=Vector2(fit,fit)
	sprite.position=Vector2(0,-visual_height*0.5)
	sprite.z_index=5
	add_child(sprite)
	z_index=6
	set_process(true)

func set_quest_marker(value:String) -> void:
	quest_marker=value if value in ["!","?"] else ""
	queue_redraw()

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

func draw_ellipse_shadow(center:Vector2,radius:Vector2,color:Color) -> void:
	var points=PackedVector2Array()
	for i in range(20):
		var angle=TAU*float(i)/20.0
		points.append(center+Vector2(cos(angle)*radius.x,sin(angle)*radius.y))
	draw_colored_polygon(points,color)

func _draw() -> void:
	# Grounding shadow + normalized feet position removes the "pasted PNG" look.
	draw_ellipse_shadow(Vector2(0,-2),Vector2(21,6),Color(0,0,0,.30))
	if quest_marker=="":
		return
	var y=-visual_height-22.0
	var marker_color=Color("e5b66f") if quest_marker=="!" else Color("9fe7b2")
	draw_circle(Vector2(0,y),15,Color("18121ff0"))
	draw_arc(Vector2(0,y),15,0,TAU,24,marker_color,2)
	draw_string(ThemeDB.fallback_font,Vector2(-5,y+6),quest_marker,HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("fff1df"))
