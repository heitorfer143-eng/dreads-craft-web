extends Node2D

const World = preload("res://scripts/world.gd")
const Player = preload("res://scripts/player.gd")
const Mob = preload("res://scripts/mob.gd")
const Items = preload("res://scripts/items.gd")
const Saves = preload("res://scripts/save_game.gd")
const Backdrop = preload("res://scripts/backdrop.gd")
const LobbyBackdrop = preload("res://scripts/lobby_backdrop.gd")
const NPC = preload("res://scripts/npc.gd")
const VillageStructure = preload("res://scripts/village_structure.gd")
const Interior = preload("res://scripts/interior.gd")

var in_purity=false
var overworld: Node2D
var return_position=Vector2.ZERO
var boss: Node2D
var boss_defeated=false
var dialogue_index=0
var boss_panel: VBoxContainer
var boss_bar: ProgressBar
var boss_title: Label
var portal_button: Button

var world: Node2D
var player: CharacterBody2D
var enemies: Node2D
var npcs: Node2D
var structures: Node2D
var interior: Node2D
var in_structure := ""
var structure_return_position := Vector2.ZERO
var craft_override := false
var ui: CanvasLayer
var menu: PanelContainer
var menu_box: VBoxContainer
var hud: Control
var stats: Label
var time_label: Label
var hp_bar: ProgressBar
var food_bar: ProgressBar
var bar: HBoxContainer
var hotbar_back: Panel
var status: Label
var selected_name: Label
var mode_label: Label
var mode_frame: Panel
var menu_background: Control
var lobby_root: Control
var action_box: HBoxContainer
var sky: Node2D
var active = false
var modal = true
var selected = 2
var hotbar = [2,3,4,8,9,11]
var target = Vector2i(-1,-1)
var progress = 0.0
var last_target = Vector2i(-1,-1)
var clock = .32
var day = 1
var world_name = "Reino do Abismo"
var difficulty = 1
var auto_save = 0.0
var spawn_timer = 0.0
var mining_held = false
var pause_kind = ""
var message_time = 0.0
var selection: Node2D
var craft_category="all"
var portrait_icon: TextureRect
var device_controls: Control
var touch_aim=Vector2(80,-24)
var food_value: Label
var game_audio: Node
var menu_title: Label
var menu_tip_label: Label
var menu_tip_timer := 0.0
var menu_tip_index := 0
var menu_glow := 0.0
var current_npc=null
const LOBBY_TIPS = [
	"Clique com o botão direito para colocar blocos ou abrir a bancada.",
	"A noite é mais perigosa: prepare abrigo, espada e comida antes do escurecer.",
	"Use a roda do mouse ou as teclas 1–6 para trocar rapidamente de item.",
	"Carvão e ferro aparecem no subsolo. Uma picareta acelera bastante a mineração.",
	"Quedas altas causam dano. Planeje sua descida antes de explorar cavernas profundas."
]

func _ready() -> void:
	configure_input()
	var bg_layer=CanvasLayer.new()
	bg_layer.layer=-1
	add_child(bg_layer)
	sky=Backdrop.new()
	bg_layer.add_child(sky)
	ui=CanvasLayer.new()
	add_child(ui)
	build_ui()
	game_audio=preload("res://scripts/game_audio.gd").new()
	add_child(game_audio)
	device_controls=preload("res://scripts/device_controls.gd").new()
	device_controls.game=self
	ui.add_child(device_controls)
	show_main()
	get_tree().auto_accept_quit=false

func configure_input() -> void:
	var bindings={"left":[KEY_A,KEY_LEFT],"right":[KEY_D,KEY_RIGHT],"jump":[KEY_SPACE,KEY_W,KEY_UP],"down":[KEY_S,KEY_SHIFT,KEY_DOWN],"inventory":[KEY_E],"craft":[KEY_C],"attack":[KEY_F],"pause":[KEY_ESCAPE]}
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for code in bindings[action]:
			var event=InputEventKey.new()
			event.physical_keycode=code
			InputMap.action_add_event(action,event)

func panel_style(alpha: float=0.96, border: Color=Color("8d7257")) -> StyleBoxFlat:
	var style=StyleBoxFlat.new()
	style.bg_color=Color(0.045,0.032,0.065,alpha)
	style.border_color=border
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left=22
	style.content_margin_right=22
	style.content_margin_top=18
	style.content_margin_bottom=18
	style.shadow_color=Color(0,0,0,0.55)
	style.shadow_size=10
	return style

func compact_panel_style(alpha: float=0.86, border: Color=Color("5d526c"), margin: int=8) -> StyleBoxFlat:
	var style=StyleBoxFlat.new()
	style.bg_color=Color(0.035,0.025,0.055,alpha)
	style.border_color=border
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left=margin
	style.content_margin_right=margin
	style.content_margin_top=margin
	style.content_margin_bottom=margin
	style.shadow_color=Color(0,0,0,0.35)
	style.shadow_size=4
	return style

func button_style(color: Color, border: Color) -> StyleBoxFlat:
	var style=StyleBoxFlat.new()
	style.bg_color=color
	style.border_color=border
	style.set_border_width_all(1)
	style.set_corner_radius_all(7)
	style.content_margin_left=16
	style.content_margin_right=16
	style.content_margin_top=11
	style.content_margin_bottom=11
	return style

func label(text: String, size: int=18) -> Label:
	var node=Label.new()
	node.text=text
	node.add_theme_font_size_override("font_size",size)
	node.add_theme_color_override("font_color",Color("eee4d7"))
	return node

func button(text: String, callback: Callable) -> Button:
	var node=Button.new()
	node.focus_mode=Control.FOCUS_NONE
	node.text=text
	node.custom_minimum_size=Vector2(260,54)
	node.add_theme_stylebox_override("normal",button_style(Color("17131dee"),Color("66536f")))
	node.add_theme_stylebox_override("hover",button_style(Color("282035ff"),Color("a077bc")))
	node.add_theme_stylebox_override("pressed",button_style(Color("39254aff"),Color("c08de0")))
	node.add_theme_stylebox_override("disabled",button_style(Color("100d15aa"),Color("403748")))
	node.add_theme_font_size_override("font_size",17)
	node.add_theme_color_override("font_color",Color("eee7df"))
	node.add_theme_color_override("font_hover_color",Color("ffffff"))
	node.pressed.connect(callback)
	return node

func icon_button(path: String, tooltip: String, callback: Callable) -> Button:
	var node=Button.new()
	node.focus_mode=Control.FOCUS_NONE
	node.custom_minimum_size=Vector2(40,40)
	node.icon=load(path)
	node.expand_icon=true
	node.tooltip_text=tooltip
	node.add_theme_constant_override("icon_max_width",22)
	node.add_theme_stylebox_override("normal",button_style(Color("100c18ee"),Color("5e4a68")))
	node.add_theme_stylebox_override("hover",button_style(Color("241a31ff"),Color("a174c3")))
	node.add_theme_stylebox_override("pressed",button_style(Color("332244ff"),Color("d09bea")))
	node.pressed.connect(callback)
	for state in ["normal","hover","pressed"]:
		var box=node.get_theme_stylebox(state)
		box.content_margin_left=4
		box.content_margin_right=4
		box.content_margin_top=4
		box.content_margin_bottom=4
	return node

func make_texture(path: String, size: Vector2) -> TextureRect:
	var rect=TextureRect.new()
	rect.texture=load(path)
	rect.custom_minimum_size=size
	rect.size=size
	rect.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode=TextureRect.STRETCH_SCALE
	rect.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return rect

