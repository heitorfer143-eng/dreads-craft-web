extends Node2D

var kind="villager"
var display_name="Aldeão"
var dialogue="Bem-vindo ao Reino do Abismo."
var player: CharacterBody2D
var game: Node2D
var sprite: Sprite2D
var region=Rect2()

const REGIONS={
	"villager":Rect2(8,73,73,275),
	"blacksmith":Rect2(80,13,100,330),
	"merchant":Rect2(183,126,93,226),
	"mysterious":Rect2(275,80,100,271),
	"hunter":Rect2(372,13,109,337),
	"monk":Rect2(475,28,100,323),
	"rabbit":Rect2(568,59,66,243)
}

func configure(p_kind:String,p_name:String,p_dialogue:String,p_player:CharacterBody2D,p_game:Node2D) -> void:
	kind=p_kind
	display_name=p_name
	dialogue=p_dialogue
	player=p_player
	game=p_game

func _ready() -> void:
	region=REGIONS.get(kind,REGIONS["villager"])
	var atlas=AtlasTexture.new()
	atlas.atlas=load("res://assets/npcs/npc_sheet.png")
	atlas.region=region
	sprite=Sprite2D.new()
	sprite.texture=atlas
	sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var scale_value=0.36 if kind!="rabbit" else 0.42
	sprite.scale=Vector2(scale_value,scale_value)
	sprite.position=Vector2(0,-region.size.y*scale_value/2.0)
	add_child(sprite)
	z_index=4
	set_process(true)

func is_near() -> bool:
	return is_instance_valid(player) and global_position.distance_to(player.global_position)<105.0

func interact() -> void:
	if is_instance_valid(game):
		game.show_npc_dialogue(self)

func _process(_delta:float) -> void:
	queue_redraw()

func _draw() -> void:
	if not is_near():
		return
	var font=ThemeDB.fallback_font
	draw_circle(Vector2(0,-155 if kind!="rabbit" else -115),18,Color("17131dee"))
	draw_arc(Vector2(0,-155 if kind!="rabbit" else -115),18,0,TAU,24,Color("d8af72"),2)
	draw_string(font,Vector2(-12,-149 if kind!="rabbit" else -109),"...",HORIZONTAL_ALIGNMENT_CENTER,24,13,Color("f6e5cf"))
