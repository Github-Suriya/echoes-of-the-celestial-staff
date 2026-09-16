class_name BossPhaseController
extends Node

## BossPhaseController
## Evaluates health thresholds, manages multi-phase progression, and guarantees idempotent transitions.

signal phase_changed(new_phase_number: int, phase_data: BossPhaseData)
signal phase_transition_started(new_phase_number: int)
signal phase_transition_finished(new_phase_number: int)

@export var boss_data: BossData = null

var current_phase_index: int = 0
var current_phase_data: BossPhaseData = null
var is_transitioning: bool = false

var _phase_2_triggered: bool = false
var _actor: Node2D = null

func _ready() -> void:
	if owner is Node2D:
		_actor = owner as Node2D

func configure(data: BossData) -> void:
	boss_data = data
	reset_phases()

func reset_phases() -> void:
	current_phase_index = 0
	_phase_2_triggered = false
	is_transitioning = false
	
	if boss_data != null and not boss_data.phases.is_empty():
		current_phase_data = boss_data.phases[0]
	else:
		current_phase_data = null

func get_current_phase_number() -> int:
	return current_phase_index + 1

func get_current_phase_data() -> BossPhaseData:
	return current_phase_data

func check_health_threshold(current_hp: float, max_hp: float) -> void:
	if max_hp <= 0.0 or is_transitioning:
		return
	
	var ratio: float = current_hp / max_hp
	
	# Evaluate Phase 2 threshold (<= 0.50 HP)
	if ratio <= 0.50 and not _phase_2_triggered:
		trigger_phase_transition(1)

func trigger_phase_transition(target_phase_index: int) -> bool:
	if boss_data == null or boss_data.phases.size() <= target_phase_index:
		return false
	
	if target_phase_index == 1 and _phase_2_triggered:
		return false
	
	_phase_2_triggered = true
	is_transitioning = true
	current_phase_index = target_phase_index
	current_phase_data = boss_data.phases[target_phase_index]
	
	var phase_num: int = target_phase_index + 1
	phase_transition_started.emit(phase_num)
	
	if has_node("/root/EventBus"):
		var bus: Node = get_node("/root/EventBus")
		if bus != null and bus.has_signal("boss_phase_changed"):
			var bname: String = boss_data.display_name if boss_data != null else "Boss"
			bus.boss_phase_changed.emit(bname, phase_num)
	
	return true

func complete_phase_transition() -> void:
	is_transitioning = false
	var phase_num: int = current_phase_index + 1
	phase_transition_finished.emit(phase_num)
	phase_changed.emit(phase_num, current_phase_data)
