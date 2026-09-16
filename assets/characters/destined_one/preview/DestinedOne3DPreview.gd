extends Node3D

@onready var camera: Camera3D = $Camera3D
@onready var character_root: Node3D = $DestinedOne
@onready var weapon_root: Node3D = $DestinedOne/Weapon
@onready var ground: MeshInstance3D = $GroundPreview
@onready var key_light: DirectionalLight3D = $KeyLight
@onready var fill_light: DirectionalLight3D = $FillLight
@onready var fps_label: Label = $CanvasLayer/UI/VBox/FPSLabel
@onready var info_label: Label = $CanvasLayer/UI/VBox/InfoLabel

const CANONICAL_CAM_SIZE: float = 3.85
const CANONICAL_CAM_POS: Vector3 = Vector3(-0.25, 1.25, 4.0)
const CANONICAL_CHAR_ROT: Vector3 = Vector3(0, -20, 0)

var _is_ortho: bool = true

func _ready() -> void:
	_apply_production_materials()
	_update_camera_settings()
	if info_label:
		info_label.text = "Destined One — 3D Authoring Preview\nScale: 1.0 (2.44m) | Polys: 717k Tris\nOrientation: RIGHT-FACING (-20° Y)\nCamera: Orthographic (Size: %.2f)" % CANONICAL_CAM_SIZE

func _process(_delta: float) -> void:
	if fps_label:
		var fps = Engine.get_frames_per_second()
		var mem_mb = float(OS.get_static_memory_usage()) / (1024.0 * 1024.0)
		fps_label.text = "FPS: %d | Memory: %.1f MB" % [fps, mem_mb]

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
