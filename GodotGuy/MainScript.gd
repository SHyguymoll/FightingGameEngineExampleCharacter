extends CharacterBody3D

var fighterName = "Godot Guy"
var tscnFile = "res://GodotGuy/scenes/GodotGuy.tscn"
var charSelectIcon = "res://GodotGuy/Icon.png"

const BUFFERSIZE = 10

var health = 100
var walkSpeed = 1

const GRAVITY = -0.5
const MIN_VEL = -6.5

var distance = 0.0
var rightFacing = true
var attackEnded = true
var damageMultiplier = 1.0
var defenseMultiplier = 1.0
var knockbackHorizontal = 0.0
var knockbackVertical = 0.0

const STARTXOFFSET = 2
const BUTTONCOUNT = 4

#State transitions are handled by a FSM implemented as match statements
enum states {
	intro, round_win, set_win, #round stuff
	idle, crouch, #basic basics
	walk_forward, walk_back, #lateral movement
	jump_forward, jump_neutral, jump_back, #aerial movement
	attack, post_attack, #handling attacks
	block_high, block_low, get_up, #handling getting attacked well
	hurt_high, hurt_low, hurt_crouch, #not handling getting attacked well
	hurt_fall, hurt_lie, hurt_bounce, #REALLY not handling getting attacked well
	}
var state_current: states = states.idle

func update_state(new_state: states, reset_animation: bool):
	state_current = new_state
	if reset_animation:
		anim_timer = 0

