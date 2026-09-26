extends Area2D

signal interacted(mel)

var player: CharacterBody2D
var tamed := false
var sprite: Sprite2D
var home_position:=Vector2.ZERO
var wander_dir:=1.0
var wander_timer:=0.0
var anim_time:=0.0
var base_scale:=0.46
var quest_marker:=""
var world_min_x:=0.0
var world_max_x:=320.0*32.0
var world_min_y:=0.0
var world_max_y:=96.0*32.0

func setup(target: CharacterBody2D, is_tamed: bool=false) -> void:
	player=target
	tamed=is_tamed

func _ready() -> void:
	collision_layer=0
	collision_mask=0
	var shape=CollisionShape2D.new()
	var capsule=CapsuleShape2D.new()
	capsule.radius=18
	capsule.height=34
	shape.shape=capsule
	shape.position=Vector2(0,-16)
	add_child(shape)
	sprite=Sprite2D.new()
	sprite.texture=load("res://assets/npcs/mel_generated.png")
	sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	if sprite.texture!=null:
		base_scale=34.0/maxf(1.0,sprite.texture.get_size().y)
	sprite.scale=Vector2(base_scale,base_scale)
	sprite.position=Vector2(0,-17)
	add_child(sprite)
	home_position=global_position
	wander_timer=randf_range(1.4,3.2)
	z_index=6

func set_world_bounds(min_x:float,max_x:float,min_y:float,max_y:float) -> void:
	world_min_x=min_x
	world_max_x=max_x
	world_min_y=min_y
	world_max_y=max_y

func can_interact() -> bool:
	return is_instance_valid(player) and global_position.distance_to(player.global_position)<125.0

func interact() -> void:
	if can_interact():
		interacted.emit(self)

func set_tamed(value: bool) -> void:
	tamed=value
	if tamed:
		quest_marker=""
	queue_redraw()

func set_quest_marker(value:String) -> void:
	quest_marker="" if tamed else (value if value in ["!","?"] else "")
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	anim_time+=delta
	wander_timer-=delta
	if tamed:
		var target=player.position+Vector2(-player.face*72,0)
		var distance=global_position.distance_to(target)
		if distance>420:
			global_position=target
		elif distance>58:
			global_position.x=move_toward(global_position.x,target.x,150.0*delta)
			global_position.y=move_toward(global_position.y,player.position.y,110.0*delta)
			sprite.flip_h=player.position.x<global_position.x
	else:
		if wander_timer<=0:
			wander_timer=randf_range(1.2,3.0)
			wander_dir=-wander_dir if randf()<0.7 else wander_dir
		var min_x=home_position.x-150.0
		var max_x=home_position.x+150.0
		if global_position.x<=min_x:
			wander_dir=1.0
		elif global_position.x>=max_x:
			wander_dir=-1.0
		global_position.x=clampf(global_position.x+wander_dir*42.0*delta,min_x,max_x)
		sprite.flip_h=wander_dir<0
	global_position.x=clampf(global_position.x,world_min_x+16.0,world_max_x-16.0)
	global_position.y=clampf(global_position.y,world_min_y+36.0,world_max_y-2.0)
	var moving=tamed and global_position.distance_to(player.position)>70.0 or not tamed
	sprite.position=Vector2(0,-17+sin(anim_time*(8.0 if moving else 3.0))*1.0)
	sprite.scale=Vector2(base_scale,base_scale)

func _process(_delta: float) -> void:
	queue_redraw()

func draw_ellipse_shadow(center:Vector2,radius:Vector2,color:Color) -> void:
	var points=PackedVector2Array()
	for i in range(18):
		var angle=TAU*float(i)/18.0
		points.append(center+Vector2(cos(angle)*radius.x,sin(angle)*radius.y))
	draw_colored_polygon(points,color)

func _draw() -> void:
	draw_ellipse_shadow(Vector2(0,-2),Vector2(14,4),Color(0,0,0,.22))
	if quest_marker=="":
		return
	var y=-68.0
	var marker_color=Color("e5b66f") if quest_marker=="!" else Color("9fe7b2")
	draw_circle(Vector2(0,y),13,Color("17111ef0"))
	draw_arc(Vector2(0,y),13,0,TAU,20,marker_color,2)
	draw_string(ThemeDB.fallback_font,Vector2(-4,y+5),quest_marker,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("fff1df"))
