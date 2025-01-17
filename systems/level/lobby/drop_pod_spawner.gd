class_name DropPodSpawner extends Node3D

@export var pod_id: int
@export var pod_active: bool
@export var pod_loaded: bool

@onready var l_door: RigidBody3D = $LDoor
@onready var r_door: RigidBody3D = $RDoor

@onready var l_door_closed: Vector3 = l_door.position
@onready var l_door_open: Vector3 = l_door.position + Vector3.RIGHT * 0.5
@onready var r_door_closed: Vector3 = r_door.position
@onready var r_door_open: Vector3 = r_door.position - Vector3.RIGHT * 0.5

@onready var spot_light_3d: SpotLight3D = $SpotLight3D

@export var active_light_color: Color
@export var inactive_light_color: Color

func _enter_tree() -> void:
	EventBus.pod_launched.connect(_on_pod_launched)
	EventBus.game_ended.connect(_on_game_ended)

func _physics_process(delta: float) -> void:
	if !pod_active:
		l_door.position = l_door.position.move_toward(l_door_closed, delta * 8.0)
		r_door.position = r_door.position.move_toward(r_door_closed, delta * 8.0)
		spot_light_3d.light_color = inactive_light_color
	else:
		l_door.position = l_door.position.move_toward(l_door_open, delta * 8.0)
		r_door.position = r_door.position.move_toward(r_door_open, delta * 8.0)
		spot_light_3d.light_color = active_light_color

func spawn() -> void:
	if pod_loaded: return
	var _pod: Node = SpawnManager.spawn_server_owned_object(Spawner.SpawnType.VEHICLE, 0, {"pod_id" = pod_id}, global_transform)
	pod_loaded = true

func _on_pod_launched(_pod_id: int) -> void:
	if pod_id == _pod_id: pod_loaded = false

func _on_game_ended() -> void:
	pod_loaded = false
	pod_active = false
	spawn()
