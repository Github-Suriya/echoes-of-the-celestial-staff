@tool
extends SceneTree

## AssetGenerator
## Procedural generator that creates genuine, high-clarity 2D SpriteFrames and environment textures
## for Phase 12 Forbidden Forest visual integration in Echoes of the Celestial Staff.

func _init() -> void:
	print("[ASSET_GEN] Generating Phase 12 2D SpriteFrames and Environment Textures...")
	
	_ensure_dir("res://assets/art/characters")
	_ensure_dir("res://assets/art/enemies")
	_ensure_dir("res://assets/art/bosses")
	_ensure_dir("res://assets/art/environments")
	
	_generate_yuan_sprites()
	_generate_enemy_sprites()
	_generate_boss_sprites()
	_generate_environment_textures()
	
	print("[ASSET_GEN] Phase 12 assets successfully generated and saved.")
	quit(0)

func _ensure_dir(path: String) -> void:
	var dir: DirAccess = DirAccess.open("res://")
	if dir != null and not dir.dir_exists(path.replace("res://", "")):
		dir.make_dir_recursive(path.replace("res://", ""))

# -------------------------------------------------------------------------
# Player Yuan Sprites
# -------------------------------------------------------------------------

func _generate_yuan_sprites() -> void:
	var sf: SpriteFrames = SpriteFrames.new()
	var w: int = 64
	var h: int = 64
	
	var c_robe: Color = Color(0.086, 0.627, 0.521, 1.0) # Jade
	var c_head: Color = Color(0.172, 0.243, 0.313, 1.0) # Charcoal
	var c_sash: Color = Color(0.905, 0.298, 0.235, 1.0) # Crimson
	var c_staff: Color = Color(0.85, 0.72, 0.30, 1.0) # Celestial Gold
	var c_gold_glow: Color = Color(1.0, 0.85, 0.2, 0.8)
	
	var anim_configs: Dictionary = {
		"idle": {"frames": 4, "speed": 6.0, "pose": "idle"},
		"run": {"frames": 6, "speed": 12.0, "pose": "run"},
		"jump": {"frames": 2, "speed": 8.0, "pose": "jump"},
		"fall": {"frames": 2, "speed": 8.0, "pose": "fall"},
		"land": {"frames": 2, "speed": 10.0, "pose": "land"},
		"light_1": {"frames": 4, "speed": 10.0, "pose": "atk1"},
		"light_2": {"frames": 4, "speed": 10.0, "pose": "atk2"},
		"light_3": {"frames": 5, "speed": 10.0, "pose": "atk3"},
		"heavy_1": {"frames": 6, "speed": 10.0, "pose": "heavy"},
		"charge_heavy": {"frames": 4, "speed": 8.0, "pose": "charge"},
		"air_1": {"frames": 4, "speed": 12.0, "pose": "air"},
		"dodge": {"frames": 4, "speed": 12.0, "pose": "dodge"},
		"parry": {"frames": 3, "speed": 10.0, "pose": "parry"},
		"perfect_parry": {"frames": 3, "speed": 10.0, "pose": "pparry"},
		"hit_reaction": {"frames": 2, "speed": 8.0, "pose": "hit"},
		"death": {"frames": 5, "speed": 8.0, "pose": "death"},
		"ability_celestial_arc": {"frames": 4, "speed": 12.0, "pose": "arc"},
		"ability_heavenly_pulse": {"frames": 4, "speed": 10.0, "pose": "pulse"},
		"ability_cloud_step": {"frames": 4, "speed": 14.0, "pose": "cloud"},
		"transformation_activate": {"frames": 4, "speed": 10.0, "pose": "trans_start"},
		"transformation_active": {"frames": 4, "speed": 8.0, "pose": "trans_loop"},
		"transformation_end": {"frames": 3, "speed": 8.0, "pose": "trans_end"}
	}
	
	for anim_name in anim_configs.keys():
		var cfg: Dictionary = anim_configs[anim_name]
		sf.add_animation(anim_name)
		sf.set_animation_speed(anim_name, cfg["speed"])
		sf.set_animation_loop(anim_name, anim_name in ["idle", "run", "charge_heavy", "transformation_active"])
		
		var fcount: int = cfg["frames"]
		var pose: String = cfg["pose"]
		for f in range(fcount):
			var img: Image = Image.create(w, h, false, Image.FORMAT_RGBA8)
			_render_yuan_frame(img, w, h, pose, f, fcount, c_robe, c_head, c_sash, c_staff, c_gold_glow)
			var tex: ImageTexture = ImageTexture.create_from_image(img)
			sf.add_frame(anim_name, tex)
	
	ResourceSaver.save(sf, "res://assets/art/characters/yuan_spritesheet.tres")

