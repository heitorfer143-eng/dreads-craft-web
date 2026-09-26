extends RefCounted

const P0=preload("res://assets/dungeon/atlas_part_00.gd")
const P1=preload("res://assets/dungeon/atlas_part_01.gd")
const P2=preload("res://assets/dungeon/atlas_part_02.gd")
const P3=preload("res://assets/dungeon/atlas_part_03.gd")
const P4=preload("res://assets/dungeon/atlas_part_04.gd")
const P5=preload("res://assets/dungeon/atlas_part_05.gd")
const P6=preload("res://assets/dungeon/atlas_part_06.gd")

const REGIONS={
	"dungeon_tower_facade":Rect2i(2,2,54,64),
	"dungeon_water_gate":Rect2i(58,2,55,60),
	"dungeon_crypt_facade":Rect2i(114,2,64,59),
	"dungeon_desert_facade":Rect2i(180,2,56,56),
	"guardian_aura":Rect2i(2,67,44,44),
	"guardian_attack1":Rect2i(47,67,38,40),
	"guardian_attack2":Rect2i(87,67,42,39),
	"guardian_idle":Rect2i(130,67,34,36),
	"guardian_walk1":Rect2i(166,67,34,36),
	"guardian_walk2":Rect2i(202,67,31,36),
	"guardian_hurt":Rect2i(2,112,35,34),
	"dungeon_wall_stone":Rect2i(38,112,20,26),
	"dungeon_wall_sandstone":Rect2i(60,112,20,26),
	"guardian_death":Rect2i(80,112,44,23),
	"chest_dungeon_open":Rect2i(126,112,20,22),
	"chest_boss_open":Rect2i(148,112,21,22),
	"chest_boss_sealed":Rect2i(170,112,28,22),
	"chest_loot_burst":Rect2i(200,112,24,22),
	"chest_common_open":Rect2i(225,112,19,20),
	"chest_rare_open":Rect2i(2,148,20,20),
	"chest_boss_closed":Rect2i(23,148,26,20),
	"ancient_sword":Rect2i(50,148,14,19),
	"resistance_amulet":Rect2i(65,148,14,19),
	"map_fragment":Rect2i(80,148,18,19),
	"crypt_key":Rect2i(100,148,8,19),
	"dungeon_relic":Rect2i(109,148,13,19),
	"chest_common_closed":Rect2i(124,148,26,19),
	"chest_dungeon_closed":Rect2i(150,148,26,19),
	"chest_rare_closed":Rect2i(178,148,26,18),
	"explorer_boots":Rect2i(204,148,19,14)
}

static var _atlas:Texture2D=null
static var _textures:Dictionary={}
static var _guardian_frames:SpriteFrames=null

static func encoded_data() -> String:
	return P0.DATA+P1.DATA+P2.DATA+P3.DATA+P4.DATA+P5.DATA+P6.DATA

static func atlas() -> Texture2D:
	if _atlas!=null:
		return _atlas
	var raw=Marshalls.base64_to_raw(encoded_data())
	if raw.is_empty():
		return null
	var image=Image.new()
	if image.load_webp_from_buffer(raw)!=OK:
		return null
	_atlas=ImageTexture.create_from_image(image)
	return _atlas

static func texture(name:String) -> AtlasTexture:
	if _textures.has(name):
		return _textures[name]
	var base=atlas()
	if base==null or not REGIONS.has(name):
		return null
	var result=AtlasTexture.new()
	result.atlas=base
	result.region=Rect2(REGIONS[name])
	result.filter_clip=true
	_textures[name]=result
	return result

static func guardian_frames() -> SpriteFrames:
	if _guardian_frames!=null:
		return _guardian_frames
	var frames=SpriteFrames.new()
	frames.remove_animation("default")
	for animation_name in ["idle","walk","attack","hurt","death"]:
		frames.add_animation(animation_name)
	frames.set_animation_loop("idle",true)
	frames.set_animation_speed("idle",1.0)
	frames.add_frame("idle",texture("guardian_idle"))
	frames.set_animation_loop("walk",true)
	frames.set_animation_speed("walk",5.0)
	frames.add_frame("walk",texture("guardian_walk1"))
	frames.add_frame("walk",texture("guardian_walk2"))
	frames.set_animation_loop("attack",true)
	frames.set_animation_speed("attack",7.5)
	frames.add_frame("attack",texture("guardian_attack1"))
	frames.add_frame("attack",texture("guardian_attack2"))
	frames.set_animation_loop("hurt",false)
	frames.set_animation_speed("hurt",1.0)
	frames.add_frame("hurt",texture("guardian_hurt"))
	frames.set_animation_loop("death",false)
	frames.set_animation_speed("death",1.0)
	frames.add_frame("death",texture("guardian_death"))
	_guardian_frames=frames
	return _guardian_frames

static func item_texture_name(item_id:int) -> String:
	return str({
		36:"ancient_sword",
		37:"resistance_amulet",
		38:"explorer_boots",
		39:"map_fragment",
		40:"crypt_key",
		41:"dungeon_relic"
	}.get(item_id,""))

static func chest_texture_name(tier:String,opened:bool,sealed:bool=false) -> String:
	if tier=="boss" and sealed and not opened:
		return "chest_boss_sealed"
	if tier=="boss":
		return "chest_boss_open" if opened else "chest_boss_closed"
	if tier=="dungeon":
		return "chest_dungeon_open" if opened else "chest_dungeon_closed"
	if tier=="rare":
		return "chest_rare_open" if opened else "chest_rare_closed"
	return "chest_common_open" if opened else "chest_common_closed"
