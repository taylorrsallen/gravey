class_name PlayerController extends Node
## Owns and sends inputs to [Character] and [CameraRig]. Coordinates some game specific functionalities which are unique to players.

const CHARACTER: PackedScene = preload("res://systems/character/character.scn")

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
enum PlayerControllerFlag {
	CURSOR_VISIBLE,
	MENU_VISIBLE,
}

enum {
	CONTROL_KEYBOARD,
	CONTROL_SONY,
	CONTROL_NINTENDO,
	CONTROL_XBOX,
}

const CAMERA_RIG_SCN: PackedScene = preload("res://systems/camera/camera_rig.scn")
const SPLITSCREEN_VIEW_SCN: PackedScene = preload("res://systems/controller/player/splitscreen_view.scn")
const SHADER_VIEW_SCN: PackedScene = preload("res://systems/controller/player/shader_view.scn")


# (({[%%%(({[=======================================================================================================================]}))%%%]}))
# DATA
@export var local_id: int

# INPUT
var controls_assigned: int = -1
var device_assigned: int = -1

@export var move_input: Vector2
@export var raw_move_input: Vector3
@export var world_move_input: Vector3

# COMPOSITION
@export var character: Character
@export var camera_rig: CameraRig
@onready var label_3d: Label3D = $Label3D
@onready var owned_objects: Node = $OwnedObjects
@onready var owned_objects_spawner: MultiplayerSpawner = $OwnedObjects/MultiplayerSpawner
@onready var hud_3d: HUD3D = $HUD3D
@onready var multiplayer_spawner: MultiplayerSpawner = $OwnedObjects/MultiplayerSpawner
@onready var shop: Shop = $Shop
@onready var laser_pointer: Node3D = $LaserPointer

@onready var breathing_audio_stream_player: AudioStreamPlayer = $BreathingAudioStreamPlayer
@onready var heartbeat_audio_stream_player: AudioStreamPlayer = $HeartbeatAudioStreamPlayer
@onready var low_armor_audio_stream_player: AudioStreamPlayer = $LowArmorAudioStreamPlayer
@onready var low_shields_audio_stream_player: AudioStreamPlayer = $LowShieldsAudioStreamPlayer
@onready var mask_breathing_audio_stream_player: AudioStreamPlayer = $MaskBreathingAudioStreamPlayer

# VIEW
@onready var camera_view_layer: CanvasLayer = $CameraViewLayer
@export var splitscreen_view: SplitscreenView
@onready var shader_view_layer: CanvasLayer = $ShaderViewLayer
@export var shader_view: ShaderView
#@onready var menu_view: Control = $HUDViewLayer/MenuView

# FLAGS
@export var flags: int

# INTERACTABLE
@export var focused_equippable: EquippableBase
@export var desire_to_equip: float
@export var max_desire_to_equip: float = 0.4
@export var successfully_equipped_with_press: bool

@export var focused_interactable: InteractableBase

# GAME
@export var points: int
@export var respawn_time: float = 5.0
@export var respawn_timer: float

# SHOP
@export var laser_designating: bool
@export var laser_valid: bool
@export var laser_point: Vector3
@export var laser_length: float = 50.0
@export var laser_valid_color: Color
@export var laser_invalid_color: Color

# SOUNDS
@export var breathing_volume_target: float = -200.0
@export var heartbeat_volume_target: float = -200.0
@export var low_armor_volume_target: float = -200.0
@export var low_shield_volume_target: float = -200.0
@export var mask_breathing_volume_target: float = -200.0
@onready var pod_falling_audio_stream_player: AudioStreamPlayer = $PodFallingAudioStreamPlayer

# MULTIPLAYER
@export var player_name: String
@export var player_color: Color

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func is_flag_on(flag: PlayerControllerFlag) -> bool: return Util.is_flag_on(flags, flag)
func set_flag_on(flag: PlayerControllerFlag) -> void: flags = Util.set_flag_on(flags, flag)
func set_flag_off(flag: PlayerControllerFlag) -> void: flags = Util.set_flag_off(flags, flag)
func set_flag(flag: PlayerControllerFlag, active: bool) -> void: flags = Util.set_flag(flags, flag, active)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func init() -> void:
	spawn_character()
	spawn_camera_rig()
	if local_id == 0:
		assign_default_controls(0)
		set_cursor_captured()
	
	EventBus.game_ended.connect(_on_game_ended)
	EventBus.game_started.connect(_on_game_ended)

func _on_game_ended() -> void:
	points = 0

func _enter_tree() -> void:
	set_multiplayer_authority(get_parent().name.to_int())

