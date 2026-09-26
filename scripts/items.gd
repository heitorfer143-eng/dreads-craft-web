extends RefCounted

const NAMES = {1: "Grama", 2: "Terra", 3: "Pedra", 4: "Madeira", 5: "Folhas", 6: "Carvão", 7: "Ferro", 8: "Tábuas", 9: "Bancada", 10: "Carne", 11: "Espada de ferro", 12: "Relíquia Vital", 13: "Picareta de madeira", 14: "Diamante", 15: "Avarita", 16: "Portal da Pureza", 17: "Picareta de pedra", 18: "Picareta de ferro", 19: "Picareta de diamante", 20: "Espada de madeira", 21: "Espada de pedra", 22: "Espada de diamante", 23: "Osso", 24: "Waystone", 25: "Minério das Almas", 26: "Orbe das Almas", 27: "Coração Abissal", 28: "Baú", 29: "Areia", 30: "Arenito", 31: "Arenito trabalhado", 32: "Capacete de Avarita", 33: "Peitoral de Avarita", 34: "Calças de Avarita", 35: "Botas de Avarita"}
const COLORS = {1: Color("68765b"), 2: Color("594237"), 3: Color("575663"), 4: Color("79503b"), 5: Color("354838"), 6: Color("33323d"), 7: Color("9b7768"), 8: Color("a67b50"), 9: Color("bd9160"), 25: Color("f4fbff"), 29: Color("d9b76f"), 30: Color("b88750"), 31: Color("c9975c")}
const HARDNESS = {1: 0.5, 2: 0.65, 3: 1.8, 4: 1.15, 5: 0.3, 6: 2.1, 7: 2.6, 8: 0.8, 9: 1.2, 14: 5.0, 15: 9.0, 16: 3.0, 25: 7.5, 28: 1.1, 29: 0.55, 30: 1.65, 31: 1.8}

const ICONS = {
	2: "res://assets/items/dirt.png",
	3: "res://assets/items/stone.png",
	4: "res://assets/tiles/wood_v11.svg",
	5: "res://assets/items/leaves.png",
	6: "res://assets/items/coal.png",
	7: "res://assets/items/iron.png",
	8: "res://assets/items/planks.png",
	9: "res://assets/items/table.png",
	10: "res://assets/items/meat.png",
	11: "res://assets/items/generated/sword_iron.png",
	12: "res://assets/items/relic_vital.svg",
	13: "res://assets/items/generated/pickaxe_wood.png",
	14: "res://assets/items/item_14.svg",
	15: "res://assets/items/item_15.svg",
	16: "res://assets/items/portal_new_world.svg",
	17: "res://assets/items/generated/pickaxe_stone.png",
	18: "res://assets/items/generated/pickaxe_iron.png",
	19: "res://assets/items/generated/pickaxe_diamond.png",
	20: "res://assets/items/generated/sword_wood.png",
	21: "res://assets/items/generated/sword_stone.png",
	22: "res://assets/items/generated/sword_diamond.png",
	23: "res://assets/items/bone.svg",
	24: "res://assets/items/portal_new_world.svg",
	25: "res://assets/items/soul_ore.svg",
	26: "res://assets/items/soul_ore.svg",
	27: "res://assets/items/abyssal_heart.svg",
	28: "res://assets/items/chest.svg",
	29: "res://assets/tiles/sand.svg",
	30: "res://assets/tiles/sandstone.svg",
	31: "res://assets/tiles/cut_sandstone.svg",
	32: "res://assets/armor/avarita_helmet.png",
	33: "res://assets/armor/avarita_chest.png",
	34: "res://assets/armor/avarita_legs.png",
	35: "res://assets/armor/avarita_boots.png"
}

