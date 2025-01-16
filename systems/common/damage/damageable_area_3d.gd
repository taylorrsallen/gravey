class_name DamageableArea3D extends StaticBody3D

signal damaged(damage_data: DamageData, area_id: int, source: Node)

@export var id: int
@export var source: Node
@export var team: int = -1

func damage(damage_data: , _source: Node) -> void:
	damaged.emit(damage_data, id, _source)

func damage_sourceless(damage_data: DamageData) -> void:
	damaged.emit(damage_data, id, null)

func get_matter_id() -> int:
	if is_instance_valid(source):
		return source.get_matter_id_for_damageable_area_3d(id)
	else:
		return get_parent().get_matter_id_for_damageable_area_3d(id)

func will_die_from_damage(damage_data: DamageData) -> bool:
	if is_instance_valid(source):
		return source.will_die_from_damage(damage_data, id)
	else:
		return get_parent().will_die_from_damage(damage_data, id)
