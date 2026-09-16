extends Node3D

@onready var camera: Camera3D = $Camera3D
@onready var character_root: Node3D = $DestinedOne
@onready var weapon_root: Node3D = $DestinedOne/Weapon
@onready var anim_player: AnimationPlayer = $DestinedOne/AnimationPlayer
@onready var ground: MeshInstance3D = $GroundPreview
@onready var key_light: DirectionalLight3D = $KeyLight
@onready var fill_light: DirectionalLight3D = $FillLight
@onready var fps_label: Label = $CanvasLayer/UI/VBox/FPSLabel
@onready var status_label: Label = $CanvasLayer/UI/VBox/StatusLabel
@onready var anim_container: HFlowContainer = $CanvasLayer/UI/VBox/AnimButtons

const CANONICAL_CAM_SIZE: float = 3.85
const CANONICAL_CAM_POS: Vector3 = Vector3(-0.25, 1.25, 4.0)
const CANONICAL_CHAR_ROT: Vector3 = Vector3(0, -20, 0)

const ANIMATIONS: Array[String] = [
	"destined_idle",
	"destined_combat_idle",
	"destined_walk",
	"destined_run",
	"destined_jump",
	"destined_fall",
	"destined_land",
	"destined_dodge",
	"destined_dodge_recovery",
	"destined_light_01",
	"destined_light_02",
	"destined_light_03",
	"destined_heavy",
	"destined_heavy_charge",
	"destined_hurt",
	"destined_stagger",
	"destined_knockdown",
	"destined_getup"
]

var _is_ortho: bool = true
var _destined_sk: Skeleton3D
var _weapon_sk: Skeleton3D

func _ready() -> void:
	_destined_sk = character_root.find_child("Skeleton3D", true, false)
	if weapon_root:
		_weapon_sk = weapon_root.find_child("Skeleton3D", true, false)
		
	_apply_production_materials()
	_setup_animation_player()
	_update_camera_settings()
	_create_ui_buttons()
	
	# Start with idle
	play_animation("destined_idle")

func _process(_delta: float) -> void:
	_sync_weapon_bones()
	
	if fps_label:
		var fps = Engine.get_frames_per_second()
		var mem_mb = float(OS.get_static_memory_usage()) / (1024.0 * 1024.0)
		fps_label.text = "FPS: %d | Memory: %.1f MB" % [fps, mem_mb]
		
	if status_label and anim_player:
		var curr = anim_player.current_animation
		var pos = anim_player.current_animation_position
		var len_a = anim_player.current_animation_length
		status_label.text = "Animation: %s (%.2fs / %.2fs) | Playing: %s" % [
			curr if curr != "" else "NONE", pos, len_a, str(anim_player.is_playing())
		]

func _setup_animation_player() -> void:
	var lib_path = "res://assets/characters/destined_one/animations/libraries/destined_one_animation_library.res"
	if ResourceLoader.exists(lib_path):
		var lib = load(lib_path)
		if anim_player.has_animation_library(""):
			anim_player.remove_animation_library("")
		anim_player.add_animation_library("", lib)
		print("[PREVIEW] Loaded animation library successfully with ", lib.get_animation_list().size(), " animations.")
	else:
		printerr("[PREVIEW] Animation library missing at: ", lib_path)

func play_animation(anim_name: String) -> void:
	if anim_player and anim_player.has_animation(anim_name):
		anim_player.play(anim_name)
		print("[PREVIEW] Playing: ", anim_name)

func _sync_weapon_bones() -> void:
	if not _destined_sk or not _weapon_sk:
		return
	var arm_bones = ["pelvis", "spine_01", "spine_02", "spine_03", "clavicle_r", "upperarm_r", "lowerarm_r", "hand_r"]
	for bname in arm_bones:
		var d_idx = _destined_sk.find_bone(bname)
		var w_idx = _weapon_sk.find_bone(bname)
		if d_idx >= 0 and w_idx >= 0:
			_weapon_sk.set_bone_pose_rotation(w_idx, _destined_sk.get_bone_pose_rotation(d_idx))

func _create_ui_buttons() -> void:
	if not anim_container:
		return
		
	for c in anim_container.get_children():
		c.queue_free()
		
	for anim_name in ANIMATIONS:
		var btn = Button.new()
		btn.text = anim_name.replace("destined_", "").capitalize()
		btn.pressed.connect(func(): play_animation(anim_name))
		anim_container.add_child(btn)

func _apply_production_materials() -> void:
	var mat_dir = "res://assets/characters/destined_one/materials/"
	var stack = [character_root]
	if weapon_root:
		stack.append(weapon_root)
	
	while stack.size() > 0:
		var n = stack.pop_back()
		if n is MeshInstance3D and n.mesh:
			for s in range(n.mesh.get_surface_count()):
				var orig_mat = n.mesh.surface_get_material(s)
				var mname = orig_mat.resource_name if orig_mat else ""
				if mname != "":
					var mat_path = mat_dir + mname + ".tres"
					if ResourceLoader.exists(mat_path):
						var custom_mat = load(mat_path)
						n.set_surface_override_material(s, custom_mat)
		for c in n.get_children():
			stack.append(c)

func _update_camera_settings() -> void:
	if camera:
		if _is_ortho:
			camera.projection = Camera3D.PROJECTION_ORTHOGONAL
			camera.size = CANONICAL_CAM_SIZE
			camera.position = CANONICAL_CAM_POS
		else:
			camera.projection = Camera3D.PROJECTION_PERSPECTIVE
			camera.fov = 45.0
			camera.position = CANONICAL_CAM_POS

func toggle_projection() -> void:
	_is_ortho = not _is_ortho
	_update_camera_settings()

func toggle_ground() -> void:
	if ground:
		ground.visible = not ground.visible

func reset_view() -> void:
	_is_ortho = true
	_update_camera_settings()
	if character_root:
		character_root.rotation_degrees = CANONICAL_CHAR_ROT
	play_animation("destined_idle")