func _ready() -> void:
	for vehicle_data in Util.VEHICLE_DATABASE.database:
		multiplayer_spawner.add_spawnable_scene(vehicle_data.scene.resource_path)
	
	if is_multiplayer_authority():
		init()
	else:
		hud_3d.hide()
		breathing_audio_stream_player.queue_free()
		heartbeat_audio_stream_player.queue_free()
		low_armor_audio_stream_player.queue_free()
		low_shields_audio_stream_player.queue_free()
		mask_breathing_audio_stream_player.queue_free()
	
	owned_objects_spawner.spawn_path = owned_objects.get_path()

func _physics_process(delta: float) -> void:
	if laser_designating:
		laser_pointer.show()
		if laser_valid:
			laser_pointer.get_child(0).get_surface_override_material(0).albedo_color = laser_valid_color
		else:
			laser_pointer.get_child(0).get_surface_override_material(0).albedo_color = laser_invalid_color
	else:
		laser_pointer.hide()
	
	if is_multiplayer_authority():
		if Input.is_action_just_pressed("start_" + str(local_id)):
			if shop.shop_interface.visible:
				shop.close_shop_interface()
				set_cursor_captured()
			else:
				toggle_cursor_visible()
		
		if shop.shop_interface.visible:
			if !is_flag_on(PlayerControllerFlag.CURSOR_VISIBLE): set_cursor_visible()
		
		if local_id == 0:
			if !get_window().has_focus():
				set_cursor_visible()
		
		_update_raw_inputs()
		if !is_flag_on(PlayerControllerFlag.CURSOR_VISIBLE): _update_camera_look(delta)
		
		if is_instance_valid(character):
			if character.dead:
				camera_rig.anchor_node = null
				character = null
				return
			
			character.world_move_input = world_move_input
			character.look_in_direction(camera_rig.camera_3d.global_basis, delta)
			
			character.physics_update(delta)
			
			_update_character_focused_interactable()
			_update_character_focused_interactable_action()
			_update_character_focused_equippable()
			_update_character_equip_action()
			_update_character_ik_targets(delta)
			_update_character_laser_pointer()
			_update_character_input(delta)
			_update_character_hud_3d(delta)
			_update_character_sounds(delta)
		else:
			camera_rig.update_first_person_position(1.0)
			
			shader_view.fade_to_black.modulate.a = clampf(respawn_timer * 0.5, 0.0, 1.0)
			
			respawn_timer += delta
			if respawn_timer >= respawn_time:
				spawn_character()
				_init_camera_rig()
	else:
		var _character: Character = null
		for child in owned_objects.get_children():
			if child is Character:
				_character = child
				break
		
		if is_instance_valid(_character) && !_character.dead:
			label_3d.show()
			label_3d.global_position = _character.global_position + Vector3.UP * 0.7
			if player_name != "":
				label_3d.text = player_name
			else:
				label_3d.text = str(get_multiplayer_authority())
			
			label_3d.modulate = player_color * 5.0
			label_3d.modulate.a = 0.6
		else:
			label_3d.hide()

func _update_raw_inputs() -> void:
	move_input = Input.get_vector("move_left_" + str(local_id), "move_right_" + str(local_id), "move_forward_" + str(local_id), "move_back_" + str(local_id))
	raw_move_input = Vector3(move_input.x, 1.0 if Input.is_action_pressed("jump_" + str(local_id)) else 0.0, move_input.y)
	world_move_input = camera_rig.get_yaw_local_vector3(raw_move_input)

func _update_camera_look(delta: float) -> void:
	var look_movement: Vector2 = Vector2.ZERO
	if local_id == 0:
		var cursor_movement: Vector2 = (get_viewport().size * 0.5).floor() - get_viewport().get_mouse_position()
		get_viewport().warp_mouse((get_viewport().size * 0.5).floor())
		look_movement += cursor_movement
	
	#var gamepad_look_input: Vector2 = Input.get_vector("look_left_" + str(local_id), "look_right_" + str(local_id), "look_down_" + str(local_id), "look_up_" + str(local_id)) * 4.0 * camera_rig.gamepad_look_sensitivity
	#gamepad_look_input.x = -gamepad_look_input.x
	#look_movement += gamepad_look_input
	
	const camera_shake: float = 0.015
	if is_instance_valid(character) && is_instance_valid(character.vehicle) && character.vehicle is VehicleDropPod && character.vehicle.dropping:
		camera_rig.anchor_offset = camera_rig.camera_3d.global_basis.x * randf_range(-camera_shake, camera_shake) + camera_rig.camera_3d.global_basis.y * randf_range(-camera_shake, camera_shake)
	else:
		camera_rig.anchor_offset = Vector3.ZERO
	
	camera_rig.apply_inputs(raw_move_input, look_movement, delta)
	camera_rig.apply_camera_rotation()

