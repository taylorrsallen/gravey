class_name HUD3D extends Node3D

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
# COMPOSITION
@onready var reticle: MeshInstance3D = $Reticle
@onready var radar: MeshInstance3D = $Radar
@onready var ammo_display: AmmoDisplay = $AmmoDisplay
@onready var health_display: AmmoDisplay = $HealthDisplay
@onready var shield_display: AmmoDisplay = $ShieldDisplay
@onready var interact_prompt: Label3D = $InteractPrompt
@onready var fire_mode_display: Node3D = $FireModeDisplay
@onready var ammo_stock_widget: Node3D = $AmmoStockWidget

@onready var ammo_stock_counter: Label3D = $AmmoStockWidget/AmmoStockCounter
@onready var ammo_stock_icon: AmmoRowMesh = $AmmoStockWidget/Node3D/AmmoStockIcon
@onready var ammo_stock_border: MeshInstance3D = $AmmoStockWidget/AmmoStockBorder

@onready var single_back: Label3D = $FireModeDisplay/SingleBack
@onready var single_front: Label3D = $FireModeDisplay/SingleBack/SingleFront
@onready var semi_auto_back: Label3D = $FireModeDisplay/SemiAutoBack
@onready var semi_auto_front: Label3D = $FireModeDisplay/SemiAutoBack/SemiAutoFront
@onready var full_auto_back: Label3D = $FireModeDisplay/FullAutoBack
@onready var full_auto_front: Label3D = $FireModeDisplay/FullAutoBack/FullAutoFront

@onready var inventory_icon_0: MeshInstance3D = $WeaponSelection/InventoryIcon0
@onready var inventory_icon_1: MeshInstance3D = $WeaponSelection/InventoryIcon1
@onready var inventory_icon_2: MeshInstance3D = $WeaponSelection/InventoryIcon2

@onready var inventory_icons: Array[MeshInstance3D] = [inventory_icon_0, inventory_icon_1, inventory_icon_2]

@onready var inventory_icon_text_back_0: Label3D = $WeaponSelection/InventoryIcon0/InventoryIconTextBack0
@onready var inventory_icon_text_front_0: Label3D = $WeaponSelection/InventoryIcon0/InventoryIconTextBack0/InventoryIconTextFront0
@onready var inventory_icon_text_back_1: Label3D = $WeaponSelection/InventoryIcon1/InventoryIconTextBack1
@onready var inventory_icon_text_front_1: Label3D = $WeaponSelection/InventoryIcon1/InventoryIconTextBack1/InventoryIconTextFront1
@onready var inventory_icon_text_back_2: Label3D = $WeaponSelection/InventoryIcon2/InventoryIconTextBack2
@onready var inventory_icon_text_front_2: Label3D = $WeaponSelection/InventoryIcon2/InventoryIconTextBack2/InventoryIconTextFront2

@onready var points_counter_back: Label3D = $PointsCounterBack
@onready var points_counter_front: Label3D = $PointsCounterBack/PointsCounterFront

@onready var wave_counter_back: Label3D = $WaveCounterBack
@onready var wave_counter_front: Label3D = $WaveCounterBack/WaveCounterFront

@onready var text_foreground_elements: Array[Label3D] = [single_front, semi_auto_front, full_auto_front, ammo_stock_counter, interact_prompt, inventory_icon_text_front_0, inventory_icon_text_front_1, inventory_icon_text_front_2, points_counter_front, wave_counter_front]
@onready var text_background_elements: Array[Label3D] = [single_back, semi_auto_back, full_auto_back, inventory_icon_text_back_0, inventory_icon_text_back_1, inventory_icon_text_back_2, points_counter_back, wave_counter_back]

@export var primary_color_set: ColorSet
@export var secondary_color_set: ColorSet
@export var empty_inventory_icon: Texture2D

@onready var power_brick_icon: MeshInstance3D = $PowerBrickIcon

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _physics_process(delta: float) -> void:
	primary_color_set.update(delta)
	secondary_color_set.update(delta)
	
	reticle.get_surface_override_material(0).albedo_color = primary_color_set.get_primary()
	
	shield_display.live_ammo_color = primary_color_set.get_primary()
	shield_display.background_ammo_color = primary_color_set.get_background()
	health_display.live_ammo_color = secondary_color_set.get_primary()
	health_display.background_ammo_color = secondary_color_set.get_background()
	
	radar.get_surface_override_material(0).albedo_color = primary_color_set.get_secondary()
	
	ammo_stock_icon.get_surface_override_material(0).albedo_color = primary_color_set.get_primary()
	ammo_stock_border.get_surface_override_material(0).albedo_color = primary_color_set.get_primary()
	ammo_display.live_ammo_color = primary_color_set.get_primary()
	ammo_display.background_ammo_color = primary_color_set.get_background()
	
	inventory_icon_0.get_surface_override_material(0).albedo_color = primary_color_set.get_primary()
	inventory_icon_1.get_surface_override_material(0).albedo_color = primary_color_set.get_primary()
	inventory_icon_2.get_surface_override_material(0).albedo_color = primary_color_set.get_primary()
	
	for i in text_background_elements.size():
		text_foreground_elements[i].modulate = primary_color_set.get_primary()
		text_foreground_elements[i].modulate.a8 = 100
		text_background_elements[i].modulate = primary_color_set.get_background()
		text_background_elements[i].modulate.a8 = 100

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func set_points(points: int) -> void:
	points_counter_back.text = str(points) + " ₽"
	points_counter_front.text = str(points) + " ₽"

