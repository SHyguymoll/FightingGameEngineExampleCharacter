extends Node3D

#required variables from Content.gd
var p1
var p2
var stage
var projectiles : Array[Projectile]

#required variables from InputHandle.gd
var p1_buttons = [false, false, false, false, false, false, false, false, false, false]
var p2_buttons = [false, false, false, false, false, false, false, false, false, false]

var p1_inputs : Dictionary = {
	up=[[0, false]],
	down=[[0, false]],
	left=[[0, false]],
	right=[[0, false]],
}

var p2_inputs : Dictionary = {
	up=[[0, false]],
	down=[[0, false]],
	left=[[0, false]],
	right=[[0, false]],
}

var p1_input_index : int = 0
var p2_input_index : int = 0

#specific to this testing area
@export var player_test_one : PackedScene
@export var player_test_two : PackedScene
@export var scene_to_test : PackedScene

var p1_reset_health_on_drop := true
var p2_reset_health_on_drop := true
var p1_health_reset : float
var p2_health_reset : float

#required variables and methods from Game.gd
@export var camera_mode = 0
const CAMERAMAXX = 1.6
const CAMERAMAXY = 10
const MOVEMENTBOUNDX = 8
var p1_combo := 0
var p2_combo := 0
enum moments {
	INTRO,
	GAME,
	ROUND_END
}
var moment := moments.INTRO

func make_hud():
	# player 1
	$HUD/HealthAndTime/P1Group/Health.max_value = p1.health
	$HUD/HealthAndTime/P1Group/Health.value = p1.health
	$HUD/HealthAndTime/P1Group/NameAndPosVel/Char.text = p1.char_name
	$HUD/HealthAndTime/P1Group/NameAndPosVel/PosVel.text = str(p1.position) + "\n" + str(p1.velocity)
	$HUD/P1Stats/State.text = p1.states.keys()[p1.current_state]
	
	# player 2
	$HUD/HealthAndTime/P2Group/Health.max_value = p2.health
	$HUD/HealthAndTime/P2Group/Health.value = p2.health
	$HUD/HealthAndTime/P2Group/NameAndPosVel/Char.text = p2.char_name
	$HUD/HealthAndTime/P2Group/NameAndPosVel/PosVel.text = str(p2.position) + "\n" + str(p2.velocity)
	$HUD/P2Stats/State.text = p2.states.keys()[p2.current_state]
	
	
	# game itself
	$HUD/Fight.visible = false
	$HUD/TrainingModeControls/P1Controls/HBoxContainer/HealthReset.min_value = 1
	$HUD/TrainingModeControls/P1Controls/HBoxContainer/HealthReset.max_value = p1.health
	$HUD/TrainingModeControls/P1Controls/HBoxContainer/HealthReset.value = $HUD/TrainingModeControls/P1Controls/HBoxContainer/HealthReset.max_value
	$HUD/TrainingModeControls/P1Controls/HBoxContainer/HealthResetSwitch.set_pressed_no_signal(p1_reset_health_on_drop)
	$HUD/TrainingModeControls/P2Controls/HBoxContainer/HealthReset.min_value = 1
	$HUD/TrainingModeControls/P2Controls/HBoxContainer/HealthReset.max_value = p2.health
	$HUD/TrainingModeControls/P2Controls/HBoxContainer/HealthReset.value = $HUD/TrainingModeControls/P2Controls/HBoxContainer/HealthReset.max_value
	$HUD/TrainingModeControls/P2Controls/HBoxContainer/HealthResetSwitch.set_pressed_no_signal(p2_reset_health_on_drop)

func update_hud():
	# player 1
	$HUD/HealthAndTime/P1Group/Health.value = p1.health
	$HUD/P1Stats/State.text = p1.states.keys()[p1.current_state]
	if "attack" in $HUD/P1Stats/State.text:
		$HUD/P1Stats/State.text += " : " + p1.current_attack
	$HUD/HealthAndTime/P1Group/NameAndPosVel/PosVel.text = str(p1.position) + "\n" + str(p1.velocity)
	$HUD/P1Stats/Combo.text = str(p1_combo)
	
	# player 2
	$HUD/HealthAndTime/P2Group/Health.value = p2.health
	$HUD/P2Stats/State.text = p2.states.keys()[p2.current_state]
	if "attack" in $HUD/P2Stats/State.text:
		$HUD/P2Stats/State.text += " : " + p2.current_attack
	$HUD/HealthAndTime/P2Group/NameAndPosVel/PosVel.text = str(p2.position) + "\n" + str(p2.velocity)
	$HUD/P2Stats/Combo.text = str(p2_combo)

