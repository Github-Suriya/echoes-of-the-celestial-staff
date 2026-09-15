class_name TestPlayerRoom
extends Node2D

## TestPlayerRoom
## Interactive testbed designed to test all 2D player locomotion mechanics:
## walking, acceleration, short jumps, high jumps, gaps, ledges, and out-of-bounds respawn.

@onready var spawn_point: Marker2D = $SpawnPoint
@onready var player: CharacterBody2D = $Player

func _ready() -> void:
	if has_node("/root/GameManager"):
		var gm: Node = get_node("/root/GameManager")
		if gm != null and gm.has_method("set_game_state"):
			gm.set_game_state(2) # 2 = PLAYING
	
	if player != null and spawn_point != null:
		player.global_position = spawn_point.global_position
		if player.has_node("Components/PlayerRespawn"):
			var respawn: Node = player.get_node("Components/PlayerRespawn")
			if respawn != null and respawn.has_method("set_spawn_position"):
				respawn.call("set_spawn_position", spawn_point.global_position)
