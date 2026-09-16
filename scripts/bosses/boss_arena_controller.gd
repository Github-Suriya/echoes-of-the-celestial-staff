class_name BossArenaController
extends Node2D

## BossArenaController
## Orchestrates boss encounter lifecycles, physical arena boundary locking,
## encounter activation triggers, HUD synchronization, and reset mechanisms.

signal encounter_started()
signal encounter_completed()
signal arena_locked()
signal arena_unlocked()

@export var boss: BossController = null
@export var player: Node2D = null
@export var entry_trigger: Area2D = null
@export var left_barrier: StaticBody2D = null
@export var right_barrier: StaticBody2D = null
@export var boss_hud: CanvasLayer = null
@export var boss_defeat_flag: StringName = &"granite_abbot_defeated"

var is_encounter_active: bool = false
var is_encounter_completed: bool = false

func _ready() -> void:
	# Start with barriers lowered / non-colliding
	unlock_arena()
	
	if entry_trigger != null and not entry_trigger.body_entered.is_connected(_on_trigger_body_entered):
		entry_trigger.body_entered.connect(_on_trigger_body_entered)
	
	if boss != null and not boss.boss_defeated_signal.is_connected(_on_boss_defeated):
		boss.boss_defeated_signal.connect(_on_boss_defeated)

func start_encounter() -> void:
	if is_encounter_active:
		return
	
	is_encounter_active = true
	is_encounter_completed = false
	
	lock_arena()
	
	if boss != null:
		if player != null and boss.perception != null:
			boss.perception.acquire_target(player)
		
		if boss.state_machine != null:
			boss.state_machine.change_state(&"Intro")
	
	if boss_hud != null:
		boss_hud.visible = true
	
	if has_node("/root/EventBus"):
		var bus: Node = get_node("/root/EventBus")
		if bus != null:
			var bname: String = boss.boss_data.display_name if (boss != null and boss.boss_data != null) else "Boss"
			if bus.has_signal("boss_started"):
				bus.boss_started.emit(bname)
			if bus.has_signal("boss_arena_locked"):
				bus.boss_arena_locked.emit()
	
	encounter_started.emit()

func lock_arena() -> void:
	if left_barrier != null:
		left_barrier.collision_layer = 1
		left_barrier.visible = true
	if right_barrier != null:
		right_barrier.collision_layer = 1
		right_barrier.visible = true
	
	arena_locked.emit()

func unlock_arena() -> void:
	if left_barrier != null:
		left_barrier.collision_layer = 0
		left_barrier.visible = false
	if right_barrier != null:
		right_barrier.collision_layer = 0
		right_barrier.visible = false
	
	if has_node("/root/EventBus"):
		var bus: Node = get_node("/root/EventBus")
		if bus != null and bus.has_signal("boss_arena_unlocked"):
			bus.boss_arena_unlocked.emit()
	
	arena_unlocked.emit()

func complete_encounter() -> void:
	is_encounter_active = false
	is_encounter_completed = true
	
	unlock_arena()
	
	if boss != null and boss.hitbox != null and boss.hitbox.is_active:
		boss.hitbox.deactivate()
	
	if boss_hud != null:
		boss_hud.visible = false
	
	if not boss_defeat_flag.is_empty():
		var wc: Node = _get_world_controller()
		if wc != null and "world_state" in wc and wc.world_state != null:
			wc.world_state.set_flag(boss_defeat_flag, true)
	
	encounter_completed.emit()

func reset_encounter() -> void:
	is_encounter_active = false
	is_encounter_completed = false
	
	unlock_arena()
	
	if boss != null:
		boss.reset_boss()
		if boss.perception != null:
			boss.perception.clear_target()
	
	if boss_hud != null:
		boss_hud.visible = false

func apply_state(state: WorldState) -> void:
	if state == null or boss_defeat_flag.is_empty():
		return
	if state.has_flag(boss_defeat_flag):
		is_encounter_completed = true
		is_encounter_active = false
		unlock_arena()
		if boss != null:
			boss.visible = false
			boss.process_mode = Node.PROCESS_MODE_DISABLED
			if boss.has_node("CollisionShape2D"):
				var col: CollisionShape2D = boss.get_node("CollisionShape2D") as CollisionShape2D
				if col != null:
					col.set_deferred("disabled", true)
		if boss_hud != null:
			boss_hud.visible = false
		if entry_trigger != null:
			entry_trigger.set_deferred("monitoring", false)

func record_state(state: WorldState) -> void:
	if state == null or boss_defeat_flag.is_empty():
		return
	state.set_flag(boss_defeat_flag, is_encounter_completed)

func _on_trigger_body_entered(body: Node2D) -> void:
	if is_encounter_active or is_encounter_completed:
		return
	
	# Detect player entry
	if body is PlayerController or body.name == "Player" or (player != null and body == player):
		if player == null:
			player = body
		start_encounter()

func _on_boss_defeated() -> void:
	complete_encounter()

func _get_world_controller() -> Node:
	var curr: Node = get_parent()
	while curr != null:
		if curr.has_method("request_room_transition") or "world_state" in curr:
			return curr
		curr = curr.get_parent()
	return null

