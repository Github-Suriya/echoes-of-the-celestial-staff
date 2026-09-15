class_name PlayerRespawn
extends Node

## PlayerRespawn
## Manages spawn point anchoring, pit-fall boundary checks, and player state reset upon respawn.

signal respawned(spawn_pos: Vector2)

@export var fall_death_y: float = 1200.0

var spawn_position: Vector2 = Vector2.ZERO
var _player: CharacterBody2D = null

func _ready() -> void:
	if owner is CharacterBody2D:
		_player = owner as CharacterBody2D
		call_deferred("_init_spawn_position")

func _init_spawn_position() -> void:
	if _player != null and spawn_position == Vector2.ZERO:
		spawn_position = _player.global_position

func set_spawn_position(new_pos: Vector2) -> void:
	spawn_position = new_pos

func check_boundaries() -> void:
	if _player == null:
		return
	
	if _player.global_position.y > fall_death_y:
		respawn()

func respawn() -> void:
	if _player == null:
		return
	
	_player.velocity = Vector2.ZERO
	_player.global_position = spawn_position
	
	# Reset state machine to Idle
	if _player.has_node("StateMachine"):
		var sm: StateMachine = _player.get_node("StateMachine") as StateMachine
		if sm != null:
			sm.change_state(&"Idle")
	
	respawned.emit(spawn_position)
	
	if has_node("/root/EventBus"):
		var bus: Node = get_node("/root/EventBus")
		if bus != null and bus.has_signal("player_died"):
			bus.player_died.emit()
