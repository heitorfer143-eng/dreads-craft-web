extends Node2D

var purity=false
var camera: Camera2D
var clock=0.32
var world_bg=preload("res://assets/backgrounds/dark_castles_generated.png")

func _process(_delta:float) -> void:
	queue_redraw()

func _draw() -> void:
	var size=get_viewport_rect().size
	if purity:
		draw_purity(size)
		return
	# The normal world now uses an actual pixel-art landscape image instead of flat procedural shapes.
	draw_texture_rect(world_bg,Rect2(Vector2.ZERO,size),false)
	var night_strength=clampf(absf(clock-.5)*2.0,0.0,1.0)
	var tint=Color(0.015,0.012,0.035,0.30+night_strength*.34)
	draw_rect(Rect2(Vector2.ZERO,size),tint)
	# Subtle parallax fog only; the scenery itself comes from the image asset.
	var drift=fmod((camera.global_position.x*.04 if is_instance_valid(camera) else 0.0),size.x)
	draw_rect(Rect2(-drift,size.y*.66,size.x*1.3,size.y*.13),Color(.34,.30,.46,.075))
	draw_rect(Rect2(size.x-drift,size.y*.66,size.x*1.3,size.y*.13),Color(.45,.40,.62,.045))

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
