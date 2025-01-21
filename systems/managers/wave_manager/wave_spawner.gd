class_name WaveSpawner extends Marker3D

@export var active: bool
@export var spawn_roles: Array[BodyData.BodyRole] = [BodyData.BodyRole.TRASH]

func _update(_delta: float) -> void: active = true
