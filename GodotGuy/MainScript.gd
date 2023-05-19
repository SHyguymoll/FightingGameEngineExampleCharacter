class_name Fighter
extends CharacterBody3D

var fighter_name = "Godot Guy"
var tscn_file = "res://GodotGuy/scenes/GodotGuy.tscn"
var char_select_icon = "res://GodotGuy/Icon.png"

var input_buffer_len = 10

@export var health = 100
@export var walk_speed = 1

@export var gravity = -0.5
@export var min_fall_vel = -6.5

var distance = 0.0
var right_facing = true
var damage_mult = 1.0
var defense_mult = 1.0
var kback_hori = 0.0
var kback_vert = 0.0

var start_x_offset = 2
const BUTTONCOUNT = 4

#State transitions are handled by a FSM implemented as match statements
enum states {
	intro, round_win, set_win, #round stuff
	idle, crouch, #basic basics
	walk_forward, walk_back, #lateral movement
	jump_forward, jump_neutral, jump_back, #aerial movement
	attack, post_attack, #handling attacks
	block_high, block_low, get_up, #handling getting attacked well
	hurt_high, hurt_low, hurt_crouch, #not handling getting attacked well
	hurt_fall, hurt_lie, hurt_bounce, #REALLY not handling getting attacked well
	}
var state_current: states = states.idle

func update_state(new_state: states, new_animation_timer: int):
	state_current = new_state
	if new_animation_timer != -1:
		step_timer = new_animation_timer

# attack format:
#"<Name>":
#	{
#		"damage": <damage>,
#		"type": "<hit location>",
#		"kb_hori": <horizontal knockback value>,
#		"kb_vert": <vertical knockback value>,
#		"total_frame_length": <time value>,
#		"cancelable_after_frame": <frame number>,
#		"hitboxes": "<hitbox set name>",
#		"extra": ... This one is up to whatever
#	}

#TODO: attacks proper
var attacks = {
	"stand_a":
		{
			"damage": 3,
			"type": "mid",
			"kbHori": 0.2,
			"kbVert": 0.0,
			"total_frame_length": 4,
			"cancelable_after_frame": 3,
			"hitboxes": "" #TODO
		},
	"stand_b":
		{
			"damage": 4,
			"type": "mid",
			"kbHori": 0.6,
			"kbVert": 0.0,
			"total_frame_length": 6,
			"cancelable_after_frame": 5,
			"hitboxes": "" #TODO
		},
	"stand_c":
		{
			"damage": 4,
			"type": "mid",
			"kbHori": 0.6,
			"kbVert": 0.0,
			"total_frame_length": 11,
			"cancelable_after_frame": 8,
			"hitboxes": "" #TODO
		},
	"crouch_a": #TODO
		{
			"damage": 3,
			"type": "mid",
			"kbHori": 0.2,
			"kbVert": 0.0,
			"hitboxes": ""
		},
	"crouch_b": #TODO
		{
			"damage": 4,
			"type": "mid",
			"kbHori": 0.6,
			"kbVert": 0.0,
			"hitboxes": ""
		},
	"crouch_c": #TODO
		{
			"damage": 4,
			"type": "mid",
			"kbHori": 0.6,
			"kbVert": 0.0,
			"hitboxes": ""
		},
	"jump_a": #TODO
		{
			"damage": 3,
			"type": "mid",
			"kbHori": 0.2,
			"kbVert": 0.0,
			"hitboxes": ""
		},
	"jump_b": #TODO
		{
			"damage": 4,
			"type": "mid",
			"kbHori": 0.6,
			"kbVert": 0.0,
			"hitboxes": ""
		},
	"jump_c": #TODO
		{
			"damage": 4,
			"type": "mid",
			"kbHori": 0.6,
			"kbVert": 0.0,
			"hitboxes": ""
		},
}

var current_attack

func attack_ended() -> bool:
	return step_timer >= attacks[current_attack]["total_frame_length"]

#func attack_cancelable() -> bool:
#	return step_timer >= attacks[current_attack]["cancelable_after_frame"]

func update_attack(new_attack: String) -> void:
	current_attack = new_attack

# Animations are handled manually and controlled by the game engine during the physics_process step.
# Therefore, all animations top out at 60 FPS, which is a small constraint for now.
# animation format:
#"<Name>":
#	{
#		"animation_length": <value>,
#		<frame_number>: [<animation frame x>, <animation frame y>], ...,
#		"extra": ... This one is up to whatever
#	}

