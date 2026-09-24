extends Node2D

var kind="blacksmith"
var display_name="Ferreiro"
var texture_path=""
var player: CharacterBody2D
var game: Node2D
var sprite: Sprite2D

func configure(p_kind:String,p_name:String,p_texture:String,p_player:CharacterBody2D,p_game:Node2D) -> void:
	kind=p_kind
	display_name=p_name
	texture_path=p_texture
	player=p_player
	game=p_game

func _ready() -> void:
	sprite=Sprite2D.new()
	sprite.texture=load(texture_path)
	sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	# Slightly larger than before so the new pixel-art details survive phone scaling.
	var desired_width=304.0 if kind=="blacksmith" else 318.0 if kind=="market" else 318.0
	var tex_size=sprite.texture.get_size()
	var factor=desired_width/maxf(1.0,tex_size.x)
	sprite.scale=Vector2(factor,factor)
	sprite.position=Vector2(0,-tex_size.y*factor*0.5)
	add_child(sprite)
	z_index=1
	set_process(true)

func door_position() -> Vector2:
	var offset=Vector2.ZERO
	if kind=="blacksmith":
		offset=Vector2(72,-20)
	elif kind=="market":
		offset=Vector2(-70,-20)
	return global_position+offset

func is_near() -> bool:
	return is_instance_valid(player) and door_position().distance_to(player.global_position)<120.0

func interact() -> void:
	if is_instance_valid(game):
		game.enter_structure(kind,display_name)

func _process(_delta:float) -> void:
	queue_redraw()

func _draw() -> void:
	# Small grounding shadow makes buildings sit in the world instead of floating.
	draw_ellipse_shadow(Vector2(0,-5),Vector2(132,13),Color(0,0,0,0.28))
	if not is_near():
		return
	var font=ThemeDB.fallback_font
	var box=Rect2(-92,-218,184,32)
	draw_rect(box,Color("0c0913dc"),true)
	draw_rect(box,Color("a9825d"),false,2)
	draw_string(font,Vector2(-86,-196),"FALAR / ENTRAR · "+display_name,HORIZONTAL_ALIGNMENT_CENTER,172,10,Color("f3dfc3"))

func draw_ellipse_shadow(center:Vector2,radius:Vector2,color:Color) -> void:
	var points=PackedVector2Array()
	for i in range(24):
		var angle=TAU*float(i)/24.0
		points.append(center+Vector2(cos(angle)*radius.x,sin(angle)*radius.y))
	draw_colored_polygon(points,color)
