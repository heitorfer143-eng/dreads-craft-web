extends SceneTree

var failures := 0

func _initialize() -> void:
	ProjectSettings.set_setting("application/config/use_custom_user_dir",true)
	ProjectSettings.set_setting("application/config/custom_user_dir_name","DreadsCraftLakeTests")
	call_deferred("run")

func check(value:bool,message:String) -> void:
	if not value:
		failures+=1
		push_error(message)

func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_world(false,42019)
	await process_frame
	game.resume()

	var sig_a=game.world.lake_signature()
	var center_a=game.world.lake_center_x
	var width_a=game.world.lake_width
	var depth_a=game.world.lake_depth
	var water_y=game.world.lake_water_y
	check(center_a>=120 and center_a<=150,"Lake center range")
	check(width_a>=20 and width_a<=28,"Lake width range")
	check(depth_a>=7 and depth_a<=11,"Lake depth range")
	check(game.world.is_lake_zone(center_a),"Lake center belongs to lake")
	check(game.world.lake_water_y>game.world.surfaces[game.world.lake_start_x-1],"Water stays below left bank")
	check(game.world.lake_water_y>game.world.surfaces[game.world.lake_end_x+1],"Water stays below right bank")
	check(game.world.is_near_lake_temple(game.world.lake_temple_position()),"Temple entrance is at lake floor")
	game.device_controls.set_mobile(true)
	game.layout()
	check(game.action_box.visible,"Mobile top action buttons stay visible")
	check(game.mode_frame.visible,"Mobile survival/creative badge stays visible")
	game.device_controls.set_mobile(false)
	game.layout()

	game.world.generate(42019)
	check(game.world.lake_signature()==sig_a,"Same seed keeps identical lake")
	game.world.generate(42020)
	check(game.world.lake_signature()!=sig_a,"Different seed changes lake")
	game.world.generate(42019)

	game.resume()
	game.player.position=game.world.lake_temple_position()
	await physics_frame
	check(game.interact_nearby(),"Temple can be entered explicitly")
	check(game.in_lake_temple,"Entered submerged temple")
	check(is_instance_valid(game.lake_boss),"Leviathan spawns only inside temple")
	check(game.lake_boss.max_hp==1400.0,"Leviathan HP")
	check(game.lake_arena.boss_position.y>=640.0,"Leviathan is positioned deeper in the lake")
	check(game.player.max_air==8.0,"Player has underwater air capacity")
	game.player.set_water_state(true,true)
	var air_before=game.player.air
	game.player._update_breath(1.25)
	check(game.player.air<air_before,"Air decreases while head is submerged")
	game.player.set_water_state(false,false)
	game.player._update_breath(1.0)
	check(game.player.air>0.0,"Air recovers out of water")
	check(not bool(game.forms_unlocked.get("fox",false)),"Fox form starts locked")
	game.lake_boss.hit(701.0)
	check(game.lake_boss.phase_two(),"Phase two starts at 50 percent")
	game.lake_boss.hit(9999.0)
	await process_frame
	check(game.lake_boss_defeated,"Leviathan defeat persists in state")
	check(int(game.player.inventory.get(27,0))==1,"Unique Abyssal Heart reward")
	check(bool(game.forms_unlocked.get("fox",false)),"Leviathan unlocks Fox form")
	game.apply_form("fox")
	check(game.current_form=="fox","Fox form can be selected after unlock")
	check(game.player.current_form=="fox","Player sprite state switches to Fox")

	print("LAKE_TEST seed=42019 center=",center_a," width=",width_a," depth=",depth_a," water_y=",water_y," signature=",sig_a)
	print("PASS abyssal lake seed, submerged temple, leviathan phase 2 and reward" if failures==0 else "FAIL lake tests="+str(failures))
	game.queue_free()
	await process_frame
	quit(0 if failures==0 else 1)
