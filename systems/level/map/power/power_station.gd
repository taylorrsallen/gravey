class_name PowerStation extends Node3D

@export var powered: bool: set = _set_powered
@export var id: int

@onready var power_cell: Node3D = $grave_power_brick

func _set_powered(_powered: bool) -> void:
	powered = _powered
	if powered:
		power_cell.show()
		await get_tree().create_timer(1.0).timeout
		for child in get_children():
			if child is NavigationLink3D: child.enabled = true

func try_power(character: Character) -> void:
	if character.power < 100: return
	
	powered = true
	character.power = 0
	
	if !multiplayer.is_server():
		_rpc_power.rpc_id(1)
	# TODO: Do sound and VFX stuff

@rpc("any_peer", "call_remote")
func _rpc_power() -> void:
	powered = true
