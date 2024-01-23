class_name Fighter
extends CharacterBody3D

# This script holds the main components of a Fighter, namely the attacks and state machine.
# A Fighter has several variables and methods which are accessed and called by the game.
# input_step() is called with the latest buffer of inputs
# damage_step() is called with the details of the attack, if it happened

# This block of variables and signals are accessed by the game for various reasons.
@export var char_name : String
@export var health : float
var player_number : int # This is set by the game, don't change this
var distance : float # Ditto
var input_buffer_len : int = 10 # Must be a positive number.
var start_x_offset : float = 2
const BUTTONCOUNT : int = 3
var attack_connected : bool
var attack_hurt : bool

signal hitbox_created
signal projectile_created
signal defeated

# Preload ui elements here for the game to add to the screen.
var ui_elements = {
	player1=[
		preload("res://GodotGuy/scenes/SuperBarP1.tscn").instantiate()
	],
	player2=[
		preload("res://GodotGuy/scenes/SuperBarP2.tscn").instantiate()
	]
}

# this block of variables isn't required, but generally used by a typical fighter.
@export var walk_speed : float = 2
@export var jump_total : int = 2
var jump_count : int = 0
@export var jump_height : float = 11
@export var gravity : float = -0.5
@export var min_fall_vel : float = -6.5

var right_facing : bool = true

var kback : Vector3 = Vector3.ZERO
var stun_time_start : int = 0
var stun_time_current : int = 0
@onready var hitbox = preload("res://GodotGuy/scenes/Hitbox.tscn")

const JUST_PRESSED_BUFFER : int = 2
const DASH_INPUT_LENIENCY : int = 15
const MOTION_INPUT_LENIENCY : int = 12
const GROUND_SLIDE_FRICTION : float = 0.97

@export var animate : AnimationPlayer

@export var meter : float = 0
const METER_MAX = 100

var damage_mult : float = 1.0
var defense_mult : float = 1.0

# Extremely important, how the character stores the inputs from the game.
# Dictionary with 4 entries for each cardinal directional input, plus the number of buttons (buttonX).
# Each entry holds an array made up of tuples of a boolean and an int, representing how long the
# input was held/not held.
# Saved here as the alternative was copying potentially large blocks of data for many functions.
var inputs

@onready var projectiles = [preload("res://GodotGuy/scenes/ProjectileStraight.tscn")]

# these are guard clause variables, and may be removed
@export var attack_ended = true
@export var dash_ended = true

#State transitions are handled by a FSM implemented as match statements in the input_step
enum states {
	intro, round_win, set_win, lose, #round stuff
	idle, crouch, #basic basics
	walk_forward, walk_back, dash_forward, dash_back, #lateral movement
	jump_right_init, jump_neutral_init, jump_left_init, #jump from ground initial
	jump_right_air_init, jump_neutral_air_init, jump_left_air_init, #jump from air initial
	jump_right, jump_neutral, jump_left, #aerial actionable
	jump_right_no_act, jump_neutral_no_act, jump_left_no_act, #aerial not actionable
	attack_normal, attack_command, attack_motion, jump_attack, #handling attacks
	block_high, block_low, block_air, get_up, #handling getting attacked well
	hurt_high, hurt_low, hurt_crouch, #not handling getting attacked well
	hurt_fall, hurt_lie, hurt_bounce, #REALLY not handling getting attacked well
	}
var state_start := states.intro
@export var current_state: states
var previous_state : states

# left and right suffixes, change for your animation's version
var anim_left_suf = "_left"
var anim_right_suf = "_right"

# Single animations for states can be handled by a simple hash lookup.
# Because left vs right is handled externally, only the first part of the name is used
@export var basic_anim_state_dict := {
	states.intro : "other/intro",
	states.round_win : "other/round_win",
	states.set_win : "other/set_win",
	states.idle : "basic/idle",
	states.crouch : "basic/crouch",
	states.jump_right_init : "basic/jump", states.jump_left_init : "basic/jump", states.jump_neutral_init : "basic/jump",
	states.jump_right_air_init : "basic/jump", states.jump_neutral_air_init : "basic/jump", states.jump_left_air_init : "basic/jump",
	states.jump_right : "basic/jump", states.jump_left : "basic/jump", states.jump_neutral : "basic/jump",
	states.jump_right_no_act : "basic/jump", states.jump_left_no_act : "basic/jump", states.jump_neutral_no_act : "basic/jump",
	states.hurt_high : "hurting/high",
	states.hurt_low : "hurting/low",
	states.hurt_crouch : "hurting/crouch",
	states.hurt_fall : "hurting/air",
	states.hurt_bounce : "hurting/air",
	states.hurt_lie : "hurting/lying",
	states.get_up : "hurting/get_up",
	states.block_high : "blocking/high",
	states.block_low : "blocking/low",
	states.block_air : "blocking/air",
}
# Moving left and right on the ground is decoupled from moving forward and backward in this script,
# so variables exist here for ease like the dictionary above.
@export var move_left_anim : StringName = &"basic/walk_left"
@export var move_right_anim : StringName = &"basic/walk_right"

