class_name Character extends RigidBody3D

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
signal spawned_on_peer(peer_id: int, character: Character)
signal jumped()
signal landed(force: float)
signal damaged()
signal killed(character: Character)

signal water_entered()
signal water_exited()

signal weapon_changed()

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
enum CharacterFlag {
	GROUNDED,
	WALK,
	SPRINT,
	CROUCH,
	TUMBLING,
	NOCLIP,
	WATER,
	UNDERWATER,
}

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
# COMPOSITION
@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D
@onready var nav_collider: CollisionShape3D = $NavCollider
@onready var body_container: Node3D = $BodyContainer
@onready var body_base: BodyBase = $BodyContainer/BodyBase

@onready var gun_barrel_ik_target: Marker3D = $GunBarrelIKTarget
@onready var l_hand_ik_target: Marker3D = $LHandIKTarget
@onready var r_hand_ik_target: Marker3D = $RHandIKTarget

@onready var gun_base: GunBase = $GunBarrelIKTarget/GunBase

@onready var shield_model: MeshInstance3D = $BodyContainer/ShieldModel

@onready var inventory: Inventory = $Inventory

@onready var shield_recharge_audio_player: AudioStreamPlayer3D = $ShieldRechargeAudioPlayer

# DATA
## There is supposed to be a base class that both PlayerController and AIController derive from, but I don't need it for this game, and I am LAZY!!!
@export var controller: PlayerController
@export var metadata: Dictionary

# FLAGS
@export var flags: int

# MOVEMENT
@export var max_ground_angle: float = 0.75

@export var ride_height: float = 1.22
@export var ride_spring_strength: float = 220.0
@export var ride_spring_damper: float = 20.0
@export var upright_rotation: Quaternion = Quaternion.IDENTITY
@export var upright_spring_strength: float = 25.0
@export var upright_spring_damper: float = 3.0

var look_basis: Basis
var look_direction: Vector3
var look_scalar: float

var move_input: Vector3
var world_move_input: Vector3
var desired_facing: Vector3
var move_direction: Vector3
@export var move_direction_lerp_speed: float = 10.0
@export var move_accel_lerp_speed: float = 3.0

@export var crouch_speed: float = 4.5
@export var walk_speed: float = 1.0
@export var jog_speed: float = 2.5
@export var sprint_speed: float = 8.0
var current_speed: float = walk_speed

@export var target_speed_multiplier: float = 1.0
@export var speed_multiplier: float
@export var speed_recharge_time: float = 1.5
@export var speed_recharge_timer: float

@export var jump_velocity: float = 4.5

var last_velocity: Vector3

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# VEHICLE
@export var vehicle: VehicleBase
@export var in_vehicle: bool

# AIMING
@export var breath: Vector3
@export var breath_timer: float
@export var gun_barrel_look_direction: Vector3
@export var gun_barrel_look_target: Vector3
@export var gun_barrel_position_target: Vector3
@export var gun_barrel_position_recoil_modifier: Vector3
@export var gun_barrel_angular_recoil_modifier: Vector3

@export var l_hand_ik_target_target: Vector3
@export var r_hand_ik_target_target: Vector3

# STATS
@export var max_health: float = 40.0
@export var health: float = max_health
@export var max_shields: float = 100.0
@export var shields = max_shields
@export var shield_recharged_per_second: float = 20.0
@export var shield_recharge_delay: float = 3.0
@export var shield_recharge_timer: float

@export var shields_down: bool
@export var shields_charging: bool

# MELEE
@export var melee_time: float = 0.5
@export var melee_timer: float

# DEATH
@export var dead: bool

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func is_flag_on(flag: CharacterFlag) -> bool: return Util.is_flag_on(flags, flag)
func set_flag_on(flag: CharacterFlag) -> void: flags = Util.set_flag_on(flags, flag)
func set_flag_off(flag: CharacterFlag) -> void: flags = Util.set_flag_off(flags, flag)
func set_flag(flag: CharacterFlag, active: bool) -> void: flags = Util.set_flag(flags, flag, active)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
# GETSET
## Thou shalt not access body_base directly or thou shalt be smote
func set_body_id(body_id: int) -> void:
	body_base.body_id = body_id

