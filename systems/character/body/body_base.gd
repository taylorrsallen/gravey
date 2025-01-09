class_name BodyBase extends Node3D

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
signal body_changed()

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@export var body_id: int: set = _set_body_id
@export var body_data: BodyData: set = _set_body_data
@export var body_model: BodyModel

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _set_body_id(_body_id: int) -> void:
	body_id = _body_id
	body_data = Util.BODY_DATABASE.database[body_id]

func _set_body_data(_body_data: BodyData) -> void:
	body_data = _body_data
	
	if is_instance_valid(body_model): body_model.queue_free()
	body_model = body_data.body_model.instantiate()
	add_child(body_model)
	
	body_changed.emit()
