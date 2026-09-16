class_name AbilityGate
extends StaticBody2D

## AbilityGate
## Reusable progression barrier gating access to rooms and sub-sections.
## Queries PlayerCapabilities (e.g. Celestial Arc, Cloud Step) or WorldState flags.
## When unlocked, dissolves physical collision and records permanent open state.

signal gate_opened(gate_id: StringName)
signal gate_locked_attempt(gate_id: StringName, required_ability: StringName)

@export var gate_id: StringName = &""
@export var required_ability: StringName = &""
@export var required_flag: StringName = &""
@export var is_open: bool = false
@export var gate_name: String = "Ability Gate"

@onready var collision_shape: CollisionShape2D = $CollisionShape2D if has_node("CollisionShape2D") else null
@onready var visual_barrier: CanvasItem = $VisualBarrier if has_node("VisualBarrier") else null
@onready var trigger_area: Area2D = $TriggerArea if has_node("TriggerArea") else null

func _ready() -> void:
	collision_layer = 1 # World geometry layer
	collision_mask = 0
	
	if trigger_area != null:
		trigger_area.collision_layer = 0
		trigger_area.collision_mask = 2 # Player layer
		if not trigger_area.body_entered.is_connected(_on_trigger_body_entered):
			trigger_area.body_entered.connect(_on_trigger_body_entered)
	
	_update_gate_state(false)

func check_unlock(capabilities: PlayerCapabilities = null, world_state: WorldState = null) -> bool:
	if is_open:
		return true
	
	var can_open: bool = false
	
	# Check capability requirement if specified
	if not required_ability.is_empty():
		if capabilities != null and capabilities.has_ability(required_ability):
			can_open = true
		else:
			var wc: Node = _get_world_controller()
			if wc != null and "capabilities" in wc and wc.capabilities != null:
				if wc.capabilities.has_ability(required_ability):
					can_open = true
	
	# Check flag requirement if specified
	if not required_flag.is_empty():
		if world_state != null and world_state.has_flag(required_flag):
			can_open = true
		else:
			var wc: Node = _get_world_controller()
			if wc != null and "world_state" in wc and wc.world_state != null:
				if wc.world_state.has_flag(required_flag):
					can_open = true
	
	if can_open:
		open_gate()
		return true
	else:
		gate_locked_attempt.emit(gate_id, required_ability)
		return false

func open_gate(silent: bool = false) -> void:
	if is_open:
		return
	is_open = true
	_update_gate_state(not silent)
	
	var wc: Node = _get_world_controller()
	if wc != null and "world_state" in wc and wc.world_state != null:
		var flag: StringName = StringName("gate_opened_%s" % gate_id)
		wc.world_state.set_flag(flag, true)
	
	if not silent:
		gate_opened.emit(gate_id)
		var bus: Node = _get_event_bus()
		if bus != null and bus.has_signal("ability_gate_opened"):
			bus.ability_gate_opened.emit(gate_id)

func close_gate() -> void:
	is_open = false
	_update_gate_state(false)
	
	var wc: Node = _get_world_controller()
	if wc != null and "world_state" in wc and wc.world_state != null:
		var flag: StringName = StringName("gate_opened_%s" % gate_id)
		wc.world_state.set_flag(flag, false)

func apply_state(state: WorldState) -> void:
	if state == null or gate_id.is_empty():
		return
	var flag: StringName = StringName("gate_opened_%s" % gate_id)
	if state.has_flag(flag):
		if state.get_flag(flag):
			open_gate(true)
		else:
			close_gate()

func record_state(state: WorldState) -> void:
	if state == null or gate_id.is_empty():
		return
	var flag: StringName = StringName("gate_opened_%s" % gate_id)
	state.set_flag(flag, is_open)

func _update_gate_state(animate: bool = false) -> void:
	if is_open:
		set_collision_layer_value(1, false)
		if collision_shape != null:
			collision_shape.set_deferred("disabled", true)
		if visual_barrier != null:
			visual_barrier.visible = false
	else:
		set_collision_layer_value(1, true)
		if collision_shape != null:
			collision_shape.set_deferred("disabled", false)
		if visual_barrier != null:
			visual_barrier.visible = true

func _on_trigger_body_entered(body: Node2D) -> void:
	if is_open:
		return
	if body is CharacterBody2D or body.name == "Player":
		check_unlock()

func _get_world_controller() -> Node:
	var curr: Node = get_parent()
	while curr != null:
		if curr.has_method("request_room_transition") or "capabilities" in curr:
			return curr
		curr = curr.get_parent()
	return null

func _get_event_bus() -> Node:
	if Engine.has_singleton("EventBus"):
		return Engine.get_singleton("EventBus")
	var main_loop: MainLoop = Engine.get_main_loop()
	if main_loop is SceneTree:
		var root: Window = (main_loop as SceneTree).root
		if root != null and root.has_node("EventBus"):
			return root.get_node("EventBus")
	return null
