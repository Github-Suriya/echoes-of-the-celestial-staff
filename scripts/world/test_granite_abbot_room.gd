class_name TestGraniteAbbotRoom
extends Node2D

## TestGraniteAbbotRoom
## Interactive test arena for Phase 9 Boss Framework & The Granite Abbot Prototype:
## - Enclosed arena with dynamic physical barriers (Left/Right)
## - Entry detection trigger activating encounter, arena lock, and boss intro
## - Multi-phase boss AI with readable telegraph cues
## - Perfect parry deflection and posture stagger windows
## - Idempotent 50% HP Phase 2 transition
## - Boss defeat unlocking barriers and dismissive HUD
## - Comprehensive debug shortcuts: [R] Reset, [T] Spirit, [C] Stance, [F] Awakening, [B] Force Phase 2

@onready var player: PlayerController = $Player
@onready var boss: BossController = $GraniteAbbot
@onready var arena_controller: BossArenaController = $BossArenaController
@onready var boss_hud: BossHealthBar = $BossHealthBar
@onready var spirit_hud: SpiritHUD = $SpiritHUD

func _ready() -> void:
	if has_node("/root/GameManager"):
		var gm: Node = get_node("/root/GameManager")
		if gm != null and gm.has_method("set_game_state"):
			gm.set_game_state(2) # GameState.PLAYING
	
	if has_node("/root/DebugManager"):
		var dm: Node = get_node("/root/DebugManager")
		if dm != null and dm.has_method("log_info"):
			dm.log_info("Granite Abbot Boss Room initialized.", "WORLD")
	
	if spirit_hud != null and player != null:
		spirit_hud.bind_player(player)
	
	if boss_hud != null and boss != null:
		boss_hud.bind_boss(boss)
	
	if arena_controller != null:
		arena_controller.boss = boss
		arena_controller.player = player
		arena_controller.boss_hud = boss_hud

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	
	match event.keycode:
		KEY_R:
			_reset_encounter()
		KEY_T:
			_restore_player_spirit()
		KEY_C:
			_cycle_player_stance()
		KEY_F:
			_trigger_awakening()
		KEY_B:
			_force_boss_phase_transition()

func _reset_encounter() -> void:
	if arena_controller != null:
		arena_controller.reset_encounter()
	if player != null:
		if player.respawn_component != null:
			player.respawn_component.respawn()
		elif player.has_method("respawn"):
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
			stance_ctrl.cycle_stance()

func _trigger_awakening() -> void:
	if player != null and player.has_node("Components/TransformationController"):
		var trans: TransformationController = player.get_node("Components/TransformationController") as TransformationController
		if trans != null:
			trans.activate()

func _force_boss_phase_transition() -> void:
	if boss != null and boss.phase_controller != null:
		boss.phase_controller.trigger_phase_transition(1)
