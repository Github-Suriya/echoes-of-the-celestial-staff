extends Node

## SceneManager
## Handles safe scene transitions, tracking the current scene, and notifying via EventBus.
## Registered as global Autoload singleton "SceneManager".

signal transition_started(target_scene: String)
signal transition_completed(loaded_scene: String)

var current_scene_path: String = ""
var is_transitioning: bool = false

var _event_bus: Node
var _debug_manager: Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if is_inside_tree():
		if has_node("/root/EventBus"):
			_event_bus = get_node("/root/EventBus")
		if has_node("/root/DebugManager"):
			_debug_manager = get_node("/root/DebugManager")
		
		# Determine initial scene if loaded
		if get_tree() != null and get_tree().current_scene != null:
			current_scene_path = get_tree().current_scene.scene_file_path
	
	if _debug_manager != null and _debug_manager.has_method("log_info"):
		_debug_manager.log_info("SceneManager initialized. Current scene: %s" % current_scene_path, "SCENE")

func change_scene_to_file(scene_path: String) -> bool:
	if is_transitioning:
		if _debug_manager != null and _debug_manager.has_method("log_warn"):
			_debug_manager.log_warn("Scene transition rejected: already transitioning.", "SCENE")
		return false
	
	if not ResourceLoader.exists(scene_path):
		if _debug_manager != null and _debug_manager.has_method("log_error"):
			_debug_manager.log_error("Scene file does not exist: %s" % scene_path, "SCENE")
		return false
	
	is_transitioning = true
	transition_started.emit(scene_path)
	
	var old_scene_path: String = current_scene_path
	if _event_bus != null and _event_bus.has_signal("scene_unloaded") and not old_scene_path.is_empty():
		_event_bus.scene_unloaded.emit(old_scene_path)
	
	if _debug_manager != null and _debug_manager.has_method("log_info"):
		_debug_manager.log_info("Transitioning from '%s' to '%s'" % [old_scene_path, scene_path], "SCENE")
	
	if not is_inside_tree() or get_tree() == null:
		is_transitioning = false
		return false
	
	var err: Error = get_tree().change_scene_to_file(scene_path)
	if err != OK:
		is_transitioning = false
		if _debug_manager != null and _debug_manager.has_method("log_error"):
			_debug_manager.log_error("Failed to change scene to '%s'. Error code: %d" % [scene_path, err], "SCENE")
		return false
	
	current_scene_path = scene_path
	is_transitioning = false
	transition_completed.emit(scene_path)
	
	if _event_bus != null and _event_bus.has_signal("scene_loaded"):
		_event_bus.scene_loaded.emit(scene_path)
	
	return true

func change_scene_to_packed(packed_scene: PackedScene) -> bool:
	if is_transitioning:
		if _debug_manager != null and _debug_manager.has_method("log_warn"):
			_debug_manager.log_warn("Scene transition rejected: already transitioning.", "SCENE")
		return false
	
	if packed_scene == null:
		if _debug_manager != null and _debug_manager.has_method("log_error"):
			_debug_manager.log_error("PackedScene is null.", "SCENE")
		return false
	
	is_transitioning = true
	var target_path: String = packed_scene.resource_path
	transition_started.emit(target_path)
	
	var old_scene_path: String = current_scene_path
	if _event_bus != null and _event_bus.has_signal("scene_unloaded") and not old_scene_path.is_empty():
		_event_bus.scene_unloaded.emit(old_scene_path)
	
	if not is_inside_tree() or get_tree() == null:
		is_transitioning = false
		return false
	
	var err: Error = get_tree().change_scene_to_packed(packed_scene)
	if err != OK:
		is_transitioning = false
		if _debug_manager != null and _debug_manager.has_method("log_error"):
			_debug_manager.log_error("Failed to change scene to packed. Error code: %d" % err, "SCENE")
		return false
	
	current_scene_path = target_path
	is_transitioning = false
	transition_completed.emit(target_path)
	
	if _event_bus != null and _event_bus.has_signal("scene_loaded"):
		_event_bus.scene_loaded.emit(target_path)
	
	return true

func reload_current_scene() -> bool:
	if current_scene_path.is_empty():
		if _debug_manager != null and _debug_manager.has_method("log_warn"):
			_debug_manager.log_warn("Cannot reload scene: current scene path is empty.", "SCENE")
		return false
	return change_scene_to_file(current_scene_path)
