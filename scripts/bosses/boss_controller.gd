class_name BossController
extends CharacterBody2D

## BossController
## Central coordinator for boss encounters in Echoes of the Celestial Staff.
## Integrates multi-phase state machine, data-driven attack sets, telegraphs,
## and posture / poise mechanics while reusing canonical combat interfaces.

signal boss_state_changed(old_state: StringName, new_state: StringName)
signal boss_phase_changed_signal(phase_number: int)
signal boss_defeated_signal()
signal boss_reset_signal()

@export var boss_data: BossData = null
@export var auto_start_ai: bool = true

var health_component: HealthComponent = null
var poise_component: PoiseComponent = null
var perception: BossPerception = null
var combat_controller: BossCombatController = null
var phase_controller: BossPhaseController = null
var telegraph_controller: BossTelegraphController = null
var anim_controller: BossAnimationController = null
var state_machine: StateMachine = null
var hitbox: Hitbox = null
var hurtbox: Hurtbox = null
var status_label: Label = null

var is_defeated: bool = false
var initial_position: Vector2 = Vector2.ZERO
var gravity: float = 980.0

var facing_direction: int = 1:
	set(value):
		var clamped_val: int = 1 if value >= 0 else -1
		if facing_direction != clamped_val:
			facing_direction = clamped_val
			_on_facing_changed(facing_direction)

func _ready() -> void:
	initial_position = global_position
	
	# Enforce layer contracts: Layer 3 (bitmask 4) for Enemy/Boss body, Layer 1 (bitmask 1) for World
	collision_layer = 4
	collision_mask = 1
	
	_discover_components()
	_connect_signals()
	
	if boss_data != null:
		configure(boss_data)

func _discover_components() -> void:
	if has_node("Components/HealthComponent"):
		health_component = $Components/HealthComponent as HealthComponent
	if has_node("Components/PoiseComponent"):
		poise_component = $Components/PoiseComponent as PoiseComponent
	if has_node("Components/BossPerception"):
		perception = $Components/BossPerception as BossPerception
	if has_node("Components/BossCombatController"):
		combat_controller = $Components/BossCombatController as BossCombatController
	if has_node("Components/BossPhaseController"):
		phase_controller = $Components/BossPhaseController as BossPhaseController
	if has_node("Components/BossTelegraphController"):
		telegraph_controller = $Components/BossTelegraphController as BossTelegraphController
	elif has_node("Visuals/TelegraphIndicator"):
		telegraph_controller = $Visuals/TelegraphIndicator as BossTelegraphController
	if has_node("Components/BossAnimationController"):
		anim_controller = $Components/BossAnimationController as BossAnimationController
	if has_node("StateMachine"):
		state_machine = $StateMachine as StateMachine
	if has_node("Combat/BossHitbox"):
		hitbox = $Combat/BossHitbox as Hitbox
	if has_node("Combat/BossHurtbox"):
		hurtbox = $Combat/BossHurtbox as Hurtbox
	elif has_node("Hurtbox"):
		hurtbox = $Hurtbox as Hurtbox
	if has_node("StatusLabel"):
		status_label = $StatusLabel as Label

func _connect_signals() -> void:
	if health_component != null:
		health_component.died.connect(_on_died)
		health_component.health_changed.connect(_on_health_changed)
	
	if poise_component != null:
		poise_component.stagger_started.connect(_on_stagger_started)
	
	if hurtbox != null:
		hurtbox.hit_received.connect(_on_hit_received)
	
	if combat_controller != null:
		combat_controller.attack_started.connect(_on_attack_started)
		combat_controller.attack_active_entered.connect(_on_attack_active_entered)
		combat_controller.attack_recovered.connect(_on_attack_recovered)
		combat_controller.attack_interrupted_signal.connect(_on_attack_interrupted)
	
	if phase_controller != null:
		phase_controller.phase_changed.connect(_on_phase_changed)
		phase_controller.phase_transition_started.connect(_on_phase_transition_started)
	
	if state_machine != null:
		state_machine.state_changed.connect(_on_state_changed)

