class_name Hitbox
extends Area3D

@export var lifetime : int
@export_category("Damage")
@export var damage_hit : float
@export var damage_block : float
@export_category("Stun")
@export var stun_hit : int
@export var stun_block : int
@export_category("Knockback")
@export var kback_hit : Vector3
@export var kback_block : Vector3
@export_category("Misc")
@export var hit_priority : int
@export var hit_type : String
@export var on_hit : Array
@export var on_block : Array

var marked := false

func _physics_process(_d):
	if lifetime > 0:
		lifetime -= 1
	if lifetime == 0 or marked:
		if not get_node_or_null(^"HitSound") and not get_node_or_null(^"BlockSound"):
			queue_free()
		else:
			if not $HitSound.playing and not $BlockSound.playing:
				queue_free()

func destroy():
	monitorable = false
	marked = true
