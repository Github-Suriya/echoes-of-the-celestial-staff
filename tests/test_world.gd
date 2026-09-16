extends Node

## Automated Metroidvania World System Foundation Test Suite (Phase 10)
## Validates:
## - WorldData & RoomData Resources
## - PlayerCapabilities Progression Gating
## - Persistent WorldState & Flags
## - Room2D Lifecycle & Invariant Transitions
## - Room Transitions & Player Repositioning
## - Camera Bounds Clamping & Smoothing
## - Ability-Gated Doors (Celestial Arc & Cloud Step)
## - Checkpoint System & Respawn Handling
## - Persistent World Objects
## - Granite Abbot World Persistence Integration
## - SaveManager Slot Integration & Serialization
## - Transition Safety, Re-entrancy & Error Handling

var _tests_passed: int = 0
var _tests_failed: int = 0

func _ready() -> void:
	print("\n==================================================")
	print(" RUNNING PHASE 10 METROIDVANIA WORLD SYSTEM TEST SUITE")
	print("==================================================")
	
	_test_01_world_data_and_room_data()
	_test_02_player_capabilities()
	_test_03_world_state_and_flags()
	_test_04_room_2d_lifecycle()
	_test_05_room_transitions_and_spawning()
	_test_06_camera_bounds_and_smoothing()
	_test_07_ability_gates()
	_test_08_checkpoint_system()
	_test_09_persistent_world_objects()
	_test_10_granite_abbot_persistence()
	_test_11_save_manager_integration()
	_test_12_safety_reentrancy_and_errors()
	
	print("==================================================")
	print(" WORLD SYSTEM TEST RESULTS: %d / %d PASSED (%d FAILED)" % [
		_tests_passed,
		_tests_passed + _tests_failed,
		_tests_failed
	])
	print("==================================================")
	
	if _tests_failed == 0:
		print("\nSUCCESS: All Phase 10 Metroidvania World System tests passed cleanly.\n")
		get_tree().quit(0)
	else:
		push_error("FAILURE: %d world system tests failed." % _tests_failed)
		get_tree().quit(1)

func _assert(condition: bool, test_name: String) -> void:
	if condition:
		_tests_passed += 1
		print("[PASS] %s" % test_name)
	else:
		_tests_failed += 1
		printerr("[FAIL] %s" % test_name)

# ==============================================================================
# CATEGORY 1: WORLD DATA & ROOMDATA RESOURCES
# ==============================================================================
func _test_01_world_data_and_room_data() -> void:
	print("\n--- Category 1: World Data & RoomData Resources ---")
	
	var rdata: RoomData = RoomData.new(
		&"test_room",
		"Test Room",
		"res://scenes/world/room_2d.tscn",
		Rect2(0, 0, 1920, 1080),
		[&"default", &"left", &"right"],
		{ "exit_a": { "destination_room_id": &"room_b", "destination_spawn_id": &"start" } }
	)
	_assert(rdata != null, "DATA-01: RoomData resource instantiated")
	_assert(rdata.is_valid(), "DATA-02: RoomData validation passes for complete definition")
	
	var invalid_id: RoomData = RoomData.new(&"", "No ID", "res://scene.tscn")
	_assert(not invalid_id.is_valid(), "DATA-03: RoomData validation fails when room_id is empty")
	
	var invalid_path: RoomData = RoomData.new(&"r1", "No Path", "")
	_assert(not invalid_path.is_valid(), "DATA-04: RoomData validation fails when scene_path is empty")
	
	var invalid_bounds: RoomData = RoomData.new(&"r2", "Bad Bounds", "res://scene.tscn", Rect2(0, 0, 0, -10))
	_assert(not invalid_bounds.is_valid(), "DATA-05: RoomData validation fails when room_bounds size is zero or negative")
	
	_assert(rdata.has_spawn_point(&"default"), "DATA-06: has_spawn_point returns true for registered spawn point")
	_assert(not rdata.has_spawn_point(&"unknown_spawn"), "DATA-07: has_spawn_point returns false for unknown spawn point")
	
	var conn: Dictionary = rdata.get_connection(&"exit_a")
	_assert(conn.get("destination_room_id") == &"room_b", "DATA-08: get_connection returns target destination room ID")
	_assert(rdata.get_connection(&"non_existent").is_empty(), "DATA-09: get_connection returns empty dict for unknown exit")
	
	var res_a: Resource = load("res://data/world/room_a.tres")
	var res_b: Resource = load("res://data/world/room_b.tres")
	var res_c: Resource = load("res://data/world/room_c.tres")
	_assert(res_a is RoomData and res_b is RoomData and res_c is RoomData, "DATA-10: Predefined test world room .tres resources load valid RoomData")

