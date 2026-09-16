class_name SpiritAbilityController
extends Node

## SpiritAbilityController
## Manages equipped Spirit Abilities, cast validation, atomic cost transactions,
## lightweight numeric cooldowns, casting lifecycle phases, and execution delegates.

signal ability_started(ability_data: SpiritAbilityData)
signal ability_phase_changed(phase: int)
signal ability_completed(ability_data: SpiritAbilityData)
signal ability_failed(ability_id: StringName, reason: StringName)
signal cooldown_updated(ability_id: StringName, remaining: float, total: float)

enum AbilityPhase {
	READY,
	STARTUP,
	ACTIVE,
	RECOVERY,
	COOLDOWN
}

@export var ability_slots: Array[SpiritAbilityData] = []
@export var projectile_scene: PackedScene = preload("res://scenes/effects/spirit_projectile.tscn")

var player: CharacterBody2D = null
var current_ability: SpiritAbilityData = null
var current_phase: AbilityPhase = AbilityPhase.READY
var phase_timer: float = 0.0
var is_casting: bool = false
var cloud_step_direction: int = 1

var _cooldown_timers: Dictionary = {} # Dictionary[StringName, float]
var _cooldown_durations: Dictionary = {} # Dictionary[StringName, float]

func _ready() -> void:
	if owner is CharacterBody2D:
		player = owner as CharacterBody2D
	elif get_parent() is CharacterBody2D:
		player = get_parent() as CharacterBody2D
	elif get_parent() != null and get_parent().get_parent() is CharacterBody2D:
		player = get_parent().get_parent() as CharacterBody2D
	
	_ensure_default_ability_slots()

func _ensure_default_ability_slots() -> void:
	if ability_slots.is_empty():
		var default_paths: Array[String] = [
			"res://data/abilities/ability_celestial_arc.tres",
			"res://data/abilities/ability_heavenly_pulse.tres",
			"res://data/abilities/ability_cloud_step.tres"
		]
		for path in default_paths:
			if ResourceLoader.exists(path):
				var res: Resource = load(path)
				if res is SpiritAbilityData:
					ability_slots.append(res)
	
	for ability in ability_slots:
		if ability != null and not ability.ability_id.is_empty():
			_cooldown_timers[ability.ability_id] = 0.0
			_cooldown_durations[ability.ability_id] = ability.cooldown

func _process(delta: float) -> void:
	# Decrement cooldown timers without allocating memory
	for ability_id in _cooldown_timers.keys():
		var current_val: float = _cooldown_timers[ability_id]
		if current_val > 0.0:
			var new_val: float = maxf(current_val - delta, 0.0)
			_cooldown_timers[ability_id] = new_val
			var total_dur: float = _cooldown_durations.get(ability_id, 1.0)
			cooldown_updated.emit(ability_id, new_val, total_dur)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	
	if has_node("/root/InputManager"):
		var im: Node = get_node("/root/InputManager")
		if im != null and im.has_method("is_action_just_pressed"):
			if im.is_action_just_pressed(&"ability_1"):
				trigger_ability_slot(0)
			elif im.is_action_just_pressed(&"ability_2"):
				trigger_ability_slot(1)
			elif im.is_action_just_pressed(&"ability_3"):
				trigger_ability_slot(2)
	else:
		if event.is_action_pressed(&"ability_1"):
			trigger_ability_slot(0)
		elif event.is_action_pressed(&"ability_2"):
			trigger_ability_slot(1)
		elif event.is_action_pressed(&"ability_3"):
			trigger_ability_slot(2)