func _on_body_changed() -> void:
	if body_base.body_model.l_hand_skeleton_ik_3d:
		body_base.body_model.l_hand_skeleton_ik_3d.target_node = l_hand_ik_target.get_path()
		body_base.body_model.l_hand_skeleton_ik_3d.start()
	if body_base.body_model.r_hand_skeleton_ik_3d:
		body_base.body_model.r_hand_skeleton_ik_3d.target_node = r_hand_ik_target.get_path()
		body_base.body_model.r_hand_skeleton_ik_3d.start()
	
	max_shields = body_base.body_data.max_shields
	shields = max_shields
	max_health = body_base.body_data.max_health
	health = max_health
	
	crouch_speed = body_base.body_data.crouch_speed
	walk_speed = body_base.body_data.walk_speed
	jog_speed = body_base.body_data.jog_speed
	sprint_speed = body_base.body_data.sprint_speed
	
	collision_layer = body_base.body_data.collision_layer
	collision_mask = body_base.body_data.collision_mask

func get_weapon_hold_offset() -> Vector3:
	if gun_base.data:
		return gun_base.data.hold_offset
	else:
		return Vector3.ZERO

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _enter_tree() -> void:
	set_multiplayer_authority(get_parent().get_multiplayer_authority())

func _ready() -> void:
	gun_base.equipped_to_character = self
	body_base.body_changed.connect(_on_body_changed)
	
	if is_multiplayer_authority():
		inventory.init()
		set_active_inventory_slot_weapon()
		
		## TODO: TEMP
		#body_base.hide()
	
	gun_barrel_ik_target.global_position = global_position
	l_hand_ik_target.global_position = global_position
	r_hand_ik_target.global_position = global_position

func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority(): physics_update(delta)

func physics_update(delta: float) -> void:
	if is_multiplayer_authority() && global_position.y < -200.0:
		print("[Peer %s]: Out of Bounds death" % multiplayer.get_unique_id())
		die()
	
	if dead:
		hide()
		return
	
	if body_base.melee_target == 1.0:
		melee_timer += delta
		if melee_timer >= melee_time:
			melee_timer = 0.0
			body_base.melee_target = 0.0
			body_base.body_model.set_melee_active(false)
		body_base.set_ik_active(false)
	else:
		body_base.set_ik_active(true)
	
	if in_vehicle:
		body_base.set_ik_active(false)
		gun_base.hide()
		body_base.set_walking(0.0)
	else:
		gun_base.show()
	
	if !is_instance_valid(vehicle):
		_update_movement(delta)
		_update_aim(delta)
	else:
		_send_vehicle_inputs(delta)
		vehicle.update(delta)
		
		# Updating the vehicle may cause a forced ejection, so we need to check that we are still in the vehicle before updating our position
		if is_instance_valid(vehicle):
			linear_velocity = Vector3.ZERO
			global_position = vehicle.seat.global_position
		#global_transform = vehicle.seat.global_transform
	
	_update_stats(delta)

func _process(_delta: float) -> void:
	if shield_recharge_timer != 0.0: return
	if shields == max_shields: return
	var shield_percent: float = shields * 0.01
	
	shield_recharge_audio_player.pitch_scale = shield_percent + 0.01
	
	if shield_percent > 0.5:
		shield_recharge_audio_player.volume_db = ((1.0 - shield_percent) * 5.0) * 200.0 - 200.0
	else:
		shield_recharge_audio_player.volume_db = 0.0

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func face_direction(direction: Vector3, delta: float) -> void:
	Util.rotate_yaw_to_target(delta * move_direction_lerp_speed, body_container, body_container.global_position + direction)

func look_in_direction(look_basiss: Basis, _delta: float) -> void:
	$BodyContainer/MeshInstance3D.global_basis = look_basiss

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _send_vehicle_inputs(_delta: float) -> void:
	pass