func spawn_points_widget(points: int) -> void:
	pass

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func set_inventory_slot(slot: int, gun_data_id: int) -> void:
	if gun_data_id == 0:
		inventory_icons[slot].get_surface_override_material(0).albedo_texture = empty_inventory_icon
		return
	
	var gun_data: GunData = Util.GUN_DATABASE.database[gun_data_id - 1]
	inventory_icons[slot].get_surface_override_material(0).albedo_texture = gun_data.hud_icon

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func damage() -> void:
	var d_primary: Color = Color(randf(), randf(), randf())
	var d_secondary: Color = Color(randf(), randf(), randf())
	var d_tertiary: Color = Color(randf(), randf(), randf())
	var d_background: Color = Color(randf(), randf(), randf())
	
	primary_color_set._current_primary = d_primary
	primary_color_set._current_secondary = d_secondary
	primary_color_set._current_tertiary = d_tertiary
	primary_color_set._current_background = d_background.lerp(Color.BLACK, 0.5)
	
	secondary_color_set._current_primary = d_primary
	secondary_color_set._current_secondary = d_secondary
	secondary_color_set._current_tertiary = d_tertiary
	secondary_color_set._current_background = d_background.lerp(Color.BLACK, 0.5)

func update_reticle(camera_rig: CameraRig, character: Character) -> void:
	if reticle.get_surface_override_material(0).albedo_texture != character.gun_base.data.reticle:
		reticle.get_surface_override_material(0).albedo_texture = character.gun_base.data.reticle
	
	var recoil_distance_mod: float = character.gun_barrel_angular_recoil_modifier.dot(Vector3.ZERO) * 8.0 + character.gun_barrel_position_recoil_modifier.length() * 7.0
	
	var reticle_target: Vector3 = character.gun_base.global_position - character.gun_base.global_basis.z * 100.0
	var space_state: PhysicsDirectSpaceState3D = character.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(character.gun_base.global_position, character.gun_base.global_position - character.gun_base.global_basis.z * 100.0, 3, [character.get_rid()])
	var result: Dictionary = space_state.intersect_ray(query)
	if !result.is_empty(): reticle_target = result["position"]
	var reticle_direction_from_camera: Vector3 = (reticle_target - camera_rig.camera_3d.global_position).normalized()
	
	reticle.global_position = camera_rig.camera_3d.global_position + reticle_direction_from_camera * (10.0 - recoil_distance_mod - character.gun_base.data.spread_degrees)
	reticle.global_basis = character.gun_base.global_basis
	#print(character.gun_barrel_angular_recoil_modifier)
	#print(character.gun_barrel_angular_recoil_modifier.dot(Vector3.ZERO))
	#print(reticle.global_position.distance_to(camera_rig.camera_3d.global_position))

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func set_ammo_stock_count(ammo: int) -> void:
	ammo_stock_counter.text = "x " + str(ammo)

func set_ammo_stock_icon(icon: Texture2D) -> void:
	ammo_stock_icon.get_surface_override_material(0).albedo_texture = icon
	ammo_stock_icon.mesh.size.x = icon.get_size().x * 0.01
	ammo_stock_icon.mesh.size.y = icon.get_size().y * 0.01

func set_fire_mode_displayed(fire_mode: GunData.FireMode) -> void:
	match fire_mode:
		GunData.FireMode.SEMI_AUTO:
			single_front.hide()
			semi_auto_front.show()
			full_auto_front.hide()
		GunData.FireMode.FULL_AUTO:
			single_front.hide()
			semi_auto_front.hide()
			full_auto_front.show()
		_:
			single_front.show()
			semi_auto_front.hide()
			full_auto_front.hide()

func set_available_fire_modes_displayed(fire_modes: Array[GunData.FireMode]) -> void:
	single_front.hide()
	single_back.hide()
	semi_auto_front.hide()
	semi_auto_back.hide()
	full_auto_front.hide()
	full_auto_back.hide()
	for fire_mode in fire_modes:
		match fire_mode:
			GunData.FireMode.SEMI_AUTO: semi_auto_back.show()
			GunData.FireMode.FULL_AUTO: full_auto_back.show()
			_: single_back.show()