func trigger_ability_slot(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= ability_slots.size():
		return false
	var ability: SpiritAbilityData = ability_slots[slot_index]
	if ability == null:
		return false
	return trigger_ability(ability)

func can_cast_ability(data: SpiritAbilityData) -> bool:
	if data == null:
		return false
	
	# Blocked if already casting an ability
	if is_casting:
		return false
	
	# Blocked if on cooldown
	if not is_ability_ready(data.ability_id):
		return false
	
	# Blocked if insufficient Spirit
	var spirit_comp: SpiritComponent = _get_spirit_component()
	if spirit_comp != null and not spirit_comp.has_spirit(data.spirit_cost):
		return false
	
	# Context checks: Grounded vs Airborne
	if player != null:
		if not data.can_use_grounded and player.is_on_floor():
			return false
		if not data.can_use_airborne and not player.is_on_floor():
			return false
	
	# Blocked during committed combat states
	if player != null and player.has_node("Components/CombatController"):
		var combat: CombatController = player.get_node("Components/CombatController") as CombatController
		if combat != null and combat.is_attacking():
			if combat.is_charging_heavy:
				return false
			var phase: CombatController.AttackPhase = combat.get_attack_phase()
			if phase == CombatController.AttackPhase.STARTUP or phase == CombatController.AttackPhase.ACTIVE:
				return false
			if not combat.can_cancel_attack():
				return false
	
	# Blocked during active defense states
	if player != null and player.has_node("Components/DefenseController"):
		var defense: DefenseController = player.get_node("Components/DefenseController") as DefenseController
		if defense != null:
			if defense.is_dodging and defense.is_invulnerable_to_damage:
				return false
			if defense.is_parrying and defense.is_in_parry_window():
				return false
	
	return true

func trigger_ability(data: SpiritAbilityData) -> bool:
	if not can_cast_ability(data):
		var reason: StringName = &"state_blocked"
		if is_casting:
			reason = &"busy"
		elif data != null and not is_ability_ready(data.ability_id):
			reason = &"cooldown"
		elif data != null and _get_spirit_component() != null and not _get_spirit_component().has_spirit(data.spirit_cost):
			reason = &"insufficient_spirit"
		ability_failed.emit(data.ability_id if data != null else &"", reason)
		_notify_fail_feedback()
		return false
	
	# Atomic commit: consume Spirit
	var spirit_comp: SpiritComponent = _get_spirit_component()
	if spirit_comp != null:
		var consumed: bool = spirit_comp.consume_spirit(data.spirit_cost)
		if not consumed:
			ability_failed.emit(data.ability_id, &"insufficient_spirit")
			return false
	
	# Start cooldown
	start_cooldown(data.ability_id, data.cooldown)
	
	# Initialize ability lifecycle
	current_ability = data
	is_casting = true
	current_phase = AbilityPhase.STARTUP
	phase_timer = data.startup_time
	
	# Configure Cloud Step direction if applicable
	if data.ability_id == &"cloud_step":
		var move_axis: float = 0.0
		if has_node("/root/InputManager"):
			move_axis = get_node("/root/InputManager").get_movement_axis()
		if absf(move_axis) > 0.05:
			cloud_step_direction = 1 if move_axis > 0.0 else -1
		else:
			cloud_step_direction = player.get_facing_direction() if player != null and player.has_method("get_facing_direction") else 1
	
	# Transition StateMachine
	if player != null and player.has_node("StateMachine"):
		var sm: StateMachine = player.get_node("StateMachine") as StateMachine
		if sm != null and sm.has_state(&"SpiritAbility"):
			sm.change_state(&"SpiritAbility")
	
	_notify_animation_cast(data.ability_id)
	ability_started.emit(data)
	ability_phase_changed.emit(current_phase)
	return true

func process_ability(delta: float) -> bool:
	if not is_casting or current_ability == null:
		return false
	
	phase_timer -= delta
	
	while is_casting and phase_timer <= 0.0:
		var overflow: float = -phase_timer
		match current_phase:
			AbilityPhase.STARTUP:
				current_phase = AbilityPhase.ACTIVE
				phase_timer = current_ability.active_time - overflow
				_execute_active_ability()
				ability_phase_changed.emit(current_phase)
			
			AbilityPhase.ACTIVE:
				current_phase = AbilityPhase.RECOVERY
				phase_timer = current_ability.recovery_time - overflow
				ability_phase_changed.emit(current_phase)
			
			AbilityPhase.RECOVERY:
				finish_ability()
				return false
	
	_process_ability_physics(delta)
	return is_casting

func _execute_active_ability() -> void:
	if current_ability == null:
		return
	
	match current_ability.ability_type:
		SpiritAbilityData.AbilityType.PROJECTILE:
			_spawn_projectile()
		SpiritAbilityData.AbilityType.AREA:
			_execute_area_shockwave()
		SpiritAbilityData.AbilityType.MOBILITY:
			_start_cloud_step_burst()

func _spawn_projectile() -> void:
	if projectile_scene == null or player == null:
		return
	
	var proj: SpiritProjectile = projectile_scene.instantiate() as SpiritProjectile
	var facing: int = player.get_facing_direction() if player.has_method("get_facing_direction") else 1
	var spawn_pos: Vector2 = player.global_position + Vector2(18.0 * float(facing), -22.0)
	
	var container: Node = player.get_parent() if player.get_parent() != null else player
	container.add_child(proj)
	proj.launch(current_ability, spawn_pos, facing, player)

func _execute_area_shockwave() -> void:
	if player == null:
		return
	
	var space_state: PhysicsDirectSpaceState2D = player.get_world_2d().direct_space_state
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 64.0
	
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, player.global_position + Vector2(0, -22.0))
	query.collision_mask = 64 # Layer 7 EnemyHurtbox
	query.collide_with_areas = true
	query.collide_with_bodies = false
	
	var results: Array[Dictionary] = space_state.intersect_shape(query, 16)
	var hit_count: int = 0
	var hit_areas: Array[Area2D] = []
	
	for res in results:
		var collider: Object = res.collider
		if collider is Area2D and collider.has_method("receive_hit") and not hit_areas.has(collider):
			hit_areas.append(collider)
			var target_area: Area2D = collider as Area2D
			var hit_dir: int = 1 if target_area.global_position.x >= player.global_position.x else -1
			
			var payload: DamageInfo = DamageInfo.new()
			payload.damage = current_ability.damage
			payload.poise_damage = current_ability.poise_damage
			payload.knockback_force = current_ability.knockback_force
			payload.hit_direction = hit_dir
			payload.attack_id = current_ability.ability_id
			payload.attacker = player
			payload.hitstop_duration = current_ability.hitstop_duration
			payload.is_parryable = current_ability.is_parryable
			payload.is_dodgeable = current_ability.is_dodgeable
			
			target_area.receive_hit(payload)
			hit_count += 1
			
			if has_node("/root/EventBus"):
				var bus: Node = get_node("/root/EventBus")
				if bus != null and bus.has_signal("damage_dealt"):
					var victim: Node2D = target_area.owner as Node2D if target_area.owner is Node2D else target_area
					bus.damage_dealt.emit(victim, payload.damage, false)
	
	# Apply hitstop if at least one target was hit
	if hit_count > 0 and current_ability.hitstop_duration > 0.0 and has_node("/root/GameManager"):
		var gm: Node = get_node("/root/GameManager")
		if gm != null and gm.has_method("apply_hitstop"):
			gm.apply_hitstop(current_ability.hitstop_duration)

