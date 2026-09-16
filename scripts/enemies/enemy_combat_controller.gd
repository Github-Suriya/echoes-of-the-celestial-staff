class_name EnemyCombatController
extends Node

## EnemyCombatController
## Orchestrates enemy attack lifecycles, phase timings, hitbox activation, and cooldowns.

signal attack_started(attack_data: EnemyAttackData)
signal attack_active_entered()
signal attack_recovered()
signal attack_interrupted_signal()
signal attack_completed()

enum AttackPhase {
	READY,
	TELEGRAPH,
	ACTIVE,
	RECOVERY,
	COOLDOWN,
	INTERRUPTED
}

@export var default_attack_data: EnemyAttackData = null
@export var hitbox: Hitbox = null

var current_phase: AttackPhase = AttackPhase.READY
var active_attack_data: EnemyAttackData = null

var _phase_timer: float = 0.0
var _cooldown_timer: float = 0.0
var _actor: Node2D = null

func _ready() -> void:
	if owner is Node2D:
		_actor = owner as Node2D

func configure(data: EnemyData, hb: Hitbox = null) -> void:
	if hb != null:
		hitbox = hb
	if data != null and data.default_attack != null:
		default_attack_data = data.default_attack

func can_attack() -> bool:
	if current_phase != AttackPhase.READY:
		return false
	if _cooldown_timer > 0.0:
		return false
	if _actor != null:
		if _actor is EnemyController:
			var ec: EnemyController = _actor as EnemyController
			if ec.is_dead or (ec.poise_component != null and ec.poise_component.is_staggered):
				return false
		elif _actor.has_node("Components/PoiseComponent"):
			var pc: PoiseComponent = _actor.get_node("Components/PoiseComponent") as PoiseComponent
			if pc != null and pc.is_staggered:
				return false
	return default_attack_data != null

func is_attacking() -> bool:
	return current_phase == AttackPhase.TELEGRAPH or current_phase == AttackPhase.ACTIVE or current_phase == AttackPhase.RECOVERY

func is_on_cooldown() -> bool:
	return _cooldown_timer > 0.0

func get_cooldown_remaining() -> float:
	return maxf(0.0, _cooldown_timer)

func get_attack_range() -> float:
	if default_attack_data != null:
		return default_attack_data.attack_range
	return 40.0

func trigger_attack(attack_override: EnemyAttackData = null) -> bool:
	if not can_attack() and attack_override == null:
		return false
	
	active_attack_data = attack_override if attack_override != null else default_attack_data
	if active_attack_data == null:
		return false
	
	current_phase = AttackPhase.TELEGRAPH
	_phase_timer = active_attack_data.telegraph_duration
	attack_started.emit(active_attack_data)
	return true

func process_combat(delta: float) -> void:
	# Cooldown countdown
	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta
		if _cooldown_timer <= 0.0 and current_phase == AttackPhase.COOLDOWN:
			current_phase = AttackPhase.READY
	
	match current_phase:
		AttackPhase.TELEGRAPH:
			_phase_timer -= delta
			if _phase_timer <= 0.0:
				_enter_active_phase()
		
		AttackPhase.ACTIVE:
			_phase_timer -= delta
			if _phase_timer <= 0.0:
				_enter_recovery_phase()
		
		AttackPhase.RECOVERY:
			_phase_timer -= delta
			if _phase_timer <= 0.0:
				_enter_cooldown_phase()
		
		AttackPhase.INTERRUPTED:
			_phase_timer -= delta
			if _phase_timer <= 0.0:
				_enter_cooldown_phase()
		
		AttackPhase.READY, AttackPhase.COOLDOWN:
			pass

func _enter_active_phase() -> void:
	current_phase = AttackPhase.ACTIVE
	_phase_timer = active_attack_data.active_time if active_attack_data != null else 0.12
	
	if hitbox != null and active_attack_data != null:
		hitbox.activate(active_attack_data, _actor)
	
	attack_active_entered.emit()

func _enter_recovery_phase() -> void:
	current_phase = AttackPhase.RECOVERY
	_phase_timer = active_attack_data.recovery_time if active_attack_data != null else 0.35
	
	if hitbox != null:
		hitbox.deactivate()
	
	attack_recovered.emit()

func _enter_cooldown_phase() -> void:
	current_phase = AttackPhase.COOLDOWN
	_cooldown_timer = active_attack_data.cooldown if active_attack_data != null else 1.8
	
	if hitbox != null:
		hitbox.deactivate()
	
	attack_completed.emit()

func interrupt_attack() -> void:
	if not is_attacking():
		return
	
	if hitbox != null:
		hitbox.deactivate()
	
	current_phase = AttackPhase.INTERRUPTED
	_phase_timer = 0.60 # Brief recoil stun duration
	_cooldown_timer = 1.0 # Guarantee cooldown on interrupt
	
	attack_interrupted_signal.emit()

func reset_combat() -> void:
	if hitbox != null:
		hitbox.deactivate()
	current_phase = AttackPhase.READY
	_phase_timer = 0.0
	_cooldown_timer = 0.0
	active_attack_data = null
