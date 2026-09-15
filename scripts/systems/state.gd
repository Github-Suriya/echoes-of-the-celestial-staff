class_name State
extends Node

## State
## Abstract base class for hierarchical state machine nodes.
## Subclasses override enter, exit, update, physics_update, and handle_input.

var state_machine: Node = null

func set_state_machine(sm: Node) -> void:
	state_machine = sm

func enter() -> void:
	pass

func exit() -> void:
	pass

func update(_delta: float) -> void:
	pass

func physics_update(_delta: float) -> void:
	pass

func handle_input(_event: InputEvent) -> void:
	pass