func configure(data: BossData) -> void:
	boss_data = data
	if boss_data == null:
		return
	
	if health_component != null:
		health_component.max_health = boss_data.max_health
		health_component.current_health = boss_data.max_health
	
	if poise_component != null:
		poise_component.max_poise = boss_data.max_poise
		poise_component.current_poise = boss_data.max_poise
		poise_component.stagger_duration = boss_data.stagger_duration
		poise_component.poise_regen_delay = boss_data.poise_regen_delay
		poise_component.poise_regen_rate = boss_data.poise_regen_rate
	
	if perception != null:
		perception.configure_boss(boss_data)
	
	if phase_controller != null:
		phase_controller.configure(boss_data)
		if combat_controller != null and phase_controller.current_phase_data != null:
			combat_controller.set_phase_data(phase_controller.current_phase_data)
	
	if combat_controller != null:
		combat_controller.hitbox = hitbox

func _physics_process(delta: float) -> void:
	if not auto_start_ai:
		return
	
	if is_dead_or_defeated():
		move_and_slide()
		return
	
	if perception != null:
		perception.update_perception(delta)
	
	if combat_controller != null:
		combat_controller.process_combat(delta)
	
	move_and_slide()
	_update_status_display()

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

func get_facing_direction() -> int:
	return facing_direction

func set_facing_direction(dir: int) -> void:
	facing_direction = dir

func face_target() -> void:
	if perception != null and perception.has_target():
		var diff: float = perception.current_target.global_position.x - global_position.x
		if absf(diff) > 8.0:
			facing_direction = 1 if diff > 0.0 else -1

func _on_facing_changed(new_dir: int) -> void:
	if anim_controller != null:
		anim_controller.update_facing(new_dir)
	
	# Adjust hitbox offset based on facing
	if hitbox != null and combat_controller != null and combat_controller.active_attack_data != null:
		var base_offset: Vector2 = combat_controller.active_attack_data.hitbox_offset
		hitbox.position = Vector2(base_offset.x * float(new_dir), base_offset.y)

func interrupt_attack() -> void:
	if is_dead_or_defeated():
		return
	
	if combat_controller != null and combat_controller.is_attacking():
		combat_controller.interrupt_attack()
	
	if anim_controller != null:
		anim_controller.play_attack_interrupted()
	
	if state_machine != null and state_machine.get_current_state_name() == &"Attack":
		state_machine.change_state(&"Hit")

func receive_hit(_damage_info: DamageInfo) -> void:
	if is_dead_or_defeated():
		return
	
	# If poise broke or in phase transition, do not interrupt state
	if poise_component != null and poise_component.is_staggered:
		return
	if is_in_phase_transition():
		return
	
	if state_machine != null:
		var current_st: StringName = state_machine.get_current_state_name()
		if current_st != &"Stagger" and current_st != &"Defeated" and current_st != &"PhaseTransition":
			# Only flinch if not attacking or if the attack is marked interruptible
			if combat_controller == null or not combat_controller.is_attacking():
				state_machine.change_state(&"Hit")
			elif combat_controller.active_attack_data != null and combat_controller.active_attack_data.is_interruptible:
				interrupt_attack()

func die() -> void:
	if is_defeated:
		return
	
	is_defeated = true
	velocity = Vector2.ZERO
	
	if state_machine != null:
		state_machine.change_state(&"Defeated")
	
	if hitbox != null:
		hitbox.deactivate()
	
	if hurtbox != null:
		hurtbox.is_invulnerable = true
		hurtbox.set_deferred("monitoring", false)
		hurtbox.set_deferred("monitorable", false)
	
	if telegraph_controller != null:
		telegraph_controller.stop_telegraph()
	
	boss_defeated_signal.emit()

func reset_boss() -> void:
	global_position = initial_position
	velocity = Vector2.ZERO
	is_defeated = false
	facing_direction = 1
	
	if health_component != null:
		health_component.reset()
	if poise_component != null:
		poise_component.reset()
	if phase_controller != null:
		phase_controller.reset_phases()
		if combat_controller != null and phase_controller.current_phase_data != null:
			combat_controller.set_phase_data(phase_controller.current_phase_data)
	if combat_controller != null:
		combat_controller.reset_combat()
	if telegraph_controller != null:
		telegraph_controller.stop_telegraph()
	if anim_controller != null:
		anim_controller.reset_visuals()
	if hurtbox != null:
		hurtbox.is_invulnerable = false
		hurtbox.set_deferred("monitoring", true)
		hurtbox.set_deferred("monitorable", true)
	if state_machine != null:
		state_machine.change_state(&"Idle")
	
	boss_reset_signal.emit()
	_update_status_display()

