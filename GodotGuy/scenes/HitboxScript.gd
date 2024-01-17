class_name Hitbox
extends Area3D

@export var lifetime : int
@export var damage_hit : float
@export var damage_block : float
@export var stun_hit : int
@export var stun_block : int
@export var kback_hit : Vector3
@export var kback_block : Vector3
@export var hit_priority : int
@export var type : String

func _physics_process(_d):
	if lifetime > 0:
		lifetime -= 1
	if lifetime == 0:
		queue_free()
