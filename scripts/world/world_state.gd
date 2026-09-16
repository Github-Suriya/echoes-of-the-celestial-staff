class_name WorldState
extends RefCounted

## WorldState
## Lightweight, deterministic persistent state manager for Metroidvania flags.
## Coordinates boss defeats, opened doors, triggered checkpoints, and puzzle milestones.
## Supports clean serialization into SaveManager slots.

signal flag_changed(flag_name: StringName, value: bool)
signal state_reset()

var _flags: Dictionary = {} # StringName -> bool
var _data: Dictionary = {} # StringName -> Variant

func _init() -> void:
	_flags = {}
	_data = {}

func set_flag(flag_name: StringName, value: bool = true) -> void:
	if flag_name.is_empty():
		return
	var old_val: bool = _flags.get(flag_name, false)
	_flags[flag_name] = value
	if old_val != value:
		flag_changed.emit(flag_name, value)
		var bus: Node = _get_event_bus()
		if bus != null and bus.has_signal("world_flag_changed"):
			bus.world_flag_changed.emit(flag_name, value)

func get_flag(flag_name: StringName, default_value: bool = false) -> bool:
	return _flags.get(flag_name, default_value)

func has_flag(flag_name: StringName) -> bool:
	return _flags.has(flag_name) and bool(_flags[flag_name])

func clear_flag(flag_name: StringName) -> void:
	if _flags.has(flag_name):
		_flags.erase(flag_name)
		flag_changed.emit(flag_name, false)
		var bus: Node = _get_event_bus()
		if bus != null and bus.has_signal("world_flag_changed"):
			bus.world_flag_changed.emit(flag_name, false)

func set_data(key: StringName, value: Variant) -> void:
	if key.is_empty():
		return
	_data[key] = value

func get_data(key: StringName, default_value: Variant = null) -> Variant:
	return _data.get(key, default_value)

func has_data(key: StringName) -> bool:
	return _data.has(key)

func clear_data(key: StringName) -> void:
	_data.erase(key)

func reset() -> void:
	_flags.clear()
	_data.clear()
	state_reset.emit()

func serialize() -> Dictionary:
	var flags_dict: Dictionary = {}
	for k in _flags.keys():
		flags_dict[String(k)] = _flags[k]
	
	var data_dict: Dictionary = {}
	for k in _data.keys():
		data_dict[String(k)] = _data[k]
	
	return {
		"flags": flags_dict,
		"data": data_dict
	}

func deserialize(data: Dictionary) -> void:
	reset()
	if data.has("flags") and data["flags"] is Dictionary:
		var flags_dict: Dictionary = data["flags"] as Dictionary
		for k in flags_dict.keys():
			_flags[StringName(k)] = bool(flags_dict[k])
	
	if data.has("data") and data["data"] is Dictionary:
		var data_dict: Dictionary = data["data"] as Dictionary
		for k in data_dict.keys():
			_data[StringName(k)] = data_dict[k]

func _get_event_bus() -> Node:
	if Engine.has_singleton("EventBus"):
		return Engine.get_singleton("EventBus")
	var main_loop: MainLoop = Engine.get_main_loop()
	if main_loop is SceneTree:
		var root: Window = (main_loop as SceneTree).root
		if root != null and root.has_node("EventBus"):
			return root.get_node("EventBus")
	return null
