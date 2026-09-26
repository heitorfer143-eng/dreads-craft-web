extends Node2D

const World = preload("res://scripts/world.gd")
const Player = preload("res://scripts/player.gd")
const Mob = preload("res://scripts/mob.gd")
const Items = preload("res://scripts/items.gd")
const Saves = preload("res://scripts/save_game.gd")
const Accounts = preload("res://scripts/account_store.gd")
const PlayerHistory = preload("res://scripts/player_history.gd")
const CloudClient = preload("res://scripts/cloud_client.gd")
const Backdrop = preload("res://scripts/backdrop.gd")
const LobbyBackdrop = preload("res://scripts/lobby_backdrop.gd")
const NPC = preload("res://scripts/npc.gd")
const VillageStructure = preload("res://scripts/village_structure.gd")
const Interior = preload("res://scripts/interior.gd")
const Mel = preload("res://scripts/mel.gd")
const GeneratedAssets = preload("res://scripts/generated_assets.gd")
const GeneratedIntro = preload("res://scripts/generated_intro.gd")
const MultiplayerClient = preload("res://scripts/multiplayer_client.gd")
const DroppedItem = preload("res://scripts/dropped_item.gd")
const DeathBackpack = preload("res://scripts/death_backpack.gd")
const SoulProjectile = preload("res://scripts/soul_projectile.gd")
const LakeBoss = preload("res://scripts/lake_leviathan.gd")
const LakeArena = preload("res://scripts/lake_arena.gd")

var in_purity=false
var in_purity_realm=false
var overworld: Node2D
var return_position=Vector2.ZERO
var boss: Node2D
var boss_defeated=false
var dialogue_index=0
var boss_panel: VBoxContainer
var boss_bar: ProgressBar
var boss_title: Label
var portal_button: Button
var lake_boss: Node2D
var lake_boss_defeated := false
var lake_announced := false
var lake_discovered := false
var in_lake_temple := false
var lake_arena: Node2D
var lake_return_position := Vector2.ZERO

var world: Node2D
var player: CharacterBody2D
var enemies: Node2D
var npcs: Node2D
var structures: Node2D
var drops: Node2D
var death_bags: Node2D
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
var air_frame: Panel
var air_bar: ProgressBar
var air_value: Label
var transform_button: Button
var form_name_label: Label
var forms_unlocked: Dictionary = {"spike":true,"fox":false}
var current_form := "spike"
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
var selected = 0
var hotbar = [0,0,0,0,0,0,0,0,0]
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
var mel_quest_started := false
var mel: Area2D
var mel_tamed := false
var borin_quest_done := false
var monk_quest_done := false
var night_kills := 0
var polar_bear_defeated := false
var snow_announced := false
var snow_reached := false
var abyss_slime_kills := 0
var abyss_warden_kills := 0
var quest_states: Dictionary = {}
const QUEST_MEL := "mel_bones"
const QUEST_BORIN := "borin_supplies"
const QUEST_MERCHANT := "merchant_supplies"
const QUEST_ABYSS := "abyss_hunt"
const QUEST_MONK := "monk_hunt"
const QUEST_SNOW := "snow_hunt"
var online: Node
var multiplayer_active := false
var multiplayer_host := false
var online_player_name := "Spike"
var online_world_name := "Reino Online"
var online_room_code_entry := ""
var chat_panel: Panel
var chat_log: RichTextLabel
var chat_input: LineEdit
var chat_button: Button
var chat_close_button: Button
var chat_messages:Array=[]
var compass_frame:Panel
var compass_label:Label
var history_local_join_recorded:=false
var chest_inventories:Dictionary={}
var armor_equipment:Dictionary={"head":0,"chest":0,"legs":0,"feet":0}
var login_root:Control
var login_user:LineEdit
var login_password:LineEdit
var login_feedback:Label
var current_account:=""
var cloud:Node
var cloud_syncing:=false
var cloud_last_error:=""
var desert_announced:=false
const PLACEABLE_BLOCKS = [2,3,4,5,6,7,8,9,14,15,16,28,29,30,31]
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
	cloud=CloudClient.new()
	cloud.name="CloudClient"
	add_child(cloud)
	game_audio=preload("res://scripts/game_audio.gd").new()
	add_child(game_audio)
	device_controls=preload("res://scripts/device_controls.gd").new()
	device_controls.game=self
	ui.add_child(device_controls)
	# DeviceControls resolves the real touch/mobile state in _ready(). Re-layout now so
	# landscape phones do not accidentally keep the desktop-sized hotbar.
	layout()
	online=MultiplayerClient.new()
	online.game=self
	online.failed.connect(on_multiplayer_failed)
	online.room_ready.connect(on_multiplayer_room_ready)
	add_child(online)
	show_login()
	get_tree().auto_accept_quit=false

func configure_input() -> void:
	var bindings={"left":[KEY_A,KEY_LEFT],"right":[KEY_D,KEY_RIGHT],"jump":[KEY_SPACE,KEY_W,KEY_UP],"down":[KEY_S,KEY_SHIFT,KEY_DOWN],"inventory":[KEY_E],"craft":[KEY_C],"attack":[KEY_F],"drop":[KEY_Q],"pause":[KEY_ESCAPE],"chat":[KEY_T]}
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
	build_badge.text="DREADS CRAFT • BUILD 14.3.3 • BOSS + ORB FIX"
	build_badge.position=Vector2(12,get_viewport_rect().size.y-24)
	build_badge.add_theme_font_size_override("font_size",10)
	build_badge.add_theme_color_override("font_color",Color("80758b"))
	build_badge.mouse_filter=Control.MOUSE_FILTER_IGNORE
	ui.add_child(build_badge)
	menu_background=TextureRect.new()
	menu_background.texture=load("res://assets/backgrounds/dark_castles_generated.png")
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
	stats_root.size=Vector2(244,90)
	stats_root.clip_contents=true
	stats_frame.add_child(stats_root)
	var portrait=TextureRect.new()
	portrait_icon=portrait
	portrait.texture=load("res://assets/sprites/normal_idle_0.png")
	portrait.position=Vector2(10,12)
	portrait.size=Vector2(46,46)
	portrait.custom_minimum_size=Vector2(46,46)
	portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE
	stats_root.add_child(portrait)
	form_name_label=label("SPIKE",9)
	form_name_label.position=Vector2(8,61)
	form_name_label.size=Vector2(52,15)
	form_name_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	stats_root.add_child(form_name_label)
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

	air_frame=Panel.new()
	air_frame.name="AirFrame"
	air_frame.size=Vector2(194,34)
	air_frame.add_theme_stylebox_override("panel",panel_style(0.90,Color("607aa5")))
	air_frame.hide()
	hud.add_child(air_frame)
	var air_caption=label("AR",9)
	air_caption.position=Vector2(10,8)
	air_frame.add_child(air_caption)
	air_bar=ProgressBar.new()
	air_bar.position=Vector2(36,10)
	air_bar.size=Vector2(112,10)
	air_bar.max_value=8
	air_bar.value=8
	air_bar.show_percentage=false
	air_bar.add_theme_stylebox_override("background",meter_style(Color("101522")))
	air_bar.add_theme_stylebox_override("fill",meter_style(Color("6f9ed4")))
	air_frame.add_child(air_bar)
	air_value=label("100%",9)
	air_value.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	air_value.position=Vector2(150,6)
	air_value.size=Vector2(36,18)
	air_frame.add_child(air_value)

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
	chat_button=Button.new()
	chat_button.text="CHAT"
	chat_button.focus_mode=Control.FOCUS_NONE
	chat_button.custom_minimum_size=Vector2(58,40)
	chat_button.add_theme_font_size_override("font_size",10)
	chat_button.add_theme_stylebox_override("normal",button_style(Color("100c18ee"),Color("5e4a68")))
	chat_button.add_theme_stylebox_override("hover",button_style(Color("241a31ff"),Color("a174c3")))
	chat_button.add_theme_stylebox_override("pressed",button_style(Color("332244ff"),Color("d09bea")))
	chat_button.pressed.connect(toggle_multiplayer_chat)
	chat_button.hide()
	action_box.add_child(chat_button)
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
	transform_button=icon_button("res://assets/ui/transform.svg","Transformações",show_transformations)
	transform_button.name="TransformButton"
	hud.add_child(transform_button)

	hotbar_back=Panel.new()
	hotbar_back.size=Vector2(492,58)
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

	chat_panel=Panel.new()
	chat_panel.name="MultiplayerChat"
	chat_panel.size=Vector2(380,176)
	chat_panel.add_theme_stylebox_override("panel",compact_panel_style(0.92,Color("765786"),8))
	chat_panel.hide()
	ui.add_child(chat_panel)
	chat_log=RichTextLabel.new()
	chat_log.position=Vector2(9,8)
	chat_log.size=Vector2(362,116)
	chat_log.bbcode_enabled=false
	chat_log.scroll_active=true
	chat_log.scroll_following=true
	chat_log.add_theme_font_size_override("normal_font_size",12)
	chat_log.mouse_filter=Control.MOUSE_FILTER_IGNORE
	chat_panel.add_child(chat_log)
	chat_close_button=Button.new()
	chat_close_button.text="×"
	chat_close_button.focus_mode=Control.FOCUS_NONE
	chat_close_button.position=Vector2(342,6)
	chat_close_button.size=Vector2(30,26)
	chat_close_button.tooltip_text="Fechar chat"
	chat_close_button.add_theme_font_size_override("font_size",18)
	chat_close_button.pressed.connect(close_multiplayer_chat)
	chat_panel.add_child(chat_close_button)
	chat_input=LineEdit.new()
	chat_input.position=Vector2(9,132)
	chat_input.size=Vector2(362,34)
	chat_input.placeholder_text="Mensagem... (T para abrir)"
	chat_input.max_length=120
	chat_input.text_submitted.connect(submit_multiplayer_chat)
	chat_input.gui_input.connect(on_chat_input_event)
	chat_input.focus_exited.connect(func():
		if is_instance_valid(player):
			player.input_locked=false
	)
	chat_panel.add_child(chat_input)

	compass_frame=Panel.new()
	compass_frame.name="MultiplayerCompass"
	compass_frame.size=Vector2(176,24)
	compass_frame.add_theme_stylebox_override("panel",compact_panel_style(0.86,Color("6f557d"),7))
	compass_frame.hide()
	hud.add_child(compass_frame)
	compass_label=label("• aguardando",9)
	compass_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	compass_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	compass_label.position=Vector2(5,2)
	compass_label.size=Vector2(166,20)
	compass_label.add_theme_color_override("font_color",Color("eadfc7"))
	compass_frame.add_child(compass_label)

	menu=PanelContainer.new()
	menu.add_theme_stylebox_override("panel",panel_style(0.975,Color("9a7757")))
	ui.add_child(menu)
	var scroll=ScrollContainer.new()
	scroll.name="MenuScroll"
	scroll.custom_minimum_size=Vector2(560,360)
	scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
	scroll.scroll_deadzone=6
	scroll.follow_focus=true
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
	var mobile_layout=size.x <= 900 or (is_instance_valid(device_controls) and bool(device_controls.mobile))
	var menu_scroll=menu.get_node_or_null("MenuScroll") if is_instance_valid(menu) else null
	if menu_scroll:
		if pause_kind=="creation":
			menu_scroll.custom_minimum_size=Vector2(minf(1040,size.x-54),minf(570,size.y-64))
		elif pause_kind=="world_intro":
			menu_scroll.custom_minimum_size=Vector2(minf(900,size.x-42),minf(560,size.y-50))
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
		elif pause_kind=="world_intro":
			menu_size=Vector2(minf(940,size.x-30),minf(620,size.y-30))
		elif pause_kind=="purity_dialogue":
			menu_size=Vector2(minf(920,size.x-60),minf(520,size.y-70))
		menu.position=Vector2((size.x-menu_size.x)/2.0,maxf(18,(size.y-menu_size.y)/2.0))
		menu.size=menu_size
	var stats_frame=hud.get_node_or_null("StatsFrame") if is_instance_valid(hud) else null
	if stats_frame:
		stats_frame.position=Vector2(6,6) if mobile_layout else Vector2(12,10)
		stats_frame.scale=Vector2(0.78,0.78) if size.x<560 else Vector2(0.88,0.88) if mobile_layout else Vector2.ONE
		stats_frame.size=Vector2(244,90)
	var clock_frame=hud.get_node_or_null("ClockFrame") if is_instance_valid(hud) else null
	if clock_frame:
		clock_frame.scale=Vector2(0.78,0.78) if size.x<560 else Vector2(0.88,0.88) if mobile_layout else Vector2.ONE
		clock_frame.position=Vector2((size.x-138)/2.0,6) if mobile_layout else Vector2((size.x-184)/2.0,10)
		clock_frame.size=Vector2(184,38)
	if is_instance_valid(action_box):
		# Keep the familiar top-right inventory/crafting/menu/fullscreen buttons
		# on mobile too; the previous lake build accidentally hid the whole strip.
		action_box.visible=true
		action_box.scale=Vector2(0.82,0.82) if mobile_layout else Vector2.ONE
		var actions_width=(235.0 if multiplayer_active else 175.0)*action_box.scale.x
		action_box.position=Vector2(size.x-actions_width-12.0,8.0 if mobile_layout else 10.0)
	if is_instance_valid(mode_frame):
		mode_frame.visible=true
		mode_frame.scale=Vector2(0.82,0.82) if mobile_layout else Vector2.ONE
		mode_frame.position=Vector2(size.x-122.0,48.0) if mobile_layout else Vector2(size.x-144,56)
		mode_frame.size=Vector2(132,32)
	if is_instance_valid(transform_button):
		transform_button.scale=Vector2(0.82,0.82) if mobile_layout else Vector2.ONE
		transform_button.position=Vector2(size.x-48.0,82.0) if mobile_layout else Vector2(size.x-52.0,96.0)
	if is_instance_valid(air_frame):
		var stat_scale=Vector2(0.78,0.78) if size.x<560 else Vector2(0.88,0.88) if mobile_layout else Vector2.ONE
		air_frame.scale=stat_scale
		air_frame.position=Vector2(6,80) if mobile_layout else Vector2(12,104)
	if is_instance_valid(compass_frame):
		compass_frame.scale=Vector2(0.86,0.86) if mobile_layout else Vector2.ONE
		compass_frame.position=Vector2((size.x-compass_frame.size.x*compass_frame.scale.x)/2.0,48.0 if mobile_layout else 54.0)
	if is_instance_valid(chat_panel):
		chat_panel.size=Vector2(minf(380.0,size.x-24.0),156.0 if mobile_layout else 176.0)
		chat_panel.position=Vector2(12.0,maxf(92.0,size.y-chat_panel.size.y-(106.0 if mobile_layout else 78.0)))
		if is_instance_valid(chat_log):
			chat_log.size=Vector2(chat_panel.size.x-18.0,96.0 if mobile_layout else 116.0)
		if is_instance_valid(chat_input):
			chat_input.position=Vector2(9.0,112.0 if mobile_layout else 132.0)
			chat_input.size=Vector2(chat_panel.size.x-18.0,34.0)
		if is_instance_valid(chat_close_button):
			chat_close_button.position=Vector2(chat_panel.size.x-38.0,6.0)
	if is_instance_valid(hotbar_back):
		# Mobile hotbar is deliberately larger than desktop: 9 x 64px slots plus a
		# compact frame. It remains centered between the movement and action clusters.
		hotbar_back.scale=Vector2.ONE
		hotbar_back.size=Vector2(612,74) if mobile_layout else Vector2(492,58)
		hotbar_back.position=Vector2((size.x-hotbar_back.size.x)/2.0,size.y-94) if mobile_layout else Vector2((size.x-492)/2.0,size.y-68)
	if is_instance_valid(bar):
		bar.scale=Vector2.ONE
		var mobile_bar_width=592.0
		bar.position=Vector2((size.x-mobile_bar_width)/2.0,size.y-89) if mobile_layout else Vector2((size.x-450)/2.0,size.y-61)
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
		outer_scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
		outer_scroll.scroll_vertical=0
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
			delete_world_everywhere(str(meta.get("id","")))
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


func web_login_enabled() -> bool:
	return OS.has_feature("web")

func setup_web_login_overlay() -> void:
	if not web_login_enabled():
		return
	var js="""
(() => {
	let root=document.getElementById('dreads-native-login');
	if (!root) {
		root=document.createElement('div');
		root.id='dreads-native-login';
		root.innerHTML=`
			<div class="dc-login-card">
				<div class="dc-login-title">DREADS CRAFT</div>
				<div class="dc-login-sub">CONTA LOCAL · SEU REINO, SEU PROGRESSO</div>
				<label>Usuário</label>
				<input id="dreads-login-user" type="text" maxlength="20" autocomplete="username" autocapitalize="none" spellcheck="false" placeholder="Digite seu usuário">
				<label>Senha</label>
				<input id="dreads-login-pass" type="password" maxlength="72" autocomplete="current-password" placeholder="Digite sua senha">
				<div id="dreads-login-feedback"></div>
				<button id="dreads-login-enter" type="button">ENTRAR</button>
				<button id="dreads-login-create" type="button">CRIAR CONTA</button>
				<div class="dc-login-note">Conta local deste dispositivo. A senha nunca é salva em texto puro.</div>
			</div>`;
		const style=document.createElement('style');
		style.id='dreads-native-login-style';
		style.textContent=`
			#dreads-native-login{position:fixed;inset:0;z-index:2147483000;display:flex;align-items:center;justify-content:center;padding:12px;box-sizing:border-box;background:rgba(5,3,10,.24);font-family:Arial,sans-serif;color:#eee4d7;touch-action:manipulation}
			#dreads-native-login *{box-sizing:border-box}
			.dc-login-card{width:min(460px,calc(100vw - 24px));max-height:calc(100vh - 24px);overflow:auto;padding:20px;border:2px solid #9c6c48;border-radius:14px;background:rgba(13,9,18,.96);box-shadow:0 18px 60px rgba(0,0,0,.55)}
			.dc-login-title{text-align:center;font-size:34px;font-weight:800;letter-spacing:2px;color:#f1d7ad;margin-bottom:4px}
			.dc-login-sub{text-align:center;font-size:11px;color:#bca9c4;margin-bottom:18px}
			.dc-login-card label{display:block;font-size:14px;margin:10px 0 6px}
			.dc-login-card input{display:block;width:100%;height:48px;padding:0 14px;border:1px solid #806043;border-radius:7px;background:#0c0910;color:#fff;font-size:17px;outline:none;-webkit-user-select:text;user-select:text}
			.dc-login-card input:focus{border-color:#d7a568;box-shadow:0 0 0 2px rgba(215,165,104,.22)}
			.dc-login-card button{display:block;width:100%;height:50px;margin-top:10px;border:1px solid #8d5e48;border-radius:7px;background:#261722;color:#f6eadc;font-size:17px;font-weight:700}
			.dc-login-card button:active{transform:translateY(1px);background:#3a2232}
			#dreads-login-feedback{min-height:24px;margin-top:8px;text-align:center;color:#e5b9a8;font-size:13px}
			.dc-login-note{text-align:center;color:#9f92a6;font-size:10px;margin-top:12px}
			@media(max-height:620px){#dreads-native-login{align-items:flex-start;padding-top:8px}.dc-login-card{padding:12px}.dc-login-title{font-size:26px}.dc-login-sub{margin-bottom:8px}.dc-login-card input{height:42px}.dc-login-card button{height:43px}}
		`;
		document.head.appendChild(style);
		document.body.appendChild(root);
		document.getElementById('dreads-login-enter').addEventListener('click',()=>{window.dreadsLoginAction='login';});
		document.getElementById('dreads-login-create').addEventListener('click',()=>{window.dreadsLoginAction='create';});
		document.getElementById('dreads-login-pass').addEventListener('keydown',(e)=>{if(e.key==='Enter'){e.preventDefault();window.dreadsLoginAction='login';}});
	}
	root.style.display='flex';
	window.dreadsLoginAction='';
	const user=document.getElementById('dreads-login-user');
	if (user) setTimeout(()=>user.focus(),0);
})();
"""
	JavaScriptBridge.eval(js,true)
	JavaScriptBridge.eval("document.getElementById('dreads-login-user').value="+JSON.stringify(Accounts.last_user())+";",true)

