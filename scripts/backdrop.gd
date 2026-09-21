extends Node2D

var purity=false
var camera: Camera2D
var clock = 0.32

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var size=get_viewport_rect().size
	if purity:
		draw_purity(size)
		return
	var night_strength=clampf(absf(clock-.5)*2.0,0.0,1.0)
	var sky_top=Color("17142b").lerp(Color("070a16"),night_strength)
	var sky_bottom=Color("342c47").lerp(Color("111827"),night_strength)
	draw_rect(Rect2(Vector2.ZERO,size),sky_top)
	# Faixas de névoa criam profundidade sem competir com o terreno.
	for band in 7:
		var alpha=0.018+band*0.005
		var y=90+band*75
		draw_rect(Rect2(0,y,size.x,58),Color(0.55,0.49,0.72,alpha))
	# Lua grande e brilho frio.
	var moon=Vector2(size.x*.79,104)
	for radius in [70,60,52]:
		var a=0.025 if radius==70 else 0.05 if radius==60 else 0.1
		draw_circle(moon,radius,Color(0.75,0.74,0.9,a))
	draw_circle(moon,39,Color("c9c4d8"))
	draw_circle(moon+Vector2(13,-8),8,Color("a9a4bc"))
	draw_circle(moon+Vector2(-11,10),5,Color("a9a4bc"))
	# Estrelas fixas em tela para manter a cena viva.
	for i in 34:
		var sx=fmod(float(i*97+41),size.x)
		var sy=fmod(float(i*53+19),190.0)
		var twinkle=.25+.18*sin(Time.get_ticks_msec()/620.0+i)
		draw_circle(Vector2(sx,sy),1.1,Color(0.76,0.72,0.93,twinkle))
	# Silhuetas de montanhas em três planos.
	for layer in 3:
		var points=PackedVector2Array([Vector2(-100,size.y)])
		var shift=camera.global_position.x*(.025+layer*.025) if is_instance_valid(camera) else 0.0
		var base=285+layer*92
		for x in range(-100,int(size.x)+101,42):
			var wave=sin((x+shift)*.007+layer)*45+sin((x+shift)*.017+layer*.7)*18
			points.append(Vector2(x,base+wave))
		points.append(Vector2(size.x+100,size.y))
		draw_colored_polygon(points,[Color("2c2943"),Color("202237"),Color("151b29")][layer])
	# Castelo distante com torres irregulares e janelas acesas.
	var castle_x=size.x*.43
	for tower in 6:
		var tx=castle_x+tower*62-150
		var th=120+(tower%3)*54
		var y=350-th
		draw_rect(Rect2(tx,y,44,th+135),Color("11121e"))
		for tooth in 3:
			draw_rect(Rect2(tx+tooth*15,y-12,10,14),Color("11121e"))
		if tower in [1,3,5]:
			draw_rect(Rect2(tx+18,y+38,6,15),Color("9a6248"))
	# Arcos de ruína ao fundo.
	for arch in 3:
		var ax=size.x*.63+arch*72
		draw_rect(Rect2(ax,252,13,160),Color("141522"))
		draw_rect(Rect2(ax+42,252,13,160),Color("141522"))
		draw_arc(Vector2(ax+27,265),28,PI,TAU,20,Color("141522"),10)

func draw_purity(size: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("303e62"))
	for band in 12:
		draw_rect(Rect2(0,band*size.y/12,size.x,size.y/12+1),Color(.64,.8,.95,.02+band*.012))
	var center=Vector2(size.x*.5,180)
	for radius in [130,110,85]:
		draw_arc(center,radius,0,TAU,96,Color(.95,.89,.69,.35),2)
	for column in 7:
		var x=column*size.x/6
		draw_rect(Rect2(x-15,130,30,size.y),Color(.75,.82,.9,.17))
		draw_arc(Vector2(x+size.x/12,160),size.x/12,PI,TAU,32,Color(.87,.87,.76,.3),8)
	for i in 45:
		var x=fmod(i*137.0,size.x)
		var y=fmod(i*71.0-Time.get_ticks_msec()*.013+10000,size.y)
		draw_circle(Vector2(x,y),1.5,Color(.95,.92,.72,.5))
