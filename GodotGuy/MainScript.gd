class_name Fighter
extends CharacterBody3D

@export var char_name : String = "Godot Guy"
@export var health : float = 100
@export var walk_speed : float = 1
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
var stun_time : int = 0

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
	attack, command_attack, jump_attack, special_attack, #handling attacks
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
	"stand_a":
		{
			"damage": 3,
			"type": "mid",
			"stun_time": 4,
			"priority": 2,
			"kbHori": 0.2,
			"kbVert": 0.0,
			"total_frame_length": 8,
			"cancelable_after_frame": 3,
			"hitboxes": "stand_a"
		},
	"stand_b":
		{
			"damage": 4,
			"type": "mid",
			"stun_time": 4,
			"priority": 1,
			"kbHori": 0.6,
			"kbVert": 0.0,
			"total_frame_length": 14,
			"cancelable_after_frame": 5,
			"hitboxes": "stand_b"
		},
	"stand_c":
		{
			"damage": 8,
			"type": "mid",
			"stun_time": 4,
			"priority": 1,
			"kbHori": 0.6,
			"kbVert": 0.0,
			"total_frame_length": 20,
			"cancelable_after_frame": 15,
			"hitboxes": "stand_c"
		},
	"crouch_a": #TODO
		{
			"damage": 2,
			"type": "mid",
			"stun_time": 4,
			"priority": 1,
			"kbHori": 0.2,
			"kbVert": 0.0,
			"total_frame_length": 4,
			"cancelable_after_frame": 3,
			"hitboxes": "crouch_a"
		},
	"crouch_b": #TODO
		{
			"damage": 5,
			"type": "mid",
			"stun_time": 4,
			"priority": 3,
			"kbHori": 0.6,
			"kbVert": 0.0,
			"total_frame_length": 4,
			"cancelable_after_frame": 3,
			"hitboxes": "crouch_b"
		},
	"crouch_c": #TODO
		{
			"damage": 10,
			"type": "mid",
			"stun_time": 4,
			"priority": 1,
			"kbHori": 1.0,
			"kbVert": 5.0,
			"total_frame_length": 20,
			"cancelable_after_frame": 15,
			"hitboxes": "crouch_c"
		},
	"jump_a": #TODO
		{
			"damage": 2,
			"type": "mid",
			"stun_time": 4,
			"priority": 1,
			"kbHori": 0.2,
			"kbVert": 0.0,
			"total_frame_length": -1,
			"cancelable_after_frame": 15,
			"hitboxes": "jump_a"
		},
	"jump_b": #TODO
		{
			"damage": 4,
			"type": "mid",
			"stun_time": 4,
			"priority": 2,
			"kbHori": 0.6,
			"kbVert": 0.0,
			"total_frame_length": -1,
			"cancelable_after_frame": 15,
			"hitboxes": "jump_b"
		},
	"jump_c": #TODO
		{
			"damage": 6,
			"type": "high",
			"stun_time": 4,
			"priority": 1,
			"kbHori": 1.5,
			"kbVert": 0.0,
			"total_frame_length": 20,
			"cancelable_after_frame": 15,
			"hitboxes": "jump_c"
		},
}

var current_attack : String

func basic_attack_ended() -> bool:
	return step_timer >= attacks[current_attack]["total_frame_length"] and attacks[current_attack]["total_frame_length"] != -1

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

enum buttons {Up = 1, Down = 2, Left = 4, Right = 8, A = 16, B = 32, C = 64}

func button_pressed(inputs: Dictionary, input: String):
	return inputs[input][-1][1]

func button_held(inputs: Dictionary, input: String, length: int):
	return inputs[input][-1][0] >= length and inputs[input][-1][1]

func handle_attack(buffer: Dictionary) -> Array:
	if (
		!button_pressed(buffer, "button0") and
		!button_pressed(buffer, "button1") and
		!button_pressed(buffer, "button2")
		):
		return [current_state, step_timer]
	var decision_timer = step_timer
	match current_state:
		states.idle, states.walk_back, states.walk_forward:
			if button_pressed(buffer, "button0"):
				update_attack("stand_a")
				decision_timer = 0
			if button_pressed(buffer, "button1"):
				update_attack("stand_b")
				decision_timer = 0
			if button_pressed(buffer, "button2"):
				update_attack("stand_c")
				decision_timer = 0
		states.crouch:
			if button_pressed(buffer, "button0"):
				update_attack("crouch_a")
				decision_timer = 0
			if button_pressed(buffer, "button1"):
				update_attack("crouch_b")
				decision_timer = 0
			if button_pressed(buffer, "button2"):
				update_attack("crouch_c")
				decision_timer = 0
	return [states.attack, decision_timer]

