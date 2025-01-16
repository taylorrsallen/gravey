class_name PoweredDevice extends Node3D

@export var powered: bool
@export var connected_station_id: int
@onready var map: Map = get_parent().get_parent()

func _physics_process(delta: float) -> void:
	_update_powered_state()
	if !powered: return
	for child in get_children(): child._update(delta)

func _update_powered_state() -> void:
	if !is_instance_valid(map): return
	for power_station in map.power_stations.get_children():
		if !(power_station is PowerStation): return
		if power_station.id != connected_station_id: continue
		powered = power_station.powered
