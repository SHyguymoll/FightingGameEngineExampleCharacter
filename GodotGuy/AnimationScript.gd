extends Sprite3D

# For Sprites, Animations are handled manually and controlled by the game engine
# during the physics_process step.
# Therefore, all animations top out at 60 FPS, which is a small constraint for now.
# animation format:
#"<Name>":
#	{
#		"animation_length": <value>,
#		<frame_number>: [<animation frame x>, <animation frame y>], ...,
#		"extra": ... This one is up to whatever
#	}

#TODO: animations proper
var animations : Dictionary = {
	"idle":
		{
			"animation_length": 1,
			0: Vector2i(0,0),
		},
	"crouch":
		{
			"animation_length": 1,
			0: Vector2i(1,0),
		},
	"walk_right":
		{
			"animation_length": 39,
			0: Vector2i(2,0),
			4: Vector2i(3,0),
			9: Vector2i(4,0),
			14: Vector2i(5,0),
			19: Vector2i(6,0),
			24: Vector2i(7,0),
			29: Vector2i(8,0),
			34: Vector2i(0,0)
		},
	"walk_left":
		{
			"animation_length": 39,
			0: Vector2i(0,0),
			4: Vector2i(8,0),
			9: Vector2i(7,0),
			14: Vector2i(6,0),
			19: Vector2i(5,0),
			24: Vector2i(4,0),
			29: Vector2i(3,0),
			34: Vector2i(2,0)
		},
	"jump":
		{
			"animation_length": 1,
			0: Vector2i(0,0),
		},
	"stand_a":
		{
			"animation_length": 4,
			0: Vector2i(6,1),
			2: Vector2i(7,1),
			3: Vector2i(8,1),
		},
	"stand_b":
		{
			"animation_length": 6,
			0: Vector2i(4,2),
			2: Vector2i(5,2),
			3: Vector2i(6,2),
			4: Vector2i(7,2),
			5: Vector2i(8,2),
		},
	"stand_c":
		{
			"animation_length": 11,
			0: Vector2i(0,4),
			2: Vector2i(1,4),
			4: Vector2i(2,4),
			5: Vector2i(3,4),
			6: Vector2i(4,4),
			9: Vector2i(5,4),
			10: Vector2i(6,4),
		},
	"crouch_a":
		{
			"animation_length": 5,
			0: Vector2i(0,1),
			2: Vector2i(1,1),
			3: Vector2i(2,1),
		},
	"crouch_b":
		{
			"animation_length": 7,
			0: Vector2i(0,2),
			2: Vector2i(1,2),
			4: Vector2i(2,2),
			5: Vector2i(3,2),
		},
	"crouch_c":
		{
			"animation_length": 10,
			0: Vector2i(0,3),
			1: Vector2i(1,3),
			2: Vector2i(2,3),
			5: Vector2i(3,3),
			6: Vector2i(4,3),
			7: Vector2i(5,3),
			8: Vector2i(6,3),
		},
	"jump_a":
		{
			"animation_length": 1,
			0: Vector2i(3,1),
		},
	"jump_b":
		{
			"animation_length": 8,
			0: Vector2i(4,1),
			3: Vector2i(5,1),
		},
	"jump_c":
		{
			"animation_length": 15,
			0: Vector2i(0,5),
			3: Vector2i(1,5),
			7: Vector2i(2,5),
			8: Vector2i(3,5),
			12: Vector2i(0,0),
		},
	"block_high":
		{
			"animation_length": 1,
			0: Vector2i(7,3),
		},
	"block_low":
		{
			"animation_length": 1,
			0: Vector2i(8,3),
		},
	"block_air":
		{
			"animation_length": 1,
			0: Vector2i(7,3),
		},
	"hurt_high":
		{
			"animation_length": 1,
			0: Vector2i(7,4),
		},
	"hurt_low":
		{
			"animation_length": 1,
			0: Vector2i(8,4),
		},
	"hurt_crouch":
		{
			"animation_length": 1,
			0: Vector2i(7,5),
		},
	"hurt_fall":
		{
			"animation_length": 1,
			0: Vector2i(5,5),
		},
	"hurt_lie":
		{
			"animation_length": 1,
			0: Vector2i(6,5),
		},
	"get_up":
		{
			"animation_length": 15,
			0: Vector2i(5,5),
			7: Vector2i(8,0),
			14: Vector2i(0,0),
		},
}

var current_animation: String

func animation_ended(current_step) -> bool:
	return current_step >= animations[current_animation]["animation_length"]

func anim(current_step) -> void:
	frame_coords = (animations[current_animation] as Dictionary).get(current_step, frame_coords)
