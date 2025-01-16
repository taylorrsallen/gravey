extends Node

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
signal game_started()
signal game_ended()
signal pod_launched(id: int)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func start_game() -> void:
	_rpc_start_game.rpc()

func end_game() -> void:
	print("end game")
	Util.main.reset()
	game_ended.emit()

@rpc("authority", "call_local", "reliable")
func _rpc_start_game() -> void:
	game_started.emit()

func launch_pod(id: int) -> void:
	_rpc_launch_pod.rpc(id)

@rpc("any_peer", "call_local", "reliable")
func _rpc_launch_pod(id: int) -> void:
	pod_launched.emit(id)