const CRAFT_ICONS = {
	17: "res://assets/items/generated/pickaxe_stone.png",
	18: "res://assets/items/generated/pickaxe_iron.png",
	19: "res://assets/items/generated/pickaxe_diamond.png",
	20: "res://assets/items/generated/sword_wood.png",
	21: "res://assets/items/generated/sword_stone.png",
	11: "res://assets/items/generated/sword_iron.png",
	22: "res://assets/items/generated/sword_diamond.png",
	16: "res://assets/items/portal_new_world.svg",
	25: "res://assets/tiles/soul_ore.svg",
	26: "res://assets/items/soul_ore.svg",
	32: "res://assets/armor/avarita_helmet.png",
	33: "res://assets/armor/avarita_chest.png",
	34: "res://assets/armor/avarita_legs.png",
	35: "res://assets/armor/avarita_boots.png"
}

const TILE_TEXTURES = {
	1: "res://assets/tiles/grass.png",
	2: "res://assets/tiles/dirt.png",
	3: "res://assets/tiles/stone_world.svg",
	4: "res://assets/tiles/wood_v11.svg",
	5: "res://assets/tiles/leaves.png",
	6: "res://assets/tiles/coal.png",
	7: "res://assets/tiles/iron.png",
	8: "res://assets/tiles/planks.png",
	14: "res://assets/tiles/tile_14.svg",
	15: "res://assets/tiles/tile_15.svg",
	16: "res://assets/items/portal_new_world.svg",
	25: "res://assets/tiles/soul_ore.svg",
	29: "res://assets/tiles/sand.svg",
	30: "res://assets/tiles/sandstone.svg",
	31: "res://assets/tiles/cut_sandstone.svg"
}
const RECIPES = [
	{"name": "Tábuas x4", "cost": {4: 1}, "id": 8, "count": 4, "table": false},
	{"name": "Bancada", "cost": {8: 4}, "id": 9, "count": 1, "table": false},
	{"name": "Picareta de madeira", "cost": {8: 3, 4: 2}, "id": 13, "count": 1, "table": true},
	{"name": "Picareta de pedra", "cost": {3: 3, 8: 2}, "id": 17, "count": 1, "table": true},
	{"name": "Picareta de ferro", "cost": {7: 3, 8: 2}, "id": 18, "count": 1, "table": true},
	{"name": "Picareta de diamante", "cost": {14: 3, 8: 2}, "id": 19, "count": 1, "table": true},
	{"name": "Espada de madeira", "cost": {8: 2}, "id": 20, "count": 1, "table": true},
	{"name": "Espada de pedra", "cost": {3: 2, 8: 1}, "id": 21, "count": 1, "table": true},
	{"name": "Espada de ferro", "cost": {7: 2, 8: 1}, "id": 11, "count": 1, "table": true},
	{"name": "Espada de diamante", "cost": {14: 2, 8: 1}, "id": 22, "count": 1, "table": true},
	{"name": "Portal da Pureza", "cost": {14: 9, 15: 1}, "id": 16, "count": 1, "table": true},
	{"name": "Waystone", "cost": {3: 8, 14: 1}, "id": 24, "count": 1, "table": true},
	{"name": "Orbe das Almas", "cost": {25: 6, 7: 2, 14: 1}, "id": 26, "count": 1, "table": true},
	{"name": "Baú", "cost": {8: 8}, "id": 28, "count": 1, "table": true},
	{"name": "Arenito x2", "cost": {29: 4}, "id": 30, "count": 2, "table": false},
	{"name": "Arenito trabalhado x4", "cost": {30: 4}, "id": 31, "count": 4, "table": true},
	{"name": "Capacete de Avarita", "cost": {15: 3, 7: 2}, "id": 32, "count": 1, "table": true},
	{"name": "Peitoral de Avarita", "cost": {15: 6, 7: 4}, "id": 33, "count": 1, "table": true},
	{"name": "Calças de Avarita", "cost": {15: 5, 7: 3}, "id": 34, "count": 1, "table": true},
	{"name": "Botas de Avarita", "cost": {15: 3, 7: 2}, "id": 35, "count": 1, "table": true}
]

