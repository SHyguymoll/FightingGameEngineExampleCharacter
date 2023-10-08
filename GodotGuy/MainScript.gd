class_name Fighter
extends CharacterBody3D

# This script holds the main components of a Fighter, namely the attacks and state machine.
# A Fighter has several variables and methods which are accessed and called by the game.
# input_step() is called with the latest buffer of inputs
# damage_step() is called with the details of the attack, if it happened

@export var char_name : String = "Godot Guy"
@export var health : float = 100
@export var walk_speed : float = 2
@export var jump_total : int = 2
@export var jump_height : float = 11
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
var stun_time_start : int = 0
var stun_time_current : int = 0

@export var attack_ended = true

var start_x_offset : float = 2
const BUTTONCOUNT : int = 3
const JUST_PRESSED_BUFFER : int = 2
const GROUND_SLIDE_FRICTION : float = 0.97

#State transitions are handled by a FSM implemented as match statements
enum states {
	intro, round_win, set_win, #round stuff
	idle, crouch, #basic basics
	walk_forward, walk_back, #lateral movement
	jump_forward, jump_neutral, jump_back, #aerial movement
	attack, attack_command, jump_attack, special_attack, #handling attacks
	block_high, block_low, block_air, get_up, #handling getting attacked well
	hurt_high, hurt_low, hurt_crouch, #not handling getting attacked well
	hurt_fall, hurt_lie, hurt_bounce, #REALLY not handling getting attacked well
	}
var state_start := states.idle
var current_state: states

func update_state(new_state: states):
	current_state = new_state

# attack format:
#"<Name>":
#	{
#		"damage": <damage>,
#		"type": "<hit location>",
#		"stun_time": <time value>,
#		"priority": <priority value>,
#		"kb_hori": <horizontal knockback value>,
#		"kb_vert": <vertical knockback value>,
#		"total_frame_length": <time value>,
#		"cancelable_after_frame": <frame number>,
#		"hitboxes": "<hitbox set name>",
#		"extra": ... This one is up to whatever
#	}

#TODO: attacks proper
var attacks = {
	"attack_normal/stand_a":
		{
			"damage": 3,
			"damage_block": 0,
			"type": "mid",
			"stun_time": 10,
			"stun_time_block": 4,
			"priority": 2,
			"kbHori": 0.2,
			"kbVert": 0.0,
			"kbHori_block": 0.1,
			"kbVert_block": 0.0
		},
	"attack_normal/stand_b":
		{
			"damage": 4,
			"damage_block": 0,
			"type": "mid",
			"stun_time": 7,
			"stun_time_block": 7,
			"priority": 1,
			"kbHori": 0.6,
			"kbVert": 0.0,
			"kbHori_block": -0.15,
			"kbVert_block": 0.0
		},
	"attack_normal/stand_c":
		{
			"damage": 8,
			"damage_block": 2,
			"type": "mid",
			"stun_time": 25,
			"stun_time_block": 2,
			"priority": 1,
			"kbHori": 0.6,
			"kbVert": 0.0,
			"kbHori_block": 1,
			"kbVert_block": 0.0
		},
	"attack_command/crouch_a":
		{
			"damage": 3,
			"damage_block": 0,
			"type": "low",
			"stun_time": 5,
			"stun_time_block": 4,
			"priority": 1,
			"kbHori": 0.05,
			"kbVert": 0.0,
			"kbHori_block": 0.3,
			"kbVert_block": 0.0
		},
	"attack_command/crouch_b":
		{
			"damage": 8,
			"damage_block": 3,
			"type": "mid",
			"stun_time": 16,
			"stun_time_block": 8,
			"priority": 1,
			"kbHori": 0.6,
			"kbVert": 0.0,
			"kbHori_block": 1,
			"kbVert_block": 0.0
		},
	"attack_command/crouch_c":
		{
			"damage": 15,
			"damage_block": 5,
			"type": "mid",
			"stun_time": 60,
			"stun_time_block": 30,
			"priority": 1,
			"kbHori": 0.0,
			"kbVert": 4,
			"kbHori_block": 2,
			"kbVert_block": 0.0
		},
	"attack_jumping/a":
		{
			"damage": 15,
			"damage_block": 5,
			"type": "mid",
			"stun_time": 60,
			"stun_time_block": 30,
			"priority": 1,
			"kbHori": 0.0,
			"kbVert": 4,
			"kbHori_block": 2,
			"kbVert_block": 0.0
		},
	"attack_jumping/b":
		{
			"damage": 15,
			"damage_block": 5,
			"type": "mid",
			"stun_time": 60,
			"stun_time_block": 30,
			"priority": 1,
			"kbHori": 0.0,
			"kbVert": 4,
			"kbHori_block": 2,
			"kbVert_block": 0.0
		},
	"attack_jumping/c":
		{
			"damage": 15,
			"damage_block": 5,
			"type": "high",
			"stun_time": 60,
			"stun_time_block": 30,
			"priority": 1,
			"kbHori": 0.0,
			"kbVert": 4,
			"kbHori_block": 2,
			"kbVert_block": 0.0
		},
}

