class_name CameraShakeController
extends Node

## CameraShakeController
## Lightweight, bounded trauma-based camera shake feedback system.
## Responds to combat impacts, parry deflections, boss slams, and phase transitions.
## Adheres to room bounding boxes without permanent shake or player disorientation.

@export var camera: Camera2D = null
@export var trauma_decay: float = 1.8
@export var max_offset: Vector2 = Vector2(14.0, 8.0)
@export var max_roll: float = 0.03

var _trauma: float = 0.0
var _base_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	if camera == null and owner != null and owner.has_node("Camera2D"):
		camera = owner.get_node("Camera2D") as Camera2D
	
	if camera != null:
		_base_offset = camera.offset
	
	_connect_event_bus()

func _process(delta: float) -> void:
	if camera == null:
		return
	
	if _trauma > 0.0:
		_trauma = maxf(0.0, _trauma - trauma_decay * delta)
		var shake: float = _trauma * _trauma # Quadratic curve for organic feel
		
		var offset_x: float = randf_range(-1.0, 1.0) * max_offset.x * shake
		var offset_y: float = randf_range(-1.0, 1.0) * max_offset.y * shake
		var roll: float = randf_range(-1.0, 1.0) * max_roll * shake
		
		# Respect owner lookahead if present on camera
		var lookahead_x: float = 0.0
		if owner != null and "camera" in owner and owner.camera == camera:
			lookahead_x = camera.offset.x - _base_offset.x
		
		camera.offset = _base_offset + Vector2(lookahead_x + offset_x, offset_y)
		camera.rotation = roll
	else:
		if camera.rotation != 0.0:
			camera.rotation = 0.0

func add_trauma(amount: float) -> void:
	_trauma = clampf(_trauma + amount, 0.0, 1.0)

func get_trauma() -> float:
	return _trauma

# -------------------------------------------------------------------------
# Preset Camera Profiles
# -------------------------------------------------------------------------

func shake_normal_hit() -> void:
	add_trauma(0.18)

func shake_heavy_impact() -> void:
	add_trauma(0.36)

func shake_perfect_parry() -> void:
	add_trauma(0.32)

func shake_boss_slam() -> void:
	add_trauma(0.50)

func shake_boss_phase_transition() -> void:
	add_trauma(0.65)

func shake_final_boss_death() -> void:
	add_trauma(0.80)

# -------------------------------------------------------------------------
# EventBus Integration
# -------------------------------------------------------------------------

func _connect_event_bus() -> void:
	if not has_node("/root/EventBus"):
		return
	var bus: Node = get_node("/root/EventBus")
	if bus == null:
		return
	
	if bus.has_signal("damage_dealt") and not bus.damage_dealt.is_connected(_on_damage_dealt):
		bus.damage_dealt.connect(_on_damage_dealt)
	if bus.has_signal("perfect_parry") and not bus.perfect_parry.is_connected(_on_perfect_parry):
		bus.perfect_parry.connect(_on_perfect_parry)
	if bus.has_signal("boss_phase_changed") and not bus.boss_phase_changed.is_connected(_on_boss_phase_changed):
		bus.boss_phase_changed.connect(_on_boss_phase_changed)
	if bus.has_signal("boss_defeated") and not bus.boss_defeated.is_connected(_on_boss_defeated):
		bus.boss_defeated.connect(_on_boss_defeated)

func _on_damage_dealt(_target: Node2D, amount: float, is_critical: bool) -> void:
	if is_critical or amount >= 25.0:
		shake_heavy_impact()
	else:
		shake_normal_hit()

func _on_perfect_parry(_defender: Node2D, _attacker: Node2D) -> void:
	shake_perfect_parry()

func _on_boss_phase_changed(_boss_id: StringName, _phase_id: int) -> void:
	shake_boss_phase_transition()

func _on_boss_defeated(boss_name: String) -> void:
	if boss_name == "Corrupted Forest Heart":
		shake_final_boss_death()
	else:
		shake_heavy_impact()
