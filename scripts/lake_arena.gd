extends Node2D

var world_seed := 1
var arena_size := Vector2(1680,960)
var floor_y := 850.0
var water_top := 500.0
var spawn_position := Vector2(190,812)
var exit_position := Vector2(108,810)
var boss_position := Vector2(1180,852)

func _ready() -> void:
	z_index=-8
	var body=StaticBody2D.new()
	body.collision_layer=1
	body.collision_mask=0
	var floor_shape=RectangleShape2D.new()
	floor_shape.size=Vector2(arena_size.x,32)
	var floor=CollisionShape2D.new()
	floor.shape=floor_shape
	floor.position=Vector2(arena_size.x*0.5,floor_y+16)
	body.add_child(floor)
	for x in [12.0,arena_size.x-12.0]:
		var wall_shape=RectangleShape2D.new()
		wall_shape.size=Vector2(24,arena_size.y)
		var wall=CollisionShape2D.new()
		wall.shape=wall_shape
		wall.position=Vector2(x,arena_size.y*0.5)
		body.add_child(wall)
	_add_platform(body,Vector2(410,735),Vector2(220,22))
	_add_platform(body,Vector2(1510,720),Vector2(190,22))
	add_child(body)
	queue_redraw()

func _add_platform(body:StaticBody2D,center:Vector2,size:Vector2) -> void:
	var shape=RectangleShape2D.new()
	shape.size=size
	var collider=CollisionShape2D.new()
	collider.shape=shape
	collider.position=center+Vector2(0,size.y*0.5)
	body.add_child(collider)

func is_in_water(pos:Vector2) -> bool:
	return pos.y>=water_top-14.0 and pos.y<=floor_y+10.0

func _process(_delta:float) -> void:
	queue_redraw()

func _stone(rect:Rect2,base:Color=Color("242a3b"),edge:Color=Color("3c465d")) -> void:
	draw_rect(rect,base)
	draw_rect(Rect2(rect.position,Vector2(rect.size.x,4)),edge)
	draw_rect(Rect2(rect.position,Vector2(4,rect.size.y)),Color(edge.r*0.72,edge.g*0.72,edge.b*0.72,1.0))

func _trident(center:Vector2,scale:float,color:Color) -> void:
	var w=maxf(2.0,4.0*scale)
	draw_line(center+Vector2(0,38)*scale,center+Vector2(0,-35)*scale,color,w)
	draw_line(center+Vector2(0,-12)*scale,center+Vector2(-22,-28)*scale,color,w)
	draw_line(center+Vector2(-22,-28)*scale,center+Vector2(-22,-10)*scale,color,w)
	draw_line(center+Vector2(0,-12)*scale,center+Vector2(22,-28)*scale,color,w)
	draw_line(center+Vector2(22,-28)*scale,center+Vector2(22,-10)*scale,color,w)

func _chain(a:Vector2,b:Vector2,links:int) -> void:
	for i in range(links):
		var f=float(i)/float(maxi(1,links-1))
		var p=a.lerp(b,f)+Vector2(0,sin(f*PI)*12)
		draw_arc(p,6,0,TAU,10,Color("342d33"),2.5)

func _blue_flame(p:Vector2) -> void:
	draw_circle(p+Vector2(0,8),22,Color("20bde522"))
	draw_polygon(PackedVector2Array([
		p+Vector2(-12,12),p+Vector2(-8,-5),p+Vector2(0,-27),
		p+Vector2(7,-7),p+Vector2(12,12)
	]),PackedColorArray([Color("20bde5"),Color("20bde5"),Color("7cecff"),Color("20bde5"),Color("20bde5")]))
	draw_rect(Rect2(p+Vector2(-15,13),Vector2(30,8)),Color("1b1c25"))

