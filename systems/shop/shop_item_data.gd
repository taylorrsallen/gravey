class_name ShopItemData extends Resource

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
enum ShopCategory {
	WEAPON,
	AMMO,
}

@export var category: ShopCategory
@export var id: int