func _update_character_focused_interactable() -> void:
	var space_state: PhysicsDirectSpaceState3D = character.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(character.global_position, character.global_position + camera_rig.get_camera_forward() * 1.5, 17)
	var result: Dictionary = space_state.intersect_ray(query)
	
	if result.is_empty() || !(result["collider"] is InteractableBase):
		focused_interactable = null
		return
	
	var collider: Node3D = result["collider"]
	if collider.get_parent() is VehicleBase && collider.get_parent() != character.vehicle && !collider.get_parent().full:
		focused_interactable = result["collider"]
	elif collider.get_parent() is PowerStation && !collider.get_parent().powered:
		focused_interactable = result["collider"]
	else:
		focused_interactable = null

func _update_character_focused_interactable_action() -> void:
	if laser_designating: return
	
	if Input.is_action_just_pressed("equip_" + str(local_id)):
		if is_instance_valid(character.vehicle) && character.vehicle.can_exit:
			character.exit_vehicle()
		else:
			if !is_instance_valid(focused_interactable): return
			if focused_interactable.get_parent() is VehicleBase:
				var vehicle: VehicleBase = Util.VEHICLE_DATABASE.database[focused_interactable.get_parent().id].scene.instantiate()
				vehicle.transform = focused_interactable.get_parent().global_transform
				vehicle.metadata = focused_interactable.get_parent().metadata.duplicate(true)
				vehicle.drop_target = focused_interactable.get_parent().drop_target
				owned_objects.add_child(vehicle, true)
				character.board_vehicle(vehicle)
				focused_interactable.get_parent().destroy()
			elif focused_interactable.get_parent() is PowerStation:
				focused_interactable.get_parent().try_power(character)

func _update_character_focused_equippable() -> void:
	var results: Array[PhysicsBody3D] = AreaQueryManager.query_area(character.global_position, 1.8, 8)
	if results.is_empty():
		focused_equippable = null
		return
	
	var closest_result: PhysicsBody3D = null
	var closest_distance: float = 10.0
	for result in results:
		if result is PickupBase:
			result.pickup(character)
			continue
		
		var distance: float = character.global_position.distance_to(result.global_position)
		if distance >= closest_distance: continue
		closest_result = result
		closest_distance = distance
	
	if !closest_result:
		focused_equippable = null
		return
	
	focused_equippable = closest_result

func _update_character_equip_action() -> void:
	if !is_instance_valid(focused_equippable) || desire_to_equip != max_desire_to_equip || successfully_equipped_with_press: return
	if laser_designating: return
	desire_to_equip = 0.0
	character.equip(focused_equippable)
	focused_equippable = null
	successfully_equipped_with_press = true

func _update_character_hud_3d(delta: float) -> void:
	if character.health < character.max_health * 0.5:
		hud_3d.hide()
	else:
		hud_3d.show()
	
	if Util.main.main_menu.visible:
		hud_3d.hide()
	
	if Util.main.wave_manager.current_wave == 0:
		hud_3d.wave_counter_back.hide()
	else:
		hud_3d.wave_counter_back.show()
		hud_3d.wave_counter_back.text = "Wave " + str(Util.main.wave_manager.current_wave)
		hud_3d.wave_counter_front.text = "Wave " + str(Util.main.wave_manager.current_wave)
	
	if character.power >= 100:
		hud_3d.power_brick_icon.show()
	else:
		hud_3d.power_brick_icon.hide()
	
	hud_3d.set_points(points)
	
	if is_instance_valid(character.vehicle):
		camera_rig.update_first_person_position(1.0)
		hud_3d.global_position = camera_rig.camera_3d.global_position
	else:
		hud_3d.global_position = camera_rig.camera_3d.global_position
		camera_rig.update_first_person_position(1.0)
	
	hud_3d.health_display.ammo = character.health
	hud_3d.shield_display.ammo = character.shields
	
	hud_3d.global_basis = camera_rig.camera_3d.global_basis
	
	if character.gun_base.data:
		hud_3d.update_reticle(camera_rig, character)
		hud_3d.ammo_display.ammo = character.gun_base.rounds
		hud_3d.set_ammo_stock_count(character.inventory.ammo_stock[character.gun_base.data.bullet_id])
	else:
		hud_3d.ammo_display.ammo = 0
	
	if laser_designating:
		hud_3d.interact_prompt.show()
		if laser_valid:
			hud_3d.interact_prompt.text = "Press E to call in order"
		else:
			hud_3d.interact_prompt.text = "NO CLEARANCE"
	elif is_instance_valid(focused_interactable):
		if focused_interactable.get_parent() is VehicleBase:
			hud_3d.interact_prompt.text = "Press E to get in " + "ERROR_VEHICLE_NOT_FOUND"
			hud_3d.interact_prompt.show()
		elif focused_interactable.get_parent() is PowerStation:
			if character.power >= 100:
				hud_3d.interact_prompt.text = "Press E to place power brick"
				hud_3d.interact_prompt.show()
			else:
				hud_3d.interact_prompt.text = "Need power brick"
				hud_3d.interact_prompt.show()
		else:
			hud_3d.interact_prompt.hide()
	elif is_instance_valid(focused_equippable):
		var gun_data: GunData = Util.GUN_DATABASE.database[focused_equippable.gun_data_id - 1]
		hud_3d.interact_prompt.text = "Hold E to equip " + gun_data.name
		hud_3d.interact_prompt.show()
	else:
		hud_3d.interact_prompt.hide()
	
	hud_3d.radar.update_display(camera_rig, character, delta)

