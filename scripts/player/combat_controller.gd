class_name CombatController
extends Node

## CombatController
## Orchestrates player weapon attacks, combo chains, input buffering, hitbox activation,
## aerial combat, charged heavy attacks, and attack cancellation windows.

signal attack_started(attack: AttackData)
signal attack_phase_changed(phase: int)
signal attack_finished()
signal attack_hit_connected(target: Area2D, damage_info: DamageInfo)
signal charge_updated(charge_ratio: float)

enum AttackPhase {
	NONE,
	STARTUP,
	ACTIVE,
	RECOVERY
}

const INPUT_BUFFER_DURATION: float = 0.35 # Holds early attack inputs up to 350ms

@export var hitbox: Hitbox

var player: CharacterBody2D = null

var current_attack: AttackData = null
var current_phase: AttackPhase = AttackPhase.NONE
var phase_timer: float = 0.0
var combo_timer: float = 0.0
var combo_index: int = 0
var has_buffered_attack: bool = false
var buffered_is_heavy: bool = false
var is_combo_window_open: bool = false

# Heavy Attack Charging State
var is_charging_heavy: bool = false
var charge_timer: float = 0.0
var charge_multiplier: float = 1.0
var poise_charge_multiplier: float = 1.0

var _input_buffer_timer: float = 0.0
var _attacks: Dictionary = {} # Dictionary[StringName, AttackData]

func _ready() -> void:
	if owner is CharacterBody2D:
		player = owner as CharacterBody2D
	
	_load_attack_resources()
	
	# Auto-discover hitbox if not assigned
	if hitbox == null and player != null:
		if player.has_node("Combat/PlayerHitbox"):
			hitbox = player.get_node("Combat/PlayerHitbox") as Hitbox
	
	if hitbox != null:
		hitbox.hit_connected.connect(_on_hitbox_connected)

func _load_attack_resources() -> void:
	var paths: Dictionary = {
		&"light_1": "res://data/attacks/attack_light_1.tres",
		&"light_2": "res://data/attacks/attack_light_2.tres",
		&"light_3": "res://data/attacks/attack_light_3.tres",
		&"heavy_1": "res://data/attacks/attack_heavy_1.tres",
		&"air_1": "res://data/attacks/attack_air_1.tres"
	}
	
	for id in paths:
		var path: String = paths[id]
		if ResourceLoader.exists(path):
			var res: Resource = load(path)
			if res is AttackData:
				_attacks[id] = res

func is_attacking() -> bool:
	return current_phase != AttackPhase.NONE or is_charging_heavy

func get_current_attack() -> AttackData:
	return current_attack

func get_attack_phase() -> AttackPhase:
	return current_phase

func get_attack_phase_name() -> String:
	if is_charging_heavy:
		return "CHARGING"
	match current_phase:
		AttackPhase.STARTUP:
			return "STARTUP"
		AttackPhase.ACTIVE:
			return "ACTIVE"
		AttackPhase.RECOVERY:
			return "RECOVERY"
		_:
			return "NONE"

func get_combo_index() -> int:
	return combo_index

func can_cancel_attack() -> bool:
	return current_phase == AttackPhase.RECOVERY

func start_light_attack() -> bool:
	if not _attacks.has(&"light_1"):
		return false
	
	return _execute_attack(_attacks[&"light_1"], 1)

func start_heavy_attack() -> bool:
	if not _attacks.has(&"heavy_1"):
		return false
	
	charge_multiplier = 1.0
	poise_charge_multiplier = 1.0
	return _execute_attack(_attacks[&"heavy_1"], 0)

func start_heavy_charge() -> bool:
	if not _attacks.has(&"heavy_1"):
		return false
	
	var attack_data: AttackData = _attacks[&"heavy_1"]
	if not attack_data.is_chargeable:
		return start_heavy_attack()
	
	is_charging_heavy = true
	charge_timer = 0.0
	charge_multiplier = 1.0
	poise_charge_multiplier = 1.0
	
	_notify_animation_charge()
	return true

func update_heavy_charge(delta: float) -> void:
	if not is_charging_heavy or not _attacks.has(&"heavy_1"):
		return
	
	var attack_data: AttackData = _attacks[&"heavy_1"]
	charge_timer = minf(attack_data.maximum_charge_time, charge_timer + delta)
	
	var ratio: float = get_charge_ratio()
	charge_multiplier = lerpf(1.0, attack_data.maximum_damage_multiplier, ratio)
	poise_charge_multiplier = lerpf(1.0, attack_data.maximum_poise_multiplier, ratio)
	
	charge_updated.emit(ratio)

