extends SceneTree

func _init() -> void:
	print("==================================================")
	print("BUILDING DESTINED ONE PRODUCTION MATERIALS")
	print("==================================================")
	
	var tex_dir = "res://assets/characters/destined_one/source/textures/"
	var wtex_dir = "res://assets/characters/destined_one/source/weapon/textures/"
	var mat_dir = "res://assets/characters/destined_one/materials/"
	
	var dir = DirAccess.open("res://assets/characters/destined_one/")
	if dir:
		dir.make_dir_recursive("materials")
		
	# Helper to create and save StandardMaterial3D
	var create_mat = func(mat_name: String, albedo_file: String, normal_file: String, roughness: float, metallic: float, cull: int, transp: int, scissor: float = 0.35, color_override: Color = Color.WHITE) -> StandardMaterial3D:
		var mat = StandardMaterial3D.new()
		mat.resource_name = mat_name
		mat.albedo_color = color_override
		mat.roughness = roughness
		mat.metallic = metallic
		mat.cull_mode = cull as BaseMaterial3D.CullMode
		mat.transparency = transp as BaseMaterial3D.Transparency
		
		if transp == BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR:
			mat.alpha_scissor_threshold = scissor
			
		if albedo_file != "" and ResourceLoader.exists(albedo_file):
			var tex = load(albedo_file)
			if tex is Texture2D:
				mat.albedo_texture = tex
				print("  [OK] Albedo: %s" % albedo_file.get_file())
			else:
				print("  [FAIL] Failed loading texture: %s" % albedo_file)
		elif albedo_file != "":
			print("  [MISSING] Texture does not exist: %s" % albedo_file)
			
		if normal_file != "" and ResourceLoader.exists(normal_file):
			var ntex = load(normal_file)
			if ntex is Texture2D:
				mat.normal_enabled = true
				mat.normal_texture = ntex
				print("  [OK] Normal: %s" % normal_file.get_file())
				
		var save_path = mat_dir + mat_name + ".tres"
		var err = ResourceSaver.save(mat, save_path)
		if err == OK:
			print("Saved: %s" % save_path)
		else:
			printerr("Error saving material: %d" % err)
		return mat
	
	print("\n1. Head / Face (MF_STC_LaoYing_01_Body)")
	create_mat.call("MF_STC_LaoYing_01_Body", tex_dir + "T_wukong_head_d.png", tex_dir + "T_wukong_head_n.png", 0.65, 0.0, BaseMaterial3D.CULL_BACK, BaseMaterial3D.TRANSPARENCY_DISABLED)
	
	print("\n2. Lacrimal Fluid - Tear Layer (MF_WuKong_lacrimal_fluid) [HELPER - Transparent]")
	create_mat.call("MF_WuKong_lacrimal_fluid", "", "", 0.1, 0.0, BaseMaterial3D.CULL_BACK, BaseMaterial3D.TRANSPARENCY_ALPHA, 0.1, Color(1, 1, 1, 0.0))
	
	print("\n3. Eyes (MF_WuKong_Eye_01)")
	create_mat.call("MF_WuKong_Eye_01", tex_dir + "T_wukong_head_d.png", "", 0.1, 0.0, BaseMaterial3D.CULL_BACK, BaseMaterial3D.TRANSPARENCY_DISABLED, 0.0, Color(0.88, 0.72, 0.28, 1.0))
	
	print("\n4. Eye Occlusion (MF_WuKong_Eye_Occlusion_01) [HELPER - Transparent]")
	create_mat.call("MF_WuKong_Eye_Occlusion_01", "", "", 1.0, 0.0, BaseMaterial3D.CULL_BACK, BaseMaterial3D.TRANSPARENCY_ALPHA, 0.1, Color(0, 0, 0, 0.0))
	
	print("\n5. Hair Cards (M_Wukong_Haircard_Inst)")
	create_mat.call("M_Wukong_Haircard_Inst", tex_dir + "HairTexture_basecolor.png", tex_dir + "HairTexture_normal.png", 0.7, 0.0, BaseMaterial3D.CULL_DISABLED, BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR, 0.25)
	
	print("\n6. Mouth (M_wukong_mouth)")
	create_mat.call("M_wukong_mouth", tex_dir + "T_wukong_mouth_d.png", tex_dir + "T_wukong_mouth_n.png", 0.5, 0.0, BaseMaterial3D.CULL_BACK, BaseMaterial3D.TRANSPARENCY_DISABLED)
	
	print("\n7. Cloth (MF_WuKong_Cloth_01)")
	create_mat.call("MF_WuKong_Cloth_01", tex_dir + "T_WuKong_Cloth_01_D.png", tex_dir + "T_WuKong_Cloth_01_N.png", 0.8, 0.0, BaseMaterial3D.CULL_DISABLED, BaseMaterial3D.TRANSPARENCY_DISABLED)
	
	print("\n8. Leather (MF_WuKong_Leather_01)")
	create_mat.call("MF_WuKong_Leather_01", tex_dir + "T_WuKong_Leather_01_D.png", tex_dir + "T_WuKong_Leather_01_N.png", 0.55, 0.1, BaseMaterial3D.CULL_DISABLED, BaseMaterial3D.TRANSPARENCY_DISABLED)
	
	print("\n9. Body Skin (MF_GYCY_WuKong_02_Body02)")
	create_mat.call("MF_GYCY_WuKong_02_Body02", tex_dir + "T_wukong_body_d.png", tex_dir + "T_wukong_body_n.png", 0.65, 0.0, BaseMaterial3D.CULL_BACK, BaseMaterial3D.TRANSPARENCY_DISABLED)
	
	print("\n10. Object (MF_WuKong_Object_01)")
	create_mat.call("MF_WuKong_Object_01", tex_dir + "T_WuKong_Object_01_D.png", tex_dir + "T_WuKong_Object_01_N.png", 0.6, 0.0, BaseMaterial3D.CULL_BACK, BaseMaterial3D.TRANSPARENCY_DISABLED)
	
	print("\n11. Hair Mesh Static (M_Hair_KajiyaKai_Inst)")
	create_mat.call("M_Hair_KajiyaKai_Inst", tex_dir + "HairTexture_basecolor.png", tex_dir + "HairTexture_normal.png", 0.7, 0.0, BaseMaterial3D.CULL_DISABLED, BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR, 0.25)
	
	print("\n12. Metal (MF_WuKong_Metal_01)")
	create_mat.call("MF_WuKong_Metal_01", tex_dir + "T_WuKong_Metal_01_D.png", tex_dir + "T_WuKong_Metal_01_N.png", 0.35, 0.9, BaseMaterial3D.CULL_BACK, BaseMaterial3D.TRANSPARENCY_DISABLED)
	
	print("\n13. Rope (MF_WuKong_Rope_01)")
	create_mat.call("MF_WuKong_Rope_01", tex_dir + "T_WuKong_Rope_01_D.png", tex_dir + "T_WuKong_Rope_01_N.png", 0.75, 0.0, BaseMaterial3D.CULL_BACK, BaseMaterial3D.TRANSPARENCY_DISABLED)
	
	print("\n14. Cloth Ring (M_WuKong_Born_Cloth_Ring_Layers)")
	create_mat.call("M_WuKong_Born_Cloth_Ring_Layers", tex_dir + "T_WuKong_Born_Cloth_Ring_D.png", tex_dir + "T_WuKong_Born_Cloth_Ring_N.png", 0.7, 0.0, BaseMaterial3D.CULL_DISABLED, BaseMaterial3D.TRANSPARENCY_DISABLED)
	
	print("\n15. Weapon Staff (MF_HGS_WuKong_JGB_01)")
	create_mat.call("MF_HGS_WuKong_JGB_01", wtex_dir + "T_HGS_WuKong_JGB_01_D.png", wtex_dir + "T_HGS_WuKong_JGB_01_N.png", 0.35, 0.85, BaseMaterial3D.CULL_BACK, BaseMaterial3D.TRANSPARENCY_DISABLED)
	
	print("\n16. Weapon FX (M_wukong_weapon_fx) [Additive FX shell - transparent for base render]")
	var wfx = StandardMaterial3D.new()
	wfx.resource_name = "M_wukong_weapon_fx"
	wfx.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wfx.albedo_color = Color(1.0, 0.5, 0.1, 0.0) # Transparent shell so textured staff shows
	wfx.cull_mode = BaseMaterial3D.CULL_BACK
	ResourceSaver.save(wfx, mat_dir + "M_wukong_weapon_fx.tres")
	
	print("\n==================================================")
	print("ALL MATERIALS BUILT AND SAVED CLEANLY!")
	print("==================================================")
	quit(0)
