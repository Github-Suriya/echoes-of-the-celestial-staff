class_name TransformationController
extends Node

## TransformationController
## Orchestrates temporary supernatural transformations (Celestial Awakening).
## Manages activation requirements, atomic Spirit transactions, duration timing,
## and provides transformation-adjusted multipliers to locomotion, combat, defense, and spirit abilities.

signal transformation_started(data: TransformationData)
signal transformation_state_changed(new_state: int)
signal transformation_ended(data: TransformationData)
signal transformation_failed(reason: StringName)

enum LifecycleState {
	INACTIVE,
	ACTIVATING,
	ACTIVE,
	ENDING
}

@export var transformation_data: TransformationData = null

var player: CharacterBody2D = null
var current_state: LifecycleState = LifecycleState.INACTIVE
var _remaining_duration: float = 0.0

func _ready() -> void:
	if owner is CharacterBody2D:
		player = owner as CharacterBody2D
	elif get_parent() is CharacterBody2D:
		player = get_parent() as CharacterBody2D
	elif get_parent() != null and get_parent().get_parent() is CharacterBody2D:
		player = get_parent().get_parent() as CharacterBody2D
	
	_load_default_transformation_data()

func _load_default_transformation_data() -> void:
	if transformation_data == null:
		var default_path: String = "res://data/characters/transformation_celestial_awakening.tres"
		if ResourceLoader.exists(default_path):
			var res: Resource = load(default_path)
			if res is TransformationData:
				transformation_data = res

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	
	if has_node("/root/InputManager"):
		var im: Node = get_node("/root/InputManager")
		if im != null and im.has_method("is_action_just_pressed"):
			if im.is_action_just_pressed(&"transformation_activate"):
				activate()
	else:
		if event.is_action_pressed(&"transformation_activate"):
			activate()

func _physics_process(delta: float) -> void:
	if current_state == LifecycleState.ACTIVE:
		_remaining_duration = maxf(0.0, _remaining_duration - delta)
		if _remaining_duration <= 0.0:
			deactivate()

func can_activate() -> bool:
	if current_state != LifecycleState.INACTIVE:
		return false
	
	if transformation_data == null:
		return false
	
	if player == null:
		return true
	
	# 1. Check Spirit resource sufficiency
	var spirit_comp: SpiritComponent = _get_spirit_component()
	if spirit_comp != null and spirit_comp.current_spirit < transformation_data.spirit_cost:
		return false
	
	# 2. Check CombatController state
	if player.has_node("Components/CombatController"):
		var combat: CombatController = player.get_node("Components/CombatController") as CombatController
		if combat != null:
			if combat.is_charging_heavy:
				return false
			if combat.is_attacking():
				var phase: CombatController.AttackPhase = combat.get_attack_phase()
				if phase == CombatController.AttackPhase.STARTUP or phase == CombatController.AttackPhase.ACTIVE:
					return false
				# Transformation activation is explicitly ALLOWED during recovery
	
	# 3. Check DefenseController state
	if player.has_node("Components/DefenseController"):
		var defense: DefenseController = player.get_node("Components/DefenseController") as DefenseController
		if defense != null:
			if defense.is_dodging and defense.is_invulnerable_to_damage:
				return false
			if defense.is_parrying and defense.is_in_parry_window():
				return false
	
	# 4. Check StateMachine state (e.g. AirAttack active frames)
	if player.has_node("StateMachine"):
		var sm: StateMachine = player.get_node("StateMachine") as StateMachine
		if sm != null and sm.current_state is PlayerAirAttackState:
			if player.has_node("Components/CombatController"):
				var combat: CombatController = player.get_node("Components/CombatController") as CombatController
				if combat != null:
					var phase: CombatController.AttackPhase = combat.get_attack_phase()
					if phase == CombatController.AttackPhase.STARTUP or phase == CombatController.AttackPhase.ACTIVE:
						return false
	
	# 5. Check SpiritAbilityController state
	if player.has_node("Components/SpiritAbilityController"):
		var ability_ctrl: SpiritAbilityController = player.get_node("Components/SpiritAbilityController") as SpiritAbilityController
		if ability_ctrl != null and ability_ctrl.is_casting:
			return false
	
	return true

func activate() -> bool:
	if not can_activate():
		transformation_failed.emit(&"activation_blocked_or_insufficient_resource")
		return false
	
	# Consume Spirit atomically
	var spirit_comp: SpiritComponent = _get_spirit_component()
	if spirit_comp != null:
		var consumed: bool = spirit_comp.consume_spirit(transformation_data.spirit_cost)
		if not consumed:
			transformation_failed.emit(&"insufficient_spirit")
			return false
	
	# ACTIVATING phase
	current_state = LifecycleState.ACTIVATING
	transformation_state_changed.emit(current_state)
	if has_node("/root/EventBus"):
		var bus: Node = get_node("/root/EventBus")
		if bus != null and bus.has_signal("transformation_state_changed"):
			bus.transformation_state_changed.emit(current_state)
	
	_notify_animation_activate()
	_play_audio_activate()
	
	# ACTIVE phase
	current_state = LifecycleState.ACTIVE
	_remaining_duration = transformation_data.duration
	
	transformation_state_changed.emit(current_state)
	transformation_started.emit(transformation_data)
	
	if has_node("/root/EventBus"):
		var bus: Node = get_node("/root/EventBus")
		if bus != null:
			if bus.has_signal("transformation_started"):
				bus.transformation_started.emit(transformation_data.transformation_id, transformation_data.duration)
			if bus.has_signal("transformation_state_changed"):
				bus.transformation_state_changed.emit(current_state)
	
	return true

