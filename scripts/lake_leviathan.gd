extends Node2D

signal defeated

var player: CharacterBody2D
var max_hp := 1400.0
var hp := 1400.0
var awakened := true
var state := "recover"
var timer := 1.6
var age := 0.0
var flash := 0.0
var warning_x := 0.0
var dive_target_x := 0.0
var attack_index := 0
var body_sprite: Sprite2D
var orbs: Array = []
var wave_x := 0.0
var wave_dir := -1.0
var wave_hit := false
var orb_volley_can_damage := true
var arena_size := Vector2(1680,960)
var combat_floor_y := 850.0
var combat_min_y := 510.0

func _ready() -> void:
	z_index=8
	body_sprite=Sprite2D.new()
	body_sprite.texture=load("res://assets/boss/lake_leviathan.svg")
	body_sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	body_sprite.position=Vector2(0,-128)
	body_sprite.scale=Vector2(0.72,0.72)
	body_sprite.z_index=2
	add_child(body_sprite)
	queue_redraw()

func set_arena_bounds(size:Vector2,floor_y:float) -> void:
	arena_size=size
	combat_floor_y=floor_y
	combat_min_y=maxf(420.0,floor_y-340.0)

func hit(amount:float) -> void:
	if hp<=0 or not awakened:
		return
	hp=maxf(0.0,hp-amount)
	flash=0.14
	if hp<=0:
		awakened=false
		defeated.emit()
		queue_free()

func phase_two() -> bool:
	return hp<=max_hp*0.5

func _physics_process(delta:float) -> void:
	age+=delta
	flash=maxf(0.0,flash-delta)
	var enraged=phase_two()
	if is_instance_valid(body_sprite):
		body_sprite.position.y=-128.0+sin(age*(2.8 if enraged else 2.0))*4.0
		body_sprite.rotation=sin(age*1.15)*0.012
		body_sprite.modulate=Color("fff1ff") if flash>0 else (Color("e9d7ff") if enraged else Color.WHITE)
		body_sprite.visible=state!="dive_hidden"
		body_sprite.scale=Vector2(0.76,0.76) if enraged else Vector2(0.72,0.72)
	_update_orbs(delta)
	if state=="wave":
		wave_x+=wave_dir*(620.0 if enraged else 500.0)*delta
		if not wave_hit and is_instance_valid(player) and absf(player.position.x-wave_x)<38.0 and player.position.y>combat_min_y:
			player.take_damage(15 if enraged else 12)
			player.velocity.x=wave_dir*340.0
			wave_hit=true
		if wave_x<20 or wave_x>arena_size.x-20:
			state="recover"
			timer=0.55 if enraged else 0.8
	if not awakened or not is_instance_valid(player):
		queue_redraw()
		return
	timer-=delta
	if timer>0:
		queue_redraw()
		return
	match state:
		"recover":
			attack_index+=1
			match attack_index%4:
				0:
					state="tentacle_warn"
					warning_x=player.position.x
					timer=0.65 if enraged else 0.82
				1:
					state="wave_warn"
					timer=0.72 if enraged else 0.92
				2:
					state="orb_warn"
					timer=0.62 if enraged else 0.78
				3:
					state="dive_warn"
					dive_target_x=clampf(player.position.x,280.0,arena_size.x-280.0)
					timer=0.78 if enraged else 1.02
		"tentacle_warn":
			if absf(player.position.x-warning_x)<62.0 and player.position.y>combat_min_y:
				player.take_damage(20 if enraged else 16)
				player.velocity.y=-260
			state="tentacle_impact"
			timer=0.24
		"tentacle_impact":
			state="recover"
			timer=0.68 if enraged else 0.86
		"wave_warn":
			wave_dir=-1.0 if player.position.x<position.x else 1.0
			wave_x=position.x
			wave_hit=false
			state="wave"
			timer=2.5
		"orb_warn":
			_spawn_orbs(5 if enraged else 3)
			state="recover"
			timer=0.82 if enraged else 1.05
		"dive_warn":
			state="dive_hidden"
			timer=0.52 if enraged else 0.8
		"dive_hidden":
			position.x=dive_target_x
			if absf(player.position.x-position.x)<105.0 and player.position.y>combat_min_y-20.0:
				player.take_damage(23 if enraged else 18)
				player.velocity.y=-330
			state="dive_splash"
			timer=0.28
		"dive_splash":
			state="recover"
			timer=0.7 if enraged else 0.92
	queue_redraw()

