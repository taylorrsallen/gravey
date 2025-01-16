class_name Shop extends Node

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
const DELIVERY_DROP_VESSEL: PackedScene = preload("res://systems/shop/delivery_drop_vessel.scn")

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
# COMPOSITION
@onready var shop_interface: ShopInterface = $ShopInterface

# DATA
@export var cart: Array[ShopItemData] = []
@export var selected_vessel_cost: int = 40

# DELIVERY
@export var delivery_spawn_point: Vector3 = Vector3(0.0, 950.0, 0.0)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _ready() -> void:
	shop_interface.shop = self

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func try_place_order(laser_point: Vector3, laser_valid: bool) -> bool:
	if !laser_valid: return false
	
	get_parent().points -= get_cart_total_cost()
	
	var delivery_drop_vessel: DeliveryDropVessel = DELIVERY_DROP_VESSEL.instantiate()
	delivery_drop_vessel.delivery_target = laser_point
	delivery_drop_vessel.contents = cart.duplicate(true)
	delivery_drop_vessel.position = delivery_spawn_point
	get_parent().owned_objects.add_child(delivery_drop_vessel, true)
	
	return true

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func open_shop_interface() -> void:
	shop_interface.show()
	shop_interface.refresh()

func close_shop_interface() -> void:
	shop_interface.hide()

func toggle_shop_interface() -> void:
	if shop_interface.visible:
		close_shop_interface()
	else:
		open_shop_interface()

func clear_cart() -> void:
	cart = []

func get_cart_total_cost() -> int:
	var total_cost: int = selected_vessel_cost
	for i in cart.size():
		match cart[i].category:
			ShopItemData.ShopCategory.WEAPON:
				var gun_data: GunData = Util.GUN_DATABASE.database[cart[i].id - 1]
				total_cost += gun_data.shop_point_cost
			ShopItemData.ShopCategory.AMMO:
				var bullet_data: BulletData = Util.BULLET_DATABASE.database[cart[i].id]
				total_cost += bullet_data.shop_ammo_box_point_cost
			ShopItemData.ShopCategory.ITEM:
				var item_data: ItemData = Util.ITEM_DATABASE.database[cart[i].id]
				total_cost += item_data.shop_point_cost
	
	return total_cost

func start_laser_designator() -> void:
	get_parent().laser_designating = true
	close_shop_interface()
	get_parent().set_cursor_captured()