@export var dash_left_anim : StringName = &"basic/dash"
@export var dash_right_anim : StringName = &"basic/dash"

# Nothing should modify the fighter's state here, this is purely for real-time effects
# and starting the animation player.
func _ready():
	reset_facing()
	animate.play(basic_anim_state_dict[current_state] + 
		(anim_right_suf if right_facing else anim_left_suf))
func _process(_delta):
	$DebugData.text = """Right Facing: %s
	Current State: %s
	Last State: %s
	Attack Finished: %s
	Stun: %s:%s
	Knockback: %s
	""" % [
		right_facing,
		states.keys()[current_state],
		states.keys()[previous_state],
		attack_ended,
		stun_time_current,
		stun_time_start,
		kback,
	]
	if len(inputs.up) > 0:
		$DebugData.text += str(inputs_as_numpad()[0])

var attack_return_state := {
	"attack_normal/a": states.idle,
	"attack_normal/b": states.idle,
	"attack_normal/c": states.idle,
	"attack_command/crouch_a": states.crouch,
	"attack_command/crouch_b": states.crouch,
	"attack_command/crouch_c": states.crouch,
	"attack_motion/projectile": states.idle,
	"attack_motion/uppercut": states.jump_neutral_no_act,
}

var hitbox_layer : int

# Functions used by the AnimationPlayer to perform actions within animations

enum av_effects {ADD = 0, SET = 1, SET_X = 2, SET_Y = 3}

func update_velocity(vel : Vector3, how : av_effects):
	if not right_facing: vel.x *= -1
	match how:
		av_effects.ADD:
			velocity += vel
		av_effects.SET:
			velocity = vel
		av_effects.SET_X:
			velocity.x = vel.x
		av_effects.SET_Y:
			velocity.y = vel.y

func create_hitbox(pos : Vector3, shape : Shape3D,
				lifetime : int, damage_hit : float, damage_block : float,
				stun_hit : int, stun_block : int, hit_priority : int,
				kback_hit : Vector3, kback_block : Vector3, type : String,
				on_hit_data, on_block_data):
	var new_hitbox := (hitbox.instantiate() as Hitbox)
	if not right_facing:
		pos.x *= -1
	new_hitbox.set_position(pos + global_position)
	(new_hitbox.get_node(^"CollisionShape3D") as CollisionShape3D).set_shape(shape)
	new_hitbox.collision_layer = hitbox_layer
	new_hitbox.lifetime = lifetime
	new_hitbox.damage_hit = damage_hit * damage_mult
	new_hitbox.damage_block = damage_block * damage_mult
	new_hitbox.stun_hit = stun_hit
	new_hitbox.stun_block = stun_block
	new_hitbox.kback_hit = kback_hit
	new_hitbox.kback_block = kback_block
	new_hitbox.hit_priority = hit_priority
	new_hitbox.type = type
	new_hitbox.on_hit = on_hit_data
	new_hitbox.on_block = on_block_data
	emit_signal(&"hitbox_created", new_hitbox)

