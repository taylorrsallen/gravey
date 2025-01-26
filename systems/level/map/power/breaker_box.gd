class_name BreakerBox extends Node

@export var station_to_power: PowerStation
@export var switches: Array[BreakerSwitch]

func _physics_process(delta: float) -> void:
	var all_breakers_flipped: bool = true
	for switch in switches: all_breakers_flipped = switch.flipped
	if all_breakers_flipped: station_to_power.powered = true
