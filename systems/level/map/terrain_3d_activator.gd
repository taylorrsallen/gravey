class_name Terrain3DActivator extends Node

func _ready() -> void:
	var terrain_3d: Terrain3D = get_parent()
	var peer_connection: PeerConnection = Util.main.network_manager.try_get_local_peer_connection()
	var player_controller: PlayerController = peer_connection.try_get_player_controller(0)
	terrain_3d.set_camera(player_controller.camera_rig.camera_3d)
