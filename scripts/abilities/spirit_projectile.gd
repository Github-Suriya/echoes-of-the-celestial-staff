class_name SpiritProjectile
extends Area2D

## SpiritProjectile
## Lightweight Area2D projectile entity spawned by projectile-type Spirit Abilities (Celestial Arc).
## Delivers DamageInfo payloads to overlapping enemy Hurtboxes and tracks hit history to prevent duplicate hits.

signal projectile_hit(target_hurtbox: Area2D, damage_info: DamageInfo)
signal projectile_expired()

@export var speed: float = 520.0
@export var max_lifetime: float = 1.2

var direction: int = 1
var ability_data: SpiritAbilityData = null
var attacker: Node2D = null
var damage_multiplier: float = 1.0

var _lifetime_timer: float = 0.0
var _hit_hurtboxes: Array[Area2D] = []
var _is_active: bool = true

func _ready() -> void:
	# Default layers: Layer 4 (PlayerHitbox, bit 3 -> 8), Mask 7 (EnemyHurtbox, bit 6 -> 64)
	if collision_layer == 1:
		collision_layer = 8
		collision_mask = 64
	
	area_entered.connect(_on_area_entered)
	_lifetime_timer = max_lifetime

func launch(data: SpiritAbilityData, start_pos: Vector2, facing_dir: int, source_actor: Node2D = null, dmg_mult: float = 1.0) -> void:
	ability_data = data
	global_position = start_pos
	direction = 1 if facing_dir >= 0 else -1
	attacker = source_actor
	damage_multiplier = dmg_mult
	_lifetime_timer = max_lifetime
	_hit_hurtboxes.clear()
	_is_active = true
	
	# Scale visual orientation
	scale.x = float(direction)

func _physics_process(delta: float) -> void:
	if not _is_active:
		return
	
	global_position.x += float(direction) * speed * delta
	_lifetime_timer -= delta
	
	if _lifetime_timer <= 0.0:
		expire()

func expire() -> void:
	_is_active = false
	projectile_expired.emit()
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	if not _is_active or ability_data == null:
		return
	
	if not area.has_method("receive_hit"):
		return
	
	if _hit_hurtboxes.has(area):
		return
	
	# Prevent hitting self/caster
	if "owner_actor" in area and area.owner_actor != null and area.owner_actor == attacker:
		return
	
	_hit_hurtboxes.append(area)
	
	var payload: DamageInfo = DamageInfo.new()
	payload.damage = ability_data.damage * damage_multiplier
	payload.poise_damage = ability_data.poise_damage
	payload.knockback_force = ability_data.knockback_force
	payload.hit_direction = direction
	payload.attack_id = ability_data.ability_id
	payload.attacker = attacker
	payload.source_hitbox = self
	payload.hitstop_duration = ability_data.hitstop_duration
	payload.is_parryable = ability_data.is_parryable
	payload.is_dodgeable = ability_data.is_dodgeable
	
	area.receive_hit(payload)
	projectile_hit.emit(area, payload)
	
	# Trigger hitstop if specified
	if payload.hitstop_duration > 0.0 and has_node("/root/GameManager"):
		var gm: Node = get_node("/root/GameManager")
		if gm != null and gm.has_method("apply_hitstop"):
			gm.apply_hitstop(payload.hitstop_duration)
	
	# Notify EventBus
	if has_node("/root/EventBus"):
		var bus: Node = get_node("/root/EventBus")
		if bus != null and bus.has_signal("damage_dealt"):
			var victim: Node2D = area.owner as Node2D if area.owner is Node2D else area
			bus.damage_dealt.emit(victim, payload.damage, false)
	
	# Expire after successful hit
	expire()
