extends Control

var game: Node2D
var mobile=false
var fingers: Dictionary={}
var regions: Dictionary={}
var placing_timer=0.0

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	mobile=OS.has_feature("android") or OS.has_feature("ios") or DisplayServer.is_touchscreen_available() or (OS.has_feature("web") and get_viewport_rect().size.x <= 900)
	get_viewport().size_changed.connect(rebuild_regions)
	rebuild_regions()

func set_mobile(value: bool) -> void:
	if mobile==value:
		return
	release_all()
	mobile=value
	queue_redraw()

func rebuild_regions() -> void:
	var viewport=get_viewport_rect().size
	var edge=viewport.x
	var bottom=viewport.y-14
	# Large touch targets: minimum ~84px and up to 112px on wide phones/tablets.
	var b=84.0 if viewport.x < 520 else 96.0 if viewport.x < 700 else 112.0
	var gap=10.0
	regions={
		"left":Rect2(18,bottom-b,b,b),
		"right":Rect2(18+b+gap,bottom-b,b,b),
		"jump":Rect2(edge-18-b,bottom-b*2-gap,b,b),
		"down":Rect2(edge-18-b,bottom-b,b,b),
		"mine":Rect2(edge-18-b*2-gap,bottom-b*2-gap,b,b),
		"place":Rect2(edge-18-b*2-gap,bottom-b,b,b),
		"attack":Rect2(edge-18-b*3-gap*2,bottom-b*2-gap,b,b),
		"inventory":Rect2(edge-18-b,bottom-b*3-gap*2,b,b)
	}
	release_all()
	queue_redraw()

func release_all() -> void:
	for action in ["left","right","jump","down"]:
		Input.action_release(action)
	fingers.clear()
	if is_instance_valid(game):
		game.mining_held=false

func region_at(point: Vector2) -> String:
	for action in regions:
		if action=="down" and not game.player.creative:
			continue
		if regions[action].has_point(point):
			return action
	return ""

func update_actions() -> void:
	var pressed=fingers.values()
	for action in ["left","right","jump","down"]:
		if action in pressed:
			Input.action_press(action)
		else:
			Input.action_release(action)
	game.mining_held="mine" in pressed

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		set_mobile(true)
		if not event.pressed:
			if fingers.has(event.index):
				fingers.erase(event.index)
				update_actions()
				get_viewport().set_input_as_handled()
			return
		if not game.active or game.modal:
			return
		var action=region_at(event.position)
		if action!="":
			fingers[event.index]=action
			update_actions()
			if action=="place":
				place()
			elif action=="attack":
				game.attack()
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

func place() -> void:
	game.update_target()
	game.use_selected()

func _process(delta: float) -> void:
	visible=game.active and not game.modal
	if not visible:
		if not fingers.is_empty():
			release_all()
		return
	placing_timer-=delta
	if mobile and placing_timer<=0:
		placing_timer=.2
		if "place" in fingers.values():
			place()
		if "attack" in fingers.values():
			game.attack()
	queue_redraw()

func _draw() -> void:
	if not game.active or game.modal:
		return
	var font=ThemeDB.fallback_font
	if not mobile:
		var index=0
		for node in game.action_box.get_children():
			draw_string(font,node.global_position+Vector2(3,12),["E","C","Esc","F11"][index],HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("dcc99d"))
			index+=1
		index=0
		for node in game.bar.get_children():
			draw_string(font,node.global_position+Vector2(3,11),str(index+1),HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("dcc99d"))
			index+=1
		return
	var captions={"left":"<","right":">","jump":"SUBIR" if game.player.creative else "PULAR","down":"DESCER","mine":"MINERAR","place":"COLOCAR","attack":"ATACAR","inventory":"MOCHILA"}
	for action in regions:
		if action=="down" and not game.player.creative:
			continue
		var rect: Rect2=regions[action]
		var active=action in fingers.values()
		draw_style_box(style(active),rect)
		draw_string(font,rect.position+Vector2(0,rect.size.y/2+6),captions[action],HORIZONTAL_ALIGNMENT_CENTER,rect.size.x,15 if rect.size.x>=96 else 13,Color("efdfcc"))

func style(active: bool) -> StyleBoxFlat:
	var box=StyleBoxFlat.new()
	box.bg_color=Color("50335bed") if active else Color("14101bd9")
	box.border_color=Color("d6ab79") if active else Color("88705e")
	box.set_border_width_all(3)
	box.set_corner_radius_all(18)
	return box

func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT:
		release_all()