func handle_jump_attack(buffer: Dictionary) -> Array:
	if (
		!button_pressed(buffer, "button0") and
		!button_pressed(buffer, "button1") and
		!button_pressed(buffer, "button2")
		):
		return [current_state, step_timer]
	var decision_timer = step_timer
	match current_state:
		states.jump_neutral, states.jump_back, states.jump_forward:
			if button_pressed(buffer, "button0"):
				update_attack("jump_a")
				decision_timer = 0
			if button_pressed(buffer, "button1"):
				update_attack("jump_b")
				decision_timer = 0
			if button_pressed(buffer, "button2"):
				update_attack("jump_c")
				decision_timer = 0
	return [states.jump_attack, decision_timer]

func walk_value(input: Dictionary) -> int: #returns -1 (trying to walk away), 0 (no walking inputs), and 1 (trying to walk towards)
	return int(
		(button_pressed(input, "right") and right_facing) or
		(button_pressed(input, "left") and !right_facing)
		) + -1 * int(
			(button_pressed(input, "left") and right_facing) or
			(button_pressed(input, "right") and !right_facing)
			)

enum walk_directions {
	back = -1,
	neutral = 0,
	forward = 1,
	none = 2
}

func walk_check(input : Dictionary, exclude: walk_directions) -> Array:
	var walk = walk_value(input)
	if walk == exclude:
		return [current_state, step_timer]
	match walk:
		walk_directions.forward:
			return [states.walk_forward, 0]
		walk_directions.neutral:
			return [states.idle, 0]
		walk_directions.back:
			if distance < 5:
				return [states.walk_back, 0]
	return [current_state, step_timer]

func jump_check(input: Dictionary, exclude: walk_directions) -> Array:
	if button_held(input, "up", 4):
		var dir = walk_value(input)
		if dir == exclude:
			return [current_state, step_timer]
		match dir:
			walk_directions.forward:
				return [states.jump_forward, 0]
			walk_directions.neutral:
				return [states.jump_neutral, 0]
			walk_directions.back:
				return [states.jump_back, 0]
		return [current_state, step_timer]
	else:
		return [current_state, step_timer]

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
			if button_pressed(input, "down"):
				decision = states.crouch
				decision_timer = 0
			jump_decision = jump_check(input, walk_directions.none)
			if jump_decision != [current_state, step_timer]:
				decision = jump_decision[0]
				decision_timer = jump_decision[1]
			attack_decision = handle_attack(buffer)
			if attack_decision != [current_state, step_timer]:
				decision = attack_decision[0]
				decision_timer = attack_decision[1]
		states.crouch:
			if !button_pressed(input, "down"):
				walk_decision = walk_check(input, walk_directions.none)
				decision = walk_decision[0]
				decision_timer = walk_decision[1]
		states.walk_forward:
			walk_decision = walk_check(input, walk_directions.forward)
			if walk_decision != [current_state, step_timer]:
				decision = walk_decision[0]
				decision_timer = walk_decision[1]
			if button_pressed(input, "down"):
				decision = states.crouch
				decision_timer = 0
			jump_decision = jump_check(input, walk_directions.none)
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
			if button_pressed(input, "down"):
				decision = states.crouch
				decision_timer = 0
			jump_decision = jump_check(input, walk_directions.none)
			if jump_decision != [current_state, step_timer]:
				decision = jump_decision[0]
				decision_timer = jump_decision[1]
			attack_decision = handle_attack(buffer)
			if attack_decision != [current_state, step_timer]:
				decision = attack_decision[0]
				decision_timer = attack_decision[1]
		states.jump_forward:
			jump_decision = jump_check(input, walk_directions.forward)
			if jump_decision != [current_state, step_timer]:
				decision = jump_decision[0]
				decision_timer = jump_decision[1]
			attack_decision = handle_jump_attack(buffer)
			if attack_decision != [current_state, step_timer]:
				decision = attack_decision[0]
				decision_timer = attack_decision[1]
		states.jump_neutral:
			jump_decision = jump_check(input, walk_directions.neutral)
			if jump_decision != [current_state, step_timer]:
				decision = jump_decision[0]
				decision_timer = jump_decision[1]
			attack_decision = handle_jump_attack(buffer)
			if attack_decision != [current_state, step_timer]:
				decision = attack_decision[0]
				decision_timer = attack_decision[1]
		states.jump_back:
			jump_decision = jump_check(input, walk_directions.back)
			if jump_decision != [current_state, step_timer]:
				decision = jump_decision[0]
				decision_timer = jump_decision[1]
			attack_decision = handle_jump_attack(buffer)
			if attack_decision != [current_state, step_timer]:
				decision = attack_decision[0]
				decision_timer = attack_decision[1]
		states.attack:
			if basic_attack_ended(): #Lasts as long as its animation
				match current_attack:
					"stand_a", "stand_b", "stand_c":
						decision = states.idle
						decision_timer = 0
				current_attack = ""
		states.command_attack:
			if basic_attack_ended(): #Lasts as long as its animation
				match current_attack:
					"crouch_a", "crouch_b", "crouch_c":
						decision = states.crouch
						decision_timer = 0
				current_attack = ""
		states.jump_attack:
			if basic_attack_ended(): #Lasts as long as its animation
				match current_attack:
					"jump_c":
						decision = states.jump_neutral
						decision_timer = 0
				current_attack = ""
			if ground_cancelled_attack_ended(): #Ends when the character hits the ground
				match current_attack:
					"jump_a", "jump_b":
						decision = states.idle
						decision_timer = 0
				current_attack = ""
	update_state(decision, decision_timer)

