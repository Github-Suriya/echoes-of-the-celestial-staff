extends SceneTree

func _init() -> void:
	print("==================================================")
	print("STARTING DESTINED ONE TECHNICAL ASSET AUDIT")
	print("==================================================")
	
	var char_fbx_path = "res://assets/characters/destined_one/source/Destined One - Born.fbx"
	var weapon_fbx_path = "res://assets/characters/destined_one/source/weapon/Destined One - Born - Weapon.fbx"
	
	# Check file existence
	if not FileAccess.file_exists(char_fbx_path):
		printerr("ERROR: Character FBX not found at: ", char_fbx_path)
		quit(1)
		return
	
	var start_time = Time.get_ticks_msec()
	var char_res = load(char_fbx_path)
	var load_duration_ms = Time.get_ticks_msec() - start_time
	
	if not char_res or not (char_res is PackedScene):
		printerr("ERROR: Failed to load Character FBX as PackedScene")
		quit(1)
		return
	
	var char_inst: Node = char_res.instantiate()
	if not char_inst:
		printerr("ERROR: Failed to instantiate Character FBX PackedScene")
		quit(1)
		return
	
	print("\n--- 1. Import & Root Information ---")
	print("Import status: SUCCESS")
	print("Load duration: %d ms" % load_duration_ms)
	print("Root node: %s (Type: %s)" % [char_inst.name, char_inst.get_class()])
	
	# Node traversal
	var node_count = 0
	var mi_list: Array[MeshInstance3D] = []
	var skel: Skeleton3D = null
	var anim_player: AnimationPlayer = null
	var stack: Array[Node] = [char_inst]
	
	var all_nodes_info = []
	
	while stack.size() > 0:
		var n = stack.pop_back()
		node_count += 1
		all_nodes_info.append({"name": n.name, "type": n.get_class()})
		
		if n is MeshInstance3D:
			mi_list.append(n)
		elif n is Skeleton3D and skel == null:
			skel = n
		elif n is AnimationPlayer and anim_player == null:
			anim_player = n
			
		for c in n.get_children():
			stack.append(c)
	
	print("Total Node count: %d" % node_count)
	print("MeshInstance3D count: %d" % mi_list.size())
	print("Skeleton3D count: %d" % (1 if skel != null else 0))
	print("AnimationPlayer count: %d" % (1 if anim_player != null else 0))
	
	# Mesh statistics
	print("\n--- 2. Mesh & Geometry Statistics ---")
	var total_verts = 0
	var total_tris = 0
	var total_surfaces = 0
	var total_blend_shapes = 0
	var material_names: Array[String] = []
	var aabb_total = AABB()
	var aabb_initialized = false
	
	for mi in mi_list:
		print("  MeshInstance3D: '%s'" % mi.name)
		if mi.mesh:
			var m = mi.mesh
			var sc = m.get_surface_count()
			total_surfaces += sc
			var bs_count = 0
			if m is ArrayMesh:
				bs_count = m.get_blend_shape_count()
			total_blend_shapes += bs_count
			print("    Surfaces: %d, Blend Shapes: %d" % [sc, bs_count])
			
			var mi_aabb = mi.get_aabb()
			if not aabb_initialized:
				aabb_total = mi_aabb
				aabb_initialized = true
			else:
				aabb_total = aabb_total.merge(mi_aabb)
				
			for s in range(sc):
				var mat = mi.get_surface_override_material(s)
				if mat == null:
					mat = m.surface_get_material(s)
				var mat_name = mat.resource_name if mat and mat.resource_name != "" else (mat.get_class() if mat else "None")
				if not material_names.has(mat_name):
					material_names.append(mat_name)
					
				var arr = m.surface_get_arrays(s)
				var verts = arr[Mesh.ARRAY_VERTEX]
				var inds = arr[Mesh.ARRAY_INDEX]
				var vc = verts.size() if verts else 0
				var tc = (inds.size() / 3) if inds else (vc / 3)
				total_verts += vc
				total_tris += tc
				print("      Surface %d: %d verts, %d tris, Material: '%s'" % [s, vc, tc, mat_name])
	
	print("Total Surfaces: %d" % total_surfaces)
	print("Total Vertices: %d" % total_verts)
	print("Total Triangles: %d" % total_tris)
	print("Total Blend Shapes: %d" % total_blend_shapes)
	print("Unique Materials (%d): %s" % [material_names.size(), str(material_names)])
	print("Raw AABB bounds: position=%s, size=%s" % [str(aabb_total.position), str(aabb_total.size)])
	print("Approx height: %.2f units, width: %.2f units, depth: %.2f units" % [aabb_total.size.y, aabb_total.size.x, aabb_total.size.z])
	
	# Skeleton audit
	print("\n--- 3. Skeleton Audit ---")
	var bone_count = 0
	var bone_names: Array[String] = []
	if skel:
		bone_count = skel.get_bone_count()
		print("Skeleton3D found: '%s'" % skel.name)
		print("Total bone count: %d" % bone_count)
		
		for b in range(bone_count):
			bone_names.append(skel.get_bone_name(b))
		
		# Save all bones to file
		var bone_file = FileAccess.open("res://assets/characters/destined_one/reports/bone_list.txt", FileAccess.WRITE)
		if bone_file:
			bone_file.store_line("DESTINED ONE SKELETON BONE HIERARCHY (Total: %d)" % bone_count)
			bone_file.store_line("==================================================")
			for b in range(bone_count):
				var p = skel.get_bone_parent(b)
				var pname = skel.get_bone_name(p) if p >= 0 else "ROOT"
				bone_file.store_line("[%03d] %-30s -> Parent: [%03d] %s" % [b, skel.get_bone_name(b), p, pname])
			bone_file.close()
			print("Saved complete bone hierarchy to: res://assets/characters/destined_one/reports/bone_list.txt")
		
		# Humanoid bone semantic analysis
		var semantic_mappings = [
			{"semantic": "Root", "targets": ["root", "origin"]},
			{"semantic": "Hips", "targets": ["pelvis", "hips", "hip"]},
			{"semantic": "Spine", "targets": ["spine_01", "spine1", "spine"]},
			{"semantic": "Chest", "targets": ["spine_02", "spine2", "chest"]},
			{"semantic": "UpperChest", "targets": ["spine_03", "spine3", "upperchest"]},
			{"semantic": "Neck", "targets": ["neck_01", "neck1", "neck"]},
			{"semantic": "Head", "targets": ["head"]},
			{"semantic": "LeftShoulder", "targets": ["clavicle_l", "shoulder_l"]},
			{"semantic": "LeftUpperArm", "targets": ["upperarm_l", "arm_l"]},
			{"semantic": "LeftLowerArm", "targets": ["lowerarm_l", "forearm_l"]},
			{"semantic": "LeftHand", "targets": ["hand_l"]},
			{"semantic": "RightShoulder", "targets": ["clavicle_r", "shoulder_r"]},
			{"semantic": "RightUpperArm", "targets": ["upperarm_r", "arm_r"]},
			{"semantic": "RightLowerArm", "targets": ["lowerarm_r", "forearm_r"]},
			{"semantic": "RightHand", "targets": ["hand_r"]},
			{"semantic": "LeftUpperLeg", "targets": ["thigh_l", "upperleg_l"]},
			{"semantic": "LeftLowerLeg", "targets": ["calf_l", "lowerleg_l"]},
			{"semantic": "LeftFoot", "targets": ["foot_l"]},
			{"semantic": "LeftToes", "targets": ["ball_l_01", "ball_l", "toe_l", "toes_l"]},
			{"semantic": "RightUpperLeg", "targets": ["thigh_r", "upperleg_r"]},
			{"semantic": "RightLowerLeg", "targets": ["calf_r", "lowerleg_r"]},
			{"semantic": "RightFoot", "targets": ["foot_r"]},
			{"semantic": "RightToes", "targets": ["ball_r_01", "ball_r", "toe_r", "toes_r"]},
			{"semantic": "WeaponRight", "targets": ["weapon_r", "socket_weapon_r", "hand_r"]},
			{"semantic": "WeaponLeft", "targets": ["weapon_l", "socket_weapon_l", "hand_l"]}
		]
		
		print("\nHumanoid Bone Mapping Results:")
		print("----------------------------------------------------------------------")
		print("%-18s | %-20s | %-6s | %s" % ["SEMANTIC BONE", "ACTUAL BONE", "FOUND", "NOTES"])
		print("----------------------------------------------------------------------")
		for sm in semantic_mappings:
			var found_name = ""
			for target in sm["targets"]:
				for actual in bone_names:
					if actual.to_lower() == target:
						found_name = actual
						break
				if found_name != "":
					break
			var found_bool = (found_name != "")
			var note = "Exact match" if found_bool else "Not identified in primary list"
			if found_name == "hand_r" and sm["semantic"] == "WeaponRight":
				note = "Using hand_r as weapon attachment socket"
			elif found_name == "hand_l" and sm["semantic"] == "WeaponLeft":
				note = "Using hand_l as off-hand socket"
			print("%-18s | %-20s | %-6s | %s" % [sm["semantic"], (found_name if found_bool else "N/A"), ("YES" if found_bool else "NO"), note])
		print("----------------------------------------------------------------------")
		
		# Categorize bones
		var hair_bones = []
		var cloth_bones = []
		var face_bones = []
		var finger_bones = []
		var core_bones = []
		var other_bones = []
		
		for bname in bone_names:
			var low = bname.to_lower()
			if "hair" in low or "whisker" in low:
				hair_bones.append(bname)
			elif "cloth" in low or "skirt" in low or "cape" in low or "rope" in low or "belt" in low:
				cloth_bones.append(bname)
			elif "face" in low or "lip" in low or "eye" in low or "brow" in low or "jaw" in low or "cheek" in low:
				face_bones.append(bname)
			elif "thumb" in low or "index" in low or "middle" in low or "ring" in low or "pinky" in low or "finger" in low:
				finger_bones.append(bname)
			elif "root" in low or "pelvis" in low or "spine" in low or "neck" in low or "head" in low or "clavicle" in low or "upperarm" in low or "lowerarm" in low or "hand" in low or "thigh" in low or "calf" in low or "foot" in low or "ball" in low:
				core_bones.append(bname)
			else:
				other_bones.append(bname)
				
		print("\nBone Categorization:")
		print("  Core Humanoid bones: %d" % core_bones.size())
		print("  Finger bones: %d" % finger_bones.size())
		print("  Facial bones: %d" % face_bones.size())
		print("  Hair bones: %d" % hair_bones.size())
		print("  Cloth / Ribbon bones: %d" % cloth_bones.size())
		print("  Other / Accessory / Helper bones: %d" % other_bones.size())
	else:
		printerr("WARNING: No Skeleton3D found!")
	
	# Animation audit
	print("\n--- 4. Animation Source Audit ---")
	if anim_player:
		var anim_list = anim_player.get_animation_list()
		print("AnimationPlayer found: '%s'" % anim_player.name)
		print("Embedded Animation count: %d" % anim_list.size())
		if anim_list.size() == 0:
			print("REPORT: Destined One source FBX contains no embedded animation takes.")
		else:
			for a in anim_list:
				var anim = anim_player.get_animation(a)
				print("  Animation: '%s', Duration: %.2fs" % [a, anim.length if anim else 0.0])
	else:
		print("No AnimationPlayer node found in Character FBX.")
		print("REPORT: Destined One source FBX contains no embedded animation takes.")
	
	# Weapon audit
	print("\n--- 5. Weapon Source Audit ---")
	if FileAccess.file_exists(weapon_fbx_path):
		var wstart = Time.get_ticks_msec()
		var w_res = load(weapon_fbx_path)
		var w_duration = Time.get_ticks_msec() - wstart
		if w_res and (w_res is PackedScene):
			var w_inst: Node = w_res.instantiate()
			print("Weapon FBX loaded cleanly (%d ms)" % w_duration)
			print("Weapon root: '%s' (Type: %s)" % [w_inst.name, w_inst.get_class()])
			
			var w_nodes = 0
			var w_verts = 0
			var w_tris = 0
			var w_mats = []
			var w_aabb = AABB()
			var w_aabb_init = false
			var w_skel = null
			var w_stack = [w_inst]
			while w_stack.size() > 0:
				var wn = w_stack.pop_back()
				w_nodes += 1
				if wn is Skeleton3D and w_skel == null:
					w_skel = wn
				if wn is MeshInstance3D and wn.mesh:
					var wm = wn.mesh
					var w_aabb_curr = wn.get_aabb()
					if not w_aabb_init:
						w_aabb = w_aabb_curr
						w_aabb_init = true
					else:
						w_aabb = w_aabb.merge(w_aabb_curr)
					for s in range(wm.get_surface_count()):
						var mat = wn.get_surface_override_material(s)
						if mat == null:
							mat = wm.surface_get_material(s)
						var mname = mat.resource_name if mat and mat.resource_name != "" else (mat.get_class() if mat else "None")
						if not w_mats.has(mname):
							w_mats.append(mname)
						var arr = wm.surface_get_arrays(s)
						var v = arr[Mesh.ARRAY_VERTEX]
						var ind = arr[Mesh.ARRAY_INDEX]
						var vc = v.size() if v else 0
						var tc = (ind.size() / 3) if ind else (vc / 3)
						w_verts += vc
						w_tris += tc
				for wc in wn.get_children():
					w_stack.append(wc)
					
			print("Weapon Node count: %d" % w_nodes)
			print("Weapon Vertices: %d" % w_verts)
			print("Weapon Triangles: %d" % w_tris)
			print("Weapon Materials: %s" % str(w_mats))
			print("Weapon AABB: position=%s, size=%s" % [str(w_aabb.position), str(w_aabb.size)])
			print("Weapon Length: %.2f units" % max(w_aabb.size.x, max(w_aabb.size.y, w_aabb.size.z)))
			print("Weapon Skeleton: %s (bones: %d)" % [("Found" if w_skel else "None"), (w_skel.get_bone_count() if w_skel else 0)])
			w_inst.queue_free()
		else:
			printerr("ERROR: Could not load Weapon FBX as PackedScene")
	else:
		printerr("ERROR: Weapon FBX does not exist at: ", weapon_fbx_path)
	
	char_inst.queue_free()
	
	print("\n==================================================")
	print("DESTINED ONE TECHNICAL ASSET AUDIT COMPLETE")
	print("==================================================")
	quit(0)
