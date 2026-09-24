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
var body_sprite:Sprite2D

func _ready() -> void:
	body_sprite=Sprite2D.new()
	body_sprite.texture=load("res://assets/boss/purity_guardian_v2.svg")
	body_sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	body_sprite.position=Vector2(0,-86)
	body_sprite.scale=Vector2(0.74,0.74)
	body_sprite.z_index=0
	add_child(body_sprite)
	queue_redraw()

func set_expression(value: String) -> void:
	expression=value
	queue_redraw()

func hit(amount: float) -> void:
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
	if is_instance_valid(body_sprite):
		body_sprite.position.y=-86.0+sin(age*2.8)*2.0
		body_sprite.modulate=Color("fff4dd") if flash>0 else Color.WHITE
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
	var gold=Color("efcc72")
	var aura=Color("7bdff0") if expression in ["cold","defiant"] else Color("ff9c5b") if expression=="angered" else Color("ffe28a")
	var pulse=sin(age*3.0)*3.0
	var origin=Vector2(0,-92+pulse)

	# Halo + fractured runes frame the new masked portrait/body sprite.
	draw_circle(origin,69,Color(aura.r,aura.g,aura.b,0.075))
	draw_arc(origin,63,-2.75,-0.35,40,gold,3)
	draw_arc(origin,63,0.35,2.75,40,gold,3)
	for side in [-1,1]:
		draw_line(Vector2(side*55,-133),Vector2(side*72,-151),aura,4)
		draw_line(Vector2(side*58,-119),Vector2(side*82,-120),Color(aura.r,aura.g,aura.b,.55),3)

	# Expression lighting changes enough that dialogue portraits and battle feel alive.
	if expression=="angered":
		draw_line(Vector2(-18,-128),Vector2(-3,-124),Color("ff9f52"),4)
		draw_line(Vector2(3,-124),Vector2(18,-128),Color("ff9f52"),4)
	elif expression=="wrath":
		draw_arc(origin,78,0,TAU,56,Color(1.0,.86,.45,.55),5)
		draw_circle(Vector2(0,-126),8,Color(1.0,.92,.55,.20))
	else:
		draw_line(Vector2(-17,-126),Vector2(-4,-126),Color("79e9ff"),3)
		draw_line(Vector2(4,-126),Vector2(17,-126),Color("d8b8ff"),3)

	# Attack telegraphs retain the original gameplay timings/hitboxes.
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
