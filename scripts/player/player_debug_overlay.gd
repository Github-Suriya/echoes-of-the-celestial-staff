class_name PlayerDebugOverlay
extends CanvasLayer

## PlayerDebugOverlay
## Real-time movement diagnostics overlay.
## Automatically enabled in debug builds, toggleable with F3.

@onready var _label: Label = $PanelContainer/MarginContainer/DebugLabel

var _player: CharacterBody2D = null

func _ready() -> void:
	# Hide by default in non-debug export builds
	visible = OS.is_debug_build()
	if owner is CharacterBody2D:
		_player = owner as CharacterBody2D

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F3:
			visible = not visible

func _process(_delta: float) -> void:
	if not visible or _player == null or _label == null:
		return
	
	var movement: Node = null
	if _player.has_node("Components/PlayerMovement"):
		movement = _player.get_node("Components/PlayerMovement")
	
	var state_machine: Node = null
	if _player.has_node("StateMachine"):
		state_machine = _player.get_node("StateMachine")
	
	var fps: float = Performance.get_monitor(Performance.TIME_FPS)
	var pos: Vector2 = _player.global_position
	var vel: Vector2 = _player.velocity
	var grounded: bool = _player.is_on_floor()
	var state_name: String = state_machine.get_current_state_name() if state_machine != null else "N/A"
	
	var facing: String = "RIGHT (+1)" if _player.get("facing_direction") == 1 else "LEFT (-1)"
	var coyote: float = movement.get_coyote_timer() if movement != null else 0.0
	var buffer: float = movement.get_jump_buffer_timer() if movement != null else 0.0
	
	_label.text = """[PLAYER MOVEMENT DEBUG (F3)]
FPS: %.1f
State: %s
Facing: %s
Pos: (%.1f, %.1f)
Vel: (%.1f, %.1f)
Grounded: %s
Coyote: %.3fs | Buffer: %.3fs""" % [
		fps,
		state_name,
		facing,
		pos.x, pos.y,
		vel.x, vel.y,
		str(grounded),
		coyote, buffer
	]
