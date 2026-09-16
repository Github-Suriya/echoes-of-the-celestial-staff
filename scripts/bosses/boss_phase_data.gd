class_name BossPhaseData
extends Resource

## BossPhaseData
## Custom Resource defining phase attributes, stat multipliers, telegraph tints, and attack sets.

@export var phase_id: int = 1
@export var phase_name: String = "Phase 1"
@export var health_threshold_ratio: float = 1.0 # Fraction of max HP (e.g. 1.0 for P1, 0.5 for P2)
@export var movement_speed_multiplier: float = 1.0
@export var attack_speed_multiplier: float = 1.0
@export var damage_multiplier: float = 1.0
@export var poise_damage_multiplier: float = 1.0
@export var attacks: Array[EnemyAttackData] = []
@export var attack_weights: Array[float] = []
@export var telegraph_color: Color = Color(1.0, 0.75, 0.1, 0.8) # Warning indicator color
@export var aura_color: Color = Color(0.8, 0.8, 0.8, 0.3) # Ambient stone aura color
