extends Node

## InputManager
## Centralizes input query abstraction, action names, and input availability.
## Registered as global Autoload singleton "InputManager".

# Standard Action Name Constants
const ACTION_MOVE_LEFT: StringName = &"move_left"
const ACTION_MOVE_RIGHT: StringName = &"move_right"
const ACTION_JUMP: StringName = &"jump"
const ACTION_LIGHT_ATTACK: StringName = &"light_attack"
const ACTION_HEAVY_ATTACK: StringName = &"heavy_attack"
const ACTION_DODGE: StringName = &"dodge"
const ACTION_PARRY: StringName = &"parry"
const ACTION_ABILITY_1: StringName = &"ability_1"
const ACTION_ABILITY_2: StringName = &"ability_2"
const ACTION_ABILITY_3: StringName = &"ability_3"
const ACTION_ABILITY_4: StringName = &"ability_4"
const ACTION_STANCE_SWITCH: StringName = &"stance_switch"
const ACTION_INTERACT: StringName = &"interact"
const ACTION_MAP: StringName = &"map"
const ACTION_PAUSE: StringName = &"pause"

const ALL_ACTIONS: Array[StringName] = [
	ACTION_MOVE_LEFT,
	ACTION_MOVE_RIGHT,
	ACTION_JUMP,
	ACTION_LIGHT_ATTACK,
	ACTION_HEAVY_ATTACK,
	ACTION_DODGE,
	ACTION_PARRY,
	ACTION_ABILITY_1,
	ACTION_ABILITY_2,
	ACTION_ABILITY_3,
	ACTION_ABILITY_4,
	ACTION_STANCE_SWITCH,
	ACTION_INTERACT,
	ACTION_MAP,
	ACTION_PAUSE
]

var is_gameplay_input_enabled: bool = true
var _debug_manager: Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if is_inside_tree() and has_node("/root/DebugManager"):
		_debug_manager = get_node("/root/DebugManager")
	
	_ensure_default_action_mappings()
	if _debug_manager != null and _debug_manager.has_method("log_info"):
		_debug_manager.log_info("InputManager initialized with 15 standard actions.", "INPUT")

func _unhandled_input(event: InputEvent) -> void:
	# Global pause handling via InputManager
	if event.is_action_pressed(ACTION_PAUSE):
		if is_inside_tree() and has_node("/root/GameManager"):
			var gm: Node = get_node("/root/GameManager")
			if gm != null and gm.has_method("toggle_pause"):
				gm.toggle_pause()
				if is_inside_tree() and get_viewport() != null:
					get_viewport().set_input_as_handled()

func is_action_just_pressed(action_name: StringName) -> bool:
	if not is_gameplay_input_enabled and action_name != ACTION_PAUSE:
		return false
	return Input.is_action_just_pressed(action_name)

func is_action_pressed(action_name: StringName) -> bool:
	if not is_gameplay_input_enabled and action_name != ACTION_PAUSE:
		return false
	return Input.is_action_pressed(action_name)

func is_action_just_released(action_name: StringName) -> bool:
	if not is_gameplay_input_enabled and action_name != ACTION_PAUSE:
		return false
	return Input.is_action_just_released(action_name)

func get_movement_axis() -> float:
	if not is_gameplay_input_enabled:
		return 0.0
	return Input.get_axis(ACTION_MOVE_LEFT, ACTION_MOVE_RIGHT)

func has_registered_action(action_name: StringName) -> bool:
	return InputMap.has_action(action_name)

func set_gameplay_input_enabled(enabled: bool) -> void:
	is_gameplay_input_enabled = enabled
	if _debug_manager != null and _debug_manager.has_method("log_info"):
		_debug_manager.log_info("Gameplay input enabled: %s" % str(enabled), "INPUT")

func _ensure_default_action_mappings() -> void:
	var key_defaults: Dictionary = {
		ACTION_MOVE_LEFT: [KEY_A, KEY_LEFT],
		ACTION_MOVE_RIGHT: [KEY_D, KEY_RIGHT],
		ACTION_JUMP: [KEY_SPACE, KEY_W],
		ACTION_LIGHT_ATTACK: [KEY_J],
		ACTION_HEAVY_ATTACK: [KEY_K],
		ACTION_DODGE: [KEY_SHIFT],
		ACTION_PARRY: [KEY_Q],
		ACTION_ABILITY_1: [KEY_1],
		ACTION_ABILITY_2: [KEY_2],
		ACTION_ABILITY_3: [KEY_3],
		ACTION_ABILITY_4: [KEY_4],
		ACTION_STANCE_SWITCH: [KEY_TAB],
		ACTION_INTERACT: [KEY_E],
		ACTION_MAP: [KEY_M],
		ACTION_PAUSE: [KEY_ESCAPE]
	}
	
	var mouse_defaults: Dictionary = {
		ACTION_LIGHT_ATTACK: [MOUSE_BUTTON_LEFT],
		ACTION_HEAVY_ATTACK: [MOUSE_BUTTON_RIGHT]
	}
	
	for action in ALL_ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		if key_defaults.has(action):
			for key_code in key_defaults[action]:
				var ev: InputEventKey = InputEventKey.new()
				ev.physical_keycode = key_code
				InputMap.action_add_event(action, ev)
		if mouse_defaults.has(action):
			for mouse_btn in mouse_defaults[action]:
				var mev: InputEventMouseButton = InputEventMouseButton.new()
				mev.button_index = mouse_btn
				InputMap.action_add_event(action, mev)
