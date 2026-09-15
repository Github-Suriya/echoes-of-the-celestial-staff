class_name Bootstrap
extends Node

## Bootstrap
## Minimal entry-point controller for Echoes of the Celestial Staff.
## Verifies core autoload infrastructure, initializes state, and transitions to the initial scene.

@export var next_scene_path: String = "res://scenes/core/test_scene.tscn"

func _ready() -> void:
	_verify_foundation()
	_proceed_to_next_scene()

func _verify_foundation() -> void:
	var required_autoloads: Array[String] = [
		"DebugManager",
		"EventBus",
		"GameManager",
		"InputManager",
		"AudioManager",
		"SceneManager",
		"SaveManager"
	]
	
	var missing: Array[String] = []
	for name_str in required_autoloads:
		if not has_node("/root/" + name_str):
			missing.append(name_str)
	
	if missing.size() > 0:
		push_error("[BOOTSTRAP] Critical Error: Missing required Autoloads: %s" % str(missing))
		return
	
	var dm: DebugManager = get_node("/root/DebugManager") as DebugManager
	if dm != null:
		dm.log_info("Bootstrap verification passed: all 7 Autoloads verified.", "BOOTSTRAP")

func _proceed_to_next_scene() -> void:
	var gm: GameManager = get_node_or_null("/root/GameManager") as GameManager
	if gm != null:
		gm.set_game_state(GameManager.GameState.MENU)
	
	var sm: SceneManager = get_node_or_null("/root/SceneManager") as SceneManager
	if sm != null:
		# Defer scene change slightly to allow node tree stabilization
		call_deferred("_change_scene", sm)

func _change_scene(sm: SceneManager) -> void:
	sm.change_scene_to_file(next_scene_path)
