class_name DefenseController
extends Node

## DefenseController
## Orchestrates defensive actions (ground dodge, invulnerability frames, perfect dodge,
## parry, and perfect parry) and intercepts incoming combat hits before damage resolution.

signal dodge_started(direction: int)
signal dodge_completed()
signal perfect_dodge(attacker: Node2D)
signal parry_started()
signal parry_success(attacker: Node2D)
signal perfect_parry(attacker: Node2D)

enum DefenseResult {
	NONE,
	DODGE_NORMAL,
	DODGE_PERFECT,
	PARRY_NORMAL,
	PARRY_PERFECT
}

# --- Dodge Configuration ---
@export var dodge_duration: float = 0.35
@export var dodge_speed: float = 380.0
@export var dodge_iframe_start: float = 0.033
@export var dodge_iframe_end: float = 0.200
@export var perfect_dodge_window_start: float = 0.033
@export var perfect_dodge_window_end: float = 0.100

# --- Parry Configuration ---
@export var parry_startup: float = 0.033
@export var parry_window_duration: float = 0.220
@export var perfect_parry_window_duration: float = 0.083
@export var parry_recovery: float = 0.180
@export var perfect_parry_poise_damage: float = 25.0

var player: CharacterBody2D = null

# Runtime Dodge State
var is_dodging: bool = false
var dodge_timer: float = 0.0
var dodge_direction: int = 1
var is_invulnerable_to_damage: bool = false

# Runtime Parry State
var is_parrying: bool = false
var parry_timer: float = 0.0

func _ready() -> void:
	if owner is CharacterBody2D:
		player = owner as CharacterBody2D
	elif get_parent() is CharacterBody2D:
		player = get_parent() as CharacterBody2D
	elif get_parent() != null and get_parent().get_parent() is CharacterBody2D:
		player = get_parent().get_parent() as CharacterBody2D

func start_dodge(move_axis: float, facing: int) -> void:
	is_dodging = true
	dodge_timer = dodge_duration
	is_invulnerable_to_damage = false
	
	# Determine dodge direction
	if move_axis > 0.05:
		dodge_direction = 1
	elif move_axis < -0.05:
		dodge_direction = -1
	else:
		dodge_direction = 1 if facing >= 0 else -1
	
	# Set initial dodge velocity
	var dist_mult: float = 1.0
	var stance: StanceController = _get_stance_controller()
	if stance != null:
		dist_mult *= stance.get_dodge_distance_multiplier()
	var trans: TransformationController = _get_transformation_controller()
	if trans != null:
		dist_mult *= trans.get_dodge_velocity_multiplier()
	
	if player != null:
		player.velocity.x = float(dodge_direction) * dodge_speed * dist_mult
	
	# Visual / Animation hook
	_notify_animation_dodge()
	
	dodge_started.emit(dodge_direction)
	if has_node("/root/EventBus"):
		var bus: Node = get_node("/root/EventBus")
		if bus != null and bus.has_signal("dodge_started"):
			bus.dodge_started.emit(player, dodge_direction)

func process_dodge(delta: float) -> bool:
	if not is_dodging:
		return false
	
	dodge_timer -= delta
	var elapsed: float = dodge_duration - dodge_timer
	
	# Update combat invulnerability state
	is_invulnerable_to_damage = (elapsed >= dodge_iframe_start and elapsed <= dodge_iframe_end)
	
	# Apply dodge velocity curve with smooth deceleration, stance, and transformation multipliers
	var dist_mult: float = 1.0
	var recovery_mult: float = 1.0
	var stance: StanceController = _get_stance_controller()
	if stance != null:
		dist_mult *= stance.get_dodge_distance_multiplier()
		recovery_mult *= stance.get_dodge_recovery_multiplier()
	var trans: TransformationController = _get_transformation_controller()
	if trans != null:
		dist_mult *= trans.get_dodge_velocity_multiplier()
		recovery_mult *= trans.get_dodge_recovery_multiplier()
	
	if player != null:
		var speed_factor: float = clampf(dodge_timer / dodge_duration, 0.2, 1.0)
		player.velocity.x = float(dodge_direction) * dodge_speed * dist_mult * speed_factor
		player.move_and_slide()
	
	var effective_duration: float = dodge_iframe_end + (dodge_duration - dodge_iframe_end) * recovery_mult
	if elapsed >= effective_duration or dodge_timer <= 0.0:
		finish_dodge()
		return false
	
	return true

