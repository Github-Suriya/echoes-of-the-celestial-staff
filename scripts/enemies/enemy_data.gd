class_name EnemyData
extends Resource

## EnemyData
## Data-driven configuration resource for enemies.
## Defines vitality, posture, locomotion, perception, and combat balancing parameters.

@export_group("Identification")
@export var enemy_id: StringName = &""
@export var display_name: String = ""

@export_group("Health & Poise")
@export var max_health: float = 80.0
@export var max_poise: float = 30.0
@export var stagger_duration: float = 1.4
@export var poise_regen_delay: float = 2.5
@export var poise_regen_rate: float = 15.0

@export_group("Locomotion")
@export var patrol_speed: float = 50.0
@export var chase_speed: float = 110.0
@export var acceleration: float = 500.0
@export var deceleration: float = 700.0
@export var gravity: float = 980.0

@export_group("Perception & Ranges")
@export var detection_range: float = 180.0
@export var lose_target_range: float = 260.0
@export var preferred_combat_distance: float = 34.0
@export var attack_range: float = 42.0
@export var alert_duration: float = 0.35

@export_group("Patrol")
@export var patrol_distance: float = 90.0
@export var patrol_wait_time: float = 1.2

@export_group("Combat & Rewards")
@export var attack_cooldown: float = 1.8
@export var bounty_qi: int = 10
@export var default_attack: EnemyAttackData = null