func _draw() -> void:
	var t=float(Time.get_ticks_msec())/1000.0
	var width=arena_size.x
	draw_rect(Rect2(Vector2.ZERO,arena_size),Color("070b14"))
	draw_rect(Rect2(0,70,width,330),Color("0e1625"))
	draw_circle(Vector2(width-210,130),72,Color("9bcbe522"))
	draw_circle(Vector2(width-210,130),51,Color("cfeaf177"))

	# Distant drowned ruins establish scale without interfering with gameplay.
	for x in [90.0,310.0,620.0,1390.0,1570.0]:
		_stone(Rect2(x,238,28,262),Color("141b2b"),Color("26364a"))
		_stone(Rect2(x-11,226,50,16),Color("1a2233"),Color("344257"))
	for x in [185.0,520.0,760.0,1480.0]:
		draw_line(Vector2(x,410),Vector2(x-18,490),Color("17251f"),5)

	# Water occupies a much deeper vertical band than the old arena.
	draw_rect(Rect2(0,water_top,width,floor_y-water_top),Color("112c48dc"))
	draw_rect(Rect2(0,water_top,width,6),Color("75b5d8dd"))
	for x in range(0,int(width),64):
		var y=water_top+12+sin(t*2.0+float(x)*0.022)*3.0
		draw_line(Vector2(x+7,y),Vector2(x+45,y),Color("89c6df66"),2)

	# Main drowned temple facade: symmetrical columns, chains, banners and cyan runes.
	var cx=1180.0
	var base=floor_y
	_stone(Rect2(cx-360,base-300,720,300),Color("1e2635"),Color("3a485b"))
	_stone(Rect2(cx-310,base-342,620,54),Color("232d3e"),Color("4c5969"))
	for px in [cx-310,cx-215,cx+215,cx+310]:
		_stone(Rect2(px-28,base-360,56,360),Color("232b3a"),Color("4a5668"))
		_stone(Rect2(px-38,base-375,76,20),Color("293345"),Color("566274"))
	# Broken upper silhouette.
	_stone(Rect2(cx-164,base-406,328,76),Color("202838"),Color("495568"))
	draw_polygon(PackedVector2Array([
		Vector2(cx-170,base-406),Vector2(cx-110,base-465),Vector2(cx-45,base-426),
		Vector2(cx,base-500),Vector2(cx+50,base-426),Vector2(cx+120,base-472),
		Vector2(cx+170,base-406)
	]),PackedColorArray([Color("202838"),Color("202838"),Color("202838"),Color("202838"),Color("202838"),Color("202838"),Color("202838")]))
	# Door is monumental but still proportional: about twice Spike's visual height, not gigantic.
	_stone(Rect2(cx-68,base-174,136,174),Color("101722"),Color("4b596b"))
	draw_arc(Vector2(cx,base-172),68,PI,TAU,30,Color("566478"),6)
	draw_line(Vector2(cx,base-160),Vector2(cx,base-18),Color("24c6e8"),4)
	_trident(Vector2(cx,base-92),0.9,Color("43d9f4"))
	# Trident crest from the reference composition.
	draw_polygon(PackedVector2Array([
		Vector2(cx,base-372),Vector2(cx-54,base-333),Vector2(cx-35,base-274),
		Vector2(cx+35,base-274),Vector2(cx+54,base-333)
	]),PackedColorArray([Color("263348"),Color("263348"),Color("263348"),Color("263348"),Color("263348")]))
	_trident(Vector2(cx,base-323),0.72,Color("93b9cc"))
	# Chains and banners.
	_chain(Vector2(cx-310,base-350),Vector2(cx-155,base-305),15)
	_chain(Vector2(cx+310,base-350),Vector2(cx+155,base-305),15)
	for bx in [cx-335,cx+335]:
		draw_rect(Rect2(bx-23,base-290,46,108),Color("12304a"))
		draw_polygon(PackedVector2Array([Vector2(bx-23,base-182),Vector2(bx,base-145),Vector2(bx+23,base-182)]),PackedColorArray([Color("12304a"),Color("12304a"),Color("12304a")]))
		_trident(Vector2(bx,base-237),0.38,Color("8da9b8"))
	# Blue braziers and reef growth.
	_blue_flame(Vector2(cx-150,base-102))
	_blue_flame(Vector2(cx+150,base-102))
	for algae_x in [cx-292,cx-246,cx-92,cx+98,cx+252,cx+302]:
		draw_line(Vector2(algae_x,base-345),Vector2(algae_x-5,base-305),Color("204e42"),5)
		draw_line(Vector2(algae_x+6,base-338),Vector2(algae_x+12,base-288),Color("28705b"),3)

	# Side ruins and playable ledges.
	_stone(Rect2(300,735,220,22),Color("273143"),Color("4b596b"))
	_stone(Rect2(1430,720,190,22),Color("273143"),Color("4b596b"))
	_stone(Rect2(70,665,110,185),Color("232a38"),Color("465164"))
	draw_rect(Rect2(92,690,66,160),Color("090f19"))
	draw_arc(Vector2(125,693),33,PI,TAU,24,Color("526075"),5)
	draw_string(ThemeDB.fallback_font,Vector2(56,650),"SAÍDA",HORIZONTAL_ALIGNMENT_CENTER,136,12,Color("b8cee0"))
