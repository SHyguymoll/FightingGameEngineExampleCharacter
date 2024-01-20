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

#required variables and methods from Game.gd
@export var cameraMode = 0
const CAMERAMAXX = 6
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
	$HUD/P1Health.max_value = p1.health
	$HUD/P1Health.value = p1.health
	$HUD/P1Char.text = p1.char_name
	$HUD/P1State.text = p1.states.keys()[p1.current_state]
	$HUD/P1PosVel.text = str(p1.position) + "\n" + str(p1.velocity)
	
	# player 2
	$HUD/P2Health.max_value = p2.health
	$HUD/P2Health.value = p2.health
	$HUD/P2Char.text = p2.char_name
	$HUD/P2State.text = p2.states.keys()[p2.current_state]
	$HUD/P2PosVel.text = str(p2.position) + "\n" + str(p2.velocity)
	
	# game itself
	$HUD/Fight.visible = false

func update_hud(game_start := true):
	# player 1
	$HUD/P1Health.value = p1.health
	$HUD/P1State.text = p1.states.keys()[p1.current_state]
	if "attack" in $HUD/P1State.text:
		$HUD/P1State.text += " : " + p1.current_attack
	$HUD/P1PosVel.text = str(p1.position) + "\n" + str(p1.velocity)
	$HUD/P1Combo.text = str(p1_combo)
	
	# player 2
	$HUD/P2Health.value = p2.health
	$HUD/P2State.text = p2.states.keys()[p2.current_state]
	if "attack" in $HUD/P2State.text:
		$HUD/P2State.text += " : " + p2.current_attack
	$HUD/P2PosVel.text = str(p2.position) + "\n" + str(p2.velocity)
	$HUD/P2Combo.text = str(p2_combo)
	
	# game itself
	if game_start:
		$HUD/Fight.modulate.a8 -= 10

func init_fighters():
	for i in range(p1.BUTTONCOUNT):
		p1_inputs["button" + str(i)] = [[0, false]]
	p1.player_number = 1
	p1.position = Vector3(p1.start_x_offset * -1,0,0)
	p1.right_facing = true
	p1.update_state(p1.state_start)
	p1.initialize_boxes(true)
	p1.char_name += " p1"
	p1.hitbox_created.connect(register_hitbox)
	p1.projectile_created.connect(register_projectile)
	p1.defeated.connect(player_defeated)
	
	for i in range(p2.BUTTONCOUNT):
		p2_inputs["button" + str(i)] = [[0, false]]
	p2.player_number = 2
	p2.position = Vector3(p2.start_x_offset,0,0)
	p2.right_facing = false
	p2.update_state(p2.state_start)
	p2.initialize_boxes(false)
	p2.char_name += " p2"
	p2.hitbox_created.connect(register_hitbox)
	p2.projectile_created.connect(register_projectile)
	p2.defeated.connect(player_defeated)

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

func camera_control(mode: int):
	$Camera3D.projection = CAMERA_ORTH if mode < 3 else CAMERA_PERSPECTIVE
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

func build_inputs_tracked(p1_buf : Dictionary, p2_buf : Dictionary) -> void:
	var lookup_string := ""
	var dirs := ["up", "down", "left", "right"]
	
	$HUD/P1Inputs.text = ""
	for i in range(len(p1_buf.up)):
		lookup_string = ""
		lookup_string += dirs[0] if p1_buf[dirs[0]][i][1] else ""
		lookup_string += dirs[1] if p1_buf[dirs[1]][i][1] else ""
		lookup_string += dirs[2] if p1_buf[dirs[2]][i][1] else ""
		lookup_string += dirs[3] if p1_buf[dirs[3]][i][1] else ""
		$HUD/P1Inputs.text += directionDictionary[lookup_string]
		$HUD/P1Inputs.text += "\t"
		for button in p1_buf:
			if button in dirs:
				$HUD/P1Inputs.text += str([directionDictionary[button], p1_buf[button][i][1]])
			else:
				$HUD/P1Inputs.text += str(p1_buf[button][i])
		$HUD/P1Inputs.text += "\n"
	
	$HUD/P2Inputs.text = ""
	for i in range(len(p2_buf.up)):
		lookup_string = ""
		lookup_string += dirs[0] if p2_buf[dirs[0]][i][1] else ""
		lookup_string += dirs[1] if p2_buf[dirs[1]][i][1] else ""
		lookup_string += dirs[2] if p2_buf[dirs[2]][i][1] else ""
		lookup_string += dirs[3] if p2_buf[dirs[3]][i][1] else ""
		$HUD/P2Inputs.text += directionDictionary[lookup_string]
		$HUD/P2Inputs.text += "\t"
		for button in p2_buf:
			if button in dirs:
				$HUD/P2Inputs.text += str([directionDictionary[button], p2_buf[button][i][1]])
			else:
				$HUD/P2Inputs.text += str(p2_buf[button][i])
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
	build_inputs_tracked(p1_buf, p2_buf)
	
	if p1.return_overlaps():
		if p1.damage_step(p1.return_attacker()):
			p2.attack_connected = true
			p2.attack_hurt = true
			p2_combo += 1
		else:
			p2.attack_connected = true
			p2.attack_hurt = false
	if p2.return_overlaps():
		if p2.damage_step(p2.return_attacker()):
			p1.attack_connected = true
			p1.attack_hurt = true
			p1_combo += 1
		else:
			p1.attack_connected = true
			p1.attack_hurt = false
	
	for prot in projectiles:
		if prot.return_overlaps():
			prot.destroy()
	
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
	p1.reset_facing()
	p2.reset_facing()

func register_hitbox(hitbox):
	add_child(hitbox, true)

func register_projectile(projectile):
	projectile.projectile_ended.connect(delete_projectile)
	add_child(projectile, true)
	projectiles.append(projectile)

func delete_projectile(projectile):
	projectiles.erase(projectile)

func player_defeated(player: int):
	pass

func _physics_process(_delta):
	camera_control(cameraMode)
	
	match moment:
		moments.INTRO:
			move_inputs_and_iterate()
			if p1.post_intro() and p2.post_intro():
				moment = moments.GAME
				$HUD/Fight.visible = true
			check_combo()
			update_hud(false)
		moments.GAME:
			# handle projectiles
			for proj in projectiles:
				proj.tick()
			create_inputs()
			move_inputs_and_iterate()
			check_combo()
			character_positioning()
			update_hud()
		moments.ROUND_END:
			pass
	
