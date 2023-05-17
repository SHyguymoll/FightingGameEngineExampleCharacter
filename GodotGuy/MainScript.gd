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

# attack format:
#"<Name>":
#	{
#		"damage": <damage>,
#		"type": "<hit location>",
#		"kb_hori": <horizontal knockback value>,
#		"kb_vert": <vertical knockback value>,
#		"animation": "<animation name>",
#		"hitboxes": "<hitbox set name>",
#		"extra": ... This one is up to whatever
#	}

# Animations are handled manually and controlled by the game engine during the physics_process step.
# Therefore, all animations top out at 60 FPS, which is a small constraint for now.
# animation format:
#"<Name>":
#	{
#		"animation_start_frame": [<animation frame x>, <animation frame y>],
#		"animation_length": <value>,
#		"animation": {
#			<frame_number>: [<animation frame x>, <animation frame y>]
#		},
#		"extra": ... This one is up to whatever
#	}

#TODO: attacks proper
var attack = {
	"stand_a":
		{
			"damage": 3,
			"type": "mid",
			"kbHori": -0.2,
			"kbVert": 0.2,
			"animation": ""
		},
	"stand_b":
		{
			"damage": 4,
			"type": "high",
			"kbHori": -0.6,
			"kbVert": 0.1,
			"animation": ""
		},
	"Low":
		{
			"damage": 4,
			"type": "low",
			"kbHori": -2.4,
			"kbVert": 0.8,
			"animation": ""
		},
	"Dash_Mid":
		{
			"damage": 4,
			"type": "mid",
			"kbHori": -0.1,
			"kbVert": 0.2,
			"animation": ""
		},
	"Dash_High":
		{
			"damage": 7,
			"type": "high",
			"kbHori": -1.2,
			"kbVert": 0.6,
			"animation": ""
		},
	"Dash_Low":
		{
			"damage": 7,
			"type": "high",
			"kbHori": -0.05,
			"kbVert": 3.25,
			"animation": ""
		},
}

#TODO: animations
var animations = {
	"idle":
		{
			"animation_start_frame": [0,0],
			"animation_length": 1,
			"animation": {}
		},
	"crouch":
		{
			"animation_start_frame": [1,0],
			"animation_length": 1,
			"animation": {}
		},
	"walk_right":
		{
			"animation_start_frame": [2,0],
			"animation_length": 7,
			"animation":
				{
					1: [3,0],
					2: [4,0],
					3: [5,0],
					4: [6,0],
					5: [7,0],
					6: [8,0],
					7: [9,0]
				}
		},
	"walk_left":
		{
			"animation_start_frame": [9,0],
			"animation_length": 7,
			"animation":
				{
					1: [8,0],
					2: [7,0],
					3: [6,0],
					4: [5,0],
					5: [4,0],
					6: [3,0],
					7: [2,0]
				}
		}
}

#TODO: hitboxes

var animStep = 0
var animTimer = 0
var tooClose = false

enum states {
	Intro, Round_Win, Set_Win,
	Idle, Crouch, Jump_Forward, Jump_Back, Jump_Neutral,
	Walk_Forward, Walk_Back,
	Attack,
	Block_High, Block_Low,
	Hurt_High, Hurt_Low, Hurt_Crouch, Hurt_Fall, Hurt_Lie, Hurt_Bounce, Get_Up,
	}
var stateCurrent = states.Idle

enum inputs {Up = 1, Down = 2, Left = 4, Right = 8, A = 16, B = 32, C = 64}

func decodeHash(inputHash: int) -> Array:
	var decodedHash = [false, false, false, false, false, false, false, false]
	var inpVal = inputs.values()
	for i in range(BUTTONCOUNT + 3,-1,-1): #arrays start at 0, so everything is subtracted by 1 (4 directions -> 3)
		if inputHash >= inpVal[i]:
			inputHash -= inpVal[i]
			decodedHash[i] = true
	return decodedHash

func ifAttacking(buffer: Array) -> void:
	var decBuf = []
	for i in range(len(buffer)):
		decBuf.append([decodeHash(buffer[i][0]), buffer[i][1]])
	match stateCurrent:
		states.Idle, states.Walk_Back, states.Walk_Forward:
			if decBuf[-1][0][4]:
				animStep = 0
			if decBuf[-1][0][5]:
				animStep = 1
			if decBuf[-1][0][6]:
				animStep = 2
		states.Crouch:
			if decBuf[-1][0][4]:
				animStep = 10
			if decBuf[-1][0][5]:
				animStep = 11
			if decBuf[-1][0][6]:
				animStep = 12
		states.Jump_Neutral, states.Jump_Back, states.Jump_Forward:
			if decBuf[-1][0][4]:
				animStep = 20
			if decBuf[-1][0][5]:
				animStep = 21
			if decBuf[-1][0][6]:
				animStep = 22
	stateCurrent = states.Attack
	attackEnded = false

func walkCheck(buffer: Array) -> int: #returns -1 (trying to walk away), 0 (no walking inputs), and 1 (trying to walk towards)
	return int((buffer[3] and rightFacing) or (buffer[2] and !rightFacing)) + -1*int((buffer[2] and rightFacing) or (buffer[3] and !rightFacing))