func hide_web_login_overlay() -> void:
	if not web_login_enabled():
		return
	JavaScriptBridge.eval("const e=document.getElementById('dreads-native-login'); if(e)e.style.display='none'; window.dreadsLoginAction='';",true)

func sync_login_from_web() -> void:
	if not web_login_enabled():
		return
	var web_user=JavaScriptBridge.eval("(document.getElementById('dreads-login-user')||{}).value||''",true)
	var web_pass=JavaScriptBridge.eval("(document.getElementById('dreads-login-pass')||{}).value||''",true)
	if is_instance_valid(login_user):
		login_user.text=str(web_user)
	if is_instance_valid(login_password):
		login_password.text=str(web_pass)

func set_web_login_feedback(message:String) -> void:
	if not web_login_enabled():
		return
	JavaScriptBridge.eval("const e=document.getElementById('dreads-login-feedback'); if(e)e.textContent="+JSON.stringify(message)+";",true)

func poll_web_login() -> void:
	if not web_login_enabled():
		return
	var action=str(JavaScriptBridge.eval("window.dreadsLoginAction||''",true))
	if action=="":
		return
	JavaScriptBridge.eval("window.dreadsLoginAction='';",true)
	sync_login_from_web()
	if action=="create":
		attempt_create_account()
	elif action=="login":
		attempt_login()

func configure_login_field(field:LineEdit) -> void:
	field.editable=true
	field.focus_mode=Control.FOCUS_ALL
	field.mouse_filter=Control.MOUSE_FILTER_STOP
	field.virtual_keyboard_enabled=true
	field.caret_blink=true
	field.selecting_enabled=true
	field.gui_input.connect(func(event):
		if (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT):
			field.grab_focus()
	)

func show_login() -> void:
	active=false
	modal=true
	pause_kind="login"
	if is_instance_valid(login_root):
		login_root.queue_free()
	login_root=Control.new()
	login_root.name="LoginRoot"
	login_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	login_root.mouse_filter=Control.MOUSE_FILTER_PASS
	login_root.process_mode=Node.PROCESS_MODE_ALWAYS
	login_root.z_index=2000
	ui.add_child(login_root)
	if is_instance_valid(lobby_root):
		lobby_root.hide()
	if is_instance_valid(menu_background):
		menu_background.hide()
	if is_instance_valid(menu):
		menu.hide()
	if is_instance_valid(hud):
		hud.hide()
	var background=TextureRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter=Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists("res://assets/backgrounds/dreads_craft_cover.jpg"):
		background.texture=load("res://assets/backgrounds/dreads_craft_cover.jpg")
	background.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.modulate=Color("9e96a6")
	login_root.add_child(background)
	var shade=ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color=Color("08050dcc")
	shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
	login_root.add_child(shade)
	var center=CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter=Control.MOUSE_FILTER_PASS
	login_root.add_child(center)
	var viewport=get_viewport_rect().size
	var compact=viewport.y<620.0 or viewport.x<620.0
	var card=PanelContainer.new()
	card.name="LoginCard"
	card.custom_minimum_size=Vector2(clampf(viewport.x-24.0,300.0,460.0),clampf(viewport.y-20.0,320.0,500.0))
	card.mouse_filter=Control.MOUSE_FILTER_PASS
	card.add_theme_stylebox_override("panel",compact_panel_style(0.96,Color("9c6c48"),12))
	center.add_child(card)
	var scroll=ScrollContainer.new()
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO
	scroll.follow_focus=true
	card.add_child(scroll)
	var margin=MarginContainer.new()
	margin.add_theme_constant_override("margin_left",22 if not compact else 14)
	margin.add_theme_constant_override("margin_right",22 if not compact else 14)
	margin.add_theme_constant_override("margin_top",18 if not compact else 10)
	margin.add_theme_constant_override("margin_bottom",18 if not compact else 10)
	margin.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	scroll.add_child(margin)
	var box=VBoxContainer.new()
	box.name="LoginFields"
	box.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation",7 if compact else 12)
	margin.add_child(box)
	var title=label("DREADS CRAFT",28 if compact else 38)
	title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color",Color("f1d7ad"))
	box.add_child(title)
	var sub=label("CONTA LOCAL · SEU REINO, SEU PROGRESSO",10 if compact else 11)
	sub.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_color_override("font_color",Color("bca9c4"))
	box.add_child(sub)
	box.add_child(label("Usuário",12 if compact else 13))
	login_user=LineEdit.new()
	login_user.name="LoginUsername"
	login_user.placeholder_text="Digite seu usuário"
	login_user.max_length=20
	login_user.text=Accounts.last_user()
	login_user.custom_minimum_size=Vector2(0,40 if compact else 46)
	configure_login_field(login_user)
	box.add_child(login_user)
	box.add_child(label("Senha",12 if compact else 13))
	login_password=LineEdit.new()
	login_password.name="LoginPassword"
	login_password.placeholder_text="Digite sua senha"
	login_password.secret=true
	login_password.max_length=72
	login_password.custom_minimum_size=Vector2(0,40 if compact else 46)
	configure_login_field(login_password)
	login_password.text_submitted.connect(func(_value): attempt_login())
	box.add_child(login_password)
	login_feedback=label("",11 if compact else 12)
	login_feedback.name="LoginFeedback"
	login_feedback.custom_minimum_size=Vector2(0,24)
	login_feedback.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	login_feedback.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	login_feedback.add_theme_color_override("font_color",Color("e5b9a8"))
	box.add_child(login_feedback)
	var enter=button("ENTRAR",attempt_login)
	enter.name="LoginEnter"
	enter.custom_minimum_size=Vector2(0,46 if compact else 54)
	box.add_child(enter)
	var create=button("CRIAR CONTA",attempt_create_account)
	create.name="LoginCreate"
	create.custom_minimum_size=Vector2(0,42 if compact else 48)
	box.add_child(create)
	var note=label("Conta local deste dispositivo. A senha nunca é salva em texto puro.",9 if compact else 10)
	note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	note.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_color_override("font_color",Color("9f92a6"))
	box.add_child(note)
	login_user.call_deferred("grab_focus")
	setup_web_login_overlay()

func finish_account_login(user:String,password:String="",sync_cloud:bool=false) -> void:
	current_account=user.strip_edges()
	online_player_name=current_account
	Saves.set_account(current_account)
	Accounts.remember_user(current_account)
	if password!="" and not Accounts.has_accounts():
		Accounts.create_account(current_account,password)
	login_password.clear()
	if sync_cloud and is_instance_valid(cloud) and cloud.is_authenticated():
		set_web_login_feedback("Sincronizando seus mundos...")
		login_feedback.text="Sincronizando seus mundos..."
		await sync_account_worlds()
	hide_web_login_overlay()
	show_main()

func attempt_login() -> void:
	if not is_instance_valid(login_user) or not is_instance_valid(login_password):
		return
	sync_login_from_web()
	var user=login_user.text.strip_edges()
	var password=login_password.text
	if is_instance_valid(cloud) and cloud.is_enabled():
		login_feedback.text="Entrando na conta..."
		set_web_login_feedback("Entrando na conta...")
		login_cloud_account(user,password)
		return
	var result=Accounts.authenticate(user,password)
	if not bool(result.get("ok",false)):
		var message=str(result.get("message","Falha no login."))
		login_feedback.text=message
		set_web_login_feedback(message)
		return
	await finish_account_login(str(result.get("user","")),password,false)

func login_cloud_account(user:String,password:String) -> void:
	var result=await cloud.login(user,password)
	if bool(result.get("ok",false)):
		await finish_account_login(str(result.get("user",user)),password,true)
		return
	# Automatic one-time migration of an account/worlds created before cloud saves.
	var local=Accounts.authenticate(user,password)
	if int(result.get("status",0))==401 and bool(local.get("ok",false)):
		var migrated=await cloud.create_account(user,password)
		if bool(migrated.get("ok",false)):
			await finish_account_login(str(migrated.get("user",user)),password,true)
			return
	var message=str(result.get("message","Falha no login."))
	if int(result.get("status",0))==0:
		message="Servidor de contas indisponível. Tente novamente em alguns segundos."
	login_feedback.text=message
	set_web_login_feedback(message)

func attempt_create_account() -> void:
	if not is_instance_valid(login_user) or not is_instance_valid(login_password):
		return
	sync_login_from_web()
	var user=login_user.text.strip_edges()
	var password=login_password.text
	if is_instance_valid(cloud) and cloud.is_enabled():
		login_feedback.text="Criando sua conta online..."
		set_web_login_feedback("Criando sua conta online...")
		create_cloud_account(user,password)
		return
	var result=Accounts.create_account(user,password)
	if not bool(result.get("ok",false)):
		var message=str(result.get("message","Falha ao criar conta."))
		login_feedback.text=message
		set_web_login_feedback(message)
		return
	await finish_account_login(str(result.get("user","")),password,false)

func create_cloud_account(user:String,password:String) -> void:
	var result=await cloud.create_account(user,password)
	if not bool(result.get("ok",false)):
		var message=str(result.get("message","Falha ao criar conta."))
		login_feedback.text=message
		set_web_login_feedback(message)
		return
	# Keep a local credential/cache only as offline migration backup; cloud is authoritative.
	var local_created=Accounts.create_account(str(result.get("user",user)),password)
	if not bool(local_created.get("ok",false)):
		Accounts.remember_user(str(result.get("user",user)))
	await finish_account_login(str(result.get("user",user)),password,true)

func logout_account() -> void:
	if active and not multiplayer_active:
		save_world()
	Accounts.logout()
	if is_instance_valid(cloud):
		cloud.clear_session()
	Saves.clear_account()
	current_account=""
	online_player_name="Spike"
	show_login()

func sync_account_worlds() -> void:
	if not is_instance_valid(cloud) or not cloud.is_authenticated() or cloud_syncing:
		return
	cloud_syncing=true
	cloud_last_error=""
	var remote_result=await cloud.list_worlds()
	if not bool(remote_result.get("ok",false)):
		cloud_last_error=str(remote_result.get("message","Não foi possível sincronizar os mundos."))
		cloud_syncing=false
		return
	var remote_worlds:Array=remote_result.get("worlds",[])
	var remote_by_id:Dictionary={}
	for meta in remote_worlds:
		if meta is Dictionary:
			remote_by_id[str(meta.get("id",""))]=meta
	var local_worlds=Saves.list_worlds()
	var local_by_id:Dictionary={}
	for meta in local_worlds:
		if meta is Dictionary:
			local_by_id[str(meta.get("id",""))]=meta
	# Upload worlds that exist only locally, or whose local save is newer.
	for id in local_by_id.keys():
		var local_meta:Dictionary=local_by_id[id]
		var remote_meta:Dictionary=remote_by_id.get(id,{})
		if remote_meta.is_empty() or int(local_meta.get("saved_at",0))>int(remote_meta.get("saved_at",0)):
			var data=Saves.read_world_by_id(str(id))
			if not data.is_empty():
				await cloud.save_world(str(id),data)
	# Re-read metadata after uploads, then download missing/newer cloud worlds.
	remote_result=await cloud.list_worlds()
	if bool(remote_result.get("ok",false)):
		remote_worlds=remote_result.get("worlds",[])
	for meta in remote_worlds:
		if not meta is Dictionary:
			continue
		var id=str(meta.get("id",""))
		var local_meta:Dictionary=local_by_id.get(id,{})
		if local_meta.is_empty() or int(meta.get("saved_at",0))>int(local_meta.get("saved_at",0)):
			var loaded=await cloud.load_world(id)
			if bool(loaded.get("ok",false)) and loaded.get("data",{}) is Dictionary:
				Saves.import_world(id,loaded.get("data",{}))
	cloud_syncing=false

func upload_world_to_cloud(world_id:String,data:Dictionary) -> void:
	if world_id=="" or not is_instance_valid(cloud) or not cloud.is_authenticated():
		return
	var result=await cloud.save_world(world_id,data)
	if not bool(result.get("ok",false)):
		cloud_last_error=str(result.get("message","Falha ao salvar na nuvem."))

func delete_world_everywhere(world_id:String) -> void:
	Saves.select_world(world_id)
	Saves.erase_save()
	if is_instance_valid(cloud) and cloud.is_authenticated():
		await cloud.delete_world(world_id)
	show_world_browser_v2()

func show_main() -> void:
	hide_web_login_overlay()
	active=false
	modal=true
	if is_instance_valid(login_root):
		login_root.hide()
	if is_instance_valid(chat_panel):
		chat_panel.hide()
	if is_instance_valid(chat_button):
		chat_button.hide()
	if is_instance_valid(compass_frame):
		compass_frame.hide()
	if is_instance_valid(player):
		player.input_locked=false
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
	var subtitle=label("REINO DO ABISMO · CONTA "+current_account,15)
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
	var new_button=lobby_button("NOVO MUNDO","Crie um reino e escolha seu modo.","res://assets/ui/new_world_icon.svg",show_creation,true)
	right.add_child(new_button)
	right.add_child(lobby_button("MULTIPLAYER","Crie uma sala ou entre usando um código.","res://assets/items/item_16.svg",show_multiplayer))
	right.add_child(lobby_button("MEUS MUNDOS","Escolha, crie ou exclua seus mundos.","res://assets/items/item_14.svg",show_world_browser_v2))
	right.add_child(lobby_button("CONFIGURAÇÕES","Tela cheia, controles e conta.","res://assets/items/menu.png",func(): show_settings(true)))
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


func mobile_web_prompt(edit: LineEdit, title: String, uppercase: bool=false) -> void:
	if not OS.has_feature("web"):
		edit.grab_focus()
		return
	var js="window.prompt("+JSON.stringify(title)+","+JSON.stringify(edit.text)+")"
	var value=JavaScriptBridge.eval(js,true)
	if value==null:
		return
	var result=str(value).strip_edges()
	if uppercase:
		result=result.to_upper()
	edit.text=result
	edit.caret_column=edit.text.length()
	edit.text_changed.emit(edit.text)

func multiplayer_line_edit(placeholder:String,text_value:String="",prompt_title:String="",uppercase:bool=false) -> LineEdit:
	var edit=LineEdit.new()
	edit.text=text_value
	edit.placeholder_text=placeholder
	edit.max_length=32
	edit.virtual_keyboard_enabled=true
	edit.virtual_keyboard_type=LineEdit.KEYBOARD_TYPE_DEFAULT
	edit.focus_mode=Control.FOCUS_ALL
	edit.custom_minimum_size=Vector2(0,58)
	edit.add_theme_font_size_override("font_size",16)
	edit.add_theme_stylebox_override("normal",button_style(Color("100c18f2"),Color("7f5e95")))
	edit.add_theme_stylebox_override("focus",button_style(Color("171022ff"),Color("c268e5")))
	edit.gui_input.connect(func(event):
		if event is InputEventScreenTouch and event.pressed:
			mobile_web_prompt(edit,prompt_title if prompt_title!="" else placeholder,uppercase)
			get_viewport().set_input_as_handled()
	)
	return edit

func multiplayer_input_row(edit: LineEdit, prompt_title:String, uppercase:bool=false) -> HBoxContainer:
	var row=HBoxContainer.new()
	row.add_theme_constant_override("separation",8)
	row.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	edit.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	row.add_child(edit)
	var change=button("EDITAR",func(): mobile_web_prompt(edit,prompt_title,uppercase))
	change.custom_minimum_size=Vector2(100,58)
	row.add_child(change)
	return row

func show_multiplayer(error_text:String="") -> void:
	clear_menu("MULTIPLAYER","multiplayer")
	var mobile=get_viewport_rect().size.x<=900

	var subtitle=label("Crie um mundo online ou entre na sala de um amigo usando o código.",13)
	subtitle.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_color_override("font_color",Color("c7b4d3"))
	menu_box.add_child(subtitle)

	if mobile:
		var mobile_note=label("No celular: toque no campo ou em EDITAR para abrir o teclado.",11)
		mobile_note.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		mobile_note.add_theme_color_override("font_color",Color("a995b7"))
		menu_box.add_child(mobile_note)

	if error_text!="":
		var err=label(error_text,13)
		err.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		err.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		err.add_theme_color_override("font_color",Color("ef8e8e"))
		menu_box.add_child(err)

	var identity=PanelContainer.new()
	identity.add_theme_stylebox_override("panel",compact_panel_style(0.84,Color("6f557d"),10))
	identity.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	menu_box.add_child(identity)
	var identity_box=VBoxContainer.new()
	identity_box.add_theme_constant_override("separation",7)
	identity.add_child(identity_box)
	var name_title=label("IDENTIDADE DA CONTA",12)
	name_title.add_theme_color_override("font_color",Color("d9c4e6"))
	identity_box.add_child(name_title)
	online_player_name=current_account if current_account!="" else "Spike"
	var account_name=label("Jogando como  "+online_player_name,17)
	account_name.add_theme_color_override("font_color",Color("f1d7ad"))
	identity_box.add_child(account_name)
	var account_note=label("Este é o seu nome de usuário da conta e será exibido para os outros jogadores.",10)
	account_note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	account_note.add_theme_color_override("font_color",Color("a995b7"))
	identity_box.add_child(account_note)

	var columns=VBoxContainer.new() if mobile else HBoxContainer.new()
	columns.add_theme_constant_override("separation",14)
	columns.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	menu_box.add_child(columns)

	var create_panel=PanelContainer.new()
	create_panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	create_panel.add_theme_stylebox_override("panel",compact_panel_style(0.88,Color("6f557d"),12))
	columns.add_child(create_panel)
	var create_box=VBoxContainer.new()
	create_box.add_theme_constant_override("separation",9)
	create_panel.add_child(create_box)

	var create_header=HBoxContainer.new()
	create_header.add_theme_constant_override("separation",8)
	create_box.add_child(create_header)
	var create_icon=TextureRect.new()
	create_icon.texture=load("res://assets/items/item_16.svg")
	create_icon.custom_minimum_size=Vector2(38,38)
	create_icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	create_icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	create_header.add_child(create_icon)
	var ct=label("CRIAR SALA",20)
	ct.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	ct.add_theme_color_override("font_color",Color("e9d6f2"))
	create_header.add_child(ct)

	var cd=label("Escolha o nome do mundo. Depois o jogo gera um código para seus amigos.",12)
	cd.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	create_box.add_child(cd)

	var world_label=label("NOME DO MUNDO",11)
	world_label.add_theme_color_override("font_color",Color("bda6ca"))
	create_box.add_child(world_label)
	var world_edit=multiplayer_line_edit("Nome do mundo",online_world_name,"Nome do mundo multiplayer")
	world_edit.text_changed.connect(func(value):
		online_world_name=value.strip_edges()
	)
	create_box.add_child(multiplayer_input_row(world_edit,"Nome do mundo multiplayer"))

	var seed_title=label("SEED (OPCIONAL)",11)
	seed_title.add_theme_color_override("font_color",Color("bda6ca"))
	create_box.add_child(seed_title)
	var online_seed_edit=multiplayer_line_edit("Ex.: 12345 ou ABISMO","","Seed do mundo multiplayer")
	create_box.add_child(multiplayer_input_row(online_seed_edit,"Seed do mundo multiplayer"))

	var create_btn=button("CRIAR SALA ONLINE",func():
		online_player_name=current_account if current_account!="" else "Spike"
		online_world_name=world_edit.text.strip_edges()
		if online_player_name=="":
			show_multiplayer("Entre em uma conta primeiro.")
			return
		if online_world_name=="":
			show_multiplayer("Digite o nome do mundo.")
			return
		status.text="Conectando ao servidor..."
		online.create_room(online_player_name,seed_from_text(online_seed_edit.text),online_world_name)
	)
	create_btn.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	create_btn.custom_minimum_size=Vector2(0,54)
	create_box.add_child(create_btn)

	var join_panel=PanelContainer.new()
	join_panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	join_panel.add_theme_stylebox_override("panel",compact_panel_style(0.88,Color("6f557d"),12))
	columns.add_child(join_panel)
	var join_box=VBoxContainer.new()
	join_box.add_theme_constant_override("separation",9)
	join_panel.add_child(join_box)

	var join_header=HBoxContainer.new()
	join_header.add_theme_constant_override("separation",8)
	join_box.add_child(join_header)
	var join_icon=TextureRect.new()
	join_icon.texture=load("res://assets/items/item_14.svg")
	join_icon.custom_minimum_size=Vector2(38,38)
	join_icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	join_icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	join_header.add_child(join_icon)
	var jt=label("ENTRAR EM SALA",20)
	jt.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	jt.add_theme_color_override("font_color",Color("e9d6f2"))
	join_header.add_child(jt)

	var jd=label("Digite o código de 5 caracteres enviado pelo dono da sala.",12)
	jd.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	join_box.add_child(jd)

	var code_label=label("CÓDIGO DA SALA",11)
	code_label.add_theme_color_override("font_color",Color("bda6ca"))
	join_box.add_child(code_label)
	var room_edit=multiplayer_line_edit("Ex.: A7K2P",online_room_code_entry,"Código da sala",true)
	room_edit.max_length=5
	room_edit.text_changed.connect(func(value):
		online_room_code_entry=value.strip_edges().to_upper().left(5)
		if room_edit.text!=online_room_code_entry:
			room_edit.text=online_room_code_entry
			room_edit.caret_column=room_edit.text.length()
	)
	join_box.add_child(multiplayer_input_row(room_edit,"Código da sala",true))

	var join_btn=button("ENTRAR PELO CÓDIGO",func():
		online_player_name=current_account if current_account!="" else "Spike"
		online_room_code_entry=room_edit.text.strip_edges().to_upper()
		if online_player_name=="":
			show_multiplayer("Entre em uma conta primeiro.")
			return
		if online_room_code_entry.length()!=5:
			show_multiplayer("Digite o código completo de 5 caracteres.")
			return
		online.join_room(online_player_name,online_room_code_entry)
	)
	join_btn.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	join_btn.custom_minimum_size=Vector2(0,54)
	join_box.add_child(join_btn)

	var note=label("Multiplayer V1 · jogadores, movimento e blocos sincronizados em tempo real.",11)
	note.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_color_override("font_color",Color("9e90aa"))
	menu_box.add_child(note)
	menu_box.add_child(button("VOLTAR",show_main))
	layout()

