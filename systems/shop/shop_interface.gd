class_name ShopInterface extends Control

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
const SHOP_ITEM_DISPLAY: PackedScene = preload("res://systems/shop/shop_item_display.scn")

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
# DATA
@export var shop: Shop

@export var active_category: int = 1: set = _set_active_category

# COMPOSITION
@onready var category_vessels: Button = $InterfacePanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/CategoriesVBoxContainer/CategoryVessels
@onready var category_guns: Button = $InterfacePanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/CategoriesVBoxContainer/CategoryGuns
@onready var category_ammo: Button = $InterfacePanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/CategoriesVBoxContainer/CategoryAmmo
@onready var category_items: Button = $InterfacePanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/CategoriesVBoxContainer/CategoryItems

@onready var catalog_v_box_container: VBoxContainer = $InterfacePanelContainer/MarginContainer/VBoxContainer/HBoxContainer/CatalogPanelContainer/MarginContainer/ScrollContainer/CatalogVBoxContainer
@onready var cart_v_box_container: VBoxContainer = $InterfacePanelContainer/MarginContainer/VBoxContainer/HBoxContainer/CartPanelContainer/MarginContainer/VBoxContainer/PanelContainer/ScrollContainer/CartVBoxContainer

@onready var vessel_icon: TextureRect = $InterfacePanelContainer/MarginContainer/VBoxContainer/HBoxContainer/CartPanelContainer/MarginContainer/VBoxContainer/PanelContainer2/HBoxContainer/VesselIcon
@onready var vessel_name: Label = $InterfacePanelContainer/MarginContainer/VBoxContainer/HBoxContainer/CartPanelContainer/MarginContainer/VBoxContainer/PanelContainer2/HBoxContainer/VesselName
@onready var vessel_cost: Label = $InterfacePanelContainer/MarginContainer/VBoxContainer/HBoxContainer/CartPanelContainer/MarginContainer/VBoxContainer/PanelContainer2/HBoxContainer/VesselCost

@onready var cart_cost_to_funds_header: Label = $InterfacePanelContainer/MarginContainer/VBoxContainer/HBoxContainer/CartPanelContainer/MarginContainer/VBoxContainer/HBoxContainer/CartCostToFundsHeader
@onready var cart_cost_label: Label = $InterfacePanelContainer/MarginContainer/VBoxContainer/HBoxContainer/CartPanelContainer/MarginContainer/VBoxContainer/HBoxContainer/CartCostLabel
@onready var cart_funds_label: Label = $InterfacePanelContainer/MarginContainer/VBoxContainer/HBoxContainer/CartPanelContainer/MarginContainer/VBoxContainer/HBoxContainer/CartFundsLabel
@onready var cart_buy: Button = $InterfacePanelContainer/MarginContainer/VBoxContainer/HBoxContainer/CartPanelContainer/MarginContainer/VBoxContainer/HBoxContainer/CartBuy

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _set_active_category(_active_category: int) -> void:
	active_category = _active_category
	
	for child in catalog_v_box_container.get_children(): child.free()
	
	match active_category:
		0: _refresh_vessel_category()
		1: _refresh_guns_category()
		2: _refresh_ammo_category()
		3: _refresh_items_category()

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _refresh_vessel_category() -> void:
	pass

func _refresh_guns_category() -> void:
	for i in Util.GUN_DATABASE.database.size(): _add_item_display_to_category(ShopItemData.ShopCategory.WEAPON, i + 1)

func _refresh_ammo_category() -> void:
	for i in Util.BULLET_DATABASE.database.size(): _add_item_display_to_category(ShopItemData.ShopCategory.AMMO, i)

func _refresh_items_category() -> void:
	for i in Util.ITEM_DATABASE.database.size(): _add_item_display_to_category(ShopItemData.ShopCategory.ITEM, i)

func _add_item_display_to_category(category: ShopItemData.ShopCategory, id: int) -> void:
	var shop_item_data: ShopItemData = ShopItemData.new()
	shop_item_data.category = category
	shop_item_data.id = id
	
	var shop_item_display: ShopItemDisplay = SHOP_ITEM_DISPLAY.instantiate()
	catalog_v_box_container.add_child(shop_item_display, true)
	shop_item_display.data = shop_item_data
	shop_item_display.pressed.connect(_add_item_to_cart)

func _add_item_to_cart(shop_item_data: ShopItemData, _index: int) -> void:
	shop.cart.append(shop_item_data)
	refresh_cart()

func _remove_item_from_cart(_shop_item_data: ShopItemData, index: int) -> void:
	shop.cart.remove_at(index)
	refresh_cart()

func refresh_cart():
	for child in cart_v_box_container.get_children(): child.queue_free()
	for i in shop.cart.size(): _add_item_display_to_cart(shop.cart[i], i)
	
	var total_cost: int = shop.get_cart_total_cost()
	var funds: int = shop.get_parent().points
	cart_cost_label.text = str(total_cost)
	cart_funds_label.text = str(funds)
	
	cart_buy.disabled = funds < total_cost

func _add_item_display_to_cart(shop_item_data: ShopItemData, index: int) -> void:
	var shop_item_display: ShopItemDisplay = SHOP_ITEM_DISPLAY.instantiate()
	cart_v_box_container.add_child(shop_item_display, true)
	shop_item_display.data = shop_item_data
	shop_item_display.index = index
	shop_item_display.pressed.connect(_remove_item_from_cart)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func refresh() -> void:
	active_category = active_category
	refresh_cart()

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _on_vessels_pressed() -> void: active_category = 0
func _on_guns_pressed() -> void: active_category = 1
func _on_ammo_pressed() -> void: active_category = 2
func _on_items_pressed() -> void: active_category = 3

func _on_clear_cart_pressed() -> void:
	shop.clear_cart()
	refresh_cart()

func _on_cart_buy_pressed() -> void:
	shop.start_laser_designator()
