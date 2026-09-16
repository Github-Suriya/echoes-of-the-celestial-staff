class_name SpiritAbilityData
extends Resource

## SpiritAbilityData
## Data-driven resource defining attributes, timings, costs, and combat payloads for Spirit Abilities.

enum AbilityType {
	PROJECTILE,
	AREA,
	MOBILITY,
	BUFF
}

@export var ability_id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var ability_type: AbilityType = AbilityType.PROJECTILE

# Resource & Cooldown Costs
@export var spirit_cost: float = 20.0
@export var cooldown: float = 2.0

# Frame / Timing Lifecycle (in seconds)
@export var startup_time: float = 0.08
@export var active_time: float = 0.05
@export var recovery_time: float = 0.15

# Combat Payload Values
@export var damage: float = 18.0
@export var poise_damage: float = 15.0
@export var knockback_force: Vector2 = Vector2(140.0, -20.0)
@export var hitstop_duration: float = 0.04

# Defensive Flags
@export var is_parryable: bool = true
@export var is_dodgeable: bool = true

# Context Constraints
@export var can_use_grounded: bool = true
@export var can_use_airborne: bool = true
@export var interruptible: bool = false
@export var movement_multiplier: float = 1.0