func _spawn_orbs(count:int) -> void:
	orb_volley_can_damage=true
	var origin=position+Vector2(0,-175)
	for i in range(count):
		var target=player.position+Vector2((float(i)-float(count-1)/2.0)*44.0,-20)
		var velocity=(target-origin).normalized()*(330.0 if phase_two() else 270.0)
		orbs.append({"pos":origin,"vel":velocity,"life":4.2})

func _update_orbs(delta:float) -> void:
	for i in range(orbs.size()-1,-1,-1):
		var orb=orbs[i]
		orb["pos"]=Vector2(orb["pos"])+Vector2(orb["vel"])*delta
		orb["life"]=float(orb["life"])-delta
		if is_instance_valid(player) and Vector2(orb["pos"]).distance_to(player.position+Vector2(0,-22))<24:
			if orb_volley_can_damage:
				player.take_damage(13 if phase_two() else 10)
				orb_volley_can_damage=false
			orbs.remove_at(i)
			continue
		if float(orb["life"])<=0 or Vector2(orb["pos"]).x<0 or Vector2(orb["pos"]).x>arena_size.x or Vector2(orb["pos"]).y<0 or Vector2(orb["pos"]).y>arena_size.y:
			orbs.remove_at(i)
	queue_redraw()

func _draw() -> void:
	var glow=Color("aa6cff")
	var water=Color("6e91bd")
	var base=Vector2(0,-8)
	draw_arc(base,160,PI+0.08,TAU-0.08,48,Color(water.r,water.g,water.b,0.52),7)
	draw_arc(base+Vector2(0,10),112,PI+0.1,TAU-0.1,40,Color(glow.r,glow.g,glow.b,0.26),4)
	if phase_two():
		draw_arc(Vector2(0,-160),205,0,TAU,64,Color(0.68,0.35,1.0,0.22+0.06*sin(age*5.0)),6)
	if state=="tentacle_warn" or state=="tentacle_impact":
		var x=warning_x-position.x
		if state=="tentacle_warn":
			draw_rect(Rect2(x-44,-8,88,9),Color(0.72,0.38,1.0,0.72))
			draw_line(Vector2(x,-12),Vector2(x,-100),Color("9a6bdf66"),4)
		else:
			var pts=PackedVector2Array([Vector2(x-35,0),Vector2(x-25,-85),Vector2(x-8,-185),Vector2(x+5,-245),Vector2(x+26,-165),Vector2(x+36,-72),Vector2(x+43,0)])
			draw_colored_polygon(pts,Color("33214f"))
			draw_polyline(pts,glow,5)
	if state=="wave_warn":
		draw_rect(Rect2(-300,-18,600,14),Color("6d8fc566"))
		draw_string(ThemeDB.fallback_font,Vector2(-70,-32),"A ÁGUA RECUA...",HORIZONTAL_ALIGNMENT_CENTER,140,12,Color("c5dcff"))
	if state=="wave":
		draw_line(Vector2(wave_x-position.x,-10),Vector2(wave_x-position.x,-130),Color("8bb8e8dd"),18)
		draw_line(Vector2(wave_x-position.x+12,-10),Vector2(wave_x-position.x+12,-95),Color("b3d6ff88"),8)
	if state=="orb_warn":
		draw_arc(Vector2(0,-170),78,0,TAU,40,Color("b879ff99"),7)
	if state=="dive_warn":
		var x=dive_target_x-position.x
		draw_circle(Vector2(x,-4),58,Color("9a5cf04a"))
		draw_arc(Vector2(x,-4),58,0,TAU,36,glow,5)
	if state=="dive_splash":
		for radius in [45.0,80.0,120.0]:
			draw_arc(Vector2(0,-4),radius,PI,TAU,32,Color("90b9e899"),6)
	for orb in orbs:
		var local=Vector2(orb["pos"])-position
		draw_circle(local,12,Color("7e45c9"))
		draw_circle(local,6,Color("d6a5ff"))