func build_ui() -> void:
	var build_badge=Label.new()
	build_badge.text="DREADS CRAFT • BUILD 10.3"
	build_badge.position=Vector2(12,get_viewport_rect().size.y-24)
	build_badge.add_theme_font_size_override("font_size",10)
	build_badge.add_theme_color_override("font_color",Color("80758b"))
	build_badge.mouse_filter=Control.MOUSE_FILTER_IGNORE
	ui.add_child(build_badge)
	menu_background=TextureRect.new()
	menu_background.texture=load("res://assets/ui/background_v11.svg")
	menu_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_background.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	menu_background.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	menu_background.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	menu_background.mouse_filter=Control.MOUSE_FILTER_IGNORE
	ui.add_child(menu_background)
	lobby_root=Control.new()
	lobby_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(lobby_root)

	hud=Control.new()
	hud.mouse_filter=Control.MOUSE_FILTER_IGNORE
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(hud)

	# HUD compacto criado do zero: sem molduras gigantes importadas.
	var stats_frame=Panel.new()
	stats_frame.name="StatsFrame"
	stats_frame.size=Vector2(244,90)
	stats_frame.add_theme_stylebox_override("panel",panel_style(0.92,Color("725f78")))
	hud.add_child(stats_frame)
	var stats_root=Control.new()
	stats_root.custom_minimum_size=Vector2(244,90)
	stats_frame.add_child(stats_root)
	var portrait=TextureRect.new()
	portrait_icon=portrait
	portrait.texture=load("res://assets/ui/spike_portrait.png")
	portrait.position=Vector2(10,12)
	portrait.size=Vector2(46,46)
	portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE
	stats_root.add_child(portrait)
	var spike_name=label("SPIKE",9)
	spike_name.position=Vector2(12,61)
	spike_name.size=Vector2(44,15)
	spike_name.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	stats_root.add_child(spike_name)
	var hp_caption=label("VIDA",9)
	hp_caption.position=Vector2(68,9)
	stats_root.add_child(hp_caption)
	var food_caption=label("FOME",9)
	food_caption.position=Vector2(68,43)
	stats_root.add_child(food_caption)
	hp_bar=ProgressBar.new()
	hp_bar.position=Vector2(68,24)
	hp_bar.size=Vector2(142,10)
	hp_bar.max_value=100
	hp_bar.show_percentage=false
	hp_bar.add_theme_stylebox_override("background",meter_style(Color("130c13")))
	hp_bar.add_theme_stylebox_override("fill",meter_style(Color("bf2548")))
	hp_bar.size=Vector2(142,10)
	stats_root.add_child(hp_bar)
	food_bar=ProgressBar.new()
	food_bar.position=Vector2(68,58)
	food_bar.size=Vector2(142,10)
	food_bar.max_value=100
	food_bar.show_percentage=false
	food_bar.add_theme_stylebox_override("background",meter_style(Color("130c13")))
	food_bar.add_theme_stylebox_override("fill",meter_style(Color("c28a36")))
	food_bar.size=Vector2(142,10)
	stats_root.add_child(food_bar)
	stats=label("",9)
	stats.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	stats.position=Vector2(186,7)
	stats.size=Vector2(82,18)
	stats.position=Vector2(146,7)
	food_value=label("",10)
	food_value.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	food_value.position=Vector2(174,42)
	food_value.size=Vector2(54,18)
	stats_root.add_child(food_value)
	stats_root.add_child(stats)

	var clock_frame=Panel.new()
	clock_frame.name="ClockFrame"
	clock_frame.size=Vector2(184,38)
	clock_frame.add_theme_stylebox_override("panel",panel_style(0.90,Color("725f78")))
	hud.add_child(clock_frame)
	time_label=label("",12)
	time_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	time_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	time_label.position=Vector2(7,5)
	time_label.size=Vector2(170,28)
	clock_frame.add_child(time_label)

	action_box=HBoxContainer.new()
	action_box.add_theme_constant_override("separation",5)
	hud.add_child(action_box)
	action_box.add_child(icon_button("res://assets/items/backpack.png","Inventário",show_inventory))
	action_box.add_child(icon_button("res://assets/items/table.png","Criação",show_craft))
	action_box.add_child(icon_button("res://assets/items/menu.png","Menu",show_pause))
	action_box.add_child(icon_button("res://assets/items/fullscreen.png","Tela cheia",toggle_fullscreen))
	mode_frame=Panel.new()
	mode_frame.size=Vector2(132,32)
	mode_frame.add_theme_stylebox_override("panel",panel_style(0.88,Color("725f78")))
	hud.add_child(mode_frame)
	mode_label=label("",10)
	mode_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	mode_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	mode_label.position=Vector2(7,5)
	mode_label.size=Vector2(118,22)
	mode_frame.add_child(mode_label)

	hotbar_back=Panel.new()
	hotbar_back.size=Vector2(404,58)
	hotbar_back.add_theme_stylebox_override("panel",panel_style(0.90,Color("725f78")))
	ui.add_child(hotbar_back)
	bar=HBoxContainer.new()
	bar.add_theme_constant_override("separation",5)
	bar.mouse_filter=Control.MOUSE_FILTER_PASS
	ui.add_child(bar)
	selected_name=label("",11)
	selected_name.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	ui.add_child(selected_name)
	status=label("",11)
	status.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	ui.add_child(status)

	menu=PanelContainer.new()
	menu.add_theme_stylebox_override("panel",panel_style(0.975,Color("9a7757")))
	ui.add_child(menu)
	var scroll=ScrollContainer.new()
	scroll.name="MenuScroll"
	scroll.custom_minimum_size=Vector2(560,360)
	scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	menu.add_child(scroll)
	menu_box=VBoxContainer.new()
	menu_box.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	menu_box.add_theme_constant_override("separation",12)
	scroll.add_child(menu_box)
	get_viewport().size_changed.connect(layout)
	layout()

func layout() -> void:
	if is_instance_valid(hp_bar):
		hp_bar.size=Vector2(142,10)
		food_bar.size=Vector2(142,10)
	var size=get_viewport_rect().size
	var mobile_layout=size.x <= 900
	var menu_scroll=menu.get_node_or_null("MenuScroll") if is_instance_valid(menu) else null
	if menu_scroll:
		if pause_kind=="creation":
			menu_scroll.custom_minimum_size=Vector2(minf(1040,size.x-54),minf(570,size.y-64))
		elif pause_kind=="craft":
			menu_scroll.custom_minimum_size=Vector2(minf(1140,size.x-24),minf(650,size.y-24))
		else:
			menu_scroll.custom_minimum_size=Vector2(minf(560,size.x-44),minf(360,size.y-56)) if mobile_layout else Vector2(560,360)
	if is_instance_valid(menu):
		var menu_size=Vector2(620,480)
		if pause_kind=="craft":
			menu_size=Vector2(minf(1180,size.x-40),minf(680,size.y-36))
		elif pause_kind=="creation":
			menu_size=Vector2(minf(1120,size.x-32),minf(660,size.y-28))
		elif pause_kind=="purity_dialogue":
			menu_size=Vector2(minf(920,size.x-60),minf(520,size.y-70))
		menu.position=Vector2((size.x-menu_size.x)/2.0,maxf(18,(size.y-menu_size.y)/2.0))
		menu.size=menu_size
	var stats_frame=hud.get_node_or_null("StatsFrame") if is_instance_valid(hud) else null
	if stats_frame:
		stats_frame.position=Vector2(6,6) if mobile_layout else Vector2(12,10)
		stats_frame.scale=Vector2(0.66,0.66) if size.x<560 else Vector2(0.76,0.76) if mobile_layout else Vector2.ONE
		stats_frame.size=Vector2(244,90)
	var clock_frame=hud.get_node_or_null("ClockFrame") if is_instance_valid(hud) else null
	if clock_frame:
		clock_frame.scale=Vector2(0.68,0.68) if size.x<560 else Vector2(0.78,0.78) if mobile_layout else Vector2.ONE
		clock_frame.position=Vector2((size.x-138)/2.0,6) if mobile_layout else Vector2((size.x-184)/2.0,10)
		clock_frame.size=Vector2(184,38)
	if is_instance_valid(action_box):
		action_box.visible=not mobile_layout
		action_box.scale=Vector2.ONE
		action_box.position=Vector2(size.x-183,10)
	if is_instance_valid(mode_frame):
		mode_frame.visible=not mobile_layout
		mode_frame.position=Vector2(size.x-144,56)
		mode_frame.size=Vector2(132,32)
	if is_instance_valid(hotbar_back):
		hotbar_back.scale=Vector2(0.62,0.62) if size.x<560 else Vector2(0.72,0.72) if mobile_layout else Vector2.ONE
		hotbar_back.position=Vector2((size.x-291)/2.0,size.y-126) if mobile_layout else Vector2((size.x-404)/2.0,size.y-68)
		hotbar_back.size=Vector2(404,58)
	if is_instance_valid(bar):
		bar.scale=Vector2(0.62,0.62) if size.x<560 else Vector2(0.72,0.72) if mobile_layout else Vector2.ONE
		bar.position=Vector2((size.x-246)/2.0,size.y-121) if mobile_layout else Vector2((size.x-342)/2.0,size.y-61)
	if is_instance_valid(selected_name):
		selected_name.visible=not mobile_layout
		selected_name.position=Vector2((size.x-240)/2.0,size.y-92)
		selected_name.size=Vector2(240,18)
	if is_instance_valid(status):
		status.position=Vector2(12,96) if mobile_layout else Vector2((size.x-420)/2.0,size.y-114)
		status.size=Vector2(size.x-24,18) if mobile_layout else Vector2(420,18)

func clear_menu(title: String, kind: String) -> void:
	var outer_scroll=menu.get_node_or_null("MenuScroll") if is_instance_valid(menu) else null
	if outer_scroll:
		outer_scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO
	for child in menu_box.get_children():
		menu_box.remove_child(child)
		child.queue_free()
	pause_kind=kind
	if is_instance_valid(lobby_root):
		lobby_root.hide()
	if is_instance_valid(menu_background):
		menu_background.show()
	modal=true
	if is_instance_valid(boss_panel):
		boss_panel.hide()
		portal_button.hide()
	if is_instance_valid(device_controls):
		device_controls.release_all()
	mining_held=false
	progress=0
	menu.show()
	if title != "":
		var title_label=label(title.to_upper(),24)
		title_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		menu_box.add_child(title_label)
		var rule=HSeparator.new()
		rule.modulate=Color("795c8c")
		menu_box.add_child(rule)
	if is_instance_valid(player):
		player.process_mode=Node.PROCESS_MODE_DISABLED
	if is_instance_valid(enemies):
		enemies.process_mode=Node.PROCESS_MODE_DISABLED
	layout()

func resume() -> void:
	if pause_kind=="craft":
		craft_override=false
	if not active:
		return
	modal=false
	menu.hide()
	menu_background.hide()
	if is_instance_valid(lobby_root):
		lobby_root.hide()
	player.process_mode=Node.PROCESS_MODE_INHERIT
	enemies.process_mode=Node.PROCESS_MODE_INHERIT
	refresh_hud()

func set_button_icon(node: Button, path: String) -> void:
	if ResourceLoader.exists(path):
		node.icon=load(path)
		node.expand_icon=true

func lobby_panel_style(alpha: float=0.84, border: Color=Color("6d537c")) -> StyleBoxFlat:
	var style=StyleBoxFlat.new()
	style.bg_color=Color(0.035,0.025,0.055,alpha)
	style.border_color=border
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	style.content_margin_left=18
	style.content_margin_right=18
	style.content_margin_top=16
	style.content_margin_bottom=16
	style.shadow_color=Color(0,0,0,0.50)
	style.shadow_size=12
	return style