#TODO: animations proper
var animations = {
	"idle":
		{
			"animation_length": 1,
			0: [0,0],
		},
	"crouch":
		{
			"animation_length": 1,
			0: [1,0],
		},
	"walk_right":
		{
			"animation_length": 7,
			0: [2,0],
			1: [3,0],
			2: [4,0],
			3: [5,0],
			4: [6,0],
			5: [7,0],
			6: [8,0],
			7: [9,0]
			
		},
	"walk_left":
		{
			"animation_length": 7,
			0: [9,0],
			1: [8,0],
			2: [7,0],
			3: [6,0],
			4: [5,0],
			5: [4,0],
			6: [3,0],
			7: [2,0]
		},
	
	"stand_a":
		{
			"animation_length": 4,
			0: [6,1],
			2: [7,1],
			3: [8,1],
		},
	"stand_b":
		{
			"animation_length": 6,
			0: [4,2],
			2: [5,2],
			3: [6,2],
			4: [7,2],
			5: [8,2],
		},
	"stand_c":
		{
			"animation_length": 11,
			0: [0,4],
			2: [1,4],
			4: [2,4],
			5: [3,4],
			6: [4,4],
			9: [5,4],
			10: [6,4],
		},
	"crouch_a":
		{
			"animation_length": 5,
			0: [0,1],
			2: [1,1],
			3: [2,1],
		},
	"crouch_b":
		{
			"animation_length": 7,
			0: [0,2],
			2: [1,2],
			4: [2,2],
			5: [3,2],
		},
	"crouch_c":
		{
			"animation_length": 10,
			0: [0,3],
			1: [1,3],
			2: [2,3],
			5: [3,3],
			6: [4,3],
			7: [5,3],
			8: [6,3],
		},
	"jump_a": #TODO
		{
			"animation_length": 5,
			0: [0,1],
			2: [1,1],
			3: [2,1],
		},
	"jump_b": #TODO
		{
			"animation_length": 7,
			0: [0,2],
			2: [1,2],
			4: [2,2],
			5: [3,2],
		},
	"jump_c": #TODO
		{
			"animation_length": 10,
			0: [0,3],
			1: [1,3],
			2: [2,3],
			5: [3,3],
			6: [4,3],
			7: [5,3],
			8: [6,3],
		},
}

var current_animation: String
var step_timer = 0

func anim() -> void:
	if animations[current_animation][step_timer] != null:
		$Sprite.frame_coords = animations[current_animation][step_timer]

# Hitboxes and Hurtboxes are handled through a dictionary for easy reuse.
# box format:
#"<Name>":
#	{
#		"boxes": [<path>, ...],
#		"extra": ... This one is up to whatever
#	}

#TODO: hitboxes
var hitboxes = {
	"basic": {
		"boxes": [],
	}
}

#TODO: hurtboxes
var hurtboxes = {
	"basic": {
		"boxes": [],
	}
}

enum actions {set, add, remove}

func initialize_boxes(player: bool) -> void:
	if player:
		$Hurtboxes.collision_layer = 2
		$Hitboxes.collision_mask = 4
	else:
		$Hurtboxes.collision_layer = 4
		$Hitboxes.collision_mask = 2

func update_hitboxes(hitboxes: Array[String], action: actions) -> void:
	match action:
		actions.set:
			pass
	pass

var too_close : bool = false

enum inputs {Up = 1, Down = 2, Left = 4, Right = 8, A = 16, B = 32, C = 64}

func decode_hash(inputHash: int) -> Array:
	var decodedHash = [false, false, false, false, false, false, false, false]
	var inpVal = inputs.values()
	for i in range(BUTTONCOUNT + 3,-1,-1): #arrays start at 0, so everything is subtracted by 1 (4 directions -> 3)
		if inputHash >= inpVal[i]:
			inputHash -= inpVal[i]
			decodedHash[i] = true
	return decodedHash

func handle_attack(buffer: Array) -> void:
	var decoded_buffer = []
	for input in buffer:
		decoded_buffer.append([decode_hash(input[0]), input[1]])
	match state_current:
		states.idle, states.walk_back, states.walk_forward:
			if decoded_buffer[-1][0][4]:
				update_attack("stand_a")
			if decoded_buffer[-1][0][5]:
				update_attack("stand_b")
			if decoded_buffer[-1][0][6]:
				update_attack("stand_c")
		states.crouch:
			if decoded_buffer[-1][0][4]:
				update_attack("crouch_a")
			if decoded_buffer[-1][0][5]:
				update_attack("crouch_b")
			if decoded_buffer[-1][0][6]:
				update_attack("crouch_c")
		states.jump_neutral, states.jump_back, states.jump_forward:
			if decoded_buffer[-1][0][4]:
				update_attack("jump_a")
			if decoded_buffer[-1][0][5]:
				update_attack("jump_b")
			if decoded_buffer[-1][0][6]:
				update_attack("jump_c")
	update_state(states.attack, 0)

