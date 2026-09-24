extends Node2D

var kind="blacksmith"
var display_name="Interior"
var exit_position=Vector2(110,600)

func configure(p_kind:String,p_name:String) -> void:
	kind=p_kind
	display_name=p_name

func add_prop(path:String,pos:Vector2,scale_value:float=1.0,z:int=-1,modulate_color:Color=Color.WHITE) -> void:
	if not ResourceLoader.exists(path):
		return
	var sprite=Sprite2D.new()
	sprite.texture=load(path)
	sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position=pos
	sprite.scale=Vector2(scale_value,scale_value)
	sprite.z_index=z
	sprite.modulate=modulate_color
	add_child(sprite)

func _ready() -> void:
	z_index=-10

	# Controlled decoration: no giant image covering the player.
	if kind=="blacksmith":
		add_prop("res://assets/items/generated/sword_iron.png",Vector2(900,305),0.95)
		add_prop("res://assets/items/generated/pickaxe_iron.png",Vector2(1010,305),0.95)
		add_prop("res://assets/npcs/blacksmith_generated.png",Vector2(965,514),0.56)
	elif kind in ["market","shop"]:
		add_prop("res://assets/items/meat.png",Vector2(700,500),1.0)
		add_prop("res://assets/items/coal.png",Vector2(780,500),1.0)
		add_prop("res://assets/items/iron.png",Vector2(860,500),1.0)
		add_prop("res://assets/items/item_14.svg",Vector2(940,500),0.9)
		add_prop("res://assets/npcs/blacksmith_generated.png",Vector2(1015,508),0.50)
	else:
		add_prop("res://assets/npcs/monk_generated.png",Vector2(930,510),0.48)
		add_prop("res://assets/items/relic_vital.svg",Vector2(640,360),1.0)

	var body=StaticBody2D.new()
	body.collision_layer=1
	var floor_shape=RectangleShape2D.new()
	floor_shape.size=Vector2(1280,44)
	var floor_col=CollisionShape2D.new()
	floor_col.shape=floor_shape
	floor_col.position=Vector2(640,648)
	body.add_child(floor_col)

	for x in [12.0,1268.0]:
		var wall_shape=RectangleShape2D.new()
		wall_shape.size=Vector2(24,720)
		var wall_col=CollisionShape2D.new()
		wall_col.shape=wall_shape
		wall_col.position=Vector2(x,360)
		body.add_child(wall_col)
	add_child(body)
	queue_redraw()

func beam(rect:Rect2) -> void:
	draw_rect(rect,Color("3d281f"),true)
	draw_rect(Rect2(rect.position+Vector2(3,3),Vector2(maxf(0,rect.size.x-6),3)),Color("795238"),true)

func shelf(x:float,y:float,w:float) -> void:
	draw_rect(Rect2(x,y,w,12),Color("8a5e3e"),true)
	draw_rect(Rect2(x+8,y+12,10,72),Color("4a3024"),true)
	draw_rect(Rect2(x+w-18,y+12,10,72),Color("4a3024"),true)

func _draw() -> void:
	# Room shell.
	draw_rect(Rect2(0,0,1280,720),Color("09070d"),true)
	draw_rect(Rect2(22,82,1236,516),Color("211822"),true)
	draw_rect(Rect2(22,82,1236,516),Color("8c6848"),false,6)
	beam(Rect2(22,105,1236,18))
	beam(Rect2(22,568,1236,18))
	for x in [255.0,520.0,790.0,1055.0]:
		beam(Rect2(x,105,16,463))

	# Floor.
	draw_rect(Rect2(0,586,1280,134),Color("201319"),true)
	for y in range(590,720,26):
		draw_rect(Rect2(0,y,1280,2),Color("67432f"),true)
	for x in range(0,1280,128):
		draw_rect(Rect2(x,586,3,134),Color("4c3024"),true)

	# Exit door at the left.
	draw_rect(Rect2(45,360,170,226),Color("0c0910"),true)
	draw_rect(Rect2(45,360,170,226),Color("b88c5d"),false,5)
	draw_rect(Rect2(73,402,114,184),Color("442b22"),true)
	draw_rect(Rect2(84,415,92,162),Color("301d19"),true)
	draw_circle(Vector2(158,505),6,Color("e8c978"))
	draw_string(ThemeDB.fallback_font,Vector2(72,392),"SAÍDA",HORIZONTAL_ALIGNMENT_CENTER,116,14,Color("f1d8af"))

	if kind=="blacksmith":
		# Forge left-center, workbench right.
		draw_rect(Rect2(310,406,205,162),Color("2a1a18"),true)
		draw_rect(Rect2(330,435,165,133),Color("563024"),true)
		draw_circle(Vector2(412,514),48,Color("b54024"))
		draw_circle(Vector2(412,514),27,Color("ffad42"))
		draw_rect(Rect2(640,492,450,76),Color("402a22"),true)
		draw_rect(Rect2(640,492,450,9),Color("a96f46"),true)
		shelf(840,230,250)
		draw_string(ThemeDB.fallback_font,Vector2(655,480),"BANCADA DE BORIN",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("efca91"))
	elif kind in ["market","shop"]:
		# Proper shop interior with clear counter/interact zone.
		shelf(300,245,260)
		shelf(620,245,310)
		draw_rect(Rect2(610,470,540,98),Color("3c2821"),true)
		draw_rect(Rect2(610,470,540,10),Color("b47b4c"),true)
		draw_rect(Rect2(960,208,180,205),Color("2b1d19"),true)
		for y in [235,295,355]:
			draw_rect(Rect2(976,y,148,9),Color("8a5c3c"),true)
		draw_string(ThemeDB.fallback_font,Vector2(760,450),"LOJA · TROCAS",HORIZONTAL_ALIGNMENT_CENTER,300,18,Color("f1d49d"))
		draw_string(ThemeDB.fallback_font,Vector2(750,548),"FALAR / ENTRAR para negociar",HORIZONTAL_ALIGNMENT_CENTER,340,13,Color("cfbca9"))
	else:
		# Chapel.
		draw_rect(Rect2(515,432,260,136),Color("2d2838"),true)
		draw_rect(Rect2(535,452,220,116),Color("584a64"),true)
		draw_arc(Vector2(645,324),118,PI,TAU,32,Color("c7ad77"),8)
		draw_line(Vector2(645,295),Vector2(645,415),Color("ddb959"),11)
		draw_line(Vector2(595,340),Vector2(695,340),Color("ddb959"),11)
		for x in [300.0,430.0,840.0,970.0]:
			draw_rect(Rect2(x,520,105,28),Color("654630"),true)

	draw_string(ThemeDB.fallback_font,Vector2(260,150),display_name.to_upper(),HORIZONTAL_ALIGNMENT_CENTER,760,24,Color("f0dfc8"))