func lobby_button(text: String, subtitle: String, icon_path: String, callback: Callable, primary: bool=false) -> Button:
	var node=Button.new()
	node.focus_mode=Control.FOCUS_NONE
	node.custom_minimum_size=Vector2(360,68)
	node.text=""
	var base=Color("2a1736ee") if primary else Color("130f1bee")
	var border=Color("b47ad5") if primary else Color("5d496b")
	node.add_theme_stylebox_override("normal",button_style(base,border))
	node.add_theme_stylebox_override("hover",button_style(Color("352144ff"),Color("c899e4")))
	node.add_theme_stylebox_override("pressed",button_style(Color("20152aff"),Color("d7b1ed")))
	node.pressed.connect(callback)
	var row=HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left=12
	row.offset_top=8
	row.offset_right=-12
	row.offset_bottom=-8
	row.mouse_filter=Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation",12)
	node.add_child(row)
	var ico=TextureRect.new()
	if ResourceLoader.exists(icon_path):
		ico.texture=load(icon_path)
	ico.custom_minimum_size=Vector2(40,40)
	ico.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	ico.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ico.mouse_filter=Control.MOUSE_FILTER_IGNORE
	row.add_child(ico)
	var copy=VBoxContainer.new()
	copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	copy.mouse_filter=Control.MOUSE_FILTER_IGNORE
	row.add_child(copy)
	var title=label(text,16)
	title.add_theme_color_override("font_color",Color("fff6e9"))
	copy.add_child(title)
	var sub=label(subtitle,11)
	sub.add_theme_color_override("font_color",Color("aa99b8"))
	copy.add_child(sub)
	var arrow=label("›",28)
	arrow.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	arrow.add_theme_color_override("font_color",Color("a776c3"))
	row.add_child(arrow)
	return node

func lobby_info_chip(text: String, icon_path: String) -> PanelContainer:
	var chip=PanelContainer.new()
	chip.add_theme_stylebox_override("panel",lobby_panel_style(0.65,Color("4b3b56")))
	chip.custom_minimum_size=Vector2(150,52)
	var row=HBoxContainer.new()
	row.add_theme_constant_override("separation",8)
	chip.add_child(row)
	var ico=TextureRect.new()
	if ResourceLoader.exists(icon_path):
		ico.texture=load(icon_path)
	ico.custom_minimum_size=Vector2(26,26)
	ico.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	ico.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(ico)
	var text_node=label(text,11)
	text_node.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	text_node.add_theme_color_override("font_color",Color("c9bbcf"))
	row.add_child(text_node)
	return chip

func difficulty_name(value: int) -> String:
	var names=["Pacífico","Fácil","Normal","Difícil"]
	return names[clampi(value,0,names.size()-1)]

func format_saved_time(data: Dictionary) -> String:
	if data.is_empty():
		return "Nenhum mundo salvo"
	var saved_day=int(data.get("day",1))
	var saved_clock=float(data.get("clock",0.32))
	var minutes=int(saved_clock*1440.0)
	return "Dia %d · %02d:%02d" % [saved_day,minutes/60,minutes%60]

func show_world_browser_v2() -> void:
	clear_menu("MEUS MUNDOS","worlds")
	var worlds=Saves.list_worlds()
	var intro=label("Escolha um reino para jogar. Você pode manter vários mundos salvos.",14)
	intro.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	intro.add_theme_color_override("font_color",Color("c7a6dd"))
	menu_box.add_child(intro)
	for meta in worlds:
		var card=PanelContainer.new()
		card.add_theme_stylebox_override("panel",panel_style(0.92,Color("765681")))
		card.custom_minimum_size=Vector2(560,104)
		menu_box.add_child(card)
		var row=HBoxContainer.new()
		row.add_theme_constant_override("separation",10)
		card.add_child(row)
		var copy=VBoxContainer.new()
		copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		row.add_child(copy)
		var title=label(str(meta.get("name","Reino")),18)
		title.add_theme_color_override("font_color",Color("f3dfca"))
		copy.add_child(title)
		var mode_text="Criativo" if bool(meta.get("creative",false)) else "Sobrevivência"
		copy.add_child(label("Dia %d  •  %s  •  %s" % [int(meta.get("day",1)),mode_text,difficulty_name(int(meta.get("difficulty",1)))],11))
		var play=button("JOGAR",func():
			Saves.select_world(str(meta.get("id","")))
			load_world()
		)
		play.custom_minimum_size=Vector2(105,44)
		row.add_child(play)
		var erase=button("EXCLUIR",func():
			Saves.select_world(str(meta.get("id","")))
			Saves.erase_save()
			show_world_browser_v2()
		)
		erase.custom_minimum_size=Vector2(105,44)
		erase.add_theme_color_override("font_color",Color("e7a6a6"))
		row.add_child(erase)
	if worlds.is_empty():
		var empty=label("Nenhum mundo salvo.",16)
		empty.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		menu_box.add_child(empty)
	menu_box.add_child(button("CRIAR NOVO MUNDO",show_creation))
	menu_box.add_child(button("VOLTAR",show_main))

func show_saved_world() -> void:
	clear_menu("Meus Mundos","worlds")
	var worlds=Saves.list_worlds()
	if worlds.is_empty():
		var empty=label("Nenhum mundo salvo ainda. Crie seu primeiro reino para ele aparecer aqui.",15)
		empty.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		empty.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		empty.custom_minimum_size=Vector2(520,80)
		menu_box.add_child(empty)
		menu_box.add_child(button("CRIAR NOVO MUNDO",show_creation))
		menu_box.add_child(button("VOLTAR",show_main))
		return
	var heading=label("Escolha um mundo para continuar",15)
	heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_color_override("font_color",Color("c7a6dd"))
	menu_box.add_child(heading)
	for meta in worlds:
		var card=PanelContainer.new()
		card.add_theme_stylebox_override("panel",panel_style(0.90,Color("735b80")))
		card.custom_minimum_size=Vector2(520,112)
		menu_box.add_child(card)
		var row=HBoxContainer.new()
		row.add_theme_constant_override("separation",12)
		card.add_child(row)
		var copy=VBoxContainer.new()
		copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		row.add_child(copy)
		var title=label(str(meta.get("name","Reino")),19)
		title.add_theme_color_override("font_color",Color("f1dfc8"))
		copy.add_child(title)
		var mode_text="Criativo" if bool(meta.get("creative",false)) else "Sobrevivência"
		var info=label("Dia %d · %s · %s" % [int(meta.get("day",1)),mode_text,difficulty_name(int(meta.get("difficulty",1)))],12)
		info.add_theme_color_override("font_color",Color("b8a9c1"))
		copy.add_child(info)
		var play=button("JOGAR",func():
			Saves.select_world(str(meta.get("id","")))
			load_world()
		)
		play.custom_minimum_size=Vector2(108,44)
		row.add_child(play)
		var erase=button("EXCLUIR",func():
			Saves.select_world(str(meta.get("id","")))
			Saves.erase_save()
			show_saved_world()
		)
		erase.custom_minimum_size=Vector2(108,44)
		erase.add_theme_color_override("font_color",Color("e7a6a6"))
		row.add_child(erase)
	menu_box.add_child(button("CRIAR NOVO MUNDO",show_creation))
	menu_box.add_child(button("VOLTAR",show_main))

func animate_lobby(delta: float) -> void:
	menu_glow+=delta
	if is_instance_valid(menu_title):
		var pulse=0.92+sin(menu_glow*1.7)*0.08
		menu_title.modulate=Color(1.0,0.93+0.04*pulse,1.0,0.94+0.06*pulse)
	if is_instance_valid(menu_tip_label):
		menu_tip_timer+=delta
		if menu_tip_timer>=5.0:
			menu_tip_timer=0.0
			menu_tip_index=(menu_tip_index+1)%LOBBY_TIPS.size()
			menu_tip_label.text="✦  "+LOBBY_TIPS[menu_tip_index]