func _update_character_ik_targets(delta: float) -> void:
	var hold_offset: Vector3 = character.get_weapon_hold_offset()
	character.set_gun_barrel_aim(camera_rig.camera_3d.global_basis, hold_offset)
	
	#print(character.gun_barrel_position_target.distance_to(character.body_base.body_model.r_shoulder_bone_attachment_3d.global_position))
	
	var space_state: PhysicsDirectSpaceState3D = character.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(camera_rig.camera_3d.global_position, camera_rig.camera_3d.global_position + camera_rig.get_camera_forward() * 100.0, 5, character.body_base.body_model.damageable_area_rids)
	var result: Dictionary = space_state.intersect_ray(query)
	
	if !result.is_empty():
		character.gun_barrel_look_target = result["position"]
	else:
		character.gun_barrel_look_target = camera_rig.camera_3d.global_position + camera_rig.get_camera_forward() * 100.0
	
	if is_instance_valid(character.vehicle):
		character.face_direction(-character.vehicle.seat.global_basis.z, delta)
	else:
		character.face_direction(camera_rig.get_yaw_forward(), delta)

func _update_character_laser_pointer() -> void:
	if !laser_designating: return
	
	var space_state: PhysicsDirectSpaceState3D = character.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(character.gun_barrel_ik_target.global_position, character.gun_barrel_ik_target.global_position - character.gun_barrel_ik_target.global_basis.z * laser_length, 5, character.body_base.body_model.damageable_area_rids)
	var result: Dictionary = space_state.intersect_ray(query)
	
	laser_pointer.global_transform = character.gun_barrel_ik_target.global_transform
	laser_pointer.scale = Vector3.ONE
	if result.is_empty() || character.global_position.y > 900.0:
		laser_pointer.scale.z = 50.0
		laser_valid = false
	else:
		laser_pointer.scale.z = (character.gun_barrel_ik_target.global_position - result["position"]).length()
		laser_point = result["position"]
		
		var up_query = PhysicsRayQueryParameters3D.create(laser_point + Vector3.UP * 0.5, laser_point + Vector3.UP * 100.0, 1)
		var up_result: Dictionary = space_state.intersect_ray(up_query)
		
		laser_valid = up_result.is_empty()

func _update_character_input(delta: float) -> void:
	if Input.is_action_just_pressed("1_" + str(local_id)):
		laser_designating = false
		character.switch_weapon(0)
	elif Input.is_action_just_pressed("2_" + str(local_id)):
		laser_designating = false
		character.switch_weapon(1)
	elif Input.is_action_just_pressed("3_" + str(local_id)):
		laser_designating = false
		character.switch_weapon(2)
	
	if Input.is_action_just_pressed("inventory_" + str(local_id)):
		laser_designating = false
		if shop.shop_interface.visible:
			shop.close_shop_interface()
			set_cursor_captured()
		else:
			shop.open_shop_interface()
	
	if Input.is_action_just_pressed("melee_" + str(local_id)):
		laser_designating = false
		character.melee()
	if Input.is_action_just_pressed("reload_" + str(local_id)):
		laser_designating = false
		character.try_reload()
	if Input.is_action_just_pressed("drop_" + str(local_id)):
		laser_designating = false
		character.drop_weapon(camera_rig.get_yaw_forward() * 2.0, Vector3(randf_range(-5.0, 5.0), randf_range(-5.0, 5.0), randf_range(-5.0, 5.0)))
	
	if Input.is_action_pressed("equip_" + str(local_id)):
		if laser_designating:
			if shop.try_place_order(laser_point, laser_valid): laser_designating = false
		else:
			desire_to_equip = clampf(desire_to_equip + delta, 0.0, max_desire_to_equip)
	else:
		successfully_equipped_with_press = false
		desire_to_equip = 0.0
	
	if Input.is_action_pressed("sprint_" + str(local_id)):
		character.set_sprinting(true)
	else:
		character.set_sprinting(false)
	
	if !is_flag_on(PlayerControllerFlag.CURSOR_VISIBLE):
		if Input.is_action_pressed("primary_" + str(local_id)):
			laser_designating = false
			character.try_fire_held_press(local_id, delta)
		if Input.is_action_just_pressed("primary_" + str(local_id)):
			laser_designating = false
			character.try_fire_single_press(local_id, delta)
	
	if Input.is_action_just_pressed("fire_mode_toggle_" + str(local_id)):
		laser_designating = false
		character.gun_base.cycle_fire_mode()
		hud_3d.set_fire_mode_displayed(character.gun_base.get_fire_mode())
	
	if Input.is_action_just_pressed("flashlight_" + str(local_id)):
		character.toggle_flashlight()

