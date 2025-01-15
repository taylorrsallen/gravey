class_name DeliveryVessel extends RigidBody3D

@export var delivery_target: Vector3

func _enter_tree() -> void:
	set_multiplayer_authority(get_parent().get_multiplayer_authority())
