extends Node2D

var kind="blacksmith"
var display_name="Interior"
var exit_position=Vector2(105,594)
var background: Sprite2D

func configure(p_kind:String,p_name:String) -> void:
	kind=p_kind
	display_name=p_name

func _load_background_texture() -> Texture2D:
	var png_path="res://assets/interiors/%s.png" % kind
	var svg_path="res://assets/interiors/%s.svg" % kind
	var emergency_path="res://assets/backgrounds/dark_castles_generated.png"

	# A file can exist but still fail Godot import (the previous chapel PNG did).
	# Never assume ResourceLoader.exists() means load() returned a usable texture.
	var tex: Texture2D=null
	if ResourceLoader.exists(png_path):
		tex=load(png_path) as Texture2D
	if tex==null and ResourceLoader.exists(svg_path):
		tex=load(svg_path) as Texture2D
	if tex==null and ResourceLoader.exists(emergency_path):
		tex=load(emergency_path) as Texture2D
	return tex

func _ready() -> void:
	# Keep the room in the same world canvas as the player, but behind every
	# interactive object. z_as_relative=false avoids double-negative child Z.
	z_index=0
	background=Sprite2D.new()
	background.z_as_relative=false
	background.z_index=-20
	background.texture=_load_background_texture()
	background.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	background.position=Vector2(640,360)

	if background.texture!=null:
		var ts=background.texture.get_size()
		background.scale=Vector2(1280.0/maxf(1.0,ts.x),720.0/maxf(1.0,ts.y))
		add_child(background)
	else:
		# Last-resort visual instead of a black screen if every asset fails.
		var fallback=Polygon2D.new()
		fallback.polygon=PackedVector2Array([
			Vector2(0,0),Vector2(1280,0),Vector2(1280,720),Vector2(0,720)
		])
		fallback.color=Color("221a2a")
		fallback.z_index=-20
		add_child(fallback)

	var body=StaticBody2D.new()
	body.collision_layer=1

	var floor_shape=RectangleShape2D.new()
	floor_shape.size=Vector2(1280,32)
	var floor_col=CollisionShape2D.new()
	floor_col.shape=floor_shape
	floor_col.position=Vector2(640,610)
	body.add_child(floor_col)

	for x in [12.0,1268.0]:
		var wall_shape=RectangleShape2D.new()
		wall_shape.size=Vector2(24,720)
		var wall_col=CollisionShape2D.new()
		wall_col.shape=wall_shape
		wall_col.position=Vector2(x,360)
		body.add_child(wall_col)

	add_child(body)
