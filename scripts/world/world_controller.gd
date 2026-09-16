class_name WorldController
extends Node2D

## WorldController
## Central coordinator for the Metroidvania interconnected world architecture.
## Responsibilities:
## - Active room lifecycle tracking (single active room in memory)
## - Safe room transitions without player duplication or velocity drift
## - Automatic camera boundary clamping and smoothing reset
## - Persistent world state and progression capabilities coordination
## - Checkpoint tracking and respawn management
## - SaveManager slot integration

signal room_transition_started(from_room_id: StringName, to_room_id: StringName)
signal room_transition_completed(room_id: StringName)
signal player_spawned(room_id: StringName, spawn_point_id: StringName)

@export var initial_room_id: StringName = &""
@export var initial_spawn_id: StringName = &"default"
@export var registered_rooms: Array[RoomData] = []

var active_room: Room2D = null
var current_room_id: StringName = &""
var active_checkpoint_room_id: StringName = &""
var active_checkpoint_spawn_id: StringName = &""
var is_transitioning: bool = false

var world_state: WorldState
var capabilities: PlayerCapabilities

var _room_registry: Dictionary = {} # StringName -> RoomData

var rooms_container: Node2D = null
var player: CharacterBody2D = null

func _init() -> void:
	world_state = WorldState.new()
	capabilities = PlayerCapabilities.new()
	_room_registry = {}

func _ready() -> void:
	if rooms_container == null and has_node("RoomsContainer"):
		rooms_container = get_node("RoomsContainer") as Node2D
	if player == null and has_node("Player"):
		player = get_node("Player") as CharacterBody2D
	
	for rdata in registered_rooms:
		if rdata != null:
			register_room(rdata)
	
	# If initial room is set, load it
	if not initial_room_id.is_empty():
		load_room(initial_room_id, initial_spawn_id)

func register_room(room_data: RoomData) -> void:
	if room_data == null or room_data.room_id.is_empty():
		return
	_room_registry[room_data.room_id] = room_data

func unregister_room(room_id: StringName) -> void:
	_room_registry.erase(room_id)

func has_registered_room(room_id: StringName) -> bool:
	return _room_registry.has(room_id)

func get_room_data(room_id: StringName) -> RoomData:
	return _room_registry.get(room_id, null)

func get_registered_room_ids() -> Array[StringName]:
	var list: Array[StringName] = []
	for k in _room_registry.keys():
		list.append(k)
	return list

func request_room_transition(destination_room_id: StringName, destination_spawn_id: StringName = &"") -> bool:
	if is_transitioning:
		return false
	
	if not has_registered_room(destination_room_id):
		push_warning("WorldController: Cannot transition to unregistered room: %s" % destination_room_id)
		return false
	
	is_transitioning = true
	var from_id: StringName = current_room_id
	room_transition_started.emit(from_id, destination_room_id)
	
	var bus: Node = _get_event_bus()
	if bus != null and bus.has_signal("room_exit_started"):
		bus.room_exit_started.emit(from_id, destination_room_id)
	
	# 1. Neutralize player velocity to prevent transition drift
	if player != null:
		player.velocity = Vector2.ZERO
	
	# 2. Record state from current active room before unloading
	if active_room != null:
		active_room.record_persistent_objects(world_state)
		active_room.deactivate_room()
		active_room.set_lifecycle_state(Room2D.LifecycleState.UNLOADING)
		active_room.queue_free()
		active_room = null
		
		if bus != null and bus.has_signal("room_unloaded"):
			bus.room_unloaded.emit(from_id)
	
	# 3. Load destination room
	var rdata: RoomData = get_room_data(destination_room_id)
	if rdata == null or not ResourceLoader.exists(rdata.scene_path):
		is_transitioning = false
		push_error("WorldController: Scene path does not exist for room: %s" % destination_room_id)
		return false
	
	if bus != null and bus.has_signal("room_loading_started"):
		bus.room_loading_started.emit(destination_room_id)
	
	var packed_scene: PackedScene = load(rdata.scene_path)
	if packed_scene == null:
		is_transitioning = false
		push_error("WorldController: Failed to load packed scene for room: %s" % destination_room_id)
		return false
	
	var new_room_node: Node = packed_scene.instantiate()
	if not (new_room_node is Room2D):
		is_transitioning = false
		push_error("WorldController: Instantiated scene is not a Room2D: %s" % destination_room_id)
		new_room_node.queue_free()
		return false
	
	var new_room: Room2D = new_room_node as Room2D
	new_room.room_id = destination_room_id
	new_room.room_data = rdata
	
	if bus != null and bus.has_signal("room_loaded"):
		bus.room_loaded.emit(destination_room_id)
	
	# 4. Attach new room to tree
	if rooms_container != null:
		rooms_container.add_child(new_room)
	else:
		add_child(new_room)
	
	new_room.initialize_room(self)
	active_room = new_room
	current_room_id = destination_room_id
	
	# 5. Position player at destination spawn point
	var target_spawn: StringName = destination_spawn_id
	if target_spawn.is_empty():
		target_spawn = initial_spawn_id
	
	var spawn_pos: Vector2 = active_room.get_spawn_position(target_spawn)
	if player != null:
		player.global_position = spawn_pos
		player.velocity = Vector2.ZERO
	
	player_spawned.emit(current_room_id, target_spawn)
	
	# 6. Apply camera limits and reset smoothing
	var bounds: Rect2 = active_room.get_camera_bounds()
	apply_camera_bounds(bounds)
	
	# 7. Apply persistent state to new room objects
	active_room.sync_persistent_objects(world_state)
	
	# 8. Activate new room
	active_room.activate_room()
	
	if bus != null and bus.has_signal("room_activated"):
		bus.room_activated.emit(destination_room_id)
	
	is_transitioning = false
	room_transition_completed.emit(destination_room_id)
	return true