func _update_character_sounds(delta: float) -> void:
	if character.global_position.y < 900.0:
		if !SoundManager.get_background_track(0):
			SoundManager.play_background_track(0, SoundDatabase.SoundType.BGT_WIND, 0)
	
	if character.health > character.max_health * 0.5:
		breathing_volume_target = -80.0
		heartbeat_volume_target = -80.0
		mask_breathing_volume_target = -15.0
		low_armor_volume_target = -80.0
	else:
		breathing_volume_target = 0.0
		heartbeat_volume_target = -12.0
		mask_breathing_volume_target = -80.0
		low_armor_volume_target = -5.0
	
	if character.max_shields == 0:
		low_shield_volume_target = -80.0
	elif character.shields <= 0:
		low_shield_volume_target = 0.0
	else:
		low_shield_volume_target = -80.0
	
	breathing_audio_stream_player.volume_db = move_toward(breathing_audio_stream_player.volume_db, breathing_volume_target, delta * 200.0)
	heartbeat_audio_stream_player.volume_db = move_toward(heartbeat_audio_stream_player.volume_db, heartbeat_volume_target, delta * 200.0)
	low_armor_audio_stream_player.volume_db = move_toward(low_armor_audio_stream_player.volume_db, low_armor_volume_target, delta * 200.0)
	low_shields_audio_stream_player.volume_db = move_toward(low_shields_audio_stream_player.volume_db, low_shield_volume_target, delta * 200.0)
	mask_breathing_audio_stream_player.volume_db = move_toward(mask_breathing_audio_stream_player.volume_db, mask_breathing_volume_target, delta * 200.0)
	
	if is_instance_valid(character.vehicle) && character.vehicle is VehicleDropPod && character.vehicle.dropping:
		if !pod_falling_audio_stream_player.playing: pod_falling_audio_stream_player.play()
	else:
		pod_falling_audio_stream_player.stop()

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func spawn_character() -> void:
	if !is_multiplayer_authority(): return
	
	if is_instance_valid(shader_view): shader_view.fade_to_black.modulate.a = 0.0
	respawn_timer = 0.0
	
	character = CHARACTER.instantiate()
	
	var valid_lobby_spawns: Array[LobbySpawn] = []
	for lobby_spawn in Util.main.lobby_spawns.get_children():
		if lobby_spawn.is_valid_spawn(): valid_lobby_spawns.append(lobby_spawn)
	var lobby_spawn: LobbySpawn = valid_lobby_spawns.pick_random()
	character.position = lobby_spawn.global_position
	
	character.weapon_changed.connect(_on_character_weapon_changed)
	character.damaged.connect(_on_character_damaged)
	
	character.controller = self
	owned_objects.add_child(character, true)
	character.set_body_id(0)
	character.body_base.body_model.head_bone_attachment.hide()
	character.body_base.body_model.l_shoulder_bone_attachment_3d.hide()
	character.body_base.body_model.r_shoulder_bone_attachment_3d.hide()
	
	#character.body_base.hide()
	character.gun_base.data_id = 1
	character.inventory.ammo_stock[0] = 128
	character.set_active_inventory_slot_weapon()
	
	character.apply_force(Vector3.UP * 800.0)
	
	_on_character_weapon_changed()
	
	character.killed.connect(_on_character_killed)

func _on_character_weapon_changed() -> void:
	if character.gun_base.data_id == 0:
		hud_3d.fire_mode_display.hide()
		hud_3d.ammo_stock_widget.hide()
		hud_3d.reticle.hide()
	else:
		hud_3d.fire_mode_display.show()
		hud_3d.ammo_stock_widget.show()
		hud_3d.reticle.show()
		
		var bullet_data: BulletData = Util.BULLET_DATABASE.database[character.gun_base.data.bullet_id]
		
		hud_3d.ammo_display.max_ammo = character.gun_base.data.capacity
		hud_3d.ammo_display.ammo_per_row = character.gun_base.data.ammo_per_row
		hud_3d.ammo_display.bullet_icon = bullet_data.icon
		hud_3d.ammo_display.regenerate_ammo_meshes()
		hud_3d.ammo_display.ammo = character.gun_base.rounds
		hud_3d.set_ammo_stock_icon(bullet_data.icon)
		hud_3d.set_available_fire_modes_displayed(character.gun_base.data.fire_modes)
		hud_3d.set_fire_mode_displayed(character.gun_base.get_fire_mode())
	
	for i in character.inventory.max_weapons:
		hud_3d.set_inventory_slot(i, character.inventory.weapons[i])