func create_projectile(pos : Vector3, projectile_ind : int, type : int,
				damage_hit : float, damage_block : float,
				stun_hit : int, stun_block : int, hit_priority : int,
				kback_hit : Vector3, kback_block : Vector3, hit_type : String,
				on_hit_data, on_block_data):
	var new_projectile := (projectiles[projectile_ind].instantiate() as Projectile)
	if not right_facing:
		pos.x *= -1
	new_projectile.set_position(pos + global_position)
	new_projectile.right_facing = right_facing
	new_projectile.type = type
	new_projectile.get_node(^"Hitbox").collision_layer = hitbox_layer
	new_projectile.get_node(^"Hitbox").damage_hit = damage_hit
	new_projectile.get_node(^"Hitbox").damage_block = damage_block * damage_mult
	new_projectile.get_node(^"Hitbox").stun_hit = stun_hit
	new_projectile.get_node(^"Hitbox").stun_block = stun_block
	new_projectile.get_node(^"Hitbox").kback_hit = kback_hit
	new_projectile.get_node(^"Hitbox").kback_block = kback_block
	new_projectile.get_node(^"Hitbox").hit_priority = hit_priority
	new_projectile.get_node(^"Hitbox").type = hit_type
	new_projectile.get_node(^"Hitbox").on_hit = on_hit_data
	new_projectile.get_node(^"Hitbox").on_block = on_block_data
	emit_signal(&"projectile_created", new_projectile)

func add_meter(add_to_meter : float):
	meter = min(meter + add_to_meter, METER_MAX)
	(ui_elements["player1" if player_number == 1 else "player2"][0] as TextureProgressBar).value = meter

# Functions used within this script and by the game, mostly for checks

func post_intro() -> bool:
	return current_state != states.intro

func post_outro() -> bool:
	return (current_state in [states.round_win, states.set_win] and not animate.is_playing()) or current_state == states.hurt_lie

func is_in_air_state() -> bool:
	return current_state in [
		states.jump_attack,
		states.jump_left, states.jump_neutral, states.jump_right,
		states.jump_right_no_act, states.jump_neutral_no_act, states.jump_left_no_act,
		states.block_air, states.hurt_bounce, states.hurt_fall
	]

func is_in_crouch_state() -> bool:
	return current_state in [states.crouch, states.hurt_crouch, states.block_low]

func is_in_dashing_state() -> bool:
	return current_state in [states.dash_back, states.dash_forward]

func is_in_attacking_state() -> bool:
	return current_state in [states.attack_normal, states.attack_command, states.attack_motion, states.jump_attack]

func is_in_hurting_state() -> bool:
	return current_state in [
		states.hurt_high, states.hurt_low, states.hurt_crouch,
		states.hurt_fall, states.hurt_bounce
	]

func set_state(new_state: states):
	if current_state != new_state:
		current_state = new_state
		update_character_animation()

func initialize_boxes(player: bool) -> void:
	if player:
		$Hurtbox.collision_mask = 2
		hitbox_layer = 4
	else:
		$Hurtbox.collision_mask = 4
		hitbox_layer = 2

# Functions used only in this script

var current_attack : String

func ground_cancelled_attack_ended() -> bool:
	return is_on_floor()

func update_attack(new_attack: String) -> void:
	current_attack = new_attack
	attack_ended = false
	attack_connected = false
	attack_hurt = false

enum actions {set, add, remove}
enum buttons {Up = 1, Down = 2, Left = 4, Right = 8, A = 16, B = 32, C = 64}

func btn_state(input: String, ind: int):
	return inputs[input][ind]

func btn_pressed_ind(input: String, ind: int):
	return btn_state(input, ind)[1]

func btn_pressed(input: String):
	return btn_pressed_ind(input, -1)

func btn_just_pressed(input: String):
	return btn_pressed_ind_under_time(input, -1, JUST_PRESSED_BUFFER)

func btn_pressed_ind_under_time(input: String, ind: int, duration: int):
	return btn_state(input, ind)[0] < duration and btn_pressed_ind(input, ind)

func button_held_over_time(input: String, duration: int):
	return btn_state(input, -1)[0] >= duration and btn_pressed(input)

func any_attack_just_pressed():
	return btn_just_pressed("button0") or btn_just_pressed("button1") or btn_just_pressed("button2")

func all_attacks_just_pressed():
	return btn_just_pressed("button0") and btn_just_pressed("button1") and btn_just_pressed("button2")

func two_attacks_just_pressed():
	return (
		int(btn_just_pressed("button0")) +
		int(btn_just_pressed("button1")) +
		int(btn_just_pressed("button2")) == 2
	)

func one_attack_just_pressed():
	return (
		int(btn_just_pressed("button0")) + 
		int(btn_just_pressed("button1")) + 
		int(btn_just_pressed("button2")) == 1
	)

