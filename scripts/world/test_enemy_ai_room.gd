class_name TestEnemyAIRoom
extends Node2D

## TestEnemyAIRoom
## Interactive test arena for Phase 8 Enemy AI Foundation:
## - Autonomous patrol, detection, alert, chase, and combat positioning
## - Real-time attack lifecycle, active hitbox windows, and cooldown enforcement
## - Defensive parrying, perfect parry interruption, and dodges
## - Poise depletion, stagger state, and idempotent death
## - Multi-enemy independence and concurrent execution.

@onready var player: PlayerController = $Player
@onready var guard1: EnemyController = $CelestialGuard1
@onready var guard2: EnemyController = $CelestialGuard2
@onready var spirit_hud: SpiritHUD = $SpiritHUD

func _ready() -> void:
	if has_node("/root/GameManager"):
		var gm: Node = get_node("/root/GameManager")
		if gm != null and gm.has_method("set_game_state"):
			gm.set_game_state(2) # GameState.PLAYING
	
	if has_node("/root/DebugManager"):
		var dm: Node = get_node("/root/DebugManager")
		if dm != null and dm.has_method("log_info"):
			dm.log_info("Enemy AI Test Room initialized with 2 Celestial Guards.", "WORLD")
	
	if spirit_hud != null and player != null:
		spirit_hud.bind_player(player)

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	
	match event.keycode:
		KEY_R:
			_reset_entities()
		KEY_T:
			_restore_player_spirit()
		KEY_C:
			_cycle_player_stance()
		KEY_F:
			_trigger_awakening()

func _trigger_awakening() -> void:
	if player != null and player.has_node("Components/TransformationController"):
		var trans: TransformationController = player.get_node("Components/TransformationController") as TransformationController
		if trans != null:
			trans.activate()

func _reset_entities() -> void:
	if guard1 != null:
		guard1.reset_enemy()
	if guard2 != null:
		guard2.reset_enemy()
	if player != null:
		player.respawn()

func _restore_player_spirit() -> void:
	if player != null and player.has_node("Components/SpiritComponent"):
		var sc: SpiritComponent = player.get_node("Components/SpiritComponent") as SpiritComponent
		if sc != null:
			sc.restore_spirit(100.0)

func _cycle_player_stance() -> void:
	if player != null and player.has_node("Components/StanceController"):
		var stance_ctrl: StanceController = player.get_node("Components/StanceController") as StanceController
		if stance_ctrl != null:
			stance_ctrl.cycle_next_stance()
