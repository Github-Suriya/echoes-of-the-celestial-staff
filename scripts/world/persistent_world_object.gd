class_name PersistentWorldObject
extends Node2D

## PersistentWorldObject
## Base node for world entities whose state must persist across room transitions
## and save files (e.g. opened doors, broken walls, collected relics).

@export var persistent_id: StringName = &""
@export var auto_sync_on_ready: bool = true

func _ready() -> void:
	if auto_sync_on_ready:
		var room: Node = _get_parent_room()
		if room != null and room.has_method("get_world_controller"):
			var wc: Node = room.get_world_controller()
			if wc != null and "world_state" in wc and wc.world_state != null:
				apply_state(wc.world_state)

func apply_state(state: WorldState) -> void:
	if state == null or persistent_id.is_empty():
		return
	var flag_name: StringName = StringName("obj_%s_active" % persistent_id)
	visible = state.get_flag(flag_name, visible)

func record_state(state: WorldState) -> void:
	if state == null or persistent_id.is_empty():
		return
	var flag_name: StringName = StringName("obj_%s_active" % persistent_id)
	state.set_flag(flag_name, visible)

func _get_parent_room() -> Node:
	var curr: Node = get_parent()
	while curr != null:
		if curr is Room2D:
			return curr
		curr = curr.get_parent()
	return null
