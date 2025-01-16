class_name SlidingDoor extends Node3D

@export var move_target: float = 1.0
@export var max_height: float = -2.0
@export var speed: float = 5.0

@export var door: Node3D
@export var obstacle: NavigationObstacle3D
@export var navigation_link_3d: NavigationLink3D

func _update(delta: float) -> void:
	if move_target == 1:
		navigation_link_3d.enabled = true
	else:
		navigation_link_3d.enabled = false
	
	if is_instance_valid(obstacle): obstacle.queue_free()
	
	if !is_instance_valid(door): return
	var target_position: Vector3 = Vector3.ZERO.lerp(Vector3.UP * max_height, move_target)
	door.position = door.position.move_toward(target_position, delta * speed)