# defining the motion inputs, with some leniency
const QUARTER_CIRCLE_FORWARD = [[2,3,6], [2,6]]
const QUARTER_CIRCLE_BACK = [[2,1,4], [2,4]]
const TIGER_KNEE_FORWARD = [[2,3,6,9]]
const TIGER_KNEE_BACK = [[2,1,4,7]]
const Z_MOTION_FORWARD = [
	[6,2,3], #canonical
	[6,5,2,3], #forward then down
	[6,2,3,6], #overshot a little
	[6,3,2,3], #rolling method
	[6,3,2,1,2,3], #super rolling method
	[6,5,1,2,3], #forward to two away from a half circle
	[6,5,4,1,2,3], #forward to one away from a half circle
	[6,5,4,1,2,3,6], #forward to a half circle, maximumly lenient
]
const Z_MOTION_BACK = [[4,2,1], [4,5,2,1], [4,1,2,3], [4,1,2,3,2,1], [4,5,3,2,1], [4,5,6,3,2,1], [4,5,6,3,2,1,4]]

const GG_INPUT = [[6,3,2,1,4,6], [6,3,2,1,4,5,6]]

func try_super_attack(cur_state: states) -> states:
	match current_state:
		states.idle, states.walk_back, states.walk_forward:
			if motion_input_check(GG_INPUT) and one_attack_just_pressed() and meter >= 50:
				meter -= 50
				update_attack("attack_super/projectile")
				return states.attack_motion
		states.jump_neutral, states.jump_left, states.jump_right:
			if motion_input_check(GG_INPUT) and one_attack_just_pressed() and meter >= 50:
				meter -= 50
				update_attack("attack_super/projectile_air")
				jump_count = 0
				return states.attack_motion
	return cur_state

func try_special_attack(cur_state: states) -> states:
	match current_state:
		states.idle, states.walk_back, states.walk_forward:
			#check z_motion first since there's a lot of overlap with quarter_circle on extreme cases
			if motion_input_check(Z_MOTION_FORWARD) and one_attack_just_pressed():
				update_attack("attack_motion/uppercut")
				jump_count = 0
				return states.attack_motion
			if motion_input_check(QUARTER_CIRCLE_FORWARD) and one_attack_just_pressed():
				update_attack("attack_motion/projectile")
				return states.attack_motion
		states.crouch:
			if motion_input_check(Z_MOTION_FORWARD) and one_attack_just_pressed():
				update_attack("attack_motion/uppercut")
				jump_count = 0
				return states.attack_motion
		states.jump_neutral, states.jump_left, states.jump_right:
			if motion_input_check(QUARTER_CIRCLE_FORWARD + TIGER_KNEE_FORWARD) and one_attack_just_pressed():
				update_attack("attack_motion/projectile_air")
				jump_count = 0
				return states.attack_motion
	return cur_state

func try_attack(cur_state: states) -> states:
	
	if (
		!btn_just_pressed("button0") and
		!btn_just_pressed("button1") and
		!btn_just_pressed("button2")
		):
		return cur_state
	
	previous_state = cur_state
	
	var super_attack = try_super_attack(cur_state)
	if super_attack != cur_state:
		return super_attack
	
	var special_attack = try_special_attack(cur_state)
	if special_attack != cur_state:
		return special_attack
	
	match current_state:
		states.idle, states.walk_back, states.walk_forward:
			if btn_just_pressed("button0"):
				update_attack("attack_normal/a")
				return states.attack_normal
			if btn_just_pressed("button1"):
				update_attack("attack_normal/b")
				return states.attack_normal
			if btn_just_pressed("button2"):
				update_attack("attack_normal/c")
				return states.attack_normal
		states.crouch:
			if btn_just_pressed("button0"):
				update_attack("attack_command/crouch_a")
				return states.attack_command
			if btn_just_pressed("button1"):
				update_attack("attack_command/crouch_b")
				return states.attack_command
			if btn_just_pressed("button2"):
				update_attack("attack_command/crouch_c")
				return states.attack_command
		states.jump_neutral, states.jump_left, states.jump_right, states.jump_neutral_air_init, states.jump_left_air_init, states.jump_right_air_init:
			if btn_just_pressed("button0"):
				update_attack("attack_jumping/a")
				return states.jump_attack
			if btn_just_pressed("button1"):
				update_attack("attack_jumping/b")
				return states.jump_attack
			if btn_just_pressed("button2"):
				update_attack("attack_jumping/c")
				return states.jump_attack
	
	# how did we get here, something has gone terribly wrong
	return states.intro

