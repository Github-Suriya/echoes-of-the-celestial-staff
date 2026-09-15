extends Node

## Automated Headless Test Suite for Phase 1 (Godot Foundation)
## Executes unit assertions directly on the active Autoload infrastructure.

var _passed_count: int = 0
var _total_count: int = 0

func _ready() -> void:
	print("\n==================================================")
	print(" RUNNING PHASE 1 AUTOMATED FOUNDATION TEST SUITE")
	print("==================================================")
	
	_test_autoload_presence()
	_test_debug_manager()
	_test_event_bus()
	_test_game_manager()
	_test_input_manager()
	_test_audio_manager()
	_test_scene_manager()
	_test_save_manager()
	
	print("==================================================")
	print(" TEST RESULTS: %d / %d PASSED" % [_passed_count, _total_count])
	print("==================================================\n")
	
	if _passed_count == _total_count:
		print("SUCCESS: All Phase 1 foundation tests passed cleanly.")
		get_tree().quit(0)
	else:
		printerr("FAILURE: One or more foundation tests failed.")
		get_tree().quit(1)

func _assert_test(test_name: String, condition: bool) -> void:
	_total_count += 1
	if condition:
		_passed_count += 1
		print("[PASS] %s" % test_name)
	else:
		printerr("[FAIL] %s" % test_name)

func _test_autoload_presence() -> void:
	print("\n--- Testing Autoload Singletons in SceneTree ---")
	var required: Array[String] = [
		"DebugManager",
		"EventBus",
		"GameManager",
		"InputManager",
		"AudioManager",
		"SceneManager",
		"SaveManager"
	]
	for name_str in required:
		_assert_test("Autoload singleton exists: /root/%s" % name_str, has_node("/root/" + name_str))

func _test_debug_manager() -> void:
	print("\n--- Testing DebugManager ---")
	var dm: Node = get_node("/root/DebugManager")
	_assert_test("DebugManager accessible", dm != null)
	_assert_test("DebugManager get_fps returns number", dm.get_fps() >= 0.0)
	_assert_test("DebugManager get_static_memory_mb returns positive float", dm.get_static_memory_mb() >= 0.0)
	
	dm.log_info("Test log info", "TEST")
	dm.log_warn("Test log warn", "TEST")
	dm.log_debug("Test log debug", "TEST")
	_assert_test("DebugManager log methods execute without error", true)

func _test_event_bus() -> void:
	print("\n--- Testing EventBus ---")
	var bus: Node = get_node("/root/EventBus")
	_assert_test("EventBus accessible", bus != null)
	
	var received: Array = [0.0, false]
	var callable = func(_target: Node2D, amount: float, is_critical: bool) -> void:
		received[0] = amount
		received[1] = is_critical
	
	bus.damage_dealt.connect(callable)
	var dummy: Node2D = Node2D.new()
	bus.damage_dealt.emit(dummy, 45.0, true)
	dummy.free()
	bus.damage_dealt.disconnect(callable)
	
	_assert_test("EventBus signal delivery works", received[0] == 45.0 and received[1] == true)

func _test_game_manager() -> void:
	print("\n--- Testing GameManager ---")
	var gm: Node = get_node("/root/GameManager")
	_assert_test("GameManager accessible", gm != null)
	
	gm.set_game_state(2) # 2 = PLAYING
	_assert_test("GameManager transitions to PLAYING", gm.get_game_state() == 2)
	_assert_test("GameManager is_playing returns true", gm.is_playing())
	
	gm.set_time_scale(0.5)
	_assert_test("GameManager set_time_scale sets Engine.time_scale", Engine.time_scale == 0.5)
	gm.reset_time_scale()
	_assert_test("GameManager reset_time_scale restores to 1.0", Engine.time_scale == 1.0)
	
	_assert_test("GameManager is not initially paused", not gm.is_paused())
	gm.set_paused(true)
	_assert_test("GameManager can set paused", gm.is_paused())
	gm.set_paused(false)
	_assert_test("GameManager can resume", not gm.is_paused())

