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
	scene.start_world(false,42019)
	await physics_frame
	await physics_frame
	check(scene.world.cells.size()==96,"World height")
	check(scene.quest_states.size()>=6,"Six quest states exist")
	check(scene.quest_states.has(scene.QUEST_ABYSS),"Abyss hunt quest exists")
	check(ResourceLoader.exists("res://assets/ui/new_world_icon.svg"),"Lobby new-world icon exists")
	check(ResourceLoader.exists("res://assets/interiors/blacksmith.png"),"Remodeled blacksmith interior exists")
	check(ResourceLoader.exists("res://assets/interiors/market.png"),"Remodeled market interior exists")
	check(ResourceLoader.exists("res://assets/interiors/chapel.png"),"Remodeled chapel interior exists")
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
	check(scene.mel.base_scale<0.5,"Mel uses compact in-world scale")
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
	var inventory={4:1}
	check(items.craft(inventory,items.RECIPES[0],false,false),"Manual planks")
	check(items.craft(inventory,items.RECIPES[1],false,false),"Manual table")
	check(inventory.get(9)==1,"Crafted table")
	check(not items.craft(inventory,items.RECIPES[2],false,false),"Equipment needs table")
	# Player can settle onto native collision and turn independently from mouse.
	for frame in 45:
		await physics_frame
	check(scene.player.is_on_floor(),"Ground collision")
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
	# Placement uses target cell and blocks overlap.
	scene.selected=2
	scene.target=Vector2i(15,33)
	scene.world.set_cell(scene.target,0)
	var count=scene.player.inventory[2]
	check(scene.place_block(),"Place empty target")
	check(scene.world.get_cell(scene.target)==2,"Target changed")
	check(scene.player.inventory[2]==count-1,"Placement consumed item")
	check(not scene.place_block(),"Cannot place on solid target")
	scene.show_inventory()
	check(scene.modal,"Inventory opens")
	scene.show_craft()
	check(scene.menu_box.get_child_count()>3,"Craft menu builds")
	scene.resume()
	scene.spawn_mob()
	await physics_frame
	check(scene.enemies.get_child_count()==0,"Village safe zone blocks hostile spawn")
	scene.player.position=Vector2(100*32,scene.world.surfaces[100]*32-2)
	scene.spawn_mob()
	await physics_frame
	check(scene.enemies.get_child_count()==1,"Mob spawns outside safe zone")
	var mob=scene.enemies.get_child(0)
	var food_before=scene.player.inventory.get(10,0)
	mob.hit(999)
	check(scene.player.inventory.get(10,0)==food_before+1,"Mob reward")
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
	# Save roundtrip uses the dedicated DreadsCraftTests data directory.
	check(scene.save_world(),"Save write")
	var saved_x=scene.player.position.x
	scene.load_world()
	check(absf(scene.player.position.x-saved_x)<1,"Save position roundtrip")
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
	print("PASS: native world, sprites, collisions, direction, jump, placement, crafting, menus, mobs, save roundtrip and flight")
	scene.queue_free()
	await process_frame
	quit()