func magic_series(level: int):
	if level == 3:
		return
	
	if level == 1 and btn_just_pressed("button1"):
		update_attack("attack_normal/b")
		update_character_animation()
	
	if btn_just_pressed("button2"):
		update_attack("attack_normal/c")
		update_character_animation()

#returns -1 (walk away), 0 (neutral), and 1 (walk towards)
func walk_value() -> int:
	return (
		(1 * int((btn_pressed("right") and right_facing) or
			(btn_pressed("left") and !right_facing))) +
		(-1 * int((btn_pressed("left") and right_facing) or
			(btn_pressed("right") and !right_facing))
		)
	)

enum walk_directions {back = -1, neutral = 0, forward = 1}

func try_walk(exclude, cur_state: states) -> states:
	var walk = walk_value()
	if walk != exclude:
		match walk:
			walk_directions.forward:
				return states.walk_forward
			walk_directions.neutral:
				return states.idle
			walk_directions.back:
				if distance < 5:
					return states.walk_back
	return cur_state

func try_dash(input: String, success_state: states, cur_state: states) -> states:
# we only need the last three inputs
	var walks = [
		btn_pressed_ind(input, -3),
		btn_pressed_ind(input, -2),
		btn_pressed_ind(input, -1)
	]
	var count_frames = btn_state(input, -3)[0] + btn_state(input, -2)[0] + btn_state(input, -1)[0]
	if walks == [true, false, true] and count_frames <= DASH_INPUT_LENIENCY:
		dash_ended = false
		return success_state
	return cur_state

func try_jump(exclude, cur_state: states, grounded := true) -> states:
	if (btn_pressed("up") and grounded) or (btn_just_pressed("up") and not grounded) and jump_count > 0:
		var dir = walk_value()
		if dir != exclude:
			match dir:
				walk_directions.forward:
					if right_facing:
						return states.jump_right_init if grounded else states.jump_right_air_init
					else:
						return states.jump_left_init if grounded else states.jump_left_air_init
				walk_directions.back:
					if right_facing:
						return states.jump_left_init if grounded else states.jump_left_air_init
					else:
						return states.jump_right_init if grounded else states.jump_right_air_init
				walk_directions.neutral:
					return states.jump_neutral_init if grounded else states.jump_neutral_air_init
	return cur_state

func directions_as_numpad(up, down, back, forward) -> int:
	if up:
		if back and right_facing or forward and not right_facing:
			return 7
		if forward and right_facing or back and not right_facing:
			return 9
		return 8
	if down:
		if back and right_facing or forward and not right_facing:
			return 1
		if forward and right_facing or back and not right_facing:
			return 3
		return 2
	if back and right_facing or forward and not right_facing:
		return 4
	if forward and right_facing or back and not right_facing:
		return 6
	return 5

func inputs_as_numpad(timing := true) -> Array:
	var numpad_buffer = []
	for i in range(max(0, len(inputs.up) - 2)):
		numpad_buffer.append(
			directions_as_numpad(
				btn_pressed_ind("up", i),
				btn_pressed_ind("down", i),
				btn_pressed_ind("left", i),
				btn_pressed_ind("right", i)
			)
		)
	if max(0, len(inputs.up) - 2) == 0:
		return [5]
	if timing:
		numpad_buffer.append(
			directions_as_numpad(
				btn_pressed_ind_under_time("up", -2, MOTION_INPUT_LENIENCY),
				btn_pressed_ind_under_time("down", -2, MOTION_INPUT_LENIENCY),
				btn_pressed_ind_under_time("left", -2, MOTION_INPUT_LENIENCY),
				btn_pressed_ind_under_time("right", -2, MOTION_INPUT_LENIENCY)
			)
		)
	else:
		numpad_buffer.append(
			directions_as_numpad(
				btn_pressed_ind("up", -2),
				btn_pressed_ind("down", -2),
				btn_pressed_ind("left", -2),
				btn_pressed_ind("right", -2)
			)
		)
	return numpad_buffer


func motion_input_check(motions_to_check) -> bool:
	var buffer_as_numpad = inputs_as_numpad()
	for motion_to_check in motions_to_check:
		var buffer_sliced = buffer_as_numpad.slice(len(buffer_as_numpad) - len(motion_to_check))
		if buffer_sliced == motion_to_check:
			return true
	return false

func handle_input() -> void:
	var decision : states = current_state
	match current_state:
