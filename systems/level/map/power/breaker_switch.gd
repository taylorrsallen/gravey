class_name BreakerSwitch extends Node3D

@export var powered: bool

@export var flipped: bool
@export var flip_speed: float = 800.0

@export var unflip_time: float = 15.0
var unflip_timer: float

@onready var model: Node3D = $Model
@export var model_flipped_x_rotation: float = 77.3

func _update(_delta: float) -> void:
	powered = true

func _physics_process(delta: float) -> void:
	if flipped:
		model.rotation_degrees.x = move_toward(model.rotation_degrees.x, model_flipped_x_rotation, delta * flip_speed)
	else:
		model.rotation_degrees.x = move_toward(model.rotation_degrees.x, -model_flipped_x_rotation, delta * flip_speed)
	
	if !is_multiplayer_authority() || !flipped: return
	unflip_timer += delta
	if unflip_timer >= unflip_time:
		_unflip()

func try_flip() -> void:
	if !powered: return
	if flipped: return
	flipped = true
	unflip_timer = 0.0

func _unflip() -> void:
	flipped = false
	unflip_timer = 0.0
