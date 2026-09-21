extends Control

var time := 0.0
var stars: Array[Vector2] = []

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for i in range(72):
		var fx=fmod(float(i*73+17),997.0)/997.0
		var fy=fmod(float(i*131+43),991.0)/991.0
		stars.append(Vector2(fx,fy*0.62))
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	time+=delta
	queue_redraw()

func hill(points: PackedVector2Array, color: Color) -> void:
	draw_colored_polygon(points,color)

func _draw() -> void:
	var s=size
	if s.x<=1.0 or s.y<=1.0:
		return

	# Fundo em gradiente desenhado em tempo real; nenhuma foto pronta.
	var top=Color("100d1f")
	var bottom=Color("1c1830")
	for i in range(20):
		var t=float(i)/19.0
		var c=top.lerp(bottom,t)
		draw_rect(Rect2(0,s.y*t,s.x,s.y/19.0+2.0),c)

	# Estrelas discretas com brilho lento.
	for i in range(stars.size()):
		var p=Vector2(stars[i].x*s.x,stars[i].y*s.y)
		var glow=0.35+0.35*(sin(time*1.3+float(i)*1.71)*0.5+0.5)
		draw_circle(p,1.0+(i%3)*0.35,Color(0.73,0.69,0.90,glow))

	# Lua e halo.
	var moon=Vector2(s.x*0.77,s.y*0.18)
	for r in range(72,45,-7):
		var alpha=0.012+float(72-r)*0.0015
		draw_circle(moon,float(r),Color(0.65,0.58,0.88,alpha))
	draw_circle(moon,40.0,Color("cbc5db"))
	draw_circle(moon+Vector2(14,-8),35.0,Color("a9a3c3"))
	draw_circle(moon+Vector2(-13,9),7.0,Color(0.43,0.40,0.55,0.22))
	draw_circle(moon+Vector2(8,12),5.0,Color(0.43,0.40,0.55,0.18))

	# Montanhas em camadas.
	hill(PackedVector2Array([
		Vector2(0,s.y*0.50),Vector2(s.x*0.12,s.y*0.39),Vector2(s.x*0.23,s.y*0.49),
		Vector2(s.x*0.36,s.y*0.31),Vector2(s.x*0.52,s.y*0.50),Vector2(s.x*0.67,s.y*0.33),
		Vector2(s.x*0.82,s.y*0.48),Vector2(s.x,s.y*0.35),Vector2(s.x,s.y),Vector2(0,s.y)
	]),Color("211c37"))
	hill(PackedVector2Array([
		Vector2(0,s.y*0.59),Vector2(s.x*0.15,s.y*0.48),Vector2(s.x*0.29,s.y*0.57),
		Vector2(s.x*0.45,s.y*0.43),Vector2(s.x*0.61,s.y*0.58),Vector2(s.x*0.76,s.y*0.46),
		Vector2(s.x*0.90,s.y*0.56),Vector2(s.x,s.y*0.49),Vector2(s.x,s.y),Vector2(0,s.y)
	]),Color("171527"))

	# Castelo distante, também desenhado proceduralmente.
	var cx=s.x*0.54
	var ground=s.y*0.55
	var castle=Color("0b0a13")
	draw_rect(Rect2(cx-92,ground-94,184,94),castle)
	draw_rect(Rect2(cx-66,ground-154,34,154),castle)
	draw_rect(Rect2(cx+28,ground-137,38,137),castle)
	draw_rect(Rect2(cx-12,ground-120,31,120),castle)
	for tower_x in [cx-66,cx-12,cx+28]:
		draw_colored_polygon(PackedVector2Array([
			Vector2(tower_x,ground-154 if tower_x==cx-66 else ground-137),
			Vector2(tower_x+17,ground-180 if tower_x==cx-66 else ground-160),
			Vector2(tower_x+34,ground-154 if tower_x==cx-66 else ground-137)
		]),castle)
	for wx in [-48.0,-4.0,43.0]:
		draw_rect(Rect2(cx+wx,ground-88,6,17),Color(0.57,0.29,0.52,0.34))

	# Árvores mortas em silhueta nas laterais.
	var tree=Color("0d0b14")
	for side in [-1,1]:
		var tx=s.x*(0.075 if side<0 else 0.93)
		var ty=s.y*0.68
		draw_line(Vector2(tx,ty),Vector2(tx+side*8,ty-118),tree,9.0)
		draw_line(Vector2(tx+side*5,ty-75),Vector2(tx+side*45,ty-112),tree,5.0)
		draw_line(Vector2(tx+side*4,ty-58),Vector2(tx-side*34,ty-92),tree,4.0)
		draw_line(Vector2(tx+side*14,ty-98),Vector2(tx+side*28,ty-135),tree,3.0)
		draw_line(Vector2(tx-side*10,ty-83),Vector2(tx-side*28,ty-116),tree,3.0)

	# Névoa em movimento lento.
	var drift=sin(time*0.22)*24.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(-80+drift,s.y*0.64),Vector2(s.x*0.26+drift,s.y*0.59),Vector2(s.x*0.55+drift,s.y*0.65),
		Vector2(s.x*0.84+drift,s.y*0.60),Vector2(s.x+90+drift,s.y*0.64),Vector2(s.x+90,s.y*0.75),Vector2(-90,s.y*0.75)
	]),Color(0.40,0.35,0.56,0.08))
	draw_rect(Rect2(0,s.y*0.72,s.x,s.y*0.28),Color(0.02,0.02,0.035,0.34))