func init_fighters():
	for i in range(p1.BUTTONCOUNT):
		p1_inputs["button" + str(i)] = [[0, false]]
	p1.player_number = 1
	p1.position = Vector3(p1.start_x_offset * -1,0,0)
	p1.initialize_boxes(true)
	p1.char_name += " p1"
	p1.hitbox_created.connect(register_hitbox)
	p1.projectile_created.connect(register_projectile)
	p1.defeated.connect(player_defeated)
	for element in p1.ui_elements.player1:
		$HUD/SpecialElements/P1Group.add_child(element)
	
	for i in range(p2.BUTTONCOUNT):
		p2_inputs["button" + str(i)] = [[0, false]]
	p2.player_number = 2
	p2.position = Vector3(p2.start_x_offset,0,0)
	p2.initialize_boxes(false)
	p2.char_name += " p2"
	p2.hitbox_created.connect(register_hitbox)
	p2.projectile_created.connect(register_projectile)
	p2.defeated.connect(player_defeated)
	for element in p2.ui_elements.player2:
		$HUD/SpecialElements/P2Group.add_child(element)
	
	character_positioning()
	p1_health_reset = p1.health
	p2_health_reset = p2.health

func reset_hitstop():
	GlobalKnowledge.global_hitstop = 0
	GlobalKnowledge.p1_hitstop = 0
	GlobalKnowledge.p2_hitstop = 0

func _ready():
	reset_hitstop()
	add_child(scene_to_test.instantiate())
	p1 = player_test_one.instantiate()
	p2 = player_test_two.instantiate()
	make_hud()
	init_fighters()
	add_child(p1)
	add_child(p2)

const ORTH_DIST = 1.328125
const CAMERA_PERSPECTIVE = 0
const CAMERA_ORTH = 1

enum camera_modes {
	ORTH_BALANCED = 0,
	ORTH_PLAYER1,
	ORTH_PLAYER2,
	PERS_BALANCED,
	PERS_PLAYER1,
	PERS_PLAYER2
}

func camera_control(mode: int):
	$Camera3D.projection = CAMERA_ORTH if mode < camera_modes.PERS_BALANCED else CAMERA_PERSPECTIVE
	match mode:
		#2d modes
		camera_modes.ORTH_BALANCED:
			$Camera3D.position.x = (p1.position.x + p2.position.x)/2
			$Camera3D.position.y = max(p1.position.y + 1, p2.position.y + 1)
			$Camera3D.position.z = ORTH_DIST
			$Camera3D.size = clampf(abs(p1.position.x - p2.position.x)/2, 3.5, 6)
		camera_modes.ORTH_PLAYER1:
			$Camera3D.position.x = p1.position.x
			$Camera3D.position.y = p1.position.y + 1
			$Camera3D.position.z = ORTH_DIST
		camera_modes.ORTH_PLAYER2:
			$Camera3D.position.x = p2.position.x
			$Camera3D.position.y = p2.position.y + 1
			$Camera3D.position.z = ORTH_DIST
		#3d modes
		camera_modes.PERS_BALANCED:
			$Camera3D.position.x = (p1.position.x + p2.position.x)/2
			$Camera3D.position.y = max(p1.position.y + 1, p2.position.y + 1)
			$Camera3D.position.z = clampf(abs(p1.position.x - p2.position.x)/2, 1.5, 1.825) + 0.5
		camera_modes.PERS_PLAYER1:
			$Camera3D.position.x = p1.position.x
			$Camera3D.position.y = p1.position.y + 1
			$Camera3D.position.z = 1.5
		camera_modes.PERS_PLAYER2:
			$Camera3D.position.x = p2.position.x
			$Camera3D.position.y = p2.position.y + 1
			$Camera3D.position.z = 1.5
	$Camera3D.position = $Camera3D.position.clamp(
		Vector3(-CAMERAMAXX, 0, $Camera3D.position.z),
		Vector3(CAMERAMAXX, CAMERAMAXY, $Camera3D.position.z)
	)

