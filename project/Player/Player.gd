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
var _attacking := false

# onready variables
onready var collision := $CollisionShape2D
onready var _attack_cooldown_timer := $AttackCooldownTimer
onready var _animations := $AnimationPlayer
onready var _animation_tree := $AnimationTree
onready var _body := $Body


func _ready()->void:
	_animation_tree.active = false
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
	
	if velocity.x != 0:
		_body.scale.x = 0.5 if velocity.x > 0 else -0.5
		_state = State.WALKING
		velocity.x *= speed
	else:
		_state = State.IDLE
	_ignore = move_and_slide(velocity, UP_VECTOR)
	_get_animation()


func _get_animation()->void:
	if _state == State.WALKING:
		if _attacking:
			_animation_tree.active = true
			_animations.play("Hit")
			yield(get_tree().create_timer(0.2), "timeout")
			_animation_tree.active = false
			_attacking = false
		_animations.play("Walk")
	elif _state == State.IDLE:
		if _attacking:
			_animations.play("Hit")
			yield(get_tree().create_timer(0.2), "timeout")
			_attacking = false
		else:
			_animations.play("Idle")


func _attack():
	_can_attack = false
	_attacking = true
	_attack_cooldown_timer.start(attack_cooldown_time)


func _calculate_gravity(delta:float)->float:
	if _time_off_ground < 1:
		_time_off_ground += delta
	return lerp(0.0, max_gravity, _time_off_ground)


func _on_AttackCooldownTimer_timeout():
	_can_attack = true
