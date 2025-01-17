class_name Inventory extends Node

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
#@export var weapons: Array[int]
@export var ammo_stock: Array[int]

@export var weapons: Array[int]
@export var weapons_ammo: Array[int]
@export var weapons_fire_mode: Array[int]
@export var weapons_flashlight: Array[bool]
@export var max_weapons: int = 3
@export var active_weapon: int

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func init() -> void:
	if !is_multiplayer_authority(): return
	ammo_stock = []
	for i in Util.BULLET_DATABASE.database.size():
		ammo_stock.append(0)
	
	weapons = []
	for i in max_weapons:
		weapons.append(0)
		weapons_ammo.append(0)
		weapons_fire_mode.append(0)
		weapons_flashlight.append(false)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func drop_contents() -> void:
	pass
