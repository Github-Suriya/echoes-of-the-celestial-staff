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
	
	var defense: DefenseController = null
	if _player.has_node("Components/DefenseController"):
		defense = _player.get_node("Components/DefenseController") as DefenseController
	
	var stance: StanceController = null
	if _player.has_node("Components/StanceController"):
		stance = _player.get_node("Components/StanceController") as StanceController
	
	var spirit_comp: SpiritComponent = null
	if _player.has_node("Components/SpiritComponent"):
		spirit_comp = _player.get_node("Components/SpiritComponent") as SpiritComponent
	
	var ability_ctrl: SpiritAbilityController = null
	if _player.has_node("Components/SpiritAbilityController"):
		ability_ctrl = _player.get_node("Components/SpiritAbilityController") as SpiritAbilityController
	
	var trans_ctrl: TransformationController = null
	if _player.has_node("Components/TransformationController"):
		trans_ctrl = _player.get_node("Components/TransformationController") as TransformationController
	
	var fps: float = Performance.get_monitor(Performance.TIME_FPS)
	var pos: Vector2 = _player.global_position
	var vel: Vector2 = _player.velocity
	var grounded: bool = _player.is_on_floor()
	var state_name: String = state_machine.get_current_state_name() if state_machine != null else "N/A"
	
	var facing: String = "RIGHT (+1)" if _player.get("facing_direction") == 1 else "LEFT (-1)"
	var coyote: float = movement.get_coyote_timer() if movement != null and movement.has_method("get_coyote_timer") else 0.0
	
	# Stance metrics
	var stance_info: String = "NONE"
	var stance_mults: String = "Spd: 1.0x | Atk: 1.0x | Dmg: 1.0x | Pse: 1.0x"
	if stance != null and stance.current_stance_data != null:
		stance_info = stance.current_stance_data.display_name.to_upper()
		stance_mults = "Spd: %.2fx | Atk: %.2fx | Dmg: %.2fx | Pse: %.2fx | Ddg: %.2fx" % [
			stance.get_movement_speed_multiplier(),
			stance.get_attack_speed_multiplier(),
			stance.get_damage_multiplier(),
			stance.get_poise_damage_multiplier(),
			stance.get_dodge_distance_multiplier()
		]
	
	# Spirit metrics
	var spirit_str: String = "N/A"
	if spirit_comp != null:
		spirit_str = "%.0f / %.0f (%.0f%%)" % [spirit_comp.get_spirit(), spirit_comp.get_max_spirit(), spirit_comp.get_spirit_ratio() * 100.0]
	
	# Ability metrics
	var ability_str: String = "IDLE"
	var cd_str: String = "[1] Arc: READY | [2] Pulse: READY | [3] Step: READY"
	if ability_ctrl != null:
		if ability_ctrl.is_casting and ability_ctrl.current_ability != null:
			ability_str = "%s (%s, %.3fs)" % [ability_ctrl.current_ability.display_name, ability_ctrl.get_phase_name(), ability_ctrl.phase_timer]
		var cd1: String = "READY" if ability_ctrl.is_ability_ready(&"celestial_arc") else "%.1fs" % ability_ctrl.get_cooldown_remaining(&"celestial_arc")
		var cd2: String = "READY" if ability_ctrl.is_ability_ready(&"heavenly_pulse") else "%.1fs" % ability_ctrl.get_cooldown_remaining(&"heavenly_pulse")
		var cd3: String = "READY" if ability_ctrl.is_ability_ready(&"cloud_step") else "%.1fs" % ability_ctrl.get_cooldown_remaining(&"cloud_step")
		cd_str = "[1] Arc: %s | [2] Pulse: %s | [3] Step: %s" % [cd1, cd2, cd3]
	
	# Combat metrics
	var attack_id: String = "NONE"
	var attack_phase: String = "NONE"
	var phase_timer_val: float = 0.0
	var combo_idx: int = 0
	var hitbox_active: bool = false
	var in_hitstop: bool = false
	var charge_info: String = "OFF"
	
	if combat != null:
		if combat.get_current_attack() != null:
			attack_id = combat.get_current_attack().attack_id
		attack_phase = combat.get_attack_phase_name()
		phase_timer_val = combat.phase_timer
		combo_idx = combat.get_combo_index()
		if combat.hitbox != null:
			hitbox_active = combat.hitbox.is_active
		if combat.is_charging_heavy:
			charge_info = "CHARGING (%.0f%%, dmg x%.2f)" % [combat.get_charge_ratio() * 100.0, combat.charge_multiplier]
	
	# Defense metrics
	var dodge_info: String = "IDLE"
	var parry_info: String = "IDLE"
	if defense != null:
		if defense.is_dodging:
			var iframes: String = "IFRAME" if defense.is_invulnerable_to_damage else "VULN"
			var perf: String = " [PERFECT]" if defense.is_in_perfect_dodge_window() else ""
			dodge_info = "%s%s (t=%.2fs)" % [iframes, perf, defense.dodge_timer]
		if defense.is_parrying:
			var p_window: String = "ACTIVE" if defense.is_in_parry_window() else "RECOVERY"
			var p_perf: String = " [PERFECT]" if defense.is_in_perfect_parry_window() else ""
			parry_info = "%s%s (t=%.2fs)" % [p_window, p_perf, defense.parry_timer]
	
	# Transformation metrics
	var trans_str: String = "INACTIVE"
	var trans_mults: String = "Spd: 1.0x | Atk: 1.0x | Dmg: 1.0x | Abi: 1.0x"
	if trans_ctrl != null:
		trans_str = "%s (%.1fs, %.0f%%)" % [
			trans_ctrl.get_lifecycle_state_name(),
			trans_ctrl.get_remaining_duration(),
			trans_ctrl.get_duration_ratio() * 100.0
		]
		if trans_ctrl.is_active():
			trans_mults = "Spd: %.2fx | Atk: %.2fx | Dmg: %.2fx | Pse: %.2fx | Abi: %.2fx" % [
				trans_ctrl.get_movement_speed_multiplier(),
				trans_ctrl.get_attack_speed_multiplier(),
				trans_ctrl.get_damage_multiplier(),
				trans_ctrl.get_poise_damage_multiplier(),
				trans_ctrl.get_spirit_ability_damage_multiplier()
			]
	
	if has_node("/root/GameManager"):
		var gm: Node = get_node("/root/GameManager")
		if gm != null and gm.has_method("is_in_hitstop"):
			in_hitstop = gm.is_in_hitstop()
	
	_label.text = """[COMBAT, STANCE & AWAKENING DEBUG (F3)]
FPS: %.1f | Hitstop: %s
State: %s | Facing: %s
Stance: %s
%s
Awakening: %s
%s
Spirit: %s
Ability: %s
CD: %s
Attack: %s (Phase: %s, %.3fs) | Charge: %s
Combo Index: %d | Hitbox: %s
Dodge: %s | Parry: %s
Pos: (%.1f, %.1f) | Vel: (%.1f, %.1f)
Grounded: %s | Coyote: %.3fs""" % [
		fps, str(in_hitstop),
		state_name, facing,
		stance_info,
		stance_mults,
		trans_str,
		trans_mults,
		spirit_str,
		ability_str,
		cd_str,
		attack_id, attack_phase, phase_timer_val, charge_info,
		combo_idx, "ACTIVE" if hitbox_active else "OFF",
		dodge_info, parry_info,
		pos.x, pos.y, vel.x, vel.y,
		str(grounded), coyote
	]
