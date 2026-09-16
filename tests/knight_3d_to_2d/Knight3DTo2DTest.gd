class_name Knight3DTo2DTest
extends Node2D

## Controller for Knight 3D -> 2D Sprite Preview.
## Demonstrates pre-rendered 512x512 orthographic sprite playback
## across Idle, Walking, and Run animations with interactive controls and telemetry.

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var title_label: Label = $UI/Panel/Margin/VBox/TitleLabel
@onready var anim_label: Label = $UI/Panel/Margin/VBox/AnimLabel
@onready var frame_label: Label = $UI/Panel/Margin/VBox/FrameLabel
@onready var fps_label: Label = $UI/Panel/Margin/VBox/FpsLabel
@onready var res_label: Label = $UI/Panel/Margin/VBox/ResLabel
@onready var status_label: Label = $UI/Panel/Margin/VBox/StatusLabel

const ANIM_KEYS: Array[StringName] = [&"idle", &"walking", &"run"]
var current_anim_index: int = 0
var is_paused: bool = false


func _ready() -> void:
	if not sprite:
		status_label.text = "Status: ERROR - AnimatedSprite2D not found"
		return
	
	_play_animation_by_index(0)
	_update_telemetry()


func _process(_delta: float) -> void:
	_update_telemetry()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	
	match key_event.keycode:
		KEY_1:
			_play_animation_by_index(0)
		KEY_2:
			_play_animation_by_index(1)
		KEY_3:
			_play_animation_by_index(2)
		KEY_LEFT:
			_prev_animation()
		KEY_RIGHT:
			_next_animation()
		KEY_SPACE:
			_toggle_pause()
		KEY_R:
			_restart_animation()


func _play_animation_by_index(index: int) -> void:
	if index < 0 or index >= ANIM_KEYS.size() or not sprite:
		return
	current_anim_index = index
	is_paused = false
	var anim_name: StringName = ANIM_KEYS[current_anim_index]
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)
	_update_telemetry()


func _prev_animation() -> void:
	var new_idx: int = (current_anim_index - 1 + ANIM_KEYS.size()) % ANIM_KEYS.size()
	_play_animation_by_index(new_idx)


func _next_animation() -> void:
	var new_idx: int = (current_anim_index + 1) % ANIM_KEYS.size()
	_play_animation_by_index(new_idx)


func _toggle_pause() -> void:
	if not sprite:
		return
	if sprite.is_playing():
		sprite.pause()
		is_paused = true
	else:
		sprite.play()
		is_paused = false
	_update_telemetry()


func _restart_animation() -> void:
	if not sprite:
		return
	sprite.frame = 0
	sprite.play()
	is_paused = false
	_update_telemetry()


func _update_telemetry() -> void:
	if not sprite or not sprite.sprite_frames:
		return
	
	var cur_anim: StringName = sprite.animation
	var cur_frame: int = sprite.frame
	var total_frames: int = sprite.sprite_frames.get_frame_count(cur_anim) if sprite.sprite_frames.has_animation(cur_anim) else 0
	var speed: float = sprite.sprite_frames.get_animation_speed(cur_anim) if sprite.sprite_frames.has_animation(cur_anim) else 30.0
	
	if anim_label:
		anim_label.text = "Current Animation: %s (%s)" % [
			cur_anim.capitalize(),
			"PAUSED" if is_paused else "PLAYING"
		]
	if frame_label:
		frame_label.text = "Frame: %d / %d" % [cur_frame + 1, total_frames]
	if fps_label:
		fps_label.text = "FPS: %.0f" % speed
	if res_label:
		res_label.text = "Resolution: 512 × 512"
	if status_label:
		status_label.text = "Status: OK - 3D Rendered 2D Sprite"


## Public API for automated tests
func get_current_animation_name() -> StringName:
	return sprite.animation if sprite else &""


func get_current_frame() -> int:
	return sprite.frame if sprite else -1


func get_total_frames(anim_name: StringName) -> int:
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation(anim_name):
		return sprite.sprite_frames.get_frame_count(anim_name)
	return 0
