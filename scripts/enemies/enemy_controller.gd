class_name EnemyController
extends CharacterBody2D

## EnemyController
## Central orchestration node for enemies.
## Coordinates perception, locomotion, combat, state machine, and damage interfaces.

signal enemy_spawned_signal()
signal enemy_died_signal()
signal enemy_state_changed(old_state: StringName, new_state: StringName)

@export var enemy_data: EnemyData = null
@export var auto_start_ai: bool = true

var health_component: HealthComponent = null
var poise_component: PoiseComponent = null
var perception: EnemyPerception = null
var movement: EnemyMovement = null
var combat_controller: EnemyCombatController = null
var anim_controller: EnemyAnimationController = null
var state_machine: StateMachine = null
var hitbox: Hitbox = null
var hurtbox: Hurtbox = null
var status_label: Label = null

var is_dead: bool = false
var initial_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	initial_position = global_position
	
	# Enforce layer contracts: Layer 3 (bitmask 4) for EnemyBody, Layer 1 (bitmask 1) for World
	collision_layer = 4
	collision_mask = 1
	
	_discover_components()
	_connect_signals()
	
	if enemy_data != null:
		configure(enemy_data)
	
	if has_node("/root/EventBus"):
		var bus: Node = get_node("/root/EventBus")
		if bus != null and bus.has_signal("enemy_spawned"):
			bus.enemy_spawned.emit(self)
	
	enemy_spawned_signal.emit()

func _discover_components() -> void:
	if has_node("Components/HealthComponent"):
		health_component = $Components/HealthComponent as HealthComponent
	if has_node("Components/PoiseComponent"):
		poise_component = $Components/PoiseComponent as PoiseComponent
	if has_node("Components/EnemyPerception"):
		perception = $Components/EnemyPerception as EnemyPerception
	if has_node("Components/EnemyMovement"):
		movement = $Components/EnemyMovement as EnemyMovement
	if has_node("Components/EnemyCombatController"):
		combat_controller = $Components/EnemyCombatController as EnemyCombatController
	if has_node("Components/EnemyAnimationController"):
		anim_controller = $Components/EnemyAnimationController as EnemyAnimationController
	if has_node("StateMachine"):
		state_machine = $StateMachine as StateMachine
	if has_node("Combat/EnemyHitbox"):
		hitbox = $Combat/EnemyHitbox as Hitbox
	if has_node("Combat/EnemyHurtbox"):
		hurtbox = $Combat/EnemyHurtbox as Hurtbox
	elif has_node("Hurtbox"):
		hurtbox = $Hurtbox as Hurtbox
	if has_node("StatusLabel"):
		status_label = $StatusLabel as Label

func _connect_signals() -> void:
	if health_component != null:
		health_component.died.connect(_on_died)
	
	if poise_component != null:
		poise_component.stagger_started.connect(_on_stagger_started)
	
	if hurtbox != null:
		hurtbox.hit_received.connect(_on_hit_received)
	
	if movement != null:
		movement.facing_changed.connect(_on_facing_changed)
	
	if combat_controller != null:
		combat_controller.attack_started.connect(_on_attack_started)
		combat_controller.attack_active_entered.connect(_on_attack_active_entered)
		combat_controller.attack_recovered.connect(_on_attack_recovered)
		combat_controller.attack_interrupted_signal.connect(_on_attack_interrupted)
	
	if state_machine != null:
		state_machine.state_changed.connect(_on_state_changed)

func configure(data: EnemyData) -> void:
	enemy_data = data
	if enemy_data == null:
		return
	
	if health_component != null:
		health_component.max_health = enemy_data.max_health
		health_component.current_health = enemy_data.max_health
	
	if poise_component != null:
		poise_component.max_poise = enemy_data.max_poise
		poise_component.current_poise = enemy_data.max_poise
		poise_component.stagger_duration = enemy_data.stagger_duration
		poise_component.poise_regen_delay = enemy_data.poise_regen_delay
		poise_component.poise_regen_rate = enemy_data.poise_regen_rate
	
	if perception != null:
		perception.configure(enemy_data)
	
	if movement != null:
		movement.configure(enemy_data, initial_position)
	
	if combat_controller != null:
		combat_controller.configure(enemy_data, hitbox)

func _physics_process(delta: float) -> void:
	if not auto_start_ai:
		return
	
	if is_dead:
		move_and_slide()
		return
	
	# Perception update
	if perception != null:
		perception.update_perception(delta)
	
	# Combat controller processing
	if combat_controller != null:
		combat_controller.process_combat(delta)
	
	# Execute locomotion
	move_and_slide()
	
	_update_status_display()

