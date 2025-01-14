class_name VehicleBase extends Node3D

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@onready var vehicle_entrance: InteractableBase = $VehicleEntrance
@onready var seat: Marker3D = $Seat

@export var driver: Character
@export var full: bool

@export var id: int
@export var metadata: Dictionary

@export var start_vehicle: bool
@export var can_exit: bool = true

@export var target_seat_rotation: Vector3

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _enter_tree() -> void:
	set_multiplayer_authority(get_parent().get_multiplayer_authority())

func update(_delta: float) -> void:
	pass

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func board(character: Character) -> void:
	driver = character
	full = true

func exit() -> void:
	driver = null
	full = false

func try_reload() -> void: pass

func destroy() -> void:
	if multiplayer.is_server():
		queue_free()
	else:
		hide()
		process_mode = Node.PROCESS_MODE_DISABLED
		_rpc_destroy.rpc_id(1)

@rpc("any_peer", "call_remote", "unreliable")
func _rpc_destroy() -> void:
	queue_free()
