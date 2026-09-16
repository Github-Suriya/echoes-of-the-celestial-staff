class_name EnemyPerception
extends Node2D

## EnemyPerception
## Deterministic, lightweight perception system for enemies.
## Throttles line-of-sight and proximity evaluations (10-15 Hz) to maintain 60 FPS budgets.

signal target_detected(target: Node2D)
signal target_lost()

@export var detection_range: float = 180.0
@export var lose_target_range: float = 260.0
@export var update_interval: float = 0.08
@export var require_line_of_sight: bool = true
@export var los_collision_mask: int = 1 # World geometry layer

var current_target: Node2D = null

var _update_timer: float = 0.0
var _cached_player: Node2D = null

func _ready() -> void:
	# Randomize initial timer slightly to prevent multiple enemies from querying on the exact same frame
	_update_timer = randf_range(0.0, update_interval)

func configure(data: EnemyData) -> void:
	if data == null:
		return
	detection_range = data.detection_range
	lose_target_range = data.lose_target_range

func has_target() -> bool:
	return current_target != null and is_target_valid()

func is_target_valid() -> bool:
	if current_target == null or not is_instance_valid(current_target):
		return false
	
	# If target has a health component, verify it is still alive
	if current_target.has_node("Components/HealthComponent"):
		var hc: HealthComponent = current_target.get_node("Components/HealthComponent") as HealthComponent
		if hc != null and hc.is_dead():
			return false
	elif current_target.has_method("is_dead") and current_target.is_dead():
		return false
	
	return true

func acquire_target(target: Node2D) -> void:
	if target == null or not is_instance_valid(target):
		return
	
	var was_has_target: bool = has_target()
	current_target = target
	
	if not was_has_target:
		target_detected.emit(current_target)

func clear_target() -> void:
	if current_target != null:
		current_target = null
		target_lost.emit()

func get_target_distance() -> float:
	if not has_target():
		return INF
	return global_position.distance_to(current_target.global_position)

func get_target_direction() -> Vector2:
	if not has_target():
		return Vector2.ZERO
	return (current_target.global_position - global_position).normalized()

func has_line_of_sight_to_target() -> bool:
	if not has_target():
		return false
	
	if not require_line_of_sight:
		return true
	
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	if space_state == null:
		return true
	
	var from_pos: Vector2 = global_position
	var to_pos: Vector2 = current_target.global_position
	
	# Raycast against world collision
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(from_pos, to_pos, los_collision_mask)
	query.exclude = [owner, current_target]
	query.collide_with_areas = false
	query.collide_with_bodies = true
	
	var result: Dictionary = space_state.intersect_ray(query)
	return result.is_empty()

func update_perception(delta: float) -> void:
	_update_timer -= delta
	if _update_timer > 0.0:
		return
	_update_timer = update_interval
	
	_evaluate_perception()

func _evaluate_perception() -> void:
	# 1. If we already have a target, check if it's still valid and in loss range
	if has_target():
		var dist: float = get_target_distance()
		if dist > lose_target_range or not is_target_valid():
			clear_target()
		return
	
	# 2. If no target, scan for player reference
	if _cached_player == null or not is_instance_valid(_cached_player):
		_find_player()
	
	if _cached_player != null and is_instance_valid(_cached_player):
		var dist: float = global_position.distance_to(_cached_player.global_position)
		if dist <= detection_range:
			# Temporary set to check LoS
			current_target = _cached_player
			if has_line_of_sight_to_target():
				target_detected.emit(current_target)
			else:
				current_target = null

func _find_player() -> void:
	# Search group first
	var players: Array[Node] = get_tree().get_nodes_in_group(&"player")
	if not players.is_empty() and players[0] is Node2D:
		_cached_player = players[0] as Node2D
		return
	
	# Fallback: check SceneManager current scene
	var root: Window = get_tree().root
	if root != null:
		var found: Node = root.find_child("Player", true, false)
		if found is Node2D:
			_cached_player = found as Node2D