func _on_character_damaged() -> void:
	hud_3d.damage()

func _on_character_killed(_character: Character) -> void:
	camera_rig.anchor_position = _character.global_position + Vector3.UP * 3.0

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
# CURSOR
func toggle_cursor_visible() -> void:
	if !is_flag_on(PlayerControllerFlag.CURSOR_VISIBLE):
		set_cursor_visible()
	else:
		set_cursor_captured()

func set_cursor_visible() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	set_flag_on(PlayerControllerFlag.CURSOR_VISIBLE)

func set_cursor_captured() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
	if is_flag_on(PlayerControllerFlag.CURSOR_VISIBLE):
		get_viewport().warp_mouse(get_viewport().size * 0.5)
		set_flag_off(PlayerControllerFlag.CURSOR_VISIBLE)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
# SPLITSCREEN
func update_splitscreen_view(player_count: int, horizontal: bool = true) -> void:
	match player_count:
		1: _set_view_anchors()
		2: _update_2_player_splitscreen_view(horizontal)
		3: _update_3_player_splitscreen_view(horizontal)
		4: _update_4_player_splitscreen_view()
		_: pass

# ------------------------------------------------------------------------------------------------
# PRIVATE SPLITSCREEN
func _set_view_anchors(left: float = 0.0, right: float = 1.0, bottom: float = 1.0, top: float = 0.0) -> void:
	_set_control_view_anchors(splitscreen_view, left, right, bottom, top)
	_set_control_view_anchors(shader_view, left, right, bottom, top)
	#_set_control_view_anchors(hud_view, left, right, bottom, top)
	#_set_control_view_anchors(gui_3d_view, left, right, bottom, top)

func _set_control_view_anchors(control: Control, left: float = 0.0, right: float = 1.0, bottom: float = 1.0, top: float = 0.0) -> void:
	control.anchor_left = left
	control.anchor_top = top
	control.anchor_right = right
	control.anchor_bottom = bottom

func _update_2_player_splitscreen_view(horizontal: bool) -> void:
	if local_id == 0:
		if horizontal:
			_set_view_anchors(0.0, 1.0, 0.5, 0.0)
		else:
			_set_view_anchors(0.0, 0.5, 1.0, 0.0)
	else:
		if horizontal:
			_set_view_anchors(0.0, 1.0, 1.0, 0.5)
		else:
			_set_view_anchors(0.5, 1.0, 1.0, 0.0)

func _update_3_player_splitscreen_view(horizontal: bool) -> void:
	match local_id:
		0:
			if horizontal:
				_set_view_anchors(0.0, 1.0, 0.5, 0.0)
			else:
				_set_view_anchors(0.0, 0.5, 1.0, 0.0)
		1:
			if horizontal:
				_set_view_anchors(0.0, 0.5, 1.0, 0.5)
			else:
				_set_view_anchors(0.5, 1.0, 0.5, 0.0)
		2: _set_view_anchors(0.5, 1.0, 1.0, 0.5)

func _update_4_player_splitscreen_view() -> void:
	match local_id:
		0: _set_view_anchors(0.0, 0.5, 0.5, 0.0)
		1: _set_view_anchors(0.5, 1.0, 0.5, 0.0)
		2: _set_view_anchors(0.0, 0.5, 1.0, 0.5)
		3: _set_view_anchors(0.5, 1.0, 1.0, 0.5)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
# CAMERA
func _init_camera_rig() -> void:
	if is_instance_valid(character):
		camera_rig.anchor_node = character.body_base.body_model.head_bone_attachment.get_node("EyeTarget")
		
		#if camera_rig.perspective == Perspective.FPS:
			#camera_rig.anchor_node = character.get_eye_target()
		#else:
			#camera_rig.anchor_node = character.camera_socket
		
		camera_rig.connect_animations(character)
	
	camera_rig.make_current()
	#camera_rig.zoom = 20.0
	#camera_rig.zoom = 2.675
	
	camera_rig.spring_arm_3d.position.x = 0.0
	
	for i in 4:
		if i == local_id: continue
		camera_rig.camera_3d.cull_mask &= ~(1 << (15 + i))

