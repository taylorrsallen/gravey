class_name ImpulseFromCenter extends RigidBody3D

func _ready() -> void:
	apply_impulse((get_parent().global_position - global_position).normalized() * randf_range(5.0, 10.0))
