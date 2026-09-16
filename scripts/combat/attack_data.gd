class_name AttackData
extends Resource

## AttackData
## Custom Resource defining data-driven attributes for a single attack move.

@export var attack_id: StringName = &""
@export var display_name: String = ""
@export var damage: float = 10.0
@export var poise_damage: float = 12.0
@export var knockback_force: Vector2 = Vector2(120.0, -30.0)
@export var startup_time: float = 0.067
@export var active_time: float = 0.050
@export var recovery_time: float = 0.133
@export var combo_window_start: float = 0.050
@export var combo_window_end: float = 0.220
@export var next_attack_id: StringName = &""
@export var forward_impulse: float = 30.0
@export var hitstop_duration: float = 0.050
@export var attack_priority: int = 1