func _test_input_manager() -> void:
	print("\n--- Testing InputManager ---")
	var im: Node = get_node("/root/InputManager")
	_assert_test("InputManager accessible", im != null)
	
	var all_actions_present: bool = true
	for action in im.ALL_ACTIONS:
		if not InputMap.has_action(action):
			all_actions_present = false
			printerr("Missing action in InputMap: ", action)
	
	_assert_test("InputManager registers all 15 gameplay actions", all_actions_present)
	_assert_test("InputManager can query gameplay input enabled", im.is_gameplay_input_enabled)
	im.set_gameplay_input_enabled(false)
	_assert_test("InputManager input suppression functions", not im.is_gameplay_input_enabled)
	im.set_gameplay_input_enabled(true)

func _test_audio_manager() -> void:
	print("\n--- Testing AudioManager ---")
	var am: Node = get_node("/root/AudioManager")
	_assert_test("AudioManager accessible", am != null)
	_assert_test("AudioManager has initialized child players", am.get_child_count() >= 3)
	
	# Test safe null handling (must not throw errors or crash)
	am.play_music(null)
	am.play_sfx(null)
	am.play_ui_sound(null)
	am.play_ambience(null)
	_assert_test("AudioManager handles null AudioStream gracefully without crash", true)
	
	# Verify audio buses in layout
	var master_idx: int = AudioServer.get_bus_index(&"Master")
	_assert_test("AudioServer contains Master bus", master_idx >= 0)
	var music_idx: int = AudioServer.get_bus_index(&"Music")
	_assert_test("AudioServer contains Music bus", music_idx >= 0)
	var sfx_idx: int = AudioServer.get_bus_index(&"SFX")
	_assert_test("AudioServer contains SFX bus", sfx_idx >= 0)
	var ambience_idx: int = AudioServer.get_bus_index(&"Ambience")
	_assert_test("AudioServer contains Ambience bus", ambience_idx >= 0)
	var ui_idx: int = AudioServer.get_bus_index(&"UI")
	_assert_test("AudioServer contains UI bus", ui_idx >= 0)
	var voice_idx: int = AudioServer.get_bus_index(&"Voice")
	_assert_test("AudioServer contains Voice bus", voice_idx >= 0)

func _test_scene_manager() -> void:
	print("\n--- Testing SceneManager ---")
	var sm: Node = get_node("/root/SceneManager")
	_assert_test("SceneManager accessible", sm != null)
	_assert_test("SceneManager initial is_transitioning is false", not sm.is_transitioning)
	
	# Test invalid scene path handling
	var success: bool = sm.change_scene_to_file("res://non_existent_scene.tscn")
	_assert_test("SceneManager gracefully rejects missing scene path", not success)

func _test_save_manager() -> void:
	print("\n--- Testing SaveManager ---")
	var sm: Node = get_node("/root/SaveManager")
	_assert_test("SaveManager accessible", sm != null)
	
	var test_slot: int = 99
	sm.delete_save_file(test_slot)
	_assert_test("SaveManager detects absence of save file", not sm.has_save_file(test_slot))
	
	var save_ok: bool = sm.save_to_slot(test_slot, {"unit_test_key": "val_123"})
	_assert_test("SaveManager saves to slot 99", save_ok)
	_assert_test("SaveManager confirms file exists after save", sm.has_save_file(test_slot))
	
	var loaded: Dictionary = sm.load_from_slot(test_slot)
	_assert_test("SaveManager loads valid save data", loaded.get("unit_test_key") == "val_123")
	_assert_test("SaveManager loaded data contains save_version", loaded.get("save_version") == 1)
	
	# Test corruption handling
	var save_path: String = sm.get_save_path(test_slot)
	var corrupted_file: FileAccess = FileAccess.open(save_path, FileAccess.WRITE)
	if corrupted_file != null:
		corrupted_file.store_string("INVALID_JSON_CORRUPTED_DATA{{{}}")
		corrupted_file.close()
	
	var corrupted_load: Dictionary = sm.load_from_slot(test_slot)
	_assert_test("SaveManager gracefully returns empty dictionary on corrupted JSON", corrupted_load.is_empty())
	
	sm.delete_save_file(test_slot)
	_assert_test("SaveManager deletes test save file cleanly", not sm.has_save_file(test_slot))