func handleInput(buffer: Array):
	var decInp = decodeHash(buffer[-1][0]) #end of buffer is newest button, first element is input hash
	var heldTime = buffer[-1][1]
	match stateCurrent:
		states.Idle:
			var walkDirection = walkCheck(decInp)
			if walkDirection > 0:
				if !tooClose:
					stateCurrent = states.Walk_Forward
			if walkDirection < 0:
				if distance < 5:
					stateCurrent = states.Walk_Back
			if (decInp[0]):
				animStep = 0
				if (decInp[3] and rightFacing) or (decInp[2] and !rightFacing):
					stateCurrent = states.Jump_Forward
				elif (decInp[2] and rightFacing) or (decInp[3] and !rightFacing):
					stateCurrent = states.Jump_Back
				else:
					stateCurrent = states.Jump_Neutral
			if buffer[-1][0] >= inputs.Up + inputs.Down + inputs.Left + inputs.Right: #if any attack input is found in hash, do this block
				ifAttacking(buffer)
		states.Walk_Forward:
			if (!decInp[3] and rightFacing) or (!decInp[2] and !rightFacing) or tooClose:
				stateCurrent = states.Idle
			if(decInp[1]):
				animStep = 1
				stateCurrent = states.Crouch
			if (decInp[0]):
				animStep = 0
				if (decInp[3] and rightFacing) or (decInp[2] and !rightFacing):
					stateCurrent = states.Jump_Forward
				elif (decInp[2] and rightFacing) or (decInp[3] and !rightFacing):
					stateCurrent = states.Jump_Back
				else:
					stateCurrent = states.Jump_Neutral
			if buffer[-1][0] >= inputs.A: #ditto
				ifAttacking(buffer)
		states.Walk_Back:
			if (!decInp[2] and rightFacing) or (!decInp[3] and !rightFacing) or distance > 5:
				stateCurrent = states.Idle
			if(decInp[1]):
				animStep = 1
				stateCurrent = states.Crouch
			if (decInp[0]):
				animStep = 0
				if (decInp[3] and rightFacing) or (decInp[2] and !rightFacing):
					stateCurrent = states.Jump_Forward
				elif (decInp[2] and rightFacing) or (decInp[3] and !rightFacing):
					stateCurrent = states.Jump_Back
				else:
					stateCurrent = states.Jump_Neutral
			if buffer[-1][0] >= inputs.A: #ditto
				ifAttacking(buffer)
		states.Attack:
			if attackEnded:
				match animStep:
					0, 1, 2:
						stateCurrent = states.Idle
						animStep = 0
					10, 11, 12:
						stateCurrent = states.Crouch
						animStep = 0
					20, 21:
						stateCurrent = states.Idle
						animStep = 0
					22:
						stateCurrent = states.Jump_Neutral
						animStep = 1

func doStateAction():
	match stateCurrent:
		states.Idle, states.Crouch:
			velocity.x = 0
		states.Walk_Forward:
			velocity.x = (1 if rightFacing else -1) * walkSpeed
		states.Walk_Back:
			velocity.x = (-1 if rightFacing else 1) * walkSpeed
			if tooClose:
				velocity.x += (-1 if rightFacing else 1) * walkSpeed
		states.Hurt_High, states.Hurt_Low, states.Hurt_Crouch, states.Block_High, states.Block_Low:
			velocity.x += (-1 if rightFacing else 1) * knockbackHorizontal
		states.Hurt_Fall:
			velocity.x += (-1 if rightFacing else 1) * knockbackHorizontal
			if animStep == 0:
				velocity.y += knockbackVertical
	
	velocity.y += GRAVITY
	velocity.y = max(MIN_VEL, velocity.y)
	if velocity.y < 0 and is_on_floor():
		velocity.y = 0
	
	set_velocity(velocity)
	set_up_direction(Vector3.UP)
	move_and_slide()

func setHurtboxGroup(hurtbox_group: Array):
	for shape in $Hurtboxes.get_children(): shape.disabled = true
	for hurtbox in hurtbox_group: get_node("Hurtboxes/" + hurtbox).disabled = false

func setHitboxGroup(hitbox_group: Array):
	for shape in $Hitboxes.get_children(): shape.disabled = true
	for hitbox in hitbox_group: get_node("Hitboxes/" + hitbox).disabled = false

func quickChangeHurtboxGroup(disable_hurtboxes: Array, enable_hurtboxes: Array):
	for hurtbox in disable_hurtboxes: get_node("Hurtboxes/" + hurtbox).disabled = true
	for hurtbox in enable_hurtboxes: get_node("Hurtboxes/" + hurtbox).disabled = false

func quickChangeHitboxGroup(disable_hitboxes: Array, enable_hitboxes: Array):
	for hitbox in disable_hitboxes: get_node("Hitboxes/" + hitbox).disabled = true
	for hitbox in enable_hitboxes: get_node("Hitboxes/" + hitbox).disabled = false

