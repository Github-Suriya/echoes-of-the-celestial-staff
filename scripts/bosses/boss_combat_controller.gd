class_name BossCombatController
extends Node

## BossCombatController
## Orchestrates boss attack selection, execution lifecycles, phase multipliers, and defensive interrupts.

signal attack_started(attack_data: EnemyAttackData)
signal attack_active_entered(attack_data: EnemyAttackData)
signal attack_recovered(attack_data: EnemyAttackData)
signal attack_interrupted_signal(attack_data: EnemyAttackData)
signal attack_completed()

enum AttackPhase {
	READY,
	TELEGRAPH,
	ACTIVE,
	RECOVERY,
	COOLDOWN,
	INTERRUPTED
}

@export var hitbox: Hitbox = null

var current_phase: AttackPhase = AttackPhase.READY
var active_attack_data: EnemyAttackData = null

var available_attacks: Array[EnemyAttackData] = []
var available_weights: Array[float] = []

var damage_multiplier: float = 1.0
var poise_damage_multiplier: float = 1.0
var attack_speed_multiplier: float = 1.0
var movement_speed_multiplier: float = 1.0

var last_attack_id: StringName = &""

var _phase_timer: float = 0.0
var _global_cooldown_timer: float = 0.0
var _attack_cooldowns: Dictionary = {} # StringName -> float

var _actor: Node2D = null

func _ready() -> void:
	if owner is Node2D:
		_actor = owner as Node2D

func set_phase_data(phase_data: BossPhaseData) -> void:
	if phase_data == null:
		return
	
	available_attacks.clear()
	available_weights.clear()
	
	for atk in phase_data.attacks:
		if atk != null:
			available_attacks.append(atk)
	
	for w in phase_data.attack_weights:
		available_weights.append(w)
	
	# Fallback weights if missing
	while available_weights.size() < available_attacks.size():
		available_weights.append(1.0)
	
	damage_multiplier = phase_data.damage_multiplier
	poise_damage_multiplier = phase_data.poise_damage_multiplier
	attack_speed_multiplier = phase_data.attack_speed_multiplier
	movement_speed_multiplier = phase_data.movement_speed_multiplier

func can_attack() -> bool:
	if current_phase != AttackPhase.READY:
		return false
	if _global_cooldown_timer > 0.0:
		return false
	if available_attacks.is_empty():
		return false
	
	if _actor != null:
		if _actor.has_method("is_dead_or_defeated") and _actor.is_dead_or_defeated():
			return false
		if _actor.has_method("is_in_phase_transition") and _actor.is_in_phase_transition():
			return false
		if _actor.has_node("Components/PoiseComponent"):
			var pc: PoiseComponent = _actor.get_node("Components/PoiseComponent") as PoiseComponent
			if pc != null and pc.is_staggered:
				return false
	
	# Check if at least one attack is off cooldown
	for atk in available_attacks:
		if get_attack_cooldown(atk.attack_id) <= 0.0:
			return true
	
	return false

func is_attacking() -> bool:
	return current_phase == AttackPhase.TELEGRAPH or current_phase == AttackPhase.ACTIVE or current_phase == AttackPhase.RECOVERY

func is_on_cooldown() -> bool:
	return _global_cooldown_timer > 0.0

func get_global_cooldown() -> float:
	return maxf(0.0, _global_cooldown_timer)

func get_attack_cooldown(attack_id: StringName) -> float:
	if _attack_cooldowns.has(attack_id):
		return maxf(0.0, float(_attack_cooldowns[attack_id]))
	return 0.0

func get_preferred_attack_range() -> float:
	var min_range: float = INF
	for atk in available_attacks:
		if atk != null and atk.attack_range < min_range:
			min_range = atk.attack_range
	return min_range if min_range < INF else 50.0

func get_maximum_attack_range() -> float:
	var max_range: float = 0.0
	for atk in available_attacks:
		if atk != null and atk.attack_range > max_range:
			max_range = atk.attack_range
	return max_range if max_range > 0.0 else 75.0

func select_attack(target_distance: float = -1.0) -> EnemyAttackData:
	if available_attacks.is_empty():
		return null
	
	# 1. Filter attacks that are off cooldown and within range (with 15% tolerance)
	var candidate_attacks: Array[EnemyAttackData] = []
	var candidate_weights: Array[float] = []
	
	for i in range(available_attacks.size()):
		var atk: EnemyAttackData = available_attacks[i]
		if atk == null:
			continue
		
		var cd: float = get_attack_cooldown(atk.attack_id)
		if cd > 0.0:
			continue
		
		# Range check
		if target_distance >= 0.0 and target_distance > atk.attack_range * 1.15:
			continue
		
		candidate_attacks.append(atk)
		var w: float = available_weights[i] if i < available_weights.size() else 1.0
		# Apply non-repetition penalty if other candidates exist
		if atk.attack_id == last_attack_id and available_attacks.size() > 1:
			w *= 0.2
		candidate_weights.append(w)
	
	# Fallback if no candidate meets strict distance condition: pick any off-cooldown attack
	if candidate_attacks.is_empty():
		for i in range(available_attacks.size()):
			var atk: EnemyAttackData = available_attacks[i]
			if atk != null and get_attack_cooldown(atk.attack_id) <= 0.0:
				candidate_attacks.append(atk)
				var w: float = available_weights[i] if i < available_weights.size() else 1.0
				candidate_weights.append(w)
	
	# Absolute fallback: return first attack
	if candidate_attacks.is_empty():
		return available_attacks[0]
	
	# Weighted selection
	var total_weight: float = 0.0
	for w in candidate_weights:
		total_weight += maxf(0.01, w)
	
	var roll: float = randf() * total_weight
	var cumulative: float = 0.0
	for i in range(candidate_attacks.size()):
		cumulative += maxf(0.01, candidate_weights[i])
		if roll <= cumulative:
			return candidate_attacks[i]
	
	return candidate_attacks[0]