func show_main() -> void:
	active=false
	if is_instance_valid(boss_panel):
		boss_panel.hide()
		portal_button.hide()
	hud.hide()
	bar.hide()
	hotbar_back.hide()
	selected_name.hide()
	status.hide()
	menu.hide()
	menu_background.show()
	lobby_root.show()
	for child in lobby_root.get_children():
		lobby_root.remove_child(child)
		child.queue_free()
	menu_tip_timer=0.0
	menu_tip_index=0

	var margin=MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",58)
	margin.add_theme_constant_override("margin_right",58)
	margin.add_theme_constant_override("margin_top",42)
	margin.add_theme_constant_override("margin_bottom",34)
	lobby_root.add_child(margin)

	var root=VBoxContainer.new()
	root.add_theme_constant_override("separation",14)
	margin.add_child(root)

	var header=HBoxContainer.new()
	header.custom_minimum_size=Vector2(1,82)
	root.add_child(header)
	var title_box=VBoxContainer.new()
	title_box.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	title_box.add_theme_constant_override("separation",0)
	header.add_child(title_box)
	menu_title=label("DREADS CRAFT",42)
	menu_title.add_theme_color_override("font_color",Color("f5eadf"))
	title_box.add_child(menu_title)
	var subtitle=label("REINO DO ABISMO",15)
	subtitle.add_theme_color_override("font_color",Color("c89ee0"))
	title_box.add_child(subtitle)
	var build=PanelContainer.new()
	build.add_theme_stylebox_override("panel",lobby_panel_style(0.66,Color("5e486a")))
	build.custom_minimum_size=Vector2(170,54)
	header.add_child(build)
	var build_text=label("ALPHA 0.8\nPC BUILD",11)
	build_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	build_text.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	build_text.add_theme_color_override("font_color",Color("baacc1"))
	build.add_child(build_text)

	var rule=HSeparator.new()
	rule.modulate=Color("6f4f82")
	root.add_child(rule)

	var body=HBoxContainer.new()
	body.size_flags_vertical=Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",22)
	root.add_child(body)

	var left=VBoxContainer.new()
	left.custom_minimum_size=Vector2(620,1)
	left.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation",12)
	body.add_child(left)
	var hook=label("SOBREVIVA AO QUE EXISTE DEPOIS DA LUZ.",24)
	hook.add_theme_color_override("font_color",Color("eadccf"))
	left.add_child(hook)
	var intro=label("Explore ruínas, construa abrigo, mine recursos e enfrente criaturas que despertam quando a noite toma o reino.",13)
	intro.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	intro.custom_minimum_size=Vector2(590,44)
	intro.add_theme_color_override("font_color",Color("b9acbf"))
	left.add_child(intro)

	var realm=PanelContainer.new()
	realm.add_theme_stylebox_override("panel",lobby_panel_style(0.80,Color("705580")))
	realm.custom_minimum_size=Vector2(600,205)
	left.add_child(realm)
	var realm_row=HBoxContainer.new()
	realm_row.add_theme_constant_override("separation",18)
	realm.add_child(realm_row)
	var spike_wrap=PanelContainer.new()
	spike_wrap.custom_minimum_size=Vector2(150,165)
	spike_wrap.add_theme_stylebox_override("panel",lobby_panel_style(0.58,Color("4b3957")))
	realm_row.add_child(spike_wrap)
	var spike=TextureRect.new()
	spike.texture=load("res://assets/sprites/normal_idle_0.png")
	var clean_mat=ShaderMaterial.new()
	var clean_shader=Shader.new()
	clean_shader.code="shader_type canvas_item; void fragment(){ vec4 c=texture(TEXTURE,UV); float bright=min(c.r,min(c.g,c.b)); if(UV.y>0.78 && bright>0.82 && abs(c.r-c.g)<0.10 && abs(c.g-c.b)<0.10){ discard; } COLOR=c; }"
	clean_mat.shader=clean_shader
	spike.material=clean_mat
	spike.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	spike.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	spike.custom_minimum_size=Vector2(120,145)
	spike_wrap.add_child(spike)
	var realm_copy=VBoxContainer.new()
	realm_copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	realm_copy.add_theme_constant_override("separation",8)
	realm_row.add_child(realm_copy)
	var saved_worlds=Saves.list_worlds()
	var saved=Saves.read_save() if not saved_worlds.is_empty() else {}
	var label_last=label("ÚLTIMO REINO",12)
	label_last.add_theme_color_override("font_color",Color("aa83c1"))
	realm_copy.add_child(label_last)
	var realm_name=label("Nenhum mundo salvo" if saved.is_empty() else str(saved.get("name","Reino do Abismo")),22)
	realm_name.add_theme_color_override("font_color",Color("f2e1cf"))
	realm_copy.add_child(realm_name)
	var realm_desc="Crie seu primeiro mundo e comece a jornada de Spike."
	if not saved.is_empty():
		var mode_text="Criativo" if bool(saved.get("creative",false)) else "Sobrevivência"
		realm_desc="%s\n%s · %s" % [format_saved_time(saved),mode_text,difficulty_name(int(saved.get("difficulty",1)))]
	var realm_info=label(realm_desc,13)
	realm_info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	realm_info.add_theme_color_override("font_color",Color("c6b9c8"))
	realm_copy.add_child(realm_info)
	var quote=label("“O abismo não dorme. Só espera.”",12)
	quote.add_theme_color_override("font_color",Color("95879f"))
	realm_copy.add_child(quote)

	var chips=HBoxContainer.new()
	chips.add_theme_constant_override("separation",10)
	left.add_child(chips)
	chips.add_child(lobby_info_chip("EXPLORAÇÃO","res://assets/items/torch.png"))
	chips.add_child(lobby_info_chip("CRAFTING","res://assets/items/table.png"))
	chips.add_child(lobby_info_chip("COMBATE","res://assets/items/sword_iron_v11.svg"))

	var right_panel=PanelContainer.new()
	right_panel.custom_minimum_size=Vector2(390,1)
	right_panel.add_theme_stylebox_override("panel",lobby_panel_style(0.86,Color("765786")))
	body.add_child(right_panel)
	var right=VBoxContainer.new()
	right.add_theme_constant_override("separation",10)
	right_panel.add_child(right)
	var menu_label=label("ESCOLHA SEU CAMINHO",13)
	menu_label.add_theme_color_override("font_color",Color("c9a6dc"))
	right.add_child(menu_label)
	var new_button=lobby_button("NOVO MUNDO","Crie um reino e escolha seu modo.","res://assets/items/sword_iron_v11.svg",show_creation,true)
	right.add_child(new_button)
	var continue_button=lobby_button("CONTINUAR","Retorne exatamente ao último save.","res://assets/items/backpack.png",load_world)
	continue_button.disabled=saved_worlds.is_empty()
	right.add_child(continue_button)
	right.add_child(lobby_button("MEUS MUNDOS","Escolha, crie ou exclua seus mundos.","res://assets/items/relic_vital.svg",show_world_browser_v2))
	right.add_child(lobby_button("CONFIGURAÇÕES","Tela cheia e controles do PC.","res://assets/items/menu.png",func(): show_settings(true)))
	var exit_button=lobby_button("SAIR","Fechar Dreads Craft.","res://assets/items/fullscreen.png",func(): get_tree().quit())
	right.add_child(exit_button)

	var tip_panel=PanelContainer.new()
	tip_panel.add_theme_stylebox_override("panel",lobby_panel_style(0.58,Color("493653")))
	tip_panel.custom_minimum_size=Vector2(1,46)
	root.add_child(tip_panel)
	menu_tip_label=label("✦  "+LOBBY_TIPS[0],12)
	menu_tip_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	menu_tip_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	menu_tip_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	menu_tip_label.add_theme_color_override("font_color",Color("c9bdce"))
	tip_panel.add_child(menu_tip_label)

	layout()


func show_creation() -> void:
	clear_menu("","creation")
	var mobile=get_viewport_rect().size.x<=900
	var field_w=minf(520.0,get_viewport_rect().size.x-92.0)

	var title=label("✦  CRIAÇÃO DE MUNDO  ✦",30 if not mobile else 24)
	title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color",Color("e5d7ff"))
	menu_box.add_child(title)
	var subtitle=label("Crie um novo mundo e comece a sua jornada.",13)
	subtitle.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color",Color("ad95c3"))
	menu_box.add_child(subtitle)

	var body=VBoxContainer.new() if mobile else HBoxContainer.new()
	body.add_theme_constant_override("separation",18)
	body.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	menu_box.add_child(body)

	var preview_panel=PanelContainer.new()
	preview_panel.add_theme_stylebox_override("panel",lobby_panel_style(0.84,Color("75538d")))
	preview_panel.custom_minimum_size=Vector2(field_w,210) if mobile else Vector2(330,390)
	body.add_child(preview_panel)
	var preview_box=VBoxContainer.new()
	preview_box.add_theme_constant_override("separation",8)
	preview_panel.add_child(preview_box)
	var preview=TextureRect.new()
	preview.texture=load("res://assets/ui/world_creation_preview_v11.svg")
	preview.custom_minimum_size=Vector2(field_w-26,160) if mobile else Vector2(300,300)
	preview.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	preview.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	preview_box.add_child(preview)
	var preview_text=label("Grandes aventuras começam com novos mundos.",12)
	preview_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	preview_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	preview_text.add_theme_color_override("font_color",Color("b7a6c8"))
	preview_box.add_child(preview_text)

	var form_panel=PanelContainer.new()
	form_panel.add_theme_stylebox_override("panel",lobby_panel_style(0.90,Color("765786")))
	form_panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	body.add_child(form_panel)
	var form=VBoxContainer.new()
	form.add_theme_constant_override("separation",10)
	form_panel.add_child(form)

	var name_label=label("Nome do mundo",14)
	name_label.add_theme_color_override("font_color",Color("f0e7f5"))
	form.add_child(name_label)
	var name_input=LineEdit.new()
	name_input.text=world_name
	name_input.placeholder_text="Meu mundo"
	name_input.custom_minimum_size=Vector2(field_w,48)
	name_input.add_theme_stylebox_override("normal",button_style(Color("100c18f2"),Color("7f5e95")))
	name_input.add_theme_stylebox_override("focus",button_style(Color("171022ff"),Color("c268e5")))
	form.add_child(name_input)

	var mode_label_create=label("Modo de jogo",14)
	mode_label_create.add_theme_color_override("font_color",Color("f0e7f5"))
	form.add_child(mode_label_create)
	var mode_group=ButtonGroup.new()
	var modes=VBoxContainer.new() if mobile else HBoxContainer.new()
	modes.add_theme_constant_override("separation",10)
	form.add_child(modes)
	var survival=Button.new()
	survival.text="🌿  SOBREVIVÊNCIA\nColete recursos e sobreviva."
	survival.toggle_mode=true
	survival.button_group=mode_group
	survival.button_pressed=true
	survival.custom_minimum_size=Vector2(field_w,70) if mobile else Vector2((field_w-10)/2.0,82)
	survival.add_theme_stylebox_override("normal",button_style(Color("17131fee"),Color("675277")))
	survival.add_theme_stylebox_override("hover",button_style(Color("2a1d36ff"),Color("b070cc")))
	survival.add_theme_stylebox_override("pressed",button_style(Color("351c48ff"),Color("e078ff")))
	modes.add_child(survival)
	var creative=Button.new()
	creative.text="🧱  CRIATIVO\nConstrua livremente."
	creative.toggle_mode=true
	creative.button_group=mode_group
	creative.custom_minimum_size=Vector2(field_w,70) if mobile else Vector2((field_w-10)/2.0,82)
	creative.add_theme_stylebox_override("normal",button_style(Color("17131fee"),Color("675277")))
	creative.add_theme_stylebox_override("hover",button_style(Color("2a1d36ff"),Color("b070cc")))
	creative.add_theme_stylebox_override("pressed",button_style(Color("351c48ff"),Color("e078ff")))
	modes.add_child(creative)

	var seed_label=label("Seed (opcional)",14)
	seed_label.add_theme_color_override("font_color",Color("f0e7f5"))
	form.add_child(seed_label)
	var seed_input=LineEdit.new()
	seed_input.placeholder_text="Digite uma seed..."
	seed_input.custom_minimum_size=Vector2(field_w,48)
	seed_input.add_theme_stylebox_override("normal",button_style(Color("100c18f2"),Color("7f5e95")))
	seed_input.add_theme_stylebox_override("focus",button_style(Color("171022ff"),Color("c268e5")))
	form.add_child(seed_input)
	var note=label("Deixe em branco para um mundo aleatório.",11)
	note.add_theme_color_override("font_color",Color("9f90ac"))
	form.add_child(note)

	var actions=VBoxContainer.new() if mobile else HBoxContainer.new()
	actions.add_theme_constant_override("separation",12)
	menu_box.add_child(actions)
	var back=button("←  VOLTAR",show_main)
	back.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	actions.add_child(back)
	var create=button("🌍  CRIAR MUNDO",func():
		world_name=name_input.text.strip_edges()
		if world_name.is_empty():
			world_name="Reino do Abismo"
		var seed_value=int(Time.get_unix_time_from_system()) if seed_input.text.is_empty() else seed_input.text.hash()
		Saves.active_id=""
		start_world(creative.button_pressed,seed_value)
		save_world()
	)
	create.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	create.add_theme_stylebox_override("normal",button_style(Color("3b1d4fff"),Color("d15df2")))
	create.add_theme_stylebox_override("hover",button_style(Color("51266cff"),Color("ec8cff")))
	actions.add_child(create)
	layout()

