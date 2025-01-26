class_name LockedPhysicsDoor extends Node3D

@export var locked: bool = true

@export var unlock_sound: SoundReferenceData
@export var unlock_delay: float = 2.0
var unlock_timer: float

@onready var rigid_body_3d: RigidBody3D = $RigidBody3D
@onready var navigation_region_3d: NavigationRegion3D = $NavigationRegion3D

func _physics_process(_delta: float) -> void:
	if locked:
		rigid_body_3d.freeze = true
		rigid_body_3d.rotation = Vector3.ZERO
		rigid_body_3d.collision_layer = 1
		navigation_region_3d.enabled = false
	else:
		rigid_body_3d.freeze = false
		rigid_body_3d.collision_layer = 4
		navigation_region_3d.enabled = true

func _update(delta: float) -> void:
	if !locked: return
	unlock_timer += delta
	if unlock_timer >= unlock_delay:
		locked = false
		if unlock_sound: SoundManager.play_pitched_3d_sfx(unlock_sound.id, unlock_sound.type, global_position, 0.9, 1.1, unlock_sound.volume_db)
