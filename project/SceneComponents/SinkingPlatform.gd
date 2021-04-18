extends Node2D

# signals

# enums

# constants
const POSITION_PATH := "position"

# exported variables
export var sink_depth := 15.0
export var sink_time := 0.4

# variables
var _ignore

# onready variables
onready var _tween := $Tween


func _change_position(rise:bool)->void:
	var current_position := get_global_transform().origin
	var new_position := current_position
	if rise:
		new_position.y -= sink_depth
	else:
		new_position.y += sink_depth
	_tween.interpolate_property(self, POSITION_PATH, null, new_position, sink_time, Tween.TRANS_LINEAR, Tween.EASE_IN)
	_tween.start()


func _on_SinkRegion_body_entered(body:PhysicsBody2D)->void:
	if body is Hero:
		_change_position(false)


func _on_SinkRegion_body_exited(body:PhysicsBody2D)->void:
	if body is Hero:
		_change_position(true)
