class_name BodyData extends Resource

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@export_category("Combat")
@export var stagger_threshold: float = 4.0
@export var max_health: float
@export var health_per_second: float
@export var max_shields: float
@export var shields_per_second: float

@export_category("Movement")
@export var weight: float = 1.0

@export_category("Model")
@export var body_model: PackedScene
