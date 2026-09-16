class_name StanceData
extends Resource

## StanceData
## Defines properties and combat/locomotion modifiers for a specific martial stance.

enum StanceType {
	SWIFT,
	MOUNTAIN,
	STORM
}

@export var stance_type: StanceType = StanceType.SWIFT
@export var stance_id: StringName = &"swift"
@export var display_name: String = "Swift Stance"
@export_multiline var description: String = ""

# Locomotion Modifiers
@export var movement_speed_multiplier: float = 1.0
@export var acceleration_multiplier: float = 1.0
@export var deceleration_multiplier: float = 1.0

# Offensive Combat Modifiers
@export var attack_speed_multiplier: float = 1.0
@export var damage_multiplier: float = 1.0
@export var poise_damage_multiplier: float = 1.0

# Defensive Modifiers
@export var dodge_distance_multiplier: float = 1.0
@export var dodge_recovery_multiplier: float = 1.0
@export var parry_window_multiplier: float = 1.0
@export var hitstop_multiplier: float = 1.0
