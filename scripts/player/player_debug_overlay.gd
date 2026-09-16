class_name PlayerDebugOverlay
extends CanvasLayer

## PlayerDebugOverlay
## Real-time movement and combat diagnostics overlay.
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
	
	var combat: CombatController = null
	if _player.has_node("Components/CombatController"):
		combat = _player.get_node("Components/CombatController") as CombatController
	
	var state_machine: Node = null
	if _player.has_node("StateMachine"):
		state_machine = _player.get_node("StateMachine")
	
	var fps: float = Performance.get_monitor(Performance.TIME_FPS)
	var pos: Vector2 = _player.global_position
	var vel: Vector2 = _player.velocity
	var grounded: bool = _player.is_on_floor()
	var state_name: String = state_machine.get_current_state_name() if state_machine != null else "N/A"
	
	var facing: String = "RIGHT (+1)" if _player.get("facing_direction") == 1 else "LEFT (-1)"
	var coyote: float = movement.get_coyote_timer() if movement != null and movement.has_method("get_coyote_timer") else 0.0
	var buffer: float = movement.get_jump_buffer_timer() if movement != null and movement.has_method("get_jump_buffer_timer") else 0.0
	
	# Combat metrics
	var attack_id: String = "NONE"
	var attack_phase: String = "NONE"
	var phase_timer_val: float = 0.0
	var combo_idx: int = 0
	var hitbox_active: bool = false
	var in_hitstop: bool = false
	
	if combat != null:
		if combat.get_current_attack() != null:
			attack_id = combat.get_current_attack().attack_id
		attack_phase = combat.get_attack_phase_name()
		phase_timer_val = combat.phase_timer
		combo_idx = combat.get_combo_index()
		if combat.hitbox != null:
			hitbox_active = combat.hitbox.is_active
	
	if has_node("/root/GameManager"):
		var gm: Node = get_node("/root/GameManager")
		if gm != null and gm.has_method("is_in_hitstop"):
			in_hitstop = gm.is_in_hitstop()
	
	_label.text = """[COMBAT & MOVEMENT DEBUG (F3)]
FPS: %.1f | Hitstop: %s
State: %s | Facing: %s
Attack: %s (Phase: %s, %.3fs)
Combo Index: %d | Hitbox: %s
Pos: (%.1f, %.1f) | Vel: (%.1f, %.1f)
Grounded: %s | Coyote: %.3fs""" % [
		fps, str(in_hitstop),
		state_name, facing,
		attack_id, attack_phase, phase_timer_val,
		combo_idx, "ACTIVE" if hitbox_active else "OFF",
		pos.x, pos.y, vel.x, vel.y,
		str(grounded), coyote
	]