func finish_dodge() -> void:
	is_dodging = false
	dodge_timer = 0.0
	is_invulnerable_to_damage = false
	
	dodge_completed.emit()
	if has_node("/root/EventBus"):
		var bus: Node = get_node("/root/EventBus")
		if bus != null and bus.has_signal("dodge_completed"):
			bus.dodge_completed.emit(player)

func start_parry() -> void:
	is_parrying = true
	parry_timer = 0.0
	
	# Halt horizontal motion during parry guard
	if player != null:
		player.velocity.x = 0.0
	
	_notify_animation_parry()
	
	parry_started.emit()
	if has_node("/root/EventBus"):
		var bus: Node = get_node("/root/EventBus")
		if bus != null and bus.has_signal("parry_started"):
			bus.parry_started.emit(player)

func process_parry(delta: float) -> bool:
	if not is_parrying:
		return false
	
	parry_timer += delta
	
	if player != null:
		player.velocity.x = move_toward(player.velocity.x, 0.0, 800.0 * delta)
		player.move_and_slide()
	
	var total_parry_duration: float = parry_startup + parry_window_duration + parry_recovery
	if parry_timer >= total_parry_duration:
		finish_parry()
		return false
	
	return true

func finish_parry() -> void:
	is_parrying = false
	parry_timer = 0.0

func cancel_defense() -> void:
	if is_dodging:
		finish_dodge()
	if is_parrying:
		finish_parry()

func is_in_perfect_dodge_window() -> bool:
	if not is_dodging:
		return false
	var elapsed: float = dodge_duration - dodge_timer
	return elapsed >= perfect_dodge_window_start and elapsed <= perfect_dodge_window_end

func is_in_parry_window() -> bool:
	if not is_parrying:
		return false
	return parry_timer >= parry_startup and parry_timer < (parry_startup + parry_window_duration)

func is_in_perfect_parry_window() -> bool:
	if not is_in_parry_window():
		return false
	return (parry_timer - parry_startup) <= perfect_parry_window_duration

func try_intercept_hit(damage_info: DamageInfo) -> int:
	# 1. Evaluate Parry Interception
	if is_in_parry_window():
		if damage_info != null and not damage_info.is_parryable:
			return DefenseResult.NONE
		
		var attacker_node: Node2D = damage_info.attacker if damage_info != null else null
		
		if is_in_perfect_parry_window():
			_execute_perfect_parry(damage_info)
			return DefenseResult.PARRY_PERFECT
		else:
			_execute_normal_parry(damage_info)
			return DefenseResult.PARRY_NORMAL
	
	# 2. Evaluate Dodge Interception
	if is_dodging and is_invulnerable_to_damage:
		if damage_info != null and not damage_info.is_dodgeable:
			return DefenseResult.NONE
		
		if is_in_perfect_dodge_window():
			_execute_perfect_dodge(damage_info)
			return DefenseResult.DODGE_PERFECT
		else:
			return DefenseResult.DODGE_NORMAL
	
	return DefenseResult.NONE

