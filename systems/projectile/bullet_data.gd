class_name BulletData extends Resource

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@export_category("Shop")
@export var shop_ammo_box_name: String
@export var shop_ammo_box_quantity: int
@export var shop_ammo_box_icon: Texture2D
@export var shop_ammo_box_point_cost: int

@export_category("Appearance")
@export var icon: Texture2D
@export var ammo_box_model: PackedScene
@export var bullet_model: PackedScene

@export_category("Gameplay")
@export var lifetime: float = 2.0
@export var speed: float = 10.0
@export var generic_hit_sound_pool: SoundPoolData

@export var damage_data: DamageData
