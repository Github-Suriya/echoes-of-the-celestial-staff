class_name ChapterHUD
extends CanvasLayer

## ChapterHUD
## Minimalist, high-clarity HUD for Chapter 1: Forbidden Forest.
## Visualizes Player Health, Spirit, Combat Stance, active Boss health/poise/phase,
## Checkpoint notifications, Death feedback, and Chapter Completion victory screen.

@export var player: PlayerController = null

@onready var health_bar: ProgressBar = find_child("HealthBar", true, false) as ProgressBar
@onready var health_label: Label = find_child("HealthLabel", true, false) as Label
@onready var spirit_bar: ProgressBar = find_child("SpiritBar", true, false) as ProgressBar
@onready var stance_badge: Label = find_child("StanceBadge", true, false) as Label
@onready var awakening_badge: Label = find_child("AwakeningBadge", true, false) as Label

@onready var boss_hud_panel: Control = find_child("BossHUDPanel", true, false) as Control
@onready var boss_name_label: Label = find_child("BossNameLabel", true, false) as Label
@onready var boss_phase_label: Label = find_child("BossPhaseLabel", true, false) as Label
@onready var boss_health_bar: ProgressBar = find_child("BossHealthBar", true, false) as ProgressBar
@onready var boss_poise_bar: ProgressBar = find_child("BossPoiseBar", true, false) as ProgressBar

@onready var notification_banner: Control = find_child("NotificationBanner", true, false) as Control
@onready var notification_label: Label = find_child("NotificationLabel", true, false) as Label

@onready var death_overlay: Control = find_child("DeathOverlay", true, false) as Control
@onready var victory_overlay: Control = find_child("VictoryOverlay", true, false) as Control

var _current_active_boss: BossController = null
var _notification_timer: float = 0.0

func _ready() -> void:
	if notification_banner != null:
		notification_banner.visible = false
	if death_overlay != null:
		death_overlay.visible = false
	if victory_overlay != null:
		victory_overlay.visible = false
	if boss_hud_panel != null:
		boss_hud_panel.visible = false
	
	_connect_event_bus()
	
	if player != null:
		bind_player(player)

func _process(delta: float) -> void:
	if _notification_timer > 0.0:
		_notification_timer -= delta
		if _notification_timer <= 0.0 and notification_banner != null:
			notification_banner.visible = false
	
	_update_player_state_display()
	_update_boss_display()

func bind_player(p: PlayerController) -> void:
	player = p
	if player == null:
		return
	
	if player.health_component != null:
		player.health_component.health_changed.connect(_on_player_health_changed)
		_update_health_display(player.health_component.current_health, player.health_component.max_health)
	
	if player.spirit_component != null:
		player.spirit_component.spirit_changed.connect(_on_player_spirit_changed)
		_update_spirit_display(player.spirit_component.get_spirit(), player.spirit_component.get_max_spirit())
	
	if player.stance_controller != null:
		player.stance_controller.stance_changed.connect(_on_stance_changed)
		_update_stance_badge(player.stance_controller.get_current_stance())

func bind_boss(b: BossController) -> void:
	_current_active_boss = b
	if _current_active_boss == null:
		if boss_hud_panel != null:
			boss_hud_panel.visible = false
		return
	
	if boss_hud_panel != null:
		boss_hud_panel.visible = true
	
	if boss_name_label != null and _current_active_boss.boss_data != null:
		boss_name_label.text = _current_active_boss.boss_data.display_name.to_upper()
	
	_update_boss_phase_label()
	
	if _current_active_boss.health_component != null and boss_health_bar != null:
		boss_health_bar.max_value = _current_active_boss.health_component.max_health
		boss_health_bar.value = _current_active_boss.health_component.current_health
	
	if _current_active_boss.poise_component != null and boss_poise_bar != null:
		boss_poise_bar.max_value = _current_active_boss.poise_component.max_poise
		boss_poise_bar.value = _current_active_boss.poise_component.current_poise

func unbind_boss() -> void:
	_current_active_boss = null
	if boss_hud_panel != null:
		boss_hud_panel.visible = false

func show_notification(text: String, duration: float = 2.5) -> void:
	if notification_label != null:
		notification_label.text = text
	if notification_banner != null:
		notification_banner.visible = true
	_notification_timer = duration