func start_multiplayer_session(seed_value:int, online_world_name:String, is_host:bool) -> void:
	multiplayer_active=true
	multiplayer_host=is_host
	world_name=online_world_name
	difficulty=1
	start_world(false,seed_value)
	chat_messages.clear()
	if is_instance_valid(chat_log):
		chat_log.text=""
	if is_instance_valid(chat_panel):
		chat_panel.hide()
	if is_instance_valid(chat_button):
		chat_button.text="CHAT"
		chat_button.show()
	if is_instance_valid(compass_frame):
		compass_frame.show()
	if multiplayer_host and current_account!="":
		PlayerHistory.record(current_account,"join",online.room_code,world_name,online_player_name,online.local_id)
		history_local_join_recorded=true
	status.text="ONLINE · SALA "+online.room_code
	message_time=5
	layout()

func _record_local_multiplayer_leave() -> void:
	if not history_local_join_recorded:
		return
	if multiplayer_host and current_account!="" and is_instance_valid(online):
		PlayerHistory.record(current_account,"leave",online.room_code,world_name,online_player_name,online.local_id)
	history_local_join_recorded=false

func on_online_player_joined(data:Dictionary) -> void:
	if not multiplayer_host or current_account=="" or not is_instance_valid(online):
		return
	PlayerHistory.record(current_account,"join",online.room_code,world_name,str(data.get("name","Jogador")),str(data.get("id","")))

func on_online_player_left(data:Dictionary) -> void:
	if not multiplayer_host or current_account=="" or not is_instance_valid(online):
		return
	PlayerHistory.record(current_account,"leave",online.room_code,world_name,str(data.get("name","Jogador")),str(data.get("id","")))

func show_player_history() -> void:
	clear_menu("HISTÓRICO DE JOGADORES","player_history")
	var entries=PlayerHistory.list_for(current_account)
	var subtitle=label("Entradas e saídas registradas neste dispositivo para a sua conta.",11)
	subtitle.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	subtitle.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	menu_box.add_child(subtitle)
	if entries.is_empty():
		menu_box.add_child(label("Nenhum jogador registrado ainda.",13))
	else:
		var first=maxi(0,entries.size()-60)
		for i in range(entries.size()-1,first-1,-1):
			var entry:Dictionary=entries[i]
			var verb="entrou" if str(entry.get("event",""))=="join" else "saiu"
			var line="%s %s — %s %s · sala %s" % [str(entry.get("player","Jogador")),verb,str(entry.get("date","")),str(entry.get("time","")),str(entry.get("room",""))]
			var row=label(line,11)
			row.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
			menu_box.add_child(row)
	menu_box.add_child(button("VOLTAR",show_pause))

func update_multiplayer_compass() -> void:
	if not multiplayer_active or not is_instance_valid(online) or not is_instance_valid(player) or not is_instance_valid(compass_frame):
		if is_instance_valid(compass_frame):
			compass_frame.hide()
		return
	compass_frame.show()
	var markers:Array[String]=[]
	var zone=current_online_zone()
	for id in online.remote_players.keys():
		var remote=online.remote_players[id]
		if not is_instance_valid(remote) or str(remote.zone)!=zone:
			continue
		var delta_pos=Vector2(remote.target_position)-player.position
		var arrow="→"
		if absf(delta_pos.x)>=absf(delta_pos.y):
			arrow="←" if delta_pos.x<0 else "→"
		else:
			arrow="↑" if delta_pos.y<0 else "↓"
		var dist=maxi(0,int(round(delta_pos.length()/32.0)))
		markers.append("%s %s %dm" % [arrow,str(remote.player_name).left(7),dist])
		if markers.size()>=3:
			break
	compass_label.text=" · ".join(markers) if not markers.is_empty() else "• aguardando jogador"

func on_multiplayer_room_ready(code:String,_seed:int,_online_world_name:String,_host:bool) -> void:
	if active:
		status.text="ONLINE · SALA "+code+" · compartilhe esse código"
		message_time=8
		append_multiplayer_chat("SISTEMA","Sala "+code+" conectada.")

func open_multiplayer_chat() -> void:
	if not multiplayer_active or not active or not is_instance_valid(chat_input):
		return
	chat_panel.show()
	if is_instance_valid(chat_button):
		chat_button.text="CHAT"
	chat_input.grab_focus()
	if is_instance_valid(player):
		player.input_locked=true

func close_multiplayer_chat() -> void:
	if is_instance_valid(chat_input):
		chat_input.release_focus()
	if is_instance_valid(chat_panel):
		chat_panel.hide()
	if is_instance_valid(player):
		player.input_locked=false

func toggle_multiplayer_chat() -> void:
	if not multiplayer_active:
		return
	if is_instance_valid(chat_panel) and chat_panel.visible:
		close_multiplayer_chat()
	else:
		open_multiplayer_chat()

func on_chat_input_event(event:InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_ESCAPE:
		close_multiplayer_chat()
		get_viewport().set_input_as_handled()

func submit_multiplayer_chat(raw:String) -> void:
	if not multiplayer_active or not is_instance_valid(online):
		return
	var text=raw.strip_edges()
	chat_input.clear()
	if text!="":
		online.send_chat(text)
	close_multiplayer_chat()

func append_multiplayer_chat(sender:String,text:String) -> void:
	if not is_instance_valid(chat_log):
		return
	var clean_sender=sender.strip_edges().left(16)
	var clean_text=text.strip_edges().left(120)
	if clean_text=="":
		return
	chat_messages.append(("%s: %s" % [clean_sender,clean_text]) if clean_sender!="" else clean_text)
	while chat_messages.size()>8:
		chat_messages.pop_front()
	chat_log.text="\n".join(chat_messages)
	if multiplayer_active and is_instance_valid(chat_button) and (not is_instance_valid(chat_panel) or not chat_panel.visible):
		chat_button.text="CHAT •"

func on_online_chat(sender:String,text:String) -> void:
	append_multiplayer_chat(sender,text)

func on_multiplayer_failed(message:String) -> void:
	if active:
		multiplayer_active=false
		if is_instance_valid(chat_panel):
			chat_panel.hide()
		if is_instance_valid(chat_button):
			chat_button.hide()
		if is_instance_valid(player):
			player.input_locked=false
		status.text=message
		message_time=6
	else:
		show_multiplayer(message)

func leave_multiplayer() -> void:
	_record_local_multiplayer_leave()
	if is_instance_valid(online):
		online.disconnect_room(false)
	multiplayer_active=false
	multiplayer_host=false
	show_main()

func current_online_zone() -> String:
	if in_lake_temple:
		return "lake_temple"
	if in_purity:
		return "purity"
	if in_structure!="":
		return "inside:"+in_structure
	return "world"

func apply_online_block(cell:Vector2i,id:int) -> void:
	if not active or in_purity or not is_instance_valid(world):
		return
	if cell.x<0 or cell.x>=world.world_width() or cell.y<0 or cell.y>=World.HEIGHT-1:
		return
	world.set_cell(cell,id)

func on_multiplayer_disconnected() -> void:
	_record_local_multiplayer_leave()
	multiplayer_active=false
	if is_instance_valid(chat_panel):
		chat_panel.hide()
	if is_instance_valid(chat_button):
		chat_button.hide()
	if is_instance_valid(player):
		player.input_locked=false
	if active:
		status.text="Conexão multiplayer encerrada."
		message_time=5


func seed_from_text(raw:String) -> int:
	var value=raw.strip_edges()
	if value.is_empty():
		return int(Time.get_unix_time_from_system()*1000.0)+int(Time.get_ticks_msec()%100000)
	if value.is_valid_int():
		return int(value)
	# Text seeds are deterministic: the same text always becomes the same integer seed.
	return int(value.hash())


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
	preview.texture=GeneratedIntro.texture()
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
	name_input.max_length=32
	name_input.virtual_keyboard_enabled=true
	name_input.virtual_keyboard_type=LineEdit.KEYBOARD_TYPE_DEFAULT
	name_input.focus_mode=Control.FOCUS_ALL
	name_input.custom_minimum_size=Vector2(field_w,54 if mobile else 48)
	name_input.add_theme_stylebox_override("normal",button_style(Color("100c18f2"),Color("7f5e95")))
	name_input.add_theme_stylebox_override("focus",button_style(Color("171022ff"),Color("c268e5")))
	name_input.gui_input.connect(func(event):
		if event is InputEventScreenTouch and event.pressed:
			if OS.has_feature("web"):
				mobile_web_prompt(name_input,"Nome do mundo")
			else:
				name_input.grab_focus()
				name_input.caret_column=name_input.text.length()
			get_viewport().set_input_as_handled()
	)
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
	seed_input.max_length=40
	seed_input.virtual_keyboard_enabled=true
	seed_input.virtual_keyboard_type=LineEdit.KEYBOARD_TYPE_DEFAULT
	seed_input.focus_mode=Control.FOCUS_ALL
	seed_input.custom_minimum_size=Vector2(field_w,54 if mobile else 48)
	seed_input.add_theme_stylebox_override("normal",button_style(Color("100c18f2"),Color("7f5e95")))
	seed_input.add_theme_stylebox_override("focus",button_style(Color("171022ff"),Color("c268e5")))
	seed_input.gui_input.connect(func(event):
		if event is InputEventScreenTouch and event.pressed:
			if OS.has_feature("web"):
				mobile_web_prompt(seed_input,"Digite a seed")
			else:
				seed_input.grab_focus()
				seed_input.caret_column=seed_input.text.length()
			get_viewport().set_input_as_handled()
	)
	form.add_child(seed_input)
	var note=label("Mesma seed = mesmo mundo. Números são usados exatamente; texto também funciona.",11)
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
		var seed_value=seed_from_text(seed_input.text)
		Saves.active_id=""
		show_world_intro(creative.button_pressed,seed_value,0)
	)
	create.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	create.add_theme_stylebox_override("normal",button_style(Color("3b1d4fff"),Color("d15df2")))
	create.add_theme_stylebox_override("hover",button_style(Color("51266cff"),Color("ec8cff")))
	actions.add_child(create)
	layout()

func show_world_intro(creative_mode: bool, seed_value: int, page: int=0) -> void:
	clear_menu("","world_intro")
	var lines=[
		"Então... você acordou. Este é o Reino do Abismo, um lugar onde a luz já não alcança como antes.",
		"Quando a noite chega, criaturas despertam. Explore, mine recursos e encontre abrigo antes que elas encontrem você.",
		"Há vilas, ruínas e segredos espalhados por estas terras. Nem todo estranho é inimigo — e alguns precisarão da sua ajuda.",
		"Seu reino começa agora. Faça aliados, fortaleça-se e descubra o que existe depois da luz."
	]
	var title=label("NOVO MUNDO",28)
	title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color",Color("f0e4dd"))
	menu_box.add_child(title)
	var subtitle=label("ANTES QUE TUDO COMECE...",11)
	subtitle.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color",Color("b898c7"))
	menu_box.add_child(subtitle)

	var art_panel=PanelContainer.new()
	art_panel.add_theme_stylebox_override("panel",compact_panel_style(0.88,Color("785b86"),10))
	art_panel.custom_minimum_size=Vector2(0,210)
	menu_box.add_child(art_panel)
	var art=TextureRect.new()
	art.texture=GeneratedIntro.texture()
	art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	art.custom_minimum_size=Vector2(0,205)
	art_panel.add_child(art)

	var dialogue=PanelContainer.new()
	dialogue.add_theme_stylebox_override("panel",compact_panel_style(0.94,Color("65506f"),12))
	dialogue.custom_minimum_size=Vector2(0,180)
	menu_box.add_child(dialogue)
	var talk=VBoxContainer.new()
	talk.add_theme_constant_override("separation",8)
	dialogue.add_child(talk)
	var speaker=label("O VIAJANTE",15)
	speaker.add_theme_color_override("font_color",Color("e1bd79"))
	talk.add_child(speaker)
	var speech=label(lines[clampi(page,0,lines.size()-1)],18)
	speech.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	speech.custom_minimum_size=Vector2(0,90)
	speech.add_theme_color_override("font_color",Color("eee6ef"))
	talk.add_child(speech)
	var counter=label("%d / %d" % [page+1,lines.size()],10)
	counter.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	counter.add_theme_color_override("font_color",Color("978aa0"))
	talk.add_child(counter)

	var actions=HBoxContainer.new()
	actions.add_theme_constant_override("separation",10)
	menu_box.add_child(actions)
	var back=button("VOLTAR",show_creation)
	back.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	actions.add_child(back)
	if page<lines.size()-1:
		var next=button("CONTINUAR  ›",func(): show_world_intro(creative_mode,seed_value,page+1))
		next.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		next.add_theme_stylebox_override("normal",button_style(Color("351c48e8"),Color("bf70dc")))
		actions.add_child(next)
	else:
		var begin=button("COMEÇAR JORNADA",func():
			start_world(creative_mode,seed_value)
			save_world()
		)
		begin.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		begin.add_theme_stylebox_override("normal",button_style(Color("3c214be8"),Color("e09a6b")))
		actions.add_child(begin)
	layout()

func show_settings(from_main: bool=false) -> void:
	clear_menu("Configurações","settings")
	var intro=label("Ajustes rápidos para PC, Android e iPhone.",14)
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
	var controls_text=label("CONTROLES\nA/D ou ←/→  mover     ·     Espaço/W  pular\nMouse esquerdo  minerar/atacar     ·     Mouse direito  colocar/interagir\nE  inventário     ·     C  crafting     ·     Q  dropar item     ·     Esc  menu",13)
	controls_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	controls_text.add_theme_color_override("font_color",Color("d7cadb"))
	controls.add_child(controls_text)
	var note=label("iPhone: o jogo também pode ser adicionado à Tela de Início para abrir sem a barra do navegador.",12)
	note.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_color_override("font_color",Color("9f91a7"))
	menu_box.add_child(note)
	if current_account!="":
		var account_panel=PanelContainer.new()
		account_panel.add_theme_stylebox_override("panel",panel_style(0.82,Color("5c4a67")))
		account_panel.custom_minimum_size=Vector2(520,108)
		menu_box.add_child(account_panel)
		var account_box=VBoxContainer.new()
		account_box.add_theme_constant_override("separation",8)
		account_panel.add_child(account_box)
		var account_label=label("CONTA · "+current_account,13)
		account_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		account_label.add_theme_color_override("font_color",Color("d9c4e6"))
		account_box.add_child(account_label)
		var logout_button=button("SAIR DA CONTA",logout_account)
		logout_button.custom_minimum_size=Vector2(0,48)
		account_box.add_child(logout_button)
	menu_box.add_child(button("VOLTAR",func():
		if from_main or not active:
			show_main()
		else:
			show_pause()
	))

func toggle_fullscreen() -> void:
	if OS.has_feature("web"):
		# Keep a single ESC press available to the game while in browser fullscreen.
		# Chrome supports Keyboard Lock in fullscreen; other browsers still receive
		# preventDefault as a best-effort fallback. Holding ESC remains the browser's
		# emergency way out of fullscreen.
		var js="(function(){const d=document,e=d.documentElement;const ios=/iPad|iPhone|iPod/.test(navigator.userAgent);if(!window.__dreadsFullscreenKeys){d.addEventListener('keydown',(ev)=>{if(d.fullscreenElement&&ev.key==='Escape'){ev.preventDefault();}},true);d.addEventListener('fullscreenchange',()=>{if(!d.fullscreenElement&&navigator.keyboard&&navigator.keyboard.unlock){try{navigator.keyboard.unlock();}catch(_){}}});window.__dreadsFullscreenKeys=true;}if(d.fullscreenElement){if(navigator.keyboard&&navigator.keyboard.unlock){try{navigator.keyboard.unlock();}catch(_){}}d.exitFullscreen&&d.exitFullscreen();return 'exit';}if(e.requestFullscreen){Promise.resolve(e.requestFullscreen({navigationUI:'hide'})).then(()=>{if(navigator.keyboard&&navigator.keyboard.lock){navigator.keyboard.lock(['Escape']).catch(()=>{});}}).catch(()=>{});return 'native';}if(e.webkitRequestFullscreen){e.webkitRequestFullscreen();return 'webkit';}d.body.style.margin='0';d.body.style.padding='0';d.body.style.overflow='hidden';e.style.overflow='hidden';d.body.style.position='fixed';d.body.style.inset='0';d.body.style.width='100vw';d.body.style.height='100dvh';window.scrollTo(0,1);return ios?'ios-fallback':'fallback';})()"
		var result=str(JavaScriptBridge.eval(js,true))
		if result=="ios-fallback":
			status.text="Modo tela cheia do iPhone ativado · para esconder a barra do Safari, abra pela Tela de Início"
			message_time=6
			return
	var mode=DisplayServer.window_get_mode()
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if mode==DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)

