class_name BreakerBox extends Node

@export var station_to_power: PowerStation
@export var switches: Array[BreakerSwitch]

func _physics_process(_delta: float) -> void:
	var all_breakers_flipped: bool = true
	for switch in switches:
		if !switch.flipped:
			all_breakers_flipped = false
			break
	if all_breakers_flipped: station_to_power.powered = true