func get_facing_direction() -> int:
	return movement.facing_direction if movement != null else 1

func set_facing_direction(dir: int) -> void:
	if movement != null:
		movement.facing_direction = dir

func interrupt_attack() -> void:
	if is_dead:
		return
	
	if combat_controller != null and combat_controller.is_attacking():
		combat_controller.interrupt_attack()
	
	if anim_controller != null:
		anim_controller.play_attack_interrupted()

func receive_hit(damage_info: DamageInfo) -> void:
	if is_dead:
		return
	
	# If poise broke, PoiseComponent signal handles stagger
	if poise_component != null and poise_component.is_staggered:
		return
	
	# If currently not attacking or attack is interruptible, trigger Hit flinch state
	if state_machine != null:
		var current_st: StringName = state_machine.get_current_state_name()
		if current_st != &"Stagger" and current_st != &"Dead":
			if combat_controller == null or not combat_controller.is_attacking() or (combat_controller.active_attack_data != null and combat_controller.active_attack_data.is_interruptible):
				state_machine.change_state(&"Hit")

func die() -> void:
	if is_dead:
		return
	
	is_dead = true
	velocity = Vector2.ZERO
	
	if state_machine != null:
		state_machine.change_state(&"Dead")
	
	if hitbox != null:
		hitbox.deactivate()
	
	if hurtbox != null:
		hurtbox.set_deferred("monitoring", false)
		hurtbox.set_deferred("monitorable", false)
	
	if perception != null:
		perception.clear_target()
	
	var bounty: int = enemy_data.bounty_qi if enemy_data != null else 10
	if has_node("/root/EventBus"):
		var bus: Node = get_node("/root/EventBus")
		if bus != null and bus.has_signal("enemy_died"):
			bus.enemy_died.emit(self, bounty)
	
	enemy_died_signal.emit()

func reset_enemy() -> void:
	global_position = initial_position
	velocity = Vector2.ZERO
	is_dead = false
	
	if health_component != null:
		health_component.reset()
	if poise_component != null:
		poise_component.reset()
	if movement != null:
		movement.set_spawn_position(initial_position)
	if combat_controller != null:
		combat_controller.reset_combat()
	if anim_controller != null:
		anim_controller.reset_visuals()
	if hurtbox != null:
		hurtbox.monitoring = true
		hurtbox.monitorable = true
	
	if state_machine != null:
		state_machine.change_state(&"Idle")
	
	_update_status_display()

func _on_died() -> void:
	die()

func _on_stagger_started(_duration: float) -> void:
	if is_dead:
		return
	if has_node("/root/EventBus"):
		var bus: Node = get_node("/root/EventBus")
		if bus != null and bus.has_signal("enemy_staggered"):
			bus.enemy_staggered.emit(self)
	if state_machine != null:
		state_machine.change_state(&"Stagger")

func _on_hit_received(damage_info: DamageInfo) -> void:
	receive_hit(damage_info)

func _on_facing_changed(new_dir: int) -> void:
	if anim_controller != null:
		anim_controller.update_facing(new_dir)
	
	# Adjust hitbox offset based on facing
	if hitbox != null and combat_controller != null and combat_controller.active_attack_data != null:
		var base_offset: Vector2 = combat_controller.active_attack_data.hitbox_offset
		hitbox.position = Vector2(base_offset.x * float(new_dir), base_offset.y)

func _on_attack_started(_attack_data: EnemyAttackData) -> void:
	if anim_controller != null:
		anim_controller.play_attack_telegraph()

func _on_attack_active_entered() -> void:
	if anim_controller != null:
		anim_controller.play_attack_active()

func _on_attack_recovered() -> void:
	if anim_controller != null:
		anim_controller.play_attack_recovery()

func _on_attack_interrupted() -> void:
	if anim_controller != null:
		anim_controller.play_attack_interrupted()

func _on_state_changed(old_state: StringName, new_state: StringName) -> void:
	enemy_state_changed.emit(old_state, new_state)
	_update_status_display()

func _update_status_display() -> void:
	if status_label == null:
		return
	
	var current_hp: float = health_component.current_health if health_component != null else 0.0
	var max_hp: float = health_component.max_health if health_component != null else 0.0
	var current_p: float = poise_component.current_poise if poise_component != null else 0.0
	var max_p: float = poise_component.max_poise if poise_component != null else 0.0
	var st_name: StringName = state_machine.get_current_state_name() if state_machine != null else &"NONE"
	
	status_label.text = "HP: %.0f/%.0f | Poise: %.0f/%.0f\n[%s]" % [current_hp, max_hp, current_p, max_p, st_name]
