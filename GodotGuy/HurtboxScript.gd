extends Area3D

enum actions {set, add, remove}

var hurtboxes : Dictionary = {
	"base": {
		"boxes": ["Base"],
	},
	"low": {
		"boxes": ["Low"],
	},
	"pull_back": {
		"boxes": ["StandBPullBack"],
	},
	"pop_up": {
		"boxes": ["JumpCPopUp"],
	},
}

func update_hurtboxes(new_hurtboxes: Array[String], choice: actions) -> void:
	match choice:
		actions.set:
			for hurtbox in hurtboxes:
				for box in hurtboxes[hurtbox]["boxes"]:
					(get_node(box) as CollisionShape3D).disabled = true
			for new_hurtbox in new_hurtboxes:
				for box in hurtboxes[new_hurtbox]["boxes"]:
					(get_node(box) as CollisionShape3D).disabled = false
		actions.add:
			for new_hurtbox in new_hurtboxes:
				for box in hurtboxes[new_hurtbox]["boxes"]:
					(get_node(box) as CollisionShape3D).disabled = false
		actions.remove:
			for new_hurtbox in new_hurtboxes:
				for box in hurtboxes[new_hurtbox]["boxes"]:
					(get_node(box) as CollisionShape3D).disabled = true