# ==============================================================================
# CATEGORY 2: PLAYER CAPABILITIES & PROGRESSION UNLOCKS
# ==============================================================================
func _test_02_player_capabilities() -> void:
	print("\n--- Category 2: Player Capabilities & Progression Unlocks ---")
	
	var caps: PlayerCapabilities = PlayerCapabilities.new()
	_assert(caps.get_unlocked_abilities().is_empty(), "CAPS-01: PlayerCapabilities initializes with 0 unlocked abilities")
	_assert(not caps.has_ability(&"celestial_arc"), "CAPS-02: has_ability returns false for locked capability")
	
	var unlocked: bool = caps.unlock_ability(&"celestial_arc")
	_assert(unlocked, "CAPS-03: unlock_ability grants capability and returns true")
	
	var dup_unlocked: bool = caps.unlock_ability(&"celestial_arc")
	_assert(not dup_unlocked, "CAPS-04: Duplicate unlock_ability is idempotent and returns false")
	_assert(caps.has_ability(&"celestial_arc"), "CAPS-05: has_ability returns true for unlocked capability")
	
	var locked: bool = caps.lock_ability(&"celestial_arc")
	_assert(locked, "CAPS-06: lock_ability revokes capability and returns true")
	_assert(not caps.lock_ability(&"celestial_arc"), "CAPS-07: lock_ability on ungranted ability returns false")
	
	caps.toggle_ability(&"cloud_step")
	_assert(caps.has_ability(&"cloud_step"), "CAPS-08: toggle_ability unlocks ability from locked state")
	caps.toggle_ability(&"cloud_step")
	_assert(not caps.has_ability(&"cloud_step"), "CAPS-09: toggle_ability locks ability from unlocked state")
	
	caps.unlock_ability(&"celestial_arc")
	caps.unlock_ability(&"cloud_step")
	caps.clear_capabilities()
	_assert(caps.get_unlocked_abilities().is_empty() and not caps.has_ability(&"celestial_arc"), "CAPS-10: clear_capabilities removes all unlocked abilities")

# ==============================================================================
# CATEGORY 3: PERSISTENT WORLD STATE & FLAGS
# ==============================================================================
func _test_03_world_state_and_flags() -> void:
	print("\n--- Category 3: Persistent World State & Flags ---")
	
	var ws: WorldState = WorldState.new()
	_assert(not ws.has_flag(&"boss_defeated"), "STATE-01: has_flag returns false for unset flag")
	_assert(not ws.get_flag(&"boss_defeated", false), "STATE-02: get_flag returns provided default value when unset")
	_assert(ws.get_flag(&"custom_flag", true), "STATE-03: get_flag respects true default value when unset")
	
	ws.set_flag(&"boss_defeated", true)
	_assert(ws.has_flag(&"boss_defeated"), "STATE-04: has_flag returns true after set_flag")
	_assert(ws.get_flag(&"boss_defeated"), "STATE-05: get_flag returns true for active flag")
	
	ws.set_flag(&"boss_defeated", false)
	_assert(not ws.has_flag(&"boss_defeated"), "STATE-06: has_flag returns false after set_flag false")
	
	ws.set_flag(&"chest_opened", true)
	ws.clear_flag(&"chest_opened")
	_assert(not ws.has_flag(&"chest_opened"), "STATE-07: clear_flag removes flag completely")
	
	ws.set_data(&"relic_count", 5)
	_assert(ws.has_data(&"relic_count"), "STATE-08: has_data returns true after set_data")
	_assert(int(ws.get_data(&"relic_count")) == 5, "STATE-09: get_data retrieves stored Variant value")
	
	ws.clear_data(&"relic_count")
	_assert(not ws.has_data(&"relic_count"), "STATE-10: clear_data removes arbitrary data entry")
	
	ws.set_flag(&"flag_a", true)
	ws.set_data(&"key_a", "value_a")
	ws.reset()
	_assert(not ws.has_flag(&"flag_a") and not ws.has_data(&"key_a"), "STATE-11: reset clears both flags and data dictionaries")
	
	var signal_received: Array[bool] = [false]
	ws.flag_changed.connect(func(fname: StringName, fval: bool) -> void:
		if fname == &"test_signal" and fval == true:
			signal_received[0] = true
	)
	ws.set_flag(&"test_signal", true)
	_assert(signal_received[0], "STATE-12: set_flag emits flag_changed signal with correct payload")

