class_name TestCombatRoom
extends Node2D

## TestCombatRoom
## Sandbox arena for evaluating combat feel, light combo strings, heavy attacks,
## hit detection, poise depletion, stagger, knockback, and hitstop.

@onready var player: PlayerController = $Player
@onready var dummy: CombatTestDummy = $CombatTestDummy

func _ready() -> void:
	if has_node("/root/GameManager"):
		var gm: Node = get_node("/root/GameManager")
		if gm != null and gm.has_method("set_game_state"):
			gm.set_game_state(2) # GameState.PLAYING
	
	if has_node("/root/DebugManager"):
		var dm: Node = get_node("/root/DebugManager")
		if dm != null and dm.has_method("log_info"):
			dm.log_info("Combat Test Room initialized.", "WORLD")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			if dummy != null:
				dummy.reset_dummy()
