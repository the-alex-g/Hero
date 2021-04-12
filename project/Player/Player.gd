class_name Hero
extends KinematicBody2D

# signals

# constants
const UP_VECTOR := Vector2.UP
const MAX_GRAVITY := 400.0

# enums
enum State {WALKING, IDLE, AIRBORNE, DASHING}

# exported variables
export var speed := 200
export var jump_time := 2.0
export var jump_strength := 200
export var attack_cooldown_time := 0.5
export var dash_speed := 400
export var dash_time := 0.6
export var slam_fall_speed := 600.0

# normal variables
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
var _was_attacking := false
var _was_jumping := false
var _can_dash := true
var _damage := 1.0
var _dashing_left := false
var _was_dashing := false
var _was_smashing := false

# onready variables
onready var collision := $CollisionShape2D
onready var _attack_cooldown_timer := $AttackCooldownTimer
onready var _animation_tree := $AnimationTree
onready var _sword_hit_area := $Body/HitArea
onready var _smash_area := $Body/SmashArea
onready var _floor_detector := $FloorDetector


func _ready()->void:
	_animation_tree.active = true
	_action_key += _player_index + "_"


func _physics_process(delta:float)->void:
	var velocity := Vector2.ZERO
	if _state != State.DASHING:
		var y_force := 0.0
		
		if Input.is_action_pressed(_action_key+"left"):
			velocity.x -= 1
		
		if Input.is_action_pressed(_action_key+"right"):
			velocity.x += 1
		
		if Input.is_action_just_pressed(_action_key+"jump") and _can_jump:
			_jumping = true
			_was_jumping = false
			_can_jump = false
			_time_off_ground = 0.0
		
		if Input.is_action_just_pressed(_action_key+"attack") and _can_attack:
			_attack()
		
		if Input.is_action_just_pressed(_action_key+"smash_attack") and _can_attack:
			_prepare_smash_attack()
		
		if Input.is_action_just_pressed(_action_key+"dash") and _can_dash and _can_attack:
			$DashCooldownTimer.start(dash_time)
			_can_dash = false
			_state = State.DASHING
			if $Body.scale.x > 0:
				_dashing_left = false
			else:
				_dashing_left = true
			return
		
		if not _is_on_floor():
			var gravity_scale := MAX_GRAVITY if not _smash_attack else slam_fall_speed
			_gravity_effect = _calculate_gravity(delta, gravity_scale)
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
			$Body.scale.x = 0.5 if velocity.x > 0 else -0.5
			_state = State.WALKING
			velocity.x *= speed
		elif velocity.x == 0:
			_state = State.IDLE
		if not _is_on_floor():
			_state = State.AIRBORNE
		if _is_on_floor() and _smash_attack:
			_execute_smash()
	
	else:
		velocity.x += dash_speed
		velocity.x *= -1.0 if _dashing_left else 1.0
		velocity.y = 0.0
	
	_ignore = move_and_slide(velocity, UP_VECTOR)
	_get_animation()


func _execute_smash()->void:
	for body in _smash_area.get_overlapping_bodies():
		if body is Enemy:
			body.hit(_damage)
			body.throw_back(get_global_transform().origin)
	_can_attack = true
	_was_smashing = false
	_smash_attack = false


func _prepare_smash_attack()->void:
	_can_attack = false
	_smash_attack = true
	_jumping = false
	_time_off_ground = 1.0


func _get_animation()->void:
	# values from 0 (not hitting) to 1 (hitting)
	var walk_hit := 0.0
	var jump_hit := 0.0
	var idle_hit := 0.0
	var dash_value := 0.0
	
	# values from 0 (jumping) to 1 (falling)
	var jump := 0.0
	
	# values from -1 (walking) through 0 (jumping) to 1 (idle)
	var master_action := 0.0
	
	if _state == State.WALKING:
		dash_value = 0.0
		master_action = -1.0
	
	elif _state == State.IDLE:
		master_action = 1.0
	
	elif _state == State.AIRBORNE:
		master_action = 0.0
	
	elif _state == State.DASHING:
		dash_value = 1.0
		master_action = -1.0
	
	_set_animation(idle_hit, jump_hit, walk_hit, jump, dash_value, master_action)


func _set_animation(idle:float, jump:float, walk:float, jump_or_fall:float, dash_value:float, master_value:float)->void:
	# master is -1: walk, 0: jump, 1: idle
	var air_attack := 0.0
	if _attacking:
		idle = 1.0
		jump = 1.0
		walk = 1.0
		air_attack = 0.0
		if not _was_attacking:
			_animation_tree.set("parameters/IdleHitSeek/seek_position", 0)
			_animation_tree.set("parameters/JumpHitSeek/seek_position", 0)
			_animation_tree.set("parameters/WalkHitSeek/seek_position", 0)
			_was_attacking = true
	
	if _jumping:
		jump_or_fall = 0.0
		if not _was_jumping:
			_animation_tree.set("parameters/JumpSeek/seek_position", 0)
			_was_jumping = true
	else:
		jump_or_fall = 1.0
	
	if dash_value == 1.0 and not _was_dashing:
		_animation_tree.set("parameters/DashSeek/seek_position", 0)
		_was_dashing = true
	
	if _smash_attack:
		jump = 1.0
		air_attack = 1.0
		if not _was_smashing:
			_animation_tree.set("parameters/SlamSeek/seek_position", 0)
			_was_smashing = true
	
	_animation_tree.set("parameters/FallJump/add_amount", jump_or_fall)
	_animation_tree.set("parameters/WalkHit/add_amount", walk)
	_animation_tree.set("parameters/WalkDash/add_amount", dash_value)
	_animation_tree.set("parameters/Airborne/blend_amount", jump)
	_animation_tree.set("parameters/JumpHit/blend_amount", air_attack)
	_animation_tree.set("parameters/IdleHit/add_amount", idle)
	_animation_tree.set("parameters/Master/blend_amount", master_value)


func _attack()->void:
	_can_attack = false
	_attacking = true
	for body in _sword_hit_area.get_overlapping_bodies():
		if body is Enemy:
			body.hit(_damage)
	_attack_cooldown_timer.start(attack_cooldown_time)
	$AttackAnimTimer.start(0.2)


func _calculate_gravity(delta:float, gravity_scale)->float:
	if _time_off_ground < 1:
		_time_off_ground += delta
	return lerp(0.0, gravity_scale, _time_off_ground)


func _on_AttackCooldownTimer_timeout()->void:
	_can_attack = true


func _on_AttackAnimTimer_timeout()->void:
	_attacking = false
	_was_attacking = false
	_stop_attacking_animations()


func _stop_attacking_animations()->void:
	_animation_tree.set("parameters/WalkHit/add_amount", 0.0)
	_animation_tree.set("parameters/JumpHit/add_amount", 0.0)
	_animation_tree.set("parameters/IdleHit/add_amount", 0.0)


func _is_on_floor()->bool:
	var is_detecting := false
	if _floor_detector.is_colliding():
		is_detecting = true
	return is_detecting


func _on_DashCooldownTimer_timeout()->void:
	_can_dash = true
	_was_dashing = false
	_state = State.IDLE
