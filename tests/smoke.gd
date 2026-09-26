extends SceneTree

func _initialize() -> void:
	ProjectSettings.set_setting("application/config/use_custom_user_dir",true)
	ProjectSettings.set_setting("application/config/custom_user_dir_name","DreadsCraftTests")
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		push_error(message)
		quit(1)
		assert(value,message)

func run() -> void:
	var scene=load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var accounts=load("res://scripts/account_store.gd")
	var saves=load("res://scripts/save_game.gd")
	var smoke_user="smoke_"+str(Time.get_ticks_usec())
	var smoke_password="TestPass987!"
	var created=accounts.create_account(smoke_user,smoke_password)
	print("ACCOUNT_CREATE_RESULT=",created)
	check(bool(created.get("ok",false)),"Create local account: "+str(created))
	check(not bool(accounts.authenticate(smoke_user,"wrong-password").get("ok",false)),"Reject wrong password")
	var login_result=accounts.authenticate(smoke_user,smoke_password)
	print("ACCOUNT_LOGIN_RESULT=",login_result)
	check(bool(login_result.get("ok",false)),"Login local account: "+str(login_result))
	saves.set_account(smoke_user)
	check(is_instance_valid(scene.login_root),"Login screen exists before entering game")
	scene.start_world(false,42019)
	await physics_frame
	await physics_frame
	# The starter Mel quest intentionally opens a modal dialogue and pauses the
	# player; close it so physics-specific smoke checks exercise live gameplay.
	scene.resume()
	await physics_frame
	check(scene.world.cells.size()==96,"World height")
	check(scene.world.world_width()==640,"Finite world uses configured width")
	var finite_width=scene.world.world_width()
	scene.world.ensure_generated_to(finite_width+200)
	check(scene.world.world_width()==finite_width,"World never grows past its finite boundary")
	check(scene.world.has_method("draw_village_decor"),"Village decoration pass exists")
	check(ResourceLoader.exists("res://assets/decor/decor_atlas.png"),"Decoration atlas from supplied art exists")
	check(load("res://assets/decor/decor_atlas.png")!=null,"Decoration atlas imports correctly")
	check(scene.world.has_method("_draw_decor_sprite"),"World decorations render from sprite atlas")
	var desert_x=scene.world.desert_center_cell()
	check(scene.world.biome_at(desert_x)=="desert","Generated world contains a real desert region")
	check(scene.world.get_cell(Vector2i(desert_x,scene.world.surfaces[desert_x]))==29,"Desert surface is sand")
	check(scene.world.get_cell(Vector2i(desert_x,scene.world.surfaces[desert_x]+1))==30,"Desert subsurface is sandstone")
	var desert_columns=0
	for x in range(scene.world.desert_start_x,scene.world.desert_end_x+1):
		if scene.world.is_desert_biome(x):
			desert_columns+=1
	check(desert_columns>=120,"Desert is a large biome instead of a tiny patch")
	var lake_sig_a=scene.world.lake_signature()
	var lake_center_a=scene.world.lake_center_x
	check(scene.world.is_lake_zone(lake_center_a),"Seeded lake center is inside lake")
	check(scene.world.lake_depth>=7 and scene.world.lake_depth<=11,"Seeded lake depth range")
	check(scene.world.lake_width>=20 and scene.world.lake_width<=28,"Seeded lake width range")
	check(scene.quest_states.size()>=6,"Six quest states exist")
	check(scene.quest_states.has(scene.QUEST_ABYSS),"Abyss hunt quest exists")
	check(ResourceLoader.exists("res://assets/ui/new_world_icon.svg"),"Lobby new-world icon exists")
	check(ResourceLoader.exists("res://assets/interiors/blacksmith.png"),"Remodeled blacksmith interior exists")
	check(ResourceLoader.exists("res://assets/interiors/market.png"),"Remodeled market interior exists")
	check(ResourceLoader.exists("res://assets/interiors/chapel.png"),"Remodeled chapel interior file exists")
	check(ResourceLoader.exists("res://assets/boss/lake_leviathan.svg"),"Lake Leviathan art exists")
	check(ResourceLoader.exists("res://scripts/lake_boss.gd"),"Lake Leviathan script exists")
	check(load("res://assets/interiors/blacksmith.png")!=null,"Blacksmith PNG imports correctly")
	check(load("res://assets/interiors/market.png")!=null,"Market PNG imports correctly")
	check(load("res://assets/interiors/chapel.png")!=null,"Chapel PNG imports correctly")
	var interior_class=load("res://scripts/interior.gd")
	for interior_kind in ["blacksmith","market","chapel"]:
		var room=interior_class.new()
		room.configure(interior_kind,"Smoke Test")
		root.add_child(room)
		await process_frame
		check(is_instance_valid(room.background),"Interior background node exists: "+interior_kind)
		check(room.background.texture!=null,"Interior has a usable texture or fallback: "+interior_kind)
		room.queue_free()
		await process_frame
	var tree_cell=Vector2i(-1,-1)
	for y in range(scene.world.cells.size()):
		for x in range(scene.world.cells[y].size()):
			if int(scene.world.cells[y][x])==4:
				tree_cell=Vector2i(x,y)
				break
		if tree_cell.x>=0:
			break
	check(tree_cell.x>=0 and not scene.world.is_solid(tree_cell),"Tree trunks are pass-through but remain world cells")
	check(scene.player.sprite.sprite_frames.has_animation("walk"),"Player animations")
	# Fox transformation keeps the existing player state machine, but now has authored multi-frame motion.
	scene.player.set_form("fox")
	check(load("res://assets/player/forms/fox_animation_atlas.png")!=null,"Fox atlas PNG loads cleanly")
	check(scene.player.sprite.sprite_frames.has_animation("idle"),"Fox idle animation exists")
	check(ResourceLoader.exists("res://assets/player/forms/fox_animation_atlas.png"),"Approved fox atlas exists")
	check(load("res://assets/player/forms/fox_animation_atlas.png")!=null,"Approved fox atlas imports correctly")
	check(scene.player.sprite.sprite_frames.get_frame_count("idle")==4,"Fox idle uses four approved-sheet frames")
	check(scene.player.sprite.sprite_frames.get_frame_count("walk")==6,"Fox walk/run uses six approved-sheet frames")
	check(scene.player.sprite.sprite_frames.get_frame_count("attack")==2,"Fox attack uses two approved-sheet frames")
	check(scene.player.sprite.sprite_frames.get_frame_texture("jump",0)!=null,"Fox jump frame loads")
	scene.player.set_form("spike")
	check(scene.mel.base_scale<0.7,"Mel uses compact in-world scale")
	var market_found=false
	for building in scene.structures.get_children():
		if str(building.kind)=="market":
			market_found=true
			check(str(building.texture_path).ends_with("market.png"),"Market uses generated PNG")
	check(market_found,"Market structure spawned")
	var sprite_factory=load("res://scripts/sprites.gd")
	var new_slime=sprite_factory.make("dark_slime")
	var new_warden=sprite_factory.make("undead_knight")
	check(new_slime.sprite_frames.has_animation("death") and new_warden.sprite_frames.has_animation("attack"),"Remodeled mob sheets load")
	new_slime.free()
	new_warden.free()
	var items=load("res://scripts/items.gd")
	check(items.drop_for_block(3,{})==0,"Stone broken by hand produces no drop")
	check(items.drop_for_block(3,{13:1})==3,"Stone with wooden pickaxe drops stone")
	check(items.drop_for_block(7,{13:1})==0 and items.drop_for_block(7,{17:1})==7,"Iron needs stone-tier pickaxe")
	check(items.drop_for_block(14,{17:1})==0 and items.drop_for_block(14,{18:1})==14,"Diamond needs iron-tier pickaxe")
	check(items.drop_for_block(15,{18:1})==0 and items.drop_for_block(15,{19:1})==15,"Avarita needs diamond-tier pickaxe")
	var inventory={4:1}
	check(items.craft(inventory,items.RECIPES[0],false,false),"Manual planks")
	check(items.craft(inventory,items.RECIPES[1],false,false),"Manual table")
	check(inventory.get(9)==1,"Crafted table")
	check(not items.craft(inventory,items.RECIPES[2],false,false),"Equipment needs table")
	var stone_before=int(scene.player.inventory.get(3,0))
	var drop_count_before=scene.drops.get_child_count()
	scene.spawn_ground_drop(3,2,scene.player.position+Vector2(76,-8))
	check(scene.drops.get_child_count()==drop_count_before+1,"Drop appears visibly in world")
	for frame in 150:
		await physics_frame
	check(int(scene.player.inventory.get(3,0))==stone_before+2,"Nearby drop is collected into inventory")
	check(scene.drops.get_child_count()==drop_count_before,"Drop disappears only after collection")
	# Player can settle onto native collision and turn independently from mouse.
	var ground_x=72
	scene.player.position=Vector2(ground_x*32+16,scene.world.surfaces[ground_x]*32-64)
	scene.player.velocity=Vector2.ZERO
	for frame in 75:
		await physics_frame
	check(scene.player.is_on_floor(),"Ground collision at known terrain column")
	Input.action_press("left")
	for frame in 10:
		await physics_frame
	check(scene.player.face==-1,"Face left")
	Input.action_release("left")
	Input.action_press("right")
	for frame in 10:
		await physics_frame
	check(scene.player.face==1,"Face right")
	Input.action_release("right")
	Input.action_press("jump")
	await physics_frame
	await physics_frame
	check(scene.player.velocity.y<0,"Jump")
	Input.action_release("jump")
	# Placement uses an unprotected outdoor area; the village intentionally blocks building.
	var build_x=100
	scene.player.position=Vector2((build_x-2)*32+16,scene.world.surfaces[build_x-2]*32-2)
	scene.player.velocity=Vector2.ZERO
	scene.player.inventory[2]=3
	scene.selected=2
	var dirt_target=Vector2i(build_x,scene.world.surfaces[build_x]-2)
	scene.target=dirt_target
	scene.world.set_cell(dirt_target,0)
	var count=int(scene.player.inventory.get(2,0))
	check(scene.place_block(),"Place empty target outside protected village")
	check(scene.world.get_cell(dirt_target)==2,"Target changed")
	check(int(scene.player.inventory.get(2,0))==count-1,"Placement consumed item")
	check(not scene.place_block(),"Cannot place on solid target")
	scene.player.inventory[3]=2
	scene.selected=3
	var stone_target=Vector2i(build_x+1,scene.world.surfaces[build_x+1]-2)
	scene.target=stone_target
	scene.world.set_cell(stone_target,0)
	check(scene.place_block(),"Stone block can be placed")
	check(scene.world.get_cell(stone_target)==3,"Placed stone uses stone tile id")
	scene.player.inventory[28]=1
	scene.selected=28
	var chest_target=Vector2i(build_x+2,scene.world.surfaces[build_x+2]-2)
	scene.target=chest_target
	scene.world.set_cell(chest_target,0)
	check(scene.place_block(),"Chest can be placed")
	check(scene.world.get_cell(chest_target)==28,"Chest uses storage block id")
	check(scene.has_method("show_chest") and scene.has_method("spill_chest"),"Chest storage handlers exist")
	check(scene.has_method("apply_online_drop") and scene.has_method("resolve_online_drop_pickup"),"Multiplayer shared drop handlers exist")
	check(is_instance_valid(scene.chat_panel) and is_instance_valid(scene.chat_input),"Multiplayer chat UI exists")
	scene.show_inventory()
	check(scene.modal,"Inventory opens")
	scene.show_craft()
	check(scene.menu_box.get_child_count()>=3,"Craft menu builds")
	var craft_root=scene.menu_box.get_child(scene.menu_box.get_child_count()-1)
	check(craft_root is HBoxContainer and craft_root.get_child_count()>=2,"Craft menu layout has sidebar and recipes")
	scene.resume()
	scene.player.position=Vector2(34*32+16,scene.world.surfaces[34]*32-2)
	scene.player.velocity=Vector2.ZERO
	var safe_enemy_count=scene.enemies.get_child_count()
	scene.spawn_mob()
	await physics_frame
	check(scene.enemies.get_child_count()==safe_enemy_count,"Village safe zone blocks new hostile spawn")
	scene.player.position=Vector2(100*32,scene.world.surfaces[100]*32-2)
	var outside_enemy_count=scene.enemies.get_child_count()
	scene.spawn_mob()
	await physics_frame
	check(scene.enemies.get_child_count()==outside_enemy_count+1,"Mob spawns outside safe zone")
	var mob=scene.enemies.get_child(scene.enemies.get_child_count()-1)
	var drops_before_mob=scene.drops.get_child_count()
	mob.hit(999)
	check(scene.drops.get_child_count()>=drops_before_mob+2,"Mob defeat creates meat and bone ground drops")
	# A tamed Mel must never consume the generic USE action before a Waystone.
	scene.quest_states[scene.QUEST_MEL]="completed"
	scene.sync_legacy_quest_flags()
	scene.mel.set_tamed(true)
	scene.player.position=Vector2(105*32,scene.world.surfaces[105]*32-2)
	scene.mel.position=scene.player.position+Vector2(16,0)
	scene.player.inventory[24]=1
	scene.selected=24
	scene.use_selected()
	var safe_center=Vector2(34*32+16,35*32-2)
	check(scene.player.position.distance_to(safe_center)<2,"Waystone works while Mel is tamed")
	# Save/account roundtrip preserves inventory and modified blocks.
	var saved_x=scene.player.position.x
	scene.player.inventory[29]=7
	var modified_cell=Vector2i(scene.world.desert_center_cell(),scene.world.surfaces[scene.world.desert_center_cell()]-2)
	scene.world.set_cell(modified_cell,31)
	check(scene.save_world(),"Save write")
	accounts.logout()
	saves.clear_account()
	check(bool(accounts.authenticate(smoke_user,smoke_password).get("ok",false)),"Login after logout")
	saves.set_account(smoke_user)
	scene.load_world()
	check(absf(scene.player.position.x-saved_x)<1,"Save position roundtrip")
	check(int(scene.player.inventory.get(29,0))==7,"Inventory survives logout/login")
	check(scene.world.get_cell(modified_cell)==31,"Modified world survives reload")
	var world_min_x=scene.player.world_min_x
	var world_max_x=scene.player.world_max_x
	var world_min_y=scene.player.world_min_y
	var world_max_y=scene.player.world_max_y
	scene.player.position=Vector2(world_min_x-200,600)
	scene.player.velocity=Vector2(-2000,0)
	await physics_frame
	check(scene.player.position.x>=world_min_x+12.0,"Player cannot cross left boundary")
	scene.player.position=Vector2(world_max_x+200,600)
	scene.player.velocity=Vector2(2000,0)
	await physics_frame
	check(scene.player.position.x<=world_max_x-12.0,"Player cannot cross right boundary")
	scene.player.position=Vector2(600,world_min_y-200)
	scene.player.velocity=Vector2(0,-2000)
	await physics_frame
	check(scene.player.position.y>=world_min_y+44.0,"Player cannot cross top boundary")
	scene.player.position=Vector2(600,world_max_y+200)
	scene.player.velocity=Vector2(0,2000)
	await physics_frame
	check(scene.player.position.y<=world_max_y-4.0,"Player cannot cross bottom boundary")
	check(scene.player.camera.limit_left==int(world_min_x) and scene.player.camera.limit_right==int(world_max_x),"Camera horizontal limits match world bounds")
	check(scene.player.camera.limit_top==int(world_min_y) and scene.player.camera.limit_bottom==int(world_max_y),"Camera vertical limits match world bounds")
	var boundary_mob=load("res://scripts/mob.gd").new()
	boundary_mob.kind="dark_slime"
	boundary_mob.player=scene.player
	boundary_mob.set_world_bounds(world_min_x,world_max_x,world_min_y,world_max_y)
	boundary_mob.position=Vector2(world_max_x-17,scene.world.surfaces[scene.world.world_width()-2]*32-2)
	boundary_mob.knockback=Vector2(1200,0)
	scene.enemies.add_child(boundary_mob)
	await physics_frame
	await physics_frame
	check(boundary_mob.position.x<=world_max_x-16.0,"Enemy knockback cannot cross right boundary")
	boundary_mob.position.y=world_min_y-100
	await physics_frame
	check(boundary_mob.position.y>=world_min_y+8.0,"Enemy cannot cross top boundary")
	boundary_mob.queue_free()
	var first_npc=scene.npcs.get_child(0)
	first_npc.position=Vector2(world_max_x+400,world_min_y-300)
	first_npc._process(0.0)
	check(first_npc.position.x<=world_max_x-18.0 and first_npc.position.y>=world_min_y+first_npc.visual_height,"NPC respects world bounds")
	scene.mel.position=Vector2(world_min_x-400,world_max_y+300)
	await physics_frame
	check(scene.mel.position.x>=world_min_x+12.0 and scene.mel.position.y<=world_max_y-2.0,"Mel respects world bounds")
	var history=load("res://scripts/player_history.gd")
	check(history.record(smoke_user,"join","A7K2P","Smoke Realm","Lucas","remote-1")==OK,"History records player join")
	check(history.record(smoke_user,"leave","A7K2P","Smoke Realm","Lucas","remote-1")==OK,"History records player leave")
	var persisted_history=history.list_for(smoke_user)
	check(persisted_history.size()>=2,"Player history persists to disk")
	check(str(persisted_history[persisted_history.size()-1].get("event",""))=="leave","Player leave survives history reload")
	var remote_class=load("res://scripts/remote_player.gd")
	var remote=remote_class.new()
	remote.setup("Lucas",scene.player.position+Vector2(3200,0),1,"idle","world")
	scene.add_child(remote)
	scene.online.remote_players["smoke-remote"]=remote
	scene.multiplayer_active=true
	scene.update_multiplayer_compass()
	check(scene.compass_frame.visible and "→" in scene.compass_label.text,"Compass points right to distant player")
	remote.set_state(scene.player.position+Vector2(-3200,0),1,"idle","world")
	scene.update_multiplayer_compass()
	check("←" in scene.compass_label.text,"Compass updates when player moves left")
	remote.set_state(scene.player.position+Vector2(0,-3200),1,"idle","world")
	scene.update_multiplayer_compass()
	check("↑" in scene.compass_label.text,"Compass updates vertically and works at long distance")
	scene.online.remote_players.erase("smoke-remote")
	remote.queue_free()
	scene.multiplayer_active=false
	scene.update_multiplayer_compass()
	check(not scene.compass_frame.visible,"Compass is hidden outside multiplayer")
	scene.start_world(true,42019)
	await physics_frame
	Input.action_press("jump")
	for frame in 5:
		await physics_frame
	check(scene.player.velocity.y<0,"Creative flight")
	Input.action_release("jump")
	await physics_frame
	await physics_frame
	check(scene.player.velocity.y==0,"Flight release")
	# v10: seeded veins and multi-touch controls.
	var fingerprint=JSON.stringify(scene.world.cells)
	scene.world.generate(42019)
	check(JSON.stringify(scene.world.cells)==fingerprint,"Seed determinism")
	check(scene.world.lake_signature()==lake_sig_a,"Lake geometry is deterministic for same seed")
	scene.world.generate(42020)
	check(scene.world.lake_signature()!=lake_sig_a,"Different seed changes lake geometry")
	scene.world.generate(42019)
	check(scene.world.is_near_lake_temple(scene.world.lake_temple_position()),"Submerged temple entrance exists")
	check(not is_instance_valid(scene.lake_boss),"Leviathan never spawns in overworld lake")
	var lake_boss_class=load("res://scripts/lake_leviathan.gd")
	var test_boss=lake_boss_class.new()
	check(test_boss.max_hp==1400,"Abyssal Leviathan has 1400 HP")
	test_boss.free()
	var ores={6:0,7:0}
	var paired=0
	for y in range(1,95):
		for x in range(1,319):
			var cell=Vector2i(x,y)
			var id=scene.world.get_cell(cell)
			if id not in [6,7]:
				continue
			ores[id]+=1
			var connected=false
			for direction in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
				var neighbor=scene.world.get_cell(cell+direction)
				check(neighbor not in [6,7] or neighbor==id,"Different ores must have stone buffer")
				if neighbor==id:
					connected=true
			if connected:
				paired+=1
	check(ores[6]>200 and ores[7]>100,"Both ore types generated")
	check(float(paired)/(ores[6]+ores[7])>.95,"Ores form connected veins")
	var controls=scene.device_controls
	controls.set_mobile(true)
	var finger=InputEventScreenTouch.new()
	finger.index=1
	finger.position=controls.regions.left.get_center()
	finger.pressed=true
	controls._input(finger)
	check(Input.is_action_pressed("left"),"Touch movement")
	var miner=InputEventScreenTouch.new()
	miner.index=2
	miner.position=controls.regions.mine.get_center()
	miner.pressed=true
	controls._input(miner)
	check(scene.mining_held and Input.is_action_pressed("left"),"Simultaneous movement and mining")
	miner.pressed=false
	controls._input(miner)
	check(not scene.mining_held and Input.is_action_pressed("left"),"Independent touch release")
	scene.show_pause()
	check(not Input.is_action_pressed("left") and controls.fingers.is_empty(),"Pause releases touch controls")
	scene.resume()
	controls.set_mobile(false)
	check(not controls.mobile,"PC controls")
	await process_frame
	check(scene.hp_bar.size.y<=12 and scene.food_bar.size.y<=12,"HUD meters respect dimensions")
	print("PASS v10: ore counts ",ores,"; connected ratio ",float(paired)/(ores[6]+ores[7]),"; multitouch, pause reset, PC mode, HUD dimensions")
	print("PASS: accounts, mining drops, pickup magnet, finite bounds, desert, saves, sprites and gameplay systems")
	scene.queue_free()
	await process_frame
	quit()
