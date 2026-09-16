class_name CombatTrainingAttacker
extends CharacterBody2D

## CombatTrainingAttacker
## Deterministic training enemy for validating dodge, parry, perfect parry, and attack interruption.

signal attack_triggered()
signal attack_landed(target: Node2D)
signal attack_interrupted_signal()

enum AttackerState {
	IDLE,
	TELEGRAPH,
	ACTIVE,
	RECOVERY,
	INTERRUPTED,
	STAGGERED
}

@export var auto_attack: bool = false
@export var auto_attack_interval: float = 2.5
@export var telegraph_duration: float = 0.60
@export var active_duration: float = 0.15
@export var recovery_duration: float = 0.50
@export var interrupt_stun_duration: float = 0.80

@export var attack_damage: float = 15.0
@export var attack_poise_damage: float = 20.0
@export var is_parryable: bool = true
@export var is_dodgeable: bool = true
@export var is_interruptible: bool = true

var health_component: HealthComponent = null
var poise_component: PoiseComponent = null
var hitbox: Hitbox = null
var hurtbox: Hurtbox = null
var visual_rect: ColorRect = null
var indicator_rect: ColorRect = null
var status_label: Label = null

var current_state: AttackerState = AttackerState.IDLE
var state_timer: float = 0.0
var auto_timer: float = 0.0
var initial_position: Vector2 = Vector2.ZERO

var base_color: Color = Color(0.85, 0.45, 0.15, 1.0) # Rust/Orange automaton
var flash_tween: Tween = null
var _attack_data: AttackData = null

func _ready() -> void:
	initial_position = global_position
	
	if has_node("Components/HealthComponent"):
		health_component = $Components/HealthComponent as HealthComponent
	if has_node("Components/PoiseComponent"):
		poise_component = $Components/PoiseComponent as PoiseComponent
	if has_node("Combat/EnemyHitbox"):
		hitbox = $Combat/EnemyHitbox as Hitbox
	if has_node("Hurtbox"):
		hurtbox = $Hurtbox as Hurtbox
	if has_node("Visuals/Body"):
		visual_rect = $Visuals/Body as ColorRect
	if has_node("Visuals/Indicator"):
		indicator_rect = $Visuals/Indicator as ColorRect
	if has_node("StatusLabel"):
		status_label = $StatusLabel as Label
	
	_setup_attack_data()
	
	if hurtbox != null:
		hurtbox.hit_received.connect(_on_hit_received)
	
	if poise_component != null:
		poise_component.stagger_started.connect(_on_stagger_started)
		poise_component.stagger_ended.connect(_on_stagger_ended)
	
	if hitbox != null:
		hitbox.hit_connected.connect(_on_hit_connected)
	
	if indicator_rect != null:
		indicator_rect.visible = false
	
	_update_status_display()

func _setup_attack_data() -> void:
	_attack_data = AttackData.new()
	_attack_data.attack_id = &"training_swing"
	_attack_data.damage = attack_damage
	_attack_data.poise_damage = attack_poise_damage
	_attack_data.knockback_force = Vector2(160.0, -80.0)
	_attack_data.hitstop_duration = 0.06
	_attack_data.is_parryable = is_parryable
	_attack_data.is_dodgeable = is_dodgeable
	_attack_data.is_interruptible = is_interruptible

func _physics_process(delta: float) -> void:
	# Gravity & friction
	if not is_on_floor():
		velocity.y += 980.0 * delta
	velocity.x = move_toward(velocity.x, 0.0, 700.0 * delta)
	move_and_slide()
	
	_process_state(delta)
	_update_status_display()

func _process_state(delta: float) -> void:
	match current_state:
		AttackerState.IDLE:
			if auto_attack:
				auto_timer += delta
				if auto_timer >= auto_attack_interval:
					auto_timer = 0.0
					trigger_attack()
		
		AttackerState.TELEGRAPH:
			state_timer -= delta
			if state_timer <= 0.0:
				_enter_active_attack()
		
		AttackerState.ACTIVE:
			state_timer -= delta
			if state_timer <= 0.0:
				_enter_recovery()
		
		AttackerState.RECOVERY:
			state_timer -= delta
			if state_timer <= 0.0:
				current_state = AttackerState.IDLE
		
		AttackerState.INTERRUPTED:
			state_timer -= delta
			if state_timer <= 0.0:
				current_state = AttackerState.IDLE
				if visual_rect != null:
					visual_rect.color = base_color
		
		AttackerState.STAGGERED:
			# Managed by PoiseComponent signals
			pass