func start_world(creative: bool, seed_value: int) -> void:
	if is_instance_valid(overworld) and overworld!=world:
		overworld.queue_free()
	overworld=null
	in_purity=false
	in_purity_realm=false
	sky.purity=false
	boss_defeated=false
	boss=null
	lake_boss=null
	lake_boss_defeated=false
	lake_announced=false
	lake_discovered=false
	in_lake_temple=false
	lake_arena=null
	forms_unlocked={"spike":true,"fox":false}
	current_form="spike"
	mel_tamed=false
	mel_quest_started=false
	borin_quest_done=false
	monk_quest_done=false
	night_kills=0
	polar_bear_defeated=false
	snow_announced=false
	desert_announced=false
	chest_inventories.clear()
	armor_equipment={"head":0,"chest":0,"legs":0,"feet":0}
	reset_quest_progress()
	if is_instance_valid(boss_panel):
		boss_panel.hide()
	for node in [world,player,enemies,npcs,structures,drops,death_bags,interior,selection,mel]:
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
	player.set_form(current_form)
	apply_armor_equipment()
	player.set_world_bounds(float(World.WORLD_MIN_X),float(World.WORLD_MAX_X),float(World.WORLD_MIN_Y),float(World.WORLD_MAX_Y))
	player.died.connect(on_player_died)
	if creative:
		for id in Items.NAMES:
			player.inventory[id]=999
		hotbar=[2,3,4,8,9,11,16,19,22]
		selected=2
	else:
		hotbar=[0,0,0,0,0,0,0,0,0]
		selected=0
	world.camera=player.camera
	player.camera.limit_left=World.WORLD_MIN_X
	player.camera.limit_right=World.WORLD_MAX_X
	player.camera.limit_top=World.WORLD_MIN_Y
	player.camera.limit_bottom=World.WORLD_MAX_Y
	player.camera.limit_smoothed=false
	sky.camera=player.camera
	enemies=Node2D.new()
	add_child(enemies)
	npcs=Node2D.new()
	npcs.name="NPCs"
	add_child(npcs)
	structures=Node2D.new()
	structures.name="VillageStructures"
	add_child(structures)
	drops=Node2D.new()
	drops.name="GroundDrops"
	add_child(drops)
	death_bags=Node2D.new()
	death_bags.name="DeathBackpacks"
	add_child(death_bags)
	spawn_village_hub()
	spawn_world_npcs()
	spawn_mel()
	call_deferred("maybe_start_mel_quest")
	selection=preload("res://scripts/selection.gd").new()
	add_child(selection)
	active=true
	clock=.32
	day=1
	auto_save=0
	spawn_timer=0
	hud.show()
	bar.show()
	hotbar_back.show()
	selected_name.show()
	status.show()
	resume()

func reset_quest_progress() -> void:
	quest_states={
		QUEST_MEL:"not_started",
		QUEST_BORIN:"not_started",
		QUEST_MERCHANT:"not_started",
		QUEST_ABYSS:"not_started",
		QUEST_MONK:"not_started",
		QUEST_SNOW:"not_started"
	}
	snow_reached=false
	abyss_slime_kills=0
	abyss_warden_kills=0

func quest_state(id:String) -> String:
	return str(quest_states.get(id,"not_started"))

func quest_unlocked(id:String) -> bool:
	match id:
		QUEST_MEL, QUEST_BORIN:
			return true
		QUEST_MERCHANT:
			return quest_state(QUEST_BORIN)=="completed"
		QUEST_ABYSS:
			return quest_state(QUEST_MERCHANT)=="completed"
		QUEST_MONK:
			return quest_state(QUEST_ABYSS)=="completed"
		QUEST_SNOW:
			return quest_state(QUEST_MONK)=="completed"
	return false

func quest_ready(id:String) -> bool:
	if not is_instance_valid(player):
		return false
	match id:
		QUEST_MEL:
			return player.creative or int(player.inventory.get(23,0))>=3
		QUEST_BORIN:
			return player.creative or (int(player.inventory.get(3,0))>=10 and int(player.inventory.get(7,0))>=5)
		QUEST_MERCHANT:
			return player.creative or (int(player.inventory.get(4,0))>=12 and int(player.inventory.get(6,0))>=6)
		QUEST_ABYSS:
			return player.creative or (abyss_slime_kills>=4 and abyss_warden_kills>=2)
		QUEST_MONK:
			return player.creative or night_kills>=7
		QUEST_SNOW:
			return player.creative or (snow_reached and polar_bear_defeated)
	return false

func quest_progress_text(id:String) -> String:
	match id:
		QUEST_MEL:
			return "%d / 3 ossos" % mini(3,int(player.inventory.get(23,0)))
		QUEST_BORIN:
			return "Pedra %d/10  ·  Ferro %d/5" % [mini(10,int(player.inventory.get(3,0))),mini(5,int(player.inventory.get(7,0)))]
		QUEST_MERCHANT:
			return "Madeira %d/12  ·  Carvão %d/6" % [mini(12,int(player.inventory.get(4,0))),mini(6,int(player.inventory.get(6,0)))]
		QUEST_ABYSS:
			return "Slimes sombrios %d/4  ·  Guardiões espectrais %d/2" % [mini(4,abyss_slime_kills),mini(2,abyss_warden_kills)]
		QUEST_MONK:
			return "%d / 7 criaturas noturnas" % mini(7,night_kills)
		QUEST_SNOW:
			return "Bioma encontrado: %s  ·  Urso Ancião: %s" % ["SIM" if snow_reached else "NÃO","DERROTADO" if polar_bear_defeated else "PENDENTE"]
	return ""

func quest_status_text(id:String) -> String:
	if not quest_unlocked(id):
		return "BLOQUEADA"
	match quest_state(id):
		"not_started": return "NÃO INICIADA"
		"in_progress": return "EM PROGRESSO"
		"completed": return "CONCLUÍDA"
	return "NÃO INICIADA"

func completed_quest_count() -> int:
	var amount=0
	for id in [QUEST_MEL,QUEST_BORIN,QUEST_MERCHANT,QUEST_ABYSS,QUEST_MONK,QUEST_SNOW]:
		if quest_state(id)=="completed":
			amount+=1
	return amount

func accept_quest(id:String) -> void:
	if not quest_unlocked(id) or quest_state(id)!="not_started":
		return
	quest_states[id]="in_progress"
	if id==QUEST_MEL:
		mel_quest_started=true
	status.text="MISSÃO ACEITA · "+quest_progress_text(id)
	message_time=4
	update_quest_markers()

func sync_legacy_quest_flags() -> void:
	mel_quest_started=quest_state(QUEST_MEL)!="not_started"
	mel_tamed=quest_state(QUEST_MEL)=="completed"
	borin_quest_done=quest_state(QUEST_BORIN)=="completed"
	monk_quest_done=quest_state(QUEST_MONK)=="completed"

func complete_quest(id:String,npc=null) -> void:
	if quest_state(id)!="in_progress":
		return
	if not quest_ready(id):
		status.text="Objetivo ainda incompleto · "+quest_progress_text(id)
		message_time=3
		return
	if not player.creative:
		match id:
			QUEST_MEL:
				player.inventory[23]=maxi(0,int(player.inventory.get(23,0))-3)
			QUEST_BORIN:
				player.inventory[3]=maxi(0,int(player.inventory.get(3,0))-10)
				player.inventory[7]=maxi(0,int(player.inventory.get(7,0))-5)
			QUEST_MERCHANT:
				player.inventory[4]=maxi(0,int(player.inventory.get(4,0))-12)
				player.inventory[6]=maxi(0,int(player.inventory.get(6,0))-6)
	match id:
		QUEST_MEL:
			mel_tamed=true
			if is_instance_valid(mel):
				mel.set_tamed(true)
			status.text="MISSÃO CONCLUÍDA · Mel agora acompanha você."
		QUEST_BORIN:
			player.inventory[11]=int(player.inventory.get(11,0))+1
			player.inventory[14]=int(player.inventory.get(14,0))+1
			status.text="MISSÃO CONCLUÍDA · Espada de ferro + 1 diamante."
		QUEST_MERCHANT:
			player.inventory[24]=int(player.inventory.get(24,0))+1
			player.inventory[10]=int(player.inventory.get(10,0))+3
			status.text="MISSÃO CONCLUÍDA · Waystone + 3 carnes."
		QUEST_ABYSS:
			player.inventory[14]=int(player.inventory.get(14,0))+2
			player.inventory[10]=int(player.inventory.get(10,0))+4
			status.text="MISSÃO CONCLUÍDA · 2 diamantes + 4 carnes. A Prova da Noite foi liberada."
		QUEST_MONK:
			player.max_hp=maxf(player.max_hp,120.0)
			player.hp=player.max_hp
			player.inventory[14]=int(player.inventory.get(14,0))+2
			status.text="MISSÃO CONCLUÍDA · Bênção: +20 vida máxima + 2 diamantes."
		QUEST_SNOW:
			player.inventory[12]=int(player.inventory.get(12,0))+1
			player.inventory[14]=int(player.inventory.get(14,0))+2
			status.text="MISSÃO CONCLUÍDA · Relíquia Vital + 2 diamantes. O Guardião agora pode ser enfrentado."
	quest_states[id]="completed"
	sync_legacy_quest_flags()
	message_time=6
	refresh_hud()
	update_quest_markers()
	save_world()
	if npc!=null:
		show_npc_dialogue(npc)

func complete_borin_quest(npc) -> void:
	complete_quest(QUEST_BORIN,npc)

func complete_monk_quest(npc) -> void:
	complete_quest(QUEST_MONK,npc)

func marker_for_quest(id:String) -> String:
	if not quest_unlocked(id):
		return ""
	var state=quest_state(id)
	if state=="not_started":
		return "!"
	if state=="in_progress" and quest_ready(id):
		return "?"
	return ""

func update_quest_markers() -> void:
	if is_instance_valid(mel) and mel.has_method("set_quest_marker"):
		mel.set_quest_marker(marker_for_quest(QUEST_MEL))
	if is_instance_valid(npcs):
		for npc in npcs.get_children():
			if not npc.has_method("set_quest_marker"):
				continue
			var marker=""
			if str(npc.role)=="ferreiro":
				marker=marker_for_quest(QUEST_BORIN) if quest_state(QUEST_BORIN)!="completed" else marker_for_quest(QUEST_ABYSS)
			elif str(npc.role)=="monge":
				marker=marker_for_quest(QUEST_MONK) if quest_state(QUEST_MONK)!="completed" else marker_for_quest(QUEST_SNOW)
			npc.set_quest_marker(marker)
	if is_instance_valid(structures):
		for building in structures.get_children():
			if building.has_method("set_quest_marker"):
				building.set_quest_marker(marker_for_quest(QUEST_MERCHANT) if str(building.kind)=="market" else "")

func show_objectives() -> void:
	clear_menu("MISSÕES","objectives")
	var title=label("JORNADA DO DREADS CRAFT",18)
	title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color",Color("f0d99a"))
	menu_box.add_child(title)
	var tasks=[
		[QUEST_MEL,"MEL · UMA COMPANHEIRA","Entregue 3 ossos para conquistar a confiança de Mel."],
		[QUEST_BORIN,"BORIN · REFORÇANDO A FORJA","Entregue 10 pedras e 5 ferros ao ferreiro."],
		[QUEST_MERCHANT,"MERCADOR · SUPRIMENTOS DA VILA","Leve 12 madeiras e 6 carvões para reabastecer a loja."],
		[QUEST_ABYSS,"BORIN · PESTE DO ABISMO","Derrote 4 Slimes Sombrios e 2 Guardiões Espectrais fora da vila."],
		[QUEST_MONK,"MONGE · PROVA DA NOITE","Derrote 7 criaturas hostis durante a noite, longe da vila."],
		[QUEST_SNOW,"MONGE · URSO DO NORTE","Explore o bioma de neve e derrote o Urso Polar Ancião."]
	]
	for task in tasks:
		var id=str(task[0])
		var card=PanelContainer.new()
		card.add_theme_stylebox_override("panel",compact_panel_style(0.80,Color("66536f"),9))
		card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		menu_box.add_child(card)
		var box=VBoxContainer.new()
		box.add_theme_constant_override("separation",4)
		card.add_child(box)
		var name=label(str(task[1]),15)
		name.add_theme_color_override("font_color",Color("ead8f0"))
		box.add_child(name)
		var desc=label(str(task[2]),12)
		desc.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		box.add_child(desc)
		var state_label=label(quest_status_text(id),11)
		state_label.add_theme_color_override("font_color",Color("9fe7b2") if quest_state(id)=="completed" else Color("e3bd78"))
		box.add_child(state_label)
		var prog=label("Concluída e recompensa recebida." if quest_state(id)=="completed" else ("Conclua a missão anterior para desbloquear." if not quest_unlocked(id) else quest_progress_text(id)),12)
		prog.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		box.add_child(prog)
	var gate=label("A Dimensão da Pureza só aceita desafiantes que concluíram a missão Urso do Norte.",11)
	gate.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	gate.add_theme_color_override("font_color",Color("b8a5c5"))
	menu_box.add_child(gate)
	menu_box.add_child(button("VOLTAR",show_pause))
	layout()

func show_pause() -> void:
	if not active:
		return
	clear_menu(world_name+(" · ONLINE" if multiplayer_active else ""),"pause")
	if multiplayer_active:
		var room=label("SALA: "+online.room_code,18)
		room.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		room.add_theme_color_override("font_color",Color("f0cb78"))
		menu_box.add_child(room)
		var hint=label("Passe esse código para seus amigos entrarem no mesmo mundo.",12)
		hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		hint.add_theme_color_override("font_color",Color("baa9c5"))
		menu_box.add_child(hint)
		menu_box.add_child(button("CONTINUAR",resume))
		if multiplayer_host:
			menu_box.add_child(button("HISTÓRICO DE JOGADORES",show_player_history))
		menu_box.add_child(button("CONFIGURAÇÕES",func(): show_settings(false)))
		menu_box.add_child(button("SAIR DA SALA",leave_multiplayer))
		return
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
	menu_box.add_child(button("MISSÕES / OBJETIVOS",show_objectives))
	menu_box.add_child(button("CONFIGURAÇÕES",func(): show_settings(false)))
	menu_box.add_child(button("SALVAR E SAIR AO MENU",func():
		if save_world():
			show_main()
	))

func sync_hotbar_from_inventory() -> void:
	if not is_instance_valid(player) or player.creative:
		return
	# Remove exhausted items: empty slots really look empty, like Minecraft.
	for i in range(hotbar.size()):
		var id=int(hotbar[i])
		if id!=0 and int(player.inventory.get(id,0))<=0:
			hotbar[i]=0
			if selected==id:
				selected=0
	# Newly collected/crafted/dropped items automatically occupy the first free slot.
	for raw_id in Items.NAMES:
		var id=int(raw_id)
		if id==1 or int(player.inventory.get(id,0))<=0 or hotbar.has(id):
			continue
		var empty=hotbar.find(0)
		if empty<0:
			break
		hotbar[empty]=id
	if selected==0:
		for id in hotbar:
			if int(id)!=0:
				selected=int(id)
				break

func cycle_hotbar(step:int) -> void:
	if hotbar.is_empty():
		selected=0
		return
	var start=hotbar.find(selected)
	if start<0:
		start=0
	for n in range(1,hotbar.size()+1):
		var index=posmod(start+step*n,hotbar.size())
		if int(hotbar[index])!=0:
			selected=int(hotbar[index])
			refresh_hud()
			return
	selected=0
	refresh_hud()

func refresh_hud() -> void:
	if not active:
		return
	sync_hotbar_from_inventory()
	portrait_icon.texture=load("res://assets/sprites/demon_idle_0.png") if player.creative else (fox_preview_texture() if current_form=="fox" else load("res://assets/sprites/normal_idle_0.png"))
	form_name_label.text="LIVRE" if player.creative else ("RAPOSA" if current_form=="fox" else "SPIKE")
	hp_bar.max_value=player.max_hp
	hp_bar.value=player.max_hp if player.creative else player.hp
	food_bar.value=100 if player.creative else player.food
	stats.text="LIVRE" if player.creative else "%d/%d" % [int(player.hp),int(player.max_hp)]
	food_value.text="LIVRE" if player.creative else str(int(player.food))
	var minutes=int(clock*1440)
	time_label.text="DIA %d  ·  %02d:%02d" % [day,minutes/60,minutes%60]
	mode_label.text="CRIATIVO" if player.creative else "SOBREVIVÊNCIA"
	selected_name.text=Items.NAMES.get(selected,"Mãos vazias") if selected!=0 else "Mãos vazias"
	update_air_hud()

	for child in bar.get_children():
		bar.remove_child(child)
		child.queue_free()

	var mobile_hotbar=get_viewport_rect().size.x<=900 or (is_instance_valid(device_controls) and bool(device_controls.mobile))
	bar.add_theme_constant_override("separation",2 if mobile_hotbar else 5)
	for slot_index in range(9):
		var id=int(hotbar[slot_index]) if slot_index<hotbar.size() else 0
		var slot=Button.new()
		slot.focus_mode=Control.FOCUS_NONE
		slot.custom_minimum_size=Vector2(64,64) if mobile_hotbar else Vector2(48,48)
		slot.expand_icon=true
		slot.add_theme_constant_override("icon_max_width",44 if mobile_hotbar else 30)
		slot.tooltip_text=Items.NAMES.get(id,"Slot vazio") if id!=0 else "Slot vazio"

		var empty_style=StyleBoxFlat.new()
		empty_style.bg_color=Color("08080bcc")
		empty_style.border_color=Color("5e5962")
		empty_style.set_border_width_all(2)
		empty_style.set_corner_radius_all(2)
		empty_style.content_margin_left=4
		empty_style.content_margin_right=4
		empty_style.content_margin_top=4
		empty_style.content_margin_bottom=4

		var selected_style=empty_style.duplicate()
		selected_style.bg_color=Color("29252ddd")
		selected_style.border_color=Color("f4eee5")
		selected_style.set_border_width_all(3)

		slot.add_theme_stylebox_override("normal",selected_style if id!=0 and id==selected else empty_style)
		slot.add_theme_stylebox_override("hover",selected_style)
		slot.add_theme_stylebox_override("pressed",selected_style)

		if id!=0 and Items.ICONS.has(id):
			slot.icon=item_display_texture(id)
			slot.pressed.connect(func():
				selected=id
				refresh_hud()
			)
			var amount=int(player.inventory.get(id,0))
			var count=label("∞" if player.creative else str(amount),13 if mobile_hotbar else 10)
			count.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
			count.vertical_alignment=VERTICAL_ALIGNMENT_BOTTOM
			count.position=Vector2(36,43) if mobile_hotbar else Vector2(26,29)
			count.size=Vector2(24,17) if mobile_hotbar else Vector2(18,14)
			count.mouse_filter=Control.MOUSE_FILTER_IGNORE
			slot.add_child(count)
		else:
			slot.disabled=true

		var number=label(str(slot_index+1),10 if mobile_hotbar else 8)
		number.position=Vector2(4,2) if mobile_hotbar else Vector2(3,1)
		number.size=Vector2(16,12) if mobile_hotbar else Vector2(14,10)
		number.add_theme_color_override("font_color",Color("a9a3aa"))
		number.mouse_filter=Control.MOUSE_FILTER_IGNORE
		slot.add_child(number)
		bar.add_child(slot)
	layout()

func update_air_hud() -> void:
	if not is_instance_valid(air_frame) or not is_instance_valid(player):
		return
	var visible=active and player.in_water and not player.creative
	air_frame.visible=visible
	if not visible:
		return
	air_bar.max_value=player.max_air
	air_bar.value=player.air
	air_value.text="%d%%" % clampi(int(round(player.air/player.max_air*100.0)),0,100)
	air_bar.modulate=Color("ef6a75") if player.air<=2.0 else Color.WHITE


func fox_preview_texture() -> Texture2D:
	var sheet=load("res://assets/player/forms/fox_animation_atlas.png") as Texture2D
	if sheet==null:
		return null
	var texture=AtlasTexture.new()
	texture.atlas=sheet
	texture.region=Rect2(0,0,64,64)
	return texture

func apply_form(form_id:String) -> void:
	if not is_instance_valid(player):
		return
	var normalized="fox" if form_id=="fox" else "spike"
	if normalized=="fox" and not bool(forms_unlocked.get("fox",false)):
		status.text="RAPOSA BLOQUEADA · derrote o Leviatã do Lago Abissal."
		message_time=3
		return
	current_form=normalized
	player.set_form(current_form)
	refresh_hud()
	status.text="FORMA ATIVA: RAPOSA" if current_form=="fox" else "FORMA ATIVA: SPIKE"
	message_time=2.5
	save_world()

