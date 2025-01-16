class_name Level extends Node

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
signal map_changed(level: Level)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@onready var map_container: Node = $Map
@onready var multiplayer_spawner: MultiplayerSpawner = $Map/MultiplayerSpawner
@export var map: Map

@export var map_id: int: set = _set_map_id
@export var map_data: MapData: set = _set_map_data

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _set_map_id(_map_id: int) -> void:
	map_id = _map_id
	if map_id == 0:
		clear_map()
		return
	map_data = Util.MAP_DATABASE.database[map_id - 1]

func _set_map_data(_map_data: MapData) -> void:
	map_data = _map_data
	clear_map()
	map = map_data.scene.instantiate()
	map_container.add_child(map, true)
	map_changed.emit(self)

func clear_map() -> void:
	for child in map_container.get_children():
		if child is MultiplayerSpawner: continue
		child.free()

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _ready() -> void:
	for existing_map_data in Util.MAP_DATABASE.database: multiplayer_spawner.add_spawnable_scene(existing_map_data.scene.resource_path)