func show_settings(from_main: bool=false) -> void:
	clear_menu("Configurações","settings")
	var intro=label("Ajustes rápidos para jogar no PC.",14)
	intro.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	intro.add_theme_color_override("font_color",Color("c7a6dd"))
	menu_box.add_child(intro)
	var full_button=button("ALTERNAR TELA CHEIA",toggle_fullscreen)
	set_button_icon(full_button,"res://assets/items/fullscreen.png")
	full_button.custom_minimum_size=Vector2(520,54)
	menu_box.add_child(full_button)
	var controls=PanelContainer.new()
	controls.add_theme_stylebox_override("panel",panel_style(0.82,Color("5c4a67")))
	controls.custom_minimum_size=Vector2(520,150)
	menu_box.add_child(controls)
	var controls_text=label("CONTROLES\nA/D ou ←/→  mover     ·     Espaço/W  pular\nMouse esquerdo  minerar/atacar     ·     Mouse direito  colocar/interagir\nE  inventário     ·     C  crafting     ·     Esc  menu",13)
	controls_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	controls_text.add_theme_color_override("font_color",Color("d7cadb"))
	controls.add_child(controls_text)
	var note=label("Recomendado: 1280×720 ou superior.",12)
	note.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_color_override("font_color",Color("9f91a7"))
	menu_box.add_child(note)
	menu_box.add_child(button("VOLTAR",func():
		if from_main or not active:
			show_main()
		else:
			show_pause()
	))

func toggle_fullscreen() -> void:
	var mode=DisplayServer.window_get_mode()
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if mode==DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)

func start_world(creative: bool, seed_value: int) -> void:
	if is_instance_valid(overworld) and overworld!=world:
		overworld.queue_free()
	overworld=null
	in_purity=false
	sky.purity=false
	boss_defeated=false
	boss=null
	if is_instance_valid(boss_panel):
		boss_panel.hide()
	for node in [world,player,enemies,npcs,structures,interior,selection]:
		if is_instance_valid(node):
			remove_child(node)
			node.queue_free()
	world=World.new()
	add_child(world)
	world.generate(seed_value)
	player=Player.new()
	player.creative=creative
	player.spawn_position=Vector2(12*32+16,35*32-2)
	player.position=player.spawn_position
	add_child(player)
	player.died.connect(on_player_died)
	if creative:
		for id in Items.NAMES:
			player.inventory[id]=999
	world.camera=player.camera
	sky.camera=player.camera
	enemies=Node2D.new()
	add_child(enemies)
	npcs=Node2D.new()
	npcs.name="NPCs"
	add_child(npcs)
	structures=Node2D.new()
	structures.name="VillageStructures"
	add_child(structures)
	spawn_village_hub()
	spawn_world_npcs()
	selection=preload("res://scripts/selection.gd").new()
	add_child(selection)
	active=true
	clock=.32
	day=1
	selected=2
	auto_save=0
	spawn_timer=0
	hud.show()
	bar.show()
	hotbar_back.show()
	selected_name.show()
	status.show()
	resume()

func show_pause() -> void:
	if not active:
		return
	clear_menu(world_name,"pause")
	var option=OptionButton.new()
	for name_text in ["Pacífico","Fácil","Normal","Difícil"]:
		option.add_item(name_text)
	option.select(difficulty)
	option.item_selected.connect(func(index):
		difficulty=index
		if index==0 and not in_purity:
			for mob in enemies.get_children():
				mob.queue_free()
	)
	menu_box.add_child(option)
	menu_box.add_child(button("CONTINUAR",resume))
	menu_box.add_child(button("CONFIGURAÇÕES",func(): show_settings(false)))
	menu_box.add_child(button("SALVAR E SAIR AO MENU",func():
		if save_world():
			show_main()
	))

func refresh_hud() -> void:
	if not active:
		return
	portrait_icon.texture=load("res://assets/sprites/demon_idle_0.png" if player.creative else "res://assets/ui/spike_portrait.png")
	hp_bar.max_value=player.max_hp
	hp_bar.value=player.max_hp if player.creative else player.hp
	food_bar.value=100 if player.creative else player.food
	stats.text="LIVRE" if player.creative else "%d/%d" % [int(player.hp),int(player.max_hp)]
	food_value.text="LIVRE" if player.creative else str(int(player.food))
	var minutes=int(clock*1440)
	time_label.text="DIA %d  ·  %02d:%02d" % [day,minutes/60,minutes%60]
	mode_label.text="CRIATIVO" if player.creative else "SOBREVIVÊNCIA"
	selected_name.text=Items.NAMES.get(selected,"Item")
	for child in bar.get_children():
		bar.remove_child(child)
		child.queue_free()
	for id in hotbar:
		var slot=Button.new()
		slot.focus_mode=Control.FOCUS_NONE
		slot.custom_minimum_size=Vector2(52,44)
		slot.icon=load(Items.ICONS.get(id,"res://assets/items/dirt.png"))
		slot.expand_icon=true
		slot.add_theme_constant_override("icon_max_width",28)
		slot.tooltip_text=Items.NAMES.get(id,"Item")
		var normal=button_style(Color("0d0a12b8"),Color("4a3d50"))
		normal.set_corner_radius_all(4)
		for style in [normal]:
			style.content_margin_left=4
			style.content_margin_right=4
			style.content_margin_top=4
			style.content_margin_bottom=4
		var hover=button_style(Color("21172cdd"),Color("9e72be"))
		hover.set_corner_radius_all(4)
		var selected_style=button_style(Color("2d1840ee"),Color("c48ae6"))
		selected_style.set_border_width_all(2)
		selected_style.set_corner_radius_all(4)
		for style in [hover,selected_style]:
			style.content_margin_left=4
			style.content_margin_right=4
			style.content_margin_top=4
			style.content_margin_bottom=4
		slot.add_theme_stylebox_override("normal",selected_style if id==selected else normal)
		slot.add_theme_stylebox_override("hover",hover)
		slot.add_theme_stylebox_override("pressed",selected_style)
		slot.pressed.connect(func():
			selected=id
			refresh_hud()
		)
		var count=label("∞" if player.creative and id not in [11,12,13] else str(player.inventory.get(id,0)),9)
		count.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
		count.vertical_alignment=VERTICAL_ALIGNMENT_BOTTOM
		count.position=Vector2(30,27)
		count.size=Vector2(18,12)
		count.mouse_filter=Control.MOUSE_FILTER_IGNORE
		slot.add_child(count)
		bar.add_child(slot)
	layout()

func show_inventory() -> void:
	if not active:
		return
	clear_menu("Inventário","inventory")
	var subtitle=label("Itens coletados",14)
	subtitle.add_theme_color_override("font_color",Color("b8a5c5"))
	menu_box.add_child(subtitle)
	for id in Items.NAMES:
		if id==1 or (not player.creative and player.inventory.get(id,0)<=0):
			continue
		var amount="LIVRE" if player.creative else str(player.inventory.get(id,0))
		var row=button("%s    %s" % [Items.NAMES[id],amount],func():
			selected=id
			if not hotbar.has(id):
				hotbar[5]=id
			resume()
		)
		if Items.ICONS.has(id):
			row.icon=load(Items.ICONS[id])
			row.expand_icon=true
		row.custom_minimum_size=Vector2(520,54)
		row.alignment=HORIZONTAL_ALIGNMENT_LEFT
		menu_box.add_child(row)
	menu_box.add_child(button("FECHAR",resume))

func near_table() -> bool:
	if craft_override or in_structure=="blacksmith":
		return true
	if not is_instance_valid(world) or in_structure!="":
		return false
	var cell=Vector2i((player.position-Vector2(0,20))/32)
	for y in range(cell.y-2,cell.y+3):
		for x in range(cell.x-2,cell.x+3):
			if world.get_cell(Vector2i(x,y))==9:
				return true
	return false

func set_craft_category(category: String) -> void:
	craft_category=category
	show_craft()

func craft_category_button(text: String, key: String) -> Button:
	var b=button(text,func(): set_craft_category(key))
	b.custom_minimum_size=Vector2(158,48)
	b.alignment=HORIZONTAL_ALIGNMENT_LEFT
	if craft_category==key:
		b.add_theme_stylebox_override("normal",button_style(Color("2b1b27f4"),Color("d99a55")))
	return b

func craft_material_chip(id: int, required: int) -> PanelContainer:
	var chip=PanelContainer.new()
	chip.custom_minimum_size=Vector2(72,52)
	chip.add_theme_stylebox_override("panel",compact_panel_style(0.72,Color("4b4358"),5))
	var row=HBoxContainer.new()
	row.add_theme_constant_override("separation",4)
	chip.add_child(row)
	var icon=TextureRect.new()
	icon.texture=load(Items.ICONS.get(id,"res://assets/items/dirt.png"))
	icon.custom_minimum_size=Vector2(28,28)
	icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)
	var have=player.inventory.get(id,0)
	var amount=label("∞" if player.creative else "%d/%d" % [have,required],11)
	amount.add_theme_color_override("font_color",Color("9fe7b2") if player.creative or have>=required else Color("ef9b9b"))
	row.add_child(amount)
	return chip

