class_name Enemy
extends KinematicBody2D

# signals

# enums

# constants

# exported variables
export var health := 1
export var max_gravity := 400

# variables
var _ignore
var _throw_vector := Vector2.ZERO
var _gravity_effect := 0.0
var _time_off_ground := 0.0

# onready variables


func _process(delta:float)->void:
	var velocity := Vector2.ZERO
	if _throw_vector != Vector2.ZERO:
		velocity += _throw_vector*200
	
	if not is_on_floor():
		_gravity_effect = _calculate_gravity(delta)
		velocity.y += _gravity_effect
	
	if velocity.y > 0:
		_throw_vector = Vector2.ZERO
		_time_off_ground = 0.0


func _calculate_gravity(delta:float)->float:
	if _time_off_ground < 1:
		_time_off_ground += delta
	return lerp(0.0, max_gravity, _time_off_ground)


func hit(damage_done:float)->void:
	print("OW")


func throw_back(player_position:Vector2)->void:
	if player_position.x < get_global_transform().origin.x:
		_throw_vector = Vector2.UP.rotated(-PI/4)
	else:
		_throw_vector = Vector2.UP.rotated(PI/4)
	_throw_vector = _throw_vector.normalized()
