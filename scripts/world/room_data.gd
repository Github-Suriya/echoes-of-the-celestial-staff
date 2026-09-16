class_name RoomData
extends Resource

## RoomData
## Declarative resource definition for a Metroidvania room in Echoes of the Celestial Staff.
## Defines room identifiers, display metadata, scene paths, spatial boundaries,
## and entry/exit connections.

@export var room_id: StringName = &""
@export var display_name: String = ""
@export_file("*.tscn") var scene_path: String = ""
@export var room_bounds: Rect2 = Rect2(0.0, 0.0, 1920.0, 1080.0)
@export var spawn_point_ids: Array[StringName] = []
@export var connections: Dictionary = {} # exit_id -> { "destination_room_id": StringName, "destination_spawn_id": StringName }

func _init(
	p_room_id: StringName = &"",
	p_display_name: String = "",
	p_scene_path: String = "",
	p_room_bounds: Rect2 = Rect2(0.0, 0.0, 1920.0, 1080.0),
	p_spawn_points: Array[StringName] = [],
	p_connections: Dictionary = {}
) -> void:
	room_id = p_room_id
	display_name = p_display_name
	scene_path = p_scene_path
	room_bounds = p_room_bounds
	spawn_point_ids = p_spawn_points
	connections = p_connections

func is_valid() -> bool:
	if room_id.is_empty():
		return false
	if scene_path.is_empty():
		return false
	if room_bounds.size.x <= 0.0 or room_bounds.size.y <= 0.0:
		return false
	return true

func has_spawn_point(spawn_id: StringName) -> bool:
	return spawn_point_ids.has(spawn_id)

func get_connection(exit_id: StringName) -> Dictionary:
	return connections.get(exit_id, {})