const DETAILS = {
	8: {"category":"blocks", "desc":"Tábuas tratadas para construção e receitas.", "stats":[]},
	9: {"category":"blocks", "desc":"A estação necessária para equipamentos avançados.", "stats":[]},
	13: {"category":"tools", "desc":"Ferramenta inicial para os primeiros túneis.", "stats":["Dano de Mineração: 2", "Durabilidade: 80", "Velocidade: 0.9"]},
	17: {"category":"tools", "desc":"Uma ferramenta simples, mas confiável para começar sua jornada.", "stats":["Dano de Mineração: 3", "Durabilidade: 150", "Velocidade: 1.0"]},
	18: {"category":"tools", "desc":"Mais resistente, ideal para minerações profundas.", "stats":["Dano de Mineração: 5", "Durabilidade: 300", "Velocidade: 1.2"]},
	19: {"category":"tools", "desc":"Alta durabilidade e grande eficiência. Um símbolo de progresso.", "stats":["Dano de Mineração: 8", "Durabilidade: 1200", "Velocidade: 1.5"]},
	20: {"category":"weapons", "desc":"Simples, mas útil em momentos de necessidade.", "stats":["Dano de Ataque: 3", "Durabilidade: 150", "Velocidade: 1.0"]},
	21: {"category":"weapons", "desc":"Um passo adiante, para enfrentar perigos maiores.", "stats":["Dano de Ataque: 5", "Durabilidade: 250", "Velocidade: 1.0"]},
	11: {"category":"weapons", "desc":"Equilíbrio perfeito entre dano e durabilidade.", "stats":["Dano de Ataque: 8", "Durabilidade: 500", "Velocidade: 1.1"]},
	22: {"category":"weapons", "desc":"Poder e velocidade em suas mãos.", "stats":["Dano de Ataque: 12", "Durabilidade: 1560", "Velocidade: 1.3"]},
	16: {"category":"special", "desc":"Abre as portas para uma dimensão além da realidade. Somente os mais preparados devem atravessá-lo.", "stats":["“A pureza não é o fim...", "mas o verdadeiro início.”"]},
	24: {"category":"special", "desc":"Pedra rúnica de retorno. Use-a longe da vila para voltar ao centro do povoado.", "stats":["Teleporte: Vila", "Uso permanente"]},
	25: {"category":"materials", "desc":"Minério branco brilhante encontrado apenas no Reino da Pureza após a queda do Guardião.", "stats":["Raridade: Muito rara", "Requer: Picareta de diamante"]},
	26: {"category":"weapons", "desc":"Um foco arcano alimentado por Minério das Almas. Dispara projéteis em linha reta.", "stats":["Dano de projétil: 36", "Alcance: 18 blocos", "Recarga: 0,65 s"]},
	27: {"category":"special", "desc":"O núcleo ainda pulsante do Leviatã do Lago Abissal. Troféu único do Templo Submerso.", "stats":["Raridade: Lendária", "Boss: Leviatã do Lago Abissal", "Não pode ser obtido novamente"]},
	28: {"category":"blocks", "desc":"Armazena itens. Coloque no mundo e use botão direito/FALAR para abrir.", "stats":["18 tipos de item por baú"]},
	29: {"category":"blocks", "desc":"Areia do deserto. Fácil de coletar e ótima para construções claras.", "stats":[]},
	30: {"category":"blocks", "desc":"Rocha sedimentar compacta. Precisa de picareta para gerar drop.", "stats":["Requer: picareta de madeira+"]},
	31: {"category":"blocks", "desc":"Arenito lapidado para construções e ruínas.", "stats":["Bloco decorativo"]},
	32: {"category":"armor", "desc":"Capacete forjado com Avarita cristalizada.", "stats":["Redução de dano: 7%","Slot: Cabeça"]},
	33: {"category":"armor", "desc":"Peitoral pesado de Avarita, núcleo defensivo do conjunto.", "stats":["Redução de dano: 16%","Slot: Peitoral"]},
	34: {"category":"armor", "desc":"Proteção de pernas reforçada com cristais de Avarita.", "stats":["Redução de dano: 12%","Slot: Pernas"]},
	35: {"category":"armor", "desc":"Botas blindadas de Avarita.", "stats":["Redução de dano: 7%","Slot: Pés"]}
}

