class_name Fighter
extends CharacterBody3D

@export var char_name : String = "Godot Guy"
@export var health : float = 100
@export var walk_speed : float = 1
@export var jump_total : int = 1
@export var jump_height : float = 10
@export var gravity : float = -0.5
@export var min_fall_vel : float = -6.5

var input_buffer_len : int = 10

var distance : float = 0.0
var right_facing : bool = true
var damage_mult : float = 1.0
var defense_mult : float = 1.0
var kback_hori : float = 0.0
var kback_vert : float = 0.0
var jump_count : int = 0
var last_used_upward_index : int = -1
var current_index : int = -1

var start_x_offset : float = 2
const BUTTONCOUNT : int = 3

#State transitions are handled by a FSM implemented as match statements
enum states {
	intro, round_win, set_win, #round stuff
	idle, crouch, #basic basics
	walk_forward, walk_back, #lateral movement
	jump_forward, jump_neutral, jump_back, #aerial movement
	attack, post_attack, #handling attacks
	block_high, block_low, block_air, get_up, #handling getting attacked well
	hurt_high, hurt_low, hurt_crouch, #not handling getting attacked well
	hurt_fall, hurt_lie, hurt_bounce, #REALLY not handling getting attacked well
	}
var state_start := states.idle
var current_state: states

func update_state(new_state: states, new_animation_timer: int):
	current_state = new_state
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
			"hitboxes": "stand_a"
		},
	"stand_b":
		{
			"damage": 4,
			"type": "mid",
			"kbHori": 0.6,
			"kbVert": 0.0,
			"total_frame_length": 6,
			"cancelable_after_frame": 5,
			"hitboxes": "stand_b"
		},
	"stand_c":
		{
			"damage": 4,
			"type": "mid",
			"kbHori": 0.6,
			"kbVert": 0.0,
			"total_frame_length": 11,
			"cancelable_after_frame": 8,
			"hitboxes": "stand_c"
		},
	"crouch_a": #TODO
		{
			"damage": 3,
			"type": "mid",
			"kbHori": 0.2,
			"kbVert": 0.0,
			"hitboxes": "crouch_a"
		},
	"crouch_b": #TODO
		{
			"damage": 4,
			"type": "mid",
			"kbHori": 0.6,
			"kbVert": 0.0,
			"hitboxes": "crouch_b"
		},
	"crouch_c": #TODO
		{
			"damage": 4,
			"type": "mid",
			"kbHori": 0.6,
			"kbVert": 0.0,
			"hitboxes": "crouch_c"
		},
	"jump_a": #TODO
		{
			"damage": 3,
			"type": "mid",
			"kbHori": 0.2,
			"kbVert": 0.0,
			"hitboxes": "jump_a"
		},
	"jump_b": #TODO
		{
			"damage": 4,
			"type": "mid",
			"kbHori": 0.6,
			"kbVert": 0.0,
			"hitboxes": "jump_b"
		},
	"jump_c": #TODO
		{
			"damage": 4,
			"type": "mid",
			"kbHori": 0.6,
			"kbVert": 0.0,
			"hitboxes": "jump_c"
		},
}

var current_attack : String

func basic_attack_ended() -> bool:
	return step_timer >= attacks[current_attack]["total_frame_length"]

func ground_cancelled_attack_ended() -> bool:
	return is_on_floor()

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
	"jump_a": #TODO
		{
			"animation_length": 5,
			0: Vector2i(0,1),
			2: Vector2i(1,1),
			3: Vector2i(2,1),
		},
	"jump_b": #TODO
		{
			"animation_length": 7,
			0: Vector2i(0,2),
			2: Vector2i(1,2),
			4: Vector2i(2,2),
			5: Vector2i(3,2),
		},
	"jump_c": #TODO
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
}

var current_animation: String
var step_timer : int = 0

func animation_ended() -> bool:
	return step_timer >= animations[current_animation]["animation_length"]

func anim() -> void:
	$Sprite.frame_coords = animations[current_animation].get(step_timer, $Sprite.frame_coords)

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

func initialize_boxes(player: bool) -> void:
	if player:
		$Hurtboxes.collision_layer = 2
		$Hitboxes.collision_mask = 4
	else:
		$Hurtboxes.collision_layer = 4
		$Hitboxes.collision_mask = 2

func update_hitboxes(new_hitboxes: Array[String], choice: actions) -> void:
	match choice:
		actions.set:
			for hitbox in hitboxes:
				for box in hitboxes[hitbox]["boxes"]:
					(get_node("Hitboxes/{0}".format([box])) as CollisionShape3D).disabled = true
			for new_hitbox in new_hitboxes:
				for box in hitboxes[new_hitbox]["boxes"]:
					(get_node("Hitboxes/{0}".format([box])) as CollisionShape3D).disabled = false
		actions.add:
			for new_hitbox in new_hitboxes:
				for box in hitboxes[new_hitbox]["boxes"]:
					(get_node("Hitboxes/{0}".format([box])) as CollisionShape3D).disabled = false
		actions.remove:
			for new_hitbox in new_hitboxes:
				for box in hitboxes[new_hitbox]["boxes"]:
					(get_node("Hitboxes/{0}".format([box])) as CollisionShape3D).disabled = true

