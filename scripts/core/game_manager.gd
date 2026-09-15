extends Node

## GameManager
## Coordinates high-level game states, lifecycle transitions, pause state, and engine timescale.
## Registered as global Autoload singleton "GameManager".

enum GameState {
	BOOT,
	MENU,
	PLAYING,
	PAUSED,
	CUTSCENE,
	LOADING,
	GAME_OVER
}

var current_state: GameState = GameState.BOOT
var previous_state: GameState = GameState.BOOT

var _is_paused: bool = false
var _event_bus: Node
var _debug_manager: Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	if is_inside_tree():
		if has_node("/root/EventBus"):
			_event_bus = get_node("/root/EventBus")
		if has_node("/root/DebugManager"):
			_debug_manager = get_node("/root/DebugManager")
	
	if _debug_manager != null and _debug_manager.has_method("log_info"):
		_debug_manager.log_info("GameManager initialized in state: BOOT", "GAME")

func set_game_state(new_state: GameState) -> void:
	if current_state == new_state:
		return
	
	previous_state = current_state
	current_state = new_state
	
	if _debug_manager != null and _debug_manager.has_method("log_info"):
		_debug_manager.log_info("Game state changed: %s -> %s" % [
			_get_state_name(previous_state),
			_get_state_name(current_state)
		], "GAME")
	
	if _event_bus != null and _event_bus.has_signal("game_state_changed"):
		_event_bus.game_state_changed.emit(previous_state, current_state)

func get_game_state() -> GameState:
	return current_state

func get_game_state_name() -> String:
	return _get_state_name(current_state)

func is_playing() -> bool:
	return current_state == GameState.PLAYING

func is_paused() -> bool:
	return _is_paused

func set_paused(paused: bool) -> void:
	if _is_paused == paused:
		return
	
	_is_paused = paused
	if is_inside_tree():
		get_tree().paused = _is_paused
	
	if _is_paused:
		if current_state == GameState.PLAYING:
			set_game_state(GameState.PAUSED)
		if _event_bus != null and _event_bus.has_signal("game_paused"):
			_event_bus.game_paused.emit(true)
	else:
		if current_state == GameState.PAUSED:
			set_game_state(GameState.PLAYING)
		if _event_bus != null:
			if _event_bus.has_signal("game_paused"):
				_event_bus.game_paused.emit(false)
			if _event_bus.has_signal("game_resumed"):
				_event_bus.game_resumed.emit()
	
	if _debug_manager != null and _debug_manager.has_method("log_info"):
		_debug_manager.log_info("Game paused: %s" % str(_is_paused), "GAME")

func toggle_pause() -> void:
	if current_state == GameState.PLAYING or current_state == GameState.PAUSED:
		set_paused(not _is_paused)

func set_time_scale(scale: float) -> void:
	Engine.time_scale = maxf(0.0, scale)

func reset_time_scale() -> void:
	Engine.time_scale = 1.0

func _get_state_name(state: GameState) -> String:
	match state:
		GameState.BOOT:
			return "BOOT"
		GameState.MENU:
			return "MENU"
		GameState.PLAYING:
			return "PLAYING"
		GameState.PAUSED:
			return "PAUSED"
		GameState.CUTSCENE:
			return "CUTSCENE"
		GameState.LOADING:
			return "LOADING"
		GameState.GAME_OVER:
			return "GAME_OVER"
		_:
			return "UNKNOWN"
