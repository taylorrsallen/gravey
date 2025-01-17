class_name ShowNodes extends Node3D

@export var show_targets: Array[Node3D]
var done: bool

func _ready() -> void:
	for show_target in show_targets: show_target.hide()

func _update(_delta: float) -> void:
	if done: return
	for show_target in show_targets:
		if is_instance_valid(show_target) && !show_target.visible: show_target.show()
	done = true