# Priority order, from least to most: Walk, Backdash, Dash, Crouch, Jump, Attack, Block/Hurt (handled elsewhere)
		states.idle, states.walk_back, states.walk_forward:
			match current_state:
				states.idle:
					decision = try_walk(walk_directions.neutral, decision)
					if len(inputs.up) > 3:
						if right_facing:
							decision = try_dash("left", states.dash_back, decision)
							decision = try_dash("right", states.dash_forward, decision)
						else:
							decision = try_dash("left", states.dash_forward, decision)
							decision = try_dash("right", states.dash_back, decision)
				states.walk_back:
					decision = try_walk(walk_directions.back, decision)
				states.walk_forward:
					decision = try_walk(walk_directions.forward, decision)
			decision = states.crouch if btn_pressed("down") else decision
			decision = try_jump(null, decision)
			decision = try_attack(decision)
# Order: release down, attack, b/h
		states.crouch:
			decision = try_walk(null, decision) if !btn_pressed("down") else decision
			decision = try_attack(decision)
# Order: jump, attack, b/h
		states.jump_neutral, states.jump_left, states.jump_right, states.jump_neutral_air_init, states.jump_left_air_init, states.jump_right_air_init:
			decision = try_jump(null, decision, false)
			decision = try_attack(decision)
# Special cases for attack canceling
		states.attack_normal:
			if attack_connected: #if the attack landed at all
				# jump canceling normals
				decision = try_jump(null, decision)
				# magic series
				if decision == states.attack_normal:
					match current_attack:
						"attack_normal/a":
							magic_series(1)
						"attack_normal/b":
							magic_series(2)
						"attack_normal/c":
							magic_series(3)
					# special cancelling
					decision = try_special_attack(decision)
	set_state(decision)

func handle_stand_stun():
	if stun_time_current == 0:
		var new_walk = try_walk(null, current_state)
		set_state(new_walk)

func handle_air_stun():
	if stun_time_current > 0:
		return
	if is_on_floor():
#		handle_stand_stun(buffer)
		var new_walk = try_walk(null, current_state)
		set_state(new_walk)

var record_y
var check_true

func update_character_state():
	match current_state:
		states.idle:
			velocity.x = 0
			jump_count = jump_total
		states.crouch:
			velocity.x = 0
			jump_count = jump_total
		states.walk_forward:
			jump_count = jump_total
			if not $StopPlayerIntersection.has_overlapping_areas():
				velocity.x = (1 if right_facing else -1) * walk_speed
			else:
				velocity.x = 0
		states.walk_back:
			jump_count = jump_total
			velocity.x = (-1 if right_facing else 1) * walk_speed
		states.dash_forward:
			jump_count = jump_total
			if not $StopPlayerIntersection.has_overlapping_areas():
				velocity.x = (1 if right_facing else -1) * walk_speed * 1.5
			else:
				velocity.x = 0
		states.dash_back:
			jump_count = jump_total
			velocity.x = (-1 if right_facing else 1) * walk_speed * 1.5
		states.jump_right_init, states.jump_left_init, states.jump_neutral_init, states.jump_neutral_air_init, states.jump_left_air_init, states.jump_right_air_init:
			jump_count -= 1
			velocity.y = jump_height
		states.jump_right, states.jump_right_no_act:
			velocity.x = walk_speed
		states.jump_left, states.jump_left_no_act:
			velocity.x = -1 * walk_speed
		states.jump_neutral, states.jump_neutral_no_act:
			velocity.x = 0
		states.hurt_high, states.hurt_low, states.hurt_crouch, states.block_high, states.block_low:
			if stun_time_current == stun_time_start:
				velocity.x += (-1 if right_facing else 1) * kback.x
		states.hurt_fall, states.hurt_bounce, states.block_air:
			if stun_time_current == stun_time_start:
				velocity.x += (-1 if right_facing else 1) * kback.x
				velocity.y += kback.y
		states.hurt_lie:
			velocity.x *= GROUND_SLIDE_FRICTION
	velocity.y += gravity
	velocity.y = max(min_fall_vel, velocity.y)
	record_y = velocity.y
	check_true = move_and_slide()
	if velocity.y < 0 and is_on_floor():
		velocity.y = 0

