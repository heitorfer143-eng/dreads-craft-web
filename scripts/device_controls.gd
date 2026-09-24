extends Control

var game: Node2D
var mobile=false
var fingers: Dictionary={}
var regions: Dictionary={}
var repeat_timer=0.0

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	mobile=OS.has_feature("android") or OS.has_feature("ios") or DisplayServer.is_touchscreen_available() or (OS.has_feature("web") and get_viewport_rect().size.x<=1000)
	get_viewport().size_changed.connect(rebuild_regions)
	rebuild_regions()

func set_mobile(value: bool) -> void:
	if mobile==value:
		return
	release_all()
	mobile=value
	rebuild_regions()
	if is_instance_valid(game) and game.has_method("layout"):
		game.call_deferred("layout")

func rebuild_regions() -> void:
	var viewport=get_viewport_rect().size
	var bottom_margin=maxf(18.0,viewport.y*0.025)
	var side_margin=maxf(18.0,viewport.x*0.012)
	var bottom=viewport.y-bottom_margin
	# About 70% of the old button footprint: still finger-friendly, but no longer
	# covers the player, buildings and half of the hotbar in landscape.
	var b=clampf(viewport.y*0.145,82.0,104.0)
	var gap=8.0
	var right=viewport.x-side_margin
	regions={
		"left":Rect2(side_margin,bottom-b,b,b),
		"right":Rect2(side_margin+b+gap,bottom-b,b,b),
		"attack":Rect2(right-b*3-gap*2,bottom-b,b,b),
		"mine":Rect2(right-b*2-gap,bottom-b,b,b),
		"jump":Rect2(right-b,bottom-b,b,b),
		"place":Rect2(right-b*3-gap*2,bottom-b*2-gap,b,b),
		"interact":Rect2(right-b*2-gap,bottom-b*2-gap,b,b),
		"inventory":Rect2(right-b,bottom-b*2-gap,b,b),
		"down":Rect2(right-b,bottom-b*3-gap*2,b,b)
	}
	release_all()
	queue_redraw()
	if is_instance_valid(game) and game.has_method("layout"):
		game.call_deferred("layout")

func release_all() -> void:
	for action in ["left","right","jump","down"]:
		Input.action_release(action)
	fingers.clear()
	if is_instance_valid(game):
		game.mining_held=false

func region_at(point: Vector2) -> String:
	for action in regions:
		if action=="down" and (not is_instance_valid(game.player) or not game.player.creative):
			continue
		if regions[action].has_point(point):
			return action
	return ""

func prepare_target() -> void:
	if is_instance_valid(game) and game.has_method("set_touch_action_target"):
		game.set_touch_action_target()

func prepare_place_target() -> void:
	if is_instance_valid(game) and game.has_method("set_touch_place_target"):
		game.set_touch_place_target()

func update_actions() -> void:
	var pressed=fingers.values()
	for action in ["left","right","jump","down"]:
		if action in pressed:
			Input.action_press(action)
		else:
			Input.action_release(action)
	if is_instance_valid(game):
		game.mining_held="mine" in pressed
		if game.mining_held:
			prepare_target()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		set_mobile(true)
		if not event.pressed:
			if fingers.has(event.index):
				fingers.erase(event.index)
				update_actions()
				get_viewport().set_input_as_handled()
			return
		if not is_instance_valid(game) or not game.active or game.modal:
			return
		var action=region_at(event.position)
		if action!="":
			fingers[event.index]=action
			update_actions()
			if action=="place":
				prepare_place_target()
				game.use_selected()
			elif action=="attack":
				prepare_target()
				game.attack()
			elif action=="interact":
				game.interact_nearby()
			elif action=="inventory":
				game.show_inventory()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and fingers.has(event.index):
		fingers[event.index]=region_at(event.position)
		update_actions()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed:
		var switching=mobile
		set_mobile(false)
		if switching:
			for action in ["left","right","jump","down"]:
				if event.is_action_pressed(action):
					Input.action_press(action)
	elif event is InputEventMouseButton and event.device!=InputEvent.DEVICE_ID_EMULATION:
		set_mobile(false)

func _process(delta: float) -> void:
	visible=is_instance_valid(game) and game.active and not game.modal
	if not visible:
		if not fingers.is_empty():
			release_all()
		return
	repeat_timer-=delta
	if mobile and repeat_timer<=0:
		repeat_timer=.22
		if "place" in fingers.values():
			prepare_place_target()
			game.use_selected()
		if "attack" in fingers.values():
			prepare_target()
			game.attack()
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(game) or not game.active or game.modal:
		return
	var font=ThemeDB.fallback_font
	if not mobile:
		var keys=["E","C","Esc","F11"]
		var index=0
		for node in game.action_box.get_children():
			if index<keys.size():
				draw_string(font,node.global_position+Vector2(3,12),keys[index],HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("dcc99d"))
			index+=1
		index=0
		for node in game.bar.get_children():
			draw_string(font,node.global_position+Vector2(3,11),str(index+1),HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("dcc99d"))
			index+=1
		return

	var captions={
		"left":"","right":"",
		"jump":"SUBIR" if game.player.creative else "PULAR",
		"down":"DESCER","mine":"MINERAR","place":"USAR / COLOCAR",
		"attack":"ATACAR","interact":"FALAR / ENTRAR","inventory":"MOCHILA"
	}
	for action in regions:
		if action=="down" and not game.player.creative:
			continue
		var rect:Rect2=regions[action]
		var active=action in fingers.values()
		draw_style_box(style(active),rect)
		if action in ["left","right"]:
			# Draw our own arrow so Android/Web never depends on a missing Unicode glyph.
			var center=rect.get_center()
			var half=minf(rect.size.x,rect.size.y)*0.18
			var points=PackedVector2Array()
			if action=="left":
				points=PackedVector2Array([
					center+Vector2(-half,0),
					center+Vector2(half,-half),
					center+Vector2(half,half)
				])
			else:
				points=PackedVector2Array([
					center+Vector2(half,0),
					center+Vector2(-half,-half),
					center+Vector2(-half,half)
				])
			draw_colored_polygon(points,Color("fff1df"))
		else:
			var font_size=13
			draw_string(font,rect.position+Vector2(0,rect.size.y/2+5),captions[action],HORIZONTAL_ALIGNMENT_CENTER,rect.size.x,font_size,Color("fff1df"))

func style(active: bool) -> StyleBoxFlat:
	var box=StyleBoxFlat.new()
	box.bg_color=Color("5b3869a8") if active else Color("120e1a70")
	box.border_color=Color("f0bd78c8") if active else Color("9d806895")
	box.set_border_width_all(2)
	box.set_corner_radius_all(14)
	box.shadow_color=Color(0,0,0,.20)
	box.shadow_size=3
	return box

func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT:
		release_all()
