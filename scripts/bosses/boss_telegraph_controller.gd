class_name BossTelegraphController
extends Node2D

## BossTelegraphController
## Renders lightweight, readable procedural visual telegraphs for boss attacks.
## Communicates danger timing, shape, and direction to give the player clear windows
## for dodge, perfect dodge, parry, and repositioning without expensive particle systems.

@export var default_telegraph_color: Color = Color(1.0, 0.75, 0.1, 0.85)

var _is_telegraphing: bool = false
var _active_tween: Tween = null
var _current_attack: EnemyAttackData = null
var _facing: int = 1
var _telegraph_progress: float = 0.0
var _telegraph_duration: float = 0.5

# Visual shape elements
var _staff_glow: ColorRect = null
var _warning_shape: ColorRect = null
var _ground_marker: ColorRect = null
var _direction_arrow: Label = null

func _ready() -> void:
	_create_procedural_nodes()
	stop_telegraph()

func _create_procedural_nodes() -> void:
	# Warning shape (sweep / slam / thrust indicator)
	_warning_shape = ColorRect.new()
	_warning_shape.name = "WarningShape"
	_warning_shape.color = default_telegraph_color
	_warning_shape.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_warning_shape.visible = false
	add_child(_warning_shape)
	
	# Staff glow cue
	_staff_glow = ColorRect.new()
	_staff_glow.name = "StaffGlow"
	_staff_glow.color = Color(1.0, 1.0, 0.6, 0.9)
	_staff_glow.size = Vector2(8.0, 8.0)
	_staff_glow.position = Vector2(24.0, -32.0)
	_staff_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_staff_glow.visible = false
	add_child(_staff_glow)
	
	# Ground marker for shockwaves
	_ground_marker = ColorRect.new()
	_ground_marker.name = "GroundMarker"
	_ground_marker.color = Color(1.0, 0.2, 0.1, 0.6)
	_ground_marker.size = Vector2(80.0, 6.0)
	_ground_marker.position = Vector2(-40.0, 0.0)
	_ground_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ground_marker.visible = false
	add_child(_ground_marker)
	
	# Direction arrow cue
	_direction_arrow = Label.new()
	_direction_arrow.name = "DirectionIndicator"
	_direction_arrow.text = "!"
	_direction_arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_direction_arrow.position = Vector2(-10.0, -56.0)
	_direction_arrow.visible = false
	add_child(_direction_arrow)

func start_telegraph(attack_data: EnemyAttackData, facing: int = 1, duration: float = 0.5, tint: Color = Color.TRANSPARENT) -> void:
	stop_telegraph()
	
	_is_telegraphing = true
	_current_attack = attack_data
	_facing = facing
	_telegraph_duration = maxf(0.05, duration)
	_telegraph_progress = 0.0
	
	var col: Color = tint if tint != Color.TRANSPARENT else default_telegraph_color
	
	# Staff glow
	if _staff_glow != null:
		_staff_glow.position = Vector2(24.0 * float(facing) - 4.0, -32.0)
		_staff_glow.color = Color(col.r, col.g, col.b, 0.9)
		_staff_glow.visible = true
	
	# Warning shape position & size
	if _warning_shape != null:
		var shape_size: Vector2 = Vector2(60.0, 24.0)
		var shape_offset: Vector2 = Vector2(30.0, -18.0)
		
		if attack_data is BossAttackData:
			var bad: BossAttackData = attack_data as BossAttackData
			shape_size = bad.telegraph_shape_size
			shape_offset = bad.hitbox_offset
		elif attack_data != null:
			shape_size = attack_data.hitbox_size
			shape_offset = attack_data.hitbox_offset
		
		_warning_shape.size = shape_size
		_warning_shape.position = Vector2(
			(shape_offset.x * float(facing)) - (shape_size.x * 0.5),
			shape_offset.y - (shape_size.y * 0.5)
		)
		_warning_shape.color = Color(col.r, col.g, col.b, 0.25)
		_warning_shape.visible = true
	
	# Shockwave ground marker
	if _ground_marker != null:
		if attack_data is BossAttackData and (attack_data as BossAttackData).ground_marker_radius > 0.0:
			var rad: float = (attack_data as BossAttackData).ground_marker_radius
			_ground_marker.size = Vector2(rad * 2.0, 8.0)
			_ground_marker.position = Vector2(-rad, -4.0)
			_ground_marker.color = Color(col.r, col.g, col.b, 0.3)
			_ground_marker.visible = true
		else:
			_ground_marker.visible = false
	
	# Warning exclamation
	if _direction_arrow != null:
		_direction_arrow.modulate = col
		_direction_arrow.visible = true
	
	# Tween pulse towards full opacity as danger approaches
	if _active_tween != null and _active_tween.is_valid():
		_active_tween.kill()
	
	_active_tween = create_tween()
	if _active_tween != null:
		_active_tween.set_parallel(true)
		if _warning_shape != null:
			_active_tween.tween_property(_warning_shape, "color:a", 0.75, _telegraph_duration).from(0.25)
		if _ground_marker != null and _ground_marker.visible:
			_active_tween.tween_property(_ground_marker, "color:a", 0.85, _telegraph_duration).from(0.3)
		if _staff_glow != null:
			_active_tween.tween_property(_staff_glow, "scale", Vector2(1.6, 1.6), _telegraph_duration).from(Vector2(1.0, 1.0))

func stop_telegraph() -> void:
	_is_telegraphing = false
	_current_attack = null
	
	if _active_tween != null and _active_tween.is_valid():
		_active_tween.kill()
		_active_tween = null
	
	if _staff_glow != null:
		_staff_glow.visible = false
		_staff_glow.scale = Vector2.ONE
	if _warning_shape != null:
		_warning_shape.visible = false
	if _ground_marker != null:
		_ground_marker.visible = false
	if _direction_arrow != null:
		_direction_arrow.visible = false

func is_telegraphing() -> bool:
	return _is_telegraphing