func is_dead_or_defeated() -> bool:
	return is_defeated or (health_component != null and health_component.is_dead())

func is_in_phase_transition() -> bool:
	if phase_controller != null and phase_controller.is_transitioning:
		return true
	if state_machine != null and state_machine.get_current_state_name() == &"PhaseTransition":
		return true
	return false

# --- Signal Callbacks ---

func _on_died() -> void:
	die()

func _on_health_changed(cur_hp: float, max_hp: float) -> void:
	if phase_controller != null and not is_defeated:
		phase_controller.check_health_threshold(cur_hp, max_hp)

func _on_stagger_started(_duration: float) -> void:
	if is_dead_or_defeated() or is_in_phase_transition():
		return
	if state_machine != null:
		state_machine.change_state(&"Stagger")

func _on_hit_received(damage_info: DamageInfo) -> void:
	receive_hit(damage_info)

func _on_phase_transition_started(_phase_number: int) -> void:
	if state_machine != null and not is_dead_or_defeated():
		state_machine.change_state(&"PhaseTransition")

func _on_phase_changed(phase_num: int, phase_data: BossPhaseData) -> void:
	boss_phase_changed_signal.emit(phase_num)
	if combat_controller != null:
		combat_controller.set_phase_data(phase_data)

func _on_attack_started(attack_data: EnemyAttackData) -> void:
	if telegraph_controller != null and attack_data != null:
		var safe_speed: float = maxf(0.1, combat_controller.attack_speed_multiplier if combat_controller != null else 1.0)
		var tele_dur: float = attack_data.telegraph_duration / safe_speed
		var tint: Color = phase_controller.current_phase_data.telegraph_color if (phase_controller != null and phase_controller.current_phase_data != null) else Color.TRANSPARENT
		telegraph_controller.start_telegraph(attack_data, facing_direction, tele_dur, tint)
	
	if anim_controller != null and attack_data != null:
		var safe_speed: float = maxf(0.1, combat_controller.attack_speed_multiplier if combat_controller != null else 1.0)
		anim_controller.play_attack_telegraph(attack_data.telegraph_duration / safe_speed)

func _on_attack_active_entered(attack_data: EnemyAttackData) -> void:
	if telegraph_controller != null:
		telegraph_controller.stop_telegraph()
	if anim_controller != null and attack_data != null:
		var safe_speed: float = maxf(0.1, combat_controller.attack_speed_multiplier if combat_controller != null else 1.0)
		anim_controller.play_attack_active(attack_data.active_time / safe_speed)

func _on_attack_recovered(attack_data: EnemyAttackData) -> void:
	if anim_controller != null and attack_data != null:
		var safe_speed: float = maxf(0.1, combat_controller.attack_speed_multiplier if combat_controller != null else 1.0)
		anim_controller.play_attack_recovery(attack_data.recovery_time / safe_speed)

func _on_attack_interrupted(_attack_data: EnemyAttackData) -> void:
	if telegraph_controller != null:
		telegraph_controller.stop_telegraph()
	if anim_controller != null:
		anim_controller.play_attack_interrupted()

func _on_state_changed(old_state: StringName, new_state: StringName) -> void:
	boss_state_changed.emit(old_state, new_state)
	_update_status_display()

func _update_status_display() -> void:
	if status_label == null:
		return
	var cur_hp: float = health_component.current_health if health_component != null else 0.0
	var max_hp: float = health_component.max_health if health_component != null else 0.0
	var cur_p: float = poise_component.current_poise if poise_component != null else 0.0
	var max_p: float = poise_component.max_poise if poise_component != null else 0.0
	var st_name: StringName = state_machine.get_current_state_name() if state_machine != null else &"NONE"
	var p_num: int = phase_controller.get_current_phase_number() if phase_controller != null else 1
	status_label.text = "Phase %d | HP: %.0f/%.0f | Poise: %.0f/%.0f\n[%s]" % [p_num, cur_hp, max_hp, cur_p, max_p, st_name]
