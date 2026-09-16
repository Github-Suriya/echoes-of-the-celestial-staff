class_name SporeCasterController
extends EnemyController

## SporeCasterController
## Specialized enemy controller for Spore Caster.
## Spawns an EnemyProjectile toward the player when entering the active attack phase.

@export var projectile_scene: PackedScene = preload("res://scenes/effects/enemy_projectile.tscn")

func _ready() -> void:
	super._ready()
	if combat_controller != null:
		combat_controller.attack_active_entered.connect(_on_spore_attack_active)

func _on_spore_attack_active() -> void:
	if is_dead or projectile_scene == null:
		return
	
	var proj: EnemyProjectile = projectile_scene.instantiate() as EnemyProjectile
	if proj == null:
		return
	
	var parent_room: Node = get_parent()
	if parent_room == null:
		parent_room = get_tree().current_scene
	if parent_room == null:
		return
	
	parent_room.add_child(proj)
	
	var dinfo: DamageInfo = DamageInfo.new()
	if combat_controller != null and combat_controller.active_attack_data != null:
		dinfo.damage = combat_controller.active_attack_data.damage
		dinfo.poise_damage = combat_controller.active_attack_data.poise_damage
		dinfo.knockback_force = combat_controller.active_attack_data.knockback_force
		dinfo.attack_id = combat_controller.active_attack_data.attack_id
	else:
		dinfo.damage = 15.0
		dinfo.poise_damage = 10.0
		dinfo.attack_id = &"spore_caster_cast"
	
	var facing: int = 1
	if movement != null:
		facing = movement.facing_direction
	elif perception != null and perception.target != null:
		facing = 1 if perception.target.global_position.x >= global_position.x else -1
	
	var spawn_pos: Vector2 = global_position + Vector2(float(facing) * 16.0, -22.0)
	
	# If target exists, aim vectorially towards target center
	if perception != null and perception.target != null:
		var target_center: Vector2 = perception.target.global_position + Vector2(0, -20.0)
		var dir_vec: Vector2 = (target_center - spawn_pos).normalized()
		proj.launch_vector(dinfo, spawn_pos, dir_vec, self)
	else:
		proj.launch(dinfo, spawn_pos, facing, self)