func update_hurtboxes(new_hurtboxes: Array[String], choice: actions) -> void:
	match choice:
		actions.set:
			for hurtbox in hurtboxes:
				for box in hurtboxes[hurtbox]["boxes"]:
					(get_node("hurtboxes/{0}".format([box])) as CollisionShape3D).disabled = true
			for new_hurtbox in new_hurtboxes:
				for box in hurtboxes[new_hurtbox]["boxes"]:
					(get_node("hurtboxes/{0}".format([box])) as CollisionShape3D).disabled = false
		actions.add:
			for new_hurtbox in new_hurtboxes:
				for box in hurtboxes[new_hurtbox]["boxes"]:
					(get_node("hurtboxes/{0}".format([box])) as CollisionShape3D).disabled = false
		actions.remove:
			for new_hurtbox in new_hurtboxes:
				for box in hurtboxes[new_hurtbox]["boxes"]:
					(get_node("hurtboxes/{0}".format([box])) as CollisionShape3D).disabled = true

var too_close : bool = false

enum buttons {Up = 1, Down = 2, Left = 4, Right = 8, A = 16, B = 32, C = 64}

func decode_hash(inputHash: int) -> Array:
	var decodedHash = [false, false, false, false, false, false, false, false]
	var inpVal = buttons.values()
	for i in range(BUTTONCOUNT + 3,-1,-1): #arrays start at 0, so everything is subtracted by 1 (4 directions -> 3)
		if inputHash >= inpVal[i]:
			inputHash -= inpVal[i]
			decodedHash[i] = true
	return decodedHash

func handle_attack(buffer: Array) -> Array:
	if buffer[-1][0] < buttons.Up + buttons.Down + buttons.Left + buttons.Right:
		return [current_state, step_timer]
	var decoded_buffer = []
	for input in buffer:
		decoded_buffer.append([decode_hash(input[0]), input[1]])
	var decision_timer = step_timer
	match current_state:
		states.idle, states.walk_back, states.walk_forward:
			if decoded_buffer[-1][0][4]:
				update_attack("stand_a")
				decision_timer = 0
			if decoded_buffer[-1][0][5]:
				update_attack("stand_b")
				decision_timer = 0
			if decoded_buffer[-1][0][6]:
				update_attack("stand_c")
				decision_timer = 0
		states.crouch:
			if decoded_buffer[-1][0][4]:
				update_attack("crouch_a")
				decision_timer = 0
			if decoded_buffer[-1][0][5]:
				update_attack("crouch_b")
				decision_timer = 0
			if decoded_buffer[-1][0][6]:
				update_attack("crouch_c")
				decision_timer = 0
		states.jump_neutral, states.jump_back, states.jump_forward:
			if decoded_buffer[-1][0][4]:
				update_attack("jump_a")
				decision_timer = 0
			if decoded_buffer[-1][0][5]:
				update_attack("jump_b")
				decision_timer = 0
			if decoded_buffer[-1][0][6]:
				update_attack("jump_c")
				decision_timer = 0
	return [states.attack, decision_timer]

func walk_value(input: Array) -> int: #returns -1 (trying to walk away), 0 (no walking inputs), and 1 (trying to walk towards)
	return int(
		(input[3] and right_facing) or (input[2] and !right_facing)
		) + -1 * int(
			(input[2] and right_facing) or (input[3] and !right_facing)
			)

enum walk_directions {
	back = -1,
	neutral = 0,
	forward = 1,
	none = 2
}
func walk_check(input : Array, exclude: walk_directions) -> Array:
	var walk = walk_value(input)
	if walk == exclude:
		return [current_state, step_timer]
	match walk:
		walk_directions.forward:
			if !too_close:
				return [states.walk_forward, 0]
		walk_directions.neutral:
			return [states.idle, 0]
		walk_directions.back:
			if distance < 5:
				return [states.walk_back, 0]
	return [current_state, step_timer]

func jump_check(input: Array) -> Array:
	if (input[0]):
		match walk_value(input):
			1:
				return [states.jump_forward, 0]
			0:
				return [states.jump_neutral, 0]
			-1:
				return [states.jump_back, 0]
		return [current_state, step_timer]
	else:
		return [current_state, step_timer]

