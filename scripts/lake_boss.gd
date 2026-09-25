extends Node2D

signal defeated

var player: CharacterBody2D
var max_hp := 1200.0
var hp := 1200.0
var awakened := true
var state := "idle"
var timer := 1.3
var age := 0.0
var flash := 0.0
var warning_x := 0.0
var attack_index := 0
var body_sprite: Sprite2D

func _ready() -> void:
	z_index=6
	body_sprite=Sprite2D.new()
	body_sprite.texture=load("res://assets/boss/lake_leviathan.svg")
	body_sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	body_sprite.position=Vector2(0,-158)
	body_sprite.scale=Vector2(0.78,0.78)
	body_sprite.z_index=2
	add_child(body_sprite)
	queue_redraw()

func hit(amount: float) -> void:
	if hp<=0 or not awakened:
		return
	hp=maxf(0.0,hp-amount)
	flash=0.14
	if hp<=0:
		awakened=false
		defeated.emit()
		queue_free()

func _physics_process(delta: float) -> void:
	age+=delta
	flash=maxf(0.0,flash-delta)
	if is_instance_valid(body_sprite):
		body_sprite.position.y=-158.0+sin(age*2.1)*3.0
		body_sprite.rotation=sin(age*1.25)*0.008
		body_sprite.modulate=Color("fff2ff") if flash>0 else Color.WHITE
	queue_redraw()
	if not awakened or not is_instance_valid(player):
		return
	timer-=delta
	if timer>0:
		return
	var enraged=hp<=max_hp*0.45
	match state:
		"idle","recover":
			attack_index+=1
			var pattern=attack_index%3
			if pattern==0:
				state="tentacle_warn"
				warning_x=player.position.x
				timer=0.55 if enraged else 0.8
			elif pattern==1:
				state="undertow_warn"
				timer=0.65 if enraged else 0.95
			else:
				state="roar_warn"
				timer=0.75 if enraged else 1.05
		"tentacle_warn":
			if absf(player.position.x-warning_x)<72.0 and player.position.y>position.y-190.0:
				player.take_damage(26 if enraged else 20)
				player.velocity.y=-250
			state="tentacle_impact"
			timer=0.28
		"tentacle_impact":
			state="recover"
			timer=0.65 if enraged else 0.9
		"undertow_warn":
			if absf(player.position.x-position.x)<245.0:
				player.take_damage(20 if enraged else 15)
				player.velocity.x=420.0 if player.position.x>position.x else -420.0
			state="undertow_impact"
			timer=0.32
		"undertow_impact":
			state="recover"
			timer=0.7
		"roar_warn":
			if absf(player.position.x-position.x)<410.0:
				player.take_damage(16 if enraged else 11)
				player.velocity.y=-300
			state="roar_impact"
			timer=0.35
		"roar_impact":
			state="recover"
			timer=0.8

func _draw() -> void:
	var water=Color("5475a8")
	var violet=Color("8b5bd6")
	var glow=Color("bb7cff")
	var base=Vector2(0,-12)

	# Permanent water contact/ripples keep the creature visually inside the lake.
	draw_arc(base,150,PI+0.12,TAU-0.12,42,Color(water.r,water.g,water.b,0.42),7)
	draw_arc(base+Vector2(0,9),105,PI+0.10,TAU-0.10,36,Color(glow.r,glow.g,glow.b,0.22),4)
	draw_line(Vector2(-170,-6),Vector2(170,-6),Color("87a6cf55"),3)

	if state=="tentacle_warn" or state=="tentacle_impact":
		var x=warning_x-position.x
		if state=="tentacle_warn":
			draw_rect(Rect2(x-42,-8,84,8),Color(0.72,0.38,1.0,0.65))
			draw_line(Vector2(x,-10),Vector2(x,-95),Color(0.55,0.35,0.85,0.28),4)
		else:
			var pts=PackedVector2Array([
				Vector2(x-34,0),Vector2(x-24,-82),Vector2(x-10,-170),
				Vector2(x+4,-235),Vector2(x+26,-160),Vector2(x+34,-72),Vector2(x+42,0)
			])
			draw_colored_polygon(pts,Color("33214f"))
			draw_polyline(pts,glow,5)
	if state=="undertow_warn" or state=="undertow_impact":
		var alpha=0.32 if state=="undertow_warn" else 0.72
		for radius in [105.0,155.0,215.0]:
			draw_arc(base,radius,PI+0.15,TAU-0.15,44,Color(water.r,water.g,water.b,alpha),5)
		if state=="undertow_impact":
			draw_arc(base,235,PI+0.1,TAU-0.1,48,violet,9)
	if state=="roar_warn" or state=="roar_impact":
		var alpha=0.25 if state=="roar_warn" else 0.62
		draw_arc(Vector2(0,-160),205,0,TAU,64,Color(glow.r,glow.g,glow.b,alpha),7)
		if state=="roar_impact":
			draw_arc(Vector2(0,-160),265,0,TAU,72,Color("7a5bd8aa"),10)