func walk_check(inputs: Array) -> int: #returns -1 (trying to walk away), 0 (no walking inputs), and 1 (trying to walk towards)
	return int(
		(inputs[3] and right_facing) or (inputs[2] and !right_facing)
		) + -1 * int(
			(inputs[2] and right_facing) or (inputs[3] and !right_facing)
			)

func handle_input(buffer: Array) -> void:
	var input = decode_hash(buffer[-1][0]) #end of buffer is newest button, first element is input hash
	var heldTime = buffer[-1][1]
	var walk = walk_check(input)
	match state_current:
		states.idle:
			match walk:
				1:
					if !too_close:
						update_state(states.walk_forward, 0)
				-1:
					if distance < 5:
						update_state(states.walk_back, 0)
			if (input[1]):
				update_state(states.crouch, 0)
			if (input[0]):
				match walk:
					1:
						update_state(states.jump_forward, 0)
					0:
						update_state(states.jump_neutral, 0)
					-1:
						update_state(states.jump_back, 0)
			if buffer[-1][0] >= inputs.Up + inputs.Down + inputs.Left + inputs.Right: #if any attack input is found in hash, do this block
				pass
				handle_attack(buffer)
		states.walk_forward:
			if walk != 1:
				match walk:
					0:
						update_state(states.idle, 0)
					-1:
						update_state(states.walk_back, 0)
			if (input[1]):
				update_state(states.crouch, 0)
			if (input[0]):
				match walk:
					1:
						update_state(states.jump_forward, 0)
					0:
						update_state(states.jump_neutral, 0)
					-1:
						update_state(states.jump_back, 0)
			if buffer[-1][0] >= inputs.Up + inputs.Down + inputs.Left + inputs.Right: #ditto
				pass
				handle_attack(buffer)
		states.walk_back:
			if walk != -1:
				match walk:
					1:
						update_state(states.walk_forward, 0)
					0:
						update_state(states.idle, 0)
			if (input[1]):
				update_state(states.crouch, 0)
			if (input[0]):
				match walk:
					1:
						update_state(states.jump_forward, 0)
					0:
						update_state(states.jump_neutral, 0)
					-1:
						update_state(states.jump_back, 0)
			if buffer[-1][0] >= inputs.Up + inputs.Down + inputs.Left + inputs.Right: #ditto
				pass
				handle_attack(buffer)
		states.attack:
			if attack_ended():
				match current_attack:
					"stand_a", "stand_b", "stand_c":
						update_state(states.idle, 0)
					"crouch_a", "crouch_b", "crouch_c":
						update_state(states.crouch, 0)
					"jump_a", "jump_b":
						update_state(states.idle, 0)
					"jump_c":
						update_state(states.jump_neutral, 0)

func action(inputs) -> void:
	handle_input(inputs)
	match state_current:
		states.idle:
			pass
#	match state_current:
#		states.Idle, states.Crouch:
#			velocity.x = 0
#		states.Walk_Forward:
#			velocity.x = (1 if rightFacing else -1) * walkSpeed
#		states.Walk_Back:
#			velocity.x = (-1 if rightFacing else 1) * walkSpeed
#			if tooClose:
#				velocity.x += (-1 if rightFacing else 1) * walkSpeed
#		states.Hurt_High, states.Hurt_Low, states.Hurt_Crouch, states.Block_High, states.Block_Low:
#			velocity.x += (-1 if rightFacing else 1) * knockbackHorizontal
#		states.Hurt_Fall:
#			velocity.x += (-1 if rightFacing else 1) * knockbackHorizontal
#			if animStep == 0:
#				velocity.y += knockbackVertical
#
#	velocity.y += GRAVITY
#	velocity.y = max(MIN_VEL, velocity.y)
#	if velocity.y < 0 and is_on_floor():
#		velocity.y = 0
#
#	set_velocity(velocity)
#	set_up_direction(Vector3.UP)
#	move_and_slide()

func distance_check_enter(_area):
	too_close = true

func distance_check_exit(area):
	too_close = false
	print(area)

func step(inputs) -> void:
	action(inputs)
	anim()
	step_timer += 1
