class_name WaveManager extends Node

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@export var extra_points_to_add_per_wave: int = 10
@export var points_to_add_per_wave: int = 10
@export var points_per_wave: int = 10
@export var max_enemies: int = 30

@export var active: bool

@export var spawners: Array[Spawner]

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func init() -> void:
	EventBus.game_started.connect(_on_game_started)
	Util.main.level.map_changed.connect(_on_map_changed)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _on_game_started() -> void:
	restart()

func _on_map_changed(level: Level) -> void:
	for child in level.map.spawners.get_children():
		if child is Spawner: spawners.append(child)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func restart() -> void:
	extra_points_to_add_per_wave = 5
	points_to_add_per_wave = 5
	points_per_wave = 10

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func spawn_wave() -> void:
	
	points_to_add_per_wave += extra_points_to_add_per_wave
	points_per_wave += points_to_add_per_wave
