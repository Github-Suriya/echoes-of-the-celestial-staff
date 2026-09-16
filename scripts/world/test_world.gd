class_name TestWorld
extends WorldController

## TestWorld
## Interactive harness and entrypoint for the Phase 10 Metroidvania World System.
## Hosts WorldController with registered rooms (A, B, C), player, HUD,
## debug telemetry overlay, and testing shortcuts.

@export var room_a_data: RoomData
@export var room_b_data: RoomData
@export var room_c_data: RoomData

@onready var telemetry_label: Label = $DebugTelemetry/PanelContainer/MarginContainer/VBoxContainer/TelemetryLabel if has_node("DebugTelemetry/PanelContainer/MarginContainer/VBoxContainer/TelemetryLabel") else null

func _ready() -> void:
	# Register default test world rooms if provided or from data
	if room_a_data != null:
		register_room(room_a_data)
	elif ResourceLoader.exists("res://data/world/room_a.tres"):
		register_room(load("res://data/world/room_a.tres"))
	
	if room_b_data != null:
		register_room(room_b_data)
	elif ResourceLoader.exists("res://data/world/room_b.tres"):
		register_room(load("res://data/world/room_b.tres"))
	
	if room_c_data != null:
		register_room(room_c_data)
	elif ResourceLoader.exists("res://data/world/room_c.tres"):
		register_room(load("res://data/world/room_c.tres"))
	
	initial_room_id = &"room_a"
	initial_spawn_id = &"start"
	
	super._ready()
	
	if has_node("/root/GameManager"):
		var gm: Node = get_node("/root/GameManager")
		if gm != null and gm.has_method("set_game_state"):
			gm.set_game_state(2) # GameState.PLAYING

func _process(_delta: float) -> void:
	_update_telemetry()

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	
	match event.keycode:
		KEY_R:
			respawn_player_at_checkpoint()
		KEY_T:
			_restore_player_spirit()
		KEY_C:
			_cycle_player_stance()
		KEY_F:
			_trigger_awakening()
		KEY_1:
			capabilities.toggle_ability(&"celestial_arc")
		KEY_2:
			capabilities.toggle_ability(&"cloud_step")
		KEY_3:
			capabilities.clear_capabilities()

func _restore_player_spirit() -> void:
	if player != null and player.has_node("Components/SpiritComponent"):
		var sc: Node = player.get_node("Components/SpiritComponent")
		if sc != null and sc.has_method("restore_spirit"):
			sc.restore_spirit(100.0)

func _cycle_player_stance() -> void:
	if player != null and player.has_node("Components/StanceController"):
		var stance_ctrl: Node = player.get_node("Components/StanceController")
		if stance_ctrl != null and stance_ctrl.has_method("cycle_stance"):
			stance_ctrl.cycle_stance()

func _trigger_awakening() -> void:
	if player != null and player.has_node("Components/TransformationController"):
		var trans: Node = player.get_node("Components/TransformationController")
		if trans != null and trans.has_method("activate"):
			trans.activate()

func _update_telemetry() -> void:
	if telemetry_label == null:
		return
	
	var r_id: String = String(current_room_id)
	var r_name: String = ""
	var r_life: String = "NONE"
	if active_room != null:
		r_life = active_room.get_lifecycle_state_name()
		if active_room.room_data != null:
			r_name = active_room.room_data.display_name
	
	var p_pos: Vector2 = player.global_position if player != null else Vector2.ZERO
	var cp_str: String = "%s (%s)" % [String(active_checkpoint_room_id), String(active_checkpoint_spawn_id)]
	if active_checkpoint_room_id.is_empty():
		cp_str = "None (Initial Spawn)"
	
	var caps_list: Array[StringName] = capabilities.get_unlocked_abilities() if capabilities != null else []
	var caps_str: String = ", ".join(caps_list) if not caps_list.is_empty() else "None"
	
	var flags_dict: Dictionary = world_state._flags if world_state != null else {}
	var flags_list: Array[String] = []
	for k in flags_dict.keys():
		if flags_dict[k]:
			flags_list.append(String(k))
	var flags_str: String = ", ".join(flags_list) if not flags_list.is_empty() else "None"
	
	telemetry_label.text = """[WORLD TELEMETRY]
Room: %s [%s] (%s)
Player Pos: (%d, %d)
Active Checkpoint: %s
Capabilities: %s
Flags: %s
Transitioning: %s

[CONTROLS]
[R] Respawn | [T] Spirit | [C] Stance | [F] Awakening
[1] Toggle Celestial Arc | [2] Toggle Cloud Step | [3] Clear Caps""" % [
		r_id,
		r_name,
		r_life,
		int(p_pos.x),
		int(p_pos.y),
		cp_str,
		caps_str,
		flags_str,
		str(is_transitioning)
	]
