class_name EnemyAttackData
extends AttackData

## EnemyAttackData
## Data-driven specification for an individual enemy attack move.
## Inherits AttackData to remain 100% polymorphic with Hitbox and DamageInfo.

@export_group("Enemy Attack Tuning")
@export var attack_range: float = 42.0
@export var cooldown: float = 1.8
@export var telegraph_duration: float = 0.40
@export var hitbox_size: Vector2 = Vector2(36.0, 32.0)
@export var hitbox_offset: Vector2 = Vector2(24.0, -20.0)
