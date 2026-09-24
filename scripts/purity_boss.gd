extends Node2D

signal defeated
var player: CharacterBody2D
var max_hp=900.0
var hp=900.0
var awakened=false
var state="approach"
var timer=1.4
var facing=-1
var warning_x=0.0
var flash=0.0
var age=0.0
var attack_index=0
var expression="cold"

func set_expression(value: String) -> void:
	expression=value
	queue_redraw()

func hit(amount: float) -> void:
	# Attacks are already blocked by the dialogue modal; do not let a state desync
	# make the boss permanently invulnerable.
	if hp<=0:
		return
	hp=maxf(0,hp-amount)
	flash=.15
	if hp==0:
		awakened=false
		defeated.emit()
		queue_free()

func _physics_process(delta: float) -> void:
	age+=delta
	flash=maxf(0,flash-delta)
	queue_redraw()
	if not awakened or not is_instance_valid(player):
		return
	timer-=delta
	var enraged=hp<max_hp*.5
	if state=="approach":
		facing=1 if player.position.x>position.x else -1
		if absf(player.position.x-position.x)>90:
			position.x+=facing*(115 if enraged else 85)*delta
		position.x=clampf(position.x,7*32,34*32)
		if timer<=0:
			attack_index+=1
			state="pillar" if attack_index%2==0 else "slam"
			warning_x=player.position.x
			timer=.85 if enraged else 1.15
	elif state in ["slam","pillar"] and timer<=0:
		var center=position.x+facing*85 if state=="slam" else warning_x
		var radius=105 if state=="slam" else 38
		var grounded=player.position.y>35*32-75
		if absf(player.position.x-center)<radius and (state=="pillar" or grounded):
			player.take_damage(23 if enraged else 16)
		state="impact_slam" if state=="slam" else "impact_pillar"
		timer=.32
	elif state.begins_with("impact") and timer<=0:
		state="recover"
		timer=.8
	elif state=="recover" and timer<=0:
		state="approach"
		timer=1.0 if enraged else 1.6

func _draw() -> void:
	var gold=Color("ebd59a")
	var armor=Color("d9e4ec") if flash==0 else Color.WHITE
	var pulse=sin(age*3)*3
	var origin=Vector2(0,-100+pulse)
	draw_circle(origin,56,Color(.7,.85,1,.08))
	draw_arc(origin,52,0,TAU,48,gold,3)
	# Segmented wings, mantle, armored torso and crowned mask.
	for side in [-1,1]:
		for feather in 4:
			var x=side*(33+feather*12)
			var top=-107+feather*10+pulse
			draw_colored_polygon(PackedVector2Array([Vector2(side*20,-85),Vector2(x,top-20),Vector2(x+side*12,top+34),Vector2(side*24,-42)]),Color("b2c5db").darkened(feather*.09))
	draw_colored_polygon(PackedVector2Array([Vector2(-25,-84),Vector2(25,-84),Vector2(39,-6),Vector2(0,-17),Vector2(-39,-6)]),Color("454c75"))
	draw_rect(Rect2(-24,-85,48,46),armor)
	draw_colored_polygon(PackedVector2Array([Vector2(-23,-85),Vector2(0,-67),Vector2(23,-85),Vector2(0,-96)]),gold)
	for side in [-1,1]:
		draw_rect(Rect2(side*20-8,-42,16,40),armor.darkened(.18))
		draw_circle(Vector2(side*32,-76),15,armor)
		draw_line(Vector2(side*32,-70),Vector2(side*40,-37),gold,12)
	draw_colored_polygon(PackedVector2Array([Vector2(-18,-115),Vector2(18,-115),Vector2(16,-91),Vector2(0,-82),Vector2(-16,-91)]),armor)
	var eye_color=Color("58d8ec")
	if expression=="angered":
		eye_color=Color("ff9f52")
	elif expression=="wrath":
		eye_color=Color("fff0a8")
	elif expression=="defiant":
		eye_color=Color("d0e8ff")
	var eye_slant=2 if expression in ["angered","wrath"] else 0
	draw_line(Vector2(-11,-102-eye_slant),Vector2(-3,-100+eye_slant),eye_color,3)
	draw_line(Vector2(3,-100+eye_slant),Vector2(11,-102-eye_slant),eye_color,3)
	if expression=="wrath":
		draw_arc(origin,64,0,TAU,48,Color(1,.86,.45,.45),4)
	for x in [-14,0,14]:
		draw_colored_polygon(PackedVector2Array([Vector2(x-5,-114),Vector2(x,-137),Vector2(x+5,-114)]),gold)
	if state in ["slam","impact_slam"]:
		var alpha=.3 if state=="slam" else .85
		draw_rect(Rect2(facing*85-105,-9,210,9),Color(1,.7,.25,alpha))
		if state=="impact_slam":
			draw_arc(Vector2(facing*85,0),100,PI,TAU,24,gold,7)
	if state in ["pillar","impact_pillar"]:
		var x=warning_x-position.x
		draw_rect(Rect2(x-38,-8,76,8),Color(1,.75,.25,.7))
		if state=="impact_pillar":
			draw_rect(Rect2(x-32,-700,64,700),Color(.8,.95,1,.75))
