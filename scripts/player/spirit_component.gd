class_name SpiritComponent
extends Node

## SpiritComponent
## Manages player celestial essence (Spirit), transactional consumption, clamping,
## and combat-based restoration (light hits, heavy hits, perfect parries).

signal spirit_changed(current_spirit: float, max_spirit: float)
signal spirit_depleted()
signal spirit_consumed(amount: float)
signal spirit_restored(amount: float)

@export var max_spirit: float = 100.0
@export var current_spirit: float = 100.0

@export var light_hit_spirit_gain: float = 4.0
@export var heavy_hit_spirit_gain: float = 8.0
@export var perfect_parry_spirit_gain: float = 10.0

var player: CharacterBody2D = null

func _ready() -> void:
	if owner is CharacterBody2D:
		player = owner as CharacterBody2D
	elif get_parent() is CharacterBody2D:
		player = get_parent() as CharacterBody2D
	elif get_parent() != null and get_parent().get_parent() is CharacterBody2D:
		player = get_parent().get_parent() as CharacterBody2D
	
	current_spirit = clampf(current_spirit, 0.0, max_spirit)
	connect_combat_hooks()

func connect_combat_hooks() -> void:
	if player == null:
		return
	
	# Hook into CombatController for melee hit spirit gain
	if player.has_node("Components/CombatController"):
		var combat: CombatController = player.get_node("Components/CombatController") as CombatController
		if combat != null and combat.hitbox != null:
			if not combat.hitbox.hit_connected.is_connected(_on_combat_hit_connected):
				combat.hitbox.hit_connected.connect(_on_combat_hit_connected)
	
	# Hook into DefenseController for perfect parry spirit reward
	if player.has_node("Components/DefenseController"):
		var defense: DefenseController = player.get_node("Components/DefenseController") as DefenseController
		if defense != null:
			if not defense.perfect_parry.is_connected(_on_perfect_parry_reward):
				defense.perfect_parry.connect(_on_perfect_parry_reward)

func get_spirit() -> float:
	return current_spirit

func get_max_spirit() -> float:
	return max_spirit

func get_spirit_ratio() -> float:
	if max_spirit <= 0.0:
		return 0.0
	return clampf(current_spirit / max_spirit, 0.0, 1.0)

func has_spirit(amount: float) -> bool:
	return current_spirit >= amount

func consume_spirit(amount: float) -> bool:
	if amount <= 0.0:
		return true
	
	if current_spirit < amount:
		return false
	
	current_spirit -= amount
	current_spirit = clampf(current_spirit, 0.0, max_spirit)
	
	spirit_consumed.emit(amount)
	spirit_changed.emit(current_spirit, max_spirit)
	_broadcast_event_bus()
	
	if current_spirit <= 0.0:
		spirit_depleted.emit()
	
	return true

func restore_spirit(amount: float) -> void:
	if amount <= 0.0:
		return
	
	var old_spirit: float = current_spirit
	current_spirit = minf(current_spirit + amount, max_spirit)
	
	if not is_equal_approx(old_spirit, current_spirit):
		spirit_restored.emit(amount)
		spirit_changed.emit(current_spirit, max_spirit)
		_broadcast_event_bus()

func set_spirit(amount: float) -> void:
	var clamped: float = clampf(amount, 0.0, max_spirit)
	if not is_equal_approx(current_spirit, clamped):
		current_spirit = clamped
		spirit_changed.emit(current_spirit, max_spirit)
		_broadcast_event_bus()

func reset_spirit() -> void:
	set_spirit(max_spirit)

func _on_combat_hit_connected(_hurtbox: Area2D, damage_info: DamageInfo) -> void:
	if damage_info == null:
		return
	if damage_info.is_charge_attack:
		restore_spirit(heavy_hit_spirit_gain)
	else:
		restore_spirit(light_hit_spirit_gain)

func _on_perfect_parry_reward(_attacker: Node2D) -> void:
	restore_spirit(perfect_parry_spirit_gain)

func _broadcast_event_bus() -> void:
	if has_node("/root/EventBus"):
		var bus: Node = get_node("/root/EventBus")
		if bus != null and bus.has_signal("player_spirit_changed"):
			bus.player_spirit_changed.emit(current_spirit, max_spirit)
