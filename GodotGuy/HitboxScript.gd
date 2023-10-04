extends Area3D

# Hitboxes and Hurtboxes are handled through a dictionary for easy reuse.
# box format:
#"<Name>":
#	{
#		"boxes": [<path>, ...],
#		"extra": ... This one is up to whatever
#	}

var hitboxes : Dictionary = {
	"stand_a": {
		"boxes": ["StandA"],
	},
	"stand_b": {
		"boxes": ["StandB"],
	},
	"stand_c": {
		"boxes": ["StandC"],
	},
	"crouch_a": {
		"boxes": ["CrouchA"],
	},
	"crouch_b": {
		"boxes": ["CrouchB"],
	},
	"crouch_c": {
		"boxes": ["CrouchC"],
	},
	"jump_a": {
		"boxes": ["JumpA"],
	},
	"jump_b": {
		"boxes": ["JumpB"],
	},
	"jump_c": {
		"boxes": ["JumpC"],
	},
}

enum actions {set, add, remove}

func update_hitboxes(new_hitboxes: Array[String], choice: actions) -> void:
	match choice:
		actions.set:
			for hitbox in hitboxes:
				for box in hitboxes[hitbox]["boxes"]:
					(get_node(box) as CollisionShape3D).disabled = true
			for new_hitbox in new_hitboxes:
				for box in hitboxes[new_hitbox]["boxes"]:
					(get_node(box) as CollisionShape3D).disabled = false
		actions.add:
			for new_hitbox in new_hitboxes:
				for box in hitboxes[new_hitbox]["boxes"]:
					(get_node(box) as CollisionShape3D).disabled = false
		actions.remove:
			for new_hitbox in new_hitboxes:
				for box in hitboxes[new_hitbox]["boxes"]:
					(get_node(box) as CollisionShape3D).disabled = true