func _render_yuan_frame(img: Image, w: int, h: int, pose: String, frame_idx: int, total_frames: int, c_robe: Color, c_head: Color, c_sash: Color, c_staff: Color, c_glow: Color) -> void:
	var cx: int = w / 2
	var ground_y: int = h - 6
	var t: float = float(frame_idx) / float(max(1, total_frames - 1))
	
	# Compute bob and offsets based on pose
	var bob_y: int = 0
	var lean_x: int = 0
	var staff_rot: float = 0.0
	var is_trans: bool = pose.begins_with("trans")
	
	match pose:
		"idle":
			bob_y = int(sin(float(frame_idx) * PI * 0.5) * 1.5)
		"run":
			bob_y = int(abs(sin(float(frame_idx) * PI)) * 3.0)
			lean_x = 3
			staff_rot = sin(float(frame_idx) * PI * 0.7) * 0.4
		"jump":
			bob_y = -6
		"fall":
			bob_y = 2
		"land":
			bob_y = 4
		"atk1", "atk2":
			lean_x = 5
			staff_rot = lerpf(-0.8, 0.8, t)
		"atk3", "heavy":
			lean_x = 7
			staff_rot = lerpf(-1.4, 1.2, t)
		"dodge":
			bob_y = 12
			lean_x = int(t * 8.0)
		"parry", "pparry":
			lean_x = -2
			staff_rot = 1.57 # Vertical guard
		"death":
			bob_y = int(t * 16.0)
			lean_x = int(t * 6.0)
	
	var base_y: int = ground_y + bob_y
	var base_x: int = cx + lean_x
	
	# Transformation Aura
	if is_trans:
		_draw_rect(img, base_x - 14, base_y - 48, 28, 48, c_glow)
	
	# Body / Robe
	_draw_rect(img, base_x - 8, base_y - 44, 16, 42, c_robe)
	# Head
	_draw_rect(img, base_x - 6, base_y - 46, 12, 12, c_head)
	# Crimson Sash
	var sash_wave: int = int(sin(float(frame_idx) * 1.5) * 4.0)
	_draw_rect(img, base_x - 12 + sash_wave, base_y - 28, 14, 6, c_sash)
	# Eyes / Headband
	_draw_rect(img, base_x + 1, base_y - 42, 3, 3, Color(0.95, 0.8, 0.2))
	
	# Celestial Staff
	if pose != "dodge" and pose != "death":
		var staff_cx: int = base_x + 8 + int(sin(staff_rot) * 14.0)
		var staff_top_y: int = base_y - 46 + int(cos(staff_rot) * 4.0)
		_draw_rect(img, staff_cx, staff_top_y, 4, 44, c_staff)
		# Staff radiant tip
		_draw_rect(img, staff_cx - 1, staff_top_y - 2, 6, 6, Color(1.0, 0.95, 0.5))

# -------------------------------------------------------------------------
# Normal Enemies Sprites
# -------------------------------------------------------------------------