# ==============================================================================
# CATEGORY 4: ROOM2D LIFECYCLE & INVARIANT TRANSITIONS
# ==============================================================================
func _test_04_room_2d_lifecycle() -> void:
	print("\n--- Category 4: Room2D Lifecycle & Invariant Transitions ---")
	
	var room: Room2D = Room2D.new()
	add_child(room)
	
	_assert(room.get_lifecycle_state() == Room2D.LifecycleState.LOADED, "LIFE-01: Room2D enters LOADED state on ready")
	
	var wc: WorldController = WorldController.new()
	add_child(wc)
	room.initialize_room(wc)
	_assert(room.get_world_controller() == wc, "LIFE-02: initialize_room links WorldController reference")
	
	var activated_emitted: Array[bool] = [false]
	room.room_activated.connect(func() -> void: activated_emitted[0] = true)
	room.activate_room()
	_assert(room.get_lifecycle_state() == Room2D.LifecycleState.ACTIVE, "LIFE-03: activate_room sets state to ACTIVE")
	_assert(room.process_mode == Node.PROCESS_MODE_INHERIT and room.visible, "LIFE-04: activate_room enables processing and visibility")
	_assert(activated_emitted[0], "LIFE-05: activate_room emits room_activated signal")
	
	var deactivated_emitted: Array[bool] = [false]
	room.room_deactivated.connect(func() -> void: deactivated_emitted[0] = true)
	room.deactivate_room()
	_assert(room.get_lifecycle_state() == Room2D.LifecycleState.EXITING, "LIFE-06: deactivate_room sets state to EXITING")
	_assert(room.process_mode == Node.PROCESS_MODE_DISABLED, "LIFE-07: deactivate_room sets process_mode to DISABLED")
	_assert(deactivated_emitted[0], "LIFE-08: deactivate_room emits room_deactivated signal")
	
	var state_diff: Array[int] = [-1, -1]
	room.lifecycle_changed.connect(func(o: Room2D.LifecycleState, n: Room2D.LifecycleState) -> void:
		state_diff[0] = o
		state_diff[1] = n
	)
	room.set_lifecycle_state(Room2D.LifecycleState.UNLOADING)
	_assert(state_diff[0] == Room2D.LifecycleState.EXITING and state_diff[1] == Room2D.LifecycleState.UNLOADING, "LIFE-09: set_lifecycle_state emits lifecycle_changed with state diff")
	_assert(room.get_lifecycle_state_name() == "UNLOADING", "LIFE-10: get_lifecycle_state_name returns accurate string name")
	
	state_diff[0] = -1
	room.set_lifecycle_state(Room2D.LifecycleState.UNLOADING)
	_assert(state_diff[0] == -1, "LIFE-11: Setting identical state is a no-op and does not emit lifecycle_changed")
	
	var tpl_scene: PackedScene = load("res://scenes/world/room_2d.tscn")
	var tpl_instance: Node = tpl_scene.instantiate()
	_assert(tpl_instance is Room2D and tpl_instance.has_node("Geometry") and tpl_instance.has_node("SpawnPoints"), "LIFE-12: Room2D template scene instances with canonical hierarchy")
	tpl_instance.queue_free()
	
	room.queue_free()
	wc.queue_free()

# ==============================================================================
# CATEGORY 5: ROOM TRANSITIONS & PLAYER REPOSITIONING
# ==============================================================================
func _test_05_room_transitions_and_spawning() -> void:
	print("\n--- Category 5: Room Transitions & Spawning ---")
	
	var wc: WorldController = WorldController.new()
	var container: Node2D = Node2D.new()
	container.name = "RoomsContainer"
	wc.add_child(container)
	wc.rooms_container = container
	
	var player_char: CharacterBody2D = CharacterBody2D.new()
	player_char.name = "Player"
	wc.add_child(player_char)
	wc.player = player_char
	add_child(wc)
	
	var rdata_a: RoomData = load("res://data/world/room_a.tres")
	var rdata_b: RoomData = load("res://data/world/room_b.tres")
	wc.register_room(rdata_a)
	wc.register_room(rdata_b)
	
	_assert(wc.has_registered_room(&"room_a"), "TRANS-01: WorldController registers room_a")
	_assert(wc.has_registered_room(&"room_b"), "TRANS-02: WorldController registers room_b")
	_assert(wc.get_registered_room_ids().size() == 2, "TRANS-03: get_registered_room_ids returns 2 registered rooms")
	
	_assert(not wc.request_room_transition(&"invalid_room"), "TRANS-04: Transition to unregistered room rejected")
	
	var trans_started: Array[bool] = [false]
	var trans_finished: Array[bool] = [false]
	wc.room_transition_started.connect(func(_from: StringName, _to: StringName) -> void: trans_started[0] = true)
	wc.room_transition_completed.connect(func(_to: StringName) -> void: trans_finished[0] = true)
	
	player_char.velocity = Vector2(250, -400)
	var success_a: bool = wc.request_room_transition(&"room_a", &"start")
	_assert(success_a, "TRANS-05: Transition to room_a succeeds")
	_assert(wc.current_room_id == &"room_a" and wc.active_room != null, "TRANS-06: current_room_id updated and active_room present")
	_assert(wc.player == player_char, "TRANS-07: Player instance preserved across transition without duplication")
	_assert(player_char.global_position.distance_to(Vector2(150, 950)) < 5.0, "TRANS-08: Player positioned at room_a 'start' spawn point")
	_assert(player_char.velocity == Vector2.ZERO, "TRANS-09: Player linear velocity zeroed upon room transition")
	_assert(trans_started[0] and trans_finished[0], "TRANS-10: Room transition signals emitted during transition sequence")
	
	var old_room_ref: Room2D = wc.active_room
	var success_b: bool = wc.request_room_transition(&"room_b", &"from_room_a")
	_assert(success_b, "TRANS-11: Subsequent transition from room_a to room_b succeeds")
	_assert(wc.current_room_id == &"room_b" and wc.active_room != old_room_ref, "TRANS-12: Old room released and new active_room established")
	
	wc.queue_free()

