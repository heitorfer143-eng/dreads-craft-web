extends RefCounted

const NAMES = {1: "Grama", 2: "Terra", 3: "Pedra", 4: "Madeira", 5: "Folhas", 6: "Carvão", 7: "Ferro", 8: "Tábuas", 9: "Bancada", 10: "Carne", 11: "Espada de ferro", 12: "Relíquia Vital", 13: "Picareta de madeira", 14: "Diamante", 15: "Avarita", 16: "Portal da Pureza", 17: "Picareta de pedra", 18: "Picareta de ferro", 19: "Picareta de diamante", 20: "Espada de madeira", 21: "Espada de pedra", 22: "Espada de diamante", 23: "Osso"}
const COLORS = {1: Color("68765b"), 2: Color("594237"), 3: Color("575663"), 4: Color("79503b"), 5: Color("354838"), 6: Color("33323d"), 7: Color("9b7768"), 8: Color("a67b50"), 9: Color("bd9160")}
const HARDNESS = {1: 0.5, 2: 0.65, 3: 1.8, 4: 1.15, 5: 0.3, 6: 2.1, 7: 2.6, 8: 0.8, 9: 1.2, 14: 5.0, 15: 9.0, 16: 3.0}

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
	11: "res://assets/items/sword_iron_v11.svg",
	12: "res://assets/items/relic_vital.svg",
	13: "res://assets/items/pickaxe_wood_v11.svg",
	14: "res://assets/items/item_14.svg",
	15: "res://assets/items/item_15.svg",
	16: "res://assets/items/item_16.svg",
	17: "res://assets/items/pickaxe_stone_v11.svg",
	18: "res://assets/items/pickaxe_iron_v11.svg",
	19: "res://assets/items/pickaxe_diamond_v11.svg",
	20: "res://assets/items/sword_wood_v11.svg",
	21: "res://assets/items/sword_stone_v11.svg",
	22: "res://assets/items/sword_diamond_v11.svg",
	23: "res://assets/items/bone.svg"
}

const CRAFT_ICONS = {
	17: "res://assets/items/pickaxe_stone_v11.svg",
	18: "res://assets/items/pickaxe_iron_v11.svg",
	19: "res://assets/items/pickaxe_diamond_v11.svg",
	20: "res://assets/items/sword_wood_v11.svg",
	21: "res://assets/items/sword_stone_v11.svg",
	11: "res://assets/items/sword_iron_v11.svg",
	22: "res://assets/items/sword_diamond_v11.svg",
	16: "res://assets/craft_ref/portal_purity.png"
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
	9: "res://assets/tiles/table.png",
	14: "res://assets/tiles/tile_14.svg",
	15: "res://assets/tiles/tile_15.svg",
	16: "res://assets/tiles/tile_16.svg"
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
	{"name": "Portal da Pureza", "cost": {14: 9, 15: 1}, "id": 16, "count": 1, "table": true}
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
	16: {"category":"special", "desc":"Abre as portas para uma dimensão além da realidade. Somente os mais preparados devem atravessá-lo.", "stats":["“A pureza não é o fim...", "mas o verdadeiro início.”"]}
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
const SWORD_DAMAGE = {20: 14, 21: 20, 11: 28, 22: 42}

static func mining_speed(inventory: Dictionary) -> float:
	return 1.0 + best_pick(inventory) * 0.8

static func best_pick(inventory: Dictionary) -> int:
	var tier=0
	for id in PICK_TIERS:
		if inventory.get(id,0)>0:
			tier=maxi(tier,PICK_TIERS[id])
	return tier

static func can_mine(id: int, inventory: Dictionary) -> bool:
	return best_pick(inventory)>=int({7:2,14:3,15:4}.get(id,0))
