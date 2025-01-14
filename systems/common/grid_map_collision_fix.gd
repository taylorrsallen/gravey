class_name GridMapCollisionFix extends GridMap

func _ready() -> void:
	var layer: int = collision_layer
	collision_layer = 0
	collision_layer = layer
