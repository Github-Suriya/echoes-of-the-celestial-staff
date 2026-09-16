class_name DamageInfo
extends RefCounted

## DamageInfo
## Strongly-typed combat payload passed from Hitbox to Hurtbox and DamageReceivers.

var damage: float = 0.0
var poise_damage: float = 0.0
var knockback_force: Vector2 = Vector2.ZERO
var hit_direction: int = 1 # +1 for right, -1 for left
var attack_id: StringName = &""
var attacker: Node2D = null
var source_hitbox: Area2D = null
var hitstop_duration: float = 0.0