func trigger_attack() -> bool:
	if current_state != AttackerState.IDLE and current_state != AttackerState.RECOVERY:
		return false
	
	current_state = AttackerState.TELEGRAPH
	state_timer = telegraph_duration
	
	if indicator_rect != null:
		indicator_rect.visible = true
		indicator_rect.color = Color(1.0, 0.8, 0.0, 1.0) # Yellow telegraph
	
	if visual_rect != null:
		visual_rect.color = Color(1.0, 0.6, 0.2, 1.0)
	
	attack_triggered.emit()
	return true

func _enter_active_attack() -> void:
	current_state = AttackerState.ACTIVE
	state_timer = active_duration
	
	if indicator_rect != null:
		indicator_rect.visible = true
		indicator_rect.color = Color(1.0, 0.1, 0.1, 1.0) # Bright red strike
	
	if visual_rect != null:
		visual_rect.color = Color(0.9, 0.2, 0.1, 1.0)
	
	if hitbox != null and _attack_data != null:
		hitbox.damage_multiplier = 1.0
		hitbox.poise_multiplier = 1.0
		hitbox.activate(_attack_data, self)

func _enter_recovery() -> void:
	current_state = AttackerState.RECOVERY
	state_timer = recovery_duration
	
	if hitbox != null:
		hitbox.deactivate()
	
	if indicator_rect != null:
		indicator_rect.visible = false
	
	if visual_rect != null:
		visual_rect.color = base_color

func interrupt_attack() -> void:
	if current_state != AttackerState.TELEGRAPH and current_state != AttackerState.ACTIVE:
		return
	
	if hitbox != null:
		hitbox.deactivate()
	
	if indicator_rect != null:
		indicator_rect.visible = false
	
	current_state = AttackerState.INTERRUPTED
	state_timer = interrupt_stun_duration
	
	# Deflection spark visual
	if visual_rect != null:
		visual_rect.color = Color(0.4, 0.7, 1.0, 1.0) # Electric cyan/blue deflection
		if flash_tween != null and flash_tween.is_valid():
			flash_tween.kill()
		flash_tween = create_tween()
		flash_tween.tween_property(visual_rect, "color", base_color, interrupt_stun_duration)
	
	attack_interrupted_signal.emit()

func _on_hit_connected(target: Area2D, _info: DamageInfo) -> void:
	attack_landed.emit(target)

func _on_hit_received(_damage_info: DamageInfo) -> void:
	if visual_rect == null:
		return
	
	if flash_tween != null and flash_tween.is_valid():
		flash_tween.kill()
	
	flash_tween = create_tween()
	visual_rect.color = Color(1.0, 0.9, 0.9)
	var target_color: Color = Color(0.95, 0.8, 0.1) if (poise_component != null and poise_component.is_staggered) else base_color
	flash_tween.tween_property(visual_rect, "color", target_color, 0.12)

func _on_stagger_started(_duration: float) -> void:
	current_state = AttackerState.STAGGERED
	if hitbox != null:
		hitbox.deactivate()
	if indicator_rect != null:
		indicator_rect.visible = false
	if visual_rect != null:
		visual_rect.color = Color(0.95, 0.8, 0.1) # Golden stagger

func _on_stagger_ended() -> void:
	current_state = AttackerState.IDLE
	if visual_rect != null:
		visual_rect.color = base_color

func reset_attacker() -> void:
	global_position = initial_position
	velocity = Vector2.ZERO
	current_state = AttackerState.IDLE
	state_timer = 0.0
	auto_timer = 0.0
	
	if hitbox != null:
		hitbox.deactivate()
	
	if indicator_rect != null:
		indicator_rect.visible = false
	
	if health_component != null:
		health_component.reset()
	if poise_component != null:
		poise_component.reset()
	
	if visual_rect != null:
		visual_rect.color = base_color
	
	_update_status_display()

func _update_status_display() -> void:
	if status_label == null:
		return
	
	var state_names: Dictionary = {
		AttackerState.IDLE: "IDLE",
		AttackerState.TELEGRAPH: "TELEGRAPH (WINDUP)",
		AttackerState.ACTIVE: "ACTIVE [SWING!]",
		AttackerState.RECOVERY: "RECOVERY",
		AttackerState.INTERRUPTED: "DEFLECTED / INTERRUPTED",
		AttackerState.STAGGERED: "STAGGERED!"
	}
	
	var hp_str: String = "HP: %.0f/%.0f" % [
		health_component.current_health if health_component != null else 0.0,
		health_component.max_health if health_component != null else 0.0
	]
	
	var poise_str: String = "Poise: %.0f/%.0f" % [
		poise_component.current_poise if poise_component != null else 0.0,
		poise_component.max_poise if poise_component != null else 0.0
	]
	
	var st_str: String = state_names.get(current_state, "UNKNOWN")
	status_label.text = "%s | %s\n[%s]" % [hp_str, poise_str, st_str]
