class_name ForbiddenForestWorld
extends WorldController

## ForbiddenForestWorld
## Main playable world coordinator for Chapter 1 — Forbidden Forest vertical slice.
## Registers the 5 contiguous rooms, coordinates persistent world state,
## player capabilities, boss HUD bindings, checkpoints, and chapter victory.

@export var room_1_data: RoomData
@export var room_2_data: RoomData
@export var room_3_data: RoomData
@export var room_4_data: RoomData
@export var room_5_data: RoomData

@onready var chapter_hud: CanvasLayer = $ChapterHUD if has_node("ChapterHUD") else null
@onready var vfx_manager: Node2D = $VFXManager if has_node("VFXManager") else null
@onready var telemetry_label: Label = find_child("TelemetryLabel", true, false) as Label
@onready var telemetry_panel: Control = find_child("DebugTelemetry", true, false) as Control

func _ready() -> void:
	_register_all_rooms()
	
	initial_room_id = &"room_01_forest_entrance"
	initial_spawn_id = &"spawn_start"
	active_checkpoint_room_id = &"room_01_forest_entrance"
	active_checkpoint_spawn_id = &"spawn_start"
	
	super._ready()
	
	if chapter_hud != null and player is PlayerController:
		chapter_hud.bind_player(player as PlayerController)
	
	_connect_boss_signals()
	
	if has_node("/root/GameManager"):
		var gm: Node = get_node("/root/GameManager")
		if gm != null and gm.has_method("set_game_state"):
			gm.set_game_state(2) # GameState.PLAYING
	
	_update_audio_for_current_room()

func _process(_delta: float) -> void:
	_update_telemetry()

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	
	match event.keycode:
		KEY_R:
			respawn_player_at_checkpoint()
			if chapter_hud != null and chapter_hud.death_overlay != null:
				chapter_hud.death_overlay.visible = false
		KEY_T:
			_restore_player_spirit()
		KEY_C:
			_cycle_player_stance()
		KEY_F:
			_trigger_awakening()
		KEY_TAB, KEY_F1:
			if telemetry_panel != null:
				telemetry_panel.visible = not telemetry_panel.visible

func _register_all_rooms() -> void:
	var list: Array[RoomData] = [room_1_data, room_2_data, room_3_data, room_4_data, room_5_data]
	var paths: Array[String] = [
		"res://data/world/forbidden_forest/room_01_forest_entrance.tres",
		"res://data/world/forbidden_forest/room_02_ancient_grove.tres",
		"res://data/world/forbidden_forest/room_03_bamboo_path.tres",
		"res://data/world/forbidden_forest/room_04_forgotten_shrine.tres",
		"res://data/world/forbidden_forest/room_05_forest_heart.tres"
	]
	
	for i in range(paths.size()):
		var rd: RoomData = list[i] if i < list.size() else null
		if rd == null and ResourceLoader.exists(paths[i]):
			rd = load(paths[i]) as RoomData
		if rd != null:
			register_room(rd)

func _update_audio_for_current_room() -> void:
	if not has_node("/root/AudioManager"):
		return
	var am: Node = get_node("/root/AudioManager")
	if am == null:
		return
	
	match current_room_id:
		&"room_01_forest_entrance", &"room_02_ancient_grove":
			am.play_ambience_by_name(&"forest_wind")
		&"room_03_bamboo_path":
			am.play_ambience_by_name(&"bamboo_rustle")
		&"room_04_forgotten_shrine":
			am.play_ambience_by_name(&"shrine_hum")
		&"room_05_forest_heart":
			am.play_ambience_by_name(&"corrupted_heart")
	
	if not world_state.has_flag(&"chapter_1_completed"):
		am.play_music_by_name(&"exploration")

func _connect_boss_signals() -> void:
	if not has_node("/root/EventBus"):
		return
	
	var bus: Node = get_node("/root/EventBus")
	if bus == null:
		return
	
	if bus.has_signal("boss_started") and not bus.boss_started.is_connected(_on_boss_started):
		bus.boss_started.connect(_on_boss_started)
	
	if bus.has_signal("boss_phase_changed") and not bus.boss_phase_changed.is_connected(_on_boss_phase_changed):
		bus.boss_phase_changed.connect(_on_boss_phase_changed)
	
	if bus.has_signal("boss_defeated") and not bus.boss_defeated.is_connected(_on_boss_defeated):
		bus.boss_defeated.connect(_on_boss_defeated)

