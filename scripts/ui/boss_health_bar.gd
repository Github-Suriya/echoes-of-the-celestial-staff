class_name BossHealthBar
extends CanvasLayer

## BossHealthBar
## Polished, lightweight HUD for boss encounters.
## Displays boss display name, phase title badge, smooth health bar with damage catch-up,
## and posture / poise bar.

@export var boss: BossController = null

var _name_label: Label = null
var _phase_label: Label = null
var _health_bar: ProgressBar = null
var _catchup_bar: ProgressBar = null
var _poise_bar: ProgressBar = null

var _target_health: float = 300.0
var _target_catchup: float = 300.0
var _target_poise: float = 60.0

func _ready() -> void:
	_discover_nodes()
	if boss != null:
		bind_boss(boss)

func _discover_nodes() -> void:
	_name_label = find_child("NameLabel", true, false) as Label
	_phase_label = find_child("PhaseLabel", true, false) as Label
	_health_bar = find_child("HealthBar", true, false) as ProgressBar
	_catchup_bar = find_child("CatchupBar", true, false) as ProgressBar
	_poise_bar = find_child("PoiseBar", true, false) as ProgressBar

func bind_boss(b: BossController) -> void:
	boss = b
	if boss == null:
		return
	
	if boss.boss_data != null and _name_label != null:
		_name_label.text = boss.boss_data.display_name
	
	if boss.phase_controller != null and boss.phase_controller.current_phase_data != null and _phase_label != null:
		var pdata: BossPhaseData = boss.phase_controller.current_phase_data
		_phase_label.text = "PHASE %d: %s" % [pdata.phase_id, pdata.phase_name]
	
	if boss.health_component != null:
		boss.health_component.health_changed.connect(_on_health_changed)
		var max_h: float = boss.health_component.max_health
		_target_health = boss.health_component.current_health
		_target_catchup = _target_health
		if _health_bar != null:
			_health_bar.max_value = max_h
			_health_bar.value = _target_health
		if _catchup_bar != null:
			_catchup_bar.max_value = max_h
			_catchup_bar.value = _target_catchup
	
	if boss.poise_component != null:
		boss.poise_component.poise_changed.connect(_on_poise_changed)
		var max_p: float = boss.poise_component.max_poise
		_target_poise = boss.poise_component.current_poise
		if _poise_bar != null:
			_poise_bar.max_value = max_p
			_poise_bar.value = _target_poise
	
	if boss.phase_controller != null:
		boss.phase_controller.phase_changed.connect(_on_phase_changed)

func _process(delta: float) -> void:
	if not visible:
		return
	
	# Smooth catchup bar interpolation
	if _catchup_bar != null and _catchup_bar.value > _target_health:
		_catchup_bar.value = move_toward(_catchup_bar.value, _target_health, 80.0 * delta)
	
	# Smooth poise bar interpolation
	if _poise_bar != null and absf(_poise_bar.value - _target_poise) > 0.1:
		_poise_bar.value = move_toward(_poise_bar.value, _target_poise, 60.0 * delta)

func _on_health_changed(current_hp: float, _max_hp: float) -> void:
	_target_health = current_hp
	if _health_bar != null:
		_health_bar.value = current_hp

func _on_poise_changed(current_p: float, _max_p: float) -> void:
	_target_poise = current_p

func _on_phase_changed(phase_number: int, phase_data: BossPhaseData) -> void:
	if _phase_label != null and phase_data != null:
		_phase_label.text = "PHASE %d: %s" % [phase_number, phase_data.phase_name]