# ==============================================================================
# CATEGORY 6: CAMERA BOUNDS & SMOOTHING
# ==============================================================================
func _test_06_camera_bounds_and_smoothing() -> void:
	print("\n--- Category 6: Camera Bounds & Smoothing ---")
	
	var wc: WorldController = WorldController.new()
	var player_char: CharacterBody2D = CharacterBody2D.new()
	var cam: Camera2D = Camera2D.new()
	cam.name = "Camera2D"
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 8.0
	player_char.add_child(cam)
	wc.player = player_char
	add_child(wc)
	add_child(player_char)
	
	_assert(cam != null, "CAM-01: Player has valid Camera2D node")
	
	var bounds_a: Rect2 = Rect2(0, 0, 1920, 1080)
	wc.apply_camera_bounds(bounds_a)
	_assert(cam.limit_left == 0, "CAM-02: Camera limit_left applied")
	_assert(cam.limit_top == 0, "CAM-03: Camera limit_top applied")
	_assert(cam.limit_right == 1920, "CAM-04: Camera limit_right applied for 1920 width")
	_assert(cam.limit_bottom == 1080, "CAM-05: Camera limit_bottom applied for 1080 height")
	
	var bounds_b: Rect2 = Rect2(0, 0, 2400, 1080)
	wc.apply_camera_bounds(bounds_b)
	_assert(cam.limit_right == 2400, "CAM-06: Transitioning to 2400 width room updates camera limit_right to 2400")
	
	var bounds_offset: Rect2 = Rect2(100, 200, 1500, 900)
	wc.apply_camera_bounds(bounds_offset)
	_assert(cam.limit_left == 100 and cam.limit_top == 200 and cam.limit_right == 1600 and cam.limit_bottom == 1100, "CAM-07: Arbitrary offset room bounds applied correctly")
	
	wc.apply_camera_bounds(bounds_a)
	_assert(cam.limit_right == 1920, "CAM-08: Returning to Room A restores 1920 camera limits")
	_assert(cam.position_smoothing_speed == 8.0, "CAM-09: Camera smoothing configuration remains intact")
	_assert(cam.position_smoothing_enabled, "CAM-10: Camera position smoothing remains active")
	
	wc.queue_free()
	player_char.queue_free()