# attack format:
#"<Name>":
#	{
#		"damage": <damage>,
#		"type": "<hit location>",
#		"kb_hori": <horizontal knockback value>,
#		"kb_vert": <vertical knockback value>,
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
			"hitboxes": ""  #TODO
		},
	"stand_b":
		{
			"damage": 4,
			"type": "mid",
			"kbHori": 0.6,
			"kbVert": 0.0,
			"hitboxes": ""
		},
	"stand_c": #TODO
		{
			"damage": 4,
			"type": "mid",
			"kbHori": 0.6,
			"kbVert": 0.0,
			"hitboxes": ""
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
var animations = {
	"idle":
		{
			"animation_length": 1,
			0: [0,0],
		},
	"crouch":
		{
			"animation_length": 1,
			0: [1,0],
		},
	"walk_right":
		{
			"animation_length": 7,
			0: [2,0],
			1: [3,0],
			2: [4,0],
			3: [5,0],
			4: [6,0],
			5: [7,0],
			6: [8,0],
			7: [9,0]
			
		},
	"walk_left":
		{
			"animation_length": 7,
			0: [9,0],
			1: [8,0],
			2: [7,0],
			3: [6,0],
			4: [5,0],
			5: [4,0],
			6: [3,0],
			7: [2,0]
		},
	"crouch_a":
		{
			"animation_length": 5,
			0: [0,1],
			2: [1,1],
			3: [2,1],
		},
	"crouch_b":
		{
			"animation_length": 7,
			0: [0,2],
			2: [1,2],
			4: [2,2],
			5: [3,2],
		},
	"crouch_c":
		{
			"animation_length": 10,
			0: [0,3],
			1: [1,3],
			2: [2,3],
			5: [3,3],
			6: [4,3],
			7: [5,3],
			8: [6,3],
		},
	"stand_a":
		{
			"animation_length": 4,
			0: [6,1],
			2: [7,1],
			3: [8,1],
		},
	"stand_b":
		{
			"animation_length": 6,
			0: [4,2],
			2: [5,2],
			3: [6,2],
			4: [7,2],
			5: [8,2],
		},
	"stand_c":
		{
			"animation_length": 11,
			0: [0,4],
			2: [1,4],
			4: [2,4],
			5: [3,4],
			6: [4,4],
			9: [5,4],
			10: [6,4],
		},
}

var current_animation: String
var anim_timer = 0

func anim():
	if animations[current_animation][anim_timer] != null:
		$Sprite.frame_coords = animations[current_animation][anim_timer]
	anim_timer += 1

# Hitboxes and Hurtboxes are handled through a dictionary for easy reuse.
# hitbox format:
#"<Name>":
#	{
#		"hitboxes": [<hitbox path>, ...],
#		"hurtboxes": [<hurtbox path>, ...],
#		"mode": either "add" or "set",
#		"extra": ... This one is up to whatever
#	}

#TODO: hitboxes
var boxes = {
	"basic": {
		"hitboxes": [],
		"hurtboxes": [],
		"mode": "set",
	}
}

var tooClose = false

enum inputs {Up = 1, Down = 2, Left = 4, Right = 8, A = 16, B = 32, C = 64}

func decodeHash(inputHash: int) -> Array:
	var decodedHash = [false, false, false, false, false, false, false, false]
	var inpVal = inputs.values()
	for i in range(BUTTONCOUNT + 3,-1,-1): #arrays start at 0, so everything is subtracted by 1 (4 directions -> 3)
		if inputHash >= inpVal[i]:
			inputHash -= inpVal[i]
			decodedHash[i] = true
	return decodedHash

#func ifAttacking(buffer: Array) -> void:
#	var decBuf = []
#	for i in range(len(buffer)):
#		decBuf.append([decodeHash(buffer[i][0]), buffer[i][1]])
#	match stateCurrent:
#		states.Idle, states.Walk_Back, states.Walk_Forward:
#			if decBuf[-1][0][4]:
#				animStep = 0
#			if decBuf[-1][0][5]:
#				animStep = 1
#			if decBuf[-1][0][6]:
#				animStep = 2
#		states.Crouch:
#			if decBuf[-1][0][4]:
#				animStep = 10
#			if decBuf[-1][0][5]:
#				animStep = 11
#			if decBuf[-1][0][6]:
#				animStep = 12
#		states.Jump_Neutral, states.Jump_Back, states.Jump_Forward:
#			if decBuf[-1][0][4]:
#				animStep = 20
#			if decBuf[-1][0][5]:
#				animStep = 21
#			if decBuf[-1][0][6]:
#				animStep = 22
#	stateCurrent = states.Attack
#	attackEnded = false

func walkCheck(buffer: Array) -> int: #returns -1 (trying to walk away), 0 (no walking inputs), and 1 (trying to walk towards)
	return int((buffer[3] and rightFacing) or (buffer[2] and !rightFacing)) + -1*int((buffer[2] and rightFacing) or (buffer[3] and !rightFacing))

#func handleInput(buffer: Array):
#	var decInp = decodeHash(buffer[-1][0]) #end of buffer is newest button, first element is input hash
#	var heldTime = buffer[-1][1]
#	match stateCurrent:
#		states.Idle:
#			var walkDirection = walkCheck(decInp)
#			if walkDirection > 0:
#				if !tooClose:
#					stateCurrent = states.Walk_Forward
#			if walkDirection < 0:
#				if distance < 5:
#					stateCurrent = states.Walk_Back
#			if (decInp[0]):
#				animStep = 0
#				if (decInp[3] and rightFacing) or (decInp[2] and !rightFacing):
#					stateCurrent = states.Jump_Forward
#				elif (decInp[2] and rightFacing) or (decInp[3] and !rightFacing):
#					stateCurrent = states.Jump_Back
#				else:
#					stateCurrent = states.Jump_Neutral
#			if buffer[-1][0] >= inputs.Up + inputs.Down + inputs.Left + inputs.Right: #if any attack input is found in hash, do this block
#				ifAttacking(buffer)
#		states.Walk_Forward:
#			if (!decInp[3] and rightFacing) or (!decInp[2] and !rightFacing) or tooClose:
#				stateCurrent = states.Idle
#			if(decInp[1]):
#				animStep = 1
#				stateCurrent = states.Crouch
#			if (decInp[0]):
#				animStep = 0
#				if (decInp[3] and rightFacing) or (decInp[2] and !rightFacing):
#					stateCurrent = states.Jump_Forward
#				elif (decInp[2] and rightFacing) or (decInp[3] and !rightFacing):
#					stateCurrent = states.Jump_Back
#				else:
#					stateCurrent = states.Jump_Neutral
#			if buffer[-1][0] >= inputs.A: #ditto
#				ifAttacking(buffer)
#		states.Walk_Back:
#			if (!decInp[2] and rightFacing) or (!decInp[3] and !rightFacing) or distance > 5:
#				stateCurrent = states.Idle
#			if(decInp[1]):
#				animStep = 1
#				stateCurrent = states.Crouch
#			if (decInp[0]):
#				animStep = 0
#				if (decInp[3] and rightFacing) or (decInp[2] and !rightFacing):
#					stateCurrent = states.Jump_Forward
#				elif (decInp[2] and rightFacing) or (decInp[3] and !rightFacing):
#					stateCurrent = states.Jump_Back
#				else:
#					stateCurrent = states.Jump_Neutral
#			if buffer[-1][0] >= inputs.A: #ditto
#				ifAttacking(buffer)
#		states.Attack:
#			if attackEnded:
#				match animStep:
#					0, 1, 2:
#						stateCurrent = states.Idle
#						animStep = 0
#					10, 11, 12:
#						stateCurrent = states.Crouch
#						animStep = 0
#					20, 21:
#						stateCurrent = states.Idle
#						animStep = 0
#					22:
#						stateCurrent = states.Jump_Neutral
#						animStep = 1

func action():
	pass
#	match stateCurrent:
#		states.Idle, states.Crouch:
#			velocity.x = 0
#		states.Walk_Forward:
#			velocity.x = (1 if rightFacing else -1) * walkSpeed
#		states.Walk_Back:
#			velocity.x = (-1 if rightFacing else 1) * walkSpeed
#			if tooClose:
#				velocity.x += (-1 if rightFacing else 1) * walkSpeed
#		states.Hurt_High, states.Hurt_Low, states.Hurt_Crouch, states.Block_High, states.Block_Low:
#			velocity.x += (-1 if rightFacing else 1) * knockbackHorizontal
#		states.Hurt_Fall:
#			velocity.x += (-1 if rightFacing else 1) * knockbackHorizontal
#			if animStep == 0:
#				velocity.y += knockbackVertical
#
#	velocity.y += GRAVITY
#	velocity.y = max(MIN_VEL, velocity.y)
#	if velocity.y < 0 and is_on_floor():
#		velocity.y = 0
	
	set_velocity(velocity)
	set_up_direction(Vector3.UP)
	move_and_slide()

func distanceCheckAreaEnter(_area):
	tooClose = true

func distanceCheckAreaExit(area):
	tooClose = false
	print(area)

func step():
	action()
	anim()
