class_name KnightComparison
extends Node2D

## Side-by-side comparison controller:
## Left side: Original 3D Knight (rendered via SubViewport)
## Right side: Rendered 2D Knight (via AnimatedSprite2D)
## Demonstrates exact visual parity, silhouette match, and animation sync.

@onready var sprite_2d: AnimatedSprite2D = $RightContainer/AnimatedSprite2D
@onready var vp_3d: SubViewport = $LeftContainer/SubViewportContainer/SubViewport
@onready var anim_player_3d: AnimationPlayer = $LeftContainer/SubViewportContainer/SubViewport/KnightRenderSource/Knight.find_child("AnimationPlayer", true, false) as AnimationPlayer
@onready var title_label: Label = $UI/Panel/VBox/TitleLabel
@onready var status_label: Label = $UI/Panel/VBox/StatusLabel

const ANIM_MAP: Dictionary = {
	"idle": "HumanArmature|Idle",
	"walking": "HumanArmature|Walking",
	"run": "HumanArmature|Run"
}
const ANIM_KEYS: Array[StringName] = [&"idle", &"walking", &"run"]
var current_anim_index: int = 0
var is_paused: bool = false


func _ready() -> void:
	_play_synced_animation(0)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	
	match key_event.keycode:
		KEY_1:
			_play_synced_animation(0)
		KEY_2:
			_play_synced_animation(1)
		KEY_3:
			_play_synced_animation(2)
		KEY_LEFT:
			_prev_animation()
		KEY_RIGHT:
			_next_animation()
		KEY_SPACE:
			_toggle_pause()
		KEY_R:
			_restart_animation()


func _play_synced_animation(idx: int) -> void:
	if idx < 0 or idx >= ANIM_KEYS.size():
		return
	current_anim_index = idx
	is_paused = false
	var anim_2d_key: StringName = ANIM_KEYS[current_anim_index]
	var anim_3d_key: String = ANIM_MAP[anim_2d_key]
	
	if sprite_2d and sprite_2d.sprite_frames:
		sprite_2d.play(anim_2d_key)
	
	if anim_player_3d:
		anim_player_3d.play(anim_3d_key)
	
	if status_label:
		status_label.text = "Sync: %s (3D: %s | 2D: %s)" % [
			anim_2d_key.capitalize(),
			anim_3d_key,
			anim_2d_key
		]


func _prev_animation() -> void:
	var new_idx: int = (current_anim_index - 1 + ANIM_KEYS.size()) % ANIM_KEYS.size()
	_play_synced_animation(new_idx)


func _next_animation() -> void:
	var new_idx: int = (current_anim_index + 1) % ANIM_KEYS.size()
	_play_synced_animation(new_idx)


func _toggle_pause() -> void:
	if is_paused:
		if sprite_2d:
			sprite_2d.play()
		if anim_player_3d:
			anim_player_3d.play()
		is_paused = false
	else:
		if sprite_2d:
			sprite_2d.pause()
		if anim_player_3d:
			anim_player_3d.pause()
		is_paused = true


func _restart_animation() -> void:
	if sprite_2d:
		sprite_2d.frame = 0
		sprite_2d.play()
	if anim_player_3d:
		anim_player_3d.seek(0.0, true)
		anim_player_3d.play()
	is_paused = false