# ==============================================================================
# CATEGORY 7: ABILITY GATES & CONDITIONAL ACCESS
# ==============================================================================
func _test_07_ability_gates() -> void:
	print("\n--- Category 7: Ability Gates & Conditional Access ---")
	
	var gate: AbilityGate = AbilityGate.new()
	gate.gate_id = &"gate_arc"
	gate.required_ability = &"celestial_arc"
	
	var col: CollisionShape2D = CollisionShape2D.new()
	col.name = "CollisionShape2D"
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(40, 160)
	col.shape = shape
	gate.add_child(col)
	
	var visual: ColorRect = ColorRect.new()
	visual.name = "VisualBarrier"
	gate.add_child(visual)
	add_child(gate)
	
	_assert(not gate.is_open, "GATE-01: AbilityGate initializes closed")
	_assert(gate.collision_layer & 1 != 0, "GATE-02: Closed AbilityGate collides on Layer 1 (World Geometry)")
	_assert(visual.visible, "GATE-03: Closed AbilityGate visual barrier is visible")
	
	var caps: PlayerCapabilities = PlayerCapabilities.new()
	var ws: WorldState = WorldState.new()
	
	var locked_attempt: Array[bool] = [false]
	gate.gate_locked_attempt.connect(func(_gid: StringName, _req: StringName) -> void: locked_attempt[0] = true)
	var opened_without_cap: bool = gate.check_unlock(caps, ws)
	_assert(not opened_without_cap and locked_attempt[0], "GATE-04: check_unlock fails without required capability and emits signal")
	_assert(not gate.is_open and gate.collision_layer & 1 != 0, "GATE-05: Gate remains closed and solid after failed unlock")
	
	caps.unlock_ability(&"celestial_arc")
	var gate_opened_signal: Array[bool] = [false]
	gate.gate_opened.connect(func(_gid: StringName) -> void: gate_opened_signal[0] = true)
	var opened_with_cap: bool = gate.check_unlock(caps, ws)
	_assert(opened_with_cap and gate.is_open, "GATE-06: check_unlock succeeds when capability is granted")
	_assert(gate_opened_signal[0], "GATE-07: open_gate emits gate_opened signal")
	_assert(gate.collision_layer & 1 == 0, "GATE-08: Opened AbilityGate disables collision on Layer 1")
	_assert(not visual.visible, "GATE-09: Opened AbilityGate visual barrier is hidden")
	
	var recorded_state: WorldState = WorldState.new()
	gate.record_state(recorded_state)
	_assert(recorded_state.has_flag(&"gate_opened_gate_arc"), "GATE-10: record_state records open flag in WorldState")
	
	var gate_2: AbilityGate = AbilityGate.new()
	gate_2.gate_id = &"gate_arc"
	gate_2.required_ability = &"celestial_arc"
	var col2: CollisionShape2D = CollisionShape2D.new()
	col2.name = "CollisionShape2D"
	gate_2.add_child(col2)
	add_child(gate_2)
	gate_2.apply_state(recorded_state)
	_assert(gate_2.is_open, "GATE-11: apply_state restores open gate status on new gate instance")
	
	var gate_cloud: AbilityGate = AbilityGate.new()
	gate_cloud.gate_id = &"gate_cloud"
	gate_cloud.required_ability = &"cloud_step"
	add_child(gate_cloud)
	_assert(not gate_cloud.check_unlock(caps, ws), "GATE-12: Cloud Step gate remains locked when only Celestial Arc is unlocked")
	
	gate.queue_free()
	gate_2.queue_free()
	gate_cloud.queue_free()

# ==============================================================================
# CATEGORY 8: CHECKPOINT SYSTEM & RESPAWN HANDLING
# ==============================================================================
func _test_08_checkpoint_system() -> void:
	print("\n--- Category 8: Checkpoint System & Respawn Handling ---")
	
	var wc: WorldController = WorldController.new()
	add_child(wc)
	
	var cp: Checkpoint = Checkpoint.new()
	cp.checkpoint_id = &"checkpoint_a"
	cp.room_id = &"room_a"
	cp.spawn_point_id = &"start"
	
	var vis: ColorRect = ColorRect.new()
	vis.name = "VisualIndicator"
	cp.add_child(vis)
	wc.add_child(cp)
	
	_assert(not cp.is_active, "CP-01: Checkpoint initializes inactive")
	_assert(vis.modulate == Checkpoint.COLOR_INACTIVE, "CP-02: Checkpoint visual indicator shows inactive color")
	
	var cp_activated_emitted: Array[bool] = [false]
	cp.activated.connect(func(_id: StringName) -> void: cp_activated_emitted[0] = true)
	cp.activate()
	_assert(cp.is_active, "CP-03: activate marks checkpoint active")
	_assert(cp_activated_emitted[0], "CP-04: activate emits activated signal")
	_assert(vis.modulate == Checkpoint.COLOR_ACTIVE, "CP-05: Checkpoint visual indicator changes to active gold color")
	_assert(wc.active_checkpoint_room_id == &"room_a" and wc.active_checkpoint_spawn_id == &"start", "CP-06: activate updates WorldController active checkpoint coordinates")
	_assert(wc.world_state.has_flag(&"checkpoint_active_checkpoint_a"), "CP-07: activate records checkpoint flag in WorldState")
	
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	var player: Node = player_scene.instantiate()
	add_child(player)
	var health_comp: HealthComponent = player.get_node("Components/HealthComponent")
	var spirit_comp: SpiritComponent = player.get_node("Components/SpiritComponent")
	health_comp.take_damage(50.0)
	spirit_comp.consume_spirit(60.0)
	
	cp.activate(player as Node2D)
	_assert(health_comp.current_health == health_comp.max_health, "CP-08: Checkpoint activation restores player health to maximum")
	_assert(spirit_comp.current_spirit == spirit_comp.max_spirit, "CP-09: Checkpoint activation restores player spirit to maximum")
	
	var cp_state: WorldState = WorldState.new()
	cp.record_state(cp_state)
	var new_cp: Checkpoint = Checkpoint.new()
	new_cp.checkpoint_id = &"checkpoint_a"
	new_cp.apply_state(cp_state)
	_assert(new_cp.is_active, "CP-10: Checkpoint state restores from WorldState on new instance")
	
	player.queue_free()
	new_cp.queue_free()
	wc.queue_free()

