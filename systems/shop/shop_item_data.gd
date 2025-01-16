class_name ShopItemData extends Resource

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
enum ShopCategory {
	WEAPON,
	AMMO,
	ITEM,
}

@export var category: ShopCategory
@export var id: int