func attempt_animation_reset():
	if animation_ended():
		step_timer = 0

func standable_stun_check(buffer):
	if stun_time == 0:
		var new_walk = walk_check(
				slice_input_dictionary(buffer, len(buffer.up) - 1, len(buffer.up)),
				walk_directions.none
			)
		update_state(new_walk[0], new_walk[1])

func aerial_stun_check(buffer):
	if is_on_floor():
		standable_stun_check(buffer)

func action(buffer : Dictionary, cur_index: int) -> void:
	current_index = cur_index
	handle_input(buffer)
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
		states.jump_forward, states.jump_back, states.jump_neutral:
			current_animation = "jump"
			if (jump_count > 0 and
				last_used_upward_index != current_index and
				buffer.up[-2][1] != buffer.up[-1][1] and
				buffer.up[-1][1]):
					jump_count -= 1
					last_used_upward_index = current_index
					velocity.y = jump_height
					var jump = jump_check(buffer, walk_directions.none)
					current_state = jump[0]
					step_timer = jump[1]
		states.jump_forward:
			velocity.x = (1 if right_facing else -1) * walk_speed
		states.jump_back:
			velocity.x = (1 if right_facing else -1) * walk_speed
		states.jump_neutral:
			velocity.x = 0
		states.attack, states.jump_attack:
			current_animation = current_attack
		states.hurt_high:
			current_animation = "hurt_high"
		states.hurt_low:
			current_animation = "hurt_low"
		states.hurt_crouch:
			current_animation = "hurt_crouch"
		states.hurt_fall:
			current_animation = "hurt_fall"
		states.hurt_lie:
			current_animation = "hurt_lie"
		states.get_up:
			current_animation = "get_up"
		states.block_high:
			current_animation = "block_high"
		states.block_low:
			current_animation = "block_low"
		states.block_air:
			current_animation = "block_air"
#		states.hurt_high, states.hurt_low, states.hurt_crouch, states.block_high, states.block_low:
#			velocity.x += (-1 if right_facing else 1) * knockbackHorizontal
#		states.Hurt_Fall, states.block_air:
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
		states.jump_forward, states.jump_back, states.jump_neutral, states.jump_attack:
			if is_on_floor():
				last_used_upward_index = -1
				var new_walk = walk_check(
					slice_input_dictionary(buffer, len(buffer.up) - 1, len(buffer.up)),
					walk_directions.none
				)
				update_state(new_walk[0], new_walk[1])
		states.block_high, states.block_low:
			stun_time -= 1
			standable_stun_check(buffer)
		states.block_air:
			stun_time -= 1
			if is_on_floor():
				stun_time = 0
			aerial_stun_check(buffer)
		states.hurt_high, states.hurt_low, states.hurt_crouch:
			stun_time -= 1
			standable_stun_check(buffer)
		states.hurt_fall, states.hurt_lie:
			stun_time -= 1
			aerial_stun_check(buffer)

func reset_facing():
	if distance < 0:
		right_facing = true
	else:
		right_facing = false
	rotation_degrees.y = 180 * int(!right_facing)

func step(inputs : Dictionary, cur_index: int) -> void:
	action(inputs, cur_index)
	anim()
	step_timer += 1