func show_transformations() -> void:
	if not active:
		return
	clear_menu("Transformações","transformations")
	var intro=label("Escolha a forma de Spike. Novas formas serão adicionadas futuramente.",13)
	intro.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	intro.add_theme_color_override("font_color",Color("c9b6d8"))
	menu_box.add_child(intro)
	var spike_button=button(("✓ " if current_form=="spike" else "")+"SPIKE · FORMA ORIGINAL",func():
		apply_form("spike")
		resume()
	)
	spike_button.icon=load("res://assets/sprites/normal_idle_0.png")
	spike_button.expand_icon=true
	menu_box.add_child(spike_button)
	var fox_unlocked=bool(forms_unlocked.get("fox",false))
	var fox_button=button(("✓ " if current_form=="fox" else "")+("RAPOSA · DESBLOQUEADA" if fox_unlocked else "RAPOSA · BLOQUEADA"),func():
		apply_form("fox")
		if bool(forms_unlocked.get("fox",false)):
			resume()
	)
	fox_button.icon=fox_preview_texture()
	fox_button.expand_icon=true
	fox_button.disabled=not fox_unlocked
	menu_box.add_child(fox_button)
	if not fox_unlocked:
		var hint=label("Derrote o LEVIATÃ DO LAGO ABISSAL para libertar a Forma Raposa.",12)
		hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		hint.add_theme_color_override("font_color",Color("a98dbd"))
		menu_box.add_child(hint)
	menu_box.add_child(button("FECHAR",resume))
	layout()

func chest_key(cell:Vector2i) -> String:
	return "%d,%d" % [cell.x,cell.y]

func serialize_chests() -> Dictionary:
	return chest_inventories.duplicate(true)

func restore_chests(raw) -> void:
	chest_inventories.clear()
	if not raw is Dictionary:
		return
	for key in raw:
		var src=raw[key]
		if not src is Dictionary:
			continue
		var inv:Dictionary={}
		for item_id in src:
			var count=int(src[item_id])
			if count>0:
				inv[int(item_id)]=count
		chest_inventories[str(key)]=inv

func spill_chest(cell:Vector2i) -> void:
	var key=chest_key(cell)
	if not chest_inventories.has(key):
		return
	var pos=Vector2(cell.x*32+16,cell.y*32+8)
	var stored:Dictionary=chest_inventories[key]
	for raw_id in stored:
		var item_id=int(raw_id)
		var count=int(stored[raw_id])
		if count<=0:
			continue
		if multiplayer_active and is_instance_valid(online):
			online.send_drop_spawn(item_id,count,pos)
		else:
			spawn_ground_drop(item_id,count,pos)
	chest_inventories.erase(key)

func chest_put_one(cell:Vector2i,item_id:int) -> void:
	if not is_instance_valid(player) or player.creative:
		return
	var owned=int(player.inventory.get(item_id,0))
	if owned<=0:
		return
	var key=chest_key(cell)
	var stored:Dictionary=chest_inventories.get(key,{})
	if not stored.has(item_id) and stored.size()>=18:
		status.text="Baú cheio."
		message_time=2
		return
	player.inventory[item_id]=owned-1
	stored[item_id]=int(stored.get(item_id,0))+1
	chest_inventories[key]=stored
	show_chest(cell)

func chest_take_one(cell:Vector2i,item_id:int) -> void:
	var key=chest_key(cell)
	var stored:Dictionary=chest_inventories.get(key,{})
	var amount=int(stored.get(item_id,0))
	if amount<=0:
		return
	stored[item_id]=amount-1
	if int(stored[item_id])<=0:
		stored.erase(item_id)
	chest_inventories[key]=stored
	player.inventory[item_id]=int(player.inventory.get(item_id,0))+1
	show_chest(cell)

func show_chest(cell:Vector2i) -> void:
	if not active or not is_instance_valid(world) or world.get_cell(cell)!=28:
		return
	clear_menu("Baú","chest")
	var key=chest_key(cell)
	if not chest_inventories.has(key):
		chest_inventories[key]={}
	var stored:Dictionary=chest_inventories[key]
	var caption=label("ARMAZENADO · %d/18 tipos" % stored.size(),13)
	caption.add_theme_color_override("font_color",Color("d6b77b"))
	menu_box.add_child(caption)
	if stored.is_empty():
		menu_box.add_child(label("O baú está vazio.",12))
	else:
		for raw_id in stored.keys():
			var item_id=int(raw_id)
			var line=HBoxContainer.new()
			line.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			line.add_theme_constant_override("separation",8)
			var info=label("%s  x%d" % [Items.NAMES.get(item_id,"Item"),int(stored[raw_id])],13)
			info.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			line.add_child(info)
			var take=button("RETIRAR 1",func(): chest_take_one(cell,item_id))
			take.custom_minimum_size=Vector2(130,44)
			line.add_child(take)
			menu_box.add_child(line)
	var rule=HSeparator.new()
	menu_box.add_child(rule)
	menu_box.add_child(label("SEU INVENTÁRIO",13))
	for raw_id in player.inventory.keys():
		var item_id=int(raw_id)
		var amount=int(player.inventory.get(raw_id,0))
		if amount<=0:
			continue
		var row=HBoxContainer.new()
		row.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation",8)
		var info=label("%s  x%d" % [Items.NAMES.get(item_id,"Item"),amount],12)
		info.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var put=button("GUARDAR 1",func(): chest_put_one(cell,item_id))
		put.custom_minimum_size=Vector2(130,44)
		put.disabled=player.creative or (not stored.has(item_id) and stored.size()>=18)
		row.add_child(put)
		menu_box.add_child(row)
	menu_box.add_child(button("FECHAR",resume))

func armor_slot_title(slot:String) -> String:
	return str({"head":"CABEÇA","chest":"PEITORAL","legs":"PERNAS","feet":"PÉS"}.get(slot,slot.to_upper()))

func apply_armor_equipment() -> void:
	if is_instance_valid(player):
		player.set_armor_equipment(armor_equipment)

func equip_armor_item(id:int) -> bool:
	if not Items.is_armor(id) or not is_instance_valid(player):
		return false
	var slot=Items.armor_slot(id)
	if slot=="":
		return false
	if not player.creative and int(player.inventory.get(id,0))<=0:
		return false
	var old_id=int(armor_equipment.get(slot,0))
	if old_id==id:
		return true
	if old_id>0 and not player.creative:
		player.inventory[old_id]=int(player.inventory.get(old_id,0))+1
	if not player.creative:
		player.inventory[id]=int(player.inventory.get(id,0))-1
		if int(player.inventory.get(id,0))<=0:
			player.inventory.erase(id)
	armor_equipment[slot]=id
	apply_armor_equipment()
	status.text="%s equipado · defesa total %d%%" % [Items.NAMES.get(id,"Armadura"),int(round(Items.armor_reduction(armor_equipment)*100.0))]
	message_time=2.5
	refresh_hud()
	return true

func unequip_armor_slot(slot:String) -> bool:
	var old_id=int(armor_equipment.get(slot,0))
	if old_id<=0 or not is_instance_valid(player):
		return false
	if not player.creative:
		player.inventory[old_id]=int(player.inventory.get(old_id,0))+1
	armor_equipment[slot]=0
	apply_armor_equipment()
	status.text="%s removido" % Items.NAMES.get(old_id,"Armadura")
	message_time=2.0
	refresh_hud()
	return true

func show_inventory() -> void:
	if not active:
		return
	clear_menu("Inventário","inventory")
	var subtitle=label("Itens coletados · Q também dropa 1 item no PC",14)
	subtitle.add_theme_color_override("font_color",Color("b8a5c5"))
	menu_box.add_child(subtitle)
	var armor_panel=PanelContainer.new()
	armor_panel.add_theme_stylebox_override("panel",compact_panel_style(0.72,Color("4e8aa0"),8))
	menu_box.add_child(armor_panel)
	var armor_box=VBoxContainer.new()
	armor_box.add_theme_constant_override("separation",6)
	armor_panel.add_child(armor_box)
	var defense=label("ARMADURA DE AVARITA · DEFESA TOTAL %d%%" % int(round(Items.armor_reduction(armor_equipment)*100.0)),13)
	defense.add_theme_color_override("font_color",Color("83e7ff"))
	armor_box.add_child(defense)
	var armor_row=HBoxContainer.new()
	armor_row.add_theme_constant_override("separation",6)
	armor_box.add_child(armor_row)
	for slot in ["head","chest","legs","feet"]:
		var equipped_id=int(armor_equipment.get(slot,0))
		var slot_text=armor_slot_title(slot)+"\n"+(Items.NAMES.get(equipped_id,"Vazio") if equipped_id>0 else "Vazio")
		var slot_button=button(slot_text,func(s=slot): 
			if int(armor_equipment.get(s,0))>0:
				unequip_armor_slot(s)
				show_inventory()
		)
		slot_button.custom_minimum_size=Vector2(150,62)
		slot_button.add_theme_font_size_override("font_size",10)
		if equipped_id>0:
			slot_button.icon=item_display_texture(equipped_id)
			slot_button.expand_icon=true
		armor_row.add_child(slot_button)
	for id in Items.NAMES:
		if id==1 or (not player.creative and player.inventory.get(id,0)<=0):
			continue
		var line=HBoxContainer.new()
		line.add_theme_constant_override("separation",8)
		line.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		menu_box.add_child(line)

		var amount="LIVRE" if player.creative else str(player.inventory.get(id,0))
		var row=button("%s    %s" % [Items.NAMES[id],amount],func():
			if Items.is_armor(id):
				if equip_armor_item(id):
					show_inventory()
				return
			selected=id
			if not hotbar.has(id):
				var empty_slot=hotbar.find(0)
				hotbar[empty_slot if empty_slot>=0 else hotbar.size()-1]=id
			resume()
		)
		row.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		if Items.ICONS.has(id):
			row.icon=item_display_texture(id)
			row.expand_icon=true
			row.alignment=HORIZONTAL_ALIGNMENT_LEFT
		line.add_child(row)

		var drop_button:Button
		if Items.is_armor(id):
			drop_button=button("EQUIPAR",func():
				if equip_armor_item(id):
					show_inventory()
			)
			drop_button.disabled=(not player.creative and int(player.inventory.get(id,0))<=0)
		else:
			drop_button=button("DROPAR 1",func():
				selected=id
				drop_selected_item(1)
				show_inventory()
			)
			drop_button.disabled=player.creative or int(player.inventory.get(id,0))<=0 or in_purity
		drop_button.custom_minimum_size=Vector2(126,54)
		line.add_child(drop_button)
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
	icon.texture=item_display_texture(id)
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
	icon.texture=item_display_texture(int(recipe.id),true)
	icon.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
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
	sidebar.add_child(craft_category_button("🛡  ARMADURAS","armor"))
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
	recipe_scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO
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
	if modal and event is InputEventScreenDrag and absf(event.relative.y)>absf(event.relative.x):
		var modal_scroll=menu.get_node_or_null("MenuScroll") if is_instance_valid(menu) else null
		if modal_scroll:
			modal_scroll.scroll_vertical=maxi(0,modal_scroll.scroll_vertical-int(event.relative.y*1.35))
			get_viewport().set_input_as_handled()
			return
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
	if active and multiplayer_active and event.is_action_pressed("chat"):
		toggle_multiplayer_chat()
		get_viewport().set_input_as_handled()
		return
	if is_instance_valid(chat_input) and chat_input.has_focus():
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
	if event.is_action_pressed("drop"):
		drop_selected_item(1)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode==KEY_R:
			use_selected()
			get_viewport().set_input_as_handled()
			return
		if event.physical_keycode>=KEY_1 and event.physical_keycode<=KEY_9:
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
			cycle_hotbar(offset)

func set_touch_action_target() -> void:
	if not is_instance_valid(player) or in_structure!="" or in_purity or not is_instance_valid(world):
		return

	# If the player touched an exact solid block on the world, do not replace it
	# when the MINERAR button is pressed. This fixes trees and vertical mining.
	if target.x>=0 and target.y>=0 and world.get_cell(target) not in [0,16]:
		var exact_center=Vector2(target*32+Vector2i(16,16))
		if player.position.distance_to(exact_center)<=170.0:
			return

	var aim=touch_aim
	if aim.length()<8.0:
		aim=Vector2(player.face*96.0,0)
	var dir=aim.normalized()
	var center=Vector2i(floor(player.position.x/32.0),floor((player.position.y-24.0)/32.0))
	var best=Vector2i(-1,-1)
	var best_score=999999.0

	# Search every reachable nearby block, but strongly prefer the direction
	# the player last touched: left/right/up/down all work with the same button.
	for dy in range(-4,5):
		for dx in range(-4,5):
			if dx==0 and dy==0:
				continue
			var cell=center+Vector2i(dx,dy)
			if cell.x<0 or cell.x>=320 or cell.y<0 or cell.y>=95:
				continue
			if world.get_cell(cell) in [0,16]:
				continue
			var cell_center=Vector2(cell*32+Vector2i(16,16))
			var delta=cell_center-(player.position-Vector2(0,24))
			var distance=delta.length()
			if distance>170.0 or distance<5.0:
				continue
			var dot=dir.dot(delta.normalized())
			if dot<0.10:
				continue
			var score=(1.0-dot)*190.0+distance
			# Wood/leaves get a tiny preference so tapping a tree does not snap
			# to the dirt/stone behind it.
			var block_id=world.get_cell(cell)
			if block_id in [4,5]:
				score-=12.0
			if score<best_score:
				best_score=score
				best=cell

	# Fallback: nearest reachable solid block around the character. This makes
	# MINERAR useful even if the previous touch was on a UI control.
	if best.x<0:
		for dy in range(-3,4):
			for dx in range(-3,4):
				if dx==0 and dy==0:
					continue
				var cell=center+Vector2i(dx,dy)
				if cell.x<0 or cell.x>=320 or cell.y<0 or cell.y>=95:
					continue
				if world.get_cell(cell) in [0,16]:
					continue
				var distance=(Vector2(cell*32+Vector2i(16,16))-(player.position-Vector2(0,24))).length()
				if distance<=150.0 and distance<best_score:
					best_score=distance
					best=cell

	target=best
	if target.x>=0:
		touch_aim=Vector2(target*32+Vector2i(16,16))-player.position

func refresh_mobile_mining_target() -> void:
	if not is_instance_valid(device_controls) or not device_controls.mobile or not mining_held:
		return
	# Keep the current target while it is still a solid reachable block.
	if target.x>=0 and target.y>=0 and world.get_cell(target) not in [0,16]:
		var center=Vector2(target*32+Vector2i(16,16))
		if player.position.distance_to(center)<=150.0:
			return
	set_touch_action_target()

func set_touch_place_target() -> void:
	if not is_instance_valid(player) or in_structure!="" or in_purity or not is_instance_valid(world):
		return

	var origin=player.position-Vector2(0,24)
	# First respect the exact empty cell touched by the player.
	var desired=Vector2i(floor((player.position+touch_aim).x/32.0),floor((player.position+touch_aim).y/32.0))
	if desired.x>=0 and desired.x<world.world_width() and desired.y>=0 and desired.y<95:
		var desired_center=Vector2(desired*32+Vector2i(16,16))
		var desired_area=Rect2(Vector2(desired)*32,Vector2(32,32))
		if world.get_cell(desired)==0 and origin.distance_to(desired_center)<=170.0 and not player.body_rect().intersects(desired_area):
			target=desired
			return

	# If the touch is on a solid block, place on the closest empty face of it.
	if desired.x>=0 and desired.x<320 and desired.y>=0 and desired.y<95 and world.get_cell(desired) not in [0,16]:
		var choices=[Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]
		var best=Vector2i(-1,-1)
		var best_score=999999.0
		var touch_world=player.position+touch_aim
		for offset in choices:
			var cell=desired+offset
			if cell.x<0 or cell.x>=320 or cell.y<0 or cell.y>=95:
				continue
			if world.get_cell(cell)!=0:
				continue
			var area=Rect2(Vector2(cell)*32,Vector2(32,32))
			if player.body_rect().intersects(area):
				continue
			var center=Vector2(cell*32+Vector2i(16,16))
			if origin.distance_to(center)>170.0:
				continue
			var score=center.distance_to(touch_world)
			if score<best_score:
				best_score=score
				best=cell
		if best.x>=0:
			target=best
			return

	# Reliable fallback in front/above/below the player.
	var feet=Vector2i(floor(player.position.x/32.0),floor(player.position.y/32.0))
	var fallback=[
		feet+Vector2i(player.face,0),
		feet+Vector2i(player.face,-1),
		feet+Vector2i(player.face,1),
		feet+Vector2i(0,-2)
	]
	for cell in fallback:
		if cell.x<0 or cell.x>=320 or cell.y<0 or cell.y>=95:
			continue
		if world.get_cell(cell)!=0:
			continue
		var area=Rect2(Vector2(cell)*32,Vector2(32,32))
		if not player.body_rect().intersects(area):
			target=cell
			touch_aim=Vector2(cell*32+Vector2i(16,16))-player.position
			return
	target=Vector2i(-1,-1)

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
	if in_purity or target.x<0 or world.get_cell(target)!=0 or selected not in PLACEABLE_BLOCKS:
		return false
	if not in_purity and world.is_village_protected(target) and not player.creative:
		status.text="A vila é uma zona protegida: não é possível construir aqui."
		message_time=2.5
		return false
	var area=Rect2(Vector2(target)*32,Vector2(32,32))
	if player.body_rect().intersects(area):
		return false
	if not player.creative and player.inventory.get(selected,0)<1:
		return false
	world.set_cell(target,selected)
	if selected==28:
		chest_inventories[chest_key(target)]={}
	if multiplayer_active and is_instance_valid(online):
		online.send_block_change(target,selected)
	if not player.creative:
		player.inventory[selected]-=1
	refresh_hud()
	return true

func spawn_ground_drop(item_id:int,count:int,world_position:Vector2,remaining:float=300.0,network_id:String="",networked:bool=false) -> void:
	if not is_instance_valid(drops) or not is_instance_valid(player) or item_id<=0 or count<=0:
		return
	var pickup=DroppedItem.new()
	pickup.setup(item_id,count,player,remaining,network_id,networked)
	pickup.position=world_position
	drops.add_child(pickup)

func apply_online_drop(data:Dictionary) -> void:
	if not multiplayer_active or not is_instance_valid(drops):
		return
	var drop_id=str(data.get("id",""))
	var item_id=int(data.get("item_id",0))
	var count=int(data.get("count",1))
	if drop_id=="" or item_id<=0 or count<=0:
		return
	for node in drops.get_children():
		if str(node.get("network_id"))==drop_id:
			return
	var pos=Vector2(float(data.get("x",0.0)),float(data.get("y",0.0)))
	spawn_ground_drop(item_id,count,pos,300.0,drop_id,true)

func remove_online_drop(drop_id:String) -> void:
	if not is_instance_valid(drops):
		return
	for node in drops.get_children():
		if str(node.get("network_id"))==drop_id:
			node.queue_free()
			return

func request_online_drop_pickup(drop_id:String) -> void:
	if multiplayer_active and is_instance_valid(online) and drop_id!="":
		online.send_drop_pickup(drop_id)

func resolve_online_drop_pickup(drop_id:String,by_id:String,item_id:int,count:int) -> void:
	remove_online_drop(drop_id)
	if not multiplayer_active or not is_instance_valid(online) or by_id!=online.local_id:
		return
	player.inventory[item_id]=int(player.inventory.get(item_id,0))+maxi(1,count)
	on_ground_item_picked(item_id,maxi(1,count))

func current_death_scope() -> String:
	if in_lake_temple:
		return "lake"
	if in_structure!="":
		return "structure:"+in_structure
	if in_purity:
		return "purity_realm" if in_purity_realm else "purity_arena"
	return "overworld"

func spawn_death_backpack(contents:Dictionary,world_position:Vector2,scope:String) -> void:
	if not is_instance_valid(death_bags) or contents.is_empty():
		return
	var bag=DeathBackpack.new()
	bag.setup(contents,player,self,scope)
	bag.position=world_position
	death_bags.add_child(bag)

func serialize_death_backpacks() -> Array:
	var result:Array=[]
	if not is_instance_valid(death_bags):
		return result
	for bag in death_bags.get_children():
		if bag.has_method("serialize"):
			result.append(bag.serialize())
	return result