func _update_stats(delta: float) -> void:
	if is_multiplayer_authority():
		shield_recharge_timer = clampf(shield_recharge_timer - delta, 0.0, shield_recharge_delay)
		if shield_recharge_timer == 0.0:
			shields = clampf(shields + delta * shield_recharged_per_second, 0.0, max_shields)
			if !shields_charging && shields != max_shields: start_shield_regen_sound()
	if shields == max_shields:
		shields_charging = false
		shield_recharge_audio_player.stop()
	
	var shield_percent: float = shields * 0.01
	shield_model.get_surface_override_material(0).albedo_color.a8 = shield_percent * 200.0
	#shield_model.get_surface_override_material(0).set_shader_parameter("fresnel_sharpness", 9.0 - shield_percent * 8.0)
	#shield_model.get_surface_override_material(0).set_shader_parameter("extend_distance", -0.1 + shield_percent * 0.14)
	
	if shields <= 0.0 && !shields_down:
		shields_down = true
		shields_charging = false
		if max_shields > 0.0: SoundManager.play_pitched_3d_sfx(12, SoundDatabase.SoundType.SFX_EXPLOSION, global_position)
	elif shields > 0.0 && shields_down:
		shields_down = false
	
	speed_recharge_timer = clampf(speed_recharge_time + delta, 0.0, speed_recharge_time)
	if speed_recharge_timer == speed_recharge_time:
		speed_multiplier = move_toward(speed_multiplier, target_speed_multiplier, delta)

func _update_aim(delta: float) -> void:
	if !is_multiplayer_authority(): return
	
	if body_base.body_model.r_hand_skeleton_ik_3d && body_base.body_model.r_hand_skeleton_ik_3d.active == false && body_base.body_model.r_hand_bone_attachment_3d:
		gun_barrel_ik_target.global_transform = body_base.body_model.r_hand_bone_attachment_3d.get_child(0).global_transform
		gun_barrel_ik_target.scale = Vector3.ONE
		return
	
	# Update breath vector, used to add a little bit of natural movement to the aim so that it isn't robotically perfect
	breath_timer += delta
	breath = Vector3(sin(breath_timer * 0.1), sin(breath_timer * 0.3), sin(breath_timer * 0.1)) * 0.3
	
	# Barrel position recoil
	var raw_position_recoil: Vector3 = gun_barrel_position_recoil_modifier * 0.1 + breath * 0.1
	var position_recoil: Vector3 = (raw_position_recoil.x * gun_barrel_ik_target.global_basis.x + raw_position_recoil.y * gun_barrel_ik_target.global_basis.y + raw_position_recoil.z * gun_barrel_ik_target.global_basis.z)
	
	gun_barrel_ik_target.global_position = gun_barrel_ik_target.global_position.move_toward(gun_barrel_position_target + position_recoil, delta * clampf(gun_barrel_ik_target.global_position.distance_to(gun_barrel_position_target) * 55.0, 2.0, 999.0))
	
	# Barrel look direction recoil
	var look_recoil: Vector3 = (gun_barrel_angular_recoil_modifier.x * gun_barrel_ik_target.global_basis.x + gun_barrel_angular_recoil_modifier.y * gun_barrel_ik_target.global_basis.y)
	
	var gun_barrel_look_direction_target: Vector3 = (gun_barrel_look_target - gun_barrel_ik_target.global_position).normalized()
	gun_barrel_look_direction = gun_barrel_look_direction.move_toward(gun_barrel_look_direction_target + look_recoil, delta * clampf(gun_barrel_look_direction.distance_to(gun_barrel_look_direction_target) * 15.0, 1.05, 999.0))
	gun_barrel_ik_target.look_at(gun_barrel_ik_target.global_position + gun_barrel_look_direction)
	
	# Barrel steadying
	# TODO: Affected by gun weight & arm strength
	gun_barrel_position_recoil_modifier = gun_barrel_position_recoil_modifier.move_toward(Vector3.ZERO, delta * clampf(gun_barrel_position_recoil_modifier.distance_to(Vector3.ZERO) * 15.0, 1.05, 999.0))
	gun_barrel_angular_recoil_modifier = gun_barrel_angular_recoil_modifier.move_toward(Vector3.ZERO, delta * clampf(gun_barrel_angular_recoil_modifier.distance_to(Vector3.ZERO) * 15.0, 1.05, 999.0))
	
	if is_instance_valid(gun_base.model):
		if is_instance_valid(gun_base.model.l_hand_grip):
			l_hand_ik_target.global_transform = gun_base.model.l_hand_grip.global_transform
		if is_instance_valid(gun_base.model.r_hand_grip):
			r_hand_ik_target.global_transform = gun_base.model.r_hand_grip.global_transform

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
# HELPER
func snap_gun_aim() -> void:
	var look_recoil: Vector3 = (gun_barrel_angular_recoil_modifier.x * gun_barrel_ik_target.global_basis.x + gun_barrel_angular_recoil_modifier.y * gun_barrel_ik_target.global_basis.y)
	
	var gun_barrel_look_direction_target: Vector3 = (gun_barrel_look_target - gun_barrel_ik_target.global_position).normalized()
	gun_barrel_look_direction = gun_barrel_look_direction_target + look_recoil
	gun_barrel_ik_target.look_at(gun_barrel_ik_target.global_position + gun_barrel_look_direction)

