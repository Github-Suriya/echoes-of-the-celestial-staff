class_name EnemyMovement
extends Node

## EnemyMovement
## Locomotion controller for enemies.
## Manages horizontal steering, acceleration, deceleration, gravity, and patrol bounds.

signal facing_changed(new_direction: int)
signal patrol_waypoint_reached()

@export var patrol_speed: float = 50.0
@export var chase_speed: float = 110.0
@export var acceleration: float = 500.0
@export var deceleration: float = 700.0
@export var gravity: float = 980.0
@export var patrol_distance: float = 90.0
@export var patrol_wait_time: float = 1.2

var facing_direction: int = 1: # +1 = Right, -1 = Left
	set(value):
		var clamped_val: int = 1 if value >= 0 else -1
		if facing_direction != clamped_val:
			facing_direction = clamped_val
			facing_changed.emit(facing_direction)

var spawn_position: Vector2 = Vector2.ZERO
var left_patrol_x: float = 0.0
var right_patrol_x: float = 0.0
var current_patrol_target_x: float = 0.0
var patrol_moving_right: bool = true

var body: CharacterBody2D = null

func _ready() -> void:
	if owner is CharacterBody2D:
		body = owner as CharacterBody2D

func configure(data: EnemyData, initial_pos: Vector2) -> void:
	if data != null:
		patrol_speed = data.patrol_speed
		chase_speed = data.chase_speed
		acceleration = data.acceleration
		deceleration = data.deceleration
		gravity = data.gravity
		patrol_distance = data.patrol_distance
		patrol_wait_time = data.patrol_wait_time
	
	set_spawn_position(initial_pos)

func set_spawn_position(pos: Vector2) -> void:
	spawn_position = pos
	left_patrol_x = spawn_position.x - patrol_distance
	right_patrol_x = spawn_position.x + patrol_distance
	patrol_moving_right = true
	current_patrol_target_x = right_patrol_x

func apply_gravity(delta: float) -> void:
	if body == null:
		return
	if not body.is_on_floor():
		body.velocity.y += gravity * delta

func move_toward_x(target_x: float, max_speed: float, delta: float) -> void:
	if body == null:
		return
	
	var diff: float = target_x - body.global_position.x
	if absf(diff) > 4.0:
		var dir_sign: float = signf(diff)
		facing_direction = int(dir_sign)
		body.velocity.x = move_toward(body.velocity.x, dir_sign * max_speed, acceleration * delta)
	else:
		stop_horizontal(delta)

func stop_horizontal(delta: float) -> void:
	if body == null:
		return
	body.velocity.x = move_toward(body.velocity.x, 0.0, deceleration * delta)

func step_patrol(delta: float) -> bool:
	if body == null:
		return false
	
	# Reverse if hitting a wall
	if body.is_on_wall():
		reverse_patrol_direction()
	
	var diff: float = current_patrol_target_x - body.global_position.x
	if absf(diff) <= 8.0:
		reverse_patrol_direction()
		patrol_waypoint_reached.emit()
		return true
	
	move_toward_x(current_patrol_target_x, patrol_speed, delta)
	return false

func reverse_patrol_direction() -> void:
	patrol_moving_right = not patrol_moving_right
	current_patrol_target_x = right_patrol_x if patrol_moving_right else left_patrol_x
	facing_direction = 1 if patrol_moving_right else -1

func face_target(target: Node2D) -> void:
	if target == null or body == null:
		return
	var diff: float = target.global_position.x - body.global_position.x
	if absf(diff) > 2.0:
		facing_direction = 1 if diff > 0.0 else -1