func _on_boss_started(boss_name: String) -> void:
	if active_room == null:
		return
	
	# Find BossController in active room
	var boss: BossController = _find_active_boss(active_room)
	if boss != null and chapter_hud != null:
		chapter_hud.bind_boss(boss)
	
	if has_node("/root/AudioManager"):
		var am: Node = get_node("/root/AudioManager")
		if am != null:
			if boss_name == "Corrupted Forest Heart":
				am.play_music_by_name(&"final_boss_p1")
			else:
				am.play_music_by_name(&"intermediate_boss")

func _on_boss_phase_changed(boss_id: StringName, phase_id: int) -> void:
	if has_node("/root/AudioManager"):
		var am: Node = get_node("/root/AudioManager")
		if am != null:
			if boss_id == &"corrupted_forest_heart" and phase_id == 2:
				am.play_music_by_name(&"final_boss_p2")

func _on_boss_defeated(boss_name: String) -> void:
	if chapter_hud != null:
		chapter_hud.unbind_boss()
	
	if boss_name == "Corrupted Forest Heart":
		world_state.set_flag(&"chapter_1_completed", true)
		if chapter_hud != null:
			chapter_hud.show_chapter_complete()
		if has_node("/root/AudioManager"):
			var am: Node = get_node("/root/AudioManager")
			if am != null:
				am.play_music_by_name(&"chapter_complete")
	else:
		if has_node("/root/AudioManager"):
			var am: Node = get_node("/root/AudioManager")
			if am != null:
				am.play_music_by_name(&"exploration")

func _find_active_boss(node: Node) -> BossController:
	if node is BossController:
		return node as BossController
	for child in node.get_children():
		var found: BossController = _find_active_boss(child)
		if found != null:
			return found
	return null

func _restore_player_spirit() -> void:
	if player != null and player.has_node("Components/SpiritComponent"):
		var sc: SpiritComponent = player.get_node("Components/SpiritComponent") as SpiritComponent
		if sc != null:
			sc.restore_spirit(sc.get_max_spirit())

func _cycle_player_stance() -> void:
	if player != null and player.has_node("Components/StanceController"):
		var st: StanceController = player.get_node("Components/StanceController") as StanceController
		if st != null:
			st.cycle_stance()

func _trigger_awakening() -> void:
	if player != null and player.has_node("Components/TransformationController"):
		var tc: TransformationController = player.get_node("Components/TransformationController") as TransformationController
		if tc != null:
			if tc.is_active():
				tc.deactivate()
			else:
				tc.activate()

func _update_telemetry() -> void:
	if telemetry_label == null:
		return
	
	var fps: float = Engine.get_frames_per_second()
	var stance_str: String = "N/A"
	if player != null and player.has_node("Components/StanceController"):
		var st: StanceController = player.get_node("Components/StanceController") as StanceController
		if st != null:
			match st.get_current_stance():
				0:
					stance_str = "SWIFT"
				1:
					stance_str = "MOUNTAIN"
				2:
					stance_str = "STORM"
	
	var boss_count: int = 0
	if active_room != null:
		boss_count = 1 if _find_active_boss(active_room) != null else 0
	
	var lines: Array[String] = [
		"[CHAPTER 1: FORBIDDEN FOREST]",
		"FPS: %d (GL Compatibility)" % int(fps),
		"Room: %s" % String(current_room_id),
		"Checkpoint: %s [%s]" % [String(active_checkpoint_room_id), String(active_checkpoint_spawn_id)],
		"Stance: %s | Boss in Room: %d" % [stance_str, boss_count],
		"Defeated Bosses:",
		"  Verdant Fang: %s" % ("YES" if world_state.has_flag(&"verdant_fang_defeated") else "NO"),
		"  Bamboo Warden: %s" % ("YES" if world_state.has_flag(&"bamboo_warden_defeated") else "NO"),
		"  Hollow Keeper: %s" % ("YES" if world_state.has_flag(&"hollow_shrine_keeper_defeated") else "NO"),
		"  Forest Heart: %s" % ("YES" if world_state.has_flag(&"corrupted_forest_heart_defeated") else "NO"),
		"Chapter 1 Complete: %s" % ("YES" if world_state.has_flag(&"chapter_1_completed") else "NO"),
		"Controls: [A/D] Move | [Space] Jump | [J] Light | [K] Heavy | [Shift] Dodge | [L] Parry",
		"Shortcuts: [C] Stance | [T] Spirit | [F] Awakening | [R] Respawn | [Tab] Hide"
	]
	telemetry_label.text = "\n".join(lines)
