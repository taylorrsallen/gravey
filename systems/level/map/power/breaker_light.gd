class_name BreakerLight extends OmniLight3D

@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D

func _update_flipped(flipped: bool) -> void:
	if !flipped:
		light_color = Color.RED
		mesh_instance_3d.get_surface_override_material(0).albedo_color = Color.RED
	else:
		light_color = Color.GREEN
		mesh_instance_3d.get_surface_override_material(0).albedo_color = Color.GREEN