var current_attack : String

func ground_cancelled_attack_ended() -> bool:
	return is_on_floor()

func update_attack(new_attack: String) -> void:
	current_attack = new_attack
	attack_ended = false

enum actions {set, add, remove}

func initialize_boxes(player: bool) -> void:
	if player:
		$Hurtboxes.collision_layer = 2
		$Hitboxes.collision_mask = 4
	else:
		$Hurtboxes.collision_layer = 4
		$Hitboxes.collision_mask = 2

enum buttons {Up = 1, Down = 2, Left = 4, Right = 8, A = 16, B = 32, C = 64}

func button_pressed(inputs: Dictionary, input: String):
	return inputs[input][-1][1]

func button_just_pressed(inputs: Dictionary, input: String):
	return inputs[input][-1][0] < JUST_PRESSED_BUFFER and inputs[input][-1][1]

func button_held(inputs: Dictionary, input: String, length: int):
	return inputs[input][-1][0] >= length and inputs[input][-1][1]

func handle_attack(buffer: Dictionary) -> states:
	if (
		!button_pressed(buffer, "button0") and
		!button_pressed(buffer, "button1") and
		!button_pressed(buffer, "button2")
		):
		return current_state
	match current_state:
		states.idle, states.walk_back, states.walk_forward:
			if button_just_pressed(buffer, "button0"):
				update_attack("attack_normal/stand_a")
			if button_just_pressed(buffer, "button1"):
				update_attack("attack_normal/stand_b")
			if button_just_pressed(buffer, "button2"):
				update_attack("attack_normal/stand_c")
		states.crouch:
			if button_just_pressed(buffer, "button0"):
				update_attack("attack_command/crouch_a")
			if button_just_pressed(buffer, "button1"):
				update_attack("attack_command/crouch_b")
			if button_just_pressed(buffer, "button2"):
				update_attack("attack_command/crouch_c")
	return states.attack

func handle_jump_attack(buffer: Dictionary) -> states:
	if (
		!button_just_pressed(buffer, "button0") and
		!button_just_pressed(buffer, "button1") and
		!button_just_pressed(buffer, "button2")
		):
		return current_state
	match current_state:
		states.jump_neutral, states.jump_back, states.jump_forward:
			if button_just_pressed(buffer, "button0"):
				update_attack("attack_jumping/a")
			if button_just_pressed(buffer, "button1"):
				update_attack("attack_jumping/b")
			if button_just_pressed(buffer, "button2"):
				update_attack("attack_jumping/c")
	return states.jump_attack

#returns -1 (walk away), 0 (neutral), and 1 (walk towards)
func walk_value(input: Dictionary) -> int:
	return int((button_pressed(input, "right") and right_facing) or (button_pressed(input, "left") and !right_facing)) +\
		-1 * int((button_pressed(input, "left") and right_facing) or (button_pressed(input, "right") and !right_facing))

enum walk_directions {
	back = -1,
	neutral = 0,
	forward = 1,
	none = 2
}

func walk_check(input : Dictionary, exclude: walk_directions) -> states:
	var walk = walk_value(input)
	if walk != exclude:
		match walk:
			walk_directions.forward:
				return states.walk_forward
			walk_directions.neutral:
				return states.idle
			walk_directions.back:
				if distance < 5:
					return states.walk_back
	return current_state

