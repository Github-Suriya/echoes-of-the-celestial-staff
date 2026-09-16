class_name Hitbox
extends Area2D

## Hitbox
## Combat Area2D that delivers DamageInfo payloads to overlapping Hurtboxes during active attack frames.

signal hit_connected(target_hurtbox: Area2D, damage_info: DamageInfo)

@export var current_attack_data: AttackData = null
@export var owner_actor: Node2D = null
@export var damage_multiplier: float = 1.0
@export var poise_multiplier: float = 1.0
@export var stance_damage_multiplier: float = 1.0
@export var stance_poise_multiplier: float = 1.0
@export var transformation_damage_multiplier: float = 1.0
@export var transformation_poise_multiplier: float = 1.0
@export var transformation_hitstop_multiplier: float = 1.0

var is_active: bool = false
var _hit_hurtboxes: Array[Area2D] = []

func _ready() -> void:
	# Default layers: Layer 4 (PlayerHitbox, bit 3 -> 8), Mask Layer 7 (EnemyHurtbox, bit 6 -> 64)
	if collision_layer == 1:
		collision_layer = 8
		collision_mask = 64
	
	# Start disabled until explicitly activated by an attack
	monitoring = false
	monitorable = false
	is_active = false
	
	area_entered.connect(_on_area_entered)
	
	if owner_actor == null and owner is Node2D:
		owner_actor = owner as Node2D

func activate(attack_data: AttackData, actor: Node2D = null) -> void:
	current_attack_data = attack_data
	if actor != null:
		owner_actor = actor
	
	_hit_hurtboxes.clear()
	is_active = true
	monitoring = true
	monitorable = true
	
	# Immediately evaluate overlapping areas to avoid missing stationary targets
	for area in get_overlapping_areas():
		_on_area_entered(area)

func deactivate() -> void:
	is_active = false
	monitoring = false
	monitorable = false
	_hit_hurtboxes.clear()
	damage_multiplier = 1.0
	poise_multiplier = 1.0
	stance_damage_multiplier = 1.0
	stance_poise_multiplier = 1.0
	transformation_damage_multiplier = 1.0
	transformation_poise_multiplier = 1.0
	transformation_hitstop_multiplier = 1.0

func _on_area_entered(area: Area2D) -> void:
	if not is_active or current_attack_data == null:
		return
	
	if not area.has_method("receive_hit"):
		return
	
	if _hit_hurtboxes.has(area):
		return
	
	# Prevent hitting self
	if "owner_actor" in area and area.owner_actor != null and area.owner_actor == owner_actor:
		return
	
	_hit_hurtboxes.append(area)
	
	# Determine hit direction based on actor facing or relative positions
	var hit_dir: int = 1
	if owner_actor != null and owner_actor.has_method("get_facing_direction"):
		hit_dir = owner_actor.get_facing_direction()
	elif owner_actor != null:
		hit_dir = 1 if area.global_position.x >= owner_actor.global_position.x else -1
	
	var payload: DamageInfo = DamageInfo.new()
	payload.damage = current_attack_data.damage * damage_multiplier * stance_damage_multiplier * transformation_damage_multiplier
	payload.poise_damage = current_attack_data.poise_damage * poise_multiplier * stance_poise_multiplier * transformation_poise_multiplier
	payload.knockback_force = current_attack_data.knockback_force
	payload.hit_direction = hit_dir
	payload.attack_id = current_attack_data.attack_id
	payload.attacker = owner_actor
	payload.source_hitbox = self
	payload.hitstop_duration = current_attack_data.hitstop_duration * transformation_hitstop_multiplier
	payload.is_parryable = current_attack_data.is_parryable
	payload.is_dodgeable = current_attack_data.is_dodgeable
	payload.attack_data = current_attack_data
	payload.is_charge_attack = (damage_multiplier > 1.0)
	
	area.receive_hit(payload)
	hit_connected.emit(area, payload)
	
	# Trigger global hitstop if duration specified
	if payload.hitstop_duration > 0.0 and has_node("/root/GameManager"):
		var gm: Node = get_node("/root/GameManager")
		if gm != null and gm.has_method("apply_hitstop"):
			gm.apply_hitstop(payload.hitstop_duration)
	
	# Notify EventBus
	if has_node("/root/EventBus"):
		var bus: Node = get_node("/root/EventBus")
		if bus != null and bus.has_signal("damage_dealt"):
			var victim_node: Node2D = area.owner as Node2D if area.owner is Node2D else area
			bus.damage_dealt.emit(victim_node, payload.damage, false)