func restore_death_backpacks(saved:Array) -> void:
	if not is_instance_valid(death_bags):
		return
	for entry in saved:
		if not entry is Dictionary:
			continue
		var raw_contents=entry.get("contents",{})
		if not raw_contents is Dictionary:
			continue
		var contents:Dictionary={}
		for raw_id in raw_contents:
			var amount=int(raw_contents[raw_id])
			if amount>0:
				contents[int(raw_id)]=amount
		var pos=entry.get("position",[0,0])
		if contents.is_empty() or not pos is Array or pos.size()<2:
			continue
		spawn_death_backpack(contents,Vector2(float(pos[0]),float(pos[1])),str(entry.get("scope","overworld")))

func on_death_backpack_collected() -> void:
	status.text="MOCHILA RECUPERADA · seus itens voltaram ao inventário."
	message_time=3
	refresh_hud()
	save_world()

func drop_selected_item(amount:int=1) -> void:
	if not active or (modal and pause_kind!="inventory") or player.creative or in_purity or in_structure!="" or selected<=0:
		return
	var owned=int(player.inventory.get(selected,0))
	if owned<=0:
		return
	var qty=mini(maxi(1,amount),owned)
	player.inventory[selected]=owned-qty
	var drop_pos=player.position+Vector2(player.face*30,-18)
	if multiplayer_active and is_instance_valid(online):
		online.send_drop_spawn(selected,qty,drop_pos)
	else:
		spawn_ground_drop(selected,qty,drop_pos)
	status.text="Dropou %dx %s · fica no chão por 5 minutos" % [qty,Items.NAMES.get(selected,"item")]
	message_time=2.5
	refresh_hud()

func try_collect_ground_item(item_id:int,count:int) -> bool:
	if not is_instance_valid(player) or item_id<=0 or count<=0 or not Items.NAMES.has(item_id):
		return false
	player.inventory[item_id]=int(player.inventory.get(item_id,0))+count
	sync_hotbar_from_inventory()
	on_ground_item_picked(item_id,count)
	return true

func on_ground_item_picked(item_id:int,count:int) -> void:
	status.text="+%d %s" % [count,Items.NAMES.get(item_id,"item")]
	message_time=1.2
	refresh_hud()

func serialize_ground_drops() -> Array:
	var result:Array=[]
	if not is_instance_valid(drops):
		return result
	for node in drops.get_children():
		if node.has_method("serialize"):
			result.append(node.serialize())
	return result

func restore_ground_drops(saved:Array) -> void:
	if not is_instance_valid(drops):
		return
	for entry in saved:
		if not entry is Dictionary:
			continue
		var pos=entry.get("position",[0,0])
		if not pos is Array or pos.size()<2:
			continue
		spawn_ground_drop(int(entry.get("id",0)),int(entry.get("count",1)),Vector2(float(pos[0]),float(pos[1])),float(entry.get("remaining",300.0)))


func play_weapon_swing() -> void:
	if not (Items.SWORD_DAMAGE.has(selected) or Items.PICK_TIERS.has(selected)):
		return
	if not player.creative and player.inventory.get(selected,0)<=0:
		return
	var texture=item_display_texture(selected,true)
	if texture!=null and player.has_method("play_weapon_attack"):
		player.play_weapon_attack(texture,0.28)

func show_damage_popup(world_position:Vector2,amount:int,critical:bool) -> void:
	var popup=Label.new()
	popup.text=("✦ %d" if critical else "%d") % amount
	popup.position=world_position+Vector2(-22,-82)
	popup.z_index=50
	popup.add_theme_font_size_override("font_size",18 if critical else 14)
	popup.add_theme_color_override("font_color",Color("fff0a3") if critical else Color("f4e9e1"))
	popup.add_theme_color_override("font_shadow_color",Color.BLACK)
	popup.add_theme_constant_override("shadow_offset_x",2)
	popup.add_theme_constant_override("shadow_offset_y",2)
	add_child(popup)
	var tween=popup.create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup,"position:y",popup.position.y-34,0.55)
	tween.tween_property(popup,"modulate:a",0.0,0.55)
	tween.set_parallel(false)
	tween.tween_callback(popup.queue_free)

func fire_soul_projectile() -> void:
	var projectile=SoulProjectile.new()
	var launch=player.position+Vector2(player.face*34,-28)
	var aim_target=player.position+touch_aim if is_instance_valid(device_controls) and device_controls.mobile else get_global_mouse_position()
	var aim_direction=(aim_target-launch).normalized()
	if aim_direction.length_squared()<0.01:
		aim_direction=Vector2(player.face,0)
	if signf(aim_direction.x)!=0:
		player.face=1 if aim_direction.x>0 else -1
	projectile.setup(aim_direction,world,enemies,self)
	projectile.position=launch
	add_child(projectile)
	status.text="✦ ORBE DAS ALMAS DISPARADO"
	message_time=0.8


func attack() -> void:
	if player.attack_time>0:
		return
	player.face=1 if (player.position+touch_aim if device_controls.mobile else get_global_mouse_position()).x>=player.position.x else -1
	if selected==26 and (player.creative or int(player.inventory.get(26,0))>0):
		player.attack_time=.65
		if is_instance_valid(game_audio):
			game_audio.hit()
		fire_soul_projectile()
		return
	player.attack_time=.35
	if is_instance_valid(game_audio):
		game_audio.hit()
	play_weapon_swing()

	var has_weapon=Items.SWORD_DAMAGE.has(selected) and (player.creative or int(player.inventory.get(selected,0))>0)
	var base_damage=float(Items.SWORD_DAMAGE.get(selected,6) if has_weapon else 6)
	if mel_tamed:
		base_damage+=2.0
	var aerial_critical=not player.creative and not player.is_on_floor() and player.velocity.y>70
	var crit_chance=Items.crit_chance(selected) if has_weapon else 0.05
	var crit_multiplier=Items.crit_multiplier(selected) if has_weapon else 1.50
	var critical=aerial_critical or randf()<crit_chance
	var final_damage=roundf(base_damage*(crit_multiplier if critical else 1.0))
	var landed=false
	var shown_damage=0

	for mob in enemies.get_children():
		if not is_instance_valid(mob) or not mob.has_method("hit"):
			continue
		var difference=mob.position-player.position
		var is_guardian=is_instance_valid(boss) and mob==boss
		var is_lake_guardian=is_instance_valid(lake_boss) and mob==lake_boss
		var is_large_boss=is_guardian or is_lake_guardian
		var reach_x=185.0 if is_lake_guardian else 145.0 if is_guardian else 100.0
		var reach_y=215.0 if is_lake_guardian else 150.0 if is_guardian else 82.0
		if absf(difference.x)<=reach_x and absf(difference.y)<=reach_y and (absf(difference.x)<24 or signf(difference.x)==player.face):
			if is_large_boss:
				mob.hit(final_damage)
			else:
				mob.hit(final_damage,340.0 if critical else 285.0)
			show_damage_popup(mob.global_position+(Vector2(0,-42) if is_guardian else Vector2.ZERO),final_damage,critical)
			landed=true
			shown_damage=maxi(shown_damage,int(final_damage))

	if landed:
		status.text=("CRÍTICO!  %d DE DANO" if critical else "%d DE DANO") % shown_damage
		message_time=1.2
		update_purity_hud()

func eat() -> void:
	if player.inventory.get(10,0)>0:
		if not player.creative:
			player.inventory[10]-=1
		player.food=minf(100,player.food+25)
		refresh_hud()

func _process(delta: float) -> void:
	if not active:
		poll_web_login()
		animate_lobby(delta)
		return
	if modal:
		return
	update_purity_hud()
	update_multiplayer_compass()
	if in_lake_temple:
		mining_held=false
		if is_instance_valid(lake_arena):
			var body_in_water=lake_arena.is_in_water(player.position)
			var head_in_water=lake_arena.is_in_water(player.position+Vector2(0,-38))
			player.set_water_state(body_in_water,head_in_water)
			update_air_hud()
			if message_time<=0 and player.position.distance_to(lake_arena.exit_position)<150:
				status.text="FALAR / ENTRAR · SAIR DO TEMPLO SUBMERSO"
		auto_save+=delta
		if auto_save>=10:
			auto_save=0
			if not multiplayer_active:
				save_world()
		message_time=maxf(0,message_time-delta)
		queue_redraw()
		return
	if in_structure!="":
		mining_held=false
		message_time=maxf(0,message_time-delta)
		if message_time==0:
			if player.position.distance_to(Vector2(110,600))<150:
				status.text="FALAR / ENTRAR: sair pela porta"
			elif in_structure=="market" and player.position.x>650:
				status.text="FALAR / ENTRAR: abrir a loja de trocas"
		queue_redraw()
		return
	if is_instance_valid(device_controls) and device_controls.mobile and mining_held:
		refresh_mobile_mining_target()
	else:
		update_target()
	if is_instance_valid(player):
		var body_in_water=not in_purity and in_structure=="" and is_instance_valid(world) and world.is_point_in_lake_water(player.position)
		var head_in_water=body_in_water and world.is_point_in_lake_water(player.position+Vector2(0,-38))
		player.set_water_state(body_in_water,head_in_water)
		update_air_hud()
	if not in_purity:
		var near_mel=find_near_mel()
		var near_npc=find_near_npc()
		var near_building=find_near_structure()
		if world.is_near_lake_temple(player.position) and message_time<=0:
			status.text="FALAR / ENTRAR · TEMPLO SUBMERSO DO ABISMO"
		elif near_mel!=null and message_time<=0:
			status.text="FALAR / INTERAGIR: Mel quer alguma coisa..."
		elif near_npc!=null and message_time<=0:
			status.text="R / FALAR: conversar com "+near_npc.npc_name
		elif near_building!=null and message_time<=0:
			status.text="BOTÃO DIREITO / FALAR: entrar em "+near_building.display_name
	if target!=last_target:
		progress=0
		last_target=target
	if (not in_purity or in_purity_realm) and mining_held and target.x>=0 and world.get_cell(target)!=0:
		var id=world.get_cell(target)
		if world.is_village_protected(target) and not player.creative:
			progress=0
			status.text="A vila é protegida: não é possível quebrar blocos aqui."
			message_time=1.5
		else:
			progress+=delta*Items.mining_speed(player.inventory)
			if not player.creative and Items.required_pick_tier(id)>0 and not Items.can_mine(id,player.inventory):
				status.text="Sem "+Items.mining_requirement_text(id)+" · o bloco quebra, mas não gera drop."
				message_time=1
		if (player.creative or in_purity_realm or not world.is_village_protected(target)) and (player.creative or progress>=Items.HARDNESS.get(id,1.0)):
			if id==28:
				spill_chest(target)
			world.set_cell(target,0)
			if multiplayer_active and is_instance_valid(online):
				online.send_block_change(target,0)
			if is_instance_valid(game_audio): game_audio.mine()
			var drop=Items.drop_for_block(id,player.inventory)
			if drop>0:
				if in_purity_realm:
					try_collect_ground_item(drop,1)
				else:
					var drop_position=Vector2(target.x*32+16,target.y*32+8)
					if multiplayer_active and is_instance_valid(online):
						online.send_drop_spawn(drop,1,drop_position)
					else:
						spawn_ground_drop(drop,1,drop_position)
			progress=0
			if is_instance_valid(device_controls) and device_controls.mobile and mining_held:
				target=Vector2i(-1,-1)
				set_touch_action_target()
			refresh_hud()
	else:
		progress=0
	clock+=delta/720.0
	if clock>=1:
		clock-=1
		day+=1
	sky.clock=clock
	var player_cell_x=int(player.position.x/32.0)
	if not in_purity and world.is_lake_zone(player_cell_x):
		if not lake_announced:
			lake_announced=true
			lake_discovered=true
			status.text="LAGO ABISSAL DESCOBERTO · há ruínas no ponto mais profundo."
			message_time=5
	if not in_purity and world.is_snow_biome(player_cell_x):
		if not snow_announced:
			snow_announced=true
			status.text="BIOMA NEVADO DESCOBERTO · O frio daqui exige preparação."
			message_time=6
		if quest_state(QUEST_SNOW)=="in_progress":
			snow_reached=true
			ensure_polar_bear()
			update_quest_markers()
	if not in_purity and world.is_desert_biome(player_cell_x) and not desert_announced:
		desert_announced=true
		status.text="DESERTO DESCOBERTO · areia, arenito e vegetação rara."
		message_time=5
	spawn_timer+=delta
	if spawn_timer>9:
		spawn_timer=0
		if not in_purity and difficulty>0 and (clock<.22 or clock>.78) and enemies.get_child_count()<8:
			spawn_mob()
	auto_save+=delta
	if auto_save>=10:
		auto_save=0
		if not multiplayer_active:
			save_world()
	if int(Time.get_ticks_msec()/250)%2==0:
		hp_bar.max_value=player.max_hp
		hp_bar.value=player.max_hp if player.creative else player.hp
		food_bar.value=100 if player.creative else player.food
		stats.text="LIVRE" if player.creative else "%d/%d" % [int(player.hp),int(player.max_hp)]
		food_value.text="LIVRE" if player.creative else str(int(player.food))
		update_air_hud()
		var minutes=int(clock*1440)
		time_label.text=("SALA "+online.room_code+" · " if multiplayer_active and is_instance_valid(online) else "")+"DIA %d  ·  %02d:%02d" % [day,minutes/60,minutes%60]
	message_time=maxf(0,message_time-delta)
	if message_time==0:
		status.text=""
	if mining_held and target.x>=0 and world.get_cell(target)!=0:
		var hardness=float(Items.HARDNESS.get(world.get_cell(target),1.0))
		var pct=clampi(int(progress/maxf(0.01,hardness)*100.0),0,99)
		status.text="⛏ MINERANDO  %d%%  %s" % [pct,"▰".repeat(pct/20)+"▱".repeat(5-pct/20)]
	update_quest_markers()
	queue_redraw()

func spawn_village_hub() -> void:
	if not is_instance_valid(structures) or not is_instance_valid(world):
		return
	var defs=[
		{"x":18,"kind":"blacksmith","name":"Forja de Borin","texture":"res://assets/structures/blacksmith.png"},
		{"x":34,"kind":"market","name":"Casa do Mercador","texture":"res://assets/structures/market.png"},
		{"x":50,"kind":"chapel","name":"Capela da Pureza","texture":"res://assets/structures/chapel.png"}
	]
	for data in defs:
		var x=int(data.x)
		var building=VillageStructure.new()
		building.configure(str(data.kind),str(data.name),str(data.texture),player,self)
		building.position=Vector2(x*32+16,world.surfaces[x]*32)
		structures.add_child(building)

func spawn_mel() -> void:
	if not is_instance_valid(world):
		return
	mel=Mel.new()
	mel.setup(player,mel_tamed)
	mel.set_world_bounds(float(World.WORLD_MIN_X),float(World.WORLD_MAX_X),float(World.WORLD_MIN_Y),float(World.WORLD_MAX_Y))
	var x=26
	mel.position=Vector2(x*32+16,world.surfaces[x]*32-2)
	mel.interacted.connect(func(_dog): show_mel_dialogue())
	add_child(mel)

func maybe_start_mel_quest() -> void:
	if multiplayer_active:
		return
	if not active or mel_tamed or not is_instance_valid(mel):
		return
	if quest_state(QUEST_MEL)=="not_started":
		accept_quest(QUEST_MEL)
		show_mel_dialogue()

func npc_face_texture(path: String, role: String="") -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	return load(path)

func item_display_texture(id:int, craft:bool=false) -> Texture2D:
	var path=Items.CRAFT_ICONS.get(id,Items.ICONS.get(id,"res://assets/items/dirt.png")) if craft else Items.ICONS.get(id,"res://assets/items/dirt.png")
	return load(path) if ResourceLoader.exists(path) else null

func show_mel_dialogue() -> void:
	if mel_tamed:
		status.text="Mel está com você · +2 de dano contra mobs"
		message_time=3
		return
	if quest_state(QUEST_MEL)=="not_started":
		accept_quest(QUEST_MEL)
	clear_menu("","mel_dialogue")
	var mobile=get_viewport_rect().size.x<=760
	var card=PanelContainer.new()
	card.add_theme_stylebox_override("panel",compact_panel_style(0.97,Color("9a7655"),10))
	card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	menu_box.add_child(card)
	var content=VBoxContainer.new()
	content.add_theme_constant_override("separation",9)
	card.add_child(content)

	var header=HBoxContainer.new()
	header.add_theme_constant_override("separation",10)
	content.add_child(header)
	var portrait=TextureRect.new()
	portrait.texture=npc_face_texture("res://assets/npcs/mel_generated.png","mel")
	portrait.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.custom_minimum_size=Vector2(82,82) if mobile else Vector2(118,118)
	header.add_child(portrait)
	var head_text=VBoxContainer.new()
	head_text.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	header.add_child(head_text)
	var title=label("MEL",22 if mobile else 25)
	title.add_theme_color_override("font_color",Color("f1c987"))
	head_text.add_child(title)
	var role=label("COMPANHEIRA",10)
	role.add_theme_color_override("font_color",Color("b8a5c5"))
	head_text.add_child(role)

	var bones=int(player.inventory.get(23,0))
	var speech=label("Mel abana o rabinho e olha para você. Ela quer 3 ossos. Os monstros que surgem à noite deixam ossos quando são derrotados.\n\nOssos: %d / 3" % bones,14 if mobile else 16)
	speech.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	speech.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	content.add_child(speech)

	if bones>=3 or player.creative:
		var tame=button("ENTREGAR 3 OSSOS · CONCLUIR MISSÃO",func():
			complete_quest(QUEST_MEL)
			resume()
		)
		tame.custom_minimum_size=Vector2(0,48)
		content.add_child(tame)
	else:
		var hint=label("Volte quando conseguir 3 ossos durante a noite.",11)
		hint.add_theme_color_override("font_color",Color("b8a5c5"))
		content.add_child(hint)
	var close=button("FECHAR",resume)
	close.custom_minimum_size=Vector2(0,46)
	content.add_child(close)
	layout()

func can_pay_trade(cost:Dictionary) -> bool:
	if player.creative:
		return true
	for raw_id in cost:
		var id=int(raw_id)
		if int(player.inventory.get(id,0))<int(cost[raw_id]):
			return false
	return true

func perform_trade(cost:Dictionary,reward_id:int,reward_count:int,trade_name:String) -> void:
	if not can_pay_trade(cost):
		status.text="Você não tem materiais suficientes para essa troca."
		message_time=3
		return
	if not player.creative:
		for raw_id in cost:
			var id=int(raw_id)
			player.inventory[id]=int(player.inventory.get(id,0))-int(cost[raw_id])
	player.inventory[reward_id]=int(player.inventory.get(reward_id,0))+reward_count
	status.text=trade_name+" adquirido."
	message_time=3
	refresh_hud()
	show_shop()

func trade_button(title:String,cost:Dictionary,reward_id:int,reward_count:int) -> Button:
	var parts:Array[String]=[]
	for raw_id in cost:
		var id=int(raw_id)
		parts.append("%d %s" % [int(cost[raw_id]),Items.NAMES.get(id,"item")])
	var text=title+"   ←   "+", ".join(parts)
	var b=button(text,func(): perform_trade(cost,reward_id,reward_count,title))
	b.disabled=not can_pay_trade(cost)
	b.custom_minimum_size=Vector2(0,58)
	if Items.ICONS.has(reward_id):
		b.icon=item_display_texture(reward_id)
		b.expand_icon=true
		b.add_theme_constant_override("icon_max_width",34)
	return b