func jump_check(input: Dictionary, exclude: walk_directions) -> states:
	if button_just_pressed(input, "up") and jump_count > 0:
		var dir = walk_value(input)
		if dir != exclude:
			match dir:
				walk_directions.forward:
					return states.jump_forward
				walk_directions.neutral:
					return states.jump_neutral
				walk_directions.back:
					return states.jump_back
	return current_state

func is_in_air_state() -> bool:
	return current_state in [states.jump_attack, states.jump_back, states.jump_neutral, states.jump_forward, states.block_air, states.hurt_bounce, states.hurt_fall]

func is_in_crouch_state() -> bool:
	return current_state in [states.crouch, states.hurt_crouch, states.block_low]

func slice_input_dictionary(input_dict: Dictionary, from: int, to: int):
	var ret_dict = {
		up=input_dict["up"].slice(from, to),
		down=input_dict["down"].slice(from, to),
		left=input_dict["left"].slice(from, to),
		right=input_dict["right"].slice(from, to),
	}
	var ret_dict_button_count = len(input_dict) - 4
	for i in range(ret_dict_button_count):
		ret_dict["button" + str(i)] = input_dict["button" + str(i)].slice(from, to)
	return ret_dict

func handle_input(buffer: Dictionary) -> void:
	var input = slice_input_dictionary(buffer, len(buffer.up) - 1, len(buffer.up))
	var decision : states = current_state
	
	var walk_decision
	var jump_decision
	var attack_decision
	match current_state:
		states.idle, states.walk_back, states.walk_forward:
			match current_state:
				states.idle:
					walk_decision = walk_check(input, walk_directions.neutral)
				states.walk_back:
					walk_decision = walk_check(input, walk_directions.back)
				states.walk_forward:
					walk_decision = walk_check(input, walk_directions.forward)
			if walk_decision != current_state:
				decision = walk_decision
			if button_pressed(input, "down"):
				decision = states.crouch
			jump_decision = jump_check(input, walk_directions.none)
			if jump_decision != current_state:
				decision = jump_decision
			attack_decision = handle_attack(buffer)
			if attack_decision != current_state:
				decision = attack_decision
		states.crouch:
			if !button_pressed(input, "down"):
				decision = walk_check(input, walk_directions.none)
			attack_decision = handle_attack(buffer)
			if attack_decision != current_state:
				decision = attack_decision
		states.jump_neutral, states.jump_back, states.jump_forward:
			jump_decision = jump_check(input, walk_directions.none)
			if jump_decision != current_state:
				decision = jump_decision
			attack_decision = handle_jump_attack(buffer)
			if attack_decision != current_state:
				decision = attack_decision
		states.attack:
			if attack_ended:
				match current_attack:
					"attack_normal/stand_a", "attack_normal/stand_b", "attack_normal/stand_c":
						decision = states.idle
		states.attack_command:
			if attack_ended:
				match current_attack:
					"attack_command/crouch_a", "attack_command/crouch_b", "attack_command/crouch_c":
						decision = states.crouch
		states.jump_attack:
			if attack_ended:
				match current_attack:
					"attack_jumping/jump_c":
						decision = states.jump_neutral
			if ground_cancelled_attack_ended(): #Ends when the character hits the ground
				match current_attack:
					"attack_jumping/jump_a", "attack_jumping/jump_b":
						decision = states.idle
						current_attack = ""
	if Input.is_action_just_pressed("debug_hurt_weak"):
		decision = states.hurt_high
		kback_hori = 0.6
		kback_vert = 0
		stun_time_start = 15
		stun_time_current = stun_time_start
	if Input.is_action_just_pressed("debug_hurt_knockdown"):
		decision = states.hurt_fall
		kback_hori = 0.2
		kback_vert = 15
		stun_time_start = 50
		stun_time_current = stun_time_start
	if Input.is_action_just_pressed("debug_hurt_bounce"):
		decision = states.hurt_bounce
		kback_hori = 0.25
		kback_vert = -2
		stun_time_start = 30
		stun_time_current = stun_time_start
	update_state(decision)

func standable_stun_check(buffer):
	if stun_time_current == 0:
		var new_walk = walk_check(
				slice_input_dictionary(buffer, len(buffer.up) - 1, len(buffer.up)),
				walk_directions.none
			)
		update_state(new_walk)

