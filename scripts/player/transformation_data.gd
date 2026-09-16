class_name TransformationData
extends Resource

## TransformationData
## Data-driven definition for temporary supernatural transformations (e.g. Celestial Awakening).
## Encapsulates resource costs, duration, locomotion/combat/defense multipliers, and presentation profile IDs.

@export var transformation_id: StringName = &"celestial_awakening"
@export var display_name: String = "Celestial Awakening"
@export_multiline var description: String = "Channel divine celestial qi to enter an awakened state, empowering martial speed, damage, and mobility."

# Resource & Timing
@export var spirit_cost: float = 100.0
@export var duration: float = 12.0

# Locomotion Modifiers
@export var move_speed_multiplier: float = 1.10
@export var acceleration_multiplier: float = 1.10
@export var deceleration_multiplier: float = 1.10

# Combat Modifiers
@export var attack_speed_multiplier: float = 1.10
@export var damage_multiplier: float = 1.15
@export var poise_damage_multiplier: float = 1.10
@export var hitstop_multiplier: float = 1.05

# Defense Modifiers (Velocity & Recovery only; I-frames & Parry windows invariant)
@export var dodge_velocity_multiplier: float = 1.05
@export var dodge_recovery_multiplier: float = 0.95

# Spirit Ability Modifiers
@export var spirit_ability_damage_multiplier: float = 1.10

# Presentation Profiles
@export var visual_profile_id: StringName = &"celestial_awakening"
@export var audio_profile_id: StringName = &"celestial_awakening"