func _generate_enemy_sprites() -> void:
	# 1. Forest Scout (64x64, Agile orange/rust predator)
	var sf_scout: SpriteFrames = _create_standard_enemy_frames(
		64, 64,
		Color(0.82, 0.45, 0.18), # Body
		Color(0.95, 0.75, 0.15), # Eyes
		Color(0.60, 0.25, 0.10), # Claws
		"scout"
	)
	ResourceSaver.save(sf_scout, "res://assets/art/enemies/forest_scout_sprites.tres")
	
	# 2. Thorn Beast (96x96, Broad stony bramble brute)
	var sf_thorn: SpriteFrames = _create_standard_enemy_frames(
		96, 96,
		Color(0.28, 0.32, 0.30), # Dark bark
		Color(0.90, 0.30, 0.20), # Glowing red eyes
		Color(0.70, 0.50, 0.20), # Thorn horns
		"thorn"
	)
	ResourceSaver.save(sf_thorn, "res://assets/art/enemies/thorn_beast_sprites.tres")
	
	# 3. Spore Caster (64x64, Slender fungal caster)
	var sf_spore: SpriteFrames = _create_standard_enemy_frames(
		64, 64,
		Color(0.35, 0.42, 0.38), # Lichen robe
		Color(0.70, 0.30, 0.85), # Violet spore core
		Color(0.40, 0.90, 0.50), # Lime spore cap
		"spore"
	)
	ResourceSaver.save(sf_spore, "res://assets/art/enemies/spore_caster_sprites.tres")

func _create_standard_enemy_frames(w: int, h: int, c_body: Color, c_accent: Color, c_feature: Color, enemy_type: String) -> SpriteFrames:
	var sf: SpriteFrames = SpriteFrames.new()
	var anims: Dictionary = {
		"idle": {"frames": 4, "speed": 6.0},
		"move": {"frames": 6, "speed": 10.0},
		"attack": {"frames": 5, "speed": 10.0},
		"cast": {"frames": 5, "speed": 8.0},
		"hit": {"frames": 2, "speed": 8.0},
		"stagger": {"frames": 4, "speed": 8.0},
		"death": {"frames": 5, "speed": 8.0}
	}
	
	for anim_name in anims.keys():
		var cfg: Dictionary = anims[anim_name]
		sf.add_animation(anim_name)
		sf.set_animation_speed(anim_name, cfg["speed"])
		sf.set_animation_loop(anim_name, anim_name in ["idle", "move"])
		
		var fcount: int = cfg["frames"]
		for f in range(fcount):
			var img: Image = Image.create(w, h, false, Image.FORMAT_RGBA8)
			_render_enemy_frame(img, w, h, enemy_type, anim_name, f, fcount, c_body, c_accent, c_feature)
			var tex: ImageTexture = ImageTexture.create_from_image(img)
			sf.add_frame(anim_name, tex)
	
	return sf

func _render_enemy_frame(img: Image, w: int, h: int, enemy_type: String, anim_name: String, f: int, fcount: int, c_body: Color, c_eye: Color, c_feat: Color) -> void:
	var cx: int = w / 2
	var ground_y: int = h - 6
	var t: float = float(f) / float(max(1, fcount - 1))
	
	var bob: int = 0
	var lurch: int = 0
	if anim_name == "move":
		bob = int(abs(sin(float(f) * PI)) * 3.0)
		lurch = 2
	elif anim_name == "attack" or anim_name == "cast":
		lurch = int(lerpf(-2.0, 6.0, t))
	elif anim_name == "hit":
		lurch = -4
	elif anim_name == "death":
		bob = int(t * 14.0)
	
	var bx: int = cx + lurch
	var by: int = ground_y + bob
	
	match enemy_type:
		"scout":
			# Hunched agile predator
			_draw_rect(img, bx - 10, by - 36, 20, 34, c_body)
			_draw_rect(img, bx + 2, by - 32, 4, 4, c_eye)
			# Claw arm
			var claw_x: int = bx + 8 + (6 if anim_name == "attack" else 0)
			_draw_rect(img, claw_x, by - 24, 6, 14, c_feat)
		"thorn":
			# Broad heavy armored brute
			_draw_rect(img, bx - 20, by - 52, 40, 50, c_body)
			_draw_rect(img, bx - 4, by - 46, 8, 4, c_eye)
			# Horns / Thorns
			_draw_rect(img, bx - 18, by - 58, 8, 10, c_feat)
			_draw_rect(img, bx + 10, by - 58, 8, 10, c_feat)
		"spore":
			# Slender shaman with glowing bulb
			_draw_rect(img, bx - 8, by - 46, 16, 44, c_body)
			_draw_rect(img, bx - 12, by - 56, 24, 14, c_feat) # Fungal cap
			_draw_rect(img, bx - 4, by - 52, 8, 8, c_eye) # Glowing spore bulb

