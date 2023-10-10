class_name Hitbox
extends Area3D

var lifetime : int
var damage_hit : float
var damage_block : float
var stun_hit : int
var stun_block : int
var kback_hit : Vector3
var kback_block : Vector3
var hit_priority : int
var type : String

func _physics_process(delta):
	lifetime -= 1
	if lifetime < 0:
		queue_free()