var directionDictionary = {
	"": "x",
	"up": "↑", "down": "↓", "left": "←", "right": "→",
	"upleft": "↖", "downleft": "↙",
	"upright": "↗", "downright": "↘"
}

func attack_value(attackHash: int) -> String:
	return (" Ø" if bool(attackHash % 2) else " 0") + \
	("Ø" if bool((attackHash >> 1) % 2) else "0") + \
	("Ø" if bool((attackHash >> 2) % 2) else "0") + \
	("Ø" if bool((attackHash >> 3) % 2) else "0") + \
	("Ø" if bool((attackHash >> 4) % 2) else "0") + \
	("Ø " if bool((attackHash >> 5) % 2) else "0 ")

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

func build_input_tracker(p1_buf : Dictionary, p2_buf : Dictionary) -> void:
	var lookup_string := ""
	var dirs := ["up", "down", "left", "right"]
	
	$HUD/P1Stats/Inputs.text = ""
	for i in range(len(p1_buf.up)):
		lookup_string = ""
		lookup_string += dirs[0] if p1_buf[dirs[0]][i][1] else ""
		lookup_string += dirs[1] if p1_buf[dirs[1]][i][1] else ""
		lookup_string += dirs[2] if p1_buf[dirs[2]][i][1] else ""
		lookup_string += dirs[3] if p1_buf[dirs[3]][i][1] else ""
		$HUD/P1Stats/Inputs.text += directionDictionary[lookup_string]
		$HUD/P1Stats/Inputs.text += "\t"
		for button in p1_buf:
			if button in dirs:
				if p1_buf[button][i][1]:
					$HUD/P1Stats/Inputs.text += ("[%s, %s]" % [str(p1_buf[button][i][0]), directionDictionary[button]])
				else:
					$HUD/P1Stats/Inputs.text += ("[%s, x]" % [str(p1_buf[button][i][0])])
			else:
				$HUD/P1Stats/Inputs.text += str(p1_buf[button][i])
		$HUD/P1Stats/Inputs.text += "\n"
	
	$HUD/P2Stats/Inputs.text = ""
	for i in range(len(p2_buf.up)):
		lookup_string = ""
		lookup_string += dirs[0] if p2_buf[dirs[0]][i][1] else ""
		lookup_string += dirs[1] if p2_buf[dirs[1]][i][1] else ""
		lookup_string += dirs[2] if p2_buf[dirs[2]][i][1] else ""
		lookup_string += dirs[3] if p2_buf[dirs[3]][i][1] else ""
		$HUD/P2Stats/Inputs.text += directionDictionary[lookup_string]
		$HUD/P2Stats/Inputs.text += "\t"
		for button in p2_buf:
			if button in dirs:
				if p2_buf[button][i][1]:
					$HUD/P2Stats/Inputs.text += ("[%s, %s]" % [str(p2_buf[button][i][0]), directionDictionary[button]])
				else:
					$HUD/P2Stats/Inputs.text += ("[%s, x]" % [str(p2_buf[button][i][0])])
			else:
				$HUD/P2Stats/Inputs.text += str(p2_buf[button][i])
		$HUD/P2Stats/Inputs.text += "\n"

#convert to hash to simplify comparisons
func get_current_input_hashes() -> Array: return [
	(
		(int(p1_buttons[0]) * 1) +
		(int(p1_buttons[1]) * 2) +
		(int(p1_buttons[2]) * 4) +
		(int(p1_buttons[3]) * 8) +
		((int(p1.BUTTONCOUNT > 0 and p1_buttons[4])) * 16) +
		((int(p1.BUTTONCOUNT > 1 and p1_buttons[5])) * 32) +
		((int(p1.BUTTONCOUNT > 2 and p1_buttons[6])) * 64) +
		((int(p1.BUTTONCOUNT > 3 and p1_buttons[7])) * 128) +
		((int(p1.BUTTONCOUNT > 4 and p1_buttons[8])) * 256) +
		((int(p1.BUTTONCOUNT > 5 and p1_buttons[9])) * 512)
	),
	(
		(int(p2_buttons[0]) * 1) +
		(int(p2_buttons[1]) * 2) +
		(int(p2_buttons[2]) * 4) +
		(int(p2_buttons[3]) * 8) +
		((int(p2.BUTTONCOUNT > 0 and p2_buttons[4])) * 16) +
		((int(p2.BUTTONCOUNT > 1 and p2_buttons[5])) * 32) +
		((int(p2.BUTTONCOUNT > 2 and p2_buttons[6])) * 64) +
		((int(p2.BUTTONCOUNT > 3 and p2_buttons[7])) * 128) +
		((int(p2.BUTTONCOUNT > 4 and p2_buttons[8])) * 256) +
		((int(p2.BUTTONCOUNT > 5 and p2_buttons[9])) * 512)
	)
]