# ==============================================================================
# CATEGORY 9: PERSISTENT WORLD OBJECTS
# ==============================================================================
func _test_09_persistent_world_objects() -> void:
	print("\n--- Category 9: Persistent World Objects ---")
	
	var pobj: PersistentWorldObject = PersistentWorldObject.new()
	pobj.persistent_id = &"secret_relic"
	add_child(pobj)
	_assert(pobj.persistent_id == &"secret_relic", "OBJ-01: PersistentWorldObject maintains persistent_id")
	
	var ws: WorldState = WorldState.new()
	pobj.visible = false
	pobj.record_state(ws)
	_assert(not ws.get_flag(&"obj_secret_relic_active", true), "OBJ-02: record_state records object state to WorldState")
	
	var pobj_2: PersistentWorldObject = PersistentWorldObject.new()
	pobj_2.persistent_id = &"secret_relic"
	pobj_2.visible = true
	add_child(pobj_2)
	pobj_2.apply_state(ws)
	_assert(not pobj_2.visible, "OBJ-03: apply_state synchronizes node visibility from WorldState")
	
	remove_child(pobj)
	var room: Room2D = Room2D.new()
	var p_root: Node2D = Node2D.new()
	p_root.name = "PersistentObjects"
	room.add_child(p_root)
	room.persistent_objects_root = p_root
	p_root.add_child(pobj)
	add_child(room)
	
	pobj.visible = true
	room.record_persistent_objects(ws)
	_assert(ws.get_flag(&"obj_secret_relic_active"), "OBJ-04: Room2D record_persistent_objects records child states")
	
	pobj.visible = false
	room.sync_persistent_objects(ws)
	_assert(pobj.visible, "OBJ-05: Room2D sync_persistent_objects applies saved state to children")
	
	var empty_pobj: PersistentWorldObject = PersistentWorldObject.new()
	empty_pobj.record_state(ws)
	empty_pobj.apply_state(ws)
	_assert(true, "OBJ-06: PersistentWorldObject with empty ID operates without crash")
	
	var serialized_ws: Dictionary = ws.serialize()
	var restored_ws: WorldState = WorldState.new()
	restored_ws.deserialize(serialized_ws)
	_assert(restored_ws.get_flag(&"obj_secret_relic_active"), "OBJ-07: PersistentWorldObject flag persists across WorldState serialization")
	
	pobj_2.apply_state(restored_ws)
	_assert(pobj_2.visible, "OBJ-08: PersistentWorldObject restores state from deserialized WorldState")
	
	pobj.queue_free()
	pobj_2.queue_free()
	empty_pobj.queue_free()
	room.queue_free()

# ==============================================================================
# CATEGORY 10: GRANITE ABBOT WORLD PERSISTENCE
# ==============================================================================
func _test_10_granite_abbot_persistence() -> void:
	print("\n--- Category 10: Granite Abbot World Persistence ---")
	
	var arena_ctrl: BossArenaController = BossArenaController.new()
	arena_ctrl.boss_defeat_flag = &"granite_abbot_defeated"
	
	var boss_scene: PackedScene = load("res://scenes/bosses/granite_abbot.tscn")
	var boss: BossController = boss_scene.instantiate() as BossController
	arena_ctrl.boss = boss
	
	var left_bar: StaticBody2D = StaticBody2D.new()
	var right_bar: StaticBody2D = StaticBody2D.new()
	var trig: Area2D = Area2D.new()
	arena_ctrl.left_barrier = left_bar
	arena_ctrl.right_barrier = right_bar
	arena_ctrl.entry_trigger = trig
	
	add_child(arena_ctrl)
	add_child(boss)
	add_child(left_bar)
	add_child(right_bar)
	add_child(trig)
	
	_assert(arena_ctrl.boss_defeat_flag == &"granite_abbot_defeated", "BOSS-01: BossArenaController configured with granite_abbot_defeated flag")
	_assert(not arena_ctrl.is_encounter_completed, "BOSS-02: Encounter initially not completed")
	
	arena_ctrl.complete_encounter()
	_assert(arena_ctrl.is_encounter_completed, "BOSS-03: complete_encounter marks encounter completed")
	_assert(left_bar.collision_layer == 0 and right_bar.collision_layer == 0, "BOSS-04: complete_encounter unlocks arena barriers")
	
	var ws: WorldState = WorldState.new()
	arena_ctrl.record_state(ws)
	_assert(ws.has_flag(&"granite_abbot_defeated"), "BOSS-05: record_state writes granite_abbot_defeated flag to WorldState")
	
	var new_arena: BossArenaController = BossArenaController.new()
	new_arena.boss_defeat_flag = &"granite_abbot_defeated"
	var new_boss: BossController = boss_scene.instantiate() as BossController
	var new_left: StaticBody2D = StaticBody2D.new()
	var new_right: StaticBody2D = StaticBody2D.new()
	var new_trig: Area2D = Area2D.new()
	new_arena.boss = new_boss
	new_arena.left_barrier = new_left
	new_arena.right_barrier = new_right
	new_arena.entry_trigger = new_trig
	
	add_child(new_arena)
	add_child(new_boss)
	add_child(new_left)
	add_child(new_right)
	add_child(new_trig)
	
	new_arena.apply_state(ws)
	_assert(new_arena.is_encounter_completed, "BOSS-06: apply_state restores completed status on new arena controller")
	_assert(not new_boss.visible, "BOSS-07: Defeated boss visibility hidden upon room load")
	_assert(new_boss.process_mode == Node.PROCESS_MODE_DISABLED, "BOSS-08: Defeated boss process_mode disabled to prevent active encounter")
	_assert(new_left.collision_layer == 0 and new_right.collision_layer == 0, "BOSS-09: Arena barriers remain lowered on room re-entry")
	_assert(not new_arena.is_encounter_active, "BOSS-10: Defeated encounter does not activate on subsequent visits")
	
	arena_ctrl.queue_free()
	boss.queue_free()
	left_bar.queue_free()
	right_bar.queue_free()
	trig.queue_free()
	new_arena.queue_free()
	new_boss.queue_free()
	new_left.queue_free()
	new_right.queue_free()
	new_trig.queue_free()

