class_name GeneratedSheetAssets
extends RefCounted

const STRUCTURES_PATH="res://assets/generated/structures_sheet.webp"
const INTERIORS_PATH="res://assets/generated/interiors_sheet.webp"
const PORTRAITS_PATH="res://assets/generated/portraits_sheet.webp"
const EQUIPMENT_PATH="res://assets/generated/equipment_sheet.webp"
const UI_ICONS_PATH="res://assets/generated/ui_icons_sheet.webp"
const MEL_PATH="res://assets/generated/mel_sheet.webp"

static func atlas(path:String, region:Rect2) -> AtlasTexture:
	var t=AtlasTexture.new()
	t.atlas=load(path)
	t.region=region
	return t

static func structure(kind:String) -> Texture2D:
	match kind:
		"blacksmith": return atlas(STRUCTURES_PATH,Rect2(0,0,362,362))
		"market", "shop": return atlas(STRUCTURES_PATH,Rect2(362,0,362,362))
		_: return atlas(STRUCTURES_PATH,Rect2(724,0,362,362))

static func interior(kind:String) -> Texture2D:
	match kind:
		"blacksmith": return atlas(INTERIORS_PATH,Rect2(0,0,724,724))
		"market", "shop": return atlas(INTERIORS_PATH,Rect2(724,0,724,724))
		_: return atlas(INTERIORS_PATH,Rect2(1448,0,724,724))

static func portrait(role:String) -> Texture2D:
	match role:
		"villager": return atlas(PORTRAITS_PATH,Rect2(0,0,256,256))
		"blacksmith", "ferreiro": return atlas(PORTRAITS_PATH,Rect2(256,0,256,256))
		"merchant", "mercador": return atlas(PORTRAITS_PATH,Rect2(512,0,256,256))
		"traveler", "viajante": return atlas(PORTRAITS_PATH,Rect2(0,256,256,256))
		"hunter", "cacador": return atlas(PORTRAITS_PATH,Rect2(256,256,256,256))
		_: return atlas(PORTRAITS_PATH,Rect2(512,256,256,256))

static func equipment(name:String) -> Texture2D:
	match name:
		"pickaxe_wood": return atlas(EQUIPMENT_PATH,Rect2(4,45,78,102))
		"pickaxe_stone": return atlas(EQUIPMENT_PATH,Rect2(80,45,78,102))
		"pickaxe_iron": return atlas(EQUIPMENT_PATH,Rect2(157,45,79,102))
		"pickaxe_diamond": return atlas(EQUIPMENT_PATH,Rect2(236,45,77,102))
		"sword_wood": return atlas(EQUIPMENT_PATH,Rect2(4,156,74,120))
		"sword_stone": return atlas(EQUIPMENT_PATH,Rect2(80,156,74,120))
		"sword_iron": return atlas(EQUIPMENT_PATH,Rect2(157,154,76,121))
		_: return atlas(EQUIPMENT_PATH,Rect2(235,153,78,123))

static func icon(name:String) -> Texture2D:
	match name:
		"portal": return atlas(UI_ICONS_PATH,Rect2(2,32,108,122))
		"multiplayer": return atlas(UI_ICONS_PATH,Rect2(105,28,105,120))
		"worlds": return atlas(UI_ICONS_PATH,Rect2(210,38,103,118))
		"crafting": return atlas(UI_ICONS_PATH,Rect2(5,165,106,116))
		"exit": return atlas(UI_ICONS_PATH,Rect2(110,165,102,121))
		_: return atlas(UI_ICONS_PATH,Rect2(207,158,106,132))

static func item_icon(id:int) -> Texture2D:
	match id:
		13: return equipment("pickaxe_wood")
		17: return equipment("pickaxe_stone")
		18: return equipment("pickaxe_iron")
		19: return equipment("pickaxe_diamond")
		20: return equipment("sword_wood")
		21: return equipment("sword_stone")
		11: return equipment("sword_iron")
		22: return equipment("sword_diamond")
		16: return icon("portal")
		24: return icon("waystone")
	return null

static func mel_frame(row:int,index:int) -> Texture2D:
	var regions=[
		[Rect2(11,8,52,49),Rect2(72,8,52,49),Rect2(133,8,53,49),Rect2(197,8,55,49)],
		[Rect2(8,65,49,40),Rect2(56,65,45,40),Rect2(102,65,45,40),Rect2(148,66,46,40),Rect2(193,65,48,40),Rect2(241,65,45,40),Rect2(288,65,44,40),Rect2(335,65,47,40)],
		[Rect2(11,112,50,48),Rect2(74,112,51,48),Rect2(139,112,50,48),Rect2(202,112,50,48)],
		[Rect2(10,165,53,39),Rect2(72,165,51,39),Rect2(134,165,48,39),Rect2(196,165,42,39)],
		[Rect2(12,207,43,45),Rect2(72,207,43,45),Rect2(134,207,40,44),Rect2(189,207,43,45)]
	]
	var safe_row=clampi(row,0,regions.size()-1)
	var safe_index=clampi(index,0,regions[safe_row].size()-1)
	return atlas(MEL_PATH,regions[safe_row][safe_index])

static func mel_portrait() -> Texture2D:
	return mel_frame(4,3)
