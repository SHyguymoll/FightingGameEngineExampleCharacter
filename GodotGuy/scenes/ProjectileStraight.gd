class_name Projectile
extends CharacterBody3D

signal projectile_ended(proj)

@export var start_anim : StringName
@export var loop_anim : StringName
@export var end_anim : StringName
var right_facing : bool
var type : int

enum types {
	STRAIGHT = 0,
	DIAGONAL_DOWN = 1
}

func _ready():
	match type:
		types.STRAIGHT:
			velocity = Vector3.RIGHT * 3.5
		types.DIAGONAL_DOWN:
			velocity = (Vector3.RIGHT * 2.5) + (Vector3.DOWN * 1.5)
	velocity.x *= 1 if right_facing else -1
	$AnimationPlayer.play(start_anim)

func tick():
	# check if hitbox exists since it's removed on contact
	if get_node_or_null(^"Hitbox"):
		# just moves straight forward, velocity isn't even calculated here for simplicity's sake
		move_and_slide()
	else:
		destroy()
	
	#TODO also check if it's hit the bounds of the level

func return_overlaps():
	if get_node_or_null(^"ProjectileContact"):
		return $ProjectileContact.get_overlapping_areas()
	return null

func destroy():
	if get_node_or_null(^"Hitbox"):
		$Hitbox.queue_free()
	velocity = Vector3.ZERO
	$AnimationPlayer.play(end_anim)

func _on_animation_player_animation_finished(anim_name):
	match anim_name:
		start_anim:
			$AnimationPlayer.play(loop_anim)
		loop_anim:
			$AnimationPlayer.play(loop_anim)
		end_anim:
			queue_free()
			emit_signal(&"projectile_ended", self)
