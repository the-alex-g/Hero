extends KinematicBody2D

# signals

# constants
const UP_VECTOR := Vector2.UP

# enums
enum State {WALKING, IDLE}

# exported variables
export var speed := 200
export var jump_time := 2.0
export var max_gravity := 400
export var jump_strength := 200

# normal variables
var color := Color.white
var _ignore
var _player_index := "1"
var _action_key := "player_"
var _state = State.IDLE
var _jumping := false
var _gravity_effect := 0.0
var _time_off_ground := 0.0

# onready variables
onready var collision := $CollisionShape2D


func _ready()->void:
	_action_key += _player_index + "_"


func _process(delta:float)->void:
	var velocity := Vector2.ZERO
	var y_force := 0.0
	if Input.is_action_pressed(_action_key+"left"):
		velocity.x -= 1
	if Input.is_action_pressed(_action_key+"right"):
		velocity.x += 1
	if Input.is_action_just_pressed(_action_key+"jump"):
		_jump()
	
	if not is_on_floor():
		if _time_off_ground < 1:
			_time_off_ground += delta
		_gravity_effect = lerp(0.0, max_gravity, _time_off_ground)
		y_force += _gravity_effect
	else:
		if _time_off_ground != 0.0:
			_time_off_ground = 0.0
	
	if _jumping:
		y_force -= jump_strength
		if y_force > 0:
			_jumping = false
			_time_off_ground = 0.0
	
	velocity = velocity.normalized()
	velocity.y += y_force
	
	if velocity != Vector2.ZERO:
		_state = State.WALKING
		velocity.x *= speed
	_ignore = move_and_slide(velocity, UP_VECTOR)


func _jump():
	_jumping = true
	_time_off_ground = 0.0


func _draw():
	if collision != null:
		var shape = collision.get_shape()
		if shape is CapsuleShape2D:
			var radius = shape.radius
			var height = shape.height
			if collision.rotation_degrees != 270 and collision.rotation_degrees != 90:
				draw_circle(Vector2(0,height/2), radius, color)
				draw_circle(-Vector2(0,height/2), radius, color)
				draw_rect(Rect2(-Vector2(radius*2, height)/2, Vector2(radius*2, height)), color)
			else:
				draw_circle(Vector2(height/2,0), radius, color)
				draw_circle(-Vector2(height/2,0), radius, color)
				draw_rect(Rect2(-Vector2(height, radius*2)/2, Vector2(height, radius*2)), color)
