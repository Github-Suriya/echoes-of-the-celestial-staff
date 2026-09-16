@tool
extends SceneTree

## Automated Batch Renderer for Knight 3D -> 2D Sprite Pipeline.
## Renders 512x512 transparent RGBA sprites at 30 FPS for Idle, Walking, and Run.
## Assembles them into SpriteFrames and generates optional spritesheet atlases.

const RENDER_SOURCE_SCENE := "res://tests/knight_3d_to_2d/source/KnightRenderSource.tscn"
const SPRITE_DIR := "res://tests/knight_3d_to_2d/sprites/"
const GENERATED_DIR := "res://tests/knight_3d_to_2d/generated/"
const SPRITESHEET_DIR := "res://tests/knight_3d_to_2d/generated/spritesheets/"

const TARGET_FPS := 30.0
const RENDER_SIZE := Vector2i(512, 512)

const ANIMATIONS_TO_RENDER: Dictionary = {
	"idle": "HumanArmature|Idle",
	"walking": "HumanArmature|Walking",
	"run": "HumanArmature|Run"
}


func _init() -> void:
	print("==================================================")
	print("STARTING KNIGHT 3D -> 2D BATCH RENDERING PIPELINE")
	print("==================================================")
	
	await _run_pipeline()
	quit()


func _run_pipeline() -> void:
	# 1. Setup Offscreen Viewport
	var root_node := Node3D.new()
	root.add_child(root_node)
	
	var vp := SubViewport.new()
	vp.size = RENDER_SIZE
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root_node.add_child(vp)
	
	var source_packed: PackedScene = load(RENDER_SOURCE_SCENE) as PackedScene
	if not source_packed:
		printerr("[ERROR] Failed to load render source scene: ", RENDER_SOURCE_SCENE)
		return
	
	var scene_inst: Node3D = source_packed.instantiate() as Node3D
	vp.add_child(scene_inst)
	
	var ap: AnimationPlayer = scene_inst.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if not ap:
		printerr("[ERROR] AnimationPlayer not found in render source scene!")
		return
	
	# Warm up rendering engine
	for i in range(5):
		await process_frame
	
	var rendered_frame_paths: Dictionary = {}
	
	# 2. Render each requested animation
	for anim_key in ANIMATIONS_TO_RENDER.keys():
		var raw_anim_name: String = ANIMATIONS_TO_RENDER[anim_key]
		if not ap.has_animation(raw_anim_name):
			printerr("[ERROR] Missing animation track: ", raw_anim_name)
			continue
		
		var anim: Animation = ap.get_animation(raw_anim_name)
		var duration: float = anim.length
		var total_frames: int = roundi(duration * TARGET_FPS)
		
		print("\nRendering '%s' (track '%s'): duration %.3fs -> %d frames at %d FPS" % [
			anim_key, raw_anim_name, duration, total_frames, int(TARGET_FPS)
		])
		
		var out_dir: String = SPRITE_DIR + anim_key + "/"
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
		
		rendered_frame_paths[anim_key] = []
		ap.play(raw_anim_name)
		
		for frame_idx in range(total_frames):
			var sample_time: float = float(frame_idx) / TARGET_FPS
			if sample_time > duration:
				sample_time = duration
			
			ap.seek(sample_time, true)
			
			# Wait for scene graph and renderer update
			await process_frame
			await process_frame
			
			var tex: ViewportTexture = vp.get_texture()
			var img: Image = tex.get_image()
			
			var frame_filename: String = "%04d.png" % frame_idx
			var full_res_path: String = out_dir + frame_filename
			var global_out_path: String = ProjectSettings.globalize_path(full_res_path)
			
			var err: Error = img.save_png(global_out_path)
			if err == OK:
				rendered_frame_paths[anim_key].append(full_res_path)
			else:
				printerr("  Failed to save frame %d to %s: error %d" % [frame_idx, full_res_path, err])
			
			if frame_idx % 25 == 0 or frame_idx == total_frames - 1:
				print("  Rendered frame [%d/%d] (t = %.3fs)" % [frame_idx + 1, total_frames, sample_time])
		
		print("[SUCCESS] Completed '%s': %d frames saved to %s" % [
			anim_key, rendered_frame_paths[anim_key].size(), out_dir
		])
	
	root_node.free()
	
	# 3. Assemble SpriteFrames resource
	print("\n--- Assembling SpriteFrames Resource ---")
	_assemble_sprite_frames(rendered_frame_paths)
	
	# 4. Generate Spritesheet Atlases (optional performance format)
	print("\n--- Generating Spritesheet Atlases ---")
	_generate_spritesheets(rendered_frame_paths)
	
	print("\n==================================================")
	print("BATCH RENDERING PIPELINE COMPLETE!")
	print("==================================================")


