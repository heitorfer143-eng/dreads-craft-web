extends RefCounted

const RARITY_COLORS={
	"common":Color("b9b5af"),
	"uncommon":Color("79c98a"),
	"rare":Color("6ca8ff"),
	"epic":Color("c178e8"),
	"legendary":Color("f0b85f")
}

const ITEM_RARITY={
	3:"common",6:"common",10:"common",23:"common",
	7:"uncommon",17:"uncommon",18:"uncommon",24:"uncommon",
	14:"rare",39:"rare",40:"rare",38:"rare",
	36:"epic",37:"epic",15:"epic",
	41:"legendary"
}

const TYPE_NAMES={
	"crypt":"Cripta Esquecida",
	"tower":"Torre em Ruínas",
	"desert_ruin":"Ruína do Deserto"
}

const CHEST_NAMES={
	"common":"Baú Comum",
	"rare":"Baú Raro",
	"dungeon":"Baú de Dungeon",
	"boss":"Baú do Guardião"
}

static func rarity_of(item_id:int) -> String:
	return str(ITEM_RARITY.get(item_id,"common"))

static func rarity_color(rarity:String) -> Color:
	return RARITY_COLORS.get(rarity,Color("b9b5af"))

static func dungeon_name(kind:String) -> String:
	return str(TYPE_NAMES.get(kind,"Dungeon"))

static func chest_name(tier:String) -> String:
	return str(CHEST_NAMES.get(tier,"Baú"))

static func _pick_weighted(rng:RandomNumberGenerator, entries:Array) -> Dictionary:
	var total=0
	for entry in entries:
		total+=int(entry.get("weight",1))
	var roll=rng.randi_range(1,maxi(1,total))
	for entry in entries:
		roll-=int(entry.get("weight",1))
		if roll<=0:
			return entry
	return entries[0]

static func _table_for(kind:String,tier:String) -> Array:
	if kind=="crypt":
		if tier=="boss":
			return [
				{"id":40,"min":1,"max":1,"weight":100},
				{"id":36,"min":1,"max":1,"weight":36},
				{"id":14,"min":1,"max":3,"weight":64},
				{"id":41,"min":1,"max":1,"weight":18}
			]
		if tier=="dungeon":
			return [
				{"id":7,"min":2,"max":6,"weight":32},
				{"id":23,"min":3,"max":8,"weight":28},
				{"id":39,"min":1,"max":2,"weight":22},
				{"id":14,"min":1,"max":2,"weight":12},
				{"id":36,"min":1,"max":1,"weight":6}
			]
		if tier=="rare":
			return [
				{"id":39,"min":1,"max":2,"weight":40},
				{"id":40,"min":1,"max":1,"weight":28},
				{"id":14,"min":1,"max":2,"weight":20},
				{"id":36,"min":1,"max":1,"weight":12}
			]
		return [
			{"id":3,"min":8,"max":18,"weight":34},
			{"id":6,"min":3,"max":9,"weight":30},
			{"id":23,"min":2,"max":6,"weight":24},
			{"id":7,"min":1,"max":4,"weight":12}
		]
	if kind=="tower":
		if tier=="boss":
			return [
				{"id":38,"min":1,"max":1,"weight":100},
				{"id":39,"min":1,"max":3,"weight":65},
				{"id":14,"min":1,"max":2,"weight":35},
				{"id":41,"min":1,"max":1,"weight":14}
			]
		if tier=="dungeon":
			return [
				{"id":10,"min":2,"max":6,"weight":28},
				{"id":7,"min":2,"max":5,"weight":28},
				{"id":39,"min":1,"max":2,"weight":26},
				{"id":24,"min":1,"max":1,"weight":12},
				{"id":38,"min":1,"max":1,"weight":6}
			]
		if tier=="rare":
			return [
				{"id":39,"min":1,"max":3,"weight":42},
				{"id":24,"min":1,"max":1,"weight":22},
				{"id":14,"min":1,"max":2,"weight":20},
				{"id":38,"min":1,"max":1,"weight":16}
			]
		return [
			{"id":4,"min":6,"max":14,"weight":32},
			{"id":6,"min":2,"max":7,"weight":26},
			{"id":10,"min":1,"max":4,"weight":24},
			{"id":7,"min":1,"max":3,"weight":18}
		]
	if kind=="desert_ruin":
		if tier=="boss":
			return [
				{"id":37,"min":1,"max":1,"weight":100},
				{"id":14,"min":1,"max":3,"weight":48},
				{"id":15,"min":1,"max":1,"weight":12},
				{"id":41,"min":1,"max":1,"weight":16}
			]
		if tier=="dungeon":
			return [
				{"id":30,"min":5,"max":12,"weight":30},
				{"id":31,"min":3,"max":8,"weight":24},
				{"id":39,"min":1,"max":2,"weight":20},
				{"id":14,"min":1,"max":2,"weight":14},
				{"id":37,"min":1,"max":1,"weight":7},
				{"id":15,"min":1,"max":1,"weight":5}
			]
		if tier=="rare":
			return [
				{"id":31,"min":5,"max":12,"weight":30},
				{"id":39,"min":1,"max":3,"weight":28},
				{"id":14,"min":1,"max":2,"weight":20},
				{"id":37,"min":1,"max":1,"weight":16},
				{"id":15,"min":1,"max":1,"weight":6}
			]
		return [
			{"id":29,"min":8,"max":18,"weight":34},
			{"id":30,"min":4,"max":10,"weight":30},
			{"id":23,"min":1,"max":5,"weight":22},
			{"id":7,"min":1,"max":3,"weight":14}
		]
	return [{"id":3,"min":4,"max":10,"weight":1}]

static func generate_loot(seed_value:int,kind:String,tier:String) -> Dictionary:
	var rng=RandomNumberGenerator.new()
	rng.seed=seed_value ^ kind.hash() ^ tier.hash()
	var result:Dictionary={}
	var rolls=2 if tier=="common" else 3 if tier=="rare" else 4 if tier=="dungeon" else 5
	var table=_table_for(kind,tier)
	for roll_index in range(rolls):
		var entry=_pick_weighted(rng,table)
		var item_id=int(entry.get("id",3))
		var count=rng.randi_range(int(entry.get("min",1)),int(entry.get("max",1)))
		result[item_id]=int(result.get(item_id,0))+count
	# Boss chests always carry their dungeon signature item.
	if tier=="boss":
		var signature=40 if kind=="crypt" else 38 if kind=="tower" else 37
		result[signature]=maxi(1,int(result.get(signature,0)))
	return result

static func highest_rarity(inventory:Dictionary) -> String:
	var order={"common":0,"uncommon":1,"rare":2,"epic":3,"legendary":4}
	var best="common"
	for raw_id in inventory:
		var rarity=rarity_of(int(raw_id))
		if int(order.get(rarity,0))>int(order.get(best,0)):
			best=rarity
	return best
