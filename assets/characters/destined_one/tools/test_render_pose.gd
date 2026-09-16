extends SceneTree

func _init() -> void:
	print("--- TEST RENDERING DESTINED ONE TO PNG ---")
	
	# Create SubViewport
	var vp = SubViewport.new()
	vp.size = Vector2i(512, 512)
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	
	# Root Node3D
	var world_root = Node3D.new()
	vp.add_child(world_root)
	
	# WorldEnvironment
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0, 0, 0, 0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.7, 0.7, 0.75, 1.0)
	env.ambient_light_energy = 0.85
	
	var we = WorldEnvironment.new()
	we.environment = env
	world_root.add_child(we)
	
	# Key Light (Front-Right)
	var key_light = DirectionalLight3D.new()
	key_light.name = "KeyLight"
	key_light.light_color = Color(1.0, 0.96, 0.90)
	key_light.light_energy = 1.4
	key_light.shadow_enabled = false
	key_light.rotation_degrees = Vector3(-20, -35, 0)
	world_root.add_child(key_light)
	
	# Fill Light (Back-Left)
	var fill_light = DirectionalLight3D.new()
	fill_light.name = "FillLight"
	fill_light.light_color = Color(0.85, 0.90, 1.0)
	fill_light.light_energy = 0.6
	fill_light.rotation_degrees = Vector3(15, 145, 0)
	world_root.add_child(fill_light)
	
	# Rim Light
	var rim_light = DirectionalLight3D.new()
	rim_light.name = "RimLight"
	rim_light.light_color = Color(1.0, 0.85, 0.6)
	rim_light.light_energy = 0.8
	rim_light.rotation_degrees = Vector3(-10, 170, 0)
	world_root.add_child(rim_light)
	
	# Camera3D - Orthographic
	var cam = Camera3D.new()
	cam.name = "Camera3D"
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.current = true
	cam.size = 3.85 # Captures entire 2.44m character + head crown + 2.91m staff with safe padding
	cam.position = Vector3(-0.25, 1.25, 4.0)
	cam.rotation_degrees = Vector3(0, 0, 0) # Default Godot camera looks toward -Z
	world_root.add_child(cam)
	
	# Load Destined One Character
	var char_res = load("res://assets/characters/destined_one/source/Destined One - Born.fbx")
	var char_inst: Node3D = char_res.instantiate()
	char_inst.name = "DestinedOne"
	# Character native forward is +X.
	# Looking down -Z, -20 degrees Y rotation turns the character slightly toward camera (3/4 front-right).
	char_inst.rotation_degrees = Vector3(0, -20, 0)
	world_root.add_child(char_inst)
	
	# Load Weapon
	var w_res = load("res://assets/characters/destined_one/source/weapon/Destined One - Born - Weapon.fbx")
	var w_inst: Node3D = w_res.instantiate()
	w_inst.name = "Weapon"
	w_inst.rotation_degrees = Vector3(0, -20, 0)
	world_root.add_child(w_inst)
	
	# Apply materials
	var mat_dir = "res://assets/characters/destined_one/materials/"
	var apply_mats = func(root_node: Node):
		var stack = [root_node]
		while stack.size() > 0:
			var n = stack.pop_back()
			if n is MeshInstance3D and n.mesh:
				for s in range(n.mesh.get_surface_count()):
					var orig_mat = n.mesh.surface_get_material(s)
					var mname = orig_mat.resource_name if orig_mat else ""
					if mname != "":
						var custom_path = mat_dir + mname + ".tres"
						if ResourceLoader.exists(custom_path):
							var loaded_mat = load(custom_path)
							n.set_surface_override_material(s, loaded_mat)
			for c in n.get_children():
				stack.append(c)
	
	apply_mats.call(char_inst)
	apply_mats.call(w_inst)
	
	# Add viewport to root tree
	root.add_child(vp)
	
	# Let engine process and render frames
	for i in range(5):
		await process_frame
	
	var img = vp.get_texture().get_image()
	if img:
		var out_dir = "res://assets/characters/destined_one/generated/sprites/512/"
		var out_path = out_dir + "test_idle.png"
		img.save_png(out_path)
		print("Saved test render to: ", out_path)
		print("Image size: ", img.get_size())
		print("Format: ", img.get_format())
		
		# Check pixel at (5, 5) for background transparency
		var bg_pixel = img.get_pixel(5, 5)
		print("Background pixel (5, 5) alpha: ", bg_pixel.a)
		
		# Check character center pixel
		var center_pixel = img.get_pixel(256, 256)
		print("Center pixel (256, 256) alpha: ", center_pixel.a, " color: ", center_pixel)
	else:
		printerr("ERROR: Could not get viewport image")
		
	vp.queue_free()
	quit(0)
