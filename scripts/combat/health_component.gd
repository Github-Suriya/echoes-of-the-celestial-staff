class_name HealthComponent
extends Node

## HealthComponent
## Reusable health management component for players, dummies, and enemies.

signal health_changed(current: float, max_val: float)
signal damaged(amount: float)
signal healed(amount: float)
signal died()

@export var max_health: float = 100.0

var current_health: float = 100.0
var is_invulnerable: bool = false

func _ready() -> void:
	current_health = max_health

func take_damage(amount: float) -> void:
	if is_invulnerable or current_health <= 0.0 or amount <= 0.0:
		return
	
	current_health = maxf(0.0, current_health - amount)
	damaged.emit(amount)
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0.0:
		died.emit()

func heal(amount: float) -> void:
	if amount <= 0.0 or current_health <= 0.0:
		return
	
	current_health = minf(max_health, current_health + amount)
	healed.emit(amount)
	health_changed.emit(current_health, max_health)

func set_invulnerable(invulnerable: bool) -> void:
	is_invulnerable = invulnerable

func reset() -> void:
	current_health = max_health
	is_invulnerable = false
	health_changed.emit(current_health, max_health)

func is_dead() -> bool:
	return current_health <= 0.0

func get_health_percentage() -> float:
	return (current_health / max_health) if max_health > 0.0 else 0.0
