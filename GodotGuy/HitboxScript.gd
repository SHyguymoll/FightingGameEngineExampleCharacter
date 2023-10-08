extends Area3D

# This script controls hitboxes.
# It is functionally similar to HurtboxScript.gd, but the separation makes it easier to parse.

var active_hitboxes = []

enum actions {set = 0, add = 1, remove = -1}

func update_hitboxes(new_hitboxes: Array[String], choice: actions) -> void:
	match choice:
		actions.set:
			for hitbox in active_hitboxes:
				(get_node(hitbox) as CollisionShape3D).disabled = true
				get_node(hitbox).visible = false
			for new_hitbox in new_hitboxes:
				(get_node(new_hitbox) as CollisionShape3D).disabled = false
				active_hitboxes.append(new_hitbox)
				get_node(new_hitbox).visible = true
		actions.add:
			for new_hitbox in new_hitboxes:
				(get_node(new_hitbox) as CollisionShape3D).disabled = false
				active_hitboxes.append(new_hitbox)
				get_node(new_hitbox).visible = true
		actions.remove:
			for new_hitbox in new_hitboxes:
				(get_node(new_hitbox) as CollisionShape3D).disabled = true
				active_hitboxes.erase(new_hitbox)
				get_node(new_hitbox).visible = false
