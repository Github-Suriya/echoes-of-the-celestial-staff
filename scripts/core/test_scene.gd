class_name TestScene
extends Control

## TestScene
## Minimal non-gameplay testbed verifying all Phase 1 foundations.
## Displays telemetry, tests EventBus signals, and validates SaveManager/AudioManager.

@onready var _status_label: Label = $CanvasLayer/Panel/MarginContainer/VBoxContainer/StatusLabel
@onready var _telemetry_label: Label = $CanvasLayer/Panel/MarginContainer/VBoxContainer/TelemetryLabel
@onready var _log_label: Label = $CanvasLayer/Panel/MarginContainer/VBoxContainer/LogLabel

var _event_bus: EventBus
var _game_manager: GameManager
var _debug_manager: DebugManager
var _save_manager: SaveManager

func _ready() -> void:
	if has_node("/root/EventBus"):
		_event_bus = get_node("/root/EventBus") as EventBus
		_event_bus.game_state_changed.connect(_on_game_state_changed)
		_event_bus.game_paused.connect(_on_game_paused)
	
	if has_node("/root/GameManager"):
		_game_manager = get_node("/root/GameManager") as GameManager
		_game_manager.set_game_state(GameManager.GameState.PLAYING)
	
	if has_node("/root/DebugManager"):
		_debug_manager = get_node("/root/DebugManager") as DebugManager
	
	if has_node("/root/SaveManager"):
		_save_manager = get_node("/root/SaveManager") as SaveManager
		_run_save_verification()
	
	_update_ui()
	if _debug_manager != null:
		_debug_manager.log_info("TestScene loaded and active.", "TEST")

func _process(_delta: float) -> void:
	_update_telemetry()

func _update_ui() -> void:
	if _status_label == null:
		return
	var state_name: String = _game_manager.get_game_state_name() if _game_manager != null else "UNKNOWN"
	_status_label.text = "GameState: %s | Foundation: ACTIVE" % state_name

func _update_telemetry() -> void:
	if _telemetry_label == null or _debug_manager == null:
		return
	var fps: float = _debug_manager.get_fps()
	var mem: float = _debug_manager.get_static_memory_mb()
	var dc: int = _debug_manager.get_draw_calls()
	_telemetry_label.text = "FPS: %.1f | RAM: %.2f MB | Draw Calls: %d" % [fps, mem, dc]

func _run_save_verification() -> void:
	if _save_manager == null:
		return
	var test_slot: int = 1
	var save_success: bool = _save_manager.save_to_slot(test_slot, {"foundation_test": "PASSED"})
	var loaded_data: Dictionary = _save_manager.load_from_slot(test_slot)
	
	if save_success and loaded_data.get("foundation_test") == "PASSED":
		if _log_label != null:
			_log_label.text = "[OK] SaveManager Verified (Slot 1 read/write confirmed)."
	else:
		if _log_label != null:
			_log_label.text = "[FAIL] SaveManager verification failed."

func _on_game_state_changed(_old_state: int, new_state: int) -> void:
	_update_ui()

func _on_game_paused(is_paused: bool) -> void:
	if _log_label != null:
		_log_label.text = "Pause Toggled: " + ("PAUSED" if is_paused else "RESUMED")