func deactivate() -> void:
	if current_state == LifecycleState.INACTIVE:
		return
	
	current_state = LifecycleState.ENDING
	transformation_state_changed.emit(current_state)
	if has_node("/root/EventBus"):
		var bus: Node = get_node("/root/EventBus")
		if bus != null and bus.has_signal("transformation_state_changed"):
			bus.transformation_state_changed.emit(current_state)
	
	_notify_animation_end()
	_play_audio_end()
	
	current_state = LifecycleState.INACTIVE
	_remaining_duration = 0.0
	
	transformation_state_changed.emit(current_state)
	transformation_ended.emit(transformation_data)
	
	if has_node("/root/EventBus"):
		var bus: Node = get_node("/root/EventBus")
		if bus != null:
			if bus.has_signal("transformation_ended"):
				bus.transformation_ended.emit(transformation_data.transformation_id)
			if bus.has_signal("transformation_state_changed"):
				bus.transformation_state_changed.emit(current_state)

func is_active() -> bool:
	return current_state == LifecycleState.ACTIVE or current_state == LifecycleState.ACTIVATING

func get_remaining_duration() -> float:
	return _remaining_duration

func get_duration_ratio() -> float:
	if transformation_data == null or transformation_data.duration <= 0.0:
		return 0.0
	return clampf(_remaining_duration / transformation_data.duration, 0.0, 1.0)

func get_lifecycle_state() -> LifecycleState:
	return current_state

func get_lifecycle_state_name() -> String:
	match current_state:
		LifecycleState.INACTIVE:
			return "INACTIVE"
		LifecycleState.ACTIVATING:
			return "ACTIVATING"
		LifecycleState.ACTIVE:
			return "ACTIVE"
		LifecycleState.ENDING:
			return "ENDING"
		_:
			return "UNKNOWN"

func get_data() -> TransformationData:
	return transformation_data

# --- Multiplier Accessors (Return 1.0 when not active) ---

func get_movement_speed_multiplier() -> float:
	return transformation_data.move_speed_multiplier if (is_active() and transformation_data != null) else 1.0

func get_acceleration_multiplier() -> float:
	return transformation_data.acceleration_multiplier if (is_active() and transformation_data != null) else 1.0

func get_deceleration_multiplier() -> float:
	return transformation_data.deceleration_multiplier if (is_active() and transformation_data != null) else 1.0

func get_attack_speed_multiplier() -> float:
	return transformation_data.attack_speed_multiplier if (is_active() and transformation_data != null) else 1.0

func get_damage_multiplier() -> float:
	return transformation_data.damage_multiplier if (is_active() and transformation_data != null) else 1.0

func get_poise_damage_multiplier() -> float:
	return transformation_data.poise_damage_multiplier if (is_active() and transformation_data != null) else 1.0

func get_dodge_velocity_multiplier() -> float:
	return transformation_data.dodge_velocity_multiplier if (is_active() and transformation_data != null) else 1.0

func get_dodge_recovery_multiplier() -> float:
	return transformation_data.dodge_recovery_multiplier if (is_active() and transformation_data != null) else 1.0

func get_hitstop_multiplier() -> float:
	return transformation_data.hitstop_multiplier if (is_active() and transformation_data != null) else 1.0

func get_spirit_ability_damage_multiplier() -> float:
	return transformation_data.spirit_ability_damage_multiplier if (is_active() and transformation_data != null) else 1.0

# --- Helper Methods ---

func _get_spirit_component() -> SpiritComponent:
	if player != null and player.has_node("Components/SpiritComponent"):
		return player.get_node("Components/SpiritComponent") as SpiritComponent
	return null

func _notify_animation_activate() -> void:
	if player != null and player.has_node("Components/PlayerAnimationController"):
		var anim: Node = player.get_node("Components/PlayerAnimationController")
		if anim != null and anim.has_method("play_transformation_activate"):
			anim.play_transformation_activate()

func _notify_animation_end() -> void:
	if player != null and player.has_node("Components/PlayerAnimationController"):
		var anim: Node = player.get_node("Components/PlayerAnimationController")
		if anim != null and anim.has_method("play_transformation_end"):
			anim.play_transformation_end()

func _play_audio_activate() -> void:
	# Safe audio hook: Plays activation SFX if configured
	pass

func _play_audio_end() -> void:
	# Safe audio hook: Plays deactivation SFX if configured
	pass