func aerial_stun_check(buffer):
	if is_on_floor():
#		standable_stun_check(buffer)
		var new_walk = walk_check(
				slice_input_dictionary(buffer, len(buffer.up) - 1, len(buffer.up)),
				walk_directions.none
			)
		update_state(new_walk)

func action(buffer : Dictionary) -> void:
	handle_input(buffer)
	match current_state:
		states.idle:
			$AnimationPlayer.play("basic/idle")
			velocity.x = 0
			jump_count = jump_total
		states.crouch:
			$AnimationPlayer.play("basic/crouch")
			velocity.x = 0
			jump_count = jump_total
		states.walk_forward:
			if right_facing:
				$AnimationPlayer.play("basic/walk_right")
			else:
				$AnimationPlayer.play("basic/walk_left")
			jump_count = jump_total
			velocity.x = (1 if right_facing else -1) * walk_speed
		states.walk_back:
			if right_facing:
				$AnimationPlayer.play("basic/walk_left")
			else:
				$AnimationPlayer.play("basic/walk_right")
			jump_count = jump_total
			velocity.x = (-1 if right_facing else 1) * walk_speed
		states.jump_forward, states.jump_back, states.jump_neutral:
			$AnimationPlayer.play("basic/jump")
			if (jump_count > 0 and button_just_pressed(buffer, "up")):
					jump_count -= 1
					velocity.y = jump_height
					var jump = jump_check(buffer, walk_directions.none)
					current_state = jump
			match current_state:
				states.jump_forward:
					velocity.x = (1 if right_facing else -1) * walk_speed
				states.jump_back:
					velocity.x = (1 if !right_facing else -1) * walk_speed
				states.jump_neutral:
					velocity.x = 0
		states.attack:
			$AnimationPlayer.play(current_attack)
			velocity.x = 0
		states.attack_command:
			$AnimationPlayer.play(current_attack)
			velocity.x = 0
		states.jump_attack:
			$AnimationPlayer.play(current_attack)
		states.hurt_high:
			$AnimationPlayer.play("hurting/high")
			if stun_time_current == stun_time_start:
				velocity.x += (-1 if right_facing else 1) * kback_hori
		states.hurt_low:
			$AnimationPlayer.play("hurting/low")
			if stun_time_current == stun_time_start:
				velocity.x += (-1 if right_facing else 1) * kback_hori
		states.hurt_crouch:
			$AnimationPlayer.play("hurting/crouch")
			if stun_time_current == stun_time_start:
				velocity.x += (-1 if right_facing else 1) * kback_hori
		states.hurt_fall, states.hurt_bounce:
			$AnimationPlayer.play("hurting/air")
			if stun_time_current == stun_time_start:
				velocity.x += (-1 if right_facing else 1) * kback_hori
				velocity.y += kback_vert
		states.hurt_lie:
			$AnimationPlayer.play("hurting/lying")
			velocity.x = velocity.x * GROUND_SLIDE_FRICTION
		states.get_up:
			$AnimationPlayer.play("hurting/get_up")
		states.block_high:
			$AnimationPlayer.play("blocking/high")
			if stun_time_current == stun_time_start:
				velocity.x += (-1 if right_facing else 1) * kback_hori
		states.block_low:
			$AnimationPlayer.play("blocking/low")
			if stun_time_current == stun_time_start:
				velocity.x += (-1 if right_facing else 1) * kback_hori
		states.block_air:
			$AnimationPlayer.play("blocking/air")
			if stun_time_current == stun_time_start:
				velocity.x += (-1 if right_facing else 1) * kback_hori
				velocity.y += kback_vert
	velocity.y += gravity
	velocity.y = max(min_fall_vel, velocity.y)
	var record_y = velocity.y
	var check_true = move_and_slide()
	match current_state:
		states.jump_forward, states.jump_back, states.jump_neutral, states.jump_attack:
			if is_on_floor():
				var new_walk = walk_check(
					slice_input_dictionary(buffer, len(buffer.up) - 1, len(buffer.up)),
					walk_directions.none
				)
				update_state(new_walk)
		states.block_high, states.block_low:
			stun_time_current -= 1
			standable_stun_check(buffer)
		states.block_air:
			stun_time_current -= 1
			if is_on_floor():
				stun_time_current = 0
			aerial_stun_check(buffer)
		states.hurt_high, states.hurt_low, states.hurt_crouch:
			stun_time_current -= 1
			standable_stun_check(buffer)
		states.hurt_fall, states.hurt_lie:
			stun_time_current -= 1
			aerial_stun_check(buffer)
		states.hurt_bounce:
			if check_true:
				update_state(states.hurt_fall)
				velocity.y = record_y * -1
	if velocity.y < 0 and is_on_floor():
		velocity.y = 0

