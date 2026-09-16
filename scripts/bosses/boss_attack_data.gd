class_name BossAttackData
extends EnemyAttackData

## BossAttackData
## Extended attack resource for boss encounters.
## Inherits EnemyAttackData (which inherits AttackData) to maintain 100% polymorphism
## with Hitbox, Hurtbox, and DamageInfo while adding telegraph shape descriptors.

@export_group("Boss Telegraph Configuration")
@export var telegraph_type: String = "sweep" # "sweep", "slam", "thrust", "shockwave"
@export var telegraph_shape_size: Vector2 = Vector2(60.0, 24.0)
@export var ground_marker_radius: float = 0.0 # > 0 for area ground markers like shockwaves
@export var screen_shake_trauma: float = 0.0
