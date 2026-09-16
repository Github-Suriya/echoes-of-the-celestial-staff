class_name StanceController
extends Node

## StanceController
## Manages active martial stance (Swift, Mountain, Storm), transition validation rules,
## and provides stance-adjusted multipliers to locomotion, combat, and defense systems.

signal stance_changed(new_stance: int, old_stance: int)

var current_stance: int = StanceData.StanceType.SWIFT
var current_stance_data: StanceData = null

var player: CharacterBody2D = null
var _stances: Dictionary = {} # Dictionary[int, StanceData]

func _ready() -> void:
	if owner is CharacterBody2D:
		player = owner as CharacterBody2D
	elif get_parent() is CharacterBody2D:
		player = get_parent() as CharacterBody2D
	elif get_parent() != null and get_parent().get_parent() is CharacterBody2D:
		player = get_parent().get_parent() as CharacterBody2D
	
	_load_stance_resources()
	
	# Default to Swift stance if loaded
	if _stances.has(StanceData.StanceType.SWIFT):
		current_stance_data = _stances[StanceData.StanceType.SWIFT]
		current_stance = StanceData.StanceType.SWIFT

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	
	# Check stance switch input action
	if has_node("/root/InputManager"):
		var im: Node = get_node("/root/InputManager")
		if im != null and im.has_method("is_action_just_pressed"):
			if im.is_action_just_pressed(&"stance_switch"):
				cycle_stance()
	else:
		if event.is_action_pressed(&"stance_switch"):
			cycle_stance()

func _load_stance_resources() -> void:
	var paths: Dictionary = {
		StanceData.StanceType.SWIFT: "res://data/characters/stance_swift.tres",
		StanceData.StanceType.MOUNTAIN: "res://data/characters/stance_mountain.tres",
		StanceData.StanceType.STORM: "res://data/characters/stance_storm.tres"
	}
	
	for type_key in paths:
		var path: String = paths[type_key]
		if ResourceLoader.exists(path):
			var res: Resource = load(path)
			if res is StanceData:
				_stances[type_key] = res

func get_current_stance() -> int:
	return current_stance

func get_current_stance_data() -> StanceData:
	return current_stance_data

func can_change_stance() -> bool:
	if player == null:
		return true
	
	# 1. Check CombatController state
	if player.has_node("Components/CombatController"):
		var combat: CombatController = player.get_node("Components/CombatController") as CombatController
		if combat != null and combat.is_attacking():
			# Disallowed during startup, active hit, and hold-to-charge
			if combat.is_charging_heavy:
				return false
			var phase: CombatController.AttackPhase = combat.get_attack_phase()
			if phase == CombatController.AttackPhase.STARTUP or phase == CombatController.AttackPhase.ACTIVE:
				return false
			# Stance change is explicitly ALLOWED during recovery
	
	# 2. Check DefenseController state
	if player.has_node("Components/DefenseController"):
		var defense: DefenseController = player.get_node("Components/DefenseController") as DefenseController
		if defense != null:
			# Disallowed during active dodge invulnerability
			if defense.is_dodging and defense.is_invulnerable_to_damage:
				return false
			# Disallowed during active parry deflection window
			if defense.is_parrying and defense.is_in_parry_window():
				return false
	
	# 3. Check StateMachine state (e.g. AirAttack active frames)
	if player.has_node("StateMachine"):
		var sm: StateMachine = player.get_node("StateMachine") as StateMachine
		if sm != null and sm.current_state is PlayerAirAttackState:
			if player.has_node("Components/CombatController"):
				var combat: CombatController = player.get_node("Components/CombatController") as CombatController
				if combat != null:
					var phase: CombatController.AttackPhase = combat.get_attack_phase()
					if phase == CombatController.AttackPhase.STARTUP or phase == CombatController.AttackPhase.ACTIVE:
						return false
	
	# 4. Check SpiritAbilityController state (blocked during startup and active)
	if player.has_node("Components/SpiritAbilityController"):
		var ability_ctrl: SpiritAbilityController = player.get_node("Components/SpiritAbilityController") as SpiritAbilityController
		if ability_ctrl != null and ability_ctrl.is_casting:
			if ability_ctrl.current_phase == SpiritAbilityController.AbilityPhase.STARTUP or ability_ctrl.current_phase == SpiritAbilityController.AbilityPhase.ACTIVE:
				return false
	
	return true

func set_stance(new_stance: int) -> bool:
	if new_stance == current_stance:
		return true
	
	if not can_change_stance():
		return false
	
	if not _stances.has(new_stance):
		return false
	
	var old_stance: int = current_stance
	current_stance = new_stance
	current_stance_data = _stances[new_stance]
	
	_notify_animation_stance_changed(new_stance)
	
	stance_changed.emit(new_stance, old_stance)
	
	if has_node("/root/EventBus"):
		var bus: Node = get_node("/root/EventBus")
		if bus != null and bus.has_signal("player_stance_changed"):
			bus.player_stance_changed.emit(current_stance_data.stance_id)
	
	return true

func cycle_stance() -> bool:
	var next_stance: int = StanceData.StanceType.SWIFT
	match current_stance:
		StanceData.StanceType.SWIFT:
			next_stance = StanceData.StanceType.MOUNTAIN
		StanceData.StanceType.MOUNTAIN:
			next_stance = StanceData.StanceType.STORM
		StanceData.StanceType.STORM:
			next_stance = StanceData.StanceType.SWIFT
	
	return set_stance(next_stance)

# --- Multiplier Accessors ---

func get_movement_speed_multiplier() -> float:
	return current_stance_data.movement_speed_multiplier if current_stance_data != null else 1.0

func get_acceleration_multiplier() -> float:
	return current_stance_data.acceleration_multiplier if current_stance_data != null else 1.0

func get_deceleration_multiplier() -> float:
	return current_stance_data.deceleration_multiplier if current_stance_data != null else 1.0

func get_attack_speed_multiplier() -> float:
	return current_stance_data.attack_speed_multiplier if current_stance_data != null else 1.0

func get_damage_multiplier() -> float:
	return current_stance_data.damage_multiplier if current_stance_data != null else 1.0

func get_poise_damage_multiplier() -> float:
	return current_stance_data.poise_damage_multiplier if current_stance_data != null else 1.0

func get_dodge_distance_multiplier() -> float:
	return current_stance_data.dodge_distance_multiplier if current_stance_data != null else 1.0

func get_dodge_recovery_multiplier() -> float:
	return current_stance_data.dodge_recovery_multiplier if current_stance_data != null else 1.0

func get_parry_window_multiplier() -> float:
	return current_stance_data.parry_window_multiplier if current_stance_data != null else 1.0

func get_hitstop_multiplier() -> float:
	return current_stance_data.hitstop_multiplier if current_stance_data != null else 1.0

func _notify_animation_stance_changed(stance: int) -> void:
	if player != null and player.has_node("Components/PlayerAnimationController"):
		var anim: Node = player.get_node("Components/PlayerAnimationController")
		if anim != null and anim.has_method("play_stance_change_feedback"):
			anim.play_stance_change_feedback(stance)
