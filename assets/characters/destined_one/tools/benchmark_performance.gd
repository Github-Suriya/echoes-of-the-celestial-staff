extends SceneTree

func _init() -> void:
	print("==================================================")
	print("STARTING DESTINED ONE PERFORMANCE BENCHMARK")
	print("==================================================")
	
	# 1. Benchmark 3D Preview Scene
	print("\n--- 1. Benchmarking 3D Preview (717k Tris) ---")
	var scene_3d_res = load("res://assets/characters/destined_one/preview/DestinedOne3DPreview.tscn")
	var scene_3d = scene_3d_res.instantiate()
	root.add_child(scene_3d)
	
	var frames_3d = 0
	var start_3d = Time.get_ticks_msec()
	# Warmup + run 60 frames
	for i in range(60):
		await process_frame
		frames_3d += 1
	var elapsed_3d = float(Time.get_ticks_msec() - start_3d) / 1000.0
	var fps_3d = float(frames_3d) / elapsed_3d
	var mem_3d_mb = float(OS.get_static_memory_usage()) / (1024.0 * 1024.0)
	print("  3D Preview FPS: %.1f FPS (Elapsed: %.2fs for %d frames)" % [fps_3d, elapsed_3d, frames_3d])
	print("  3D Preview Memory: %.2f MB" % mem_3d_mb)
	scene_3d.queue_free()
	await process_frame
	
	# 2. Benchmark 2D Single-instance Preview
	print("\n--- 2. Benchmarking 2D Preview (Single Instance) ---")
	var scene_2d_res = load("res://assets/characters/destined_one/preview/DestinedOne2DPreview.tscn")
	var scene_2d = scene_2d_res.instantiate()
	root.add_child(scene_2d)
	
	var frames_2d = 0
	var start_2d = Time.get_ticks_msec()
	for i in range(60):
		await process_frame
		frames_2d += 1
	var elapsed_2d = float(Time.get_ticks_msec() - start_2d) / 1000.0
	var fps_2d = float(frames_2d) / elapsed_2d
	var mem_2d_mb = float(OS.get_static_memory_usage()) / (1024.0 * 1024.0)
	print("  2D Preview FPS: %.1f FPS (Elapsed: %.2fs for %d frames)" % [fps_2d, elapsed_2d, frames_2d])
	print("  2D Preview Memory: %.2f MB" % mem_2d_mb)
	scene_2d.queue_free()
	await process_frame
	
	# 3. Benchmark 2D Multi-Instance Scalability (1, 5, 10, 20 instances)
	print("\n--- 3. Benchmarking 2D Scalability (Multi-Instance) ---")
	var sf_res = load("res://assets/characters/destined_one/spriteframes/destined_one_512_spriteframes.tres")
	
	for count in [1, 5, 10, 20]:
		var container = Node2D.new()
		root.add_child(container)
		
		for c in range(count):
			var spr = AnimatedSprite2D.new()
			spr.sprite_frames = sf_res
			spr.animation = &"idle"
			spr.position = Vector2(100 + (c % 10) * 100, 200 + (c / 10) * 150)
			spr.scale = Vector2(0.14, 0.14)
			spr.play()
			container.add_child(spr)
			
		var m_frames = 0
		var m_start = Time.get_ticks_msec()
		for i in range(60):
			await process_frame
			m_frames += 1
		var m_elapsed = float(Time.get_ticks_msec() - m_start) / 1000.0
		var m_fps = float(m_frames) / m_elapsed
		var m_mem_mb = float(OS.get_static_memory_usage()) / (1024.0 * 1024.0)
		print("  Instances: %2d | FPS: %5.1f FPS | Memory: %6.2f MB" % [count, m_fps, m_mem_mb])
		
		container.queue_free()
		await process_frame
		
	print("\n==================================================")
	print("BENCHMARK COMPLETE")
	print("==================================================")
	quit(0)
