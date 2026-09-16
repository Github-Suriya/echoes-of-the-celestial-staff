extends Node3D

@onready var wukong: Node3D = $Wukong
@onready var camera: Camera3D = $Camera3D
@onready var anim_label: Label = $UI/Panel/VBox/AnimName
@onready var time_label: Label = $UI/Panel/VBox/TimeLabel
@onready var fps_label: Label = $UI/Panel/VBox/FPSLabel
@onready var play_btn: Button = $UI/Panel/VBox/HBoxControls/PlayBtn

var anim_player: AnimationPlayer = null
var current_anim_index: int = 0
var animation_names: Array[String] = []
var is_playing: bool = false
var playback_time: float = 0.0
var anim_duration: float = 1.0

func _ready() -> void:
	print("[WUKONG_AUDIT] Initializing Wukong 3D Audit Scene...")
	
	# Check for AnimationPlayer inside Wukong instance
	anim_player = wukong.find_child("AnimationPlayer", true, false)
	
	if anim_player and anim_player.get_animation_list().size() > 0:
		for a in anim_player.get_animation_list():
			animation_names.append(a)
		print("[WUKONG_AUDIT] Found embedded animations: ", animation_names)
	else:
		print("[WUKONG_AUDIT] No AnimationPlayer or embedded animations found in FBX scene.")
		# Create an audit AnimationPlayer with procedural/rest animations so UI and rendering can execute
		_setup_audit_animation_player()
	
	_update_animation_display()
	
	# Connect UI signals
	$UI/Panel/VBox/HBoxControls/PrevBtn.pressed.connect(_on_prev_pressed)
	$UI/Panel/VBox/HBoxControls/NextBtn.pressed.connect(_on_next_pressed)
	$UI/Panel/VBox/HBoxControls/PlayBtn.pressed.connect(_on_play_pressed)
	$UI/Panel/VBox/HBoxControls/RestartBtn.pressed.connect(_on_restart_pressed)

func _setup_audit_animation_player() -> void:
	if not anim_player:
		anim_player = AnimationPlayer.new()
		anim_player.name = "AuditAnimationPlayer"
		wukong.add_child(anim_player)
	
	var lib := AnimationLibrary.new()
	
	# 1. Rest Pose (Bind Pose)
	var rest_anim := Animation.new()
	rest_anim.length = 1.0
	rest_anim.loop_mode = Animation.LOOP_LINEAR
	lib.add_animation("BindPose_Rest", rest_anim)
	
	# 2. Audit Stance Idle Sway (subtle breathing deformation on spine/root to test skeleton deforms)
	var idle_anim := Animation.new()
	idle_anim.length = 2.0
	idle_anim.loop_mode = Animation.LOOP_LINEAR
	var track_idx = idle_anim.add_track(Animation.TYPE_POSITION_3D)
	idle_anim.track_set_path(track_idx, "SK_mgd_jsds/Skeleton3D:pelvis")
	idle_anim.track_insert_key(track_idx, 0.0, Vector3(0, 0, 2.05))
	idle_anim.track_insert_key(track_idx, 1.0, Vector3(0, 0, 2.08))
	idle_anim.track_insert_key(track_idx, 2.0, Vector3(0, 0, 2.05))
	lib.add_animation("Audit_Stance_Breathe", idle_anim)
	
	# 3. Audit Walk Cycle Stride (stride test)
	var walk_anim := Animation.new()
	walk_anim.length = 1.2
	walk_anim.loop_mode = Animation.LOOP_LINEAR
	var wtrack = walk_anim.add_track(Animation.TYPE_POSITION_3D)
	walk_anim.track_set_path(wtrack, "SK_mgd_jsds/Skeleton3D:pelvis")
	walk_anim.track_insert_key(wtrack, 0.0, Vector3(0, 0, 2.05))
	walk_anim.track_insert_key(wtrack, 0.3, Vector3(0, 0.05, 2.08))
	walk_anim.track_insert_key(wtrack, 0.6, Vector3(0, 0, 2.05))
	walk_anim.track_insert_key(wtrack, 0.9, Vector3(0, -0.05, 2.08))
	walk_anim.track_insert_key(wtrack, 1.2, Vector3(0, 0, 2.05))
	lib.add_animation("Audit_Walk_Stride", walk_anim)
	
	# 4. Audit Run Stride
	var run_anim := Animation.new()
	run_anim.length = 0.8
	run_anim.loop_mode = Animation.LOOP_LINEAR
	var rtrack = run_anim.add_track(Animation.TYPE_POSITION_3D)
	run_anim.track_set_path(rtrack, "SK_mgd_jsds/Skeleton3D:pelvis")
	run_anim.track_insert_key(rtrack, 0.0, Vector3(0, 0, 2.05))
	run_anim.track_insert_key(rtrack, 0.2, Vector3(0, 0.1, 2.12))
	run_anim.track_insert_key(rtrack, 0.4, Vector3(0, 0, 2.05))
	run_anim.track_insert_key(rtrack, 0.6, Vector3(0, -0.1, 2.12))
	run_anim.track_insert_key(rtrack, 0.8, Vector3(0, 0, 2.05))
	lib.add_animation("Audit_Run_Stride", run_anim)
	
	anim_player.add_animation_library("", lib)
	animation_names = ["BindPose_Rest", "Audit_Stance_Breathe", "Audit_Walk_Stride", "Audit_Run_Stride"]
	print("[WUKONG_AUDIT] Generated audit testing animations: ", animation_names)

func _process(delta: float) -> void:
	fps_label.text = "FPS: %d | Vertices: 746,789 | Triangles: 960,298 | Bones: 466" % Engine.get_frames_per_second()
	
	if is_playing and anim_player:
		playback_time += delta
		if playback_time > anim_duration:
			playback_time = fmod(playback_time, anim_duration)
		time_label.text = "Time: %.2f / %.2f s" % [playback_time, anim_duration]

func _update_animation_display() -> void:
	if animation_names.is_empty():
		anim_label.text = "Animation: NONE"
		time_label.text = "Time: 0.00 / 0.00 s"
		return
	
	var aname = animation_names[current_anim_index]
	var anim = anim_player.get_animation(aname)
	anim_duration = anim.length if anim else 1.0
	playback_time = 0.0
	anim_label.text = "Animation: %s [%d/%d]" % [aname, current_anim_index + 1, animation_names.size()]
	time_label.text = "Time: 0.00 / %.2f s" % anim_duration
	
	if is_playing:
		anim_player.play(aname)
	else:
		anim_player.play(aname)
		anim_player.pause()

func _on_prev_pressed() -> void:
	if animation_names.is_empty(): return
	current_anim_index = (current_anim_index - 1 + animation_names.size()) % animation_names.size()
	_update_animation_display()

func _on_next_pressed() -> void:
	if animation_names.is_empty(): return
	current_anim_index = (current_anim_index + 1) % animation_names.size()
	_update_animation_display()

func _on_play_pressed() -> void:
	is_playing = not is_playing
	play_btn.text = "Pause" if is_playing else "Play"
	if animation_names.is_empty(): return
	var aname = animation_names[current_anim_index]
	if is_playing:
		anim_player.play(aname)
	else:
		anim_player.pause()

func _on_restart_pressed() -> void:
	playback_time = 0.0
	if animation_names.is_empty(): return
	var aname = animation_names[current_anim_index]
	anim_player.seek(0.0, true)
	if is_playing:
		anim_player.play(aname)
	_update_animation_display()
