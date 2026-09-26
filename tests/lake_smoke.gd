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
	check(width_a>=44 and width_a<=52,"Lake is substantially wider")
	check(depth_a>=14 and depth_a<=18,"Lake is substantially deeper")
	check(game.world.is_lake_zone(center_a),"Lake center belongs to lake")
	check(game.world.lake_water_y>game.world.surfaces[game.world.lake_start_x-1],"Water stays below left bank")
	check(game.world.lake_water_y>game.world.surfaces[game.world.lake_end_x+1],"Water stays below right bank")
	check(game.world.lake_water_y>=game.world.surfaces[game.world.lake_start_x-1]+2,"Water surface leaves visible bank/sky separation")
	var restore_center=game.world.lake_center_x
	game.world.restore_lake_layout(restore_center,24,9)
	check(game.world.lake_width>=44 and game.world.lake_depth>=14,"Old narrow lake saves migrate to current lake scale")
	game.world.generate(42019)
	check(game.world.is_near_lake_temple(game.world.lake_temple_position()),"Temple entrance is at lake floor")
	var temple_floor_y=float(game.world.surfaces[game.world.lake_center_x]*game.world.TILE)
	check(absf(game.world.lake_temple_position().y-temple_floor_y)<0.1,"Submerged temple bottom is anchored to lake bed")
	check(game.world.LAKE_TEMPLE_DOOR_SIZE.y>=96.0 and game.world.LAKE_TEMPLE_DOOR_SIZE.y<game.world.LAKE_TEMPLE_SIZE.y*0.75,"Temple door is important but proportionate")
	check(game.world.decor_scale_for("bench")>game.world.decor_scale_for("sign"),"Bench is not rendered smaller than signage")
	check(game.world.decor_scale_for("well")>game.world.decor_scale_for("small_crate"),"Large structural props stay larger than minor props")
	check(game.world.decor_scale_for("tree")>=1.8,"Trees render at large environmental scale")
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
	check(game.lake_arena.arena_size.x>=1600.0 and game.lake_arena.arena_size.y>=900.0,"Boss arena is expanded")
	check(game.lake_arena.floor_y-game.lake_arena.water_top>=300.0,"Boss arena has a deep underwater band")
	check(game.lake_arena.boss_position.y>=820.0,"Leviathan is positioned deeper in the lake")
	check(game.lake_boss.arena_size==game.lake_arena.arena_size,"Leviathan attack bounds match expanded arena")
	check(game.player.max_air>=18.0,"Player has enough underwater air for a real boss attempt")
	var spike_tex=game.player.sprite.sprite_frames.get_frame_texture("idle",0)
	check(spike_tex!=null and spike_tex.get_size().y*game.player.sprite.scale.y<=70.0,"Spike visual size stays normalized")
	game.player.set_water_state(true,true)
	var air_before=game.player.air
	game.player._update_breath(1.25)
	check(game.player.air<air_before,"Air decreases while head is submerged")
	game.player.set_water_state(false,false)
	game.player._update_breath(1.0)
	check(game.player.air>0.0,"Air recovers out of water")
	check(not bool(game.forms_unlocked.get("fox",false)),"Fox form starts locked")
	var boss_hp_before_orb=game.lake_boss.hp
	var soul_projectile=load("res://scripts/soul_projectile.gd").new()
	soul_projectile.setup(Vector2.RIGHT,game.world,game.enemies,game)
	soul_projectile.position=game.lake_boss.position-Vector2(100,0)
	game.add_child(soul_projectile)
	await process_frame
	soul_projectile._process(0.08)
	check(game.lake_boss.hp<boss_hp_before_orb,"Soul Orb damages Leviathan inside submerged arena")
	game.player.inventory[14]=2
	game.player.inventory[3]=9
	var boss_hp_before_death=game.lake_boss.hp
	var heart_before_death=int(game.player.inventory.get(27,0))
	game.player.hurt_time=0.0
	game.player.take_damage(9999.0)
	await process_frame
	await process_frame
	check(game.in_lake_temple,"Death does not eject player from Leviathan arena")
	check(is_instance_valid(game.lake_boss),"Leviathan remains alive after player death")
	check(game.lake_boss.hp>0.0 and game.lake_boss.hp<=boss_hp_before_death+0.1,"Leviathan stays alive and is never healed/reset by player death")
	check(not game.lake_boss_defeated,"Player death never marks Leviathan defeated")
	check(int(game.player.inventory.get(27,0))==heart_before_death,"Player death never grants Leviathan reward")
	check(game.player.position.distance_to(game.lake_arena.spawn_position)<36.0,"Lake death respawns inside arena")
	check(game.player.inventory.is_empty(),"Death removes carried inventory")
	check(game.death_bags.get_child_count()==1,"Death creates one recoverable backpack")
	var bag=game.death_bags.get_child(0)
	game.player.position=bag.position
	bag.try_collect()
	await process_frame
	check(int(game.player.inventory.get(14,0))==2 and int(game.player.inventory.get(3,0))==9,"Death backpack restores all items")
	check(game.death_bags.get_child_count()==0,"Backpack disappears only after collection")
	game.ensure_lake_boss()
	game.lake_boss.hit(701.0)
	check(game.lake_boss.phase_two(),"Phase two starts at 50 percent")
	game.player.hp=37.0
	game.player.air=0.1
	game.player.set_water_state(true,true)
	game.lake_boss.hit(9999.0)
	await process_frame
	check(game.lake_boss_defeated,"Leviathan defeat persists in state")
	check(game.in_lake_temple,"Defeating Leviathan does not automatically exit arena")
	check(game.player.hp==game.player.max_hp,"Leviathan victory fully heals player")
	check(game.player.air==game.player.max_air and not game.player.submerged,"Victory clears drowning state")
	check(int(game.player.inventory.get(27,0))==1,"Unique Abyssal Heart reward")
	var diamond_after_victory=int(game.player.inventory.get(14,0))
	var soul_after_victory=int(game.player.inventory.get(25,0))
	var heart_after_victory=int(game.player.inventory.get(27,0))
	game.on_lake_boss_defeated()
	check(int(game.player.inventory.get(14,0))==diamond_after_victory and int(game.player.inventory.get(25,0))==soul_after_victory and int(game.player.inventory.get(27,0))==heart_after_victory,"Leviathan reward cannot duplicate")
	check(bool(game.forms_unlocked.get("fox",false)),"Leviathan unlocks Fox form")
	game.apply_form("fox")
	check(game.current_form=="fox","Fox form can be selected after unlock")
	check(game.player.current_form=="fox","Player sprite state switches to Fox")

	print("LAKE_TEST seed=42019 center=",center_a," width=",width_a," depth=",depth_a," water_y=",water_y," signature=",sig_a)
	print("PASS abyssal lake seed, submerged temple, leviathan phase 2 and reward" if failures==0 else "FAIL lake tests="+str(failures))
	game.queue_free()
	await process_frame
	quit(0 if failures==0 else 1)