# -------------------------------------------------------------------------
# Boss Sprites
# -------------------------------------------------------------------------

func _generate_boss_sprites() -> void:
	# 1. Verdant Fang (128x96, Predatory elder beast)
	var sf_fang: SpriteFrames = _create_boss_frames(
		128, 96,
		Color(0.12, 0.32, 0.22), # Dark pelt
		Color(0.18, 0.85, 0.45), # Emerald glow
		Color(0.45, 0.35, 0.20), # Bramble spine
		["idle", "move", "attack", "pounce", "claw", "hit", "stagger", "death"]
	)
	ResourceSaver.save(sf_fang, "res://assets/art/bosses/verdant_fang_sprites.tres")
	
	# 2. Bamboo Warden (96x128, Tall bamboo martial ascetic)
	var sf_warden: SpriteFrames = _create_boss_frames(
		96, 128,
		Color(0.55, 0.45, 0.15), # Bamboo armor
		Color(0.85, 0.80, 0.40), # Straw hat
		Color(0.40, 0.65, 0.25), # Polearm green
		["idle", "move", "attack", "combo", "sweep", "thrust", "hit", "stagger", "death"]
	)
	ResourceSaver.save(sf_warden, "res://assets/art/bosses/bamboo_warden_sprites.tres")
	
	# 3. Hollow Shrine Keeper (128x128, Massive ancient stone construct)
	var sf_keeper: SpriteFrames = _create_boss_frames(
		128, 128,
		Color(0.32, 0.36, 0.38), # Weathered granite
		Color(0.15, 0.85, 0.95), # Cyan soul core
		Color(0.55, 0.52, 0.48), # Stone cleaver
		["idle", "move", "attack", "cleave", "slam", "spirit_wave", "hit", "stagger", "death"]
	)
	ResourceSaver.save(sf_keeper, "res://assets/art/bosses/hollow_shrine_keeper_sprites.tres")
	
	# 4. Corrupted Forest Heart (192x192, Primordial root avatar)
	var sf_heart: SpriteFrames = _create_boss_frames(
		192, 192,
		Color(0.18, 0.14, 0.12), # Dark primordial wood
		Color(0.85, 0.12, 0.35), # Corrupted violet/crimson
		Color(0.95, 0.75, 0.20), # Celestial core remnant
		[
			"idle", "move", "attack", "root_strike", "spore_burst", "heavy_slam",
			"transition", "frenzy_flurry", "ground_rupture", "hit", "stagger", "death"
		]
	)
	ResourceSaver.save(sf_heart, "res://assets/art/bosses/corrupted_forest_heart_sprites.tres")

func _create_boss_frames(w: int, h: int, c_body: Color, c_glow: Color, c_acc: Color, anim_list: Array) -> SpriteFrames:
	var sf: SpriteFrames = SpriteFrames.new()
	for anim_name in anim_list:
		sf.add_animation(anim_name)
		sf.set_animation_speed(anim_name, 10.0 if anim_name in ["move", "combo", "frenzy_flurry"] else 6.0)
		sf.set_animation_loop(anim_name, anim_name in ["idle", "move"])
		
		var fcount: int = 4
		if anim_name in ["transition", "death"]:
			fcount = 6
		
		for f in range(fcount):
			var img: Image = Image.create(w, h, false, Image.FORMAT_RGBA8)
			var cx: int = w / 2
			var ground_y: int = h - 8
			var t: float = float(f) / float(max(1, fcount - 1))
			
			var bob: int = int(sin(float(f) * PI * 0.5) * 2.0)
			var stretch_x: int = 0
			if anim_name in ["slam", "heavy_slam", "ground_rupture"]:
				stretch_x = int(lerpf(0.0, 10.0, t))
			
			# Draw layered boss mass
			_draw_rect(img, cx - 28 - stretch_x, ground_y - 70 + bob, 56 + stretch_x * 2, 68, c_body)
			_draw_rect(img, cx - 14, ground_y - 50 + bob, 28, 24, c_glow)
			_draw_rect(img, cx - 20, ground_y - 82 + bob, 40, 14, c_acc)
			
			var tex: ImageTexture = ImageTexture.create_from_image(img)
			sf.add_frame(anim_name, tex)
	
	return sf

