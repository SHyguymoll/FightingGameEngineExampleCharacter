class_name Projectile
extends CharacterBody3D

signal projectile_ended(proj)

@export var start_anim : StringName
@export var loop_anim_left : StringName
@export var loop_anim_right : StringName
@export var end_anim : StringName
var right_facing : bool
var type : int
var source : int

enum types {
	STRAIGHT = 0,
	DIAGONAL_DOWN = 1,
	SUPER = 2,
	DIAGONAL_DOWN_SUPER = 3,
}

func _ready():
	match type:
		types.STRAIGHT:
			velocity = Vector3.RIGHT * 6
		types.DIAGONAL_DOWN:
			velocity = (Vector3.RIGHT * 5) + (Vector3.DOWN * 1.5)
		types.SUPER:
			velocity = Vector3.RIGHT * 10
		types.DIAGONAL_DOWN_SUPER:
			velocity = (Vector3.RIGHT * 30 * randf()) + (Vector3.DOWN * randf() * 10)
	velocity.x *= 1 if right_facing else -1
	match type:
		types.STRAIGHT, types.DIAGONAL_DOWN:
			($Hitbox as Hitbox).damage_hit = 5
			($Hitbox as Hitbox).damage_block = 1
			($Hitbox as Hitbox).stun_hit = 10
			($Hitbox as Hitbox).stun_block = 5
			($Hitbox as Hitbox).kback_hit = Vector3(4, 3, 0)
			($Hitbox as Hitbox).kback_block = Vector3(2, -2, 0)
			($Hitbox as Hitbox).hit_type = "mid"
			($Hitbox as Hitbox).on_hit = [8]
			($Hitbox as Hitbox).on_block = [4]
		types.SUPER:
			($Hitbox as Hitbox).damage_hit = 20
			($Hitbox as Hitbox).damage_block = 10
			($Hitbox as Hitbox).stun_hit = 10
			($Hitbox as Hitbox).stun_block = 5
			($Hitbox as Hitbox).kback_hit = Vector3(4, 7, 0)
			($Hitbox as Hitbox).kback_block = Vector3(2, -2, 0)
			($Hitbox as Hitbox).hit_type = "launch"
			($Hitbox as Hitbox).on_hit = [0]
			($Hitbox as Hitbox).on_block = [0]
		types.DIAGONAL_DOWN_SUPER:
			($Hitbox as Hitbox).damage_hit = 2
			($Hitbox as Hitbox).damage_block = 1
			($Hitbox as Hitbox).stun_hit = 10
			($Hitbox as Hitbox).stun_block = 5
			($Hitbox as Hitbox).kback_hit = Vector3(-2, 2, 0)
			($Hitbox as Hitbox).kback_block = Vector3(2, -2, 0)
			($Hitbox as Hitbox).hit_type = "launch"
			($Hitbox as Hitbox).on_hit = [0]
			($Hitbox as Hitbox).on_block = [0]
	$AnimationPlayer.play(start_anim)

func tick():
	# check if hitbox exists since it's removed on contact
	if get_node_or_null(^"Hitbox"):
		# just moves straight forward, velocity isn't even calculated here for simplicity's sake
		move_and_slide()
	else:
		destroy()

func destroy():
	if get_node_or_null(^"Hitbox"):
		$Hitbox.queue_free()
	velocity = Vector3.ZERO
	$AnimationPlayer.play(end_anim)

func _on_animation_player_animation_finished(anim_name):
	match anim_name:
		start_anim:
			$AnimationPlayer.play(loop_anim_right if right_facing else loop_anim_left)
		loop_anim_left:
			$AnimationPlayer.play(loop_anim_left)
		loop_anim_right:
			$AnimationPlayer.play(loop_anim_right)
		end_anim:
			queue_free()
			emit_signal(&"projectile_ended", self)

func _on_projectile_contact(other):
	var o_par = other.get_parent()
	if other is Stage or o_par is Stage:
		destroy()
	if o_par is Projectile:
		if source != other.get_parent().source:
			destroy()
