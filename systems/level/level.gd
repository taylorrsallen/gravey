class_name Level extends Node

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
signal map_changed(level: Level)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@onready var map_container: Node = $Map
@export var map: Map

@export var map_id: int: set = _set_map_id
@export var map_data: MapData: set = _set_map_data

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _set_map_id(_map_id: int) -> void:
	map_id = _map_id
	if map_id == 0:
		for child in map_container.get_children(): child.free()
		return
	map_data = Util.MAP_DATABASE.database[map_id - 1]

func _set_map_data(_map_data: MapData) -> void:
	map_data = _map_data
	for child in map_container.get_children(): child.free()
	map = map_data.scene.instantiate()
	map_container.add_child(map)
	map_changed.emit(self)
