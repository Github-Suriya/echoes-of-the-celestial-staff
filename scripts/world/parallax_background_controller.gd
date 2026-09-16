class_name ParallaxBackgroundController
extends Node2D

## ParallaxBackgroundController
## Lightweight 2D multi-plane depth coordinator for Forbidden Forest rooms.
## Offsets Far (0.2x), Mid (0.5x), and Foreground (1.15x) layers relative to the active camera.
## Zero shader overhead, perfectly deterministic, adheres to room boundaries.

@export var far_layer: Node2D = null
@export var mid_layer: Node2D = null
@export var foreground_layer: Node2D = null

@export var far_factor: float = 0.20
@export var mid_factor: float = 0.50
@export var foreground_factor: float = 1.15

var _camera: Camera2D = null
var _initial_cam_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	if far_layer == null and has_node("BackgroundFar"):
		far_layer = get_node("BackgroundFar") as Node2D
	if mid_layer == null and has_node("BackgroundMid"):
		mid_layer = get_node("BackgroundMid") as Node2D
	if foreground_layer == null and has_node("Foreground"):
		foreground_layer = get_node("Foreground") as Node2D

func _process(_delta: float) -> void:
	if _camera == null:
		_find_active_camera()
		if _camera != null:
			_initial_cam_pos = _camera.global_position
		return
	
	var cam_offset: Vector2 = _camera.global_position - _initial_cam_pos
	
	if far_layer != null:
		far_layer.position.x = -cam_offset.x * (1.0 - far_factor)
	if mid_layer != null:
		mid_layer.position.x = -cam_offset.x * (1.0 - mid_factor)
	if foreground_layer != null:
		foreground_layer.position.x = -cam_offset.x * (1.0 - foreground_factor)

func _find_active_camera() -> void:
	var viewport: Viewport = get_viewport()
	if viewport != null:
		_camera = viewport.get_camera_2d()