# ==============================================================================
# CATEGORY 11: SAVEMANAGER INTEGRATION & SERIALIZATION
# ==============================================================================
func _test_11_save_manager_integration() -> void:
	print("\n--- Category 11: SaveManager Integration & Serialization ---")
	
	var caps: PlayerCapabilities = PlayerCapabilities.new()
	caps.unlock_ability(&"celestial_arc")
	caps.unlock_ability(&"cloud_step")
	var caps_data: Array[String] = caps.serialize()
	_assert(caps_data.has("celestial_arc") and caps_data.has("cloud_step"), "SAVE-01: PlayerCapabilities serializes unlocked abilities to Array[String]")
	
	var restored_caps: PlayerCapabilities = PlayerCapabilities.new()
	restored_caps.deserialize(caps_data)
	_assert(restored_caps.has_ability(&"celestial_arc") and restored_caps.has_ability(&"cloud_step"), "SAVE-02: PlayerCapabilities deserializes accurately from string array")
	
	var ws: WorldState = WorldState.new()
	ws.set_flag(&"granite_abbot_defeated", true)
	ws.set_flag(&"gate_opened_gate_arc", true)
	ws.set_data(&"relics_collected", 3)
	var ws_data: Dictionary = ws.serialize()
	_assert(ws_data.has("flags") and ws_data["flags"].get("granite_abbot_defeated") == true, "SAVE-03: WorldState serializes flags to Dictionary payload")
	
	var restored_ws: WorldState = WorldState.new()
	restored_ws.deserialize(ws_data)
	_assert(restored_ws.has_flag(&"granite_abbot_defeated") and restored_ws.has_flag(&"gate_opened_gate_arc"), "SAVE-04: WorldState deserializes flags accurately")
	_assert(int(restored_ws.get_data(&"relics_collected")) == 3, "SAVE-05: WorldState deserializes arbitrary data correctly")
	
	var wc: WorldController = WorldController.new()
	wc.world_state = ws
	wc.capabilities = caps
	wc.current_room_id = &"room_b"
	wc.active_checkpoint_room_id = &"room_a"
	wc.active_checkpoint_spawn_id = &"start"
	add_child(wc)
	
	var save_success: bool = wc.save_world_state(2)
	_assert(save_success, "SAVE-06: WorldController save_world_state successfully commits to SaveManager slot 2")
	
	var wc_loaded: WorldController = WorldController.new()
	add_child(wc_loaded)
	var load_success: bool = wc_loaded.load_world_state(2)
	_assert(load_success, "SAVE-07: WorldController load_world_state successfully reads slot 2")
	_assert(wc_loaded.world_state.has_flag(&"granite_abbot_defeated"), "SAVE-08: Restored WorldController contains persistent boss defeat flag")
	_assert(wc_loaded.capabilities.has_ability(&"celestial_arc"), "SAVE-09: Restored WorldController contains unlocked capabilities")
	_assert(wc_loaded.active_checkpoint_room_id == &"room_a", "SAVE-10: Restored WorldController contains active checkpoint room reference")
	
	# Clean up save file
	if has_node("/root/SaveManager"):
		var sm: Node = get_node("/root/SaveManager")
		if sm != null and sm.has_method("delete_save_file"):
			sm.delete_save_file(2)
	
	wc.queue_free()
	wc_loaded.queue_free()

