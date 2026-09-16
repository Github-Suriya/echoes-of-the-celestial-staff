extends Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var anim_label: Label = $CanvasLayer/UI/VBox/AnimLabel
@onready var frame_label: Label = $CanvasLayer/UI/VBox/FrameLabel
@onready var fps_label: Label = $CanvasLayer/UI/VBox/FPSLabel

var _animations: Array[StringName] = [&"idle_test", &"stance_test", &"movement_test"]
var _current_idx: int = 0
var _is_paused: bool = false

func _ready() -> void:
	if sprite and sprite.sprite_frames:
		sprite.play(_animations[_current_idx])
	_update_ui()

func _process(_delta: float) -> void:
	if fps_label:
		var fps = Engine.get_frames_per_second()
		var mem_mb = float(OS.get_static_memory_usage()) / (1024.0 * 1024.0)
		fps_label.text = "FPS: %d | Memory: %.1f MB" % [fps, mem_mb]
	if frame_label and sprite:
		frame_label.text = "Frame: %d / %d" % [sprite.frame, sprite.sprite_frames.get_frame_count(sprite.animation)]

func _update_ui() -> void:
	if anim_label and sprite:
		anim_label.text = "Animation: %s (Facing: %s)" % [String(sprite.animation), "RIGHT" if not sprite.flip_h else "LEFT"]

func next_animation() -> void:
	_current_idx = (_current_idx + 1) % _animations.size()
	sprite.play(_animations[_current_idx])
	_update_ui()

func prev_animation() -> void:
	_current_idx = (_current_idx - 1 + _animations.size()) % _animations.size()
	sprite.play(_animations[_current_idx])
	_update_ui()

func toggle_pause() -> void:
	_is_paused = not _is_paused
	if _is_paused:
		sprite.pause()
	else:
		sprite.play()

func toggle_flip() -> void:
	sprite.flip_h = not sprite.flip_h
	_update_ui()

func step_frame() -> void:
	if not _is_paused:
		toggle_pause()
	var total = sprite.sprite_frames.get_frame_count(sprite.animation)
	sprite.frame = (sprite.frame + 1) % total
