class_name WaveManager extends Node

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@export var extra_points_to_add_per_wave: int
@export var points_to_add_per_wave: int
@export var points_per_wave: int

@export var current_wave: int

@export var max_enemies: int = 30
@export var enemies: int

@export var active: bool

@export var spawners: Array[WaveSpawner]

@export var bug_wave_chance: float = 0.5
@export var grunt_wave_chance: float = 0.5

@export var pause_between_waves: float = 10.0
@export var pause_timer: float

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func init() -> void:
	if !multiplayer.multiplayer_peer || !multiplayer.is_server(): return
	EventBus.game_started.connect(_on_game_started)
	EventBus.game_ended.connect(_on_game_ended)
	Util.main.level.map_changed.connect(_on_map_changed)
	restart()

func _physics_process(delta: float) -> void:
	if !multiplayer.multiplayer_peer || !multiplayer.is_server(): return
	if !active: return
	
	if enemies != 0: return
	
	pause_timer += delta
	if pause_timer >= pause_between_waves:
		pause_timer = 0.0
		spawn_wave()

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _on_game_started() -> void:
	restart()
	active = true

func _on_game_ended() -> void:
	restart()

func _on_map_changed(level: Level) -> void:
	restart()
	spawners = []
	for child in level.map.wave_spawners.get_children(): spawners.append(child)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func restart() -> void:
	extra_points_to_add_per_wave = 1
	points_to_add_per_wave = 8
	points_per_wave = 0
	
	current_wave = 0
	enemies = 0
	
	pause_timer = 0
	
	active = false

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func spawn_wave() -> void:
	current_wave += 1
	points_to_add_per_wave += extra_points_to_add_per_wave
	points_per_wave += points_to_add_per_wave
	
	#var bug_wave: bool = false
	
	# Basically buy units to fill up the unit max, and then upgrade the units until no points are left
	print("[WaveManager]: Spending %s points on wave %s!" % [points_per_wave, current_wave])
	var points_left: int = points_per_wave
	var bodies_to_spawn: Array[int] = []
	while points_left >= 1 && bodies_to_spawn.size() < max_enemies:
		# Appending Blits
		bodies_to_spawn.append(3)
		points_left -= 1
	
	var max_failed_upgrade_attempts: int = 10
	var failed_upgrade_attempts: int = 0
	while points_left >= 1 && failed_upgrade_attempts < max_failed_upgrade_attempts:
		var success: bool = false
		var i: int = randi_range(0, bodies_to_spawn.size() - 1)
		var body_to_upgrade: BodyData = Util.BODY_DATABASE.database[bodies_to_spawn[i]]
		
		# Get a list of bodies that this one could be upgraded to with available points
		var possible_upgrades: Array[int] = []
		for upgrade_body_id in Util.BODY_DATABASE.database.size():
			var body_to_upgrade_to: BodyData = Util.BODY_DATABASE.database[upgrade_body_id]
			if body_to_upgrade == body_to_upgrade_to: continue
			if points_left + body_to_upgrade.point_value >= body_to_upgrade_to.point_value:
				possible_upgrades.append(upgrade_body_id)
		
		if !possible_upgrades.is_empty():
			var upgrade_body_id: int = possible_upgrades.pick_random()
			var body_to_upgrade_to: BodyData = Util.BODY_DATABASE.database[upgrade_body_id]
			success = true
			bodies_to_spawn[i] = upgrade_body_id
			points_left -= (body_to_upgrade_to.point_value - body_to_upgrade.point_value)
		
		if !success: failed_upgrade_attempts += 1
	
	print("[WaveManager]: Spawning with %s points left!" % points_left)
	for body_id in bodies_to_spawn:
		var body: BodyData = Util.BODY_DATABASE.database[body_id]
		print("   - %s: %s points" % [body.name, body.point_value])
	
	spawn_bodies(bodies_to_spawn)

func spawn_bodies(bodies: Array[int]) -> void:
	var active_spawners: Array[WaveSpawner] = []
	for spawner in spawners:
		if spawner.active: active_spawners.append(spawner)
	
	for body_id in bodies:
		var spawner: WaveSpawner = active_spawners.pick_random()
		await get_tree().create_timer(0.1).timeout
		spawn(body_id, spawner)

func spawn(body_id: int, spawner: WaveSpawner) -> void:
	enemies += 1
	
	var new_spawn: Node = SpawnManager.spawn_server_owned_object(Spawner.SpawnType.ENEMY, body_id, {}, spawner.global_transform)
	new_spawn.character.killed.connect(_on_enemy_killed)

func _on_enemy_killed(_character: Character) -> void:
	enemies -= 1
	print("[WaveManager]: %s enemies left in wave" % enemies)
