class_name TestStanceRoom
extends Node2D

## TestStanceRoom
## Dedicated testing sandbox for evaluating combat stances:
## Swift, Mountain, Storm modifiers across locomotion, light/heavy attacks,
## charged strikes, poise depletion, dodge mobility, and parry mechanics.

@onready var player: PlayerController = $Player
@onready var attacker: CombatTrainingAttacker = $CombatTrainingAttacker
@onready var dummy: CombatTestDummy = $CombatTestDummy
@onready var stance_display: Label = $UI/StanceHUD/Margin/HBox/StanceLabel

func _ready() -> void:
	if has_node("/root/GameManager"):
		var gm: Node = get_node("/root/GameManager")
		if gm != null and gm.has_method("set_game_state"):
			gm.set_game_state(2) # GameState.PLAYING
	
	if has_node("/root/DebugManager"):
		var dm: Node = get_node("/root/DebugManager")
		if dm != null and dm.has_method("log_info"):
			dm.log_info("Combat Stances Test Room initialized.", "WORLD")
	
	_update_stance_hud()

func _process(_delta: float) -> void:
	_update_stance_hud()

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	
	var stance_ctrl: StanceController = _get_player_stance_controller()
	
	match event.keycode:
		KEY_R:
			if attacker != null:
				attacker.reset_attacker()
			if dummy != null:
				dummy.reset_dummy()
		KEY_T:
			if attacker != null:
				attacker.trigger_attack()
		KEY_Y:
			if attacker != null:
				attacker.auto_attack = not attacker.auto_attack
		KEY_C:
			if stance_ctrl != null:
				stance_ctrl.cycle_stance()
		KEY_1:
			if stance_ctrl != null:
				stance_ctrl.set_stance(StanceData.StanceType.SWIFT)
		KEY_2:
			if stance_ctrl != null:
				stance_ctrl.set_stance(StanceData.StanceType.MOUNTAIN)
		KEY_3:
			if stance_ctrl != null:
				stance_ctrl.set_stance(StanceData.StanceType.STORM)

func _update_stance_hud() -> void:
	if stance_display == null:
		return
	
	var stance_ctrl: StanceController = _get_player_stance_controller()
	if stance_ctrl == null:
		stance_display.text = "STANCE CONTROLLER NOT FOUND"
		return
	
	var current: int = stance_ctrl.get_current_stance()
	var swift_tag: String = "▶ [SWIFT] ◀" if current == StanceData.StanceType.SWIFT else "[ Swift ]"
	var mountain_tag: String = "▶ [MOUNTAIN] ◀" if current == StanceData.StanceType.MOUNTAIN else "[ Mountain ]"
	var storm_tag: String = "▶ [STORM] ◀" if current == StanceData.StanceType.STORM else "[ Storm ]"
	
	var mults_info: String = "Spd: %.2fx | Atk: %.2fx | Dmg: %.2fx | Pse: %.2fx | Ddg: %.2fx" % [
		stance_ctrl.get_movement_speed_multiplier(),
		stance_ctrl.get_attack_speed_multiplier(),
		stance_ctrl.get_damage_multiplier(),
		stance_ctrl.get_poise_damage_multiplier(),
		stance_ctrl.get_dodge_distance_multiplier()
	]
	
	stance_display.text = "%s    %s    %s\n%s" % [swift_tag, mountain_tag, storm_tag, mults_info]

func _get_player_stance_controller() -> StanceController:
	if player != null and player.has_node("Components/StanceController"):
		return player.get_node("Components/StanceController") as StanceController
	return null
