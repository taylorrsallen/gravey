class_name DoubleSlidingDoor extends Node3D

@export var move_target: float = 1.0

@export var top_door: Node3D
@onready var top_start_position: Vector3 = top_door.position
@export var top_stage_1_target: Vector3
@export var top_stage_2_target: Vector3
@export var bottom_door: Node3D
@onready var bottom_start_position: Vector3 = bottom_door.position
@export var bottom_stage_1_target: Vector3
@export var bottom_stage_2_target: Vector3

var started: bool

@export var stage_1_start_delay: float = 1.0
var stage_1_start_timer: float
@export var stage_1_progress_time: float
var stage_1_progress_timer: float
var stage_1_done: bool

@export var stage_2_start_delay: float = 2.0
var stage_2_start_timer: float
@export var stage_2_progress_time: float
var stage_2_progress_timer: float
var stage_2_started: bool
var stage_2_done: bool

#@export var stage_1_start_sound: SoundReferenceData
@export var stage_1_complete_sound: SoundReferenceData
@export var stage_2_complete_sound: SoundReferenceData

@export var progress_lights: Array[Node3D]

@onready var navigation_region_3d: NavigationRegion3D = $NavigationRegion3D
@onready var progress_alarm_audio_stream_player_3d: AudioStreamPlayer3D = $ProgressAlarmAudioStreamPlayer3D
@onready var progress_audio_stream_player_3d: AudioStreamPlayer3D = $ProgressAudioStreamPlayer3D

func _update(delta: float) -> void:
	if !is_instance_valid(top_door) || !is_instance_valid(bottom_door): return
	
	# Functionality for the door being able to close, except it can't
	if move_target == 1.0:
		navigation_region_3d.enabled = true
	else:
		navigation_region_3d.enabled = false
	
	# Early exit if already finished
	if stage_2_done: return
	
	# One time setup for door opening sequence
	if !started: _start()
	
	# Spin the lights
	for progress_light in progress_lights: progress_light.rotate_y(delta * 4.0)
	
	if stage_1_start_timer < stage_1_start_delay:
		# Stage 1 has yet to start
		stage_1_start_timer += delta
	elif stage_1_progress_timer < stage_1_progress_time:
		# Stage 1 is in progress
		stage_1_progress_timer += delta
		
		var progress_percent: float = stage_1_progress_timer / stage_1_progress_time
		top_door.position = top_start_position.lerp(top_stage_1_target, progress_percent)
		bottom_door.position = bottom_start_position.lerp(bottom_stage_1_target, progress_percent)
	elif stage_2_start_timer < stage_2_start_delay:
		# Stage 2 has yet to start
		stage_2_start_timer += delta
		if !stage_1_done: _stage_1_complete()
	elif stage_2_progress_timer < stage_2_progress_time:
		# Stage 2 is in progress
		stage_2_progress_timer += delta
		
		if !stage_2_started: _stage_2_start()
		
		var progress_percent: float = stage_2_progress_timer / stage_2_progress_time
		top_door.position = top_stage_1_target.lerp(top_stage_2_target, progress_percent)
		bottom_door.position = bottom_stage_1_target.lerp(bottom_stage_2_target, progress_percent)
	else:
		_stage_2_complete()

func _start() -> void:
	started = true
	progress_alarm_audio_stream_player_3d.play()
	for progress_light in progress_lights: progress_light.show()

func _stage_1_complete() -> void:
	stage_1_done = true
	top_door.position = top_stage_1_target
	bottom_door.position = bottom_stage_1_target
	SoundManager.play_pitched_3d_sfx(stage_1_complete_sound.id, stage_1_complete_sound.type, global_position, 0.9, 1.1, stage_1_complete_sound.volume_db)

func _stage_2_start() -> void:
	progress_audio_stream_player_3d.play()

func _stage_2_complete() -> void:
	stage_2_done = true
	top_door.position = top_stage_2_target
	bottom_door.position = bottom_stage_2_target
	
	progress_alarm_audio_stream_player_3d.stop()
	progress_audio_stream_player_3d.stop()
	for progress_light in progress_lights: progress_light.hide()
	SoundManager.play_pitched_3d_sfx(stage_2_complete_sound.id, stage_2_complete_sound.type, global_position, 0.9, 1.1, stage_2_complete_sound.volume_db)
