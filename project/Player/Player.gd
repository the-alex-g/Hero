extends KinematicBody2D

# signals

# constants
const UP_VECTOR := Vector2.UP

# enums
enum State {WALKING, IDLE, ATTACKING}

# exported variables
export var speed := 200
export var jump_time := 2.0
export var max_gravity := 400
export var jump_strength := 200
export var attack_cooldown_time := 0.5

# normal variables
var color := Color.white
var _ignore
var _player_index := "1"
var _action_key := "player_"
var _state = State.IDLE
var _jumping := false
var _gravity_effect := 0.0
var _time_off_ground := 0.0
var _can_jump := true
var _can_attack := true
var _smash_attack := false

# onready variables
onready var collision := $CollisionShape2D
onready var _attack_cooldown_timer := $AttackCooldownTimer


func _ready()->void:
	_action_key += _player_index + "_"


func _process(delta:float)->void:
	var velocity := Vector2.ZERO
	var y_force := 0.0
	if Input.is_action_pressed(_action_key+"left"):
		velocity.x -= 1
	if Input.is_action_pressed(_action_key+"right"):
		velocity.x += 1
	if Input.is_action_just_pressed(_action_key+"jump") and _can_jump:
		_jumping = true
		_can_jump = false
		_time_off_ground = 0.0
	if Input.is_action_just_pressed(_action_key+"attack") and _can_attack:
		_attack()
	
	if not is_on_floor():
		_gravity_effect = _calculate_gravity(delta)
		y_force += _gravity_effect
	else:
		if _time_off_ground != 0.0:
			_time_off_ground = 0.0
			_can_jump = true
	
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
	else:
		_state = State.IDLE
	_ignore = move_and_slide(velocity, UP_VECTOR)


func _attack():
	_can_attack = false
	_attack_cooldown_timer.start(attack_cooldown_time)


func _calculate_gravity(delta:float)->float:
	if _time_off_ground < 1:
		_time_off_ground += delta
	return lerp(0.0, max_gravity, _time_off_ground)


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


func _on_AttackCooldownTimer_timeout():
	_can_attack = true