func craft_recipe_card(recipe: Dictionary, has_table: bool) -> PanelContainer:
	var card=PanelContainer.new()
	card.custom_minimum_size=Vector2(900,112)
	card.add_theme_stylebox_override("panel",compact_panel_style(0.76,Color("443b50"),8))
	var row=HBoxContainer.new()
	row.add_theme_constant_override("separation",12)
	card.add_child(row)

	var icon_panel=PanelContainer.new()
	icon_panel.custom_minimum_size=Vector2(88,88)
	icon_panel.add_theme_stylebox_override("panel",compact_panel_style(0.68,Color("564665"),5))
	row.add_child(icon_panel)
	var icon=TextureRect.new()
	icon.texture=load(Items.CRAFT_ICONS.get(recipe.id,Items.ICONS.get(recipe.id,"res://assets/items/dirt.png")))
	icon.custom_minimum_size=Vector2(70,70)
	icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_panel.add_child(icon)

	var info_box=VBoxContainer.new()
	info_box.custom_minimum_size=Vector2(250,88)
	info_box.add_theme_constant_override("separation",3)
	row.add_child(info_box)
	var title=label(recipe.name,18)
	title.add_theme_color_override("font_color",Color("f0e8df"))
	info_box.add_child(title)
	var desc=label(Items.description(recipe.id),12)
	desc.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size=Vector2(240,55)
	desc.add_theme_color_override("font_color",Color("c5bad0"))
	info_box.add_child(desc)

	var stats_box=VBoxContainer.new()
	stats_box.custom_minimum_size=Vector2(190,88)
	stats_box.add_theme_constant_override("separation",3)
	row.add_child(stats_box)
	var stats_title=label("ATRIBUTOS",10)
	stats_title.add_theme_color_override("font_color",Color("d9a35e"))
	stats_box.add_child(stats_title)
	var stat_lines=Items.display_stats(recipe.id)
	if stat_lines.is_empty():
		stats_box.add_child(label("Item de criação / construção",11))
	else:
		for stat_text in stat_lines:
			var sl=label(str(stat_text),11)
			sl.add_theme_color_override("font_color",Color("bfc1da"))
			stats_box.add_child(sl)

	var materials=VBoxContainer.new()
	materials.custom_minimum_size=Vector2(205,88)
	materials.add_theme_constant_override("separation",5)
	row.add_child(materials)
	var mt=label("MATERIAIS",10)
	mt.add_theme_color_override("font_color",Color("d1c4dc"))
	materials.add_child(mt)
	var chips=HBoxContainer.new()
	chips.add_theme_constant_override("separation",5)
	materials.add_child(chips)
	for id in recipe.cost:
		chips.add_child(craft_material_chip(int(id),int(recipe.cost[id])))
	if recipe.table and not has_table and not player.creative:
		var need=label("Requer bancada próxima",10)
		need.add_theme_color_override("font_color",Color("e6a06f"))
		materials.add_child(need)

	var create=button("CRIAR",func():
		if Items.craft(player.inventory,recipe,player.creative,near_table()):
			status.text="%s criado" % recipe.name
			message_time=2.5
			refresh_hud()
		show_craft()
	)
	create.custom_minimum_size=Vector2(112,52)
	create.disabled=not Items.can_craft(player.inventory,recipe,player.creative,has_table)
	row.add_child(create)
	return card

func show_craft() -> void:
	if not active:
		return
	clear_menu("Dreads Craft · Criação","craft")
	var outer_scroll=menu.get_node_or_null("MenuScroll")
	if outer_scroll:
		outer_scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	var has_table=near_table()
	var root=HBoxContainer.new()
	root.add_theme_constant_override("separation",14)
	menu_box.add_child(root)

	var sidebar=VBoxContainer.new()
	sidebar.custom_minimum_size=Vector2(170,520)
	sidebar.add_theme_constant_override("separation",8)
	root.add_child(sidebar)
	var side_title=label("CRIAÇÃO",16)
	side_title.add_theme_color_override("font_color",Color("b889d2"))
	sidebar.add_child(side_title)
	sidebar.add_child(craft_category_button("▦  TODOS","all"))
	sidebar.add_child(craft_category_button("⛏  FERRAMENTAS","tools"))
	sidebar.add_child(craft_category_button("⚔  ARMAS","weapons"))
	sidebar.add_child(craft_category_button("◆  BLOCOS","blocks"))
	sidebar.add_child(craft_category_button("✦  DECORAÇÃO","decoration"))
	sidebar.add_child(craft_category_button("✧  ITENS ESPECIAIS","special"))
	var status_box=PanelContainer.new()
	status_box.add_theme_stylebox_override("panel",compact_panel_style(0.65,Color("4a3b58"),7))
	status_box.custom_minimum_size=Vector2(158,92)
	sidebar.add_child(status_box)
	var status_text=label("BANCADA\nCONECTADA" if has_table else "CRAFT MANUAL\nAproxime-se da bancada",11)
	status_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	status_text.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	status_text.add_theme_color_override("font_color",Color("cba1e4") if has_table else Color("b9a9c5"))
	status_box.add_child(status_text)
	var close=button("FECHAR",resume)
	close.custom_minimum_size=Vector2(158,44)
	sidebar.add_child(close)

	var content=VBoxContainer.new()
	content.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation",8)
	root.add_child(content)
	var header=HBoxContainer.new()
	content.add_child(header)
	var heading=label("Receitas disponíveis",16)
	heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	var hint=label("Itens avançados exigem bancada",11)
	hint.add_theme_color_override("font_color",Color("9f91ad"))
	header.add_child(hint)
	var recipe_scroll=ScrollContainer.new()
	recipe_scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	recipe_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	recipe_scroll.custom_minimum_size=Vector2(0,clampf(get_viewport_rect().size.y-210.0,330.0,520.0))
	recipe_scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_ALWAYS
	recipe_scroll.follow_focus=true
	recipe_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(recipe_scroll)
	var recipe_list=VBoxContainer.new()
	recipe_list.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	recipe_list.add_theme_constant_override("separation",8)
	recipe_scroll.add_child(recipe_list)
	var shown=0
	for recipe in Items.RECIPES:
		var category=Items.recipe_category(recipe.id)
		if craft_category!="all" and category!=craft_category:
			continue
		recipe_list.add_child(craft_recipe_card(recipe,has_table))
		shown+=1
	if shown==0:
		var empty=label("Nenhuma receita nesta categoria ainda.",15)
		empty.add_theme_color_override("font_color",Color("9588a2"))
		recipe_list.add_child(empty)

func _input(event: InputEvent) -> void:
	if event is InputEventMouse and event.device==InputEvent.DEVICE_ID_EMULATION:
		return
	if event is InputEventKey and event.pressed and event.physical_keycode==KEY_F11:
		toggle_fullscreen()
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and not event.pressed:
		mining_held=false
	if not active:
		return
	if modal and pause_kind=="purity_dialogue":
		return
	if event.is_action_pressed("pause"):
		if modal:
			resume()
		else:
			show_pause()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("inventory"):
		if modal and pause_kind=="inventory":
			resume()
		elif not modal:
			show_inventory()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("craft"):
		if modal and pause_kind=="craft":
			resume()
		elif not modal:
			show_craft()
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouse and event.device==InputEvent.DEVICE_ID_EMULATION:
		return
	if not active or modal:
		return
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		if event is InputEventScreenDrag or event.pressed:
			touch_aim=get_canvas_transform().affine_inverse()*event.position-player.position
			update_target()
		return
	if event.is_action_pressed("attack"):
		attack()
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode==KEY_R and find_near_npc()!=null:
			interact_near_npc()
			get_viewport().set_input_as_handled()
			return
		if event.physical_keycode>=KEY_1 and event.physical_keycode<=KEY_6:
			selected=hotbar[event.physical_keycode-KEY_1]
			refresh_hud()
	if event is InputEventMouseButton and event.pressed:
		if event.button_index==MOUSE_BUTTON_LEFT:
			if Items.SWORD_DAMAGE.has(selected):
				attack()
			else:
				mining_held=true
		elif event.button_index==MOUSE_BUTTON_RIGHT:
			update_target()
			use_selected()
		elif event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			var offset=1 if event.button_index==MOUSE_BUTTON_WHEEL_DOWN else -1
			selected=hotbar[posmod(hotbar.find(selected)+offset,hotbar.size())]
			refresh_hud()

func set_touch_action_target() -> void:
	if not is_instance_valid(player):
		return
	touch_aim=Vector2(player.face*105.0,-22.0)
	update_target()

func update_target() -> void:
	target=Vector2i(-1,-1)
	var mouse=player.position+touch_aim if is_instance_valid(device_controls) and device_controls.mobile else get_global_mouse_position()
	var origin=player.position-Vector2(0,24)
	if origin.distance_to(mouse)>144:
		return
	var cell=Vector2i(floor(mouse.x/32),floor(mouse.y/32))
	if cell.x<0 or cell.x>=320 or cell.y<0 or cell.y>=95:
		return
	var count=maxi(1,int(origin.distance_to(mouse)/4))
	for step in range(1,count):
		var point=origin.lerp(mouse,float(step)/count)
		var crossed=Vector2i(floor(point.x/32),floor(point.y/32))
		if crossed==cell:
			break
		if not player.body_rect().has_point(point) and world.get_cell(crossed) not in [0,16]:
			return
	target=cell

func place_block() -> bool:
	if in_purity or target.x<0 or world.get_cell(target)!=0 or selected not in [2,3,4,5,6,7,8,9,14,15,16]:
		return false
	var area=Rect2(Vector2(target)*32,Vector2(32,32))
	if player.body_rect().intersects(area):
		return false
	if not player.creative and player.inventory.get(selected,0)<1:
		return false
	world.set_cell(target,selected)
	if not player.creative:
		player.inventory[selected]-=1
	refresh_hud()
	return true

