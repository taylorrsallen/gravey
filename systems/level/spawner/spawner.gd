class_name Spawner extends Marker3D

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
signal finished_spawning()

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
enum SpawnMethod {
	ON_LOAD,
	ON_START,
	CONTINUOUS,
}

enum SpawnType {
	PLAYER,
	ENEMY,
	EQUIPPABLE,
	PICKUP,
	VEHICLE,
}

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@export var spawn_method: SpawnMethod = SpawnMethod.ON_START

@export var spawn_type: SpawnType
@export var spawn_id: int
@export var metadata: Dictionary = {}

@export var continuous_spawn_rate: float
var continuous_spawn_timer: float
@export var continuous_spawn_count: int = -1
var spawned: int

@export var max_spawned_at_once: int = 20
var currently_spawned: int

@export var active: bool

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _ready() -> void:
	if !multiplayer.is_server(): return
	EventBus.game_started.connect(_on_game_started)
	EventBus.game_ended.connect(_on_game_ended)

func _physics_process(delta: float) -> void:
	if !multiplayer.multiplayer_peer: return
	if !multiplayer.is_server(): return
	
	if !active: return
	if spawn_method != SpawnMethod.CONTINUOUS: return
	if continuous_spawn_count > -1 && spawned >= continuous_spawn_count: return
	if currently_spawned >= max_spawned_at_once: return
	
	continuous_spawn_timer += delta
	if continuous_spawn_timer >= continuous_spawn_rate:
		continuous_spawn_timer = 0.0
		spawn()

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _on_game_started() -> void:
	_on_game_ended()
	active = true
	if spawn_method != SpawnMethod.ON_START: return
	spawn()

func _on_game_ended() -> void:
	active = false
	currently_spawned = 0
	spawned = 0

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func reset_spawned() -> void:
	spawned = 0

func spawn() -> void:
	spawned += 1
	currently_spawned += 1
	
	if spawn_method == SpawnMethod.ON_LOAD: metadata["on_load"] = 0
	
	var new_spawn: Node = SpawnManager.spawn_server_owned_object(spawn_type, spawn_id, metadata, global_transform)
	if continuous_spawn_count > -1 && spawned >= continuous_spawn_count: finished_spawning.emit()
	
	if new_spawn is AIController:
		new_spawn.character.killed.connect(_on_spawn_killed)

func _on_spawn_killed(_character: Character) -> void:
	currently_spawned -= 1
