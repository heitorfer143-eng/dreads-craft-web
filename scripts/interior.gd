extends Node2D

var kind="blacksmith"
var display_name="Interior"
var exit_position=Vector2(110,600)

func configure(p_kind:String,p_name:String) -> void:
	kind=p_kind
	display_name=p_name

func add_prop(path:String,pos:Vector2,scale_value:float=1.0,modulate_color:Color=Color.WHITE,z:int=-1) -> void:
	if not ResourceLoader.exists(path):
		return
	var sprite=Sprite2D.new()
	sprite.texture=load(path)
	sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position=pos
	sprite.scale=Vector2(scale_value,scale_value)
	sprite.modulate=modulate_color
	sprite.z_index=z
	add_child(sprite)

func _ready() -> void:
	# Full-room image backdrop fitted to 1280x720. No huge hard-coded image scale.
	if ResourceLoader.exists("res://assets/backgrounds/dark_castles_generated.png"):
		var bg=Sprite2D.new()
		bg.texture=load("res://assets/backgrounds/dark_castles_generated.png")
		bg.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
		var tex_size=bg.texture.get_size()
		bg.position=Vector2(640,360)
		bg.scale=Vector2(1280.0/maxf(1.0,tex_size.x),720.0/maxf(1.0,tex_size.y))
		bg.modulate=Color(0.23,0.18,0.28,0.55)
		bg.z_index=-20
		add_child(bg)

	# Small, controlled props. They decorate instead of covering the room.
	if kind=="blacksmith":
		add_prop("res://assets/items/generated/sword_iron.png",Vector2(925,322),0.90)
		add_prop("res://assets/items/generated/pickaxe_iron.png",Vector2(1035,322),0.90)
		add_prop("res://assets/items/iron.png",Vector2(855,520),1.25)
		add_prop("res://assets/items/coal.png",Vector2(955,520),1.25)
	elif kind=="market":
		add_prop("res://assets/items/planks.png",Vector2(735,500),1.25)
		add_prop("res://assets/items/meat.png",Vector2(835,500),1.25)
		add_prop("res://assets/items/diamond.png",Vector2(935,500),1.25)
		add_prop("res://assets/items/backpack.png",Vector2(1035,492),1.15)
	else:
		add_prop("res://assets/npcs/monk_generated.png",Vector2(965,520),0.34)
		add_prop("res://assets/items/relic_vital.svg",Vector2(640,388),1.05)

	var floor_body=StaticBody2D.new()
	floor_body.collision_layer=1
	var floor_shape=RectangleShape2D.new()
	floor_shape.size=Vector2(1280,42)
	var floor_col=CollisionShape2D.new()
	floor_col.shape=floor_shape
	floor_col.position=Vector2(640,648)
	floor_body.add_child(floor_col)
	for x in [10,1270]:
		var wall_shape=RectangleShape2D.new()
		wall_shape.size=Vector2(28,720)
		var wall_col=CollisionShape2D.new()
		wall_col.shape=wall_shape
		wall_col.position=Vector2(x,360)
		floor_body.add_child(wall_col)
	add_child(floor_body)
	queue_redraw()

func draw_beam(x:float,y:float,w:float,h:float) -> void:
	draw_rect(Rect2(x,y,w,h),Color("3b271f"),true)
	draw_rect(Rect2(x+3,y+2,maxf(0,w-6),3),Color("7a5137"),true)

func draw_shelf(x:float,y:float,w:float) -> void:
	draw_rect(Rect2(x,y,w,12),Color("76503a"),true)
	draw_rect(Rect2(x+8,y+12,10,80),Color("493027"),true)
	draw_rect(Rect2(x+w-18,y+12,10,80),Color("493027"),true)

func _draw() -> void:
	# Coherent room shell.
	draw_rect(Rect2(0,0,1280,720),Color("0b0910b8"),true)
	draw_rect(Rect2(26,88,1228,500),Color("201821e8"),true)
	draw_rect(Rect2(26,88,1228,500),Color("735441"),false,6)
	draw_beam(26,118,1228,18)
	draw_beam(26,560,1228,18)
	for x in [250.0,520.0,790.0,1060.0]:
		draw_beam(x,118,16,442)

	# Warm wooden floor.
	draw_rect(Rect2(0,578,1280,142),Color("201419"),true)
	for y in range(590,720,28):
		draw_rect(Rect2(0,y,1280,3),Color("664531"),true)
	for x in range(0,1280,128):
		draw_rect(Rect2(x,578,3,142),Color("513526"),true)

	# Exit door is always obvious and never covered.
	draw_rect(Rect2(52,392,150,186),Color("100b12"),true)
	draw_rect(Rect2(52,392,150,186),Color("b78a5b"),false,5)
	draw_rect(Rect2(75,422,104,156),Color("4b2e24"),true)
	draw_rect(Rect2(84,432,86,137),Color("38221c"),true)
	draw_circle(Vector2(155,500),6,Color("e2bf72"))
	draw_rect(Rect2(63,360,128,28),Color("17101aeb"),true)

	if kind=="blacksmith":
		# Forge + workbench + weapon display.
		draw_rect(Rect2(340,408,180,170),Color("251718"),true)
		draw_rect(Rect2(356,440,148,138),Color("4c2b22"),true)
		draw_circle(Vector2(430,520),52,Color("a43b2490"))
		draw_circle(Vector2(430,520),30,Color("ff9b3ec0"))
		draw_rect(Rect2(700,500,430,78),Color("3b2720"),true)
		draw_rect(Rect2(700,500,430,9),Color("a56f47"),true)
		draw_shelf(850,250,250)
	elif kind=="market":
		# Two clean shelves and a counter.
		draw_shelf(330,290,260)
		draw_shelf(690,290,360)
		draw_rect(Rect2(640,490,500,88),Color("3d2922"),true)
		draw_rect(Rect2(640,490,500,10),Color("b07b4e"),true)
		draw_rect(Rect2(1110,205,90,255),Color("34221e"),true)
		for y in [235,300,365]:
			draw_rect(Rect2(1120,y,70,9),Color("8a5e3d"),true)
	else:
		# Chapel: central altar, arch and benches.
		draw_rect(Rect2(520,430,250,148),Color("272433"),true)
		draw_rect(Rect2(540,450,210,128),Color("54465f"),true)
		draw_arc(Vector2(645,330),120,PI,TAU,32,Color("c3ae7b"),8)
		draw_line(Vector2(645,300),Vector2(645,420),Color("d8ba5b"),11)
		draw_line(Vector2(595,342),Vector2(695,342),Color("d8ba5b"),11)
		for x in [300.0,430.0,840.0,970.0]:
			draw_rect(Rect2(x,520,105,28),Color("654630"),true)
			draw_rect(Rect2(x+10,548,12,30),Color("463023"),true)
			draw_rect(Rect2(x+83,548,12,30),Color("463023"),true)

	var font=ThemeDB.fallback_font
	draw_string(font,Vector2(70,380),display_name.to_upper(),HORIZONTAL_ALIGNMENT_CENTER,114,16,Color("f0d8b7"))
	draw_string(font,Vector2(76,455),"PORTA",HORIZONTAL_ALIGNMENT_CENTER,100,12,Color("e7c98e"))
	draw_string(font,Vector2(73,548),"FALAR / ENTRAR",HORIZONTAL_ALIGNMENT_CENTER,108,9,Color("c8b5a2"))
