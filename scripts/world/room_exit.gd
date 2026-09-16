class_name RoomExit
extends Area2D

## RoomExit
## Data-driven trigger volume routing the player between connected rooms.
## Identifies target destination room and target spawn point.

signal exit_triggered(exit_id: StringName, destination_room_id: StringName, destination_spawn_id: StringName)

@export var exit_id: StringName = &""
@export var destination_room_id: StringName = &""
@export var destination_spawn_id: StringName = &""
@export var transition_direction: Vector2 = Vector2.RIGHT
@export var is_locked: bool = false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 # Player layer
	
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func trigger_transition() -> bool:
	if is_locked:
		return false
	if destination_room_id.is_empty():
		return false
	
	exit_triggered.emit(exit_id, destination_room_id, destination_spawn_id)
	
	var wc: Node = _get_world_controller()
	if wc != null and wc.has_method("request_room_transition"):
		return wc.request_room_transition(destination_room_id, destination_spawn_id)
	return false

func _on_body_entered(body: Node2D) -> void:
	if is_locked:
		return
	if body is CharacterBody2D or body.name == "Player":
		trigger_transition()

func _get_world_controller() -> Node:
	var curr: Node = get_parent()
	while curr != null:
		if curr.has_method("request_room_transition"):
			return curr
		curr = curr.get_parent()
	return null