func release_heavy_attack() -> bool:
	if not _attacks.has(&"heavy_1"):
		is_charging_heavy = false
		return false
	
	var attack_data: AttackData = _attacks[&"heavy_1"]
	is_charging_heavy = false
	
	var success: bool = _execute_attack(attack_data, 0)
	if success and hitbox != null:
		var stance_dmg: float = 1.0
		var stance_poise: float = 1.0
		var stance: StanceController = _get_stance_controller()
		if stance != null:
			stance_dmg = stance.get_damage_multiplier()
			stance_poise = stance.get_poise_damage_multiplier()
		hitbox.damage_multiplier = charge_multiplier
		hitbox.poise_multiplier = poise_charge_multiplier
		hitbox.stance_damage_multiplier = stance_dmg
		hitbox.stance_poise_multiplier = stance_poise
	return success

func get_charge_ratio() -> float:
	if not _attacks.has(&"heavy_1"):
		return 0.0
	var attack_data: AttackData = _attacks[&"heavy_1"]
	var total_span: float = attack_data.maximum_charge_time - attack_data.minimum_charge_time
	if total_span <= 0.0:
		return 1.0 if charge_timer >= attack_data.minimum_charge_time else 0.0
	return clampf((charge_timer - attack_data.minimum_charge_time) / total_span, 0.0, 1.0)

func start_air_attack() -> bool:
	if not _attacks.has(&"air_1"):
		return false
	
	charge_multiplier = 1.0
	poise_charge_multiplier = 1.0
	return _execute_attack(_attacks[&"air_1"], 0)

func _execute_attack(attack_data: AttackData, next_combo_index: int) -> bool:
	current_attack = attack_data
	combo_index = next_combo_index
	current_phase = AttackPhase.STARTUP
	
	var attack_speed: float = 1.0
	var stance_dmg: float = 1.0
	var stance_poise: float = 1.0
	var stance: StanceController = _get_stance_controller()
	if stance != null:
		attack_speed *= stance.get_attack_speed_multiplier()
		stance_dmg = stance.get_damage_multiplier()
		stance_poise = stance.get_poise_damage_multiplier()
	
	var trans_dmg: float = 1.0
	var trans_poise: float = 1.0
	var trans_hitstop: float = 1.0
	var trans: TransformationController = _get_transformation_controller()
	if trans != null:
		attack_speed *= trans.get_attack_speed_multiplier()
		trans_dmg = trans.get_damage_multiplier()
		trans_poise = trans.get_poise_damage_multiplier()
		trans_hitstop = trans.get_hitstop_multiplier()
	
	phase_timer = attack_data.startup_time / attack_speed
	combo_timer = 0.0
	has_buffered_attack = false
	buffered_is_heavy = false
	_input_buffer_timer = 0.0
	is_combo_window_open = false
	
	if hitbox != null:
		hitbox.deactivate()
		hitbox.damage_multiplier = charge_multiplier
		hitbox.poise_multiplier = poise_charge_multiplier
		hitbox.stance_damage_multiplier = stance_dmg
		hitbox.stance_poise_multiplier = stance_poise
		hitbox.transformation_damage_multiplier = trans_dmg
		hitbox.transformation_poise_multiplier = trans_poise
		hitbox.transformation_hitstop_multiplier = trans_hitstop
		_update_hitbox_facing()
	
	# Apply forward movement impulse
	if player != null and attack_data.forward_impulse > 0.0:
		var facing: int = player.get_facing_direction() if player.has_method("get_facing_direction") else 1
		player.velocity.x += attack_data.forward_impulse * float(facing)
	
	# Notify animation controller
	_notify_animation_start(attack_data.attack_id)
	
	attack_started.emit(attack_data)
	attack_phase_changed.emit(current_phase)
	return true