func resolve_state_transitions():
	# complete jump bug fix
	match previous_state:
		states.jump_neutral_init, states.jump_neutral_air_init:
			previous_state = states.jump_neutral
		states.jump_right_init, states.jump_right_air_init:
			previous_state = states.jump_right
		states.jump_left_init, states.jump_left_air_init:
			previous_state = states.jump_left
	match current_state:
		states.intro:
			if not animate.is_playing():
				set_state(states.idle)
				previous_state = current_state
		states.get_up:
			if not animate.is_playing():
				set_state(previous_state)
		states.dash_back:
			if dash_ended:
				set_state(states.walk_back)
		states.dash_forward:
			if dash_ended:
				set_state(states.walk_forward)
		states.jump_right_init, states.jump_right_air_init:
			if not is_on_floor(): set_state(states.jump_right)
		states.jump_left_init, states.jump_left_air_init:
			if not is_on_floor(): set_state(states.jump_left)
		states.jump_neutral_init, states.jump_neutral_air_init:
			if not is_on_floor(): set_state(states.jump_neutral)
		states.jump_right, states.jump_left, states.jump_neutral, states.jump_right_no_act, states.jump_neutral_no_act, states.jump_left_no_act:
			if is_on_floor():
				var new_walk = try_walk(null, current_state)
				set_state(new_walk)
		states.block_air:
			reduce_stun()
			if is_on_floor():
				stun_time_current = 0
			handle_air_stun()
		states.hurt_high, states.hurt_low, states.hurt_crouch, states.block_high, states.block_low:
			reduce_stun()
			handle_stand_stun()
		states.hurt_fall:
			reduce_stun()
			handle_air_stun()
			if check_true and stun_time_current < stun_time_start:
				set_state(states.hurt_lie)
		states.hurt_bounce:
			reduce_stun()
			if check_true:
				set_state(states.hurt_fall)
				set_stun(stun_time_start)
				kback.y *= -1
		states.hurt_lie:
			reduce_stun()
			if stun_time_current == 0:
				set_state(states.get_up)
		states.attack_normal, states.attack_command, states.attack_motion:
			if attack_ended:
				if attack_return_state.get(current_attack) != null:
					set_state(attack_return_state[current_attack])
				else:
					set_state(previous_state)
		states.jump_attack:
			if attack_ended:
				if attack_return_state.get(current_attack) != null:
					set_state(attack_return_state[current_attack])
				else:
					set_state(previous_state)
			elif is_on_floor():
				var new_walk = try_walk(null, current_state)
				set_state(new_walk)

func update_character_animation():
	if current_state in [states.attack_normal, states.attack_command, states.attack_motion, states.jump_attack]:
		animate.play(current_attack + (anim_right_suf if right_facing else anim_left_suf))
	else:
		match current_state:
			states.walk_forward when right_facing:
				animate.play(move_right_anim)
			states.walk_forward when !right_facing:
				animate.play(move_left_anim)
			states.walk_back when right_facing:
				animate.play(move_left_anim)
			states.walk_back when !right_facing:
				animate.play(move_right_anim)
			states.dash_forward when right_facing:
				animate.play(dash_right_anim)
			states.dash_forward when !right_facing:
				animate.play(dash_left_anim)
			states.dash_back when right_facing:
				animate.play(dash_left_anim)
			states.dash_back when !right_facing:
				animate.play(dash_right_anim)
			_:
				animate.play(basic_anim_state_dict[current_state] + (anim_right_suf if right_facing else anim_left_suf))

const INFINITE_STUN := -1

func set_stun(value):
	stun_time_start = value
	GlobalKnowledge.global_hitstop = int(value/4)
	stun_time_current = stun_time_start + 1

func reduce_stun():
	if stun_time_current != -1:
		stun_time_current = max(0, stun_time_current - 1)

func reset_facing():
	if distance < 0:
		right_facing = true
	else:
		right_facing = false

# Functions called directly by the game
func return_attackers():
	return $Hurtbox.get_overlapping_areas() as Array[Hitbox]

func input_step(recv_inputs) -> void:
	inputs = recv_inputs
	if GlobalKnowledge.global_hitstop == 0:
		resolve_state_transitions()
	handle_input()
	if GlobalKnowledge.global_hitstop == 0:
		update_character_state()
	animate.speed_scale = float(GlobalKnowledge.global_hitstop == 0)
	reset_facing()

# This is called when a hitbox makes contact with the other fighter, after resolving that the fighter
# was hit by the attack. A Variant is passed for maximum customizability.
func on_hit(on_hit_data):
# For this fighter, the on_hit and on_block only store a single float, the meter to be gained.
	add_meter(on_hit_data)

