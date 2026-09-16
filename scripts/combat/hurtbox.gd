class_name Hurtbox
extends Area2D

## Hurtbox
## Combat Area2D that receives DamageInfo payloads from Hitboxes and routes to Health/Poise components.

signal hit_received(damage_info: DamageInfo)

@export var owner_actor: Node2D = null
@export var health_component: HealthComponent = null
@export var poise_component: PoiseComponent = null

var is_invulnerable: bool = false

func _ready() -> void:
	# Default layers: Layer 7 (EnemyHurtbox, bit 6 -> 64), Mask 0
	if collision_layer == 1:
		collision_layer = 64
		collision_mask = 0
	
	if owner_actor == null and owner is Node2D:
		owner_actor = owner as Node2D
	
	# Auto-discover sibling or parent components if not explicitly bound
	_find_components()

func receive_hit(damage_info: DamageInfo) -> void:
	if is_invulnerable:
		return
	
	if health_component != null and health_component.is_invulnerable:
		return
	
	# Apply damage
	if health_component != null:
		health_component.take_damage(damage_info.damage)
	
	# Apply poise damage
	if poise_component != null:
		poise_component.take_poise_damage(damage_info.poise_damage)
	
	# Apply knockback force
	if owner_actor != null and owner_actor is CharacterBody2D:
		var char_body: CharacterBody2D = owner_actor as CharacterBody2D
		var kb: Vector2 = Vector2(
			damage_info.knockback_force.x * float(damage_info.hit_direction),
			damage_info.knockback_force.y
		)
		char_body.velocity += kb
	
	hit_received.emit(damage_info)
	
	# Notify EventBus
	if has_node("/root/EventBus"):
		var bus: Node = get_node("/root/EventBus")
		if bus != null and bus.has_signal("damage_received"):
			bus.damage_received.emit(owner_actor if owner_actor != null else self, damage_info.damage)

func _find_components() -> void:
	var target: Node = owner_actor if owner_actor != null else (owner if owner != null else get_parent())
	if target == null:
		return
	
	if health_component == null:
		if target.has_node("Components/HealthComponent"):
			health_component = target.get_node("Components/HealthComponent") as HealthComponent
		elif target.has_node("HealthComponent"):
			health_component = target.get_node("HealthComponent") as HealthComponent
	
	if poise_component == null:
		if target.has_node("Components/PoiseComponent"):
			poise_component = target.get_node("Components/PoiseComponent") as PoiseComponent
		elif target.has_node("PoiseComponent"):
			poise_component = target.get_node("PoiseComponent") as PoiseComponent
