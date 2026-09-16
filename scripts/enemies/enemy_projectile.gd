class_name EnemyProjectile
extends Area2D

## EnemyProjectile
## Lightweight Area2D projectile spawned by ranged enemies (e.g. Spore Caster, Hollow Shrine Keeper).
## Delivers DamageInfo payloads to player Hurtbox (Layer 6) while traversing the world.

signal projectile_hit(target_hurtbox: Area2D, damage_info: DamageInfo)
signal projectile_expired()

@export var speed: float = 260.0
@export var max_lifetime: float = 2.0

var velocity_direction: Vector2 = Vector2.RIGHT
var damage_info: DamageInfo = null
var attacker: Node2D = null

var _lifetime_timer: float = 0.0
var _hit_hurtboxes: Array[Area2D] = []
var _is_active: bool = true

func _ready() -> void:
	# Layer 5 (EnemyHitbox, bitmask 16), Mask Layer 6 (PlayerHurtbox, bitmask 32) + Layer 1 (World, bitmask 1)
	collision_layer = 16
	collision_mask = 33
	
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	_lifetime_timer = max_lifetime

func launch(dmg: DamageInfo, start_pos: Vector2, facing_dir: int, source_actor: Node2D = null) -> void:
	damage_info = dmg
	global_position = start_pos
	attacker = source_actor
	velocity_direction = Vector2(1.0 if facing_dir >= 0 else -1.0, 0.0)
	_lifetime_timer = max_lifetime
	_hit_hurtboxes.clear()
	_is_active = true
	scale.x = velocity_direction.x

func launch_vector(dmg: DamageInfo, start_pos: Vector2, dir_vec: Vector2, source_actor: Node2D = null) -> void:
	damage_info = dmg
	global_position = start_pos
	attacker = source_actor
	velocity_direction = dir_vec.normalized()
	if velocity_direction.length_squared() < 0.01:
		velocity_direction = Vector2.RIGHT
	_lifetime_timer = max_lifetime
	_hit_hurtboxes.clear()
	_is_active = true
	rotation = velocity_direction.angle()

func _physics_process(delta: float) -> void:
	if not _is_active:
		return
	
	global_position += velocity_direction * speed * delta
	_lifetime_timer -= delta
	
	if _lifetime_timer <= 0.0:
		expire()

func expire() -> void:
	_is_active = false
	projectile_expired.emit()
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	if not _is_active:
		return
	# Expire upon hitting solid world terrain
	if body != attacker:
		expire()

func _on_area_entered(area: Area2D) -> void:
	if not _is_active or damage_info == null:
		return
	
	if not area.has_method("receive_hit"):
		return
	
	if _hit_hurtboxes.has(area):
		return
	
	# Prevent hitting self/enemy
	if "owner_actor" in area and area.owner_actor != null and area.owner_actor == attacker:
		return
	
	_hit_hurtboxes.append(area)
	
	var payload: DamageInfo = DamageInfo.new()
	payload.damage = damage_info.damage
	payload.poise_damage = damage_info.poise_damage
	payload.knockback_force = damage_info.knockback_force
	payload.hit_direction = int(sign(velocity_direction.x)) if velocity_direction.x != 0.0 else 1
	payload.attack_id = damage_info.attack_id
	payload.attacker = attacker
	payload.source_hitbox = self
	payload.hitstop_duration = damage_info.hitstop_duration
	payload.is_parryable = damage_info.is_parryable
	payload.is_dodgeable = damage_info.is_dodgeable
	
	area.receive_hit(payload)
	projectile_hit.emit(area, payload)
	
	expire()