func process_combat(delta: float) -> bool:
	if not is_attacking() or is_charging_heavy:
		return false
	
	combo_timer += delta
	phase_timer -= delta
	
	# Countdown input buffer timer
	if _input_buffer_timer > 0.0:
		_input_buffer_timer -= delta
		if _input_buffer_timer <= 0.0:
			has_buffered_attack = false
	
	# Check combo continuation window
	_update_combo_window()
	
	# Capture inputs from hardware
	_check_input_buffering()
	
	# Handle phase transitions and time rollover
	while is_attacking() and phase_timer <= 0.0:
		var overflow: float = -phase_timer
		var attack_speed: float = 1.0
		var stance_dmg: float = 1.0
		var stance_poise: float = 1.0
		var stance: StanceController = _get_stance_controller()
		if stance != null:
			attack_speed *= stance.get_attack_speed_multiplier()
			stance_dmg = stance.get_damage_multiplier()
			stance_poise = stance.get_poise_damage_multiplier()
		
		var trans_dmg: float = 1.0
		var trans_poise: float = 1.0
		var trans_hitstop: float = 1.0
		var trans: TransformationController = _get_transformation_controller()
		if trans != null:
			attack_speed *= trans.get_attack_speed_multiplier()
			trans_dmg = trans.get_damage_multiplier()
			trans_poise = trans.get_poise_damage_multiplier()
			trans_hitstop = trans.get_hitstop_multiplier()
		
		match current_phase:
			AttackPhase.STARTUP:
				current_phase = AttackPhase.ACTIVE
				phase_timer = (current_attack.active_time / attack_speed) - overflow
				if hitbox != null:
					_update_hitbox_facing()
					hitbox.damage_multiplier = charge_multiplier
					hitbox.poise_multiplier = poise_charge_multiplier
					hitbox.stance_damage_multiplier = stance_dmg
					hitbox.stance_poise_multiplier = stance_poise
					hitbox.transformation_damage_multiplier = trans_dmg
					hitbox.transformation_poise_multiplier = trans_poise
					hitbox.transformation_hitstop_multiplier = trans_hitstop
					hitbox.activate(current_attack, player)
				attack_phase_changed.emit(current_phase)
			
			AttackPhase.ACTIVE:
				current_phase = AttackPhase.RECOVERY
				phase_timer = (current_attack.recovery_time / attack_speed) - overflow
				if hitbox != null:
					hitbox.deactivate()
				attack_phase_changed.emit(current_phase)
				
				# Chain immediately if next attack was buffered
				if has_buffered_attack:
					return _consume_buffered_attack()
			
			AttackPhase.RECOVERY:
				if has_buffered_attack:
					return _consume_buffered_attack()
				
				finish_combat()
				return false
	
	# If in RECOVERY and an attack is buffered, chain immediately
	if current_phase == AttackPhase.RECOVERY and has_buffered_attack:
		return _consume_buffered_attack()
	
	return true

func _get_stance_controller() -> StanceController:
	if player != null and player.has_node("Components/StanceController"):
		return player.get_node("Components/StanceController") as StanceController
	return null

func _get_transformation_controller() -> TransformationController:
	if player != null and player.has_node("Components/TransformationController"):
		return player.get_node("Components/TransformationController") as TransformationController
	return null

func _consume_buffered_attack() -> bool:
	has_buffered_attack = false
	_input_buffer_timer = 0.0
	
	if buffered_is_heavy:
		return start_heavy_attack()
	
	if current_attack != null and not current_attack.next_attack_id.is_empty():
		var next_id: StringName = current_attack.next_attack_id
		if _attacks.has(next_id):
			return _execute_attack(_attacks[next_id], combo_index + 1)
	
	finish_combat()
	return false

func _update_combo_window() -> void:
	if current_attack == null or current_attack.next_attack_id.is_empty():
		is_combo_window_open = false
		return
	
	is_combo_window_open = (combo_timer >= current_attack.combo_window_start and combo_timer <= current_attack.combo_window_end)

func _check_input_buffering() -> void:
	# Accept buffering during any active attack phase so player isn't penalized for attacking slightly early
	if Input.is_action_just_pressed(&"light_attack"):
		buffer_attack(false)
	elif Input.is_action_just_pressed(&"heavy_attack"):
		buffer_attack(true)

func buffer_attack(is_heavy: bool) -> void:
	has_buffered_attack = true
	buffered_is_heavy = is_heavy
	_input_buffer_timer = INPUT_BUFFER_DURATION

func _update_hitbox_facing() -> void:
	if hitbox == null or player == null:
		return
	
	var facing: int = player.get_facing_direction() if player.has_method("get_facing_direction") else 1
	var base_offset_x: float = 28.0
	hitbox.position = Vector2(base_offset_x * float(facing), -22.0)

func finish_combat() -> void:
	current_phase = AttackPhase.NONE
	current_attack = null
	combo_index = 0
	has_buffered_attack = false
	_input_buffer_timer = 0.0
	is_combo_window_open = false
	is_charging_heavy = false
	charge_multiplier = 1.0
	poise_charge_multiplier = 1.0
	
	if hitbox != null:
		hitbox.deactivate()
	
	attack_finished.emit()

func cancel_combat() -> void:
	finish_combat()

func _notify_animation_start(attack_id: StringName) -> void:
	if player != null and player.has_node("Components/PlayerAnimationController"):
		var anim: Node = player.get_node("Components/PlayerAnimationController")
		if anim != null and anim.has_method("play_attack_animation"):
			anim.play_attack_animation(attack_id)

func _notify_animation_charge() -> void:
	if player != null and player.has_node("Components/PlayerAnimationController"):
		var anim: Node = player.get_node("Components/PlayerAnimationController")
		if anim != null and anim.has_method("play_charge_animation"):
			anim.play_charge_animation()

func _on_hitbox_connected(target_hurtbox: Area2D, damage_info: DamageInfo) -> void:
	attack_hit_connected.emit(target_hurtbox, damage_info)
