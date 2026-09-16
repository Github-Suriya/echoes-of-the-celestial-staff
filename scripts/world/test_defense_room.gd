class_name TestDefenseRoom
extends Node2D

## TestDefenseRoom
## Sandbox arena for testing and practicing defensive techniques:
## Ground Dodge (I-frames & Perfect Dodge), Ground Parry (deflection & Perfect Parry),
## Attack Interruption, Charged Heavy Attacks, and Aerial Strikes.

@onready var player: PlayerController = $Player
@onready var attacker: CombatTrainingAttacker = $CombatTrainingAttacker
@onready var dummy: CombatTestDummy = $CombatTestDummy

func _ready() -> void:
	if has_node("/root/GameManager"):
		var gm: Node = get_node("/root/GameManager")
		if gm != null and gm.has_method("set_game_state"):
			gm.set_game_state(2) # GameState.PLAYING
	
	if has_node("/root/DebugManager"):
		var dm: Node = get_node("/root/DebugManager")
		if dm != null and dm.has_method("log_info"):
			dm.log_info("Defense Test Room initialized.", "WORLD")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			if attacker != null:
				attacker.reset_attacker()
			if dummy != null:
				dummy.reset_dummy()
		elif event.keycode == KEY_T:
			if attacker != null:
				attacker.trigger_attack()
		elif event.keycode == KEY_Y:
			if attacker != null:
				attacker.auto_attack = not attacker.auto_attack
