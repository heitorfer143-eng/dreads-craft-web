extends Node2D

var kind="blacksmith"
var display_name="Interior"
var exit_position=Vector2(110,600)

func configure(p_kind:String,p_name:String) -> void:
	kind=p_kind
	display_name=p_name

func _ready() -> void:
	var paths={
		"blacksmith":"res://assets/interiors/blacksmith.svg",
		"market":"res://assets/interiors/market.svg",
		"chapel":"res://assets/interiors/chapel.svg"
	}
	var sprite=Sprite2D.new()
	sprite.texture=load(paths.get(kind,paths["blacksmith"]))
	sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position=Vector2(640,360)
	sprite.z_index=-2
	add_child(sprite)

	var floor_body=StaticBody2D.new()
	floor_body.collision_layer=1
	var floor_shape=RectangleShape2D.new()
	floor_shape.size=Vector2(1280,40)
	var floor_col=CollisionShape2D.new()
	floor_col.shape=floor_shape
	floor_col.position=Vector2(640,650)
	floor_body.add_child(floor_col)
	add_child(floor_body)
	for x in [10,1270]:
		var wall_shape=RectangleShape2D.new()
		wall_shape.size=Vector2(30,720)
		var wall_col=CollisionShape2D.new()
		wall_col.shape=wall_shape
		wall_col.position=Vector2(x,360)
		floor_body.add_child(wall_col)
	queue_redraw()

func _draw() -> void:
	var font=ThemeDB.fallback_font
	draw_rect(Rect2(54,545,118,66),Color("0b0811d8"),true)
	draw_rect(Rect2(54,545,118,66),Color("bd8e59"),false,2)
	draw_string(font,Vector2(62,570),"PORTA",HORIZONTAL_ALIGNMENT_CENTER,102,15,Color("f5dfc1"))
	draw_string(font,Vector2(62,594),"INTERAGIR",HORIZONTAL_ALIGNMENT_CENTER,102,11,Color("c9af93"))