func start_shield_regen_sound() -> void:
	shields_charging = true
	shield_recharge_audio_player.play()

func set_gun_barrel_aim(_basis: Basis, offset: Vector3) -> void:
	if body_base.body_model.r_shoulder_bone_attachment_3d:
		gun_barrel_position_target = (body_base.body_model.r_shoulder_bone_attachment_3d.global_position
			+ _basis.x * offset.x
			+ _basis.y * offset.y
			- _basis.z * offset.z)
	else:
		gun_barrel_position_target = (body_base.body_model.global_position
			+ _basis.x * offset.x
			+ _basis.y * offset.y
			- _basis.z * offset.z)

func will_die_from_damage(damage_data: DamageData, area_id: int) -> bool:
	var damage: float = damage_data.damage_strength
	if area_id == 1: damage *= 2.5
	print("total_health: %s | total_damage: %s" % [health + shields, damage])
	print("will die: %s" % ((health + shields) <= damage))
	return (health + shields) <= damage

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _update_movement(delta: float) -> void:
	if is_flag_on(CharacterFlag.CROUCH):
		current_speed = crouch_speed
	elif is_flag_on(CharacterFlag.WALK):
		current_speed = walk_speed
	elif is_flag_on(CharacterFlag.SPRINT):
		current_speed = sprint_speed
	else:
		current_speed = jog_speed
	
	current_speed *= speed_multiplier
	
	if is_flag_on(CharacterFlag.NOCLIP):
		_update_movement_noclip(delta)
	elif is_flag_on(CharacterFlag.UNDERWATER):
		_update_movement_underwater(delta)
	else:
		_update_movement_grounded(delta)

func _update_movement_noclip(delta: float) -> void:
	if is_flag_on(CharacterFlag.CROUCH): world_move_input.y = -1.0
	move_direction = lerp(move_direction, world_move_input.normalized(), delta * move_direction_lerp_speed)
	if world_move_input == Vector3.ZERO: set_flag_off(CharacterFlag.SPRINT)
	
	var noclip_speed: float = sprint_speed if !is_flag_on(CharacterFlag.SPRINT) else sprint_speed * 16.0
	global_position += move_direction * noclip_speed * delta

func _update_movement_underwater(delta: float) -> void:
	## Look left/right = roll
	## Look up/down = pitch
	## Move left/right = yaw
	## Move up/down = velocity
	
	move_direction = lerp(move_direction, -look_direction * move_input.z, delta * move_direction_lerp_speed)
	
	if move_direction != Vector3.ZERO:
		linear_velocity.x = move_toward(linear_velocity.x, move_direction.x * current_speed, current_speed)
		linear_velocity.y = move_toward(linear_velocity.y, move_direction.y * current_speed, current_speed)
		linear_velocity.z = move_toward(linear_velocity.z, move_direction.z * current_speed, current_speed)
		#body.set_walking(true)
	else:
		linear_velocity.x = move_toward(linear_velocity.x, 0.0, current_speed)
		linear_velocity.y = move_toward(linear_velocity.y, 0.0, current_speed)
		linear_velocity.z = move_toward(linear_velocity.z, 0.0, current_speed)
		#body.set_walking(false)
	
	if world_move_input == Vector3.ZERO:
		set_flag_off(CharacterFlag.SPRINT)
		#body.set_walking(false)
	
	#body_center_pivot.basis = body_center_pivot.basis.orthonormalized().slerp(look_basis.orthonormalized(), 0.1).orthonormalized()
	#nav_collider.basis = body_center_pivot.basis
	#body_container.basis = Basis.IDENTITY
	
	last_velocity = linear_velocity
	#move_and_slide()

