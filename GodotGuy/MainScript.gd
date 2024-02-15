class_name State2DMeterFighter
extends Fighter


# This script defines a FSM-based Fighter with the following features:
# 2D Movement
# Dashing
# Super Meter

@export_category("Animation Details")
@export var animate : FlippingAnimationPlayer
@export var basic_anim_state_dict := {
	states.intro : "other/intro",
	states.round_win : "other/win",
	states.set_win : "other/win",
	states.idle : "basic/idle",
	states.crouch : "basic/crouch",
	states.jump_right_init : "basic/jump", states.jump_left_init : "basic/jump", states.jump_neutral_init : "basic/jump",
	states.jump_right_air_init : "basic/jump", states.jump_neutral_air_init : "basic/jump", states.jump_left_air_init : "basic/jump",
	states.jump_right : "basic/jump", states.jump_left : "basic/jump", states.jump_neutral : "basic/jump",
	states.jump_right_no_act : "basic/jump", states.jump_left_no_act : "basic/jump", states.jump_neutral_no_act : "basic/jump",
	states.block_high : "blocking/high",
	states.block_low : "blocking/low",
	states.block_air : "blocking/air",
	states.hurt_high : "hurting/high",
	states.hurt_low : "hurting/low",
	states.hurt_crouch : "hurting/crouch",
	states.hurt_grabbed : "hurting/air",
	states.hurt_fall : "hurting/air",
	states.hurt_bounce : "hurting/air",
	states.hurt_lie : "hurting/lying",
	states.get_up : "hurting/get_up",
	states.outro_fall : "hurting/air",
	states.outro_bounce : "hurting/air",
	states.outro_lie : "hurting/lying",
}
@export var animation_ended = true
@export var move_left_anim : StringName = &"basic/walk_left"
@export var move_right_anim : StringName = &"basic/walk_right"
@export var dash_left_anim : StringName = &"basic/dash"
@export var dash_right_anim : StringName = &"basic/dash"

@export_category("Super Attack Meter")
@export var meter : float = 0
@export var METER_MAX : float= 100

@export_category("Damage and Defense")
@export var damage_mult : float = 1.0
@export var defense_mult : float = 1.0

@export_category("Movement")
@export var walk_speed : float = 2
@export var jump_total : int = 2
var jump_count : int = 0
@export var jump_height : float = 11
@export var gravity : float = -0.5
@export var min_fall_vel : float = -6.5
@export var GROUND_SLIDE_FRICTION : float = 0.97
var record_y : float
var check_true : bool # Used to remember results of move_and_slide()
var right_facing : bool

func _initialize_training_mode_elements(player : bool):
	if player:
		for scene in ui_elements_packed.player1:
			ui_elements.append(scene.instantiate())
		for scene in ui_elements_training_packed.player1:
			ui_elements_training.append(scene.instantiate())
	else:
		for scene in ui_elements_packed.player2:
			ui_elements.append(scene.instantiate())
		for scene in ui_elements_training_packed.player2:
			ui_elements_training.append(scene.instantiate())
	(ui_elements_training[0] as HSlider).value_changed.connect(training_mode_set_meter)

# this block of variables isn't required, but generally used by a typical fighter.
func training_mode_set_meter(val):
	meter = val
	(ui_elements[0] as TextureProgressBar).value = meter

@onready var hitboxes = {
	"stand_a": preload("res://GodotGuy/scenes/hitboxes/stand/a.tscn"),
	"stand_b": preload("res://GodotGuy/scenes/hitboxes/stand/b.tscn"),
	"stand_c": preload("res://GodotGuy/scenes/hitboxes/stand/c.tscn"),
	"crouch_a": preload("res://GodotGuy/scenes/hitboxes/crouch/a.tscn"),
	"crouch_b": preload("res://GodotGuy/scenes/hitboxes/crouch/b.tscn"),
	"crouch_c": preload("res://GodotGuy/scenes/hitboxes/crouch/c.tscn"),
	"jump_a": preload("res://GodotGuy/scenes/hitboxes/jump/a.tscn"),
	"jump_b": preload("res://GodotGuy/scenes/hitboxes/jump/b.tscn"),
	"jump_c": preload("res://GodotGuy/scenes/hitboxes/jump/c.tscn"),
	"uppercut": preload("res://GodotGuy/scenes/hitboxes/special/uppercut.tscn"),
	"grab": preload("res://GodotGuy/scenes/hitboxes/stand/grab.tscn"),
	"grab_followup": preload("res://GodotGuy/scenes/hitboxes/stand/grab_followup.tscn"),
}
@onready var projectiles = {
	"basic": preload("res://GodotGuy/scenes/ProjectileStraight.tscn")
}