func trigger_attack(attack_override: EnemyAttackData = null) -> bool:
	if not can_attack() and attack_override == null:
		return false
	
	active_attack_data = attack_override if attack_override != null else select_attack()
	if active_attack_data == null:
		return false
	
	last_attack_id = active_attack_data.attack_id
	current_phase = AttackPhase.TELEGRAPH
	
	var safe_speed: float = maxf(0.1, attack_speed_multiplier)
	_phase_timer = active_attack_data.telegraph_duration / safe_speed
	
	# Update hitbox collision shape & dimensions if configured
	_configure_hitbox_shape()
	
	attack_started.emit(active_attack_data)
	return true

func process_combat(delta: float) -> void:
	# Advance global cooldown
	if _global_cooldown_timer > 0.0:
		_global_cooldown_timer -= delta
		if _global_cooldown_timer <= 0.0 and current_phase == AttackPhase.COOLDOWN:
			current_phase = AttackPhase.READY
	
	# Advance individual attack cooldowns
	for key in _attack_cooldowns.keys():
		var remaining: float = float(_attack_cooldowns[key]) - delta
		if remaining <= 0.0:
			_attack_cooldowns.erase(key)
		else:
			_attack_cooldowns[key] = remaining
	
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
	var safe_speed: float = maxf(0.1, attack_speed_multiplier)
	_phase_timer = (active_attack_data.active_time if active_attack_data != null else 0.15) / safe_speed
	
	if hitbox != null and active_attack_data != null:
		hitbox.damage_multiplier = damage_multiplier
		hitbox.poise_multiplier = poise_damage_multiplier
		hitbox.activate(active_attack_data, _actor)
	
	# Screen shake for heavy attacks
	if active_attack_data is BossAttackData:
		var bad: BossAttackData = active_attack_data as BossAttackData
		if bad.screen_shake_trauma > 0.0 and has_node("/root/EventBus"):
			var bus: Node = get_node("/root/EventBus")
			if bus != null and bus.has_signal("screen_shake_requested"):
				bus.screen_shake_requested.emit(bad.screen_shake_trauma, 0.25)
	
	attack_active_entered.emit(active_attack_data)

func _enter_recovery_phase() -> void:
	current_phase = AttackPhase.RECOVERY
	var safe_speed: float = maxf(0.1, attack_speed_multiplier)
	_phase_timer = (active_attack_data.recovery_time if active_attack_data != null else 0.45) / safe_speed
	
	if hitbox != null:
		hitbox.deactivate()
	
	attack_recovered.emit(active_attack_data)

func _enter_cooldown_phase() -> void:
	current_phase = AttackPhase.COOLDOWN
	
	if active_attack_data != null:
		_attack_cooldowns[active_attack_data.attack_id] = active_attack_data.cooldown
		_global_cooldown_timer = minf(0.6, active_attack_data.cooldown * 0.4)
	else:
		_global_cooldown_timer = 0.5
	
	if hitbox != null:
		hitbox.deactivate()
	
	attack_completed.emit()

func interrupt_attack() -> void:
	if not is_attacking():
		return
	
	var interrupted_atk: EnemyAttackData = active_attack_data
	
	if hitbox != null:
		hitbox.deactivate()
	
	current_phase = AttackPhase.INTERRUPTED
	_phase_timer = 0.45 # Deflection recoil stun
	_global_cooldown_timer = 1.0 # Guarantee brief combat opening
	
	if active_attack_data != null:
		_attack_cooldowns[active_attack_data.attack_id] = active_attack_data.cooldown
	
	if has_node("/root/EventBus"):
		var bus: Node = get_node("/root/EventBus")
		if bus != null and bus.has_signal("boss_attack_interrupted"):
			var bname: String = _actor.name if _actor != null else "Boss"
			bus.boss_attack_interrupted.emit(bname)
	
	attack_interrupted_signal.emit(interrupted_atk)

func _configure_hitbox_shape() -> void:
	if hitbox == null or active_attack_data == null:
		return
	
	var facing: int = 1
	if _actor != null and _actor.has_method("get_facing_direction"):
		facing = _actor.get_facing_direction()
	
	var offset: Vector2 = active_attack_data.hitbox_offset
	hitbox.position = Vector2(offset.x * float(facing), offset.y)
	
	if hitbox.has_node("CollisionShape2D"):
		var col: CollisionShape2D = hitbox.get_node("CollisionShape2D") as CollisionShape2D
		if col != null:
			if col.shape is RectangleShape2D:
				var rect: RectangleShape2D = col.shape as RectangleShape2D
				rect.size = active_attack_data.hitbox_size
			elif col.shape == null:
				var rect: RectangleShape2D = RectangleShape2D.new()
				rect.size = active_attack_data.hitbox_size
				col.shape = rect

func reset_combat() -> void:
	if hitbox != null:
		hitbox.deactivate()
	current_phase = AttackPhase.READY
	_phase_timer = 0.0
	_global_cooldown_timer = 0.0
	_attack_cooldowns.clear()
	active_attack_data = null
	last_attack_id = &""
