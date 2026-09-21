extends SceneTree

var failures=0
func _initialize() -> void:
	ProjectSettings.set_setting("application/config/use_custom_user_dir",true)
	ProjectSettings.set_setting("application/config/custom_user_dir_name","DreadsCraftTests")
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures+=1
		push_error(message)

func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var items=load("res://scripts/items.gd")
	var saves=load("res://scripts/save_game.gd")
	game.start_world(false,42019)
	var counts={6:0,7:0,14:0,15:0}
	for row in game.world.cells:
		for id in counts:
			counts[id]+=row.count(id)
	check(counts[14]>=18 and counts[15]>=1 and counts[15]<counts[14] and counts[14]<counts[7],"Ore progression and rarity")
	for recipe in items.RECIPES:
		check(not recipe.cost.has(15) or recipe.id==16,"Avarita exclusive to portal")
		var inventory=recipe.cost.duplicate()
		check(items.craft(inventory,recipe,false,true),"Craft recipe "+recipe.name)
		check(inventory[recipe.id]>=1,"Recipe output "+recipe.name)
	var recipe=items.RECIPES[-1]
	check(recipe.cost=={14:9,15:1},"Exact portal cost")
	check(not items.craft({14:8,15:1},recipe,false,true),"Cannot craft without nine diamonds")
	check(not items.craft({14:9,15:1},recipe,false,false),"Portal requires table")
	check(not items.can_mine(14,{17:1}) and items.can_mine(14,{18:1}),"Diamond requires iron pick")
	check(not items.can_mine(15,{18:1}) and items.can_mine(15,{19:1}),"Avarita requires diamond pick")
	game.player.inventory[16]=1
	game.selected=16
	game.target=Vector2i(14,34)
	check(game.place_block(),"Portal placement")
	check(game.player.inventory[16]==0 and not game.world.is_solid(game.target),"Portal consumed and traversable")
	var original=JSON.stringify(game.world.cells)
	var original_position=game.player.position
	game.use_portal()
	check(game.in_purity and game.modal and not game.boss.awakened,"Portal begins dialogue before fight")
	check(JSON.stringify(game.overworld.cells)==original,"World retained")
	var hp=game.boss.hp
	game.boss.hit(100)
	check(game.boss.hp==hp,"Boss invulnerable before dialogue")
	for i in 3:
		game.advance_purity_dialogue()
	check(not game.modal and game.boss.awakened,"Dialogue starts battle")
	game.update_purity_hud()
	check(game.boss_panel.visible and game.boss_bar.max_value==900,"Boss HUD visible")
	game.boss.hit(200)
	game.update_purity_hud()
	check(game.boss_bar.value==700,"Boss HUD follows damage")
	game.boss.state="pillar"
	game.boss.timer=0
	game.boss.warning_x=game.player.position.x
	game.player.hurt_time=0
	game.boss._physics_process(.02)
	check(game.player.hp==84,"Boss attack hits")
	game.player.hurt_time=0
	game.boss.state="pillar"
	game.boss.timer=0
	game.boss.warning_x=game.player.position.x+150
	game.boss._physics_process(.02)
	check(game.player.hp==84,"Boss attack can be dodged")
	check(game.save_world(),"Save in arena")
	game.load_world()
	check(game.in_purity and game.boss.hp==700 and game.boss.awakened,"Arena save roundtrip")
	check(JSON.stringify(game.overworld.cells)==original,"Saved world preserved")
	game.player.hurt_time=0
	game.player.take_damage(999)
	await process_frame
	check(not game.in_purity and game.player.hp==100,"Death returns to world")
	check(JSON.stringify(game.world.cells)==original,"Death retains terrain")
	game.enter_purity(true)
	check(game.boss.hp==900,"Retry resets boss")
	game.player.position=game.boss.position-Vector2(50,0)
	game.device_controls.set_mobile(true)
	game.touch_aim=Vector2(80,0)
	game.selected=22
	game.player.inventory[22]=1
	game.player.attack_time=0
	game.attack()
	check(game.boss.hp==858,"Equipped diamond sword damage")
	game.selected=2
	game.player.attack_time=0
	game.attack()
	check(game.boss.hp==850,"Unequipped swords grant no damage bonus")
	game.boss.hit(9999)
	check(game.boss_defeated and game.player.inventory.get(12,0)==1,"Victory reward")
	game.leave_purity()
	check(game.player.position.distance_to(original_position)<2,"Return location")
	check(JSON.stringify(game.world.cells)==original,"Return preserves portal and terrain")
	game.load_world()
	check(game.boss_defeated,"Victory persists")
	game.enter_purity()
	check(not is_instance_valid(game.boss),"Defeated boss does not respawn")
	game.leave_purity()
	# Legacy saves remain readable without regenerating existing terrain.
	var data=saves.read_save()
	data.version=1
	data.erase("in_purity")
	data.erase("boss_defeated")
	saves.write(data)
	game.load_world()
	check(not game.in_purity and JSON.stringify(game.world.cells)==original,"Legacy save migration")
	print("v11 ores: ",counts)
	print("PASS purity progression, portal, dialogue, combat, death, victory and saves" if failures==0 else "FAILURES: "+str(failures))
	game.queue_free()
	await process_frame
	quit(0 if failures==0 else 1)
