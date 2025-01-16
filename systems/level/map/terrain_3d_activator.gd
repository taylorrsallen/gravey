class_name Terrain3DActivator extends Node

var activated: bool

func _physics_process(_delta: float) -> void:
	if activated:
		set_physics_process(false)
		return
	
	var terrain_3d: Terrain3D = get_parent()
	var peer_connection: PeerConnection = Util.main.network_manager.try_get_local_peer_connection()
	if !is_instance_valid(peer_connection): return
	var player_controller: PlayerController = peer_connection.try_get_player_controller(0)
	if !is_instance_valid(player_controller): return
	terrain_3d.set_camera(player_controller.camera_rig.camera_3d)
	activated = true
