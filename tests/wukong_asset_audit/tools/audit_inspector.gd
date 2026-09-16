@tool
extends SceneTree

var out_lines: Array[String] = []

func log_line(txt: String) -> void:
	print(txt)
	out_lines.append(txt)

func _init() -> void:
	log_line("========================================================")
	log_line("PHASE 14A: WUKONG ASSET DETAILED TECHNICAL AUDIT REPORT")
	log_line("========================================================")
	var fbx_path = "res://tests/wukong_asset_audit/source/dasheng.fbx"
	if not ResourceLoader.exists(fbx_path):
		printerr("ERROR: FBX not found at " + fbx_path)
		quit(1)
		return
	
	var scene_res = load(fbx_path)
	if not scene_res or not (scene_res is PackedScene):
		printerr("ERROR: Failed to load FBX as PackedScene!")
		quit(1)
		return
	
	var root: Node = scene_res.instantiate()
	if not root:
		printerr("ERROR: Could not instantiate FBX root node!")
		quit(1)
		return
	
	log_line("Root node class: %s, name: %s" % [root.get_class(), root.name])
	
	var mesh_instances: Array[MeshInstance3D] = []
	var skeletons: Array[Skeleton3D] = []
	var anim_players: Array[AnimationPlayer] = []
	var all_nodes: Array[Node] = []
	
	var stack: Array[Node] = [root]
	while stack.size() > 0:
		var current = stack.pop_back()
		all_nodes.append(current)
		if current is MeshInstance3D:
			mesh_instances.append(current)
		elif current is Skeleton3D:
			skeletons.append(current)
		elif current is AnimationPlayer:
			anim_players.append(current)
		
		for child in current.get_children():
			stack.append(child)
	
	log_line("\n--- GENERAL SCENE STRUCTURE ---")
	log_line("Total Node count: %d" % all_nodes.size())
	log_line("MeshInstance3D count: %d" % mesh_instances.size())
	log_line("Skeleton3D count: %d" % skeletons.size())
	log_line("AnimationPlayer count: %d" % anim_players.size())
	for n in all_nodes:
		log_line("  Node: %s (%s, parent: %s)" % [n.name, n.get_class(), n.get_parent().name if n.get_parent() else "ROOT"])
	
	# 1. Mesh Analysis
	log_line("\n--- MESH & GEOMETRY AUDIT ---")
	var total_vertices = 0
	var total_triangles = 0
	var total_surfaces = 0
	var unique_materials: Dictionary = {}
	
	for mi in mesh_instances:
		var mesh: Mesh = mi.mesh
		if not mesh:
			log_line("MeshInstance3D %s has NO mesh" % mi.name)
			continue
		
		var surf_count = mesh.get_surface_count()
		total_surfaces += surf_count
		var mi_verts = 0
		var mi_tris = 0
		log_line("\nMeshInstance: %s (Parent: %s, SkeletonPath: %s)" % [mi.name, mi.get_parent().name, mi.skeleton])
		log_line("  Surfaces: %d" % surf_count)
		
		for s in range(surf_count):
			var arrays = mesh.surface_get_arrays(s)
			var verts = arrays[Mesh.ARRAY_VERTEX]
			var indices = arrays[Mesh.ARRAY_INDEX]
			var v_count = verts.size() if verts else 0
			var t_count = (indices.size() / 3) if indices else (v_count / 3)
			mi_verts += v_count
			mi_tris += t_count
			total_vertices += v_count
			total_triangles += t_count
			
			var mat: Material = mi.get_surface_override_material(s)
			if not mat:
				mat = mesh.surface_get_material(s)
			
			var mat_name = mat.resource_name if mat else "None"
			if mat_name == "" and mat:
				mat_name = mat.get_class() + "_" + str(mat.get_instance_id())
			if mat:
				unique_materials[mat] = mat_name
			
			var format_flags = mesh.surface_get_format(s)
			var has_normals = (format_flags & Mesh.ARRAY_FORMAT_NORMAL) != 0
			var has_tangents = (format_flags & Mesh.ARRAY_FORMAT_TANGENT) != 0
			var has_uv = (format_flags & Mesh.ARRAY_FORMAT_TEX_UV) != 0
			var has_weights = (format_flags & Mesh.ARRAY_FORMAT_WEIGHTS) != 0
			var has_bones = (format_flags & Mesh.ARRAY_FORMAT_BONES) != 0
			
			log_line("  Surface %d: Verts=%d, Tris=%d, Mat=%s, Normals=%s, Tangents=%s, UV=%s, Skinned(Bones/Weights)=%s/%s" % [
				s, v_count, t_count, mat_name, has_normals, has_tangents, has_uv, has_bones, has_weights
			])
		
		log_line("  Mesh Subtotal: Verts=%d, Tris=%d" % [mi_verts, mi_tris])
	
	log_line("\nTotal Scene Geometry: Surfaces=%d, Vertices=%d, Triangles=%d" % [total_surfaces, total_vertices, total_triangles])
	log_line("Unique Materials count: %d" % unique_materials.size())
	
	# 2. Material Audit
	log_line("\n--- MATERIAL & TEXTURE AUDIT TABLE ---")
	log_line("| MATERIAL | SURFACE | TEXTURES | STATUS | NOTES |")
	log_line("| --- | --- | --- | --- | --- |")
	for mat in unique_materials.keys():
		var mname = unique_materials[mat]
		var surf_refs: Array[String] = []
		for mi in mesh_instances:
			var m = mi.mesh
			if m:
				for s in range(m.get_surface_count()):
					var sm = mi.get_surface_override_material(s)
					if not sm: sm = m.surface_get_material(s)
					if sm == mat:
						surf_refs.append("%s:S%d" % [mi.name, s])
		
		var surf_str = ", ".join(surf_refs)
		var tex_list: Array[String] = []
		var status = "OK"
		var notes = ""
		
		if mat is StandardMaterial3D:
			var std: StandardMaterial3D = mat
			if std.albedo_texture:
				tex_list.append("Albedo:" + std.albedo_texture.resource_path.get_file())
			if std.normal_texture:
				tex_list.append("Normal:" + std.normal_texture.resource_path.get_file())
			if std.roughness_texture:
				tex_list.append("Roughness:" + std.roughness_texture.resource_path.get_file())
			if std.metallic_texture:
				tex_list.append("Metallic:" + std.metallic_texture.resource_path.get_file())
			if std.emission_texture:
				tex_list.append("Emission:" + std.emission_texture.resource_path.get_file())
			
			if std.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
				notes += "TransparencyMode=" + str(std.transparency) + " "
			if std.cull_mode != BaseMaterial3D.CULL_BACK:
				notes += "CullMode=" + str(std.cull_mode) + " "
			if tex_list.is_empty():
				notes += "No textures assigned. "
				if "hair" in mname.to_lower():
					status = "INVESTIGATE"
					notes += "Hair card material without albedo."
		
		log_line("| %s | %s | %s | %s | %s |" % [
			mname, surf_str, (", ".join(tex_list) if not tex_list.is_empty() else "None"), status, notes.strip_edges()
		])
	
	# 3. Skeleton Audit
	log_line("\n--- SKELETON AUDIT ---")
	for sk in skeletons:
		log_line("Skeleton: %s" % sk.name)
		var bone_count = sk.get_bone_count()
		log_line("  Bone Count: %d" % bone_count)
		var root_bones: Array[String] = []
		var max_depth = 0
		var deforming_bone_count = 0
		
		for b in range(bone_count):
			var bname = sk.get_bone_name(b)
			var parent_idx = sk.get_bone_parent(b)
			if parent_idx == -1:
				root_bones.append(bname)
			
			var depth = 0
			var curr = parent_idx
			while curr != -1:
				depth += 1
				curr = sk.get_bone_parent(curr)
			if depth > max_depth:
				max_depth = depth
		
		log_line("  Root Bones: %s" % str(root_bones))
		log_line("  Max Hierarchy Depth: %d" % max_depth)
		
		# Check essential deformation bone chains
		var essential_chains = {
			"Spine/Torso": ["pelvis", "Bip", "spine_01", "spine_02", "spine_03", "neck_01", "head"],
			"Left Arm": ["clavicle_l", "upperarm_l", "lowerarm_l", "hand_l"],
			"Right Arm": ["clavicle_r", "upperarm_r", "lowerarm_r", "hand_r"],
			"Left Leg": ["thigh_l", "calf_l", "foot_l", "ball_l"],
			"Right Leg": ["thigh_r", "calf_r", "foot_r", "ball_r"],
			"Weapon/Staff": ["weapon_r", "weapon_l", "staff", "jgb", "weapon"]
		}
		
		log_line("  Essential Bone Chains Check:")
		for chain in essential_chains.keys():
			var found_in_chain = []
			for bname in essential_chains[chain]:
				var bidx = sk.find_bone(bname)
				if bidx != -1:
					found_in_chain.append(bname)
			log_line("    %s: %s (Found %d of %d)" % [chain, str(found_in_chain), found_in_chain.size(), essential_chains[chain].size()])
		
		# Sample bone rest transforms
		log_line("  Sample Bone Rest Transforms:")
		for bname in ["root", "pelvis", "spine_01", "head", "upperarm_l", "upperarm_r", "thigh_l", "thigh_r"]:
			var idx = sk.find_bone(bname)
			if idx != -1:
				var rest = sk.get_bone_rest(idx)
				log_line("    Bone '%s' (idx %d): pos=%s, rot=%s, scale=%s" % [
					bname, idx, rest.origin, rest.basis.get_euler(), rest.basis.get_scale()
				])
	
	# 4. Animation Audit
	log_line("\n--- ANIMATION AUDIT ---")
	log_line("AnimationPlayer count in imported scene: %d" % anim_players.size())
	if anim_players.is_empty():
		log_line("NOTE: No AnimationPlayer exists in imported FBX scene. The FBX contains a pure bind-pose skeletal mesh with skeleton and skinning weights, but no embedded animation takes.")
	else:
		for ap in anim_players:
			log_line("AnimationPlayer: %s" % ap.name)
			var anim_list = ap.get_animation_list()
			log_line("  Total Animations: %d" % anim_list.size())
			for aname in anim_list:
				var anim: Animation = ap.get_animation(aname)
				log_line("  - '%s': Length=%.3fs, Tracks=%d, Loop=%s" % [aname, anim.length, anim.get_track_count(), anim.loop_mode])
	
	# 5. Weapon / Staff Audit
	log_line("\n--- WEAPON / STAFF AUDIT ---")
	var staff_mesh_found = false
	var staff_textures_found = []
	for mi in mesh_instances:
		var m = mi.mesh
		if m:
			for s in range(m.get_surface_count()):
				var mat = mi.get_surface_override_material(s)
				if not mat: mat = m.surface_get_material(s)
				if mat:
					var mname = mat.resource_name.to_lower()
					if "weapon" in mname or "jgb" in mname:
						log_line("Staff/Weapon geometry surface found: MeshInstance '%s', Surface %d, Material '%s'" % [mi.name, s, mat.resource_name])
						staff_mesh_found = true
	
	# Check weapon textures
	var fbm_dir = DirAccess.open("res://tests/wukong_asset_audit/source/dasheng.fbm/")
	if fbm_dir:
		fbm_dir.list_dir_begin()
		var fn = fbm_dir.get_next()
		while fn != "":
			if not fn.ends_with(".import") and not fbm_dir.current_is_dir():
				if "jgb" in fn.to_lower() or "weapon" in fn.to_lower():
					staff_textures_found.append(fn)
			fn = fbm_dir.get_next()
	
	log_line("Staff/Weapon mesh is part of character mesh: %s" % ("YES (Sub-surface of main MeshInstance)" if staff_mesh_found else "NO"))
	log_line("Staff/Weapon textures found: %s" % str(staff_textures_found))
	
	# Save raw output to file
	var out_text = "\n".join(out_lines)
	var f = FileAccess.open("res://tests/wukong_asset_audit/reports/raw_audit_data.txt", FileAccess.WRITE)
	if f:
		f.store_string(out_text)
		f.close()
		print("Wrote raw audit data to res://tests/wukong_asset_audit/reports/raw_audit_data.txt")
	
	root.queue_free()
	log_line("\n=== AUDIT INSPECTOR RUN FINISHED ===")
	quit(0)