func handle_input(buffer: Array) -> void:
	var input = decode_hash(buffer[-1][0]) #end of buffer is newest button, first element is input hash
	var held_time = buffer[-1][1]
	var decision := current_state
	var decision_timer := step_timer
	
	var walk_decision
	var jump_decision
	var attack_decision
	match current_state:
		states.idle:
			walk_decision = walk_check(input, walk_directions.neutral)
			if walk_decision != [current_state, step_timer]:
				decision = walk_decision[0]
				decision_timer = walk_decision[1]
			if (input[1]):
				decision = states.crouch
				decision_timer = 0
			jump_decision = jump_check(input)
			if jump_decision != [current_state, step_timer]:
				decision = jump_decision[0]
				decision_timer = jump_decision[1]
			attack_decision = handle_attack(buffer)
			if attack_decision != [current_state, step_timer]:
				decision = attack_decision[0]
				decision_timer = attack_decision[1]
		states.crouch:
			if !input[1]:
				walk_decision = walk_check(input, walk_directions.none)
				decision = walk_decision[0]
				decision_timer = walk_decision[1]
		states.walk_forward:
			walk_decision = walk_check(input, walk_directions.forward)
			if walk_decision != [current_state, step_timer]:
				decision = walk_decision[0]
				decision_timer = walk_decision[1]
			if (input[1]):
				decision = states.crouch
				decision_timer = 0
			jump_decision = jump_check(input)
			if jump_decision != [current_state, step_timer]:
				decision = jump_decision[0]
				decision_timer = jump_decision[1]
			attack_decision = handle_attack(buffer)
			if attack_decision != [current_state, step_timer]:
				decision = attack_decision[0]
				decision_timer = attack_decision[1]
		states.walk_back:
			walk_decision = walk_check(input, walk_directions.back)
			if walk_decision != [current_state, step_timer]:
				decision = walk_decision[0]
				decision_timer = walk_decision[1]
			if (input[1]):
				decision = states.crouch
				decision_timer = 0
			jump_decision = jump_check(input)
			if jump_decision != [current_state, step_timer]:
				decision = jump_decision[0]
				decision_timer = jump_decision[1]
			attack_decision = handle_attack(buffer)
			if attack_decision != [current_state, step_timer]:
				decision = attack_decision[0]
				decision_timer = attack_decision[1]
		states.attack:
			if basic_attack_ended(): #Lasts as long as its animation
				match current_attack:
					"stand_a", "stand_b", "stand_c":
						decision = states.idle
						decision_timer = 0
					"crouch_a", "crouch_b", "crouch_c":
						decision = states.crouch
						decision_timer = 0
					"jump_c":
						decision = states.jump_neutral
						decision_timer = 0
			if ground_cancelled_attack_ended(): #Ends when the character hits the ground
				match current_attack:
					"jump_a", "jump_b":
						decision = states.idle
						decision_timer = 0
	update_state(decision, decision_timer)

func attempt_animation_reset():
	if animation_ended():
		step_timer = 0

func action(inputs) -> void:
	current_index = inputs[-1][2]
	handle_input(inputs)
	match current_state:
		states.idle:
			current_animation = "idle"
			velocity.x = 0
			jump_count = jump_total
			attempt_animation_reset()
		states.crouch:
			current_animation = "crouch"
			velocity.x = 0
			jump_count = jump_total
			attempt_animation_reset()
		states.walk_forward:
			if right_facing:
				current_animation = "walk_right"
			else:
				current_animation = "walk_left"
			jump_count = jump_total
			attempt_animation_reset()
			velocity.x = (1 if right_facing else -1) * walk_speed
		states.walk_back:
			if right_facing:
				current_animation = "walk_left"
			else:
				current_animation = "walk_right"
			jump_count = jump_total
			attempt_animation_reset()
			velocity.x = (-1 if right_facing else 1) * walk_speed
			if too_close:
				velocity.x += (-1 if right_facing else 1) * walk_speed
		states.jump_forward, states.jump_back, states.jump_neutral:
			if jump_count > 0 and last_used_upward_index != current_index:
				jump_count -= 1
				last_used_upward_index = current_index
				velocity.y += jump_height
#		states.Hurt_High, states.Hurt_Low, states.Hurt_Crouch, states.Block_High, states.Block_Low:
#			velocity.x += (-1 if right_facing else 1) * knockbackHorizontal
#		states.Hurt_Fall:
#			velocity.x += (-1 if right_facing else 1) * knockbackHorizontal
#			if animStep == 0:
#				velocity.y += knockbackVertical
#		states.hurt_fall, states.jump_forward, states.jump_neutral, states.jump_back, states.block_air:
	velocity.y += gravity
	velocity.y = max(min_fall_vel, velocity.y)
	if velocity.y < 0 and is_on_floor():
		velocity.y = 0
	move_and_slide()
	match current_state:
		states.jump_forward, states.jump_back, states.jump_neutral:
			if is_on_floor():
				var new_walk = walk_check(decode_hash(inputs[-1][0]), walk_directions.none)
				update_state(new_walk[0], new_walk[1])

func distance_check_enter(_area):
	too_close = true

func distance_check_exit(area):
	too_close = false
	print(area)

func step(inputs) -> void:
	action(inputs)
	anim()
	step_timer += 1