# -------------------------------------------------------------------------
# Environment Modular Textures
# -------------------------------------------------------------------------

func _generate_environment_textures() -> void:
	# 1. Mossy Forest Ground (256x64)
	var img_ground: Image = Image.create(256, 64, false, Image.FORMAT_RGBA8)
	_fill_gradient(img_ground, Color(0.18, 0.35, 0.22), Color(0.10, 0.18, 0.12))
	# Add grass top tufts
	for x in range(0, 256, 4):
		var gh: int = 4 + (x % 3) * 2
		_draw_rect(img_ground, x, 0, 2, gh, Color(0.28, 0.58, 0.32))
	var tex_ground: ImageTexture = ImageTexture.create_from_image(img_ground)
	ResourceSaver.save(tex_ground, "res://assets/art/environments/tex_forest_ground.tres")
	
	# 2. Bamboo Stalks (128x256)
	var img_bamboo: Image = Image.create(128, 256, false, Image.FORMAT_RGBA8)
	for bx in [20, 60, 100]:
		_draw_rect(img_bamboo, bx - 6, 0, 12, 256, Color(0.42, 0.58, 0.28))
		# Bamboo nodes
		for ny in range(0, 256, 48):
			_draw_rect(img_bamboo, bx - 8, ny, 16, 4, Color(0.28, 0.40, 0.18))
	var tex_bamboo: ImageTexture = ImageTexture.create_from_image(img_bamboo)
	ResourceSaver.save(tex_bamboo, "res://assets/art/environments/tex_bamboo_stalks.tres")
	
	# 3. Weathered Shrine Stone (256x128)
	var img_stone: Image = Image.create(256, 128, false, Image.FORMAT_RGBA8)
	_fill_gradient(img_stone, Color(0.28, 0.32, 0.35), Color(0.18, 0.22, 0.24))
	# Stone mortar lines
	for sy in range(0, 128, 32):
		_draw_rect(img_stone, 0, sy, 256, 2, Color(0.12, 0.14, 0.16))
	for sx in range(0, 256, 64):
		_draw_rect(img_stone, sx, 0, 2, 128, Color(0.12, 0.14, 0.16))
	var tex_stone: ImageTexture = ImageTexture.create_from_image(img_stone)
	ResourceSaver.save(tex_stone, "res://assets/art/environments/tex_shrine_stone.tres")
	
	# 4. Corrupted Roots (256x128)
	var img_root: Image = Image.create(256, 128, false, Image.FORMAT_RGBA8)
	_fill_gradient(img_root, Color(0.15, 0.10, 0.12), Color(0.08, 0.05, 0.08))
	# Crimson veins
	for vy in range(20, 110, 30):
		_draw_rect(img_root, 0, vy, 256, 4, Color(0.75, 0.12, 0.28, 0.8))
	var tex_root: ImageTexture = ImageTexture.create_from_image(img_root)
	ResourceSaver.save(tex_root, "res://assets/art/environments/tex_corrupted_roots.tres")

# -------------------------------------------------------------------------
# Utility Helpers
# -------------------------------------------------------------------------

func _draw_rect(img: Image, x: int, y: int, rw: int, rh: int, col: Color) -> void:
	var img_w: int = img.get_width()
	var img_h: int = img.get_height()
	for py in range(y, y + rh):
		if py < 0 or py >= img_h:
			continue
		for px in range(x, x + rw):
			if px < 0 or px >= img_w:
				continue
			var orig: Color = img.get_pixel(px, py)
			var blended: Color = col if col.a >= 0.99 else orig.blend(col)
			img.set_pixel(px, py, blended)

func _fill_gradient(img: Image, top_col: Color, bot_col: Color) -> void:
	var w: int = img.get_width()
	var h: int = img.get_height()
	for py in range(h):
		var t: float = float(py) / float(max(1, h - 1))
		var col: Color = top_col.lerp(bot_col, t)
		for px in range(w):
			img.set_pixel(px, py, col)