func _update_movement_grounded(delta: float) -> void:
	#_update_upright_rotation()
	#_update_upright_force()
	_update_ride_force()
	
	if is_flag_on(CharacterFlag.GROUNDED) && last_velocity.y < -1.0:
		landed.emit(-last_velocity.y)
	
	if !is_flag_on(CharacterFlag.GROUNDED):
		linear_velocity.y -= gravity * delta
	elif world_move_input.y > 0.0:
		linear_velocity.y += jump_velocity
		jumped.emit()
	
	if is_flag_on(CharacterFlag.GROUNDED):
		move_direction = lerp(move_direction, Vector3(world_move_input.x, 0.0, world_move_input.z).normalized(), delta * move_direction_lerp_speed)
		
		if move_direction != Vector3.ZERO:
			linear_velocity.x = move_toward(linear_velocity.x, move_direction.x * current_speed, current_speed * delta * move_accel_lerp_speed)
			linear_velocity.z = move_toward(linear_velocity.z, move_direction.z * current_speed, current_speed * delta * move_accel_lerp_speed)
			if is_multiplayer_authority(): body_base.set_walking(1.0)
		else:
			linear_velocity.x = move_toward(linear_velocity.x, 0.0, current_speed * delta * move_accel_lerp_speed)
			linear_velocity.z = move_toward(linear_velocity.z, 0.0, current_speed * delta * move_accel_lerp_speed)
			if is_multiplayer_authority(): body_base.set_walking(0.0)
	
	if world_move_input == Vector3.ZERO:
		set_flag_off(CharacterFlag.SPRINT)
		if is_multiplayer_authority(): body_base.set_walking(0.0)
	
	last_velocity = linear_velocity

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _update_upright_rotation() -> void:
	var look_transform: Transform3D = Transform3D.IDENTITY

	if move_input == Vector3.ZERO:
		var forward = -basis.z + global_position
		forward.y = 0.0
		forward = forward.normalized()
		look_transform = look_transform.looking_at(forward)
	elif move_input.x == 0.0 && move_input.z == 0.0:
		return
	else:
		var input_normalized = move_direction
		input_normalized.y = 0.0
		input_normalized = input_normalized.normalized()
		
		var look_at_vec: Vector3 = Vector3(input_normalized.x, -0.1 * input_normalized.length(), input_normalized.z)
		look_transform = look_transform.looking_at(look_at_vec)
	
	upright_rotation = look_transform.basis.get_rotation_quaternion()
	#rotation = look_transform.basis.get_euler()

func _update_upright_force() -> void:
	var current_rotation = Quaternion.from_euler(rotation)
	var to_goal: Quaternion = Util.shortest_rotation(upright_rotation, current_rotation)
	
	var axis: Vector3 = to_goal.get_axis()
	var angle: float = to_goal.get_angle()
	axis = axis.normalized()
	
	constant_torque = (axis * (angle * upright_spring_strength)) - (angular_velocity * upright_spring_damper)

