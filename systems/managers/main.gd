class_name Main extends Node

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
const ID_BUTTON: PackedScene = preload("res://systems/gui/id_button.scn")

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@onready var peer_connections_box: HBoxContainer = $PeerConnectionsBox

@onready var network_manager: NetworkManager = $NetworkManager
@onready var wave_manager: Node = $WaveManager

@onready var npcs: Node = $NPCs
@onready var server_objects: Node = $ServerObjects
@onready var level: Level = $Level
@onready var lobby_spawns: Node = $LobbySpawns
@onready var lobby: Node = $Lobby

@onready var v_box_container: VBoxContainer = $VBoxContainer
@onready var maps_v_box_container: VBoxContainer = $VBoxContainer/PanelContainer/MarginContainer/MapsVBoxContainer

@onready var multiplayer_spawner: MultiplayerSpawner = $ServerObjects/MultiplayerSpawner

## DEBUG
@export var debug: bool = false

@onready var start_game: Button = $VBoxContainer/StartGame
# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _ready() -> void:
	network_manager.server_started.connect(_on_server_started)
	network_manager.state_changed.connect(_refresh_ui)
	Util.main = self
	
	#var peer_connection: PeerConnection = network_manager._create_peer_connection(1)
	#peer_connection.try_create_player_controller()
	
	for i in Util.MAP_DATABASE.database.size():
		var map_button: IDButton = ID_BUTTON.instantiate()
		map_button.text = Util.MAP_DATABASE.database[i].name
		map_button.id = i + 1
		map_button.id_pressed.connect(_on_map_id_button_pressed)
		maps_v_box_container.add_child(map_button, true)
	
	for vehicle_data in Util.VEHICLE_DATABASE.database:
		multiplayer_spawner.add_spawnable_scene(vehicle_data.scene.resource_path)
	
	wave_manager.init()

func _on_map_id_button_pressed(id: int) -> void:
	level.map_id = id

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _on_host_pressed() -> void:
	host()

@onready var line_edit: LineEdit = $VBoxContainer/LineEdit
func _on_join_pressed() -> void:
	join(line_edit.text)

func _on_disconnect_pressed() -> void:
	disconnect_network()

func host() -> void:
	EventBus.end_game()
	level.map_id = 0
	network_manager.create_server()

func join(ip: String) -> void:
	network_manager.connect_to_server(ip)

func disconnect_network() -> void:
	network_manager.disconnect_network()
	EventBus.end_game()
	level.map_id = 0

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _refresh_ui() -> void:
	for child in peer_connections_box.get_children(): child.queue_free()
	for child in network_manager.get_children():
		if !(child is PeerConnection): continue
		var peer_con_container: PanelContainer = PanelContainer.new()
		var peer_con_vbox: VBoxContainer = VBoxContainer.new()
		var peer_con_label: Label = Label.new()
		peer_con_label.text = child.name
		peer_connections_box.add_child(peer_con_container)
		peer_con_container.add_child(peer_con_vbox)
		peer_con_vbox.add_child(peer_con_label)
		
		if child.name.to_int() == multiplayer.get_unique_id():
			var owner_label: Label = Label.new()
			owner_label.text = "This is you!"
			peer_con_vbox.add_child(owner_label)

func _on_server_started() -> void:
	start_game.show()
	
	for child in lobby.get_children():
		if !(child is Spawner): continue
		if child.spawn_method == Spawner.SpawnMethod.ON_LOAD:
			child.spawn()

func _on_start_game_pressed() -> void:
	EventBus.start_game()

func reset(game_starting: bool) -> void:
	for child in npcs.get_children():
		if child is MultiplayerSpawner: continue
		if game_starting && child.metadata.has("on_load"): continue
		child.free()
	for child in server_objects.get_children():
		if child is MultiplayerSpawner: continue
		if game_starting && child.metadata.has("on_load"): continue
		child.free()