# Ditto, but for after resolving that the fighter blocked the attack.
func on_block(on_block_data):
	add_meter(on_block_data)

func handle_damage(attack : Hitbox, blocked : bool):
	if not blocked:
		health -= attack.damage_hit * defense_mult
		set_stun(attack.stun_hit)
		kback = attack.kback_hit
		if health <= 0:
			set_state(states.hurt_lie)
			emit_signal(&"defeated", player_number)
	else:
		health = max(health - attack.damage_block * defense_mult, 1)
		set_stun(attack.stun_block)
		kback = attack.kback_block

# block rule arrays: [up, down, away, towards], 1 means valid, 0 means ignored, -1 means invalid
const BLOCK_ANY = [1, 1, 1, 1]
const BLOCK_AWAY_ANY = [0, 0, 1, -1]
const BLOCK_AWAY_HIGH = [0, -1, 1, -1]
const BLOCK_AWAY_LOW = [-1, 1, 1, -1]
const BLOCK_UNBLOCKABLE = [-1, -1. -1, -1]

# If attack is blocked, return false
# If attack isn't blocked, return true
func try_block(attack : Hitbox,
			ground_block_rules : Array, air_block_rules : Array,
			fs_stand : states, fs_crouch : states, fs_air : states) -> bool:
	# still in hitstun, can't block
	attack.queue_free()
	if is_in_hurting_state() or is_in_dashing_state() or is_in_attacking_state():
		if not is_in_air_state():
			if is_in_crouch_state():
				set_state(fs_crouch)
				handle_damage(attack, false)
				return true
			else:
				set_state(fs_stand)
				handle_damage(attack, false)
				return true
		else:
			handle_damage(attack, false)
			set_state(fs_air)
			return true
	# Try to block
	var directions = [btn_pressed("up"),btn_pressed("down"),btn_pressed("left"),btn_pressed("right")]
	if not right_facing:
		var temp = directions[2]
		directions[2] = directions[3]
		directions[3] = temp
	if not is_in_air_state():
		for check_input in range(len(directions)):
			if (directions[check_input] == true and ground_block_rules[check_input] == -1) or (directions[check_input] == false and ground_block_rules[check_input] == 1):
				if is_in_crouch_state():
					set_state(fs_crouch)
					handle_damage(attack, false)
					return true
				else:
					set_state(fs_stand)
					handle_damage(attack, false)
					return true
		if btn_pressed("down"):
			handle_damage(attack, true)
			set_state(states.block_low)
			return false
		else:
			handle_damage(attack, true)
			set_state(states.block_high)
			return false
	else:
		for check_input in range(len(directions)):
			if (directions[check_input] == true and air_block_rules[check_input] == -1) or (directions[check_input] == false and air_block_rules[check_input] == 1):
				handle_damage(attack, false)
				set_state(fs_air)
				return true
		handle_damage(attack, true)
		set_state(states.block_air)
		return false

# Only runs when a hitbox is overlapping, return rules explained above
func damage_step(attack : Hitbox) -> bool:
	match attack["type"]:
		"mid":
			return try_block(attack, BLOCK_AWAY_ANY, BLOCK_AWAY_ANY, states.hurt_high, states.hurt_crouch, states.hurt_fall)
		"high":
			return try_block(attack, BLOCK_AWAY_HIGH, BLOCK_AWAY_ANY, states.hurt_high, states.hurt_crouch, states.hurt_fall)
		"low":
			return try_block(attack, BLOCK_AWAY_LOW, BLOCK_AWAY_ANY, states.hurt_low, states.hurt_crouch, states.hurt_fall)
		"launch":
			return try_block(attack, BLOCK_AWAY_ANY, BLOCK_AWAY_ANY, states.hurt_fall, states.hurt_fall, states.hurt_fall)
		"sweep":
			return try_block(attack, BLOCK_AWAY_LOW, BLOCK_AWAY_ANY, states.hurt_lie, states.hurt_lie, states.hurt_fall)
		"slam":
			return try_block(attack, BLOCK_AWAY_HIGH, BLOCK_AWAY_ANY, states.hurt_bounce, states.hurt_bounce, states.hurt_bounce)
		_: # this will definitely not be a bug in the future
			return try_block(attack, BLOCK_UNBLOCKABLE, BLOCK_UNBLOCKABLE, states.hurt_high, states.hurt_crouch, states.hurt_fall)
