class_name Main extends Node

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
const ID_BUTTON: PackedScene = preload("res://systems/gui/id_button.scn")

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@onready var network_manager: NetworkManager = $NetworkManager
@onready var wave_manager: Node = $WaveManager
@onready var game_state_manager: GameStateManager = $GameStateManager

@onready var npcs: Node = $NPCs
@onready var server_objects: Node = $ServerObjects
@onready var level: Level = $Level
@onready var lobby_spawns: Node = $LobbySpawns
@onready var lobby: Node = $Lobby

@onready var multiplayer_spawner: MultiplayerSpawner = $ServerObjects/MultiplayerSpawner

# MAIN MENU
@onready var main_menu: Control = $MainMenu
@onready var splash_texture_rect: TextureRect = $MainMenu/SplashTextureRect
@onready var controls_texture_rect: TextureRect = $MainMenu/ControlsTextureRect
@onready var ip_line_edit: LineEdit = $MainMenu/PanelContainer2/MarginContainer/VBoxContainer/HBoxContainer/IPLineEdit

@onready var peer_connections_panel: PanelContainer = $MainMenu/PeerConnectionsPanel
@onready var peer_connections_h_box_container: HBoxContainer = $MainMenu/PeerConnectionsPanel/MarginContainer/VBoxContainer/PeerConnectionsHBoxContainer
@onready var port_warning: PanelContainer = $MainMenu/PortWarning

@onready var server_panel_container: PanelContainer = $MainMenu/ServerPanelContainer
@onready var player_count_line_edit: LineEdit = $MainMenu/ServerPanelContainer/MarginContainer/VBoxContainer/HBoxContainer/PlayerCountLineEdit
@onready var maps_v_box_container: VBoxContainer = $MainMenu/ServerPanelContainer/MarginContainer/VBoxContainer/PanelContainer/MarginContainer/VBoxContainer2/MapsVBoxContainer

@onready var player_name_line_edit: LineEdit = $MainMenu/PanelContainer3/MarginContainer/VBoxContainer/PlayerNameLineEdit
@onready var player_color_picker_button: ColorPickerButton = $MainMenu/PanelContainer3/MarginContainer/VBoxContainer/HBoxContainer/PlayerColorPickerButton

# DEBUG
@export var debug: bool = false

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

func _physics_process(_delta: float) -> void:
	if multiplayer.multiplayer_peer && multiplayer.is_server():
		server_panel_container.show()
		game_state_manager.mission_player_count = clampi(player_count_line_edit.text.to_int(), 1, 4)
	else:
		server_panel_container.hide()
	
	var player_controller: PlayerController = network_manager.try_get_local_player_controller(0)
	
	if !is_instance_valid(player_controller):
		main_menu.show()
		peer_connections_panel.hide()
		server_panel_container.hide()
		port_warning.show()
		splash_texture_rect.show()
		controls_texture_rect.hide()
	else:
		player_controller.player_name = player_name_line_edit.text
		player_controller.player_color = player_color_picker_button.color
		if player_controller.is_flag_on(PlayerController.PlayerControllerFlag.CURSOR_VISIBLE):
			if !player_controller.shop.shop_interface.visible:
				main_menu.show()
				peer_connections_panel.show()
				port_warning.hide()
				splash_texture_rect.hide()
				controls_texture_rect.show()
			else:
				main_menu.hide()
		else:
			main_menu.hide()
			peer_connections_panel.hide()
			port_warning.hide()
			splash_texture_rect.hide()
			controls_texture_rect.show()

func _on_map_id_button_pressed(id: int) -> void:
	level.map_id = id

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _on_host_pressed() -> void:
	host()

func _on_join_pressed() -> void:
	join(ip_line_edit.text)

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

func is_menu_visible() -> bool:
	return main_menu.visible

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _refresh_ui() -> void:
	for child in peer_connections_h_box_container.get_children(): child.queue_free()
	for child in network_manager.get_children():
		if !(child is PeerConnection): continue
		var peer_con_container: PanelContainer = PanelContainer.new()
		var peer_con_vbox: VBoxContainer = VBoxContainer.new()
		var peer_con_label: Label = Label.new()
		peer_con_label.text = child.name
		peer_connections_h_box_container.add_child(peer_con_container)
		peer_con_container.add_child(peer_con_vbox)
		peer_con_vbox.add_child(peer_con_label)
		
		if child.name.to_int() == multiplayer.get_unique_id():
			var owner_label: Label = Label.new()
			owner_label.text = "This is you!"
			peer_con_vbox.add_child(owner_label)

func _on_server_started() -> void:
	for child in lobby.get_children():
		if !(child is Spawner): continue
		if child.spawn_method == Spawner.SpawnMethod.ON_LOAD:
			child.spawn()
	
	game_state_manager.spawn_and_deactivate_all_pods()

func _on_start_game_pressed() -> void:
	EventBus.start_game()

func reset() -> void:
	for child in npcs.get_children():
		if child is MultiplayerSpawner: continue
		child.free()
	for child in server_objects.get_children():
		if child is MultiplayerSpawner: continue
		
		# Retarded code incoming
		if child is VehicleDropPod: EventBus.launch_pod(child.metadata["pod_id"])
		
		child.free()

func _on_join_dedicated_pressed() -> void:
	join("98.121.165.44")
