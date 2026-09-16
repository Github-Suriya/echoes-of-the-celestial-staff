class_name PlayerCapabilities
extends RefCounted

## PlayerCapabilities
## Decoupled capability and progression query interface for Metroidvania gating.
## Maintains permanent ability unlocks (e.g. Celestial Arc, Cloud Step, Astral Grip)
## independent of combat resource balances or spirit pools.

signal capability_unlocked(ability_id: StringName)
signal capability_locked(ability_id: StringName)
signal capabilities_cleared()

var _unlocked_abilities: Dictionary = {} # StringName -> bool

func _init() -> void:
	_unlocked_abilities = {}

func has_ability(ability_id: StringName) -> bool:
	return _unlocked_abilities.get(ability_id, false)

func unlock_ability(ability_id: StringName) -> bool:
	if ability_id.is_empty():
		return false
	if _unlocked_abilities.get(ability_id, false):
		return false # Already unlocked
	
	_unlocked_abilities[ability_id] = true
	capability_unlocked.emit(ability_id)
	
	var bus: Node = _get_event_bus()
	if bus != null and bus.has_signal("ability_unlocked"):
		bus.ability_unlocked.emit(String(ability_id))
	
	return true

func lock_ability(ability_id: StringName) -> bool:
	if not _unlocked_abilities.has(ability_id):
		return false
	_unlocked_abilities.erase(ability_id)
	capability_locked.emit(ability_id)
	return true

func toggle_ability(ability_id: StringName) -> bool:
	if has_ability(ability_id):
		lock_ability(ability_id)
		return false
	else:
		unlock_ability(ability_id)
		return true

func get_unlocked_abilities() -> Array[StringName]:
	var list: Array[StringName] = []
	for k in _unlocked_abilities.keys():
		if _unlocked_abilities[k]:
			list.append(k)
	return list

func clear_capabilities() -> void:
	_unlocked_abilities.clear()
	capabilities_cleared.emit()

func serialize() -> Array[String]:
	var result: Array[String] = []
	for k in _unlocked_abilities.keys():
		if _unlocked_abilities[k]:
			result.append(String(k))
	return result

func deserialize(data: Array) -> void:
	clear_capabilities()
	for item in data:
		if item is String or item is StringName:
			_unlocked_abilities[StringName(item)] = true

func _get_event_bus() -> Node:
	if Engine.has_singleton("EventBus"):
		return Engine.get_singleton("EventBus")
	var main_loop: MainLoop = Engine.get_main_loop()
	if main_loop is SceneTree:
		var root: Window = (main_loop as SceneTree).root
		if root != null and root.has_node("EventBus"):
			return root.get_node("EventBus")
	return null