#ditto, but for an already completed input
func generate_prior_input_hash(player_inputs: Dictionary):
	var fail_case := [[0,false]]
	return (
		(int(player_inputs.get("up", fail_case)[-1][1]) * 1) +
		(int(player_inputs.get("down", fail_case)[-1][1]) * 2) +
		(int(player_inputs.get("left", fail_case)[-1][1]) * 4) +
		(int(player_inputs.get("right", fail_case)[-1][1]) * 8) +
		(int(player_inputs.get("button0", fail_case)[-1][1]) * 16) +
		(int(player_inputs.get("button1", fail_case)[-1][1]) * 32) +
		(int(player_inputs.get("button2", fail_case)[-1][1]) * 64) +
		(int(player_inputs.get("button3", fail_case)[-1][1]) * 128) +
		(int(player_inputs.get("button4", fail_case)[-1][1]) * 256) +
		(int(player_inputs.get("button5", fail_case)[-1][1]) * 512)
	)
	

func increment_inputs(player_inputs: Dictionary):
	for inp in player_inputs:
		player_inputs[inp][-1][0] += 1

func create_new_input_set(player_inputs: Dictionary, new_inputs: Array):
	var ind = 0
	for inp in player_inputs:
		if new_inputs[ind] == player_inputs[inp][-1][1]: #if the same input is the same here
			player_inputs[inp].append(player_inputs[inp][-1].duplicate()) #copy it over
		else: #otherwise, this is a new input, so make a new entry
			player_inputs[inp].append([1, new_inputs[ind]])
		ind += 1

func create_inputs():
	p1_buttons[0] = Input.is_action_pressed("first_up")
	p1_buttons[1] = Input.is_action_pressed("first_down")
	if p1_buttons[0] == p1_buttons[1]: #no conflicting directions
		p1_buttons[0] = false
		p1_buttons[1] = false
	p1_buttons[2] = Input.is_action_pressed("first_left")
	p1_buttons[3] = Input.is_action_pressed("first_right")
	if p1_buttons[2] == p1_buttons[3]: #ditto
		p1_buttons[2] = false
		p1_buttons[3] = false
	for button in range(p1.BUTTONCOUNT):
		p1_buttons[button + 4] = Input.is_action_pressed("first_button" + str(button))
	
	p2_buttons[0] = Input.is_action_pressed("second_up")
	p2_buttons[1] = Input.is_action_pressed("second_down")
	if p2_buttons[0] == p2_buttons[1]: #no conflicting directions
		p2_buttons[0] = false
		p2_buttons[1] = false
	p2_buttons[2] = Input.is_action_pressed("second_left")
	p2_buttons[3] = Input.is_action_pressed("second_right")
	if p2_buttons[2] == p2_buttons[3]: #ditto
		p2_buttons[2] = false
		p2_buttons[3] = false
	for button in range(p2.BUTTONCOUNT):
		p2_buttons[button + 4] = Input.is_action_pressed("second_button" + str(button))
	
	var comp_hashes = get_current_input_hashes()
	
	if generate_prior_input_hash(p1_inputs) != comp_hashes[0]:
		create_new_input_set(p1_inputs, p1_buttons)
		p1_input_index += 1
	else:
		increment_inputs(p1_inputs)
	
	if generate_prior_input_hash(p2_inputs) != comp_hashes[1]:
		create_new_input_set(p2_inputs, p2_buttons)
		p2_input_index += 1
	else:
		increment_inputs(p2_inputs)

