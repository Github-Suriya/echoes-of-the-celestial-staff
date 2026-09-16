class_name Knight3DTest
extends Node3D

## Controller for isolated Quaternius Knight 3D Direct Import Test.
## Dynamically discovers animations from the imported KnightCharacter.fbx scene,
## provides keyboard switching, play/pause controls, and on-screen telemetry.

@onready var knight_root: Node3D = $Knight
@onready var anim_player: AnimationPlayer = $Knight/AnimationPlayer if has_node("Knight/AnimationPlayer") else null

@onready var title_label: Label = $UI/Panel/MarginContainer/VBox/TitleLabel
@onready var status_label: Label = $UI/Panel/MarginContainer/VBox/StatusLabel
@onready var current_anim_label: Label = $UI/Panel/MarginContainer/VBox/CurrentAnimLabel
@onready var progress_label: Label = $UI/Panel/MarginContainer/VBox/ProgressLabel
@onready var anim_list_label: Label = $UI/Panel/MarginContainer/VBox/ScrollContainer/AnimListLabel

var animation_names: Array[StringName] = []
var current_anim_index: int = 0
var is_paused: bool = false


func _ready() -> void:
	if not anim_player:
		anim_player = find_child("AnimationPlayer", true, false) as AnimationPlayer
	
	_discover_animations()
	
	if not animation_names.is_empty():
		var default_idx: int = _find_preferred_initial_animation()
		_play_animation_by_index(default_idx)
	else:
		if status_label:
			status_label.text = "Status: ERROR - No animations found in AnimationPlayer"
	
	_update_ui()


func _process(_delta: float) -> void:
	if not anim_player or not progress_label:
		return
	
	if anim_player.is_playing():
		var cur_pos: float = anim_player.current_animation_position
		var length: float = anim_player.current_animation_length
		progress_label.text = "Time: %.2fs / %.2fs (%s)" % [
			cur_pos,
			length,
			"PAUSED" if is_paused else "PLAYING"
		]
	elif is_paused:
		progress_label.text = "Time: PAUSED at %.2fs" % anim_player.current_animation_position
	else:
		progress_label.text = "Time: STOPPED"


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	
	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	
	var key: Key = key_event.keycode
	
	# Number keys 1-9 for direct selection
	if key >= KEY_1 and key <= KEY_9:
		var target_idx: int = int(key) - int(KEY_1)
		if target_idx < animation_names.size():
			_play_animation_by_index(target_idx)
	elif key == KEY_0:
		if animation_names.size() > 9:
			_play_animation_by_index(9)
	elif key == KEY_MINUS:
		if animation_names.size() > 10:
			_play_animation_by_index(10)
	elif key == KEY_EQUAL:
		if animation_names.size() > 11:
			_play_animation_by_index(11)
	elif key == KEY_LEFT:
		_prev_animation()
	elif key == KEY_RIGHT:
		_next_animation()
	elif key == KEY_SPACE:
		_toggle_pause()
	elif key == KEY_R:
		_restart_animation()


## Dynamically queries the AnimationPlayer for all available animation tracks.
func _discover_animations() -> void:
	animation_names.clear()
	if not anim_player:
		push_warning("Knight3DTest: AnimationPlayer node not found!")
		return
	
	var anim_list: PackedStringArray = anim_player.get_animation_list()
	for anim_name in anim_list:
		if anim_name != "RESET":
			animation_names.append(StringName(anim_name))
	
	print("[Knight3DTest] Discovered %d animations: %s" % [animation_names.size(), str(animation_names)])


## Searches for an Idle animation to use as default, otherwise returns 0.
func _find_preferred_initial_animation() -> int:
	for i in range(animation_names.size()):
		var lower_name: String = String(animation_names[i]).to_lower()
		if "idle" in lower_name and not "sword" in lower_name:
			return i
	for i in range(animation_names.size()):
		if "idle" in String(animation_names[i]).to_lower():
			return i
	return 0


func _play_animation_by_index(index: int) -> void:
	if index < 0 or index >= animation_names.size():
		return
	
	current_anim_index = index
	is_paused = false
	var anim_to_play: StringName = animation_names[current_anim_index]
	
	if anim_player:
		# Set loop mode on the animation if supported
		var anim: Animation = anim_player.get_animation(anim_to_play)
		if anim and anim_to_play != &"HumanArmature|Death":
			anim.loop_mode = Animation.LOOP_LINEAR
		
		anim_player.play(anim_to_play)
		print("[Knight3DTest] Playing [%d]: %s" % [current_anim_index, anim_to_play])
	
	_update_ui()


func _prev_animation() -> void:
	if animation_names.is_empty():
		return
	var new_idx: int = (current_anim_index - 1 + animation_names.size()) % animation_names.size()
	_play_animation_by_index(new_idx)


func _next_animation() -> void:
	if animation_names.is_empty():
		return
	var new_idx: int = (current_anim_index + 1) % animation_names.size()
	_play_animation_by_index(new_idx)


func _toggle_pause() -> void:
	if not anim_player:
		return
	
	if anim_player.is_playing():
		anim_player.pause()
		is_paused = true
	else:
		if is_paused:
			anim_player.play()
			is_paused = false
		else:
			_play_animation_by_index(current_anim_index)
	_update_ui()


func _restart_animation() -> void:
	if not anim_player or animation_names.is_empty():
		return
	is_paused = false
	var anim_to_play: StringName = animation_names[current_anim_index]
	anim_player.seek(0.0, true)
	anim_player.play(anim_to_play)
	_update_ui()


func _update_ui() -> void:
	if status_label:
		status_label.text = "Status: Loaded (%d animations)" % animation_names.size()
	
	if current_anim_label:
		if animation_names.is_empty():
			current_anim_label.text = "Animation: None"
		else:
			var raw_name: String = String(animation_names[current_anim_index])
			var clean_name: String = raw_name.replace("HumanArmature|", "")
			current_anim_label.text = "Animation [%d/%d]: %s\n(Track: %s)" % [
				current_anim_index + 1,
				animation_names.size(),
				clean_name,
				raw_name
			]
	
	if anim_list_label:
		var list_text: String = "Available Animations:\n"
		for i in range(animation_names.size()):
			var is_current: bool = (i == current_anim_index)
			var prefix: String = "> " if is_current else "  "
			var clean: String = String(animation_names[i]).replace("HumanArmature|", "")
			var shortcut: String = ""
			if i < 9:
				shortcut = "[%d] " % (i + 1)
			elif i == 9:
				shortcut = "[0] "
			elif i == 10:
				shortcut = "[-] "
			elif i == 11:
				shortcut = "[=] "
			list_text += "%s%s%s%s\n" % [
				prefix,
				shortcut,
				clean,
				" *" if is_current else ""
			]
		anim_list_label.text = list_text


## Public query API for automated regression and integration testing
func get_discovered_animations() -> Array[StringName]:
	return animation_names.duplicate()


func get_current_animation_name() -> StringName:
	if animation_names.is_empty():
		return &""
	return animation_names[current_anim_index]


func get_skeleton() -> Skeleton3D:
	return find_child("Skeleton3D", true, false) as Skeleton3D


func get_mesh_instance() -> MeshInstance3D:
	return find_child("Knight", true, false) as MeshInstance3D