func attack() -> void:
	if player.attack_time>0:
		return
	player.attack_time=.35
	if is_instance_valid(game_audio): game_audio.hit()
	player.face=1 if (player.position+touch_aim if device_controls.mobile else get_global_mouse_position()).x>=player.position.x else -1
	for mob in enemies.get_children():
		var difference=mob.position-player.position
		if absf(difference.x)<85 and absf(difference.y)<65 and signf(difference.x)==player.face:
			mob.hit(Items.SWORD_DAMAGE.get(selected,8) if player.inventory.get(selected,0)>0 or player.creative else 8,300.0)

func eat() -> void:
	if player.inventory.get(10,0)>0:
		if not player.creative:
			player.inventory[10]-=1
		player.food=minf(100,player.food+25)
		refresh_hud()

func _process(delta: float) -> void:
	if not active:
		animate_lobby(delta)
		return
	if modal:
		return
	update_purity_hud()
	update_target()
	if not in_purity:
		var near_npc=find_near_npc()
		if near_npc!=null and message_time<=0:
			status.text="E / TOCAR: conversar com "+near_npc.npc_name
	if target!=last_target:
		progress=0
		last_target=target
	if not in_purity and mining_held and target.x>=0 and world.get_cell(target)!=0:
		var id=world.get_cell(target)
		if not player.creative and not Items.can_mine(id,player.inventory):
			progress=0
			status.text="Requer picareta de "+str({7:"pedra",14:"ferro",15:"diamante"}.get(id,"material superior"))
			message_time=1
		else:
			progress+=delta*Items.mining_speed(player.inventory)
		if player.creative or progress>=Items.HARDNESS.get(id,1.0):
			world.set_cell(target,0)
			if is_instance_valid(game_audio): game_audio.mine()
			var drop=2 if id==1 else id
			player.inventory[drop]=player.inventory.get(drop,0)+1
			progress=0
			refresh_hud()
	else:
		progress=0
	clock+=delta/720.0
	if clock>=1:
		clock-=1
		day+=1
	sky.clock=clock
	spawn_timer+=delta
	if spawn_timer>9:
		spawn_timer=0
		if not in_purity and difficulty>0 and (clock<.22 or clock>.78) and enemies.get_child_count()<8:
			spawn_mob()
	auto_save+=delta
	if auto_save>=20:
		auto_save=0
		save_world()
	if int(Time.get_ticks_msec()/250)%2==0:
		hp_bar.max_value=player.max_hp
		hp_bar.value=player.max_hp if player.creative else player.hp
		food_bar.value=100 if player.creative else player.food
		stats.text="LIVRE" if player.creative else "%d/%d" % [int(player.hp),int(player.max_hp)]
		food_value.text="LIVRE" if player.creative else str(int(player.food))
		var minutes=int(clock*1440)
		time_label.text="DIA %d  ·  %02d:%02d" % [day,minutes/60,minutes%60]
	message_time=maxf(0,message_time-delta)
	if message_time==0:
		status.text=""
	if mining_held and target.x>=0 and world.get_cell(target)!=0:
		var hardness=float(Items.HARDNESS.get(world.get_cell(target),1.0))
		var pct=clampi(int(progress/maxf(0.01,hardness)*100.0),0,99)
		status.text="⛏ MINERANDO  %d%%  %s" % [pct,"▰".repeat(pct/20)+"▱".repeat(5-pct/20)]
	queue_redraw()

func spawn_village_hub() -> void:
	if not is_instance_valid(structures) or not is_instance_valid(world):
		return
	var defs=[
		{"x":18,"kind":"blacksmith","name":"Forja de Borin","texture":"res://assets/structures/blacksmith.svg"},
		{"x":34,"kind":"market","name":"Mercado do Abismo","texture":"res://assets/structures/market.svg"},
		{"x":50,"kind":"chapel","name":"Capela da Pureza","texture":"res://assets/structures/chapel.svg"}
	]
	for data in defs:
		var x=int(data.x)
		var building=VillageStructure.new()
		building.configure(str(data.kind),str(data.name),str(data.texture),player,self)
		building.position=Vector2(x*32+16,world.surfaces[x]*32)
		structures.add_child(building)

func spawn_world_npcs() -> void:
	if not is_instance_valid(npcs) or not is_instance_valid(world):
		return
	# NPC sprite comes from the generated pixel-art asset, not a runtime stick-figure drawing.
	var npc=NPC.new()
	npc.setup("ferreiro","Borin, o Ferreiro",[
		"Se quer descer fundo, não economize na picareta.",
		"Minha bancada pode criar ferramentas e armas melhores.",
		"Ferro é bom. Diamante é melhor. Avarita não pertence a uma lâmina."
	],player)
	npc.position=Vector2(15*32+16,world.surfaces[15]*32-2)
	npc.interacted.connect(func(who): show_npc_dialogue(who))
	npcs.add_child(npc)

func find_near_npc():
	if not is_instance_valid(npcs) or in_purity or in_structure!="":
		return null
	var nearest=null
	var best=125.0
	for npc in npcs.get_children():
		var d=npc.global_position.distance_to(player.global_position)
		if d<best:
			best=d
			nearest=npc
	return nearest

func find_near_structure():
	if not is_instance_valid(structures) or in_purity or in_structure!="":
		return null
	var nearest=null
	var best=125.0
	for building in structures.get_children():
		if building.has_method("door_position"):
			var d=building.door_position().distance_to(player.global_position)
			if d<best:
				best=d
				nearest=building
	return nearest

func interact_near_npc() -> void:
	var npc=find_near_npc()
	if npc!=null:
		npc.interact()

func interact_nearby() -> bool:
	if not active or modal:
		return false
	if in_structure!="":
		if player.position.distance_to(Vector2(110,600))<135:
			exit_structure()
			return true
		return false
	var npc=find_near_npc()
	if npc!=null:
		npc.interact()
		return true
	var building=find_near_structure()
	if building!=null:
		building.interact()
		return true
	return false

func set_world_collision(enabled: bool) -> void:
	if not is_instance_valid(world):
		return
	for body in world.rows.values():
		if is_instance_valid(body):
			body.collision_layer=1 if enabled else 0

func enter_structure(kind: String, display_name: String) -> void:
	if in_structure!="" or in_purity:
		return
	structure_return_position=player.position
	in_structure=kind
	set_world_collision(false)
	world.hide()
	if is_instance_valid(npcs): npcs.hide()
	if is_instance_valid(structures): structures.hide()
	if is_instance_valid(enemies):
		enemies.hide()
		enemies.process_mode=Node.PROCESS_MODE_DISABLED
	sky.hide()
	interior=Interior.new()
	interior.configure(kind,display_name)
	add_child(interior)
	player.position=Vector2(640,600)
	player.velocity=Vector2.ZERO
	player.camera.limit_left=0
	player.camera.limit_right=1280
	player.camera.limit_top=0
	player.camera.limit_bottom=720
	player.camera.reset_smoothing()
	status.text="Dentro de "+display_name+" · aproxime-se da porta e use FALAR / ENTRAR para sair"
	message_time=4

func exit_structure() -> void:
	if in_structure=="":
		return
	if is_instance_valid(interior):
		interior.queue_free()
	interior=null
	in_structure=""
	world.show()
	set_world_collision(true)
	if is_instance_valid(npcs): npcs.show()
	if is_instance_valid(structures): structures.show()
	if is_instance_valid(enemies):
		enemies.show()
		enemies.process_mode=Node.PROCESS_MODE_INHERIT
	sky.show()
	player.position=structure_return_position
	player.velocity=Vector2.ZERO
	player.camera.limit_left=0
	player.camera.limit_right=320*32
	player.camera.limit_top=0
	player.camera.limit_bottom=96*32
	player.camera.reset_smoothing()

func show_npc_dialogue(npc) -> void:
	current_npc=npc
	clear_menu("","npc_dialogue")
	var card=PanelContainer.new()
	card.add_theme_stylebox_override("panel",compact_panel_style(0.97,Color("8b6e9d"),14))
	card.custom_minimum_size=Vector2(minf(760,get_viewport_rect().size.x-36),300)
	menu_box.add_child(card)
	var row=HBoxContainer.new()
	row.add_theme_constant_override("separation",18)
	card.add_child(row)
	var portrait=TextureRect.new()
	portrait.texture=load("res://assets/npcs/blacksmith_generated.svg")
	portrait.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.custom_minimum_size=Vector2(150,210)
	portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(portrait)
	var box=VBoxContainer.new()
	box.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation",12)
	row.add_child(box)
	var who=label(npc.npc_name,22)
	who.add_theme_color_override("font_color",Color("f0d99a"))
	box.add_child(who)
	var speech=label(npc.next_line(),17)
	speech.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	speech.custom_minimum_size=Vector2(0,105)
	box.add_child(speech)
	var craft_button=button("ABRIR BANCADA",func():
		craft_override=true
		show_craft()
	)
	craft_button.custom_minimum_size=Vector2(280,54)
	box.add_child(craft_button)
	var close=button("FECHAR",resume)
	close.custom_minimum_size=Vector2(280,50)
	box.add_child(close)
	layout()

func spawn_mob() -> void:
	var cell=clampi(int(player.position.x/32)+(18 if randf()>.5 else -18),2,317)
	var mob=Mob.new()
	var roll=randf()
	mob.kind="undead_knight" if roll>.88 else "corrupted_skeleton" if roll>.62 else "dark_slime" if roll>.38 else "skeleton" if roll>.16 else "wolf"
	mob.player=player
	mob.damage=[0,4,7,11][difficulty]
	mob.position=Vector2(cell*32,world.surfaces[cell]*32-2)
	mob.killed.connect(func():
		player.inventory[10]=player.inventory.get(10,0)+1
		refresh_hud()
	)
	enemies.add_child(mob)