func _update_ride_force() -> void:
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(global_position, global_position - Vector3.UP * 1.75, 1)
	var result: Dictionary = space_state.intersect_ray(query)
	
	if !result.is_empty():
		var hit_point: Vector3 = result["position"]
		var hit_toi: float = (hit_point - global_position).length()
		var other_collider: Node3D = result["collider"]
		var normal: Vector3 = result["normal"]
		
		if hit_toi <= ride_height + ride_height * 0.1:
			# Close enough to be grounded
			if normal.y < max_ground_angle:
				set_flag_off(CharacterFlag.GROUNDED)
			else:
				set_flag_on(CharacterFlag.GROUNDED)
		else:
			set_flag_off(CharacterFlag.GROUNDED)
		
		if !is_flag_on(CharacterFlag.GROUNDED):
			constant_force = Vector3.ZERO
			return
		
		var other_linvel: Vector3 = other_collider.linear_velocity if other_collider is RigidBody3D else Vector3.ZERO
		var ray_direction_velocity: float = Vector3.DOWN.dot(linear_velocity)
		var other_direction_velocity: float = Vector3.DOWN.dot(other_linvel)
		var relative_velocity: float = ray_direction_velocity - other_direction_velocity
		
		var x: float = hit_toi - ride_height
		var spring_force: float = (x * ride_spring_strength) - (relative_velocity * ride_spring_damper)
		
		constant_force = Vector3.DOWN * spring_force
		
		if other_collider is RigidBody3D:
			pass
	else:
		set_flag_off(CharacterFlag.GROUNDED)
		constant_force = Vector3.ZERO

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@rpc("any_peer", "call_remote", "unreliable")
func _rpc_deal_damage(damage_strength: float, area_id: int) -> void:
	_deal_damage(damage_strength, area_id)

func _deal_damage(damage_strength: float, area_id: int) -> void:
	damaged.emit()
	
	if is_multiplayer_authority():
		shield_recharge_timer = shield_recharge_delay
		shields_charging = false
	
	var damage_left: float = damage_strength
	if area_id == 1: damage_left *= 2.5
	
	var damage_to_shields: float = clampf(damage_strength, 0.0, shields)
	if is_multiplayer_authority(): shields -= damage_to_shields
	damage_left -= damage_to_shields
	
	if damage_left <= 0.0:
		speed_multiplier = 0.25
		return
	
	speed_multiplier = 0.1
	speed_recharge_timer = 0.0
	health -= damage_left
	
	if health <= 0.0: die()

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _on_damageable_area_3d_damaged(damage_data: DamageData, area_id: int, _source: Node) -> void:
	if !is_multiplayer_authority():
		_rpc_deal_damage.rpc_id(get_multiplayer_authority(), damage_data.damage_strength, area_id)
		_deal_damage(damage_data.damage_strength, area_id)
	else:
		_deal_damage(damage_data.damage_strength, area_id)

func get_matter_id_for_damageable_area_3d(_area_id: int) -> int:
	if shields > 0.0:
		return 1
	else:
		return 0

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
# Actions
## Maybe you should just DIE
func die() -> void:
	if dead: return
	dead = true
	
	if is_multiplayer_authority():
		drop_weapon(Vector3(randf_range(-2.0, 2.0), randf_range(2.0, 5.0), randf_range(-2.0, 2.0)), Vector3(randf_range(-10.0, 10.0), randf_range(-10.0, 10.0), randf_range(-10.0, 10.0)))
		killed.emit(self)
		inventory.drop_contents()

		if is_instance_valid(vehicle):
			SpawnManager.spawn_server_owned_object(Spawner.SpawnType.VEHICLE, vehicle.id, vehicle.metadata, vehicle.global_transform)
			exit_vehicle()
		
		_rpc_die.rpc()
		set_physics_process(false)
		set_process(false)
		hide()
		collision_layer = 0
		collision_mask = 0
		body_base.deactivate()
		await get_tree().create_timer(10.0).timeout
		queue_free()
	else:
		_rpc_die.rpc_id(get_multiplayer_authority())
		set_physics_process(false)
		set_process(false)
		hide()
		collision_layer = 0
		collision_mask = 0
		body_base.deactivate()

@rpc("any_peer", "call_remote", "reliable")
func _rpc_die() -> void:
	die()

