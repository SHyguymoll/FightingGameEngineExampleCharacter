class_name Projectile
extends CharacterBody3D

@export var start_anim : StringName
@export var loop_anim : StringName
@export var end_anim : StringName
var right_facing
var speed
var game

func _ready():
	velocity = Vector3.RIGHT * speed * (1 if right_facing else -1)
	$AnimationPlayer.play(start_anim)

func tick():
	# check if hitbox exists since it's removed on contact
	if get_node_or_null(^"Hitbox"):
		# just moves straight forward, velocity isn't even calculated here for simplicity's sake
		move_and_slide()
	else:
		destroy()
	
	#TODO also check if it's hit the bounds of the level

func destroy():
	$AnimationPlayer.play(end_anim)

func _on_animation_player_animation_finished(anim_name):
	match anim_name:
		start_anim:
			$AnimationPlayer.play(loop_anim)
		loop_anim:
			$AnimationPlayer.play(loop_anim)
		end_anim:
			queue_free()
			game.delete_projectile(self)
