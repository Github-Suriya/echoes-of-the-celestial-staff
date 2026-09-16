class_name EnemyState
extends State

## EnemyState
## Base state node for all enemy AI states in the hierarchical StateMachine.

var enemy: EnemyController = null

func _ready() -> void:
	if owner is EnemyController:
		enemy = owner as EnemyController

func set_state_machine(sm: Node) -> void:
	super.set_state_machine(sm)
	if enemy == null and owner is EnemyController:
		enemy = owner as EnemyController

func get_state_name() -> StringName:
	return name
