extends Node2D

var kind="blacksmith"
var display_name="Interior"
var exit_position=Vector2(105,594)
var background: Sprite2D

func configure(p_kind:String,p_name:String) -> void:
	kind=p_kind
	display_name=p_name

func _ready() -> void:
	z_index=-10
	background=Sprite2D.new()
	# BUILD 14.0: the visible rooms use the generated/remodeled PNG artwork.
	# The files are 16:9 pixel-art backgrounds and are scaled with NEAREST so
	# they remain crisp on Web and Android landscape.
	var interior_path="res://assets/interiors/%s.png" % kind
	var fallback_path="res://assets/interiors/%s.svg" % kind
	if ResourceLoader.exists(interior_path):
		background.texture=load(interior_path)
	elif ResourceLoader.exists(fallback_path):
		background.texture=load(fallback_path)
	else:
		background.texture=load("res://assets/backgrounds/dark_castles_generated.png")
	background.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	background.position=Vector2(640,360)
	var ts=background.texture.get_size()
	background.scale=Vector2(1280.0/maxf(1.0,ts.x),720.0/maxf(1.0,ts.y))
	background.z_index=-10
	add_child(background)

	# Invisible collision follows the floor line in the new artwork.
	# Keeping collisions separate from the image means the art can be swapped
	# without hiding the player or breaking the exit.
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