#State transitions are handled by a FSM implemented as match statements in the input_step
enum states {
	intro, round_win, set_win, #round stuff
	idle, crouch, #basic basics
	walk_forward, walk_back, dash_forward, dash_back, #lateral movement
	jump_right_init, jump_neutral_init, jump_left_init, #jump from ground initial
	jump_right_air_init, jump_neutral_air_init, jump_left_air_init, #jump from air initial
	jump_right, jump_neutral, jump_left, #aerial actionable
	jump_right_no_act, jump_neutral_no_act, jump_left_no_act, #aerial not actionable
	attack_normal, attack_command, attack_motion, attack_grab, jump_attack, #handling attacks
	block_high, block_low, block_air, get_up, #handling getting attacked well
	hurt_high, hurt_low, hurt_crouch, hurt_grabbed, #not handling getting attacked well
	hurt_fall, hurt_lie, hurt_bounce, #REALLY not handling getting attacked well
	outro_fall, outro_lie, outro_bounce #The final stage of not handling it
}
var state_start := states.intro
var current_state: states
var previous_state : states

# Nothing should modify the fighter's state in _process or _ready, _process is purely for
# real-time effects, and _ready for initialization.

func _ready():
	reset_facing()
	animate.play(basic_anim_state_dict[current_state] + 
		(animate.anim_right_suf if right_facing else animate.anim_left_suf))

func _post_intro() -> bool:
	return current_state != states.intro

func _post_outro() -> bool:
	return (current_state in [states.round_win, states.set_win] and not animate.is_playing())

func _in_defeated_state() -> bool:
	return current_state == states.outro_lie

func _in_outro_state() -> bool:
	return current_state in [states.outro_fall, states.outro_bounce, states.outro_lie]

func _in_attacking_state() -> bool:
	return current_state in [states.attack_normal, states.attack_command, states.attack_motion, states.jump_attack]

func _in_hurting_state() -> bool:
	return current_state in [
		states.hurt_high, states.hurt_low, states.hurt_crouch, states.hurt_grabbed,
		states.hurt_fall, states.hurt_bounce
	]

func _in_grabbed_state() -> bool:
	return current_state == states.hurt_grabbed

func in_air_state() -> bool:
	return current_state in [
		states.jump_attack,
		states.jump_left, states.jump_neutral, states.jump_right,
		states.jump_right_no_act, states.jump_neutral_no_act, states.jump_left_no_act,
		states.block_air, states.hurt_bounce, states.hurt_fall
	]

func in_crouching_state() -> bool:
	return current_state in [states.crouch, states.hurt_crouch, states.block_low]

func in_dashing_state() -> bool:
	return current_state in [states.dash_back, states.dash_forward]