func _assemble_sprite_frames(rendered_paths: Dictionary) -> void:
	var sprite_frames := SpriteFrames.new()
	if sprite_frames.has_animation("default"):
		sprite_frames.remove_animation("default")
	
	for anim_name in rendered_paths.keys():
		sprite_frames.add_animation(anim_name)
		sprite_frames.set_animation_speed(anim_name, TARGET_FPS)
		sprite_frames.set_animation_loop(anim_name, true)
		
		var frames: Array = rendered_paths[anim_name]
		for path in frames:
			var img: Image = Image.load_from_file(ProjectSettings.globalize_path(path))
			if img:
				var tex: ImageTexture = ImageTexture.create_from_image(img)
				sprite_frames.add_frame(anim_name, tex)
		
		print("  SpriteFrames added animation '%s' with %d frames (loop = true, fps = 30)" % [
			anim_name, sprite_frames.get_frame_count(anim_name)
		])
	
	var save_path := GENERATED_DIR + "knight_spriteframes.tres"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(GENERATED_DIR))
	var err := ResourceSaver.save(sprite_frames, save_path)
	if err == OK:
		print("[SUCCESS] Saved SpriteFrames resource to: ", save_path)
	else:
		printerr("[ERROR] Failed to save SpriteFrames: ", err)


func _generate_spritesheets(rendered_paths: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SPRITESHEET_DIR))
	
	for anim_name in rendered_paths.keys():
		var frames: Array = rendered_paths[anim_name]
		var count: int = frames.size()
		if count == 0:
			continue
		
		# Choose grid dimensions based on count
		var cols: int = 10
		if count <= 25:
			cols = 5
		elif count <= 40:
			cols = 8
		var rows: int = ceili(float(count) / float(cols))
		
		# Downscale tiles to 256x256 for reasonable sheet resolution (e.g. 5x5 = 1280x1280, 10x10 = 2560x2560)
		var tile_w := 256
		var tile_h := 256
		var sheet_w: int = cols * tile_w
		var sheet_h: int = rows * tile_h
		
		var sheet_img := Image.create(sheet_w, sheet_h, false, Image.FORMAT_RGBA8)
		sheet_img.fill(Color(0, 0, 0, 0)) # Clean transparent background
		
		for i in range(count):
			var frame_path: String = frames[i]
			var img: Image = Image.load_from_file(ProjectSettings.globalize_path(frame_path))
			if img:
				img.resize(tile_w, tile_h, Image.INTERPOLATE_LANCZOS)
				var c := i % cols
				var r := i / cols
				var dest_x := c * tile_w
				var dest_y := r * tile_h
				sheet_img.blit_rect(img, Rect2i(0, 0, tile_w, tile_h), Vector2i(dest_x, dest_y))
		
		var sheet_out_path := SPRITESHEET_DIR + "knight_%s.png" % anim_name
		var err := sheet_img.save_png(ProjectSettings.globalize_path(sheet_out_path))
		if err == OK:
			print("  Generated spritesheet: %s (%dx%d, %d tiles)" % [
				sheet_out_path, sheet_w, sheet_h, count
			])
		else:
			printerr("  Failed to save spritesheet: ", sheet_out_path)