func doStateAnim():
	match stateCurrent:
		states.Idle:
			setHurtboxGroup(["Idle"])
			match animStep:
				0:
					$AnimatedSprite3D.animation = "Idle"
				1:
					$AnimatedSprite3D.animation = "C_Exit"
				2:
					$AnimatedSprite3D.animation = "Get_Up"
				3: #turnaround case, no turnaround animation
					pass
		states.Walk_Forward:
			setHurtboxGroup(["Idle"])
			$AnimatedSprite3D.animation = "Walk_Forward"
		states.Walk_Back:
			setHurtboxGroup(["Idle"])
			$AnimatedSprite3D.animation = "Walk_Back"
		states.Attack:
			match animStep:
				0:
					setHurtboxGroup(["Idle"])
					$AnimatedSprite3D.animation = "A_StandA"
					if $AnimatedSprite3D.frame == 1:
						setHitboxGroup(["Stand_A"])
					else:
						quickChangeHitboxGroup(["Stand_A"],[])
				1:
					if 1 <= $AnimatedSprite3D.frame <= 3:
						setHurtboxGroup(["Stand_B"])
					else:
						setHurtboxGroup(["Idle"])
					$AnimatedSprite3D.animation = "A_StandB"
					if $AnimatedSprite3D.frame == 2:
						setHitboxGroup(["Stand_B"])
					else:
						quickChangeHitboxGroup(["Stand_B"],[])
				2:
					$AnimatedSprite3D.animation = "A_StandC"
					if $AnimatedSprite3D.frame == 2:
						setHitboxGroup(["Stand_C"])
					else:
						quickChangeHitboxGroup(["Stand_C"],[])
				10:
					$AnimatedSprite3D.animation = "A_CrouchA"
				11:
					if $AnimatedSprite3D.frame <= 4:
						setHurtboxGroup([])
					else:
						setHurtboxGroup(["Crouch"])
					$AnimatedSprite3D.animation = "A_CrouchB"
					if $AnimatedSprite3D.frame == 2:
						setHitboxGroup(["Crouch_B"])
					else:
						quickChangeHitboxGroup(["Crouch_B"],[])
				12:
					$AnimatedSprite3D.animation = "A_CrouchC"
					if $AnimatedSprite3D.frame == 4:
						setHitboxGroup(["Crouch_C"])
					else:
						quickChangeHitboxGroup(["Crouch_C"],[])
				20:
					setHurtboxGroup(["Jump_A"])
					$AnimatedSprite3D.animation = "A_JumpA"
					setHitboxGroup(["Jump_A"])
				21:
					setHurtboxGroup(["Jump_B"])
					$AnimatedSprite3D.animation = "A_JumpB"
					if $AnimatedSprite3D.frame == 1:
						setHitboxGroup(["Jump_B"])
					else:
						quickChangeHitboxGroup(["Jump_B"],[])
				22:
					if $AnimatedSprite3D.frame == 3 or $AnimatedSprite3D.frame == 4:
						setHurtboxGroup(["Jump_C"])
					else:
						setHurtboxGroup(["Idle"])
					$AnimatedSprite3D.animation = "Jump_C"
					if $AnimatedSprite3D.frame == 3:
						setHitboxGroup(["Jump_C"])
					else:
						quickChangeHitboxGroup(["Jump_C"],[])
		states.Block_High:
			setHurtboxGroup(["Idle"])
			$AnimatedSprite3D.animation = "Block_Stand"
		states.Block_Low:
			setHurtboxGroup(["Crouch"])
			$AnimatedSprite3D.animation = "Block_Crouch"
		states.Hurt_High:
			setHurtboxGroup(["Idle"])
			$AnimatedSprite3D.animation = "Hurt_High"
		states.Hurt_Low:
			setHurtboxGroup(["Idle"])
			$AnimatedSprite3D.animation = "Hurt_Low"
		states.Hurt_Crouch:
			setHurtboxGroup(["Crouch"])
			$AnimatedSprite3D.animation = "Hurt_Crouch"
		states.Hurt_Fall:
			setHurtboxGroup(["Fall"])
			match animStep:
				0, 1:
					$AnimatedSprite3D.animation = "Hurt_Fall"
					animStep = 1

func animationEnded():
	match stateCurrent:
		states.Idle:
			match animStep:
				1, 2, 3:
					$AnimatedSprite3D.animation = "Idle"
					animStep = 0
		states.Crouch:
			match animStep:
				1, 3:
					$AnimatedSprite3D.animation = "C_Idle"
					animStep = 0
		states.Attack:
			attackEnded = true
			match animStep:
				0, 1, 2:
					$AnimatedSprite3D.animation = "Idle"
					animStep = 0
				10, 11, 12:
					$AnimatedSprite3D.animation = "C_Idle"
					animStep = 0
				20, 21:
					attackEnded = false
					if is_on_floor():
						attackEnded = true
						$AnimatedSprite3D.animation = "C_Idle"
						animStep = 0
				22:
					$AnimatedSprite3D.animation = "Idle"
					animStep = 1

func distanceCheckAreaEnter(_area):
	tooClose = true

func distanceCheckAreaExit(area):
	tooClose = false
	print(area)

func _physics_process(_delta):
	doStateAction()
	doStateAnim()
