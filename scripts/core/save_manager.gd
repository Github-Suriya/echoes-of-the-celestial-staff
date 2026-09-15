extends Node

## SaveManager
## Versioned, slot-based persistence foundation for Echoes of the Celestial Staff.
## Registered as global Autoload singleton "SaveManager".

const CURRENT_SAVE_VERSION: int = 1
const DEFAULT_SLOT: int = 1
const SAVE_PATH_TEMPLATE: String = "user://save_slot_%d.json"

var _debug_manager: Node

func _ready() -> void:
	if is_inside_tree() and has_node("/root/DebugManager"):
		_debug_manager = get_node("/root/DebugManager")
	
	if _debug_manager != null and _debug_manager.has_method("log_info"):
		_debug_manager.log_info("SaveManager initialized (Schema Version: %d)." % CURRENT_SAVE_VERSION, "SAVE")

func get_save_path(slot: int) -> String:
	return SAVE_PATH_TEMPLATE % slot

func has_save_file(slot: int) -> bool:
	var path: String = get_save_path(slot)
	return FileAccess.file_exists(path)

func save_to_slot(slot: int, extra_data: Dictionary = {}) -> bool:
	if slot <= 0:
		if _debug_manager != null and _debug_manager.has_method("log_error"):
			_debug_manager.log_error("Invalid save slot: %d" % slot, "SAVE")
		return false
	
	var save_payload: Dictionary = {
		"save_version": CURRENT_SAVE_VERSION,
		"timestamp": Time.get_datetime_string_from_system(true)
	}
	
	# Merge any extra payload fields
	for key in extra_data.keys():
		save_payload[key] = extra_data[key]
	
	var path: String = get_save_path(slot)
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		var err: Error = FileAccess.get_open_error()
		if _debug_manager != null and _debug_manager.has_method("log_error"):
			_debug_manager.log_error("Failed to open save file for writing: %s (Error: %d)" % [path, err], "SAVE")
		return false
	
	var json_string: String = JSON.stringify(save_payload, "\t")
	file.store_string(json_string)
	file.close()
	
	if _debug_manager != null and _debug_manager.has_method("log_info"):
		_debug_manager.log_info("Successfully saved to slot %d: %s" % [slot, path], "SAVE")
	return true

func load_from_slot(slot: int) -> Dictionary:
	var path: String = get_save_path(slot)
	if not FileAccess.file_exists(path):
		if _debug_manager != null and _debug_manager.has_method("log_info"):
			_debug_manager.log_info("No save file found at: %s" % path, "SAVE")
		return {}
	
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		var err: Error = FileAccess.get_open_error()
		if _debug_manager != null and _debug_manager.has_method("log_error"):
			_debug_manager.log_error("Failed to open save file for reading: %s (Error: %d)" % [path, err], "SAVE")
		return {}
	
	var json_string: String = file.get_as_text()
	file.close()
	
	var json: JSON = JSON.new()
	var parse_result: Error = json.parse(json_string)
	if parse_result != OK:
		if _debug_manager != null and _debug_manager.has_method("log_error"):
			_debug_manager.log_error("Corrupted save file at %s: JSON parse error line %d: %s" % [
				path,
				json.get_error_line(),
				json.get_error_message()
			], "SAVE")
		return {}
	
	var data: Variant = json.data
	if not (data is Dictionary):
		if _debug_manager != null and _debug_manager.has_method("log_error"):
			_debug_manager.log_error("Invalid save file structure at %s: Root is not a Dictionary." % path, "SAVE")
		return {}
	
	var save_dict: Dictionary = data as Dictionary
	if not validate_save_data(save_dict):
		if _debug_manager != null and _debug_manager.has_method("log_error"):
			_debug_manager.log_error("Save validation failed for slot %d at %s." % [slot, path], "SAVE")
		return {}
	
	if _debug_manager != null and _debug_manager.has_method("log_info"):
		_debug_manager.log_info("Successfully loaded save from slot %d." % slot, "SAVE")
	return save_dict

func validate_save_data(data: Dictionary) -> bool:
	if not data.has("save_version"):
		return false
	if not (data["save_version"] is int or data["save_version"] is float):
		return false
	if int(data["save_version"]) != CURRENT_SAVE_VERSION:
		if _debug_manager != null and _debug_manager.has_method("log_warn"):
			_debug_manager.log_warn("Save version mismatch: found %s, expected %d" % [
				str(data["save_version"]),
				CURRENT_SAVE_VERSION
			], "SAVE")
		return false
	if not data.has("timestamp"):
		return false
	return true

func delete_save_file(slot: int) -> bool:
	var path: String = get_save_path(slot)
	if not FileAccess.file_exists(path):
		return false
	var dir: DirAccess = DirAccess.open("user://")
	if dir == null:
		return false
	var err: Error = dir.remove(path.get_file())
	return err == OK
