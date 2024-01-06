extends Node

var global_hitstop : int
var p1_hitstop : int
var p2_hitstop : int

func _physics_process(_d):
	global_hitstop = max(global_hitstop - 1, 0)
	p1_hitstop = max(p1_hitstop - 1, 0)
	p2_hitstop = max(p2_hitstop - 1, 0)
