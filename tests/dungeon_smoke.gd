extends SceneTree

func check(value:bool,message:String) -> void:
	if not value:
		push_error(message)
		quit(1)
		assert(value,message)

func empty_or_passable(world,cell:Vector2i) -> bool:
	return world.get_cell(cell) in [0,16,28]

func connected(world,start:Vector2i,goal:Vector2i) -> bool:
	var queue:Array[Vector2i]=[start]
	var visited:Dictionary={start:true}
	var index=0
	while index<queue.size() and index<6000:
		var cell=queue[index]
		index+=1
		if cell.distance_to(goal)<=2.0:
			return true
		for off in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var next=cell+off
			if next.x<1 or next.x>=world.world_width()-1 or next.y<1 or next.y>=world.HEIGHT-1:
				continue
			if visited.has(next) or not empty_or_passable(world,next):
				continue
			visited[next]=true
			queue.append(next)
	return false

func run() -> void:
	var DungeonSystem=load("res://scripts/dungeon_system.gd")
	var DungeonArt=load("res://scripts/dungeon_art.gd")
	var Items=load("res://scripts/items.gd")
	var World=load("res://scripts/world.gd")
	var world=World.new()
	root.add_child(world)
	world.generate(42019)
	await process_frame

	check(DungeonArt.encoded_data().length()==40260,"Generated dungeon art atlas data is complete")
	check(DungeonArt.atlas()!=null,"Generated dungeon WebP atlas decodes at runtime")
	check(DungeonArt.atlas().get_size()==Vector2(256,256),"Generated dungeon atlas keeps expected dimensions")
	for art_name in ["guardian_idle","guardian_attack1","dungeon_crypt_facade","dungeon_tower_facade","dungeon_desert_facade","dungeon_water_gate","chest_common_closed","chest_rare_open","chest_dungeon_closed","chest_boss_sealed","ancient_sword","resistance_amulet","explorer_boots","map_fragment","crypt_key","dungeon_relic"]:
		check(DungeonArt.texture(art_name)!=null,"Generated dungeon asset exists: "+art_name)

	check(world.dungeons.size()==3,"Exactly three exploration dungeons generate")
	var kinds:Dictionary={}
	for dungeon in world.dungeons:
		kinds[str(dungeon.get("kind",""))]=true
	check(kinds.has("crypt") and kinds.has("tower") and kinds.has("desert_ruin"),"Crypt, ruined tower and desert ruin all generate")
	check(world.dungeon_chests.size()==12,"Each dungeon receives four loot chests")
	check(world.dungeon_secret_cells.size()>0,"Secret rooms have breakable hidden walls")

	var tiers:Dictionary={}
	for entry in world.dungeon_chests:
		var cell:Vector2i=entry.get("cell",Vector2i(-1,-1))
		var tier=str(entry.get("tier",""))
		tiers[tier]=true
		check(world.get_cell(cell)==28,"Dungeon chest is a real world chest block")
	check(tiers.has("common") and tiers.has("rare") and tiers.has("dungeon") and tiers.has("boss"),"All chest tiers generate")
	for dungeon in world.dungeons:
		check(Array(dungeon.get("mob_spawns",[])).size()>=2,"Dungeon contains dedicated enemy encounter positions")
		check(Array(dungeon.get("mob_kinds",[])).size()>=2,"Dungeon defines its own enemy mix")
		check(Vector2i(dungeon.get("entrance",Vector2i(-1,-1))).x>=0,"Dungeon exposes a facade entrance anchor")
	var animation_cell:Vector2i=world.dungeon_chests[0].get("cell",Vector2i(-1,-1))
	world.set_chest_open(animation_cell,true)
	world._process(0.2)
	check(world.chest_open_value(animation_cell)>0.0,"Dungeon chest lid has an open animation")
	check(float(world.chest_burst_time.get(world._cell_key(animation_cell),0.0))>0.0,"Opening generated chest triggers loot burst effect")
	world.set_chest_open(animation_cell,false)

	for raw_key in world.dungeon_secret_cells:
		var parts=str(raw_key).split(",")
		var cell=Vector2i(int(parts[0]),int(parts[1]))
		check(world.get_cell(cell) in [3,30,31],"Secret entrance uses normal breakable masonry")

	var crypt:Dictionary={}
	var desert:Dictionary={}
	for dungeon in world.dungeons:
		if str(dungeon.get("kind",""))=="crypt":
			crypt=dungeon
		elif str(dungeon.get("kind",""))=="desert_ruin":
			desert=dungeon
	check(not crypt.is_empty(),"Crypt metadata exists")
	var crypt_room_x=int(crypt.get("rect",Rect2i()).position.x)+2
	var crypt_entry_x=crypt_room_x-24
	var crypt_entry=Vector2i(crypt_entry_x,world.surfaces[crypt_entry_x]-1)
	check(connected(world,crypt_entry,crypt.get("center",Vector2i.ZERO)),"Crypt entrance connects surface to dungeon rooms")
	var desert_center:Vector2i=desert.get("center",Vector2i.ZERO)
	check(world.is_desert_biome(desert_center.x),"Desert ruin is generated inside desert biome")
	for dungeon in world.dungeons:
		var center:Vector2i=dungeon.get("center",Vector2i.ZERO)
		check(center.x>World.VILLAGE_MAX_X+20,"Dungeons stay away from protected village")

	var loot_a=DungeonSystem.generate_loot(123456,"crypt","dungeon")
	var loot_b=DungeonSystem.generate_loot(123456,"crypt","dungeon")
	check(loot_a==loot_b,"Dungeon loot is deterministic for a world/chest seed")
	check(DungeonSystem.generate_loot(55,"crypt","boss").has(40),"Crypt boss chest always carries Crypt Key")
	check(DungeonSystem.generate_loot(56,"tower","boss").has(38),"Tower boss chest always carries Explorer Boots")
	check(DungeonSystem.generate_loot(57,"desert_ruin","boss").has(37),"Desert boss chest always carries Resistance Amulet")
	var rare_table=DungeonSystem._table_for("crypt","rare")
	check(rare_table.any(func(entry): return int(entry.get("id",0)) in [36,39,40]),"Rare chests use a dedicated rare exploration table")

	for id in [36,37,38,39,40,41]:
		check(Items.NAMES.has(id),"Exclusive exploration item is registered: "+str(id))
		check(ResourceLoader.exists(str(Items.ICONS.get(id,""))),"Exclusive exploration item has real asset: "+str(id))
	check(Items.SWORD_DAMAGE.get(36,0)>=50,"Ancient Sword is a real high-tier weapon")
	check(Items.passive_damage_reduction({37:1})>0.07,"Resistance Amulet grants passive resistance")
	check(Items.exploration_speed_multiplier({38:1})>1.1,"Explorer Boots grant movement speed")
	check(Items.exploration_max_hp_bonus({41:1})==10.0,"Dungeon Relic grants max HP")

	var scene=load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var accounts=load("res://scripts/account_store.gd")
	var saves=load("res://scripts/save_game.gd")
	var user="dungeon_"+str(Time.get_ticks_usec())
	check(bool(accounts.create_account(user,"DungeonPass987!").get("ok",false)),"Dungeon smoke account can be created")
	saves.set_account(user)
	scene.start_world(false,42019)
	await physics_frame
	await physics_frame
	scene.resume()
	for art_item_id in [36,37,38,39,40,41]:
		check(scene.item_display_texture(art_item_id)!=null,"Exclusive item uses generated in-game art: "+str(art_item_id))
	var guardian=load("res://scripts/mob.gd").new()
	guardian.kind="undead_knight"
	guardian.player=scene.player
	guardian.set_dungeon_miniboss("art_smoke","Guardião Visual")
	scene.enemies.add_child(guardian)
	await process_frame
	check(is_instance_valid(guardian.guardian_aura),"Dungeon guardian uses generated purple aura asset")
	check(guardian.sprite.sprite_frames.has_animation("attack"),"Dungeon guardian uses generated attack animation")
	check(guardian.sprite.sprite_frames.has_animation("death"),"Dungeon guardian uses generated death pose")
	guardian.queue_free()
	await process_frame
	check(scene.chest_inventories.size()>=12,"Dungeon chest contents are initialized")
	check(scene.chest_metadata.size()>=12,"Dungeon chest rarity/source metadata is initialized")
	var boss_entry:Dictionary={}
	for entry in scene.world.dungeon_chests:
		if str(entry.get("tier",""))=="boss":
			boss_entry=entry
			break
	var boss_cell:Vector2i=boss_entry.get("cell",Vector2i(-1,-1))
	var dungeon_id=str(boss_entry.get("dungeon_id",""))
	check(scene.dungeon_chest_locked(boss_cell),"Guardian chest starts locked")
	scene.dungeon_miniboss_defeated[dungeon_id]=true
	scene.world.set_chest_unsealed(boss_cell,true)
	check(not scene.dungeon_chest_locked(boss_cell),"Guardian chest unlocks after miniboss defeat")
	check(bool(scene.world.chest_unsealed.get(scene.world._cell_key(boss_cell),false)),"Guardian chest switches from sealed art after defeat")
	check(scene.serialize_chests().has(scene.chest_key(boss_cell)),"Dungeon chest contents participate in normal chest save system")
	check(scene.has_method("spawn_dungeon_enemy") and scene.has_method("update_dungeon_encounters"),"Dungeon encounter and miniboss handlers are integrated")
	check(scene.save_world(),"Dungeon world saves successfully")
	var dungeon_save=saves.read_save()
	check(bool(dungeon_save.get("dungeon_generated",false)),"Save records dungeon generation state")
	check(Dictionary(dungeon_save.get("chests",{})).has(scene.chest_key(boss_cell)),"Dungeon chest contents persist in save")
	check(Dictionary(dungeon_save.get("chest_metadata",{})).has(scene.chest_key(boss_cell)),"Dungeon chest rarity/source metadata persists in save")
	check(bool(Dictionary(dungeon_save.get("dungeon_miniboss_defeated",{})).get(dungeon_id,false)),"Miniboss defeated state persists in save")

	scene.player.inventory[37]=1
	scene.player.inventory[38]=1
	scene.player.inventory[41]=1
	scene.apply_exploration_bonuses()
	check(scene.player.exploration_speed_multiplier>1.1,"Explorer Boots affect the existing player movement system")
	check(scene.player.exploration_damage_reduction>0.07,"Amulet affects the existing damage system")
	check(scene.player.max_hp>=110.0,"Dungeon Relic affects the existing health system")

	print("DUNGEON_TEST=",world.dungeon_signature()," chests=",world.dungeon_chests.size())
	world.queue_free()
	scene.queue_free()
	await process_frame
	quit(0)

func _initialize() -> void:
	ProjectSettings.set_setting("application/config/use_custom_user_dir",true)
	ProjectSettings.set_setting("application/config/custom_user_dir_name","DreadsCraftDungeonTests")
	call_deferred("run")
