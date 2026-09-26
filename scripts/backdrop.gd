extends Node2D

const SNOW_START_PX=190.0*32.0
var purity=false
var camera: Camera2D
var clock=0.32
var world_bg=preload("res://assets/backgrounds/dark_castles_generated.png")

func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST

func _process(_delta:float) -> void:
	queue_redraw()

func _draw() -> void:
	var size=get_viewport_rect().size
	if purity:
		draw_purity(size)
		return
	draw_texture_rect(world_bg,Rect2(Vector2.ZERO,size),false)
	var night_strength=clampf(absf(clock-.5)*2.0,0.0,1.0)
	var tint=Color(0.015,0.012,0.035,0.30+night_strength*.34)
	draw_rect(Rect2(Vector2.ZERO,size),tint)

	var camera_x=camera.global_position.x if is_instance_valid(camera) else 0.0
	var snow_mix=clampf((camera_x-(SNOW_START_PX-700.0))/700.0,0.0,1.0)
	if snow_mix>0.0:
		draw_snow_biome(size,snow_mix,camera_x)

	var drift=fmod((camera_x*.04),size.x)
	draw_rect(Rect2(-drift,size.y*.66,size.x*1.3,size.y*.13),Color(.34,.30,.46,.075))
	draw_rect(Rect2(size.x-drift,size.y*.66,size.x*1.3,size.y*.13),Color(.45,.40,.62,.045))

func draw_snow_biome(size:Vector2,amount:float,camera_x:float) -> void:
	# Blue-white atmospheric wash makes the biome readable even on old saves.
	draw_rect(Rect2(Vector2.ZERO,size),Color(0.34,0.56,0.76,0.22*amount))
	draw_rect(Rect2(0,size.y*.58,size.x,size.y*.42),Color(0.62,0.77,0.88,0.11*amount))

	# Distant frozen mountain silhouettes.
	var far=PackedVector2Array([
		Vector2(0,size.y*.60),Vector2(size.x*.14,size.y*.39),Vector2(size.x*.27,size.y*.57),
		Vector2(size.x*.43,size.y*.31),Vector2(size.x*.58,size.y*.56),Vector2(size.x*.73,size.y*.35),
		Vector2(size.x*.88,size.y*.54),Vector2(size.x,size.y*.41),Vector2(size.x,size.y*.74),Vector2(0,size.y*.74)
	])
	draw_colored_polygon(far,Color(0.26,0.36,0.52,0.55*amount))
	var caps=PackedVector2Array([
		Vector2(size.x*.10,size.y*.45),Vector2(size.x*.14,size.y*.39),Vector2(size.x*.18,size.y*.46),
		Vector2(size.x*.39,size.y*.38),Vector2(size.x*.43,size.y*.31),Vector2(size.x*.48,size.y*.40),
		Vector2(size.x*.69,size.y*.42),Vector2(size.x*.73,size.y*.35),Vector2(size.x*.78,size.y*.43)
	])
	for i in range(0,caps.size(),3):
		draw_colored_polygon(PackedVector2Array([caps[i],caps[i+1],caps[i+2]]),Color(0.87,0.94,0.99,0.70*amount))

	# Simple dark pines with snow caps.
	for i in 9:
		var x=fmod(float(i*173)-fmod(camera_x*.07,size.x)+size.x*2.0,size.x)
		var base_y=size.y*.73+float((i%3)*8)
		var h=72.0+float((i%4)*12)
		draw_rect(Rect2(x-3,base_y-h*.15,6,h*.25),Color(0.10,0.16,0.20,0.75*amount))
		for tier in 3:
			var y=base_y-h+float(tier)*h*.23
			var half=18.0+float(tier)*8.0
			draw_colored_polygon(PackedVector2Array([
				Vector2(x,y),Vector2(x-half,y+h*.34),Vector2(x+half,y+h*.34)
			]),Color(0.10,0.22,0.24,0.82*amount))
			draw_line(Vector2(x-half*.55,y+h*.21),Vector2(x+half*.35,y+h*.21),Color(0.91,0.97,1.0,0.75*amount),3)

	# Visible snowfall, deterministic and cheap.
	var now=Time.get_ticks_msec()*.035
	for i in 42:
		var x=fmod(float(i*97)+now+camera_x*.015,size.x)
		var y=fmod(float(i*61)+now*(0.55+float(i%5)*0.06),size.y)
		var r=1.0+float(i%3)
		draw_circle(Vector2(x,y),r,Color(0.94,0.98,1.0,0.72*amount))

func draw_purity(size:Vector2) -> void:
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