func show_chapter_complete() -> void:
	if victory_overlay != null:
		victory_overlay.visible = true
	if boss_hud_panel != null:
		boss_hud_panel.visible = false

func _connect_event_bus() -> void:
	if not has_node("/root/EventBus"):
		return
	
	var bus: Node = get_node("/root/EventBus")
	if bus == null:
		return
	
	if bus.has_signal("checkpoint_activated") and not bus.checkpoint_activated.is_connected(_on_checkpoint_activated):
		bus.checkpoint_activated.connect(_on_checkpoint_activated)
	
	if bus.has_signal("player_died") and not bus.player_died.is_connected(_on_player_died):
		bus.player_died.connect(_on_player_died)
	
	if bus.has_signal("boss_defeated") and not bus.boss_defeated.is_connected(_on_boss_defeated):
		bus.boss_defeated.connect(_on_boss_defeated)

func _on_player_health_changed(current: float, max_val: float) -> void:
	_update_health_display(current, max_val)

func _on_player_spirit_changed(current: float, max_val: float) -> void:
	_update_spirit_display(current, max_val)

func _on_stance_changed(new_stance: int, _old_stance: int) -> void:
	_update_stance_badge(new_stance)

func _on_checkpoint_activated(cp_id: String) -> void:
	show_notification("SHRINE ACTIVATED — RESTORED & BOUND", 2.2)
	if death_overlay != null:
		death_overlay.visible = false

func _on_player_died() -> void:
	if death_overlay != null:
		death_overlay.visible = true

func _on_boss_defeated(boss_name: String) -> void:
	if _current_active_boss != null and _current_active_boss.boss_data != null and _current_active_boss.boss_data.display_name == boss_name:
		unbind_boss()
	
	if boss_name == "Corrupted Forest Heart":
		show_chapter_complete()

func _update_health_display(cur: float, max_v: float) -> void:
	if health_bar != null:
		health_bar.max_value = max_v
		health_bar.value = cur
	if health_label != null:
		health_label.text = "HP %d / %d" % [int(cur), int(max_v)]

func _update_spirit_display(cur: float, max_v: float) -> void:
	if spirit_bar != null:
		spirit_bar.max_value = max_v
		spirit_bar.value = cur

func _update_stance_badge(stance_type: int) -> void:
	if stance_badge == null:
		return
	match stance_type:
		0: # Swift
			stance_badge.text = "[C] STANCE: SWIFT"
			stance_badge.modulate = Color(0.3, 0.9, 0.95)
		1: # Mountain
			stance_badge.text = "[C] STANCE: MOUNTAIN"
			stance_badge.modulate = Color(0.95, 0.75, 0.25)
		2: # Storm
			stance_badge.text = "[C] STANCE: STORM"
			stance_badge.modulate = Color(0.75, 0.45, 0.95)
		_:
			stance_badge.text = "[C] STANCE: %d" % stance_type
			stance_badge.modulate = Color.WHITE

func _update_player_state_display() -> void:
	if player == null:
		return
	
	if awakening_badge != null:
		if player.transformation_controller != null and player.transformation_controller.is_active():
			var rem: float = player.transformation_controller.get_remaining_duration()
			awakening_badge.visible = true
			awakening_badge.text = "AWAKENING: %.1fs" % rem
		else:
			awakening_badge.visible = false

func _update_boss_display() -> void:
	if _current_active_boss == null or not is_instance_valid(_current_active_boss):
		if boss_hud_panel != null and boss_hud_panel.visible:
			boss_hud_panel.visible = false
		return
	
	_update_boss_phase_label()
	
	if _current_active_boss.health_component != null and boss_health_bar != null:
		boss_health_bar.value = _current_active_boss.health_component.current_health
	
	if _current_active_boss.poise_component != null and boss_poise_bar != null:
		boss_poise_bar.value = _current_active_boss.poise_component.current_poise

func _update_boss_phase_label() -> void:
	if boss_phase_label != null and _current_active_boss != null and _current_active_boss.phase_controller != null:
		var pdata: BossPhaseData = _current_active_boss.phase_controller.current_phase_data
		if pdata != null:
			boss_phase_label.text = "PHASE %d: %s" % [pdata.phase_id, pdata.phase_name.to_upper()]
