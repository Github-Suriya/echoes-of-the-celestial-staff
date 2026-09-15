class_name PlayerMovementConfig
extends Resource

## PlayerMovementConfig
## Data-driven tuning parameters for 2D platforming locomotion.
## Stores values for horizontal movement, jump curves, coyote time, and buffering.

@export_group("Horizontal Locomotion")
@export var max_speed: float = 260.0
@export var acceleration: float = 1800.0
@export var deceleration: float = 2000.0
@export var air_acceleration: float = 1300.0
@export var air_deceleration: float = 800.0

@export_group("Vertical Locomotion & Jump")
@export var gravity: float = 1100.0
@export var jump_velocity: float = -420.0
@export var fall_gravity_multiplier: float = 1.4
@export var low_jump_gravity_multiplier: float = 2.2
@export var max_fall_speed: float = 650.0

@export_group("Timing & Windows")
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.12
@export var land_duration: float = 0.08
