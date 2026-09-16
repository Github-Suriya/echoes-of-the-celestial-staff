class_name VFXManager
extends Node2D

## VFXManager
## Central, decoupled visual effect spawner for Echoes of the Celestial Staff.
## Responds to EventBus combat and world signals, spawning lightweight particle bursts
## with strict particle budgets (<80 total active particles) for stable 60 FPS on Intel UHD.

@export var hit_spark_scene: PackedScene = preload("res://scenes/effects/vfx_hit_spark.tscn")
@export var heavy_impact_scene: PackedScene = preload("res://scenes/effects/vfx_heavy_impact.tscn")
@export var parry_spark_scene: PackedScene = preload("res://scenes/effects/vfx_parry_spark.tscn")
@export var dodge_burst_scene: PackedScene = preload("res://scenes/effects/vfx_dodge_burst.tscn")
@export var death_burst_scene: PackedScene = preload("res://scenes/effects/vfx_death_burst.tscn")
@export var staff_trail_scene: PackedScene = preload("res://scenes/effects/vfx_staff_trail.tscn")
@export var hit_flash_scene: PackedScene = preload("res://scenes/effects/vfx_hit_flash.tscn")
@export var boss_telegraph_scene: PackedScene = preload("res://scenes/effects/vfx_boss_telegraph.tscn")
@export var awakening_aura_scene: PackedScene = preload("res://scenes/effects/vfx_awakening_aura.tscn")
@export var phase_transition_scene: PackedScene = preload("res://scenes/effects/vfx_phase_transition.tscn")

func _ready() -> void:
	_connect_bus_signals()

func _connect_bus_signals() -> void:
	if not has_node("/root/EventBus"):
		return
	
	var bus: Node = get_node("/root/EventBus")
	if bus == null:
		return
	
	if bus.has_signal("damage_dealt") and not bus.damage_dealt.is_connected(_on_damage_dealt):
		bus.damage_dealt.connect(_on_damage_dealt)
	
	if bus.has_signal("perfect_parry") and not bus.perfect_parry.is_connected(_on_perfect_parry):
		bus.perfect_parry.connect(_on_perfect_parry)
	elif bus.has_signal("parry_success") and not bus.parry_success.is_connected(_on_parry_success):
		bus.parry_success.connect(_on_parry_success)
	
	if bus.has_signal("dodge_started") and not bus.dodge_started.is_connected(_on_dodge_started):
		bus.dodge_started.connect(_on_dodge_started)
	
	if bus.has_signal("enemy_died") and not bus.enemy_died.is_connected(_on_enemy_died):
		bus.enemy_died.connect(_on_enemy_died)
	
	if bus.has_signal("transformation_started") and not bus.transformation_started.is_connected(_on_transformation_started):
		bus.transformation_started.connect(_on_transformation_started)
	
	if bus.has_signal("boss_phase_changed") and not bus.boss_phase_changed.is_connected(_on_boss_phase_changed):
		bus.boss_phase_changed.connect(_on_boss_phase_changed)

func spawn_effect(scene: PackedScene, at_position: Vector2, color_tint: Color = Color.WHITE) -> Node2D:
	if scene == null:
		return null
	
	var fx: Node2D = scene.instantiate() as Node2D
	if fx == null:
		return null
	
	fx.global_position = at_position
	if color_tint != Color.WHITE:
		fx.modulate = color_tint
	
	add_child(fx)
	return fx

func _on_damage_dealt(target: Node2D, amount: float, is_critical: bool) -> void:
	if target == null or not is_instance_valid(target):
		return
	
	var pos: Vector2 = target.global_position + Vector2(0.0, -20.0)
	if is_critical or amount >= 25.0:
		spawn_effect(heavy_impact_scene, pos)
	else:
		spawn_effect(hit_spark_scene, pos)

func _on_perfect_parry(defender: Node2D, attacker: Node2D) -> void:
	var pos: Vector2 = defender.global_position if defender != null else global_position
	if attacker != null:
		pos = (defender.global_position + attacker.global_position) * 0.5
	spawn_effect(parry_spark_scene, pos + Vector2(0.0, -20.0), Color(1.0, 0.95, 0.4))

func _on_parry_success(defender: Node2D, _attacker: Node2D) -> void:
	if defender != null and is_instance_valid(defender):
		spawn_effect(parry_spark_scene, defender.global_position + Vector2(0.0, -20.0))

func _on_dodge_started(entity: Node2D, _direction: int) -> void:
	if entity != null and is_instance_valid(entity):
		spawn_effect(dodge_burst_scene, entity.global_position)

func _on_enemy_died(enemy: Node2D, _bounty_qi: int) -> void:
	if enemy != null and is_instance_valid(enemy):
		spawn_effect(death_burst_scene, enemy.global_position + Vector2(0.0, -20.0))

func _on_transformation_started() -> void:
	# Find player or spawn at center
	var bus: Node = get_node_or_null("/root/EventBus")
	if bus != null and has_node("/root/GameManager"):
		var p: Node2D = get_tree().get_first_node_in_group("player") as Node2D
		if p != null:
			spawn_effect(awakening_aura_scene, p.global_position + Vector2(0.0, -20.0))

func _on_boss_phase_changed(_boss_id: StringName, _phase_id: int) -> void:
	var boss: Node2D = get_tree().get_first_node_in_group("boss") as Node2D
	var pos: Vector2 = boss.global_position + Vector2(0.0, -30.0) if boss != null else Vector2(1200, 800)
	spawn_effect(phase_transition_scene, pos)
