class_name ShopItemDisplay extends PanelContainer

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
signal pressed(data: ShopItemData, index: int)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
const SHOP_ITEM_DISPLAY_NORMAL = preload("res://resources/ui_themes/shop_item_display_normal.res")
const SHOP_ITEM_DISPLAY_HOVERED = preload("res://resources/ui_themes/shop_item_display_hovered.res")

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
# DATA
@export var data: ShopItemData: set = _set_data
@export var index: int

# COMPOSITION
@onready var icon_texture_rect: TextureRect = $HBoxContainer/IconTextureRect
@onready var name_label: Label = $HBoxContainer/NameLabel
@onready var price_label: Label = $HBoxContainer/PriceLabel

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _set_data(_data: ShopItemData) -> void:
	data = _data
	
	match data.category:
		ShopItemData.ShopCategory.WEAPON:
			var gun_data: GunData = Util.GUN_DATABASE.database[data.id - 1]
			set_display(gun_data.shop_icon, gun_data.name, gun_data.shop_point_cost)
		ShopItemData.ShopCategory.AMMO:
			var bullet_data: BulletData = Util.BULLET_DATABASE.database[data.id]
			set_display(bullet_data.shop_ammo_box_icon, bullet_data.shop_ammo_box_name, bullet_data.shop_ammo_box_point_cost)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func set_display(item_icon: Texture2D, item_name: String, item_cost: int) -> void:
	icon_texture_rect.texture = item_icon
	name_label.text = item_name
	price_label.text = str(item_cost) + " ₽ "

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _on_button_pressed() -> void: pressed.emit(data, index)
func _on_button_mouse_entered() -> void: self["theme_override_styles/panel"] = SHOP_ITEM_DISPLAY_HOVERED
func _on_button_mouse_exited() -> void: self["theme_override_styles/panel"] = SHOP_ITEM_DISPLAY_NORMAL
