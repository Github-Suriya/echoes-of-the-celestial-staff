class_name BossState
extends State

## BossState
## Base state node for boss states in the StateMachine hierarchy.

var boss: BossController = null

func _ready() -> void:
	if owner is BossController:
		boss = owner as BossController

func set_state_machine(sm: Node) -> void:
	super.set_state_machine(sm)
	if boss == null and owner is BossController:
		boss = owner as BossController

func get_state_name() -> StringName:
	return name

func physics_update(delta: float) -> void:
	physics_process_state(delta)

func physics_process_state(_delta: float) -> void:
	pass
