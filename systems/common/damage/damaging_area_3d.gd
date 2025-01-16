class_name DamagingArea3D extends Area3D

signal dealt_damage(body: PhysicsBody3D)

@export var active: bool = true
@export var damage_on_impact: bool = true
@export var damage_data: DamageData

@export var exclude_areas: Array[DamageableArea3D] = []
@export var exclude_team: int = -1

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(_delta: float) -> void:
	if !active: return
	var overlaps = get_overlapping_bodies()
	if overlaps.is_empty(): return
	_on_body_entered(overlaps.pick_random())

func _on_body_entered(body: PhysicsBody3D) -> void:
	if active && body is DamageableArea3D:
		if _is_area_excluded(body): return
		
		body.damage(damage_data, null)
		active = false
		dealt_damage.emit(body)

func _is_area_excluded(area: DamageableArea3D) -> bool:
	if exclude_team != -1 && area.team != -1 && exclude_team == area.team: return true
	if exclude_areas.has(area): return true
	return false
