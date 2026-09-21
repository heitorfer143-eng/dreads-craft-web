extends Node2D

const Items=preload("res://scripts/items.gd")

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var game=get_parent()
	if not game.active or game.modal or game.target.x<0:
		return
	var area=Rect2(Vector2(game.target)*32+Vector2(1,1),Vector2(30,30))
	draw_rect(area,Color("d0abe8"),false,2)
	if game.progress>0:
		var need=float(Items.HARDNESS.get(game.world.get_cell(game.target),1))
		draw_rect(Rect2(area.position-Vector2(0,6),Vector2(30*minf(1,game.progress/need),3)),Color("c6a077"))
