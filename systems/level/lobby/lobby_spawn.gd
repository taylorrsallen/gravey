class_name LobbySpawn extends Marker3D

func is_valid_spawn() -> bool:
	var results: Array[PhysicsBody3D] = AreaQueryManager.query_area(global_position, 2.0, 2)
	return results.is_empty()
