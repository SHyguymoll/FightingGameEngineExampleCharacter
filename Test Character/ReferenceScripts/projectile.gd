class_name Projectile
extends CharacterBody3D

signal projectile_ended(proj)

@export var hitbox : Hitbox
var right_facing : bool
var type : int
var source : int

func _ready():
	pass

func tick():
	pass

func destroy():
	if hitbox != null:
		hitbox.queue_free()
	velocity = Vector3.ZERO

func _on_projectile_contact(other):
	if hitbox == null:
		return
	var o_par = other.get_parent()
	if other is Stage or o_par is Stage:
		destroy()
	if o_par is Projectile:
		if o_par.hitbox == null:
			return
		if source != o_par.source and hitbox.hit_priority <= o_par.hitbox.hit_priority:
			destroy()