func move_inputs_and_iterate():
	var p1_buf = slice_input_dictionary(
		p1_inputs, max(0, p1_input_index - p1.input_buffer_len),
		p1_input_index + 1
	)
	var p2_buf = slice_input_dictionary(
		p2_inputs,
		max(0, p2_input_index - p2.input_buffer_len),
		p2_input_index + 1
	)
	build_input_tracker(p1_buf, p2_buf)
	
	var p1_attackers = (p1.return_attackers() as Array[Hitbox])
	for p1_attacker in p1_attackers:
		var hit = p1.damage_step(p1_attacker)
		p1_attacker.queue_free()
		if hit:
			p2.attack_connected = true
			p2.attack_hurt = true
			p2_combo += 1
			p2.on_hit(p1_attacker.on_hit)
		else:
			p2.attack_connected = true
			p2.attack_hurt = false
			p2.on_block(p1_attacker.on_block)
	
	var p2_attackers = (p2.return_attackers() as Array[Hitbox])
	for p2_attacker in p2_attackers:
		var hit = p2.damage_step(p2_attacker)
		p2_attacker.queue_free()
		if hit:
			p1.attack_connected = true
			p1.attack_hurt = true
			p1_combo += 1
			p1.on_hit(p2_attacker.on_hit)
		else:
			p1.attack_connected = true
			p1.attack_hurt = false
			p1.on_block(p2_attacker.on_block)
	
	p1.input_step(p1_buf)
	p2.input_step(p2_buf)

func check_combo():
	if not p1.is_in_hurting_state():
		p2_combo = 0
	if not p2.is_in_hurting_state():
		p1_combo = 0

func character_positioning():
	p1.position.x = clamp(p1.position.x, -MOVEMENTBOUNDX, MOVEMENTBOUNDX)
	p2.position.x = clamp(p2.position.x, -MOVEMENTBOUNDX, MOVEMENTBOUNDX)
	p1.distance = p1.position.x - p2.position.x
	p2.distance = p2.position.x - p1.position.x

func register_hitbox(hitbox):
	add_child(hitbox, true)

func register_projectile(projectile):
	projectile.projectile_ended.connect(delete_projectile)
	add_child(projectile, true)
	projectiles.append(projectile)

func delete_projectile(projectile):
	projectiles.erase(projectile)

func player_defeated(player_number):
	print(player_number)
	moment = moments.ROUND_END

func training_mode_settings():
	if p1_reset_health_on_drop and not p2_combo:
		p1.health = p1_health_reset
	if p2_reset_health_on_drop and not p1_combo:
		p2.health = p2_health_reset

func _physics_process(_delta):
	camera_control(camera_mode)
	match moment:
		moments.INTRO:
			move_inputs_and_iterate()
			if p1.post_intro() and p2.post_intro():
				moment = moments.GAME
				$HUD/Fight.visible = true
			check_combo()
			character_positioning()
			update_hud()
		moments.GAME:
			# handle projectiles
			for proj in projectiles:
				proj.tick()
			create_inputs()
			move_inputs_and_iterate()
			check_combo()
			training_mode_settings()
			character_positioning()
			update_hud()
			$HUD/Fight.modulate.a8 -= 10
		moments.ROUND_END:
			move_inputs_and_iterate()
			check_combo()
			character_positioning()
			if p1.post_outro() and p2.post_outro():
				get_tree().reload_current_scene()

func _on_p1_health_reset_switch_toggled(toggled_on):
	p1_reset_health_on_drop = toggled_on

func _on_p1_health_reset_drag_ended(value_changed):
	if value_changed and p1_reset_health_on_drop:
		p1_health_reset = $HUD/TrainingModeControls/P1Controls/HBoxContainer/HealthReset.value

func _on_p2_health_reset_switch_toggled(toggled_on):
	p1_reset_health_on_drop = toggled_on

func _on_p2_health_reset_drag_ended(value_changed):
	if value_changed and p2_reset_health_on_drop:
		p2_health_reset = $HUD/TrainingModeControls/P2Controls/HBoxContainer/HealthReset.value

func _on_reset_button_up():
	get_tree().reload_current_scene()
