extends Node

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
const BULLET_BASE: PackedScene = preload("res://systems/projectile/bullet_base.scn")
const AI_CONTROLLER: PackedScene = preload("res://systems/controller/ai/ai_controller.scn")
const CHARACTER: PackedScene = preload("res://systems/character/character.scn")
const EQUIPPABLE_BASE: PackedScene = preload("res://systems/interactable/equippable_base.scn")
const PICKUP_BASE: PackedScene = preload("res://systems/interactable/pickup_base.scn")

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func spawn_client_owned_object(player_id: int, _spawn_type: int, _spawn_id: int, position: Vector3, basis: Basis) -> void:
	var bullet: BulletBase = BULLET_BASE.instantiate()
	bullet.position = position
	bullet.basis = basis
	bullet.set_multiplayer_authority(multiplayer.get_unique_id())
	var peer_connection: PeerConnection = Util.main.network_manager.try_get_local_peer_connection()
	if !peer_connection: return
	var player_controller: PlayerController = peer_connection.try_get_player_controller(player_id)
	if !player_controller: return
	player_controller.owned_objects.add_child(bullet, true)

func spawn_client_owned_bullet(player_id: int, bullet_id: int, position: Vector3, basis: Basis) -> void:
	var bullet: BulletBase = BULLET_BASE.instantiate()
	bullet.position = position
	bullet.basis = basis
	bullet.data = Util.BULLET_DATABASE.database[bullet_id]
	bullet.set_multiplayer_authority(multiplayer.get_unique_id())
	var peer_connection: PeerConnection = Util.main.network_manager.try_get_local_peer_connection()
	if !peer_connection: return
	var player_controller: PlayerController = peer_connection.try_get_player_controller(player_id)
	if !player_controller: return
	player_controller.owned_objects.add_child(bullet, true)



# (({[%%%(({[=======================================================================================================================]}))%%%]}))
## Server only
func _spawn_server_owned_ai() -> AIController:
	if !multiplayer.is_server(): return
	var ai_controller: AIController = AI_CONTROLLER.instantiate()
	return ai_controller

## Server only
func _spawn_server_owned_character(body_id: int, metadata: Dictionary, global_transform: Transform3D) -> Character:
	if !multiplayer.is_server(): return
	var character: Character = CHARACTER.instantiate()
	character.transform = global_transform
	Util.main.npcs.add_child(character, true)
	if metadata.has("gun_id"): character.gun_base.data_id = metadata["gun_id"]
	character.set_body_id(body_id)
	return character

func _spawn_server_owned_enemy(body_id: int, metadata: Dictionary, global_transform: Transform3D) -> AIController:
	var ai_controller: AIController = _spawn_server_owned_ai()
	var character: Character = _spawn_server_owned_character(body_id, metadata, global_transform)
	ai_controller.character = character
	Util.main.npcs.add_child(ai_controller, true)
	ai_controller.character = character
	return ai_controller

func spawn_equippable(id: int, metadata: Dictionary, global_transform: Transform3D, lin_vel: Vector3 = Vector3.ZERO, ang_vel: Vector3 = Vector3.ZERO) -> EquippableBase:
	if multiplayer.is_server():
		return _rpc_spawn_equippable(id, metadata, global_transform, lin_vel, ang_vel)
	else:
		_rpc_spawn_equippable.rpc_id(1, id, metadata, global_transform, lin_vel, ang_vel)
		return null

@rpc("any_peer", "call_remote", "unreliable")
func _rpc_spawn_equippable(id: int, metadata: Dictionary, global_transform: Transform3D, lin_vel: Vector3, ang_vel: Vector3) -> EquippableBase:
	var equippable: EquippableBase = EQUIPPABLE_BASE.instantiate()
	equippable.transform = global_transform
	Util.main.server_objects.add_child(equippable, true)
	equippable.metadata = metadata
	equippable.gun_data_id = id
	equippable.linear_velocity = lin_vel
	equippable.angular_velocity = ang_vel
	return equippable

func spawn_pickup(id: int, metadata: Dictionary, global_transform: Transform3D) -> PickupBase:
	if multiplayer.is_server():
		return _rpc_spawn_pickup(id, metadata, global_transform)
	else:
		_rpc_spawn_pickup.rpc_id(1, id, metadata, global_transform)
		return null

@rpc("any_peer", "call_remote", "unreliable")
func _rpc_spawn_pickup(id: int, metadata: Dictionary, global_transform: Transform3D) -> PickupBase:
	var pickup: PickupBase = PICKUP_BASE.instantiate()
	pickup.transform = global_transform
	pickup.metadata = metadata
	pickup.id = id
	Util.main.server_objects.add_child(pickup, true)
	return pickup

func spawn_vehicle(id: int, metadata: Dictionary, global_transform: Transform3D) -> VehicleBase:
	if multiplayer.is_server():
		return _rpc_spawn_vehicle(id, metadata, global_transform)
	else:
		_rpc_spawn_vehicle.rpc_id(1, id, metadata, global_transform)
		return null

@rpc("any_peer", "call_remote", "unreliable")
func _rpc_spawn_vehicle(id: int, metadata: Dictionary, global_transform: Transform3D) -> VehicleBase:
	var vehicle: VehicleBase = Util.VEHICLE_DATABASE.database[id].scene.instantiate()
	vehicle.transform = global_transform
	vehicle.metadata = metadata
	vehicle.id = id
	Util.main.server_objects.add_child(vehicle, true)
	return vehicle

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func spawn_server_owned_object(spawn_type: Spawner.SpawnType, spawn_id: int, metadata: Dictionary, global_transform: Transform3D) -> Node:
	if multiplayer.is_server():
		return _rpc_spawn_server_owned_object(spawn_type, spawn_id, metadata, global_transform)
	else:
		_rpc_spawn_server_owned_object.rpc_id(1, spawn_type, spawn_id, metadata, global_transform)
		return null

@rpc("any_peer", "call_remote", "unreliable")
func _rpc_spawn_server_owned_object(spawn_type: Spawner.SpawnType, spawn_id: int, metadata: Dictionary, global_transform: Transform3D) -> Node:
		match spawn_type:
			Spawner.SpawnType.ENEMY: return _spawn_server_owned_enemy(spawn_id, metadata, global_transform)
			Spawner.SpawnType.EQUIPPABLE: return spawn_equippable(spawn_id, metadata, global_transform)
			Spawner.SpawnType.PICKUP: return spawn_pickup(spawn_id, metadata, global_transform)
			Spawner.SpawnType.VEHICLE: return spawn_vehicle(spawn_id, metadata, global_transform)
			_: return null

#func spawn_server_owned_object(spawn_type: int)

#@rpc("any_peer", "call_local", "unreliable")
#func rpc_spawn_client_owned_object(spawn_type: int, spawn_id: int, position: Vector3, rotation: Vector3, client_peer_id: int) -> void:
	#var bullet: BulletBase = BULLET_BASE.instantiate()
	#bullet.position = position
	#bullet.rotation = rotation
	#bullet.set_multiplayer_authority(client_peer_id)
	#Util.main.projectiles.add_child(bullet, true)
