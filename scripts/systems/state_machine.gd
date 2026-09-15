class_name StateMachine
extends Node

## StateMachine
## Generic, hierarchical node-based state machine.
## Child nodes that extend State are indexed and managed.

signal state_changed(old_state_name: StringName, new_state_name: StringName)

@export var initial_state_name: StringName = &"Idle"

var current_state: State = null
var previous_state: State = null

var _states: Dictionary = {} # Dictionary[StringName, State]

func _ready() -> void:
	# Index all child State nodes
	for child in get_children():
		if child is State:
			register_state(child.name, child)
	
	if not initial_state_name.is_empty():
		call_deferred("_enter_initial_state")

func register_state(state_name: StringName, state_node: State) -> void:
	_states[state_name] = state_node
	state_node.set_state_machine(self)

func _enter_initial_state() -> void:
	if _states.has(initial_state_name):
		change_state(initial_state_name)
	elif _states.size() > 0:
		var first_name: StringName = _states.keys()[0]
		change_state(first_name)

func change_state(target_state_name: StringName) -> bool:
	if not _states.has(target_state_name):
		push_warning("[StateMachine] State not found: %s" % target_state_name)
		return false
	
	var next_state: State = _states[target_state_name]
	if current_state == next_state:
		return false
	
	var old_name: StringName = current_state.name if current_state != null else &""
	
	if current_state != null:
		current_state.exit()
	
	previous_state = current_state
	current_state = next_state
	current_state.enter()
	
	state_changed.emit(old_name, target_state_name)
	return true

func get_current_state_name() -> StringName:
	return current_state.name if current_state != null else &""

func has_state(state_name: StringName) -> bool:
	return _states.has(state_name)

func _process(delta: float) -> void:
	if current_state != null:
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	if current_state != null:
		current_state.physics_update(delta)

func _unhandled_input(event: InputEvent) -> void:
	if current_state != null:
		current_state.handle_input(event)
