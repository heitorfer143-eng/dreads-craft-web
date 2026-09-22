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
	sprite.scale=Vector2(1.55,1.55)
	sprite.position=Vector2(0,-124)
	add_child(sprite)
	z_index=1
	set_process(true)

func door_position() -> Vector2:
	return global_position+Vector2(0,-20)

func is_near() -> bool:
	return is_instance_valid(player) and door_position().distance_to(player.global_position)<110.0

func interact() -> void:
	if is_instance_valid(game):
		game.enter_structure(kind,display_name)

func _process(_delta:float) -> void:
	queue_redraw()

func _draw() -> void:
	if not is_near():
		return
	var font=ThemeDB.fallback_font
	var box=Rect2(-76,-236,152,34)
	draw_rect(box,Color("0c0913e8"),true)
	draw_rect(box,Color("a9825d"),false,2)
	draw_string(font,Vector2(-70,-214),"INTERAGIR · "+display_name,HORIZONTAL_ALIGNMENT_CENTER,140,11,Color("f3dfc3"))
