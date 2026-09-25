extends Node2D

var world_seed := 1
var spawn_position := Vector2(150,585)
var exit_position := Vector2(92,574)
var boss_position := Vector2(900,650)
var water_top := 492.0

func _ready() -> void:
	z_index=-8
	var body=StaticBody2D.new()
	body.collision_layer=1
	var floor_shape=RectangleShape2D.new()
	floor_shape.size=Vector2(1280,30)
	var floor=CollisionShape2D.new()
	floor.shape=floor_shape
	floor.position=Vector2(640,620)
	body.add_child(floor)
	for x in [12.0,1268.0]:
		var wall_shape=RectangleShape2D.new()
		wall_shape.size=Vector2(24,720)
		var wall=CollisionShape2D.new()
		wall.shape=wall_shape
		wall.position=Vector2(x,360)
		body.add_child(wall)
	add_child(body)
	queue_redraw()

func is_in_water(pos:Vector2) -> bool:
	return pos.y>=water_top-14.0 and pos.y<=625.0

func _process(_delta:float) -> void:
	queue_redraw()

func _draw() -> void:
	var t=float(Time.get_ticks_msec())/1000.0
	draw_rect(Rect2(0,0,1280,720),Color("090b17"))
	draw_rect(Rect2(0,80,1280,300),Color("11172a"))
	draw_circle(Vector2(1040,132),62,Color("a8c8e533"))
	draw_circle(Vector2(1040,132),44,Color("d7e9f199"))
	for x in [80.0,255.0,1010.0,1160.0]:
		draw_rect(Rect2(x,220,24,220),Color("171a2a"))
		draw_rect(Rect2(x+74,220,24,220),Color("171a2a"))
		draw_rect(Rect2(x,212,98,18),Color("24243a"))
	for x in [330.0,500.0,740.0,1080.0]:
		draw_rect(Rect2(x,350,34,270),Color("292a3b"))
		draw_rect(Rect2(x-10,340,54,18),Color("3c3a50"))
	draw_rect(Rect2(0,water_top,1280,128),Color("172846dc"))
	draw_rect(Rect2(0,water_top,1280,5),Color("7899c9e8"))
	for x in range(0,1280,64):
		var y=water_top+12+sin(t*2.0+float(x)*0.025)*3.0
		draw_line(Vector2(x+8,y),Vector2(x+44,y),Color("90add36f"),2)
	draw_rect(Rect2(820,414,176,18),Color("332847"))
	draw_rect(Rect2(846,432,124,88),Color("201a31"))
	draw_circle(Vector2(908,455),30,Color("7f4fcf55"))
	draw_arc(Vector2(908,455),30,0,TAU,32,Color("a86cff"),4)
	draw_line(Vector2(908,432),Vector2(908,478),Color("c597ff"),4)
	draw_line(Vector2(885,455),Vector2(931,455),Color("c597ff"),4)
	draw_rect(Rect2(40,470,104,150),Color("242332"))
	draw_rect(Rect2(55,490,74,130),Color("0a0b13"))
	draw_rect(Rect2(64,500,56,120),Color("121522"))
	draw_arc(Vector2(92,510),28,PI,TAU,24,Color("6f598f"),5)
	draw_string(ThemeDB.fallback_font,Vector2(30,458),"SAÍDA",HORIZONTAL_ALIGNMENT_CENTER,124,12,Color("c5b7d8"))