func _execute_perfect_parry(damage_info: DamageInfo) -> void:
	var attacker_node: Node2D = damage_info.attacker if damage_info != null else null
	
	# Apply strong hitstop (120ms)
	if has_node("/root/GameManager"):
		var gm: Node = get_node("/root/GameManager")
		if gm != null and gm.has_method("apply_hitstop"):
			gm.apply_hitstop(0.12, 0.02)
	
	# Inflict posture / poise break on attacker
	if attacker_node != null and attacker_node.has_node("Components/PoiseComponent"):
		var enemy_poise: Node = attacker_node.get_node("Components/PoiseComponent")
		if enemy_poise != null and enemy_poise.has_method("take_poise_damage"):
			var poise_mult: float = 1.0
			var stance: StanceController = _get_stance_controller()
			if stance != null:
				poise_mult = stance.get_poise_damage_multiplier()
			enemy_poise.take_poise_damage(perfect_parry_poise_damage * poise_mult)
	
	# Notify attacker to interrupt attack swing
	if attacker_node != null and attacker_node.has_method("interrupt_attack"):
		attacker_node.interrupt_attack()
	
	if has_node("/root/EventBus"):
		var bus: Node = get_node("/root/EventBus")
		if bus != null:
			if bus.has_signal("perfect_parry"):
				bus.perfect_parry.emit(player, attacker_node)
			if bus.has_signal("attack_interrupted"):
				bus.attack_interrupted.emit(attacker_node, &"perfect_parry")
	
	_notify_animation_perfect_parry()
	perfect_parry.emit(attacker_node)

func _execute_normal_parry(damage_info: DamageInfo) -> void:
	var attacker_node: Node2D = damage_info.attacker if damage_info != null else null
	
	# Apply light hitstop (60ms)
	if has_node("/root/GameManager"):
		var gm: Node = get_node("/root/GameManager")
		if gm != null and gm.has_method("apply_hitstop"):
			gm.apply_hitstop(0.06, 0.05)
	
	# Interrupt incoming attack if interruptible
	if damage_info != null and damage_info.attack_data != null and damage_info.attack_data.is_interruptible:
		if attacker_node != null and attacker_node.has_method("interrupt_attack"):
			attacker_node.interrupt_attack()
	
	if has_node("/root/EventBus"):
		var bus: Node = get_node("/root/EventBus")
		if bus != null and bus.has_signal("parry_success"):
			bus.parry_success.emit(player, attacker_node)
	
	parry_success.emit(attacker_node)

func _execute_perfect_dodge(damage_info: DamageInfo) -> void:
	var attacker_node: Node2D = damage_info.attacker if damage_info != null else null
	
	# Apply distinct hitstop (80ms)
	if has_node("/root/GameManager"):
		var gm: Node = get_node("/root/GameManager")
		if gm != null and gm.has_method("apply_hitstop"):
			gm.apply_hitstop(0.08, 0.04)
	
	_notify_animation_perfect_dodge()
	
	if has_node("/root/EventBus"):
		var bus: Node = get_node("/root/EventBus")
		if bus != null and bus.has_signal("perfect_dodge"):
			bus.perfect_dodge.emit(player, attacker_node)
	
	perfect_dodge.emit(attacker_node)

func _notify_animation_dodge() -> void:
	if player != null and player.has_node("Components/PlayerAnimationController"):
		var anim: Node = player.get_node("Components/PlayerAnimationController")
		if anim != null and anim.has_method("play_dodge_animation"):
			anim.play_dodge_animation()

func _notify_animation_perfect_dodge() -> void:
	if player != null and player.has_node("Components/PlayerAnimationController"):
		var anim: Node = player.get_node("Components/PlayerAnimationController")
		if anim != null and anim.has_method("play_perfect_dodge_feedback"):
			anim.play_perfect_dodge_feedback()

func _notify_animation_parry() -> void:
	if player != null and player.has_node("Components/PlayerAnimationController"):
		var anim: Node = player.get_node("Components/PlayerAnimationController")
		if anim != null and anim.has_method("play_parry_animation"):
			anim.play_parry_animation()

func _notify_animation_perfect_parry() -> void:
	if player != null and player.has_node("Components/PlayerAnimationController"):
		var anim: Node = player.get_node("Components/PlayerAnimationController")
		if anim != null and anim.has_method("play_perfect_parry_feedback"):
			anim.play_perfect_parry_feedback()

func _get_stance_controller() -> StanceController:
	if player != null and player.has_node("Components/StanceController"):
		return player.get_node("Components/StanceController") as StanceController
	return null

func _get_transformation_controller() -> TransformationController:
	if player != null and player.has_node("Components/TransformationController"):
		return player.get_node("Components/TransformationController") as TransformationController
	return null