func set_camera_rig(_camera_rig: CameraRig) -> void:
	camera_rig = _camera_rig
	_init_camera_rig()

func spawn_camera_rig() -> void:
	splitscreen_view = SPLITSCREEN_VIEW_SCN.instantiate()
	
	# TOGGLE
	if !Util.main.debug: camera_view_layer.add_child(splitscreen_view)
	
	shader_view = SHADER_VIEW_SCN.instantiate()
	shader_view_layer.add_child(shader_view)
	
	camera_rig = CAMERA_RIG_SCN.instantiate()
	
	if !Util.main.debug:
		splitscreen_view.sub_viewport.add_child(camera_rig)
	else:
		camera_view_layer.add_child(camera_rig)
	
	_init_camera_rig()
	
	#if is_instance_valid(hud): hud.queue_free()
	#hud = HUD_GUI.instantiate()
	#hud_view.add_child(hud)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
# INPUT
func assign_default_controls(control_type: int, device: int = 0) -> void:
	PlayerController.assign_default_controls_by_id(local_id, control_type, device)
	controls_assigned = control_type
	device_assigned = device

static func assign_default_controls_by_id(player_id: int, control_type: int, device: int = 0) -> void:
	match control_type:
		0: _assign_default_keyboard_controls(player_id)
		1: _assign_default_gamepad_sony_controls(player_id, device)
		2: _assign_default_gamepad_nintendo_controls(player_id, device)
		3: _assign_default_gamepad_xbox_controls(player_id, device)

# ------------------------------------------------------------------------------------------------
# PRIVATE INPUT

# HELPERS
static func _assign_key_action_event(player_id: int, action: String, keycode: Key) -> void:
	var input_event_key: InputEventKey = InputEventKey.new()
	input_event_key.keycode = keycode
	InputMap.action_erase_events(action + "_" + str(player_id))
	InputMap.action_add_event(action + "_" + str(player_id), input_event_key)

static func _assign_mouse_button_action_event(player_id: int, action: String, button: MouseButton) -> void:
	var input_event_mouse_button: InputEventMouseButton = InputEventMouseButton.new()
	input_event_mouse_button.button_index = button
	InputMap.action_erase_events(action + "_" + str(player_id))
	InputMap.action_add_event(action + "_" + str(player_id), input_event_mouse_button)

static func _assign_gamepad_button_action_event(player_id: int, device: int, action: String, button: JoyButton) -> void:
	var input_event_joypad_button: InputEventJoypadButton = InputEventJoypadButton.new()
	input_event_joypad_button.button_index = button
	input_event_joypad_button.device = device
	InputMap.action_erase_events(action + "_" + str(player_id))
	InputMap.action_add_event(action + "_" + str(player_id), input_event_joypad_button)

static func _assign_gamepad_motion_action_event(player_id: int, device: int, action: String, axis: JoyAxis, value: float) -> void:
	var input_event_joypad_motion: InputEventJoypadMotion = InputEventJoypadMotion.new()
	input_event_joypad_motion.axis = axis
	input_event_joypad_motion.axis_value = value
	input_event_joypad_motion.device = device
	InputMap.action_erase_events(action + "_" + str(player_id))
	InputMap.action_add_event(action + "_" + str(player_id), input_event_joypad_motion)

# DEFAULTS
static func _assign_default_keyboard_controls(player_id: int) -> void:
	## Move
	_assign_key_action_event(player_id, "move_left", KEY_A)
	_assign_key_action_event(player_id, "move_right", KEY_D)
	_assign_key_action_event(player_id, "move_back", KEY_S)
	_assign_key_action_event(player_id, "move_forward", KEY_W)
	
	## No look for KBM
	
	## Action inputs
	_assign_mouse_button_action_event(player_id, "primary", MOUSE_BUTTON_LEFT)
	_assign_mouse_button_action_event(player_id, "secondary", MOUSE_BUTTON_RIGHT)
	#_assign_mouse_button_action_event(player_id, "zoom_in", MOUSE_BUTTON_WHEEL_UP)
	#_assign_mouse_button_action_event(player_id, "zoom_out", MOUSE_BUTTON_WHEEL_DOWN)
	_assign_key_action_event(player_id, "inventory", KEY_TAB)
	_assign_key_action_event(player_id, "reload", KEY_R)
	_assign_key_action_event(player_id, "melee", KEY_V)
	_assign_key_action_event(player_id, "sprint", KEY_SHIFT)
	_assign_key_action_event(player_id, "fire_mode_toggle", KEY_T)
	_assign_key_action_event(player_id, "equip", KEY_E)
	_assign_key_action_event(player_id, "jump", KEY_SPACE)
	_assign_key_action_event(player_id, "drop", KEY_G)
	_assign_key_action_event(player_id, "flashlight", KEY_F)
	_assign_key_action_event(player_id, "1", KEY_1)
	_assign_key_action_event(player_id, "2", KEY_2)
	_assign_key_action_event(player_id, "3", KEY_3)
	_assign_key_action_event(player_id, "4", KEY_4)
	_assign_key_action_event(player_id, "5", KEY_5)
	#_assign_key_action_event(player_id, "sprint", KEY_SHIFT)
	#_assign_key_action_event(player_id, "interact", KEY_E)
	#_assign_key_action_event(player_id, "recipes", KEY_TAB)
	
	## Menu inputs
	_assign_key_action_event(player_id, "start", KEY_ESCAPE)

