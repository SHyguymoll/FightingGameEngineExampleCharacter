extends Node3D

#required variables from Content.gd
var p1
var p2
var stage

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

@export var cameraMode = 0
const CAMERAMAXX = 6
const CAMERAMAXY = 10
const MOVEMENTBOUNDX = 8

@export var player_to_test : PackedScene
@export var scene_to_test : PackedScene

func make_hud():
	$HUD/P1Health.max_value = p1.health
	$HUD/P1Health.value = p1.health
	$HUD/P1Char.text = p1.char_name
	$HUD/P2Health.max_value = p2.health
	$HUD/P2Health.value = p2.health
	$HUD/P2Char.text = p2.char_name

func init_fighters():
	for i in range(p1.BUTTONCOUNT):
		p1_inputs["button" + str(i)] = [[0, false]]
	p1.position = Vector3(p1.start_x_offset * -1,0,0)
	p1.right_facing = true
	p1.update_state(p1.state_start, 0)
	p1.initialize_boxes(true)
	p1.char_name += " p1"
	
	for i in range(p2.BUTTONCOUNT):
		p2_inputs["button" + str(i)] = [[0, false]]
	p2.position = Vector3(p2.start_x_offset,0,0)
	p2.right_facing = false
	p2.update_state(p2.state_start, 0)
	p2.initialize_boxes(false)
	p2.char_name += " p2"

func _ready():
	add_child(scene_to_test.instantiate())
	p1 = player_to_test.instantiate()
	p2 = player_to_test.instantiate()
	make_hud()
	init_fighters()
	add_child(p1)
	add_child(p2)

const ORTH_DIST = 1.328125

func camera_control(mode: int):
	$Camera3D.projection = 1 if mode < 3 else 0 #0 = Perspective, 1 = Orthagonal
	match mode:
		#2d modes
		0: #default
			$Camera3D.position.x = (p1.position.x + p2.position.x)/2
			$Camera3D.position.y = max(p1.position.y + 1, p2.position.y + 1)
			$Camera3D.position.z = ORTH_DIST
			$Camera3D.size = clampf(abs(p1.position.x - p2.position.x)/2, 3.5, 6)
		1: #focus player1
			$Camera3D.position.x = p1.position.x
			$Camera3D.position.y = p1.position.y + 1
			$Camera3D.position.z = ORTH_DIST
		2: #focus player2
			$Camera3D.position.x = p2.position.x
			$Camera3D.position.y = p2.position.y + 1
			$Camera3D.position.z = ORTH_DIST
		#3d modes
		3: #default
			$Camera3D.position.x = (p1.position.x + p2.position.x)/2
			$Camera3D.position.y = max(p1.position.y + 1, p2.position.y + 1)
			$Camera3D.position.z = clampf(abs(p1.position.x - p2.position.x)/2, 1.5, 1.825) + 0.5
		4: #focus player1
			$Camera3D.position.x = p1.position.x
			$Camera3D.position.y = p1.position.y + 1
			$Camera3D.position.z = 1.5
		5: #focus player2
			$Camera3D.position.x = p2.position.x
			$Camera3D.position.y = p2.position.y + 1
			$Camera3D.position.z = 1.5
	$Camera3D.position.clamp(
		Vector3(-CAMERAMAXX, 0, $Camera3D.position.z),
		Vector3(CAMERAMAXX, CAMERAMAXY, $Camera3D.position.z)
	)

var directionDictionary = { 0: "x", 1: "↑", 2: "↓", 4: "←", 8: "→", 5: "↖", 6: "↙", 9: "↗", 10: "↘" }

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

func build_inputs_tracked() -> void:
	var latest_input_set = slice_input_dictionary(p1_inputs, max(0,p1_input_index - p1.input_buffer_len), p1_input_index + 1)
	$HUD/P1Inputs.text = ""
	for i in range(len(latest_input_set.up)):
		for button in latest_input_set:
			$HUD/P1Inputs.text += str(latest_input_set[button][i])
		$HUD/P1Inputs.text += "\n"
	
	latest_input_set = slice_input_dictionary(p2_inputs, max(0,p2_input_index - p2.input_buffer_len), p2_input_index + 1)
	$HUD/P2Inputs.text = ""
	for i in range(len(latest_input_set.up)):
		for button in latest_input_set:
			$HUD/P2Inputs.text += str(latest_input_set[button][i])
		$HUD/P2Inputs.text += "\n"

