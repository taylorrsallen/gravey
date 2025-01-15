class_name DamagingArea3D extends Area3D

signal dealt_damage(body: PhysicsBody3D)

@export var active: bool = true
@export var damage_on_impact: bool = true
@export var damage_data: DamageData

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(_delta: float) -> void:
	if !active: return
	var overlaps = get_overlapping_bodies()
	if overlaps.is_empty(): return
	_on_body_entered(overlaps.pick_random())

func _on_body_entered(body: PhysicsBody3D) -> void:
	if active && body is DamageableArea3D:
		body.damage(damage_data, null)
		active = false
		dealt_damage.emit(body)