static func recipe_category(id: int) -> String:
	return str(DETAILS.get(id, {"category":"blocks"}).get("category","blocks"))

static func description(id: int) -> String:
	return str(DETAILS.get(id, {"desc":""}).get("desc",""))

static func display_stats(id: int) -> Array:
	return DETAILS.get(id, {"stats":[]}).get("stats",[])


static func can_craft(inventory: Dictionary, recipe: Dictionary, creative: bool, near_table: bool) -> bool:
	if creative:
		return true
	if recipe.table and not near_table:
		return false
	for id in recipe.cost:
		if inventory.get(id, 0) < recipe.cost[id]:
			return false
	return true

static func craft(inventory: Dictionary, recipe: Dictionary, creative: bool, near_table: bool) -> bool:
	if not can_craft(inventory, recipe, creative, near_table):
		return false
	if not creative:
		for id in recipe.cost:
			inventory[id] -= recipe.cost[id]
	inventory[recipe.id] = inventory.get(recipe.id, 0) + recipe.count
	return true

const PICK_TIERS = {13: 1, 17: 2, 18: 3, 19: 4}
const MINING_RULES = {
	3: {"min_pick":1,"drop":3},
	6: {"min_pick":1,"drop":6},
	7: {"min_pick":2,"drop":7},
	14: {"min_pick":3,"drop":14},
	15: {"min_pick":4,"drop":15},
	25: {"min_pick":4,"drop":25},
	30: {"min_pick":1,"drop":30},
	31: {"min_pick":1,"drop":31}
}
const ARMOR_SLOTS = {32:"head",33:"chest",34:"legs",35:"feet"}
const ARMOR_REDUCTION = {32:0.07,33:0.16,34:0.12,35:0.07}

static func is_armor(id:int) -> bool:
	return ARMOR_SLOTS.has(id)

static func armor_slot(id:int) -> String:
	return str(ARMOR_SLOTS.get(id,""))

static func armor_reduction(equipment:Dictionary) -> float:
	var total=0.0
	for slot in ["head","chest","legs","feet"]:
		total+=float(ARMOR_REDUCTION.get(int(equipment.get(slot,0)),0.0))
	return clampf(total,0.0,0.65)

const SWORD_DAMAGE = {20: 14, 21: 20, 11: 28, 22: 42}
const SWORD_CRIT_CHANCE = {20: 0.08, 21: 0.10, 11: 0.13, 22: 0.18}
const SWORD_CRIT_MULT = {20: 1.50, 21: 1.55, 11: 1.65, 22: 1.80}

static func mining_speed(inventory: Dictionary) -> float:
	return 1.0 + best_pick(inventory) * 0.8

static func best_pick(inventory: Dictionary) -> int:
	var tier=0
	for id in PICK_TIERS:
		if inventory.get(id,0)>0:
			tier=maxi(tier,PICK_TIERS[id])
	return tier

static func required_pick_tier(id:int) -> int:
	return int(MINING_RULES.get(id,{"min_pick":0}).get("min_pick",0))

static func can_mine(id: int, inventory: Dictionary) -> bool:
	return best_pick(inventory)>=required_pick_tier(id)

static func drop_for_block(id:int, inventory:Dictionary) -> int:
	if id==1:
		return 2
	var rule=MINING_RULES.get(id,{})
	if rule is Dictionary and not rule.is_empty():
		if best_pick(inventory)<int(rule.get("min_pick",0)):
			return 0
		return int(rule.get("drop",id))
	return id

static func mining_requirement_text(id:int) -> String:
	var tier=required_pick_tier(id)
	return str({1:"picareta de madeira",2:"picareta de pedra",3:"picareta de ferro",4:"picareta de diamante"}.get(tier,""))

static func crit_chance(id:int) -> float:
	return float(SWORD_CRIT_CHANCE.get(id,0.05))

static func crit_multiplier(id:int) -> float:
	return float(SWORD_CRIT_MULT.get(id,1.50))
