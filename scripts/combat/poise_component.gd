class_name PoiseComponent
extends Node

## PoiseComponent
## Tracks poise points, guard-break stagger thresholds, and poise recovery.

signal poise_changed(current: float, max_val: float)
signal poise_broken()
signal stagger_started(duration: float)
signal stagger_ended()

@export var max_poise: float = 35.0
@export var stagger_duration: float = 1.5
@export var poise_regen_delay: float = 2.0
@export var poise_regen_rate: float = 20.0

var current_poise: float = 35.0
var is_staggered: bool = false

var _regen_timer: float = 0.0
var _stagger_timer: float = 0.0

func _ready() -> void:
	current_poise = max_poise

func _physics_process(delta: float) -> void:
	# Stagger timer countdown
	if is_staggered:
		_stagger_timer -= delta
		if _stagger_timer <= 0.0:
			end_stagger()
		return
	
	# Poise regeneration after delay
	if _regen_timer > 0.0:
		_regen_timer -= delta
	elif current_poise < max_poise:
		current_poise = minf(max_poise, current_poise + poise_regen_rate * delta)
		poise_changed.emit(current_poise, max_poise)

func take_poise_damage(amount: float) -> void:
	if is_staggered or amount <= 0.0:
		return
	
	_regen_timer = poise_regen_delay
	current_poise = maxf(0.0, current_poise - amount)
	poise_changed.emit(current_poise, max_poise)
	
	if current_poise <= 0.0:
		trigger_stagger()

func trigger_stagger() -> void:
	is_staggered = true
	_stagger_timer = stagger_duration
	current_poise = 0.0
	poise_broken.emit()
	stagger_started.emit(stagger_duration)

func end_stagger() -> void:
	is_staggered = false
	_stagger_timer = 0.0
	_regen_timer = 0.0
	current_poise = max_poise
	stagger_ended.emit()
	poise_changed.emit(current_poise, max_poise)

func reset() -> void:
	is_staggered = false
	_stagger_timer = 0.0
	_regen_timer = 0.0
	current_poise = max_poise
	poise_changed.emit(current_poise, max_poise)

func get_poise_percentage() -> float:
	return (current_poise / max_poise) if max_poise > 0.0 else 0.0
