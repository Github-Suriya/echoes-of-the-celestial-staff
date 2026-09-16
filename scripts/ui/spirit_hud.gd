class_name SpiritHUD
extends CanvasLayer

## SpiritHUD
## Development UI displaying real-time Spirit resource gauge and ability slot cards with live cooldowns.

@export var player: PlayerController = null

@onready var spirit_label: Label = $HUDPanel/MarginContainer/VBoxContainer/SpiritHeader/SpiritLabel
@onready var spirit_progress: ProgressBar = $HUDPanel/MarginContainer/VBoxContainer/SpiritBar
@onready var slot_1_status: Label = $HUDPanel/MarginContainer/VBoxContainer/AbilityContainer/Slot1/VBox/StatusLabel
@onready var slot_2_status: Label = $HUDPanel/MarginContainer/VBoxContainer/AbilityContainer/Slot2/VBox/StatusLabel
@onready var slot_3_status: Label = $HUDPanel/MarginContainer/VBoxContainer/AbilityContainer/Slot3/VBox/StatusLabel
@onready var awakening_label: Label = $HUDPanel/MarginContainer/VBoxContainer/AwakeningContainer/AwakeningLabel if has_node("HUDPanel/MarginContainer/VBoxContainer/AwakeningContainer/AwakeningLabel") else null
@onready var awakening_bar: ProgressBar = $HUDPanel/MarginContainer/VBoxContainer/AwakeningContainer/AwakeningBar if has_node("HUDPanel/MarginContainer/VBoxContainer/AwakeningContainer/AwakeningBar") else null

var _spirit_comp: SpiritComponent = null
var _ability_ctrl: SpiritAbilityController = null
var _trans_ctrl: TransformationController = null

func _ready() -> void:
	if player != null:
		bind_player(player)

func bind_player(target_player: CharacterBody2D) -> void:
	if target_player == null:
		return
	
	if target_player.has_node("Components/SpiritComponent"):
		_spirit_comp = target_player.get_node("Components/SpiritComponent") as SpiritComponent
		if _spirit_comp != null:
			_spirit_comp.spirit_changed.connect(_on_spirit_changed)
			_update_spirit_display(_spirit_comp.get_spirit(), _spirit_comp.get_max_spirit())
	
	if target_player.has_node("Components/SpiritAbilityController"):
		_ability_ctrl = target_player.get_node("Components/SpiritAbilityController") as SpiritAbilityController
	
	if target_player.has_node("Components/TransformationController"):
		_trans_ctrl = target_player.get_node("Components/TransformationController") as TransformationController

func _process(_delta: float) -> void:
	if _ability_ctrl != null:
		# Update Slot 1: Celestial Arc
		_update_slot_status(slot_1_status, &"celestial_arc")
		# Update Slot 2: Heavenly Pulse
		_update_slot_status(slot_2_status, &"heavenly_pulse")
		# Update Slot 3: Cloud Step
		_update_slot_status(slot_3_status, &"cloud_step")
	
	_update_awakening_display()

func _update_awakening_display() -> void:
	if awakening_label == null:
		return
	
	if _trans_ctrl != null and _trans_ctrl.is_active():
		var rem: float = _trans_ctrl.get_remaining_duration()
		awakening_label.text = "CELESTIAL AWAKENING: %.1fs" % rem
		awakening_label.modulate = Color(1.0, 0.85, 0.2)
		if awakening_bar != null:
			awakening_bar.visible = true
			awakening_bar.value = _trans_ctrl.get_duration_ratio() * 100.0
	else:
		if awakening_bar != null:
			awakening_bar.visible = false
		if _trans_ctrl != null and _trans_ctrl.can_activate():
			awakening_label.text = "[F] AWAKENING: READY"
			awakening_label.modulate = Color(0.2, 1.0, 0.5)
		elif _spirit_comp != null and _spirit_comp.get_spirit() >= 100.0:
			awakening_label.text = "[F] AWAKENING: READY"
			awakening_label.modulate = Color(0.2, 1.0, 0.5)
		else:
			awakening_label.text = "[F] AWAKENING: NEED 100 SP"
			awakening_label.modulate = Color(0.6, 0.6, 0.6)

func _update_slot_status(label: Label, ability_id: StringName) -> void:
	if label == null or _ability_ctrl == null:
		return
	
	if _ability_ctrl.is_ability_ready(ability_id):
		label.text = "READY"
		label.modulate = Color(0.2, 1.0, 0.5)
	else:
		var rem: float = _ability_ctrl.get_cooldown_remaining(ability_id)
		label.text = "%.1fs" % rem
		label.modulate = Color(1.0, 0.4, 0.4)

func _on_spirit_changed(current: float, max_val: float) -> void:
	_update_spirit_display(current, max_val)

func _update_spirit_display(current: float, max_val: float) -> void:
	if spirit_label != null:
		spirit_label.text = "SPIRIT: %.0f / %.0f" % [current, max_val]
	if spirit_progress != null:
		spirit_progress.max_value = max_val
		spirit_progress.value = current
