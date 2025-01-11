class_name IDButton extends Button

signal id_pressed()

@export var id: int = -1

func _on_pressed() -> void:
	id_pressed.emit(id)
