extends Node2D

const SheetAssets=preload("res://scripts/generated_sheet_assets.gd")

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
	sprite.texture=SheetAssets.structure(kind)
	sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var desired_width=390.0 if kind=="blacksmith" else 410.0 if kind=="market" else 370.0
	var tex_size=sprite.texture.get_size()
	var factor=desired_width/maxf(1.0,tex_size.x)
	sprite.scale=Vector2(factor,factor)
	# Generated art is bottom-aligned to the terrain. No building geometry is drawn in code.
	sprite.position=Vector2(0,-tex_size.y*factor*0.5)
	add_child(sprite)
	z_index=1
	set_process(true)

func door_position() -> Vector2:
	var offset=Vector2.ZERO
	if kind=="blacksmith":
		offset=Vector2(82,-20)
	elif kind=="market":
		offset=Vector2(-72,-20)
	return global_position+offset

func is_near() -> bool:
	return is_instance_valid(player) and door_position().distance_to(player.global_position)<120.0

func interact() -> void:
	if is_instance_valid(game):
		game.enter_structure(kind,display_name)

func _process(_delta:float) -> void:
	queue_redraw()

func _draw() -> void:
	# Only an interaction hint is drawn; the building itself is the generated sprite.
	if not is_near():
		return
	var font=ThemeDB.fallback_font
	var box=Rect2(-88,-250,176,36)
	draw_rect(box,Color("0c0913e8"),true)
	draw_rect(box,Color("a9825d"),false,2)
	draw_string(font,Vector2(-82,-226),"FALAR / ENTRAR · "+display_name,HORIZONTAL_ALIGNMENT_CENTER,164,11,Color("f3dfc3"))
