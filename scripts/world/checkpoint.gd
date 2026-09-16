class_name Checkpoint
extends Area2D

## Checkpoint
## Metroidvania Spirit Shrine checkpoint foundation.
## Activates upon player contact, sets the respawn location,
## restores player Health and Spirit, and persists state in WorldState.

signal activated(checkpoint_id: StringName)

@export var checkpoint_id: StringName = &""
@export var room_id: StringName = &""
@export var spawn_point_id: StringName = &""
@export var is_active: bool = false

@onready var visual_indicator: CanvasItem = $VisualIndicator if has_node("VisualIndicator") else null

const COLOR_INACTIVE: Color = Color(0.2, 0.6, 0.5, 0.6) # Jade glow
const COLOR_ACTIVE: Color = Color(0.95, 0.77, 0.2, 1.0)   # Radiant gold

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 # Player collision layer
	
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	
	_update_visuals()

func activate(player: Node2D = null) -> void:
	is_active = true
	_update_visuals()
	
	# Coordinate with WorldController if present
	var wc: Node = _get_world_controller()
	if wc != null:
		if wc.has_method("set_active_checkpoint"):
			wc.set_active_checkpoint(room_id, spawn_point_id)
		if "world_state" in wc and wc.world_state != null:
			var flag: StringName = StringName("checkpoint_active_%s" % checkpoint_id)
			wc.world_state.set_flag(flag, true)
	
	# Restore player stats upon resting at shrine
	if player != null:
		_restore_player(player)
	
	# Emit signals
	activated.emit(checkpoint_id)
	
	var bus: Node = _get_event_bus()
	if bus != null and bus.has_signal("checkpoint_activated"):
		bus.checkpoint_activated.emit(String(checkpoint_id))

func apply_state(state: WorldState) -> void:
	if state == null or checkpoint_id.is_empty():
		return
	var flag: StringName = StringName("checkpoint_active_%s" % checkpoint_id)
	is_active = state.get_flag(flag, is_active)
	_update_visuals()

func record_state(state: WorldState) -> void:
	if state == null or checkpoint_id.is_empty():
		return
	var flag: StringName = StringName("checkpoint_active_%s" % checkpoint_id)
	state.set_flag(flag, is_active)

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D or body.name == "Player":
		activate(body)

func _restore_player(player: Node2D) -> void:
	if player.has_node("Components/HealthComponent"):
		var hc: Node = player.get_node("Components/HealthComponent")
		if hc != null:
			if hc.has_method("heal") and "max_health" in hc:
				hc.heal(hc.max_health)
			elif hc.has_method("restore_health") and "max_health" in hc:
				hc.restore_health(hc.max_health)
	
	if player.has_node("Components/SpiritComponent"):
		var sc: Node = player.get_node("Components/SpiritComponent")
		if sc != null and sc.has_method("restore_spirit") and "max_spirit" in sc:
			sc.restore_spirit(sc.max_spirit)

func _update_visuals() -> void:
	if visual_indicator != null:
		visual_indicator.modulate = COLOR_ACTIVE if is_active else COLOR_INACTIVE

func _get_world_controller() -> Node:
	var curr: Node = get_parent()
	while curr != null:
		if curr.has_method("set_active_checkpoint"):
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