func reset_facing():
	if distance < 0:
		right_facing = true
	else:
		right_facing = false
	rotation_degrees.y = 180 * int(!right_facing)

func return_overlaps():
	return $Hurtboxes.get_overlapping_areas()

func input_step(inputs : Dictionary) -> void:
	action(inputs)

#"stand_a":
#		{
#			"damage": 3,
#			"type": "mid",
#			"stun_time": 4,
#			"priority": 2,
#			"kbHori": 0.2,
#			"kbVert": 0.0,
#			"total_frame_length": 8,
#			"cancelable_after_frame": 3,
#			"hitboxes": "stand_a"
#		}

func take_damage(attack, blocked):
	if not blocked:
		health -= attack["damage"]
		stun_time_start = attack["stun_time"]
		stun_time_current = stun_time_start
		kback_hori = attack["kbHori"]
		kback_vert = attack["kbVert"]
	else:
		health -= attack["damage_block"]
		stun_time_start = attack["stun_time_block"]
		stun_time_current = stun_time_start
		kback_hori = attack["kbHori_block"]
		kback_vert = attack["kbVert_block"]

# block rule arrays: [up, down, left, right], 1 means valid, 0 means ignored, -1 means invalid
const BLOCK_ANY = [1, 1, 1, 1]
const BLOCK_AWAY_ANY = [0, 1, 0, -1]
const BLOCK_AWAY_HIGH = [0, -1, 1, -1]
const BLOCK_AWAY_LOW = [-1, 1, 1, -1]

const DEPENDENT = "dependent"

func try_block(input : Dictionary, attack : Dictionary, ground_block_rules : Array, air_block_rules : Array, block_fail_state_ground, block_fail_state_air):
	var directions = [button_pressed(input, "up"),button_pressed(input, "down"),button_pressed(input, "left"),button_pressed(input, "right")]
	if not is_in_air_state():
		for check_input in range(len(directions)):
			if (directions[check_input] == true and ground_block_rules[check_input] == -1) or (directions[check_input] == false and ground_block_rules[check_input] == 1):
				if block_fail_state_ground == DEPENDENT:
					if is_in_crouch_state():
						take_damage(attack, false)
						update_state(states.hurt_crouch)
						return
					else:
						take_damage(attack, false)
						update_state(states.hurt_high)
						return
				else:
					take_damage(attack, false)
					update_state(block_fail_state_ground)
					return
		if button_pressed(input, "down"):
			take_damage(attack, true)
			update_state(states.block_low)
			return
		else:
			take_damage(attack, true)
			update_state(states.block_high)
			return
	else:
		for check_input in range(len(directions)):
			if (directions[check_input] == true and air_block_rules[check_input] == -1) or (directions[check_input] == false and air_block_rules[check_input] == 1):
				take_damage(attack, false)
				update_state(block_fail_state_air)
				return
		take_damage(attack, true)
		update_state(states.block_air)
		return

func damage_step(inputs : Dictionary, attack : Dictionary):
	var input = slice_input_dictionary(inputs, len(inputs.up) - 1, len(inputs.up))
	match attack["type"]:
		"mid":
			try_block(input, attack, BLOCK_AWAY_ANY, BLOCK_AWAY_ANY, DEPENDENT, states.hurt_fall)
		"high":
			try_block(input, attack, BLOCK_AWAY_HIGH, BLOCK_AWAY_ANY, states.hurt_high, states.hurt_bounce)
		"low":
			try_block(input, attack, BLOCK_AWAY_LOW, BLOCK_AWAY_ANY, DEPENDENT, states.hurt_fall)
