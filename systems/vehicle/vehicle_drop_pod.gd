class_name VehicleDropPod extends VehicleBase

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@export var dropping: bool
@export var drop_target: Vector3
@export var drop_speed_curve: Curve

@export var time_to_full_speed: float = 5.0
var time_since_drop: float

@export var velocity: Vector3

@export var max_speed: float = 200.0

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _ready() -> void:
	EventBus.game_started.connect(drop)
	
	drop_target = Vector3(global_position.x + randf_range(-20.0, 20.0), 0.0, global_position.z + randf_range(-20.0, 20.0))

#func _exit_tree() -> void:
	#if !multiplayer.multiplayer_peer || !multiplayer.is_server(): return
	#if dropping: return
	#SpawnManager.spawn_server_owned_object(Spawner.SpawnType.VEHICLE, 0, metadata, global_transform)
	#destroy()

func update(delta: float) -> void:
	if !is_multiplayer_authority(): return
	
	if !dropping: return
	
	time_since_drop += delta
	
	var percent_to_full_speed: float = clampf(time_since_drop, 0.0, time_to_full_speed) / time_to_full_speed
	var thrust_strength: float = drop_speed_curve.sample(percent_to_full_speed)
	global_position += velocity * delta
	
	velocity = velocity.move_toward((drop_target - global_position).normalized() * max_speed, delta * thrust_strength)
	
	#look_at(global_position + velocity.normalized(), basis.z * randf_range(0.9, 1.1))# + (drop_target - global_position).normalized())
	
	if drop_target.distance_to(global_position) < 10.0:
		land()

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func drop() -> void:
	if !full: return
	
	EventBus.launch_pod(metadata["pod_id"])
	
	dropping = true
	can_exit = false
	velocity = -Vector3.UP * randf_range(30.0, 50.0) + global_basis.z * randf_range(40.0, 60.0) + global_basis.x * randf_range(-5.0, 5.0)

func land() -> void:
	SoundManager.play_pitched_3d_sfx(4, SoundDatabase.SoundType.SFX_EXPLOSION, global_position)
	dropping = false
	can_exit = true
	global_position = drop_target
	
	if is_instance_valid(driver): driver.exit_vehicle()
