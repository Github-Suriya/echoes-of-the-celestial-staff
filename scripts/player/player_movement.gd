class_name PlayerMovement
extends Node

## PlayerMovement
## Handles 2D locomotion physics, acceleration, gravity curves, coyote time, and jump buffering.
## Driven entirely by PlayerMovementConfig.

signal landed()

@export var config: PlayerMovementConfig

var current_move_axis: float = 0.0
var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _is_jumping: bool = false
var _player: CharacterBody2D = null

func _ready() -> void:
	if config == null:
		if ResourceLoader.exists("res://data/characters/player_movement_config.tres"):
			config = load("res://data/characters/player_movement_config.tres") as PlayerMovementConfig
		else:
			config = PlayerMovementConfig.new()
	
	if owner is CharacterBody2D:
		_player = owner as CharacterBody2D

func process_physics(player: CharacterBody2D, delta: float) -> void:
	_player = player
	
	# Fetch input
	_update_input(delta)
	
	# Compute horizontal and vertical movement
	_apply_horizontal_locomotion(delta)
	_apply_gravity_and_vertical(delta)
	
	# Execute engine physics
	_player.move_and_slide()

func _update_input(delta: float) -> void:
	# Query input through InputManager Autoload
	if has_node("/root/InputManager"):
		var im: Node = get_node("/root/InputManager")
		current_move_axis = im.get_movement_axis()
		
		if im.is_action_just_pressed(&"jump"):
			_jump_buffer_timer = config.jump_buffer_time
	else:
		current_move_axis = Input.get_axis(&"move_left", &"move_right")
		if Input.is_action_just_pressed(&"jump"):
			_jump_buffer_timer = config.jump_buffer_time
	
	# Update coyote timer
	if _player.is_on_floor():
		_coyote_timer = config.coyote_time
		_is_jumping = false
	else:
		_coyote_timer = maxf(0.0, _coyote_timer - delta)
	
	# Countdown jump buffer timer
	_jump_buffer_timer = maxf(0.0, _jump_buffer_timer - delta)

func _apply_horizontal_locomotion(delta: float) -> void:
	var target_speed: float = current_move_axis * config.max_speed
	var is_grounded: bool = _player.is_on_floor()
	
	if is_grounded:
		if absf(current_move_axis) > 0.01:
			_player.velocity.x = move_toward(_player.velocity.x, target_speed, config.acceleration * delta)
		else:
			_player.velocity.x = move_toward(_player.velocity.x, 0.0, config.deceleration * delta)
	else:
		# Air control with separate acceleration and deceleration rates
		if absf(current_move_axis) > 0.01:
			_player.velocity.x = move_toward(_player.velocity.x, target_speed, config.air_acceleration * delta)
		else:
			_player.velocity.x = move_toward(_player.velocity.x, 0.0, config.air_deceleration * delta)

func _apply_gravity_and_vertical(delta: float) -> void:
	if not _player.is_on_floor():
		var effective_gravity: float = config.gravity
		
		# Fall gravity multiplier: falling is faster than rising
		if _player.velocity.y > 0.0:
			effective_gravity *= config.fall_gravity_multiplier
		# Variable jump height: cut jump short if jump button released while rising
		elif _player.velocity.y < 0.0:
			var jump_held: bool = false
			if has_node("/root/InputManager"):
				var im: Node = get_node("/root/InputManager")
				jump_held = im.is_action_pressed(&"jump")
			else:
				jump_held = Input.is_action_pressed(&"jump")
			
			if not jump_held:
				effective_gravity *= config.low_jump_gravity_multiplier
		
		_player.velocity.y = minf(config.max_fall_speed, _player.velocity.y + effective_gravity * delta)

func can_jump() -> bool:
	if _player == null:
		return false
	return _player.is_on_floor() or _coyote_timer > 0.0

func consume_jump_intent() -> bool:
	if _jump_buffer_timer > 0.0 and can_jump():
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0
		return true
	return false

func apply_jump_impulse() -> void:
	if _player != null:
		_player.velocity.y = config.jump_velocity
		_is_jumping = true
		_coyote_timer = 0.0
		_jump_buffer_timer = 0.0

func notify_landed() -> void:
	_is_jumping = false
	landed.emit()

func get_coyote_timer() -> float:
	return _coyote_timer

func get_jump_buffer_timer() -> float:
	return _jump_buffer_timer

func is_jumping() -> bool:
	return _is_jumping