func equip(equippable: EquippableBase) -> void:
	# Check for empty inventory slot, if found, equip weapon and place it in empty slot
	for i in inventory.max_weapons:
		if inventory.weapons[i] == 0:
			switch_weapon(i)
			
			gun_base.data_id = equippable.gun_data_id
			if equippable.metadata.has("rounds"): gun_base.rounds = equippable.metadata["rounds"]
			if equippable.metadata.has("fire_mode_index"): gun_base.fire_mode_index = equippable.metadata["fire_mode_index"]
			switch_weapon(i)
			
			equippable.destroy()
			return
	
	# If no empty inventory slot found, swap with current slot
	drop_weapon(-global_basis.z, Vector3.ZERO)
	
	gun_base.data_id = equippable.gun_data_id
	if equippable.metadata.has("rounds"): gun_base.rounds = equippable.metadata["rounds"]
	if equippable.metadata.has("fire_mode_index"): gun_base.fire_mode_index = equippable.metadata["fire_mode_index"]
	
	equippable.destroy()
	set_active_inventory_slot_weapon()
	_on_weapon_changed()

func set_active_inventory_slot_weapon() -> void:
	inventory.weapons[inventory.active_weapon] = gun_base.data_id
	inventory.weapons_fire_mode[inventory.active_weapon] = gun_base.fire_mode_index
	inventory.weapons_ammo[inventory.active_weapon] = gun_base.rounds

func switch_weapon(inventory_slot: int) -> void:
	gun_base.interrupt_reload()
	
	set_active_inventory_slot_weapon()
	
	inventory.active_weapon = inventory_slot
	gun_base.data_id = inventory.weapons[inventory_slot]
	gun_base.fire_mode_index = inventory.weapons_fire_mode[inventory_slot]
	gun_base.rounds = inventory.weapons_ammo[inventory_slot]
	
	_on_weapon_changed()

func _on_weapon_changed() -> void:
	weapon_changed.emit()

func drop_weapon(_lin_vel: Vector3, _ang_vel: Vector3) -> void:
	if gun_base.data_id == 0: return
	SpawnManager.spawn_equippable(
		gun_base.data_id, {
			"rounds" = gun_base.rounds,
			"fire_mode_index" = gun_base.fire_mode_index,
		},
		global_transform,
		_lin_vel,
		_ang_vel)
	gun_base.data_id = 0
	set_active_inventory_slot_weapon()

func melee() -> void:
	if vehicle:
		pass
	else:
		_rpc_melee.rpc()

@rpc("any_peer", "call_local", "unreliable")
func _rpc_melee() -> void:
	print("melee")
	if body_base.melee_target != 1.0:
		if is_instance_valid(body_base.body_model.animation_tree):
			if body_base.melee_right:
				body_base.body_model.animation_tree["parameters/l_melee_seek/seek_request"] = 0.0
			else:
				body_base.body_model.animation_tree["parameters/r_melee_seek/seek_request"] = 0.0
		body_base.melee_right = !body_base.melee_right
		body_base.body_model.set_melee_active(true)
	body_base.melee_target = 1.0

func board_vehicle(_vehicle: VehicleBase) -> void:
	vehicle = _vehicle
	vehicle.board(self)
	in_vehicle = true

func exit_vehicle() -> void:
	vehicle.exit()
	vehicle.queue_free()
	SpawnManager.spawn_server_owned_object(Spawner.SpawnType.VEHICLE, vehicle.id, vehicle.metadata, vehicle.global_transform)
	
	global_position = vehicle.seat.global_position
	global_basis = Basis.IDENTITY
	gun_barrel_ik_target.global_position = global_position
	l_hand_ik_target.global_position = global_position
	r_hand_ik_target.global_position = global_position
	
	vehicle = null
	in_vehicle = false

func try_reload() -> void:
	if vehicle:
		vehicle.try_reload()
	else:
		gun_base.try_reload()

func set_sprinting(active: bool) -> void:
	if vehicle:
		pass
	else:
		if active:
			if !is_flag_on(Character.CharacterFlag.SPRINT): set_flag_on(Character.CharacterFlag.SPRINT)
		else:
			if is_flag_on(Character.CharacterFlag.SPRINT): set_flag_off(Character.CharacterFlag.SPRINT)

func try_fire_held_press(local_player_id: int, delta: float) -> void:
	if vehicle:
		pass
	else:
		gun_base.try_fire_held_press(local_player_id, self, delta)

func try_fire_single_press(local_player_id: int, delta: float) -> void:
	if vehicle:
		pass
	else:
		gun_base.try_fire_single_press(local_player_id, self, delta)