func save_world() -> bool:
	if not active:
		return false
	var saved_world=overworld if in_purity else world
	var saved_position=player.position
	if in_purity:
		saved_position=return_position
	elif in_structure!="":
		saved_position=structure_return_position
	var data={"version":2,"name":world_name,"seed":saved_world.world_seed,"cells":saved_world.cells,"surfaces":saved_world.surfaces,"creative":player.creative,"position":[saved_position.x,saved_position.y],"hp":player.hp,"food":player.food,"inventory":player.inventory,"clock":clock,"day":day,"difficulty":difficulty,"saved_at":int(Time.get_unix_time_from_system()),"boss_defeated":boss_defeated,"in_purity":in_purity}
	if in_purity:
		data["arena_position"]=[player.position.x,player.position.y]
		data["boss_hp"]=boss.hp if is_instance_valid(boss) else 0
		data["intro_complete"]=is_instance_valid(boss) and boss.awakened
	var error=Saves.write(data)
	if error!=OK:
		status.text="Não foi possível salvar o mundo. Código %d" % error
		message_time=8
		return false
	return true

func load_world() -> void:
	var data=Saves.read_save()
	if data.is_empty():
		return
	start_world(bool(data.creative),int(data.seed))
	world_name=str(data.name)
	world.cells=data.cells
	world.surfaces.assign(data.surfaces)
	world.rebuild_collision()
	player.position=Vector2(data.position[0],data.position[1])
	for attempt in 96:
		var feet=Vector2i(player.position/32)
		if not world.is_solid(feet) and not world.is_solid(feet-Vector2i(0,1)):
			break
		player.position.y-=32
	player.hp=float(data.hp)
	player.food=float(data.food)
	player.inventory.clear()
	for id in data.inventory:
		player.inventory[int(id)]=int(data.inventory[id])
	clock=float(data.clock)
	day=int(data.day)
	difficulty=int(data.difficulty)
	boss_defeated=bool(data.get("boss_defeated",false))
	if bool(data.get("in_purity",false)):
		enter_purity(bool(data.get("intro_complete",false)))
		var arena_position=data.get("arena_position",[320,1118])
		player.position=Vector2(clampf(float(arena_position[0]),6*32,35*32),clampf(float(arena_position[1]),15*32,35*32-2))
		if is_instance_valid(boss):
			boss.hp=clampf(float(data.get("boss_hp",900)),1,900)
	refresh_hud()

func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_CLOSE_REQUEST:
		if not active or save_world():
			get_tree().quit()
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT and active and not modal:
		show_pause()

func meter_style(color: Color) -> StyleBoxFlat:
	var style=StyleBoxFlat.new()
	style.bg_color=color
	style.set_corner_radius_all(2)
	return style

func use_selected() -> void:
	if interact_nearby():
		return
	if target.x>=0 and world.get_cell(target)==16:
		use_portal()
	elif target.x>=0 and world.get_cell(target)==9:
		show_craft()
	elif selected==10:
		eat()
	else:
		place_block()

func nearby_portal() -> bool:
	if not active or not is_instance_valid(world):
		return false
	var feet=Vector2i(player.position/32)
	for y in range(feet.y-3,feet.y+2):
		for x in range(feet.x-3,feet.x+4):
			if world.get_cell(Vector2i(x,y))==16 and (Vector2(x,y)*32+Vector2(16,16)).distance_to(player.position)<112:
				return true
	return false

func use_portal() -> void:
	if not nearby_portal():
		return
	if in_purity:
		leave_purity()
	else:
		enter_purity()

func ensure_purity_hud() -> void:
	if is_instance_valid(boss_panel):
		return
	boss_panel=VBoxContainer.new()
	boss_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
	ui.add_child(boss_panel)
	boss_title=label("GUARDIÃO DA PUREZA",17)
	boss_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	boss_panel.add_child(boss_title)
	boss_bar=ProgressBar.new()
	boss_bar.custom_minimum_size=Vector2(380,14)
	boss_bar.max_value=900
	boss_bar.show_percentage=false
	boss_bar.add_theme_stylebox_override("fill",meter_style(Color("d8b06e")))
	boss_bar.add_theme_stylebox_override("background",meter_style(Color("292033")))
	boss_panel.add_child(boss_bar)
	portal_button=button("ENTRAR NA PUREZA",use_portal)
	ui.add_child(portal_button)
	portal_button.hide()
	boss_panel.hide()

func update_purity_hud() -> void:
	ensure_purity_hud()
	var size=get_viewport_rect().size
	boss_panel.position=Vector2((size.x-380)/2,88)
	boss_panel.visible=active and in_purity and is_instance_valid(boss) and not modal
	if is_instance_valid(boss):
		boss_bar.value=boss.hp
		boss_title.text="GUARDIÃO DA PUREZA  %d / %d" % [ceili(boss.hp),int(boss.max_hp)]
	portal_button.position=Vector2((size.x-250)/2,size.y-172)
	portal_button.size=Vector2(250,40)
	portal_button.visible=active and not modal and nearby_portal()
	portal_button.text="VOLTAR AO MUNDO" if in_purity else "ENTRAR NA PUREZA"

func enter_purity(skip_dialogue: bool=false) -> void:
	if in_purity:
		return
	ensure_purity_hud()
	return_position=player.position
	overworld=world
	remove_child(overworld)
	world=World.new()
	add_child(world)
	world.world_seed=overworld.world_seed
	for y in 96:
		var row=[]
		for x in 320:
			row.append(3 if y>=35 or x<=4 or x>=37 else 0)
		world.cells.append(row)
	world.surfaces.resize(320)
	world.surfaces.fill(35)
	world.cells[34][7]=16
	world.modulate=Color("dbedff")
	world.rebuild_collision()
	world.camera=player.camera
	for mob in enemies.get_children():
		enemies.remove_child(mob)
		mob.queue_free()
	player.position=Vector2(10*32,35*32-2)
	player.velocity=Vector2.ZERO
	player.max_fall_speed=0
	player.camera.limit_left=5*32
	player.camera.limit_right=37*32
	player.camera.reset_smoothing()
	in_purity=true
	sky.purity=true
	mining_held=false
	progress=0
	if not boss_defeated:
		boss=preload("res://scripts/purity_boss.gd").new()
		boss.player=player
		boss.position=Vector2(29*32,35*32)
		enemies.add_child(boss)
		boss.defeated.connect(on_boss_defeated)
		if skip_dialogue:
			boss.awakened=true
		else:
			dialogue_index=0
			show_purity_dialogue()
	update_purity_hud()

func show_purity_dialogue() -> void:
	var entries=preload("res://scripts/purity_dialogue.gd").ENTRIES
	var entry=entries[dialogue_index]
	if is_instance_valid(boss) and boss.has_method("set_expression"):
		boss.set_expression(str(entry.expression))
	clear_menu("","purity_dialogue")
	var screen=get_viewport_rect().size
	var mobile_dialogue=screen.x<=900
	var card=PanelContainer.new()
	card.add_theme_stylebox_override("panel",compact_panel_style(0.97,Color("8b6e9d"),12))
	card.custom_minimum_size=Vector2(minf(700,screen.x-36),250 if mobile_dialogue else 300)
	menu_box.add_child(card)
	var box=VBoxContainer.new()
	box.add_theme_constant_override("separation",8)
	card.add_child(box)
	var realm=label("✦  DIMENSÃO DA PUREZA  ✦",10 if mobile_dialogue else 12)
	realm.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	realm.add_theme_color_override("font_color",Color("b9dff3"))
	box.add_child(realm)
	var speaker=label(str(entry.speaker),15 if mobile_dialogue else 18)
	speaker.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	speaker.add_theme_color_override("font_color",Color("c7a6dd") if str(entry.speaker)=="SPIKE" else Color("f0d99a"))
	box.add_child(speaker)
	var text_node=label(str(entry.text),15 if mobile_dialogue else 19)
	text_node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	text_node.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	text_node.custom_minimum_size=Vector2(0,88 if mobile_dialogue else 110)
	text_node.add_theme_color_override("font_color",Color("f3edf5"))
	box.add_child(text_node)
	var stage=label(str(entry.stage),10 if mobile_dialogue else 12)
	stage.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	stage.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	stage.add_theme_color_override("font_color",Color("9fa4ba"))
	box.add_child(stage)
	var progress_label=label("%d / %d" % [dialogue_index+1,entries.size()],9)
	progress_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	progress_label.add_theme_color_override("font_color",Color("81778d"))
	box.add_child(progress_label)
	var action=button("LUTAR" if dialogue_index==entries.size()-1 else "CONTINUAR",advance_purity_dialogue)
	action.custom_minimum_size=Vector2(220,44 if mobile_dialogue else 50)
	box.add_child(action)
	layout()
	update_purity_hud()

func advance_purity_dialogue() -> void:
	dialogue_index+=1
	if dialogue_index>=preload("res://scripts/purity_dialogue.gd").ENTRIES.size():
		if is_instance_valid(boss):
			boss.set_expression("wrath")
			boss.awakened=true
		resume()
	else:
		show_purity_dialogue()

func leave_purity() -> void:
	if not in_purity:
		return
	for mob in enemies.get_children():
		enemies.remove_child(mob)
		mob.queue_free()
	boss=null
	remove_child(world)
	world.queue_free()
	world=overworld
	overworld=null
	add_child(world)
	world.camera=player.camera
	player.position=return_position
	player.velocity=Vector2.ZERO
	player.max_fall_speed=0
	player.camera.limit_left=0
	player.camera.limit_right=320*32
	player.camera.reset_smoothing()
	in_purity=false
	sky.purity=false
	resume()
	update_purity_hud()
	save_world()

func on_player_died() -> void:
	if in_purity:
		call_deferred("leave_purity")

func on_boss_defeated() -> void:
	boss_defeated=true
	boss=null
	player.inventory[12]=player.inventory.get(12,0)+1
	player.hp=player.max_hp
	clear_menu("A Pureza foi libertada","victory")
	menu_box.add_child(label("O Guardião caiu. A Relíquia Vital é sua.",18))
	menu_box.add_child(button("EXPLORAR A ARENA",resume))
	menu_box.add_child(button("VOLTAR AO MUNDO",leave_purity))
	boss_panel.hide()
	save_world()

func _exit_tree() -> void:
	if is_instance_valid(overworld) and not overworld.is_inside_tree():
		overworld.free()