func _start_cloud_step_burst() -> void:
	if player != null:
		player.velocity.x = float(cloud_step_direction) * 550.0

func _process_ability_physics(delta: float) -> void:
	if player == null:
		return
	
	if current_ability != null and current_ability.ability_id == &"cloud_step":
		if current_phase == AbilityPhase.ACTIVE:
			player.velocity.x = float(cloud_step_direction) * 550.0
		elif current_phase == AbilityPhase.RECOVERY:
			player.velocity.x = move_toward(player.velocity.x, 0.0, 900.0 * delta)
		player.move_and_slide()
	else:
		if player.is_on_floor():
			player.velocity.x = move_toward(player.velocity.x, 0.0, 800.0 * delta)
		player.move_and_slide()

func finish_ability() -> void:
	var finished_data: SpiritAbilityData = current_ability
	is_casting = false
	current_ability = null
	current_phase = AbilityPhase.READY
	phase_timer = 0.0
	
	if finished_data != null:
		ability_completed.emit(finished_data)

func cancel_ability() -> void:
	if is_casting:
		finish_ability()

func start_cooldown(id: StringName, duration: float) -> void:
	_cooldown_timers[id] = duration
	_cooldown_durations[id] = duration

func is_ability_ready(id: StringName) -> bool:
	if not _cooldown_timers.has(id):
		return true
	return _cooldown_timers[id] <= 0.0

func get_cooldown_remaining(id: StringName) -> float:
	return maxf(_cooldown_timers.get(id, 0.0), 0.0)

func get_cooldown_ratio(id: StringName) -> float:
	var total: float = _cooldown_durations.get(id, 1.0)
	if total <= 0.0:
		return 0.0
	return clampf(get_cooldown_remaining(id) / total, 0.0, 1.0)

func get_phase_name() -> String:
	match current_phase:
		AbilityPhase.READY:
			return "READY"
		AbilityPhase.STARTUP:
			return "STARTUP"
		AbilityPhase.ACTIVE:
			return "ACTIVE"
		AbilityPhase.RECOVERY:
			return "RECOVERY"
		AbilityPhase.COOLDOWN:
			return "COOLDOWN"
	return "UNKNOWN"

func _get_spirit_component() -> SpiritComponent:
	if player != null and player.has_node("Components/SpiritComponent"):
		return player.get_node("Components/SpiritComponent") as SpiritComponent
	return null

func _notify_animation_cast(ability_id: StringName) -> void:
	if player != null and player.has_node("Components/PlayerAnimationController"):
		var anim: Node = player.get_node("Components/PlayerAnimationController")
		if anim != null:
			match ability_id:
				&"celestial_arc":
					if anim.has_method("play_celestial_arc"):
						anim.play_celestial_arc()
				&"heavenly_pulse":
					if anim.has_method("play_heavenly_pulse"):
						anim.play_heavenly_pulse()
				&"cloud_step":
					if anim.has_method("play_cloud_step"):
						anim.play_cloud_step()

func _notify_fail_feedback() -> void:
	if player != null and player.has_node("Components/PlayerAnimationController"):
		var anim: Node = player.get_node("Components/PlayerAnimationController")
		if anim != null and anim.has_method("play_spirit_fail_feedback"):
			anim.play_spirit_fail_feedback()
