class_name DistantGraveBeacon extends Node3D

@export var time_to_come_online: float
var online_timer: float
var done: bool

@onready var laser_pointer: Node3D = $LaserPointer
@onready var audio_stream_player_3d: AudioStreamPlayer3D = $AudioStreamPlayer3D


func _update(delta: float) -> void:
	if done: return
	online_timer += delta
	if online_timer >= time_to_come_online:
		laser_pointer.show()
		audio_stream_player_3d.play()
		done = true