# ==============================================================================
# CATEGORY 12: TRANSITION SAFETY, RE-ENTRANCY & ERROR HANDLING
# ==============================================================================
func _test_12_safety_reentrancy_and_errors() -> void:
	print("\n--- Category 12: Transition Safety, Re-entrancy & Error Handling ---")
	
	var wc: WorldController = WorldController.new()
	var container: Node2D = Node2D.new()
	container.name = "RoomsContainer"
	wc.add_child(container)
	wc.rooms_container = container
	
	var player_char: CharacterBody2D = CharacterBody2D.new()
	player_char.name = "Player"
	wc.add_child(player_char)
	wc.player = player_char
	add_child(wc)
	
	var rdata_a: RoomData = load("res://data/world/room_a.tres")
	var rdata_b: RoomData = load("res://data/world/room_b.tres")
	var rdata_c: RoomData = load("res://data/world/room_c.tres")
	wc.register_room(rdata_a)
	wc.register_room(rdata_b)
	wc.register_room(rdata_c)
	
	wc.load_room(&"room_a", &"start")
	_assert(wc.current_room_id == &"room_a", "SAFE-01: Room A loads as initial room")
	
	wc.is_transitioning = true
	var rejected: bool = wc.request_room_transition(&"room_b", &"from_room_a")
	_assert(not rejected, "SAFE-02: Simultaneous transition request rejected while is_transitioning is true")
	wc.is_transitioning = false
	
	var invalid_room_res: bool = wc.request_room_transition(&"non_existent_room", &"default")
	_assert(not invalid_room_res, "SAFE-03: Transition to non-existent room ID rejected safely")
	
	var bad_data: RoomData = RoomData.new(&"bad_room", "Bad Room", "res://missing_file.tscn")
	wc.register_room(bad_data)
	var missing_file_res: bool = wc.request_room_transition(&"bad_room", &"default")
	_assert(not missing_file_res, "SAFE-04: Transition to missing scene path handled gracefully without crash")
	
	var fallback_pos: bool = wc.request_room_transition(&"room_a", &"non_existent_spawn")
	_assert(fallback_pos and wc.current_room_id == &"room_a", "SAFE-05: Transition with invalid spawn ID falls back safely")
	
	var exit_node: RoomExit = RoomExit.new()
	exit_node.exit_id = &"test_exit"
	exit_node.destination_room_id = &"room_b"
	exit_node.destination_spawn_id = &"from_room_a"
	wc.add_child(exit_node)
	var exit_triggered: bool = exit_node.trigger_transition()
	_assert(exit_triggered and wc.current_room_id == &"room_b", "SAFE-06: RoomExit trigger successfully executes transition to Room B")
	
	exit_node.is_locked = true
	var locked_exit_triggered: bool = exit_node.trigger_transition()
	_assert(not locked_exit_triggered, "SAFE-07: Locked RoomExit blocks transition")
	
	wc.unregister_room(&"bad_room")
	_assert(not wc.has_registered_room(&"bad_room"), "SAFE-08: unregister_room removes room from registry cleanly")
	
	var gate: AbilityGate = AbilityGate.new()
	gate.gate_id = &"test_gate"
	add_child(gate)
	gate.open_gate(true)
	gate.open_gate(true)
	_assert(gate.is_open, "SAFE-09: Duplicate open_gate calls are idempotent and safe")
	
	var caps: PlayerCapabilities = PlayerCapabilities.new()
	caps.lock_ability(&"not_unlocked")
	_assert(not caps.has_ability(&"not_unlocked"), "SAFE-10: Locking non-unlocked ability is safe and idempotent")
	
	# Simulated full traversal path: Room A -> Room B -> Room A -> Room C
	var p1: bool = wc.request_room_transition(&"room_a", &"from_room_b")
	_assert(p1 and wc.current_room_id == &"room_a", "SAFE-11: Traversal: Returned to Room A from Room B")
	
	var p2: bool = wc.request_room_transition(&"room_c", &"from_room_a")
	_assert(p2 and wc.current_room_id == &"room_c", "SAFE-12: Traversal: Transitioned to Room C (Awakening Chamber)")
	
	var p3: bool = wc.request_room_transition(&"room_a", &"from_room_c")
	_assert(p3 and wc.current_room_id == &"room_a", "SAFE-13: Traversal: Returned to Room A from Room C")
	
	var tw_scene: PackedScene = load("res://scenes/world/test_world/test_world.tscn")
	var tw_instance: Node = tw_scene.instantiate()
	_assert(tw_instance is TestWorld, "SAFE-14: TestWorld main scene instances cleanly as TestWorld")
	tw_instance.queue_free()
	
	gate.queue_free()
	exit_node.queue_free()
	wc.queue_free()
