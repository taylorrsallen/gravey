class_name DeliveryDropVessel extends DeliveryVessel

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@export var contents: Array[ShopItemData]

@export var drop_speed_curve: Curve

@export var time_to_full_speed: float = 5.0
var time_since_drop: float

@export var fake_velocity: Vector3

@export var max_speed: float = 200.0

@export var launched: bool
@export var launch_delay: float = 10.0
@export var launch_timer: float

@onready var hud_beacon: Node3D = $HUDBeacon
@onready var hud_beacon_label: Label3D = $HUDBeacon/HUDBeaconLabel

@export var launch_sound_pool: SoundPoolData
@export var impact_sound_pool: SoundPoolData

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _ready() -> void:
	if is_multiplayer_authority(): launch_delay = randf_range(10.0, 20.0)

func _physics_process(delta: float) -> void:
	hud_beacon.global_position = delivery_target
	if launch_timer < launch_delay:
		hud_beacon_label.text = "T-" + str(launch_delay - launch_timer).left(4)
	else:
		hud_beacon_label.text = ">>> LAUNCHED <<<"
	
	if !is_multiplayer_authority(): return
	
	linear_velocity = Vector3.ZERO
	
	if !launched:
		launch_timer += delta
		if launch_timer >= launch_delay:
			launch()
		else:
			return
	
	time_since_drop += delta
	
	var percent_to_full_speed: float = clampf(time_since_drop, 0.0, time_to_full_speed) / time_to_full_speed
	var thrust_strength: float = drop_speed_curve.sample(percent_to_full_speed)
	global_position += fake_velocity * delta
	
	fake_velocity = fake_velocity.move_toward((delivery_target - global_position).normalized() * max_speed, delta * thrust_strength)
	
	if delivery_target.distance_to(global_position) < 5.0: land()

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func launch() -> void:
	launched = true
	_rpc_launch.rpc()
	angular_velocity = Vector3(randf_range(-20.0, 20.0), randf_range(-20.0, 20.0), randf_range(-20.0, 20.0))
	
	if launch_sound_pool:
		var sound: SoundReferenceData = launch_sound_pool.pool.pick_random()
		SoundManager.play_pitched_3d_sfx(sound.id, sound.type, global_position, 0.9, 1.1, sound.volume_db, 100.0)

@rpc("any_peer", "call_local", "reliable")
func _rpc_launch() -> void:
	show()

func land() -> void:
	global_position = delivery_target
	
	for shop_item_data in contents:
		var item_transform: Transform3D = Transform3D(
			Basis(Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized(), randf_range(0.0, 3.14)),
			global_position + Vector3(randf_range(-0.5, 0.5), randf_range(0.0, 0.5), randf_range(-0.5, 0.5)))
		var item_lin_vel: Vector3 = Vector3(randf_range(-5.0, 5.0), randf_range(3.0, 6.0), randf_range(-5.0, 5.0))
		var item_ang_vel: Vector3 = Vector3(randf_range(-6.0, 6.0), randf_range(-6.0, 6.0), randf_range(-6.0, 6.0))
		
		match shop_item_data.category:
			ShopItemData.ShopCategory.WEAPON:
				var gun_data: GunData = Util.GUN_DATABASE.database[shop_item_data.id - 1]
				SpawnManager.spawn_equippable(
					shop_item_data.id,
					{ "rounds" = gun_data.capacity, "fire_mode_index" = 0 },
					item_transform,
					item_lin_vel,
					item_ang_vel)
			ShopItemData.ShopCategory.AMMO:
				var bullet_data: BulletData = Util.BULLET_DATABASE.database[shop_item_data.id]
				SpawnManager.spawn_pickup(shop_item_data.id, { "ammo" = bullet_data.shop_ammo_box_quantity }, item_transform)
			ShopItemData.ShopCategory.ITEM:
				var item_data: ItemData = Util.ITEM_DATABASE.database[shop_item_data.id]
				var metadata: Dictionary = item_data.metadata.duplicate(true)
				metadata["item"] = 1
				SpawnManager.spawn_pickup(shop_item_data.id, metadata, item_transform)
	
	if impact_sound_pool:
		var sound: SoundReferenceData = impact_sound_pool.pool.pick_random()
		SoundManager.play_pitched_3d_sfx(sound.id, sound.type, global_position, 0.9, 1.1, sound.volume_db)
	VfxManager.spawn_vfx(8, global_position + Vector3.UP * 0.4, global_basis)
	
	queue_free()
