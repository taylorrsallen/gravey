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
	
	drop_target = Vector3(global_position.x, 0.0, global_position.z)

func update(delta: float) -> void:
	if !is_multiplayer_authority(): return
	if !dropping: return
	
	time_since_drop += delta
	
	var percent_to_full_speed: float = clampf(time_since_drop, 0.0, time_to_full_speed) / time_to_full_speed
	var thrust_strength: float = drop_speed_curve.sample(percent_to_full_speed)
	global_position += velocity * delta
	
	velocity = velocity.move_toward((drop_target - global_position).normalized() * max_speed, delta * thrust_strength)
	
	if global_position.distance_to(drop_target) < 0.5:
		dropping = false
		can_exit = true
	
	look_at(global_position + velocity)
	rotate_z(deg_to_rad(90.0))
	
	if drop_target.distance_to(global_position) < 10.0:
		land()

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func drop() -> void:
	dropping = true
	can_exit = false
	velocity = Vector3.UP * 15.0 + global_basis.z * 40.0

func land() -> void:
	SoundManager.play_pitched_3d_sfx(4, SoundDatabase.SoundType.SFX_EXPLOSION, global_position)
	dropping = false
	can_exit = true
	global_position = drop_target