func load_room(room_id: StringName, spawn_point_id: StringName = &"") -> bool:
	return request_room_transition(room_id, spawn_point_id)

func spawn_player(room_id: StringName, spawn_point_id: StringName = &"") -> bool:
	if current_room_id != room_id:
		return request_room_transition(room_id, spawn_point_id)
	
	if active_room != null and player != null:
		var pos: Vector2 = active_room.get_spawn_position(spawn_point_id)
		player.global_position = pos
		player.velocity = Vector2.ZERO
		player_spawned.emit(room_id, spawn_point_id)
		return true
	return false

func apply_camera_bounds(bounds: Rect2) -> void:
	if player == null:
		return
	
	var cam: Camera2D = null
	if "camera" in player and player.camera is Camera2D:
		cam = player.camera
	elif player.has_node("Camera2D"):
		cam = player.get_node("Camera2D") as Camera2D
	else:
		for child in player.get_children():
			if child is Camera2D:
				cam = child as Camera2D
				break
	
	if cam != null:
		cam.limit_left = int(bounds.position.x)
		cam.limit_top = int(bounds.position.y)
		cam.limit_right = int(bounds.position.x + bounds.size.x)
		cam.limit_bottom = int(bounds.position.y + bounds.size.y)
		cam.reset_smoothing()

func set_active_checkpoint(room_id: StringName, spawn_point_id: StringName) -> void:
	active_checkpoint_room_id = room_id
	active_checkpoint_spawn_id = spawn_point_id

func respawn_player_at_checkpoint() -> bool:
	var dest_room: StringName = active_checkpoint_room_id if not active_checkpoint_room_id.is_empty() else initial_room_id
	var dest_spawn: StringName = active_checkpoint_spawn_id if not active_checkpoint_spawn_id.is_empty() else initial_spawn_id
	if dest_room.is_empty():
		return false
	
	var ok: bool = request_room_transition(dest_room, dest_spawn)
	if ok and player != null:
		if player.has_node("Components/HealthComponent"):
			var hc: HealthComponent = player.get_node("Components/HealthComponent") as HealthComponent
			if hc != null:
				hc.heal(hc.max_health)
		if player.has_node("Components/SpiritComponent"):
			var sc: SpiritComponent = player.get_node("Components/SpiritComponent") as SpiritComponent
			if sc != null:
				sc.restore_spirit(sc.get_max_spirit())
	return ok

func save_world_state(slot: int = 1) -> bool:
	var sm: Node = _get_save_manager()
	if sm != null and sm.has_method("save_to_slot"):
		var extra: Dictionary = {
			"world_state": world_state.serialize(),
			"player_capabilities": capabilities.serialize(),
			"active_checkpoint": {
				"room_id": String(active_checkpoint_room_id),
				"spawn_id": String(active_checkpoint_spawn_id)
			},
			"current_room_id": String(current_room_id)
		}
		return sm.save_to_slot(slot, extra)
	return false

func load_world_state(slot: int = 1) -> bool:
	var sm: Node = _get_save_manager()
	if sm != null and sm.has_method("load_from_slot"):
		var data: Dictionary = sm.load_from_slot(slot)
		if data.is_empty():
			return false
		if data.has("world_state") and data["world_state"] is Dictionary:
			world_state.deserialize(data["world_state"])
		if data.has("player_capabilities") and data["player_capabilities"] is Array:
			capabilities.deserialize(data["player_capabilities"])
		if data.has("active_checkpoint") and data["active_checkpoint"] is Dictionary:
			var cp_dict: Dictionary = data["active_checkpoint"] as Dictionary
			active_checkpoint_room_id = StringName(cp_dict.get("room_id", ""))
			active_checkpoint_spawn_id = StringName(cp_dict.get("spawn_id", ""))
		if data.has("current_room_id") and not String(data["current_room_id"]).is_empty():
			current_room_id = StringName(data["current_room_id"])
		return true
	return false

func _get_event_bus() -> Node:
	if Engine.has_singleton("EventBus"):
		return Engine.get_singleton("EventBus")
	var main_loop: MainLoop = Engine.get_main_loop()
	if main_loop is SceneTree:
		var root: Window = (main_loop as SceneTree).root
		if root != null and root.has_node("EventBus"):
			return root.get_node("EventBus")
	return null

func _get_save_manager() -> Node:
	if Engine.has_singleton("SaveManager"):
		return Engine.get_singleton("SaveManager")
	var main_loop: MainLoop = Engine.get_main_loop()
	if main_loop is SceneTree:
		var root: Window = (main_loop as SceneTree).root
		if root != null and root.has_node("SaveManager"):
			return root.get_node("SaveManager")
	return null
