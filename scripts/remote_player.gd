extends Node2D

const Sprites = preload("res://scripts/sprites.gd")

var player_name := "Jogador"
var target_position := Vector2.ZERO
var face := 1
var anim := "idle"
var sprite: AnimatedSprite2D
var name_label: Label

func _ready() -> void:
	z_index=12
	sprite=Sprites.make("normal")
	sprite.scale=Vector2(0.18,0.18)
	add_child(sprite)
	name_label=Label.new()
	name_label.text=player_name
	name_label.position=Vector2(-70,-78)
	name_label.size=Vector2(140,22)
	name_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size",12)
	name_label.add_theme_color_override("font_color",Color("f3dfbd"))
	name_label.add_theme_color_override("font_shadow_color",Color("000000"))
	name_label.add_theme_constant_override("shadow_offset_x",2)
	name_label.add_theme_constant_override("shadow_offset_y",2)
	add_child(name_label)

func setup(display_name:String, pos:Vector2, p_face:int=1, p_anim:String="idle") -> void:
	player_name=display_name
	target_position=pos
	position=pos
	face=p_face
	anim=p_anim
	if is_instance_valid(name_label):
		name_label.text=player_name

func set_state(pos:Vector2,p_face:int,p_anim:String) -> void:
	target_position=pos
	face=p_face
	anim=p_anim

func _process(delta:float) -> void:
	position=position.lerp(target_position,clampf(delta*14.0,0.0,1.0))
	if not is_instance_valid(sprite):
		return
	sprite.flip_h=face<0
	var wanted=anim if sprite.sprite_frames.has_animation(anim) else "idle"
	if sprite.animation!=wanted:
		sprite.play(wanted)
