class_name GameStateManager extends Node

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@export var active_players: int
@export var ready_players: int
@export var ready_player_characters: Array[Character]

@export var update_time: float = 0.5
var update_timer: float

@export var game_active: bool

var game_start_countdown: float = 5.0
@export var game_start_timer: float

@export var drop_pod_spawners: Array[DropPodSpawner]

@export var mission_player_count: int = 1: set = _set_mission_player_count
@export var players_in_mission: int
@export var player_characters_in_mission: Array[Character]
@export var lives: int

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _set_mission_player_count(_mission_player_count) -> void: mission_player_count = clampi(_mission_player_count, 1, 4)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _enter_tree() -> void:
	EventBus.game_started.connect(_on_game_started)
	EventBus.game_ended.connect(_on_game_ended)

func _ready() -> void:
	if !multiplayer.multiplayer_peer || !multiplayer.is_server(): return
	drop_pod_spawners = []
	for child in get_parent().get_node("Lobby").get_children():
		if !(child is DropPodSpawner): continue
		drop_pod_spawners.append(child)

func _on_game_started() -> void:
	players_in_mission = ready_player_characters.size()
	player_characters_in_mission = ready_player_characters.duplicate(true)
	for readied_character in ready_player_characters:
		readied_character.killed.connect(_on_readied_character_killed)
	game_active = true

func _on_game_ended() -> void: game_active = false

func _on_readied_character_killed(_character: Character) -> void:
	if lives == 0:
		players_in_mission -= 1
	else:
		lives -= 1
		# TODO: Open a pod door

func _physics_process(delta: float) -> void:
	if !multiplayer.multiplayer_peer || !multiplayer.is_server(): return
	
	if game_active:
		var invalid_index: int = -1
		for i in player_characters_in_mission.size():
			if !is_instance_valid(player_characters_in_mission[i]):
				invalid_index = i
				break
		
		if invalid_index != -1:
			_on_readied_character_killed(null)
			player_characters_in_mission.remove_at(invalid_index)
	
	update_timer += delta
	if update_timer >= update_time:
		update_timer -= update_time
		_update_all_players_in_vehicles()
	
	if !game_active && all_players_ready() && is_instance_valid(Util.main.level.map):
		game_start_timer += delta
		
		if game_start_timer >= game_start_countdown:
			game_start_timer = 0.0
			EventBus.start_game()
	else:
		game_start_timer = 0.0
	
	if game_active && players_in_mission == 0:
		EventBus.end_game()
	
	for pod_spawner in drop_pod_spawners: pod_spawner.pod_active = false
	if is_instance_valid(Util.main.level.map) && !game_active:
		for i in mission_player_count: drop_pod_spawners[i].pod_active = true

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func spawn_and_deactivate_all_pods() -> void:
	for pod_spawner in drop_pod_spawners:
		pod_spawner.spawn()
		pod_spawner.pod_active = false

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _update_all_players_in_vehicles() -> void:
	active_players = 0
	ready_player_characters = []
	
	var player_controllers: Array[PlayerController] = get_player_controllers()
	
	var player_characters: Array[Character] = []
	for player_controller in player_controllers:
		if is_instance_valid(player_controller.character) && !player_controller.character.dead:
			player_characters.append(player_controller.character)
			continue
			
		var non_server_character: Character = null
		for owned_object in player_controller.owned_objects.get_children():
			if owned_object is Character:
				non_server_character = owned_object
				break
		
		if is_instance_valid(non_server_character) && !non_server_character.dead: player_characters.append(non_server_character)
	
	if player_characters.is_empty():
		ready_players = 0
		return
	
	active_players = clampi(player_characters.size(), 0, 4)
	
	for player_character in player_characters:
		if player_character.in_vehicle:
			ready_player_characters.append(player_character)
	
	ready_players = ready_player_characters.size()

func get_player_controllers() -> Array[PlayerController]:
	var player_controllers: Array[PlayerController] = []
	
	var peer_connections: Array[PeerConnection] = []
	for peer_connection in Util.main.network_manager.get_children():
		if peer_connection is PeerConnection:
			for player_controller in peer_connection.get_children():
				if player_controller is PlayerController:
					player_controllers.append(player_controller)
	
	return player_controllers

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func all_players_ready() -> bool:
	return active_players != 0 && ready_players == mission_player_count