func show_shop() -> void:
	if not active:
		return
	clear_menu("LOJA DO MERCADOR","shop")
	var intro=label("Troque recursos encontrados no mundo. O mercador também ajuda a manter a vila abastecida.",14)
	intro.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	intro.add_theme_color_override("font_color",Color("cbb9d4"))
	menu_box.add_child(intro)

	var state=quest_state(QUEST_MERCHANT)
	if not quest_unlocked(QUEST_MERCHANT):
		var locked=label("MISSÃO BLOQUEADA · Ajude Borin antes de assumir o pedido do mercador.",12)
		locked.add_theme_color_override("font_color",Color("9f91a7"))
		menu_box.add_child(locked)
	elif state=="not_started":
		var mission=label("MISSÃO · SUPRIMENTOS DA VILA\nLeve 12 madeiras e 6 carvões.\nRecompensa: Waystone + 3 carnes.",12)
		mission.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		mission.add_theme_color_override("font_color",Color("e3bd78"))
		menu_box.add_child(mission)
		menu_box.add_child(button("ACEITAR MISSÃO",func():
			accept_quest(QUEST_MERCHANT)
			show_shop()
		))
	elif state=="in_progress":
		var progress_label=label("SUPRIMENTOS DA VILA · "+quest_progress_text(QUEST_MERCHANT),12)
		progress_label.add_theme_color_override("font_color",Color("e3bd78"))
		menu_box.add_child(progress_label)
		var deliver=button("ENTREGAR SUPRIMENTOS",func():
			complete_quest(QUEST_MERCHANT)
			show_shop()
		)
		deliver.disabled=not quest_ready(QUEST_MERCHANT)
		menu_box.add_child(deliver)
	else:
		var done=label("MISSÃO CONCLUÍDA · O mercador agora confia em você.",12)
		done.add_theme_color_override("font_color",Color("9fe7b2"))
		menu_box.add_child(done)

	menu_box.add_child(trade_button("Waystone",{3:8,14:1},24,1))
	menu_box.add_child(trade_button("Carne x3",{6:5},10,3))
	menu_box.add_child(trade_button("Osso x2",{6:6},23,2))
	menu_box.add_child(trade_button("Diamante",{7:12},14,1))
	menu_box.add_child(button("VOLTAR PARA A CASA",resume))
	update_quest_markers()
	layout()


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
	npc.set_world_bounds(float(World.WORLD_MIN_X),float(World.WORLD_MAX_X),float(World.WORLD_MIN_Y),float(World.WORLD_MAX_Y))
	npc.position=Vector2(15*32+16,world.surfaces[15]*32-2)
	npc.interacted.connect(func(who): show_npc_dialogue(who))
	npcs.add_child(npc)
	var monk=NPC.new()
	monk.setup("monge","Monge da Pureza",[
		"A Pureza não é um lugar. É uma prova.",
		"Se encontrar Avarita, não tente transformá-la em arma.",
		"O portal responde a nove diamantes e uma Avarita."
	],player)
	monk.set_world_bounds(float(World.WORLD_MIN_X),float(World.WORLD_MAX_X),float(World.WORLD_MIN_Y),float(World.WORLD_MAX_Y))
	monk.position=Vector2(48*32+16,world.surfaces[48]*32-2)
	monk.interacted.connect(func(who): show_npc_dialogue(who))
	npcs.add_child(monk)

func find_near_mel():
	if in_purity or in_structure!="" or not is_instance_valid(mel) or mel_tamed:
		return null
	return mel if mel.can_interact() else null

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
	if in_lake_temple:
		if is_instance_valid(lake_arena) and player.position.distance_to(lake_arena.exit_position)<145:
			leave_lake_temple()
			return true
		return false
	if in_structure!="":
		if player.position.distance_to(Vector2(110,600))<135:
			exit_structure()
			return true
		if in_structure=="market" and player.position.x>650:
			show_shop()
			return true
		return false
	if is_instance_valid(mel) and not mel_tamed and mel.can_interact():
		mel.interact()
		return true
	if not in_purity and is_instance_valid(world) and world.is_near_lake_temple(player.position):
		enter_lake_temple()
		return true
	var near_mel=find_near_mel()
	if near_mel!=null:
		near_mel.interact()
		return true
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
	player.set_water_state(false,false)
	structure_return_position=player.position
	in_structure=kind
	set_world_collision(false)
	world.hide()
	if is_instance_valid(npcs): npcs.hide()
	if is_instance_valid(mel): mel.hide()
	if is_instance_valid(structures): structures.hide()
	if is_instance_valid(enemies):
		enemies.hide()
		enemies.process_mode=Node.PROCESS_MODE_DISABLED
	sky.hide()
	interior=Interior.new()
	interior.configure(kind,display_name)
	interior.z_index=0
	add_child(interior)
	player.z_index=20
	player.show()
	if is_instance_valid(player.sprite):
		player.sprite.show()
	player.position=Vector2(640,570)
	player.velocity=Vector2.ZERO
	player.set_world_bounds(0.0,1280.0,0.0,720.0)
	# Frame the 1280x720 interior background exactly while keeping the player
	# close to the bottom of the screen.
	player.camera.position=Vector2(0,-210)
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
	player.z_index=0
	player.show()
	if is_instance_valid(player.sprite):
		player.sprite.show()
	world.show()
	set_world_collision(true)
	if is_instance_valid(npcs): npcs.show()
	if is_instance_valid(mel): mel.show()
	if is_instance_valid(structures): structures.show()
	if is_instance_valid(enemies):
		enemies.show()
		enemies.process_mode=Node.PROCESS_MODE_INHERIT
	sky.show()
	player.position=structure_return_position
	player.velocity=Vector2.ZERO
	player.set_world_bounds(0.0,float(world.world_width()*32),0.0,float(World.HEIGHT*32))
	player.camera.position=Vector2(0,-100)
	player.camera.reset_smoothing()

func show_npc_dialogue(npc) -> void:
	current_npc=npc
	clear_menu("","npc_dialogue")
	var mobile=get_viewport_rect().size.x<=760
	var portrait_path="res://assets/npcs/monk_generated.png" if npc.role=="monge" else "res://assets/npcs/blacksmith_generated.png"
	var card=PanelContainer.new()
	card.add_theme_stylebox_override("panel",compact_panel_style(0.98,Color("8b6e9d"),10))
	card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	menu_box.add_child(card)
	var content=VBoxContainer.new()
	content.add_theme_constant_override("separation",9)
	card.add_child(content)

	var header=HBoxContainer.new()
	header.add_theme_constant_override("separation",10)
	content.add_child(header)
	var portrait=TextureRect.new()
	portrait.texture=npc_face_texture(portrait_path,npc.role)
	portrait.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.custom_minimum_size=Vector2(88,88) if mobile else Vector2(125,125)
	header.add_child(portrait)
	var info=VBoxContainer.new()
	info.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	header.add_child(info)
	var role_label=label("MONGE DA PUREZA" if npc.role=="monge" else "FERREIRO",10)
	role_label.add_theme_color_override("font_color",Color("b79ac8"))
	info.add_child(role_label)
	var who=label(npc.npc_name,20 if mobile else 23)
	who.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	who.add_theme_color_override("font_color",Color("f0d99a"))
	info.add_child(who)

	var speech=label("“"+npc.next_line()+"”",14 if mobile else 17)
	speech.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	speech.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	speech.add_theme_color_override("font_color",Color("eee5ed"))
	content.add_child(speech)

	if npc.role=="ferreiro":
		var borin_state=quest_state(QUEST_BORIN)
		if borin_state=="not_started":
			var quest=label("MISSÃO · REFORÇANDO A FORJA\nColete 10 pedras e 5 ferros.\nRecompensa: Espada de ferro + 1 diamante.",12)
			quest.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
			quest.add_theme_color_override("font_color",Color("e3bd78"))
			content.add_child(quest)
			content.add_child(button("ACEITAR MISSÃO",func():
				accept_quest(QUEST_BORIN)
				show_npc_dialogue(npc)
			))
		elif borin_state=="in_progress":
			var quest=label("REFORÇANDO A FORJA · "+quest_progress_text(QUEST_BORIN),12)
			quest.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
			quest.add_theme_color_override("font_color",Color("e3bd78"))
			content.add_child(quest)
			var give=button("ENTREGAR MATERIAIS",func(): complete_borin_quest(npc))
			give.disabled=not quest_ready(QUEST_BORIN)
			give.custom_minimum_size=Vector2(0,48)
			content.add_child(give)
		else:
			var done=label("MISSÃO CONCLUÍDA · A forja foi reforçada.",12)
			done.add_theme_color_override("font_color",Color("9fe7b2"))
			content.add_child(done)
			if quest_unlocked(QUEST_ABYSS):
				var abyss_state=quest_state(QUEST_ABYSS)
				if abyss_state=="not_started":
					var abyss_quest=label("NOVA MISSÃO · PESTE DO ABISMO\nBorin viu criaturas novas além da vila. Derrote 4 Slimes Sombrios e 2 Guardiões Espectrais.\nRecompensa: 2 diamantes + 4 carnes.",12)
					abyss_quest.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
					abyss_quest.add_theme_color_override("font_color",Color("b892ee"))
					content.add_child(abyss_quest)
					content.add_child(button("ACEITAR PESTE DO ABISMO",func():
						accept_quest(QUEST_ABYSS)
						show_npc_dialogue(npc)
					))
				elif abyss_state=="in_progress":
					var abyss_progress=label("PESTE DO ABISMO · "+quest_progress_text(QUEST_ABYSS),12)
					abyss_progress.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
					abyss_progress.add_theme_color_override("font_color",Color("b892ee"))
					content.add_child(abyss_progress)
					var abyss_claim=button("ENTREGAR RELATÓRIO DA CAÇADA",func(): complete_quest(QUEST_ABYSS,npc))
					abyss_claim.disabled=not quest_ready(QUEST_ABYSS)
					content.add_child(abyss_claim)
				else:
					var abyss_done=label("PESTE DO ABISMO CONCLUÍDA · As estradas estão menos perigosas.",12)
					abyss_done.add_theme_color_override("font_color",Color("9fe7b2"))
					content.add_child(abyss_done)
		var craft_button=button("ABRIR BANCADA",func():
			craft_override=true
			show_craft()
		)
		craft_button.custom_minimum_size=Vector2(0,48)
		content.add_child(craft_button)
	elif npc.role=="monge":
		var monk_state=quest_state(QUEST_MONK)
		if not quest_unlocked(QUEST_MONK):
			var locked=label("O Monge ainda não oferece a Prova da Noite. Ajude a vila e o mercador primeiro.",12)
			locked.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
			locked.add_theme_color_override("font_color",Color("9f91a7"))
			content.add_child(locked)
		elif monk_state=="not_started":
			var quest=label("MISSÃO · PROVA DA NOITE\nDerrote 7 criaturas hostis durante a noite, longe da vila.\nRecompensa: +20 vida máxima + 2 diamantes.",12)
			quest.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
			quest.add_theme_color_override("font_color",Color("e3bd78"))
			content.add_child(quest)
			content.add_child(button("ACEITAR PROVA",func():
				accept_quest(QUEST_MONK)
				show_npc_dialogue(npc)
			))
		elif monk_state=="in_progress":
			var quest=label("PROVA DA NOITE · "+quest_progress_text(QUEST_MONK),12)
			quest.add_theme_color_override("font_color",Color("e3bd78"))
			content.add_child(quest)
			var claim=button("RECEBER BÊNÇÃO",func(): complete_monk_quest(npc))
			claim.disabled=not quest_ready(QUEST_MONK)
			claim.custom_minimum_size=Vector2(0,48)
			content.add_child(claim)
		else:
			var blessed=label("PROVA DA NOITE CONCLUÍDA · Sua vida máxima foi ampliada.",12)
			blessed.add_theme_color_override("font_color",Color("9fe7b2"))
			content.add_child(blessed)

			var snow_state=quest_state(QUEST_SNOW)
			if snow_state=="not_started":
				var snow_quest=label("NOVA MISSÃO · URSO DO NORTE\nAtravesse as terras até o bioma de neve e derrote o Urso Polar Ancião.\nRecompensa: Relíquia Vital + 2 diamantes e acesso ao desafio final.",12)
				snow_quest.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
				snow_quest.add_theme_color_override("font_color",Color("b9dff3"))
				content.add_child(snow_quest)
				content.add_child(button("ACEITAR URSO DO NORTE",func():
					accept_quest(QUEST_SNOW)
					show_npc_dialogue(npc)
				))
			elif snow_state=="in_progress":
				var snow_progress=label("URSO DO NORTE · "+quest_progress_text(QUEST_SNOW),12)
				snow_progress.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
				snow_progress.add_theme_color_override("font_color",Color("b9dff3"))
				content.add_child(snow_progress)
				var snow_claim=button("ENTREGAR PROVA DO URSO",func(): complete_quest(QUEST_SNOW,npc))
				snow_claim.disabled=not quest_ready(QUEST_SNOW)
				content.add_child(snow_claim)
			else:
				var snow_done=label("URSO DO NORTE CONCLUÍDA · O caminho para o Guardião está liberado.",12)
				snow_done.add_theme_color_override("font_color",Color("9fe7b2"))
				content.add_child(snow_done)
	var close=button("CONTINUAR",resume)
	close.custom_minimum_size=Vector2(0,46)
	content.add_child(close)
	layout()

func has_polar_bear() -> bool:
	if not is_instance_valid(enemies):
		return false
	for mob in enemies.get_children():
		if str(mob.kind)=="polar_bear":
			return true
	return false

func ensure_polar_bear() -> void:
	if polar_bear_defeated or quest_state(QUEST_SNOW)!="in_progress" or not is_instance_valid(world) or has_polar_bear():
		return
	var spawn=world.snow_spawn_cell()
	var bear=Mob.new()
	bear.kind="polar_bear"
	bear.player=player
	bear.difficulty_level=maxi(2,difficulty)
	bear.set_world_bounds(float(World.WORLD_MIN_X),float(World.WORLD_MAX_X),float(World.WORLD_MIN_Y),float(World.WORLD_MAX_Y))
	bear.position=Vector2(spawn.x*32+16,spawn.y*32-2)
	bear.killed.connect(func():
		polar_bear_defeated=true
		if not player.creative:
			player.inventory[14]=int(player.inventory.get(14,0))+1
			player.inventory[24]=int(player.inventory.get(24,0))+1
		status.text="Urso Polar Ancião derrotado · +1 diamante + Waystone. Volte ao Monge."
		message_time=6
		refresh_hud()
		update_quest_markers()
		save_world()
	)
	enemies.add_child(bear)


func spawn_mob() -> void:
	if not is_instance_valid(player) or not is_instance_valid(world):
		return
	var player_cell=clampi(int(player.position.x/32),0,World.WIDTH-1)
	# Vila/spawn é uma zona segura: hostis só podem aparecer depois de o jogador
	# realmente deixar o povoado.
	if player_cell<=World.VILLAGE_MAX_X+10 or world.is_lake_zone(player_cell):
		return
	var cell=clampi(player_cell+(18 if randf()>.5 else -18),World.VILLAGE_MAX_X+11,world.world_width()-3)
	if world.is_lake_zone(cell):
		return
	if world.is_village_protected(Vector2i(cell,world.surfaces[cell])):
		return
	var mob=Mob.new()
	var roll=randf()
	# Only the dedicated pixel-art sheets are used for natural spawns. The old
	# atlas skeleton/wolf looked like pasted PNGs next to the newer art.
	mob.kind="undead_knight" if roll>.76 else "corrupted_skeleton" if roll>.38 else "dark_slime"
	mob.player=player
	mob.difficulty_level=difficulty
	mob.set_world_bounds(float(World.WORLD_MIN_X),float(World.WORLD_MAX_X),float(World.WORLD_MIN_Y),float(World.WORLD_MAX_Y))
	mob.position=Vector2(cell*32,world.surfaces[cell]*32-2)
	mob.killed.connect(func():
		var death_pos=mob.position
		spawn_ground_drop(10,1,death_pos+Vector2(-10,-8))
		spawn_ground_drop(23,1,death_pos+Vector2(10,-8))
		var night_now=clock<.22 or clock>.78
		var death_cell=int(death_pos.x/32)
		if quest_state(QUEST_ABYSS)=="in_progress" and death_cell>World.VILLAGE_MAX_X+8:
			if str(mob.kind)=="dark_slime":
				abyss_slime_kills=mini(4,abyss_slime_kills+1)
			elif str(mob.kind)=="undead_knight":
				abyss_warden_kills=mini(2,abyss_warden_kills+1)
			status.text="PESTE DO ABISMO · "+quest_progress_text(QUEST_ABYSS)
			message_time=3
			update_quest_markers()
		if quest_state(QUEST_MONK)=="in_progress" and night_now and death_cell>World.VILLAGE_MAX_X+8:
			night_kills+=1
			status.text="PROVA DA NOITE · %d/7 criaturas" % mini(7,night_kills)
			update_quest_markers()
		else:
			status.text="Criatura derrotada · recolha os drops no chão."
		message_time=2.5
	)
	enemies.add_child(mob)

func ensure_lake_boss() -> void:
	if lake_boss_defeated or not in_lake_temple or not is_instance_valid(player) or not is_instance_valid(lake_arena):
		return
	if is_instance_valid(lake_boss):
		return
	lake_boss=LakeBoss.new()
	lake_boss.player=player
	lake_boss.set_arena_bounds(lake_arena.arena_size,lake_arena.floor_y)
	lake_boss.position=lake_arena.boss_position
	enemies.add_child(lake_boss)
	lake_boss.defeated.connect(on_lake_boss_defeated)

func enter_lake_temple(skip_intro:bool=false) -> void:
	if in_lake_temple or in_purity or in_structure!="" or not is_instance_valid(world):
		return
	if not skip_intro and not world.is_near_lake_temple(player.position):
		return
	lake_return_position=player.position
	lake_discovered=true
	lake_announced=true
	in_lake_temple=true
	set_world_collision(false)
	world.hide()
	sky.hide()
	for node in [structures,npcs,mel,drops]:
		if is_instance_valid(node):
			node.hide()
	if is_instance_valid(death_bags):
		death_bags.show()
	for mob in enemies.get_children():
		enemies.remove_child(mob)
		mob.queue_free()
	lake_boss=null
	lake_arena=LakeArena.new()
	lake_arena.world_seed=world.world_seed
	add_child(lake_arena)
	player.z_index=20
	player.position=lake_arena.spawn_position
	player.velocity=Vector2.ZERO
	player.max_fall_speed=0
	player.set_water_state(lake_arena.is_in_water(player.position),lake_arena.is_in_water(player.position+Vector2(0,-38)))
	player.set_world_bounds(0.0,lake_arena.arena_size.x,0.0,lake_arena.arena_size.y)
	player.camera.position=Vector2(0,-145)
	player.camera.reset_smoothing()
	mining_held=false
	progress=0
	if not lake_boss_defeated:
		ensure_lake_boss()
	status.text="TEMPLO SUBMERSO DO ABISMO · o Leviatã desperta nas águas antigas."
	message_time=5
	update_purity_hud()

func leave_lake_temple(on_death:bool=false) -> void:
	if not in_lake_temple:
		return
	if is_instance_valid(lake_boss):
		lake_boss.queue_free()
	lake_boss=null
	if is_instance_valid(lake_arena):
		lake_arena.queue_free()
	lake_arena=null
	in_lake_temple=false
	player.z_index=0
	world.show()
	set_world_collision(true)
	sky.show()
	for node in [structures,npcs,mel,drops]:
		if is_instance_valid(node):
			node.show()
	if is_instance_valid(death_bags):
		death_bags.show()
	player.position=world.lake_shore_spawn() if on_death else lake_return_position
	player.velocity=Vector2.ZERO
	player.max_fall_speed=0
	player.set_water_state(world.is_point_in_lake_water(player.position),world.is_point_in_lake_water(player.position+Vector2(0,-38)))
	player.set_world_bounds(0.0,float(world.world_width()*32),0.0,float(World.HEIGHT*32))
	player.camera.position=Vector2(0,-100)
	player.camera.reset_smoothing()
	status.text="Você voltou ao LAGO ABISSAL."
	message_time=3
	update_purity_hud()

