extends Node2D

var kind="blacksmith"
var display_name="Interior"
var exit_position=Vector2(110,600)

func configure(p_kind:String,p_name:String) -> void:
	kind=p_kind
	display_name=p_name

func add_prop(path:String,pos:Vector2,scale_value:float=1.0,modulate_color:Color=Color.WHITE) -> void:
	if not ResourceLoader.exists(path):
		return
	var sprite=Sprite2D.new()
	sprite.texture=load(path)
	sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position=pos
	sprite.scale=Vector2(scale_value,scale_value)
	sprite.modulate=modulate_color
	sprite.z_index=-1
	add_child(sprite)

func _ready() -> void:
	# Reuse the generated dark-fantasy artwork as a real image backdrop instead
	# of the old flat placeholder SVG interiors.
	var bg=Sprite2D.new()
	bg.texture=load("res://assets/backgrounds/dark_castles_generated.png")
	bg.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	bg.position=Vector2(640,360)
	bg.scale=Vector2(8.0,8.0)
	bg.modulate=Color(0.34,0.27,0.38,0.72)
	bg.z_index=-10
	add_child(bg)

	# Existing game artwork becomes room decoration, so interiors feel like
	# actual places while keeping entry/exit as the only mechanic.
	if kind=="blacksmith":
		add_prop("res://assets/items/table.png",Vector2(820,548),2.8)
		add_prop("res://assets/items/iron.png",Vector2(750,470),2.1)
		add_prop("res://assets/items/coal.png",Vector2(875,472),2.0)
		add_prop("res://assets/items/generated/sword_iron.png",Vector2(1010,420),1.55)
		add_prop("res://assets/items/generated/pickaxe_iron.png",Vector2(1090,425),1.55)
	elif kind=="market":
		add_prop("res://assets/items/table.png",Vector2(800,550),2.5)
		add_prop("res://assets/items/planks.png",Vector2(690,470),1.8)
		add_prop("res://assets/items/meat.png",Vector2(790,465),1.8)
		add_prop("res://assets/items/diamond.png",Vector2(890,465),1.8)
		add_prop("res://assets/items/backpack.png",Vector2(1030,455),1.6)
	else:
		add_prop("res://assets/npcs/monk_generated.png",Vector2(920,520),0.52)
		add_prop("res://assets/items/relic_vital.svg",Vector2(640,400),1.8)

	var floor_body=StaticBody2D.new()
	floor_body.collision_layer=1
	var floor_shape=RectangleShape2D.new()
	floor_shape.size=Vector2(1280,46)
	var floor_col=CollisionShape2D.new()
	floor_col.shape=floor_shape
	floor_col.position=Vector2(640,648)
	floor_body.add_child(floor_col)
	for x in [10,1270]:
		var wall_shape=RectangleShape2D.new()
		wall_shape.size=Vector2(30,720)
		var wall_col=CollisionShape2D.new()
		wall_col.shape=wall_shape
		wall_col.position=Vector2(x,360)
		floor_body.add_child(wall_col)
	add_child(floor_body)
	queue_redraw()

func _draw() -> void:
	# Dark timber frame and warm floor over the image backdrop.
	draw_rect(Rect2(0,0,1280,112),Color("0b0913e8"),true)
	draw_rect(Rect2(0,112,1280,18),Color("7a4f35"),true)
	draw_rect(Rect2(0,610,1280,110),Color("21151ae8"),true)
	for x in range(0,1280,96):
		draw_rect(Rect2(x,610,5,110),Color("68452f"),true)
	draw_rect(Rect2(0,610,1280,7),Color("a5754b"),true)

	# Timber columns keep the room readable without hiding the generated background.
	for x in [250,560,960,1190]:
		draw_rect(Rect2(x,145,14,465),Color("513423d9"),true)
		draw_rect(Rect2(x+3,145,4,465),Color("8a5a36cc"),true)

	# Exit door at the left.
	draw_rect(Rect2(46,432,142,178),Color("100b12f2"),true)
	draw_rect(Rect2(46,432,142,178),Color("b98956"),false,5)
	draw_rect(Rect2(70,465,94,145),Color("3d261f"),true)
	draw_circle(Vector2(145,535),6,Color("d9b46a"))

	# Role-specific focal furniture/signage.
	if kind=="blacksmith":
		draw_rect(Rect2(690,510,390,100),Color("38231ee8"),true)
		draw_rect(Rect2(690,510,390,9),Color("a56b3f"),true)
		draw_rect(Rect2(355,445,155,165),Color("2b1715e8"),true)
		draw_circle(Vector2(432,500),58,Color("e16b2c55"))
		draw_circle(Vector2(432,500),34,Color("ffb24a99"))
	elif kind=="market":
		draw_rect(Rect2(610,500,455,110),Color("432d25e8"),true)
		draw_rect(Rect2(610,500,455,10),Color("b17c4f"),true)
		for x in [650,760,870,980]:
			draw_rect(Rect2(x,315,72,110),Color("281923cc"),true)
			draw_rect(Rect2(x,315,72,5),Color("9e744e"),true)
	else:
		draw_rect(Rect2(500,250,280,360),Color("191827dd"),true)
		draw_arc(Vector2(640,330),118,PI,TAU,40,Color("c7ad78"),8)
		draw_line(Vector2(640,315),Vector2(640,445),Color("d6b657"),12)
		draw_line(Vector2(585,365),Vector2(695,365),Color("d6b657"),12)
		for x in [300,430,850,980]:
			draw_rect(Rect2(x,525,95,28),Color("654630"),true)

	var font=ThemeDB.fallback_font
	draw_string(font,Vector2(52,405),display_name.to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("f3dfc2"))
	draw_string(font,Vector2(67,454),"SAÍDA",HORIZONTAL_ALIGNMENT_CENTER,100,13,Color("e7c98e"))
	draw_string(font,Vector2(64,585),"FALAR / ENTRAR",HORIZONTAL_ALIGNMENT_CENTER,108,10,Color("c8b5a2"))
