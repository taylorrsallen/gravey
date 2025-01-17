class_name GraveBeacon extends Node3D

@onready var omni_light_3d: OmniLight3D = $OmniLight3D
@onready var laser_pointer: Node3D = $LaserPointer
@onready var audio_stream_player_3d: AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var audio_stream_player_3d_2: AudioStreamPlayer3D = $AudioStreamPlayer3D2

var done: bool

func _update(_delta: float) -> void:
	if done: return
	done = true
	omni_light_3d.show()
	laser_pointer.show()
	audio_stream_player_3d.play()
	audio_stream_player_3d_2.play()