func on_lake_boss_defeated() -> void:
	if lake_boss_defeated:
		return
	lake_boss_defeated=true
	lake_boss=null
	# Victory is a safe state. The menu is modal, so main._process() stops updating
	# water state; explicitly clear submersion here so the player cannot drown
	# while reading the victory screen or be treated as dead when the boss falls.
	player.hp=player.max_hp
	player.air=player.max_air
	player.hurt_time=1.5
	player.velocity=Vector2.ZERO
	player.set_water_state(false,false)
	if int(player.inventory.get(27,0))<=0:
		player.inventory[27]=1
	forms_unlocked["fox"]=true
	player.inventory[14]=int(player.inventory.get(14,0))+3
	player.inventory[25]=int(player.inventory.get(25,0))+4
	clear_menu("LEVIATÃ DO LAGO ABISSAL DERROTADO","lake_victory")
	var victory=label("O coração da criatura ainda pulsa entre as ruínas inundadas.",16)
	victory.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	menu_box.add_child(victory)
	menu_box.add_child(label("Recompensa: 1x Coração Abissal · 3 Diamantes · 4 Minérios das Almas",13))
	var fox_unlock=label("NOVA FORMA DESBLOQUEADA: RAPOSA",15)
	fox_unlock.add_theme_color_override("font_color",Color("e8ad72"))
	menu_box.add_child(fox_unlock)
	menu_box.add_child(button("CONTINUAR NA ARENA",func():
		resume()
	))
	menu_box.add_child(button("SAIR DO TEMPLO",func():
		resume()
		leave_lake_temple()
	))
	boss_panel.hide()
	refresh_hud()
	save_world()

func save_world() -> bool:
	if not active:
		return false
	var saved_world=overworld if in_purity else world
	var saved_position=player.position
	if in_purity:
		saved_position=return_position
	elif in_lake_temple:
		saved_position=lake_return_position
	elif in_structure!="":
		saved_position=structure_return_position
	var data={"version":11,"name":world_name,"seed":saved_world.world_seed,"cells":saved_world.cells,"surfaces":saved_world.surfaces,"creative":player.creative,"position":[saved_position.x,saved_position.y],"hp":player.hp,"food":player.food,"inventory":player.inventory,"clock":clock,"day":day,"difficulty":difficulty,"saved_at":int(Time.get_unix_time_from_system()),"boss_defeated":boss_defeated,"in_purity":in_purity,"in_purity_realm":in_purity_realm,"mel_tamed":mel_tamed,"mel_quest_started":mel_quest_started,"borin_quest_done":borin_quest_done,"monk_quest_done":monk_quest_done,"night_kills":night_kills,"polar_bear_defeated":polar_bear_defeated,"hotbar":hotbar.duplicate(),"selected":selected,"dropped_items":serialize_ground_drops(),"death_backpacks":serialize_death_backpacks(),"quest_states":quest_states.duplicate(true),"snow_reached":snow_reached,"abyss_slime_kills":abyss_slime_kills,"abyss_warden_kills":abyss_warden_kills,"lake_generated":saved_world.lake_generated,"lake_center_x":saved_world.lake_center_x,"lake_width":saved_world.lake_width,"lake_depth":saved_world.lake_depth,"lake_water_y":saved_world.lake_water_y,"lake_discovered":lake_discovered,"in_lake_temple":in_lake_temple,"lake_boss_defeated":lake_boss_defeated,"lake_boss_hp":lake_boss.hp if is_instance_valid(lake_boss) else -1.0,"forms_unlocked":forms_unlocked.duplicate(true),"current_form":current_form,"armor_equipment":armor_equipment.duplicate(true),"chests":serialize_chests()}
	if in_purity:
		if in_purity_realm:
			data["purity_position"]=[player.position.x,player.position.y]
		else:
			data["arena_position"]=[player.position.x,player.position.y]
			data["boss_hp"]=boss.hp if is_instance_valid(boss) else 0
			data["intro_complete"]=is_instance_valid(boss) and boss.awakened
	var error=Saves.write(data)
	if error!=OK:
		status.text="Não foi possível salvar o mundo. Código %d" % error
		message_time=8
		return false
	if is_instance_valid(cloud) and cloud.is_authenticated():
		upload_world_to_cloud(Saves.current_world_id(),data.duplicate(true))
	return true

func load_world() -> void:
	var data=Saves.read_save()
	if data.is_empty():
		return
	start_world(bool(data.creative),int(data.seed))
	world_name=str(data.name)
	world.cells=data.cells
	world.surfaces.assign(data.surfaces)
	# Older saves were 320 blocks wide. Extend them deterministically once to the
	# current finite width, preserving every existing modified cell.
	world.ensure_generated_to(World.WIDTH-1)
	if int(data.get("lake_center_x",-1))>=0:
		world.restore_lake_layout(
			int(data.get("lake_center_x",world.lake_center_x)),
			int(data.get("lake_width",world.lake_width)),
			int(data.get("lake_depth",world.lake_depth))
		)
	world.repair_village_zone()
	world.repair_lake_zone()
	world.remove_ore(25)
	world.ensure_ore_minimums()
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
	armor_equipment={"head":0,"chest":0,"legs":0,"feet":0}
	var loaded_armor=data.get("armor_equipment",{})
	if loaded_armor is Dictionary:
		for slot in ["head","chest","legs","feet"]:
			var armor_id=int(loaded_armor.get(slot,0))
			if armor_id==0 or (Items.is_armor(armor_id) and Items.armor_slot(armor_id)==slot):
				armor_equipment[slot]=armor_id
	apply_armor_equipment()
	clock=float(data.clock)
	day=int(data.day)
	difficulty=int(data.difficulty)
	boss_defeated=bool(data.get("boss_defeated",false))
	mel_tamed=bool(data.get("mel_tamed",false))
	mel_quest_started=bool(data.get("mel_quest_started",mel_tamed))
	borin_quest_done=bool(data.get("borin_quest_done",false))
	monk_quest_done=bool(data.get("monk_quest_done",false))
	night_kills=int(data.get("night_kills",0))
	polar_bear_defeated=bool(data.get("polar_bear_defeated",false))
	lake_boss_defeated=bool(data.get("lake_boss_defeated",false))
	lake_discovered=bool(data.get("lake_discovered",false))
	lake_announced=lake_discovered
	forms_unlocked={"spike":true,"fox":false}
	var loaded_forms=data.get("forms_unlocked",{})
	if loaded_forms is Dictionary:
		forms_unlocked["fox"]=bool(loaded_forms.get("fox",false))
	if lake_boss_defeated:
		forms_unlocked["fox"]=true
	current_form=str(data.get("current_form","spike"))
	if current_form not in ["spike","fox"] or (current_form=="fox" and not bool(forms_unlocked.get("fox",false))):
		current_form="spike"
	player.set_form(current_form)
	var saved_quests=data.get("quest_states",{})
	if saved_quests is Dictionary and not saved_quests.is_empty():
		for quest_id in [QUEST_MEL,QUEST_BORIN,QUEST_MERCHANT,QUEST_ABYSS,QUEST_MONK,QUEST_SNOW]:
			var loaded_state=str(saved_quests.get(quest_id,"not_started"))
			quest_states[quest_id]=loaded_state if loaded_state in ["not_started","in_progress","completed"] else "not_started"
		if not saved_quests.has(QUEST_ABYSS) and (quest_state(QUEST_MONK)!="not_started" or quest_state(QUEST_SNOW)!="not_started"):
			quest_states[QUEST_ABYSS]="completed"
	else:
		# Migration for worlds created before BUILD 13.8: preserve completed old
		# objectives and never trap an advanced save behind a newly-added mission.
		quest_states[QUEST_MEL]="completed" if mel_tamed else ("in_progress" if mel_quest_started else "not_started")
		quest_states[QUEST_BORIN]="completed" if borin_quest_done else "not_started"
		quest_states[QUEST_MERCHANT]="completed" if borin_quest_done else "not_started"
		quest_states[QUEST_ABYSS]="completed" if monk_quest_done or polar_bear_defeated else "not_started"
		quest_states[QUEST_MONK]="completed" if monk_quest_done else "not_started"
		quest_states[QUEST_SNOW]="completed" if polar_bear_defeated and monk_quest_done else "not_started"
	snow_reached=bool(data.get("snow_reached",polar_bear_defeated))
	abyss_slime_kills=int(data.get("abyss_slime_kills",0))
	abyss_warden_kills=int(data.get("abyss_warden_kills",0))
	sync_legacy_quest_flags()
	if data.has("hotbar") and data.hotbar is Array:
		hotbar.clear()
		for raw_id in data.hotbar:
			hotbar.append(int(raw_id))
		while hotbar.size()<9:
			hotbar.append(0)
		if hotbar.size()>9:
			hotbar.resize(9)
	selected=int(data.get("selected",0))
	restore_chests(data.get("chests",{}))
	restore_ground_drops(data.get("dropped_items",[]))
	restore_death_backpacks(data.get("death_backpacks",[]))
	if monk_quest_done:
		player.max_hp=maxf(player.max_hp,120.0)
		player.hp=minf(player.hp,player.max_hp)
	if is_instance_valid(mel):
		mel.set_tamed(mel_tamed)
	update_quest_markers()
	if bool(data.get("in_lake_temple",false)):
		player.position=world.lake_temple_position()
		enter_lake_temple(true)
		if is_instance_valid(lake_boss) and float(data.get("lake_boss_hp",-1.0))>0:
			lake_boss.hp=clampf(float(data.get("lake_boss_hp",lake_boss.max_hp)),1.0,lake_boss.max_hp)
	if bool(data.get("in_purity",false)):
		if bool(data.get("in_purity_realm",false)) and boss_defeated:
			enter_purity_realm()
			var purity_position=data.get("purity_position",[12*32,33*32])
			player.position=Vector2(clampf(float(purity_position[0]),6*32,314*32),clampf(float(purity_position[1]),8*32,94*32))
		else:
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
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT and active:
		if not multiplayer_active:
			save_world()
		if not modal:
			show_pause()

func meter_style(color: Color) -> StyleBoxFlat:
	var style=StyleBoxFlat.new()
	style.bg_color=color
	style.set_corner_radius_all(2)
	return style

func resolve_place_target() -> void:
	if not is_instance_valid(world) or not is_instance_valid(player) or target.x<0:
		return
	if world.get_cell(target)==0:
		return
	if world.get_cell(target)==16:
		return
	var pointer=player.position+touch_aim if is_instance_valid(device_controls) and device_controls.mobile else get_global_mouse_position()
	var origin=player.position-Vector2(0,24)
	var source=target
	var best=Vector2i(-1,-1)
	var best_score=999999.0
	for offset in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
		var cell=source+offset
		if cell.x<0 or cell.x>=320 or cell.y<0 or cell.y>=95 or world.get_cell(cell)!=0:
			continue
		var area=Rect2(Vector2(cell)*32,Vector2(32,32))
		if player.body_rect().intersects(area):
			continue
		var center=Vector2(cell*32+Vector2i(16,16))
		if origin.distance_to(center)>170.0:
			continue
		var score=center.distance_to(pointer)
		if score<best_score:
			best_score=score
			best=cell
	if best.x>=0:
		target=best

func use_selected() -> void:
	if in_lake_temple:
		if interact_nearby():
			return
		if selected==10:
			eat()
			return
		if selected==24:
			use_waystone()
			return
		return
	if in_structure!="":
		interact_nearby()
		return
	if interact_nearby():
		return
	if target.x>=0 and world.get_cell(target)==16:
		use_portal()
		return
	if target.x>=0 and world.get_cell(target)==9:
		show_craft()
		return
	if target.x>=0 and world.get_cell(target)==28:
		show_chest(target)
		return
	if selected==10:
		eat()
		return
	if selected==24:
		use_waystone()
		return
	if Items.is_armor(selected):
		equip_armor_item(selected)
		return
	if selected in PLACEABLE_BLOCKS:
		if is_instance_valid(device_controls) and device_controls.mobile:
			set_touch_place_target()
		else:
			resolve_place_target()
	if not place_block():
		if selected not in PLACEABLE_BLOCKS:
			status.text="Selecione um bloco na hotbar para colocar."
		else:
			status.text="Aponte para um espaço vazio ao lado de um bloco."
		message_time=2.5

func use_waystone() -> void:
	if not active or not is_instance_valid(player):
		return
	var village_center=Vector2(34*32+16,35*32-2)
	# Waystone is an emergency return item. It must work from every special arena.
	if in_lake_temple:
		leave_lake_temple()
		player.position=village_center
		player.velocity=Vector2.ZERO
		player.max_fall_speed=0
		player.set_water_state(false)
		status.text="✦ A Waystone arrancou você do Templo Submerso e trouxe você à vila."
		message_time=5
		save_world()
		return
	if in_purity:
		leave_purity()
		player.position=village_center
		player.velocity=Vector2.ZERO
		player.max_fall_speed=0
		player.camera.reset_smoothing()
		status.text="✦ A Waystone rompeu o véu e trouxe você de volta à vila."
		message_time=5
		save_world()
		return
	if in_structure!="":
		exit_structure()
	if player.position.distance_to(village_center)<520:
		status.text="Você já está perto da vila."
		message_time=2.5
		return
	player.position=village_center
	player.velocity=Vector2.ZERO
	player.max_fall_speed=0
	player.camera.reset_smoothing()
	status.text="✦ A Waystone trouxe você de volta à vila."
	message_time=4
	save_world()


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
	elif boss_defeated:
		enter_purity_realm()
	elif not player.creative and quest_state(QUEST_SNOW)!="completed":
		status.text="O portal rejeita você · conclua a missão URSO DO NORTE com o Monge."
		message_time=5
		return
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
	var show_purity=active and in_purity and is_instance_valid(boss) and not modal
	var show_lake=active and in_lake_temple and is_instance_valid(lake_boss) and not modal
	boss_panel.visible=show_purity or show_lake
	if show_purity:
		boss_bar.max_value=boss.max_hp
		boss_bar.value=boss.hp
		boss_title.text="GUARDIÃO DA PUREZA  %d / %d" % [ceili(boss.hp),int(boss.max_hp)]
	elif show_lake:
		boss_bar.max_value=lake_boss.max_hp
		boss_bar.value=lake_boss.hp
		boss_title.text="LEVIATÃ DO LAGO ABISSAL  %d / %d" % [ceili(lake_boss.hp),int(lake_boss.max_hp)]
	portal_button.position=Vector2((size.x-250)/2,size.y-172)
	portal_button.size=Vector2(250,40)
	portal_button.visible=active and not modal and nearby_portal()
	portal_button.text="VOLTAR AO MUNDO" if in_purity else "ENTRAR NO REINO DA PUREZA" if boss_defeated else "ENFRENTAR O GUARDIÃO"

func set_overworld_entities_visible(value: bool) -> void:
	for node in [structures,npcs,mel,drops]:
		if is_instance_valid(node):
			node.visible=value
			if node==drops:
				node.process_mode=Node.PROCESS_MODE_INHERIT if value else Node.PROCESS_MODE_DISABLED

func enter_purity(skip_dialogue: bool=false) -> void:
	if in_purity or in_lake_temple:
		return
	ensure_purity_hud()
	return_position=player.position
	set_overworld_entities_visible(false)
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
	lake_boss=null
	player.position=Vector2(10*32,35*32-2)
	player.velocity=Vector2.ZERO
	player.set_water_state(false)
	player.max_fall_speed=0
	player.set_world_bounds(5.0*32.0,37.0*32.0,0.0,float(World.HEIGHT*32))
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

func enter_purity_realm() -> void:
	if in_purity or not boss_defeated:
		return
	ensure_purity_hud()
	return_position=player.position
	set_overworld_entities_visible(false)
	overworld=world
	remove_child(overworld)
	world=World.new()
	add_child(world)
	world.generate_purity_realm(overworld.world_seed)
	world.modulate=Color("dbefff")
	world.camera=player.camera
	for mob in enemies.get_children():
		enemies.remove_child(mob)
		mob.queue_free()
	var spawn_x=12
	player.position=Vector2(spawn_x*32,world.surfaces[spawn_x]*32-2)
	player.velocity=Vector2.ZERO
	player.max_fall_speed=0
	player.set_world_bounds(0.0,float(world.world_width()*32),0.0,float(World.HEIGHT*32))
	player.camera.reset_smoothing()
	in_purity=true
	in_purity_realm=true
	sky.purity=true
	mining_held=false
	progress=0
	status.text="✦ REINO DA PUREZA · Minério das Almas existe apenas nas profundezas deste reino."
	message_time=6
	update_purity_hud()

func enter_purity_realm_from_arena() -> void:
	if not boss_defeated:
		return
	leave_purity()
	call_deferred("enter_purity_realm")


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
	if str(entry.speaker)=="GUARDIÃO DA PUREZA":
		var guardian_portrait=TextureRect.new()
		guardian_portrait.texture=load("res://assets/boss/purity_guardian_v2.svg")
		guardian_portrait.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
		guardian_portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		guardian_portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		guardian_portrait.custom_minimum_size=Vector2(110,110) if mobile_dialogue else Vector2(138,138)
		guardian_portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE
		box.add_child(guardian_portrait)
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
	set_overworld_entities_visible(true)
	player.position=return_position
	player.velocity=Vector2.ZERO
	player.max_fall_speed=0
	player.set_world_bounds(0.0,float(world.world_width()*32),0.0,float(World.HEIGHT*32))
	player.camera.reset_smoothing()
	in_purity=false
	in_purity_realm=false
	sky.purity=false
	resume()
	update_purity_hud()
	save_world()

func on_player_died() -> void:
	var death_position=player.position
	var death_scope=current_death_scope()
	if not player.creative:
		var lost:Dictionary={}
		for raw_id in player.inventory.keys():
			var item_id=int(raw_id)
			var amount=int(player.inventory.get(raw_id,0))
			if amount>0:
				lost[item_id]=amount
		player.inventory.clear()
		hotbar=[0,0,0,0,0,0,0,0,0]
		selected=0
		spawn_death_backpack(lost,death_position,death_scope)

	if in_lake_temple and is_instance_valid(lake_arena):
		# Do not throw the player out of the boss room on death. Player.respawn()
		# uses this position after the signal returns, so the retry happens inside.
		player.spawn_position=lake_arena.spawn_position
		player.air=player.max_air
		player.set_water_state(false,false)
		call_deferred("_finish_lake_respawn")
		if is_instance_valid(lake_boss):
			# Death only resets the encounter position/state. Boss HP is preserved.
			lake_boss.position=lake_arena.boss_position
			lake_boss.state="recover"
			lake_boss.timer=1.25
			lake_boss.orbs.clear()
			lake_boss.wave_hit=true
		status.text="VOCÊ CAIU · recupere sua mochila e tente o Leviatã novamente." if not lake_boss_defeated else "VOCÊ CAIU · sua mochila continua dentro do templo."
		message_time=4
		refresh_hud()
		save_world()
		return

	if in_structure!="":
		player.spawn_position=Vector2(640,570)
		status.text="VOCÊ CAIU · sua mochila ficou onde você morreu."
		message_time=4
		refresh_hud()
		return

	player.spawn_position=Vector2(12*32+16,35*32-2)
	if in_purity:
		call_deferred("leave_purity")
	status.text="VOCÊ CAIU · volte ao local da morte para recuperar sua mochila."
	message_time=4
	refresh_hud()

func _finish_lake_respawn() -> void:
	if not in_lake_temple or not is_instance_valid(player) or not is_instance_valid(lake_arena):
		return
	player.position=lake_arena.spawn_position
	player.velocity=Vector2.ZERO
	player.max_fall_speed=0.0
	player.air=player.max_air
	player.set_water_state(false,false)
	player.camera.reset_smoothing()

func on_boss_defeated() -> void:
	boss_defeated=true
	boss=null
	player.inventory[12]=player.inventory.get(12,0)+1
	player.hp=player.max_hp
	clear_menu("A Pureza foi libertada","victory")
	menu_box.add_child(label("O Guardião caiu. O verdadeiro Reino da Pureza foi desbloqueado.",18))
	var realm_hint=label("Lá você encontrará o Minério das Almas — ele não existe no mundo normal.",13)
	realm_hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	menu_box.add_child(realm_hint)
	menu_box.add_child(button("ATRAVESSAR PARA O REINO",enter_purity_realm_from_arena))
	menu_box.add_child(button("VOLTAR AO MUNDO",leave_purity))
	boss_panel.hide()
	save_world()

func _exit_tree() -> void:
	if is_instance_valid(overworld) and not overworld.is_inside_tree():
		overworld.free()
