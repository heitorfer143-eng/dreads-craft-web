extends CharacterBody2D

const Items=preload("res://scripts/items.gd")

var item_id:int=0
var count:int=1
var player:CharacterBody2D
var lifetime:float=300.0
var pickup_delay:float=0.65
var age:float=0.0
var sprite:Sprite2D
var amount_label:Label

func setup(p_item_id:int,p_count:int,p_player:CharacterBody2D,p_lifetime:float=300.0) -> void:
	item_id=p_item_id
	count=maxi(1,p_count)
	player=p_player
	lifetime=clampf(p_lifetime,0.1,300.0)

func _ready() -> void:
	collision_layer=0
	collision_mask=1
	var shape=RectangleShape2D.new()
	shape.size=Vector2(14,14)
	var collider=CollisionShape2D.new()
	collider.shape=shape
	collider.position=Vector2(0,-7)
	add_child(collider)

	sprite=Sprite2D.new()
	var path=str(Items.ICONS.get(item_id,"res://assets/items/dirt.png"))
	if ResourceLoader.exists(path):
		sprite.texture=load(path)
	sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	# Item art mixes tiny tile icons with large illustrated inventory icons.
	# Normalize every dropped item to a world-sized pickup so a 256px dirt/leaves
	# illustration can never become a giant block/tree in the world.
	if sprite.texture!=null:
		var tex_size=sprite.texture.get_size()
		var longest=maxf(tex_size.x,tex_size.y)
		var fit=28.0/maxf(1.0,longest)
		sprite.scale=Vector2(fit,fit)
	else:
		sprite.scale=Vector2.ONE
	sprite.position=Vector2(0,-12)
	add_child(sprite)

	amount_label=Label.new()
	amount_label.text=str(count) if count>1 else ""
	amount_label.position=Vector2(8,-24)
	amount_label.add_theme_font_size_override("font_size",10)
	amount_label.add_theme_color_override("font_color",Color.WHITE)
	amount_label.add_theme_color_override("font_shadow_color",Color.BLACK)
	amount_label.add_theme_constant_override("shadow_offset_x",1)
	amount_label.add_theme_constant_override("shadow_offset_y",1)
	add_child(amount_label)

	velocity=Vector2(randf_range(-55.0,55.0),-150.0)
	z_index=8

func _physics_process(delta:float) -> void:
	age+=delta
	lifetime-=delta
	pickup_delay=maxf(0.0,pickup_delay-delta)
	if lifetime<=0:
		queue_free()
		return

	velocity.y=minf(700.0,velocity.y+900.0*delta)
	velocity.x=move_toward(velocity.x,0.0,110.0*delta)
	move_and_slide()
	if is_on_floor():
		velocity.y=0.0

	if is_instance_valid(sprite):
		sprite.position.y=-12.0+sin(age*5.0)*2.0

	if pickup_delay<=0 and is_instance_valid(player) and global_position.distance_to(player.global_position)<46.0:
		player.inventory[item_id]=int(player.inventory.get(item_id,0))+count
		var game=get_parent().get_parent() if get_parent()!=null else null
		if game!=null and game.has_method("on_ground_item_picked"):
			game.on_ground_item_picked(item_id,count)
		queue_free()

func serialize() -> Dictionary:
	return {
		"id":item_id,
		"count":count,
		"position":[position.x,position.y],
		"remaining":maxf(0.1,lifetime)
	}