static func _assign_default_gamepad_axis_controls(player_id: int, device: int) -> void:
	_assign_gamepad_motion_action_event(player_id, device, "move_left", JOY_AXIS_LEFT_X, -1.0)
	_assign_gamepad_motion_action_event(player_id, device, "move_right", JOY_AXIS_LEFT_X, 1.0)
	_assign_gamepad_motion_action_event(player_id, device, "move_back", JOY_AXIS_LEFT_Y, 1.0)
	_assign_gamepad_motion_action_event(player_id, device, "move_forward", JOY_AXIS_LEFT_Y, -1.0)
	
	_assign_gamepad_motion_action_event(player_id, device, "look_left", JOY_AXIS_RIGHT_X, -1.0)
	_assign_gamepad_motion_action_event(player_id, device, "look_right", JOY_AXIS_RIGHT_X, 1.0)
	_assign_gamepad_motion_action_event(player_id, device, "look_down", JOY_AXIS_RIGHT_Y, 1.0)
	_assign_gamepad_motion_action_event(player_id, device, "look_up", JOY_AXIS_RIGHT_Y, -1.0)

static func _assign_default_gamepad_common_controls(player_id: int, device: int) -> void:
	_assign_default_gamepad_axis_controls(player_id, device)
	
	_assign_gamepad_button_action_event(player_id, device, "zoom_in", JOY_BUTTON_DPAD_UP)
	_assign_gamepad_button_action_event(player_id, device, "zoom_out", JOY_BUTTON_DPAD_DOWN)
	#if player_id == 0: _assign_gamepad_button_action_event(player_id, device, "start", JOY_BUTTON_START)

static func _assign_default_gamepad_sony_controls(player_id: int, device: int) -> void:
	_assign_default_gamepad_common_controls(player_id, device)
	
	_assign_gamepad_button_action_event(player_id, device, "primary", JOY_BUTTON_A) # CROSS
	_assign_gamepad_button_action_event(player_id, device, "secondary", JOY_BUTTON_B) # CIRCLE
	_assign_gamepad_button_action_event(player_id, device, "sprint", JOY_BUTTON_RIGHT_SHOULDER)
	_assign_gamepad_button_action_event(player_id, device, "interact", JOY_BUTTON_X) # SQUARE
	_assign_gamepad_button_action_event(player_id, device, "recipes", JOY_BUTTON_LEFT_SHOULDER)
	
	#_assign_gamepad_button_action_event(player_id, device, "primary", JOY_BUTTON_Y) # TRIANGLE

static func _assign_default_gamepad_nintendo_controls(player_id: int, device: int) -> void:
	_assign_default_gamepad_common_controls(player_id, device)
	
	_assign_gamepad_button_action_event(player_id, device, "primary", JOY_BUTTON_X) # A
	_assign_gamepad_button_action_event(player_id, device, "secondary", JOY_BUTTON_A) # B
	_assign_gamepad_button_action_event(player_id, device, "sprint", JOY_BUTTON_RIGHT_SHOULDER)
	_assign_gamepad_button_action_event(player_id, device, "interact", JOY_BUTTON_Y) # X
	_assign_gamepad_button_action_event(player_id, device, "recipes", JOY_BUTTON_LEFT_SHOULDER)

static func _assign_default_gamepad_xbox_controls(player_id: int, device: int) -> void:
	_assign_default_gamepad_common_controls(player_id, device)
	
	_assign_gamepad_button_action_event(player_id, device, "primary", JOY_BUTTON_A) # CROSS
	_assign_gamepad_button_action_event(player_id, device, "secondary", JOY_BUTTON_B) # CIRCLE
	_assign_gamepad_button_action_event(player_id, device, "sprint", JOY_BUTTON_RIGHT_SHOULDER)
	_assign_gamepad_button_action_event(player_id, device, "interact", JOY_BUTTON_X) # SQUARE
	_assign_gamepad_button_action_event(player_id, device, "recipes", JOY_BUTTON_LEFT_SHOULDER)