func _process(_delta):
	$DebugData.text = """Right Facing: %s
	Current State: %s
	Last State: %s
	Attack Finished: %s
	Stun: %s:%s
	Knockback: %s
	Current Animation : %s
	""" % [
		right_facing,
		states.keys()[current_state],
		states.keys()[previous_state],
		animation_ended,
		stun_time_current,
		stun_time_start,
		kback,
		animate.current_animation
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

var grab_return_states := {
	"attack_normal/grab": {
		true: "attack_normal/grab_followup",
		false: "attack_normal/grab_whiff"
	},
}

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

func create_hitbox(pos : Vector3, hitbox_name : String):
	var new_hitbox := (hitboxes[hitbox_name].instantiate() as Hitbox)
	if not right_facing:
		pos.x *= -1
	new_hitbox.set_position(pos + global_position)
	new_hitbox.collision_layer = hitbox_layer
	new_hitbox.damage_block *= damage_mult
	new_hitbox.damage_hit *= damage_mult
	emit_signal(&"hitbox_created", new_hitbox)

func create_projectile(pos : Vector3, projectile_name : String, type : int):
	var new_projectile := (projectiles[projectile_name].instantiate() as Projectile)
	if not right_facing:
		pos.x *= -1
	new_projectile.set_position(pos + global_position)
	new_projectile.right_facing = right_facing
	new_projectile.type = type
	new_projectile.source = player_number
	new_projectile.get_node(^"Hitbox").collision_layer = hitbox_layer
	new_projectile.get_node(^"Hitbox").damage_block *= damage_mult
	new_projectile.get_node(^"Hitbox").damage_hit *= damage_mult
	emit_signal(&"projectile_created", new_projectile)

func release_grab():
	emit_signal("releasing_grab", player_number)

func add_meter(add_to_meter : float):
	meter = min(meter + add_to_meter, METER_MAX)
	(ui_elements[0] as TextureProgressBar).value = meter

func set_state(new_state: states):
	if current_state != new_state:
		current_state = new_state
		update_character_animation()

# Functions used only in this script
const INFINITE_STUN := -1

func set_stun(value):
	stun_time_start = value
	GlobalKnowledge.global_hitstop = int(abs(value)/4)
	stun_time_current = stun_time_start + 1 if stun_time_start != INFINITE_STUN else INFINITE_STUN

func reduce_stun():
	if stun_time_start != INFINITE_STUN:
		stun_time_current = max(0, stun_time_current - 1)

var current_attack : String

func ground_cancelled_attack_ended() -> bool:
	return is_on_floor()

func update_attack(new_attack: String) -> void:
	current_attack = new_attack
	animation_ended = false
	attack_connected = false
	attack_hurt = false

func any_atk_just_pressed():
	return btn_just_pressed("button0") or btn_just_pressed("button1") or btn_just_pressed("button2")

func all_atk_just_pressed():
	return btn_just_pressed("button0") and btn_just_pressed("button1") and btn_just_pressed("button2")

func two_atk_just_pressed():
	return (
		int(btn_just_pressed("button0")) +
		int(btn_just_pressed("button1")) +
		int(btn_just_pressed("button2")) == 2
	)

func one_atk_just_pressed():
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

const GG_INPUT = [[6,3,2,1,4,6], [6,3,2,1,4,5,6], [6,2,1,4,6], [6,2,4,5,6], [6,2,1,4,5,6]]

func try_super_attack(cur_state: states) -> states:
	match current_state:
		states.idle, states.walk_back, states.walk_forward:
			if motion_input_check(GG_INPUT) and one_atk_just_pressed() and meter >= 50:
				meter -= 50
				update_attack("attack_super/projectile")
				return states.attack_motion
		states.jump_neutral, states.jump_left, states.jump_right:
			if motion_input_check(GG_INPUT) and one_atk_just_pressed() and meter >= 50:
				meter -= 50
				update_attack("attack_super/projectile_air")
				jump_count = 0
				return states.attack_motion
	return cur_state

func try_special_attack(cur_state: states) -> states:
	match current_state:
		states.idle, states.walk_back, states.walk_forward:
			#check z_motion first since there's a lot of overlap with quarter_circle on extreme cases
			if motion_input_check(Z_MOTION_FORWARD) and one_atk_just_pressed():
				update_attack("attack_motion/uppercut")
				jump_count = 0
				return states.attack_motion
			if motion_input_check(QUARTER_CIRCLE_FORWARD) and one_atk_just_pressed():
				update_attack("attack_motion/projectile")
				return states.attack_motion
		states.crouch:
			if motion_input_check(Z_MOTION_FORWARD) and one_atk_just_pressed():
				update_attack("attack_motion/uppercut")
				jump_count = 0
				return states.attack_motion
		states.jump_neutral, states.jump_left, states.jump_right:
			if motion_input_check(QUARTER_CIRCLE_FORWARD + TIGER_KNEE_FORWARD) and one_atk_just_pressed():
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
			if two_atk_just_pressed():
				update_attack("attack_normal/grab")
				return states.attack_grab
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
		animation_ended = false
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
		states.hurt_grabbed:
			velocity.x = 0
			velocity.y = -gravity #negative gravity is used here to undo gravity and halt all movement
		states.hurt_high, states.hurt_low, states.hurt_crouch, states.block_high, states.block_low:
			if stun_time_current == stun_time_start:
				velocity.x += (-1 if right_facing else 1) * kback.x
		states.hurt_fall, states.hurt_bounce, states.block_air, states.outro_bounce, states.outro_fall:
			if stun_time_current == stun_time_start:
				velocity.x += (-1 if right_facing else 1) * kback.x
				velocity.y += kback.y
		states.hurt_lie, states.outro_lie:
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
		states.idle, states.walk_forward, states.walk_back, states.crouch when game_ended:
			set_state(states.round_win)
			return
		states.intro:
			if not animate.is_playing():
				set_state(states.idle)
				previous_state = current_state
		states.round_win:
			previous_state = current_state
			set_state(states.round_win)
		states.set_win:
			previous_state = current_state
			set_state(states.set_win)
		states.get_up:
			if not animate.is_playing():
				set_state(previous_state)
		states.dash_back:
			if animation_ended:
				set_state(states.walk_back)
		states.dash_forward:
			if animation_ended:
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
		states.outro_bounce:
			reduce_stun()
			if check_true:
				set_state(states.outro_fall)
				set_stun(stun_time_start)
				kback.y *= -1
		states.hurt_lie:
			reduce_stun()
			if stun_time_current == 0:
				set_state(states.get_up)
		states.outro_fall:
			reduce_stun()
			if check_true:
				set_state(states.outro_lie)
		states.attack_normal, states.attack_command, states.attack_motion:
			if animation_ended:
				if attack_return_state.get(current_attack) != null:
					set_state(attack_return_state[current_attack])
				else:
					set_state(previous_state)
		states.attack_grab:
			if animation_ended:
				update_attack(grab_return_states[current_attack][attack_connected])
				set_state(states.attack_normal)
		states.jump_attack:
			if animation_ended:
				if attack_return_state.get(current_attack) != null:
					set_state(attack_return_state[current_attack])
				else:
					set_state(previous_state)
			elif is_on_floor():
				var new_walk = try_walk(null, current_state)
				set_state(new_walk)

func update_character_animation():
	if current_state in [states.attack_normal, states.attack_command, states.attack_motion, states.attack_grab, states.jump_attack]:
		animate.play(current_attack + (animate.anim_right_suf if right_facing else animate.anim_left_suf))
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
				animate.play(basic_anim_state_dict[current_state] + (animate.anim_right_suf if right_facing else animate.anim_left_suf))

func reset_facing():
	if distance < 0:
		right_facing = true
		grabbed_offset.x = -.46
	else:
		right_facing = false
		grabbed_offset.x = .46

# Functions called directly by the game
func _return_attackers():
	return $Hurtbox.get_overlapping_areas() as Array[Hitbox]

func _input_step(recv_inputs) -> void:
	inputs = recv_inputs
	if GlobalKnowledge.global_hitstop == 0:
		resolve_state_transitions()
	handle_input()
	if GlobalKnowledge.global_hitstop == 0:
		update_character_state()
	animate.speed_scale = float(GlobalKnowledge.global_hitstop == 0)
	reset_facing()

# This is called when a hitbox makes contact with the other fighter, after resolving that the fighter
# was hit by the attack. An Array is passed for maximum customizability.
func _on_hit(on_hit_data : Array):
# For this fighter, the on_hit and on_block arrays stores only the meter_gain, a float.
	add_meter(on_hit_data[0])

# Ditto, but for after resolving that the opposing fighter blocked the attack.
func _on_block(on_block_data : Array):
	add_meter(on_block_data[0])

func handle_damage(attack : Hitbox, blocked : bool, next_state : states):
	if not blocked:
		health -= attack.damage_hit * defense_mult
		set_stun(attack.stun_hit)
		kback = attack.kback_hit
		if health <= 0:
			set_state(states.outro_bounce)
			kback.y += 6.5
			emit_signal(&"defeated")
		else:
			set_state(next_state)
	else:
		health = max(health - attack.damage_block * defense_mult, 1)
		set_stun(attack.stun_block)
		kback = attack.kback_block
		set_state(next_state)

# block rule arrays: [up, down, away, towards], 1 means must hold, 0 means ignored, -1 means must not hold
@export_category("2D Gameplay Details")
@export var block : Dictionary = {
	away_any = [0, 0, 1, -1],
	away_high = [0, -1, 1, -1],
	away_low = [-1, 1, 1, -1],
	nope = [-1, -1. -1, -1],
}
# If attack is blocked, return false
# If attack isn't blocked, return true
func try_block(attack : Hitbox,
			ground_block_rules : Array, air_block_rules : Array,
			fs_stand : states, fs_crouch : states, fs_air : states) -> bool:
	# still in hitstun, can't block
	if _in_hurting_state() or _in_attacking_state() or in_dashing_state():
		if not in_air_state():
			if in_crouching_state():
				handle_damage(attack, false, fs_crouch)
				return true
			else:
				handle_damage(attack, false, fs_stand)
				return true
		else:
			handle_damage(attack, false, fs_air)
			return true
	# Try to block
	var directions = [btn_pressed("up"),btn_pressed("down"),btn_pressed("left"),btn_pressed("right")]
	if not right_facing:
		var temp = directions[2]
		directions[2] = directions[3]
		directions[3] = temp
	if not in_air_state():
		for check_input in range(len(directions)):
			if (directions[check_input] == true and ground_block_rules[check_input] == -1) or (directions[check_input] == false and ground_block_rules[check_input] == 1):
				if in_crouching_state():
					handle_damage(attack, false, fs_crouch)
					return true
				else:
					handle_damage(attack, false, fs_stand)
					return true
		if btn_pressed("down"):
			handle_damage(attack, true, states.block_low)
			return false
		else:
			handle_damage(attack, true, states.block_high)
			return false
	else:
		for check_input in range(len(directions)):
			if (directions[check_input] == true and air_block_rules[check_input] == -1) or (directions[check_input] == false and air_block_rules[check_input] == 1):
				handle_damage(attack, false, fs_air)
				return true
		handle_damage(attack, true, states.block_air)
		return false

func try_grab(attack_dmg: float, on_ground : bool) -> bool:
	if in_crouching_state():
		return false
	if on_ground and in_air_state():
		return false
	emit_signal(&"grabbed", player_number)
	health = max(health - attack_dmg * defense_mult, 1)
	set_stun(-1)
	kback = Vector3.ZERO
	set_state(states.hurt_grabbed)
	return true

# Only runs when a hitbox is overlapping, return rules explained above
func _damage_step(attack : Hitbox) -> bool:
	match attack.hit_type:
		"mid":
			return try_block(attack, block.away_any, block.away_any, states.hurt_high, states.hurt_crouch, states.hurt_fall)
		"high":
			return try_block(attack, block.away_high, block.away_any, states.hurt_high, states.hurt_crouch, states.hurt_fall)
		"low":
			return try_block(attack, block.away_low, block.away_any, states.hurt_low, states.hurt_crouch, states.hurt_fall)
		"launch":
			return try_block(attack, block.away_any, block.away_any, states.hurt_fall, states.hurt_fall, states.hurt_fall)
		"sweep":
			return try_block(attack, block.away_low, block.away_any, states.hurt_lie, states.hurt_lie, states.hurt_fall)
		"slam":
			return try_block(attack, block.away_high, block.away_any, states.hurt_bounce, states.hurt_bounce, states.hurt_bounce)
		"grab_ground":
			return try_grab(attack.damage_hit, true)
		"grab_air":
			return try_grab(attack.damage_hit, false)
		_: # this will definitely not be a bug in the future
			return try_block(attack, block.nope, block.nope, states.hurt_high, states.hurt_crouch, states.hurt_fall)
