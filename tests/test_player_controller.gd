extends Node

## Automated Headless Test Suite for Phase 2 (Player Controller & Locomotion)
## Executes unit assertions on PlayerController, PlayerMovement, StateMachine, and Respawn.

var _passed_count: int = 0
var _total_count: int = 0

func _ready() -> void:
	print("\n==================================================")
	print(" RUNNING PHASE 2 PLAYER CONTROLLER TEST SUITE")
	print("==================================================")
	
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	_assert_test("Player scene loads successfully", player_scene != null)
	
	var player: PlayerController = player_scene.instantiate() as PlayerController
	add_child(player)
	
	_test_player_structure(player)
	_test_movement_config(player)
	_test_facing_direction(player)
	_test_state_machine(player)
	_test_movement_physics_logic(player)
	_test_respawn_logic(player)
	_test_pause_integration(player)
	
	player.queue_free()
	
	print("==================================================")
	print(" TEST RESULTS: %d / %d PASSED" % [_passed_count, _total_count])
	print("==================================================\n")
	
	if _passed_count == _total_count:
		print("SUCCESS: All Phase 2 Player Controller tests passed cleanly.")
		get_tree().quit(0)
	else:
		printerr("FAILURE: One or more player controller tests failed.")
		get_tree().quit(1)

func _assert_test(test_name: String, condition: bool) -> void:
	_total_count += 1
	if condition:
		_passed_count += 1
		print("[PASS] %s" % test_name)
	else:
		printerr("[FAIL] %s" % test_name)

func _test_player_structure(player: PlayerController) -> void:
	print("\n--- Testing Player Scene Structure ---")
	_assert_test("Player is CharacterBody2D", player is CharacterBody2D)
	_assert_test("Player has CollisionShape2D", player.has_node("CollisionShape2D"))
	_assert_test("Player has Camera2D", player.has_node("Camera2D"))
	_assert_test("Player has Visuals", player.has_node("Visuals"))
	_assert_test("Player has PlayerMovement", player.has_node("Components/PlayerMovement"))
	_assert_test("Player has PlayerAnimationController", player.has_node("Components/PlayerAnimationController"))
	_assert_test("Player has PlayerRespawn", player.has_node("Components/PlayerRespawn"))
	_assert_test("Player has StateMachine", player.has_node("StateMachine"))

func _test_movement_config(player: PlayerController) -> void:
	print("\n--- Testing Movement Configuration ---")
	var config: PlayerMovementConfig = player.movement.config
	_assert_test("PlayerMovementConfig is non-null", config != null)
	_assert_test("Config max_speed > 0", config.max_speed > 0.0)
	_assert_test("Config acceleration > 0", config.acceleration > 0.0)
	_assert_test("Config deceleration > 0", config.deceleration > 0.0)
	_assert_test("Config jump_velocity is negative (upward)", config.jump_velocity < 0.0)
	_assert_test("Config gravity > 0", config.gravity > 0.0)
	_assert_test("Config coyote_time > 0", config.coyote_time > 0.0)
	_assert_test("Config jump_buffer_time > 0", config.jump_buffer_time > 0.0)

func _test_facing_direction(player: PlayerController) -> void:
	print("\n--- Testing Facing Direction API ---")
	_assert_test("Default facing is Right (+1)", player.get_facing_direction() == 1)
	_assert_test("is_facing_right is true", player.is_facing_right())
	_assert_test("is_facing_left is false", not player.is_facing_left())
	
	player.set_facing_direction(-1)
	_assert_test("Facing changes to Left (-1)", player.get_facing_direction() == -1)
	_assert_test("is_facing_left is now true", player.is_facing_left())
	_assert_test("Visuals scale.x flips to -1", player.visuals.scale.x == -1.0)
	
	player.set_facing_direction(1)
	_assert_test("Facing restores to Right (+1)", player.is_facing_right())
	_assert_test("Visuals scale.x restores to 1", player.visuals.scale.x == 1.0)

func _test_state_machine(player: PlayerController) -> void:
	print("\n--- Testing State Machine Transitions ---")
	var sm: StateMachine = player.state_machine
	_assert_test("StateMachine has Idle state", sm.has_state(&"Idle"))
	_assert_test("StateMachine has Run state", sm.has_state(&"Run"))
	_assert_test("StateMachine has Jump state", sm.has_state(&"Jump"))
	_assert_test("StateMachine has Fall state", sm.has_state(&"Fall"))
	_assert_test("StateMachine has Land state", sm.has_state(&"Land"))
	
	sm.change_state(&"Run")
	_assert_test("State transitions to Run", sm.get_current_state_name() == &"Run")
	sm.change_state(&"Jump")
	_assert_test("State transitions to Jump", sm.get_current_state_name() == &"Jump")
	sm.change_state(&"Fall")
	_assert_test("State transitions to Fall", sm.get_current_state_name() == &"Fall")
	sm.change_state(&"Land")
	_assert_test("State transitions to Land", sm.get_current_state_name() == &"Land")
	sm.change_state(&"Idle")
	_assert_test("State transitions back to Idle", sm.get_current_state_name() == &"Idle")

func _test_movement_physics_logic(player: PlayerController) -> void:
	print("\n--- Testing Movement Physics Logic ---")
	var mv: PlayerMovement = player.movement
	
	# Jump impulse
	mv.apply_jump_impulse()
	_assert_test("apply_jump_impulse applies upward jump_velocity", player.velocity.y == mv.config.jump_velocity)
	_assert_test("Movement reports is_jumping=true", mv.is_jumping())
	
	# Landing notification
	mv.notify_landed()
	_assert_test("notify_landed resets is_jumping to false", not mv.is_jumping())
	
	# Coyote timer and Jump Buffer initial states
	_assert_test("Coyote timer can be queried", mv.get_coyote_timer() >= 0.0)
	_assert_test("Jump buffer timer can be queried", mv.get_jump_buffer_timer() >= 0.0)

func _test_respawn_logic(player: PlayerController) -> void:
	print("\n--- Testing Respawn Component ---")
	var respawn: PlayerRespawn = player.respawn_component
	_assert_test("Respawn component exists", respawn != null)
	
	var custom_spawn: Vector2 = Vector2(150.0, 300.0)
	respawn.set_spawn_position(custom_spawn)
	_assert_test("Spawn position can be set", respawn.spawn_position == custom_spawn)
	
	# Simulate falling below pit threshold
	player.global_position = Vector2(150.0, 1500.0)
	player.velocity = Vector2(100.0, 500.0)
	respawn.check_boundaries()
	
	_assert_test("Pit fall resets position to spawn_position", player.global_position == custom_spawn)
	_assert_test("Pit fall zeroes velocity", player.velocity == Vector2.ZERO)
	_assert_test("Pit fall resets StateMachine to Idle", player.state_machine.get_current_state_name() == &"Idle")

func _test_pause_integration(player: PlayerController) -> void:
	print("\n--- Testing Pause Integration ---")
	if has_node("/root/GameManager"):
		var gm: Node = get_node("/root/GameManager")
		gm.set_game_state(2) # 2 = PLAYING
		_assert_test("Gameplay is active in PLAYING state", player._is_gameplay_active())
		
		gm.set_paused(true)
		_assert_test("Gameplay is inactive when GameManager is paused", not player._is_gameplay_active())
		
		gm.set_paused(false)
		_assert_test("Gameplay is active again when unpaused", player._is_gameplay_active())
	else:
		_assert_test("Gameplay is active by default (no GameManager)", player._is_gameplay_active())
