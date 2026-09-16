@tool
extends SceneTree

func _init() -> void:
	print("--- RENDERING HIGH-DETAIL CLOSEUPS ---")
	var root_node = Node3D.new()
	root.add_child(root_node)
	
	var vp = SubViewport.new()
	vp.size = Vector2i(768, 768)
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root_node.add_child(vp)
	
	var env_node = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0, 0, 0, 0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.45, 0.47, 0.52, 1.0)
	env.ambient_light_energy = 1.0
	env_node.environment = env
	vp.add_child(env_node)
	
	var key_light = DirectionalLight3D.new()
	key_light.position = Vector3(2, 5, 4)
	key_light.rotation_degrees = Vector3(-30, 25, 0)
	key_light.light_energy = 1.4
	vp.add_child(key_light)
	
	var fill_light = DirectionalLight3D.new()
	fill_light.position = Vector3(-2, 3, 3)
	fill_light.rotation_degrees = Vector3(-15, -35, 0)
	fill_light.light_color = Color(0.7, 0.8, 0.95)
	fill_light.light_energy = 0.6
	vp.add_child(fill_light)
	
	var cam = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.current = true
	vp.add_child(cam)
	
	var wukong = load("res://tests/wukong_asset_audit/source/dasheng.fbx").instantiate()
	wukong.scale = Vector3(0.01, 0.01, 0.01)
	vp.add_child(wukong)
	
	# Warm up
	for i in range(5):
		await process_frame
	
	# 1. Close-up: Face and Eyes
	# Head is near Y = 3.35, X = 0.0
	cam.position = Vector3(0.0, 3.45, 4.0)
	cam.size = 1.2
	for i in range(3):
		await process_frame
	var img_face = vp.get_texture().get_image()
	img_face.save_png("res://tests/wukong_asset_audit/preview/closeup_face_eyes.png")
	print("Saved closeup_face_eyes.png")
	
	# 2. Close-up: Hair / Fur / Crown Plumes
	cam.position = Vector3(0.0, 3.8, 4.0)
	cam.size = 1.8
	for i in range(3):
		await process_frame
	var img_hair = vp.get_texture().get_image()
	img_hair.save_png("res://tests/wukong_asset_audit/preview/closeup_hair_crown.png")
	print("Saved closeup_hair_crown.png")
	
	# 3. Close-up: Weapon / Staff (Ruyi Jingu Bang)
	cam.position = Vector3(0.0, 1.7, 4.0)
	cam.size = 2.5
	for i in range(3):
		await process_frame
	var img_staff = vp.get_texture().get_image()
	img_staff.save_png("res://tests/wukong_asset_audit/preview/closeup_weapon_staff.png")
	print("Saved closeup_weapon_staff.png")
	
	root_node.free()
	quit(0)
