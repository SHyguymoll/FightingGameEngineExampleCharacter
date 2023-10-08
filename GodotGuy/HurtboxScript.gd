extends Area3D

# This script controls hurtboxes.
# It is functionally similar to HitboxScript.gd, but the separation makes it easier to parse.

var active_hurtboxes = []

enum actions {set = 0, add = 1, remove = -1}

func update_hurtboxes(new_hurtboxes: Array[String], choice: actions) -> void:
	match choice:
		actions.set:
			for hurtbox in active_hurtboxes:
				(get_node(hurtbox) as CollisionShape3D).disabled = true
				get_node(hurtbox).visible = false
			for new_hurtbox in new_hurtboxes:
				(get_node(new_hurtbox) as CollisionShape3D).disabled = false
				active_hurtboxes.append(new_hurtbox)
				get_node(new_hurtbox).visible = true
		actions.add:
			for new_hurtbox in new_hurtboxes:
				(get_node(new_hurtbox) as CollisionShape3D).disabled = false
				active_hurtboxes.append(new_hurtbox)
				get_node(new_hurtbox).visible = true
		actions.remove:
			for new_hurtbox in new_hurtboxes:
				(get_node(new_hurtbox) as CollisionShape3D).disabled = true
				active_hurtboxes.erase(new_hurtbox)
				get_node(new_hurtbox).visible = false
