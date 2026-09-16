class_name Room2D
extends Node2D

## Room2D
## Base class and template controller for Metroidvania rooms in Echoes of the Celestial Staff.
## Manages room geometry, camera bounding volumes, player spawn points,
## entrances, exits, doors, enemies, checkpoints, and persistent object synchronization.

enum LifecycleState {
	UNLOADED,
	LOADING,
	LOADED,
	ACTIVE,
	EXITING,
	UNLOADING
}

signal lifecycle_changed(old_state: LifecycleState, new_state: LifecycleState)
signal room_activated()
signal room_deactivated()

@export var room_id: StringName = &""
@export var room_data: RoomData
@export var default_camera_bounds: Rect2 = Rect2(0.0, 0.0, 1920.0, 1080.0)

var current_lifecycle_state: LifecycleState = LifecycleState.UNLOADED
var _world_controller: Node2D

@onready var geometry_root: Node2D = $Geometry if has_node("Geometry") else null
@onready var camera_bounds_node: Control = $CameraBounds if has_node("CameraBounds") else null
@onready var spawn_points_root: Node2D = $SpawnPoints if has_node("SpawnPoints") else null
@onready var entrances_root: Node2D = $Entrances if has_node("Entrances") else null
@onready var exits_root: Node2D = $Exits if has_node("Exits") else null
@onready var doors_root: Node2D = $Doors if has_node("Doors") else null
@onready var enemies_root: Node2D = $Enemies if has_node("Enemies") else null
@onready var checkpoints_root: Node2D = $Checkpoints if has_node("Checkpoints") else null
@onready var persistent_objects_root: Node2D = $PersistentObjects if has_node("PersistentObjects") else null

func _ready() -> void:
	if current_lifecycle_state == LifecycleState.UNLOADED or current_lifecycle_state == LifecycleState.LOADING:
		set_lifecycle_state(LifecycleState.LOADED)

func initialize_room(world_controller: Node2D) -> void:
	_world_controller = world_controller
	set_lifecycle_state(LifecycleState.LOADED)

func activate_room() -> void:
	set_lifecycle_state(LifecycleState.ACTIVE)
	process_mode = Node.PROCESS_MODE_INHERIT
	visible = true
	room_activated.emit()

func deactivate_room() -> void:
	set_lifecycle_state(LifecycleState.EXITING)
	process_mode = Node.PROCESS_MODE_DISABLED
	room_deactivated.emit()

func set_lifecycle_state(new_state: LifecycleState) -> void:
	if current_lifecycle_state == new_state:
		return
	var old_state: LifecycleState = current_lifecycle_state
	current_lifecycle_state = new_state
	lifecycle_changed.emit(old_state, new_state)

func get_lifecycle_state() -> LifecycleState:
	return current_lifecycle_state

func get_lifecycle_state_name() -> String:
	match current_lifecycle_state:
		LifecycleState.UNLOADED:
			return "UNLOADED"
		LifecycleState.LOADING:
			return "LOADING"
		LifecycleState.LOADED:
			return "LOADED"
		LifecycleState.ACTIVE:
			return "ACTIVE"
		LifecycleState.EXITING:
			return "EXITING"
		LifecycleState.UNLOADING:
			return "UNLOADING"
		_:
			return "UNKNOWN"

func get_spawn_point(spawn_id: StringName) -> Marker2D:
	if spawn_points_root == null:
		return null
	if spawn_id.is_empty():
		# Return first available Marker2D
		for child in spawn_points_root.get_children():
			if child is Marker2D:
				return child
		return null
	
	var node_name: String = String(spawn_id)
	if spawn_points_root.has_node(node_name):
		var node: Node = spawn_points_root.get_node(node_name)
		if node is Marker2D:
			return node
	
	# Search children recursively / by partial name
	for child in spawn_points_root.get_children():
		if child is Marker2D:
			if child.name.to_lower() == node_name.to_lower() or child.name.to_lower() == ("spawn_" + node_name).to_lower():
				return child
	
	return null

func get_spawn_position(spawn_id: StringName) -> Vector2:
	var sp: Marker2D = get_spawn_point(spawn_id)
	if sp != null:
		return sp.global_position
	return global_position

func get_camera_bounds() -> Rect2:
	if room_data != null and (room_data.room_bounds.size.x > 0.0 and room_data.room_bounds.size.y > 0.0):
		return room_data.room_bounds
	
	if camera_bounds_node is ReferenceRect:
		var ref_rect: ReferenceRect = camera_bounds_node as ReferenceRect
		return Rect2(ref_rect.position, ref_rect.size)
	elif camera_bounds_node is Control:
		return Rect2(camera_bounds_node.position, camera_bounds_node.size)
	
	return default_camera_bounds

func sync_persistent_objects(world_state: WorldState) -> void:
	if world_state == null:
		return
	
	# Sync AbilityGates in doors_root
	if doors_root != null:
		for door in doors_root.get_children():
			if door.has_method("apply_state"):
				door.apply_state(world_state)
	
	# Sync Checkpoints in checkpoints_root
	if checkpoints_root != null:
		for cp in checkpoints_root.get_children():
			if cp.has_method("apply_state"):
				cp.apply_state(world_state)
	
	# Sync PersistentObjects in persistent_objects_root
	if persistent_objects_root != null:
		for obj in persistent_objects_root.get_children():
			if obj.has_method("apply_state"):
				obj.apply_state(world_state)

func record_persistent_objects(world_state: WorldState) -> void:
	if world_state == null:
		return
	
	if doors_root != null:
		for door in doors_root.get_children():
			if door.has_method("record_state"):
				door.record_state(world_state)
	
	if checkpoints_root != null:
		for cp in checkpoints_root.get_children():
			if cp.has_method("record_state"):
				cp.record_state(world_state)
	
	if persistent_objects_root != null:
		for obj in persistent_objects_root.get_children():
			if obj.has_method("record_state"):
				obj.record_state(world_state)

func get_world_controller() -> Node2D:
	return _world_controller
