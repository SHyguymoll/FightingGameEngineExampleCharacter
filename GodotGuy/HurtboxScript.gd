extends Area3D

# This script controls hurtboxes.
# It is functionally similar to HitboxScript.gd, but the separation makes it easier to parse.


# Hitboxes and Hurtboxes are handled through a dictionary for easy reuse.
# box format:
#"<Name>":
#	{
#		"boxes": [<path>, ...],
#		"extra": ... This one is up to whatever
#	}

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

enum actions {set, add, remove}

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