#convert to hash to simplify comparisons
func get_current_input_hashes() -> Array: return [
	(int(p1_buttons[0]) * 1) + \
	(int(p1_buttons[1]) * 2) + \
	(int(p1_buttons[2]) * 4) + \
	(int(p1_buttons[3]) * 8) + \
	max(0, ((int(p1_buttons[4]) - int(p1.BUTTONCOUNT < 1)) * 16)) + \
	max(0, ((int(p1_buttons[5]) - int(p1.BUTTONCOUNT < 2)) * 32)) + \
	max(0, ((int(p1_buttons[6]) - int(p1.BUTTONCOUNT < 3)) * 64)) + \
	max(0, ((int(p1_buttons[7]) - int(p1.BUTTONCOUNT < 4)) * 128)) + \
	max(0, ((int(p1_buttons[8]) - int(p1.BUTTONCOUNT < 5)) * 256)) + \
	max(0, ((int(p1_buttons[9]) - int(p1.BUTTONCOUNT < 6)) * 512)),
	(int(p2_buttons[0]) * 1) + \
	(int(p2_buttons[1]) * 2) + \
	(int(p2_buttons[2]) * 4) + \
	(int(p2_buttons[3]) * 8) + \
	max(0, ((int(p2_buttons[4]) - int(p2.BUTTONCOUNT < 1)) * 16)) + \
	max(0, ((int(p2_buttons[5]) - int(p2.BUTTONCOUNT < 2)) * 32)) + \
	max(0, ((int(p2_buttons[6]) - int(p2.BUTTONCOUNT < 3)) * 64)) + \
	max(0, ((int(p2_buttons[7]) - int(p2.BUTTONCOUNT < 4)) * 128)) + \
	max(0, ((int(p2_buttons[8]) - int(p2.BUTTONCOUNT < 5)) * 256)) + \
	max(0, ((int(p2_buttons[9]) - int(p2.BUTTONCOUNT < 6)) * 512))
]

func generate_prior_input_hash(player_inputs: Dictionary):
	var val = 0
	var multiplier = 1
	for inp in player_inputs:
		if player_inputs[inp][-1][1]:
			val += multiplier
		multiplier *= 2
	return val

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

func handle_inputs():
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
	
	var calcHashes = get_current_input_hashes()
	
	if generate_prior_input_hash(p1_inputs) != calcHashes[0]:
		create_new_input_set(p1_inputs, p1_buttons)
		p1_input_index += 1
	else:
		increment_inputs(p1_inputs)
	
	if generate_prior_input_hash(p2_inputs) != calcHashes[1]:
		create_new_input_set(p2_inputs, p2_buttons)
		p2_input_index += 1
	else:
		increment_inputs(p2_inputs)
	
	build_inputs_tracked()
	var p1_buf = slice_input_dictionary(
		p1_inputs, max(0, p1_input_index - p1.input_buffer_len),
		p1_input_index + 1
	)
	var p2_buf = slice_input_dictionary(
		p2_inputs,
		max(0, p2_input_index - p2.input_buffer_len),
		p2_input_index + 1
	)
	
	p1.step(p1_buf, p1_input_index)
	p2.step(p2_buf, p2_input_index)

func character_positioning():
	p1.position.x = clamp(p1.position.x, -MOVEMENTBOUNDX, MOVEMENTBOUNDX)
	p2.position.x = clamp(p2.position.x, -MOVEMENTBOUNDX, MOVEMENTBOUNDX)
	p1.distance = p1.position.x - p2.position.x
	p2.distance = p2.position.x - p1.position.x
	p1.reset_facing()
	p2.reset_facing()

func _physics_process(_delta):
	camera_control(cameraMode)
	handle_inputs()
	character_positioning()
