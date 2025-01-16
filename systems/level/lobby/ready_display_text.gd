class_name ReadyDisplayText extends Node3D

@onready var player_counter_label: Label3D = $PlayerCounterLabel
@onready var ready_ticks_label: Label3D = $ReadyTicksLabel
@onready var launch_label: Label3D = $LaunchLabel
@onready var launch_timer_label: Label3D = $LaunchTimerLabel

@export var ready_color: Color
@export var normal_color: Color
@export var unready_color: Color
@export var deployed_color: Color
@export var inactive_color: Color

func _physics_process(_delta: float) -> void:
	player_counter_label.text = str(Util.main.game_state_manager.ready_players) + " / " + str(Util.main.game_state_manager.mission_player_count)
	launch_timer_label.text = str(Util.main.game_state_manager.game_start_countdown - Util.main.game_state_manager.game_start_timer).left(1)
	
	var map_loaded: bool = false
	for child in Util.main.level.map_container.get_children():
		if child is Map:
			map_loaded = true
			break
	
	if Util.main.game_state_manager.game_active:
		ready_ticks_label.hide()
		
		launch_label.text = "UNITS DEPLOYED"
		launch_label.modulate = deployed_color
		
		player_counter_label.text = str(Util.main.game_state_manager.players_in_mission) + " / " + str(Util.main.game_state_manager.mission_player_count)
		player_counter_label.modulate = deployed_color
		
		launch_timer_label.modulate = inactive_color
	else:
		if !map_loaded:
			ready_ticks_label.hide()
			
			launch_label.text = "CHOOSE LANDING ZONE"
			launch_label.modulate = unready_color
			
			player_counter_label.modulate = inactive_color
			launch_timer_label.modulate = inactive_color
		else:
			if Util.main.game_state_manager.all_players_ready():
				ready_ticks_label.show()
				
				launch_label.text = "LAUNCHING"
				launch_label.modulate = normal_color
				
				player_counter_label.modulate = ready_color
				launch_timer_label.modulate = ready_color
			else:
				ready_ticks_label.hide()
				
				launch_label.text = "BOARD DROP PODS"
				launch_label.modulate = normal_color
				
				player_counter_label.modulate = unready_color
				launch_timer_label.modulate = inactive_color
