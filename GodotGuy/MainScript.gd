class_name Fighter
extends CharacterBody3D

@export var char_name : String = "Godot Guy"
@export var health : float = 100
@export var walk_speed : float = 1
@export var jump_total : int = 1
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
var state_current: states

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

var current_attack : String

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
			"animation_length": 7,
			0: Vector2i(2,0),
			1: Vector2i(3,0),
			2: Vector2i(4,0),
			3: Vector2i(5,0),
			4: Vector2i(6,0),
			5: Vector2i(7,0),
			6: Vector2i(8,0),
			7: Vector2i(9,0)
			
		},
	"walk_left":
		{
			"animation_length": 7,
			0: Vector2i(9,0),
			1: Vector2i(8,0),
			2: Vector2i(7,0),
			3: Vector2i(6,0),
			4: Vector2i(5,0),
			5: Vector2i(4,0),
			6: Vector2i(3,0),
			7: Vector2i(2,0)
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
		return [state_current, step_timer]
	var decoded_buffer = []
	for input in buffer:
		decoded_buffer.append([decode_hash(input[0]), input[1]])
	var decision_timer = step_timer
	match state_current:
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

func walk_check(inputs: Array) -> int: #returns -1 (trying to walk away), 0 (no walking inputs), and 1 (trying to walk towards)
	return int(
		(inputs[3] and right_facing) or (inputs[2] and !right_facing)
		) + -1 * int(
			(inputs[2] and right_facing) or (inputs[3] and !right_facing)
			)

func handle_input(buffer: Array) -> void:
	var input = decode_hash(buffer[-1][0]) #end of buffer is newest button, first element is input hash
	var held_time = buffer[-1][1]
	var walk = walk_check(input)
	var decision := state_current
	var decision_timer := step_timer
	match state_current:
		states.idle:
			match walk:
				1:
					if !too_close:
						decision = states.walk_forward
						decision_timer = 0
				-1:
					if distance < 5:
						decision = states.walk_back
						decision_timer = 0
			if (input[1]):
				decision = states.crouch
				decision_timer = 0
			if (input[0]):
				match walk:
					1:
						decision = states.jump_forward
						decision_timer = 0
					0:
						decision = states.jump_neutral
						decision_timer = 0
					-1:
						decision = states.jump_back
						decision_timer = 0
			var attack_decision : Array = handle_attack(buffer)
			if attack_decision != [state_current, step_timer]:
				decision = attack_decision[0]
				decision_timer = attack_decision[1]
		states.walk_forward:
			if walk != 1:
				match walk:
					0:
						decision = states.idle
						decision_timer = 0
					-1:
						decision = states.walk_back
						decision_timer = 0
			if (input[1]):
				decision = states.crouch
				decision_timer = 0
			if (input[0]):
				match walk:
					1:
						decision = states.jump_forward
						decision_timer = 0
					0:
						decision = states.jump_neutral
						decision_timer = 0
					-1:
						decision = states.jump_back
						decision_timer = 0
			var attack_decision : Array = handle_attack(buffer)
			if attack_decision != [state_current, step_timer]:
				decision = attack_decision[0]
				decision_timer = attack_decision[1]
		states.walk_back:
			if walk != -1:
				match walk:
					1:
						if !too_close:
							decision = states.walk_forward
							decision_timer = 0
					0:
						decision = states.idle
						decision_timer = 0
			if (input[1]):
				decision = states.crouch
				decision_timer = 0
			if (input[0]):
				match walk:
					1:
						decision = states.jump_forward
						decision_timer = 0
					0:
						decision = states.jump_neutral
						decision_timer = 0
					-1:
						decision = states.jump_back
						decision_timer = 0
			var attack_decision : Array = handle_attack(buffer)
			if attack_decision != [state_current, step_timer]:
				decision = attack_decision[0]
				decision_timer = attack_decision[1]
		states.attack:
			if attack_ended():
				match current_attack:
					"stand_a", "stand_b", "stand_c":
						decision = states.idle
						decision_timer = 0
					"crouch_a", "crouch_b", "crouch_c":
						decision = states.crouch
						decision_timer = 0
					"jump_a", "jump_b":
						decision = states.idle
						decision_timer = 0
					"jump_c":
						decision = states.jump_neutral
						decision_timer = 0
	update_state(decision, decision_timer)

func action(inputs) -> void:
	handle_input(inputs)
	match state_current:
		states.idle:
			current_animation = "idle"
		states.crouch:
			current_animation = "crouch"
		states.walk_forward:
			velocity.x = (1 if right_facing else -1) * walk_speed
		states.walk_back:
			velocity.x = (-1 if right_facing else 1) * walk_speed
			if too_close:
				velocity.x += (-1 if right_facing else 1) * walk_speed
#		states.Hurt_High, states.Hurt_Low, states.Hurt_Crouch, states.Block_High, states.Block_Low:
#			velocity.x += (-1 if right_facing else 1) * knockbackHorizontal
#		states.Hurt_Fall:
#			velocity.x += (-1 if right_facing else 1) * knockbackHorizontal
#			if animStep == 0:
#				velocity.y += knockbackVertical
		states.hurt_fall, states.jump_forward, states.jump_neutral, states.jump_back, states.block_air:
			velocity.y += gravity
			velocity.y = max(min_fall_vel, velocity.y)
	if velocity.y < 0 and is_on_floor():
		velocity.y = 0
	move_and_slide()

func distance_check_enter(_area):
	too_close = true

func distance_check_exit(area):
	too_close = false
	print(area)

func step(inputs) -> void:
	action(inputs)
	anim()
	step_timer += 1
