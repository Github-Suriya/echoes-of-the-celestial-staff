class_name PlayerController
extends CharacterBody2D

## PlayerController
## Root orchestrator for the player character Yuan.
## Coordinates locomotion components, combat components, facing direction, camera look-ahead, and state machine.

signal facing_direction_changed(new_direction: int)

@export var movement_config: PlayerMovementConfig

var facing_direction: int = 1 # 1 = Right, -1 = Left

@onready var movement: PlayerMovement = $Components/PlayerMovement
@onready var animation_controller: PlayerAnimationController = $Components/PlayerAnimationController
@onready var respawn_component: PlayerRespawn = $Components/PlayerRespawn
@onready var combat_controller: CombatController = $Components/CombatController if has_node("Components/CombatController") else null
@onready var defense_controller: DefenseController = $Components/DefenseController if has_node("Components/DefenseController") else null
@onready var stance_controller: StanceController = $Components/StanceController if has_node("Components/StanceController") else null
@onready var spirit_component: SpiritComponent = $Components/SpiritComponent if has_node("Components/SpiritComponent") else null
@onready var spirit_ability_controller: SpiritAbilityController = $Components/SpiritAbilityController if has_node("Components/SpiritAbilityController") else null
@onready var health_component: HealthComponent = $Components/HealthComponent if has_node("Components/HealthComponent") else null
@onready var poise_component: PoiseComponent = $Components/PoiseComponent if has_node("Components/PoiseComponent") else null
@onready var state_machine: StateMachine = $StateMachine
@onready var visuals: Node2D = $Visuals
@onready var camera: Camera2D = $Camera2D

var _target_camera_offset_x: float = 0.0

func _ready() -> void:
	# Pass movement config down if specified on controller
	if movement_config != null and movement != null:
		movement.config = movement_config
	
	# Register in EventBus
	if has_node("/root/EventBus"):
		var bus: Node = get_node("/root/EventBus")
		if bus != null and bus.has_signal("player_spawned"):
			bus.player_spawned.emit(self)

func _physics_process(delta: float) -> void:
	# Verify game is actively playing (respects Pause, Cutscene, Loading)
	if not _is_gameplay_active():
		return
	
	# Execute locomotion calculations if not locked in committed attack
	if movement != null:
		movement.process_physics(self, delta)
		
		# Update horizontal facing direction only when not actively attacking
		var is_attacking: bool = combat_controller != null and combat_controller.is_attacking()
		if not is_attacking:
			if movement.current_move_axis > 0.05:
				set_facing_direction(1)
			elif movement.current_move_axis < -0.05:
				set_facing_direction(-1)
	
	# Camera horizontal look-ahead lead
	_update_camera_lead(delta)
	
	# Out-of-bounds check
	if respawn_component != null:
		respawn_component.check_boundaries()

func set_facing_direction(dir: int) -> void:
	var new_dir: int = 1 if dir >= 0 else -1
	if facing_direction == new_dir:
		return
	
	facing_direction = new_dir
	
	# Flip visual elements without affecting collision shape
	if visuals != null:
		visuals.scale.x = float(facing_direction)
	
	# Align combat hitbox position with facing
	if combat_controller != null and combat_controller.hitbox != null:
		combat_controller.hitbox.position.x = 28.0 * float(facing_direction)
	
	facing_direction_changed.emit(facing_direction)

func get_facing_direction() -> int:
	return facing_direction

func is_facing_left() -> bool:
	return facing_direction == -1

func is_facing_right() -> bool:
	return facing_direction == 1

func _update_camera_lead(delta: float) -> void:
	if camera == null:
		return
	_target_camera_offset_x = float(facing_direction) * 45.0
	camera.offset.x = move_toward(camera.offset.x, _target_camera_offset_x, 150.0 * delta)

func _is_gameplay_active() -> bool:
	if has_node("/root/GameManager"):
		var gm: Node = get_node("/root/GameManager")
		if gm != null and gm.has_method("is_playing"):
			return gm.is_playing()
	return true
