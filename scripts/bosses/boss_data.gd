class_name BossData
extends Resource

## BossData
## Central configuration resource defining boss identity, stats, timers, and phase definitions.

@export_group("Identity")
@export var boss_id: StringName = &"granite_abbot"
@export var display_name: String = "The Granite Abbot"

@export_group("Health & Poise")
@export var max_health: float = 300.0
@export var max_poise: float = 60.0
@export var stagger_duration: float = 1.8
@export var poise_regen_delay: float = 3.0
@export var poise_regen_rate: float = 12.0

@export_group("Locomotion & Spacing")
@export var movement_speed: float = 55.0
@export var chase_speed: float = 90.0
@export var acceleration: float = 400.0
@export var deceleration: float = 650.0
@export var preferred_combat_distance: float = 50.0
@export var detection_range: float = 350.0
@export var arena_bounds: Vector2 = Vector2(-250.0, 250.0)

@export_group("Timers & Durations")
@export var intro_duration: float = 1.5
@export var defeat_duration: float = 2.0
@export var phase_transition_duration: float = 1.8
@export var bounty_qi: int = 50

@export_group("Phases & Attack Sets")
@export var phase_thresholds: Array[float] = [0.5]
@export var phases: Array[BossPhaseData] = []
