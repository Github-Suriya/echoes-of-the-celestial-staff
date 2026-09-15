class_name PlayerState
extends State

## PlayerState
## Base state for all Player locomotion and action states.
## Provides safe references to PlayerController and PlayerMovement.

var player: CharacterBody2D = null

func _ready() -> void:
	# Obtain owner reference when scene is mounted
	if owner != null and owner is CharacterBody2D:
		player = owner as CharacterBody2D

func get_movement() -> Node:
	if player != null and player.has_node("Components/PlayerMovement"):
		return player.get_node("Components/PlayerMovement")
	return null
