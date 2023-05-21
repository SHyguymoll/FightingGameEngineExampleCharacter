extends Node3D

#required variables from Content.gd
var p1
var p2
var stage

#required variables from InputHandle.gd
var p1_buttons = [false, false, false, false, false, false, false, false, false, false]
var p2_buttons = [false, false, false, false, false, false, false, false, false, false]

var p1_inputs : Array = []
var p2_inputs : Array = []
var p1_input_index : int = 0
var p2_input_index : int = 0


enum statesBase {
	Idle = 3,
	WalkForward,
	WalkBack,
	Crouch,
}

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
	p1.position = Vector3(p1.start_x_offset * -1,0,0)
	p1.right_facing = true
	p1.update_state(p1.state_start, 0)
	p1.initialize_boxes(true)
	
	p2.position = Vector3(p2.start_x_offset,0,0)
	p2.right_facing = false
	p2.update_state(p2.state_start, 0)
	p2.initialize_boxes(false)

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

func build_inputs_tracked() -> void:
	var latestInputs = p1_inputs.slice(max(0,p1_input_index - p1.input_buffer_len), p1_input_index)
	$HUD/P1Inputs.text = ""
	for input in latestInputs:
		if input[0] < 0:
			return
		$HUD/P1Inputs.text += directionDictionary[input[0] % 16] + attack_value(input[0] >> 4) + str(input[1]) + "\n"
	
	latestInputs = p2_inputs.slice(max(0,p2_input_index - p2.input_buffer_len), p2_input_index)
	$HUD/P2Inputs.text = ""
	for input in latestInputs:
		if input[0] < 0:
			return
		$HUD/P2Inputs.text += str(input[1]) + attack_value(input[0] >> 4) + directionDictionary[input[0] % 16] + "\n"

func get_input_hashes() -> Array: return [ #convert to hash to send less data (a single int compared to an array)
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
	
	var calcHashes = get_input_hashes()
	if len(p1_inputs) == 0:
		p1_inputs.append([calcHashes[0], 1])
	elif p1_inputs[p1_input_index][0] != calcHashes[0]:
		p1_inputs.append([calcHashes[0], 1])
		p1_input_index += 1
	else:
		p1_inputs[p1_input_index][1] += 1
	
	if len(p2_inputs) == 0:
		p2_inputs.append([calcHashes[1], 1])
	elif p2_inputs[p2_input_index][0] != calcHashes[1]:
		p2_inputs.append([calcHashes[1], 1])
		p2_input_index += 1
	else:
		p2_inputs[p2_input_index][1] += 1
	
	build_inputs_tracked()
	var max_p1_ind = max(0, p1_input_index - p1.input_buffer_len)
	var p1_buf
	var p2_buf
	if p1_input_index - max_p1_ind == 0:
		p1_buf = p1_inputs.slice(max_p1_ind, p1_input_index + 1)
	else:
		p1_buf = p1_inputs.slice(max_p1_ind, p1_input_index)
	var max_p2_ind = max(0, p2_input_index - p2.input_buffer_len)
	if p2_input_index - max_p2_ind == 0:
		p2_buf = p2_inputs.slice(max_p2_ind, p1_input_index + 1)
	else:
		p2_buf = p2_inputs.slice(max_p2_ind, p1_input_index)
	
	p1.step(p1_buf)
	p2.step(p2_buf)

const HALFPI = 180
const TURNAROUND_ANIMSTEP = 3

#func characterActBasic():
#	if player1.stateCurrent in statesBase:
#		if player1.position < player2.position:
#			if player1.rightFacing != true:
#				player1.rightFacing = true
#				if player1.stateCurrent == statesBase.Idle:
#					player1.animStep = TURNAROUND_ANIMSTEP
#				if player1.stateCurrent == statesBase.Crouch:
#					player1.animStep = TURNAROUND_ANIMSTEP
#		else:
#			if player1.rightFacing != false:
#				player1.rightFacing = false
#				if player1.stateCurrent == statesBase.Idle:
#					player1.animStep = TURNAROUND_ANIMSTEP
#				if player1.stateCurrent == statesBase.Crouch:
#					player1.animStep = TURNAROUND_ANIMSTEP
#		player1.rotation_degrees.y = HALFPI * int(player1.rightFacing)
#	if player2.stateCurrent in statesBase:
#		if player2.position < player1.position:
#			if player2.rightFacing != true:
#				player2.rightFacing = true
#				if player2.stateCurrent == statesBase.Idle:
#					player2.animStep = TURNAROUND_ANIMSTEP
#				if player2.stateCurrent == statesBase.Crouch:
#					player2.animStep = TURNAROUND_ANIMSTEP
#		else:
#			if player2.rightFacing != false:
#				player2.rightFacing = false
#				if player2.stateCurrent == statesBase.Idle:
#					player2.animStep = TURNAROUND_ANIMSTEP
#				if player2.stateCurrent == statesBase.Crouch:
#					player2.animStep = TURNAROUND_ANIMSTEP
#		player2.rotation_degrees.y = HALFPI * int(player2.rightFacing)
#	player1.position.x = clamp(player1.position.x, -MOVEMENTBOUNDX, MOVEMENTBOUNDX)
#	player2.position.x = clamp(player2.position.x, -MOVEMENTBOUNDX, MOVEMENTBOUNDX)
#	player1.distance = abs(player1.position.x - player2.position.x)
#	player2.distance = abs(player1.position.x - player2.position.x)
	

func _physics_process(_delta):
	camera_control(cameraMode)
	handle_inputs()
#	characterActBasic()
