class_name HangingBulb extends Node3D

@export var powered: bool
@export var broken: bool
@export var broken_material: Material

@export var bulb_mesh: MeshInstance3D
@export var light: Node3D

func _physics_process(_delta: float) -> void:
	if powered && !broken:
		bulb_mesh.set_surface_override_material(1, null)
		light.show()
	else:
		bulb_mesh.set_surface_override_material(1, broken_material)
		light.hide()

func _update(_delta: float) -> void:
	powered = true

func _on_damageable_area_3d_damaged(_damage_data: DamageData, _area_id: int, _source: Node) -> void:
	broken = true

func get_matter_id_for_damageable_area_3d(_area_id: int) -> int:
	return 2

func will_die_from_damage(_damage_data: DamageData) -> bool:
	return false
