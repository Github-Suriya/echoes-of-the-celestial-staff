class_name TestSpiritRoom
extends Node2D

## TestSpiritRoom
## Testing sandbox for Phase 6 Spirit Abilities:
## - Celestial Arc (horizontal projectile, single hit per target)
## - Heavenly Pulse (360-degree AoE, multiple target hurtbox detection)
## - Cloud Step (directional velocity burst, solid obstacle collision preservation)
## - Spirit resource management and combat-driven spirit restoration.

@onready var player: PlayerController = $Player
@onready var attacker: CombatTrainingAttacker = $CombatTrainingAttacker
@onready var dummy1: CombatTestDummy = $CombatTestDummy1
@onready var dummy2: CombatTestDummy = $CombatTestDummy2
@onready var dummy3: CombatTestDummy = $CombatTestDummy3
@onready var spirit_hud: SpiritHUD = $SpiritHUD

func _ready() -> void:
	if has_node("/root/GameManager"):
		var gm: Node = get_node("/root/GameManager")
		if gm != null and gm.has_method("set_game_state"):
			gm.set_game_state(2) # GameState.PLAYING
	
	if has_node("/root/DebugManager"):
		var dm: Node = get_node("/root/DebugManager")
		if dm != null and dm.has_method("log_info"):
			dm.log_info("Spirit Abilities Test Room initialized.", "WORLD")
	
	if spirit_hud != null and player != null:
		spirit_hud.bind_player(player)

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	
	match event.keycode:
		KEY_R:
			_reset_sandbox_entities()
		KEY_T:
			_restore_player_spirit()
		KEY_C:
			_cycle_player_stance()
		KEY_Y:
			if attacker != null:
				attacker.auto_attack = not attacker.auto_attack

func _reset_sandbox_entities() -> void:
	if dummy1 != null:
		dummy1.reset_dummy()
	if dummy2 != null:
		dummy2.reset_dummy()
	if dummy3 != null:
		dummy3.reset_dummy()
	if attacker != null:
		attacker.reset_attacker()

func _restore_player_spirit() -> void:
	if player != null and player.has_node("Components/SpiritComponent"):
		var spirit_comp: SpiritComponent = player.get_node("Components/SpiritComponent") as SpiritComponent
		if spirit_comp != null:
			spirit_comp.reset_spirit()

func _cycle_player_stance() -> void:
	if player != null and player.has_node("Components/StanceController"):
		var stance_ctrl: StanceController = player.get_node("Components/StanceController") as StanceController
		if stance_ctrl != null:
			stance_ctrl.cycle_stance()
