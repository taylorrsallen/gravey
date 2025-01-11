extends Node

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
signal game_started()
signal game_ended()

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func start_game() -> void:
	Util.main.reset(true)
	_rpc_start_game.rpc()

func end_game() -> void:
	Util.main.reset(false)
	game_ended.emit()

@rpc("authority", "call_local", "reliable")
func _rpc_start_game() -> void:
	game_started.emit()
