extends Sprite3D

# This script is part of a set of scripts which provide the look of the Fighter.
# All AnimationScripts must have the following variables and methods:
# a "current_animation" variable which holds a string
# an "animation_ended" method which returns a boolean value
# and a "step" method which takes in an integer value and updates the visuals
# In specific, this script is used if the visual aspects are handled \
# by a Sprite node, be it Sprite2D or Sprite3D.
# For Sprites, Animations are handled manually and controlled by the game engine
# during the physics_process step.
# Therefore, all animations top out at 60 FPS, which is a small constraint for now.
# animation format:
#"<Name>":
#	{
#		"animation_length": <value>,
#		<frame_number>: [<animation frame x>, <animation frame y>], ...,
#		"extra": ... This one is up to whatever
#	}

var animations : Dictionary = {}

var current_animation: String

func animation_ended(current_step) -> bool:
	return current_step >= animations[current_animation]["animation_length"]

func anim(current_step) -> void:
	if current_animation == "":
		return
	frame_coords = (animations[current_animation] as Dictionary).get(current_step, frame_coords)
