class_name AIController extends Node

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@export var character: Character: set = _set_character

@export var shots_per_second: float = 0.1
var shots_timer: float

@export var die_with_character: bool = true: set = _set_die_with_character

var target_character: Character

@export var metadata: Dictionary

var random_sound_time: float = 5.0
var random_sound_timer: float

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _set_die_with_character(_die_with_character: bool) -> void:
	die_with_character = _die_with_character
	if is_instance_valid(character):
		if !die_with_character && character.killed.is_connected(queue_free):
			character.killed.disconnect(_on_character_died)
		elif die_with_character && !character.killed.is_connected(queue_free):
			character.killed.connect(_on_character_died)

func _on_character_died(_character: Character):
	queue_free()

func _set_character(_character: Character) -> void:
	character = _character

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _ready() -> void:
	set_physics_process(false)
	call_deferred("_init_navigation")
	die_with_character = die_with_character
	
	random_sound_timer = randf_range(0.0, random_sound_time)

func _init_navigation() -> void:
	await get_tree().physics_frame
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	if !multiplayer.is_server(): return
	if !is_instance_valid(character): return
	
	random_sound_timer += delta * randf_range(0.6, 1.0)
	if random_sound_timer >= random_sound_time:
		random_sound_timer -= random_sound_time
		var sound: SoundReferenceData = character.body_base.body_data.random_sounds.pool.pick_random()
		SoundManager.play_pitched_3d_sfx(sound.id, sound.type, character.global_position)
	
	character.physics_update(delta)
	_find_target_character()
	_update_target_character(delta)

func _find_target_character() -> void:
	var peer_connections: Array[PeerConnection] = []
	for child in Util.main.network_manager.get_children():
		if child is PeerConnection: peer_connections.append(child)
	
	if peer_connections.is_empty(): return
	
	var player_characters: Array[Character] = []
	for peer_connection in peer_connections:
		for player_controller in peer_connection.get_children():
			if !(player_controller is PlayerController): continue
			if is_instance_valid(player_controller.character) && !player_controller.character.dead && player_controller.character.global_position.y < 800.0:
				player_characters.append(player_controller.character)
				continue
			
			var non_server_character: Character = null
			for owned_object in player_controller.owned_objects.get_children():
				if owned_object is Character:
					non_server_character = owned_object
					break
			
			if is_instance_valid(non_server_character) && !non_server_character.dead && non_server_character.global_position.y < 800.0: player_characters.append(non_server_character)
	
	if player_characters.is_empty(): return
	
	var closest_player_character: Character = null
	var closest_player_distance: float = 1000.0
	for player_character in player_characters:
		var distance: float = player_character.global_position.distance_to(character.global_position)
		if distance >= closest_player_distance: continue
		closest_player_character = player_character
		closest_player_distance = distance
	
	target_character = closest_player_character

func _update_target_character(delta: float) -> void:
	if !is_instance_valid(target_character):
		character.world_move_input = Vector3.ZERO
		return
	
	var look_transform: Transform3D = Transform3D(Basis.IDENTITY, character.global_position)
	look_transform = look_transform.looking_at(target_character.global_position)
	
	var distance_to_target: float = character.global_position.distance_to(target_character.global_position)
	
	character.look_in_direction(look_transform.basis, delta)
	character.gun_barrel_look_target = target_character.global_position + Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * distance_to_target * 0.05
	character.set_gun_barrel_aim(look_transform.basis, character.get_weapon_hold_offset())
	
	var should_move_closer: bool = false
	var should_fire: bool = false
	var should_melee: bool = false
	
	var space_state: PhysicsDirectSpaceState3D = character.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(character.gun_base.global_position, character.global_position - look_transform.basis.z * 50.0, 3, [character.get_rid()])
	var result: Dictionary = space_state.intersect_ray(query)
	
	if result.has("collider") && is_instance_valid(result["collider"]) && result["collider"] == target_character:
		should_move_closer = distance_to_target > character.body_base.body_data.max_desired_distance
		should_fire = distance_to_target <= character.body_base.body_data.firing_range
	elif character.body_base.body_data.firing_range > 0.0:
		should_move_closer = true
	else:
		should_move_closer = distance_to_target > character.body_base.body_data.max_desired_distance
	
	if should_move_closer:
		character.navigation_agent_3d.target_position = target_character.global_position
		var next_nav_point = character.navigation_agent_3d.get_next_path_position()
		character.world_move_input = next_nav_point - character.global_position
		character.world_move_input.y = 0.0
		character.world_move_input = character.world_move_input.normalized()
		character.face_direction(character.world_move_input, delta)
	elif distance_to_target < character.body_base.body_data.min_desired_distance:
		character.world_move_input = character.global_position - target_character.global_position
		character.world_move_input.y = 0.0
		character.world_move_input = character.world_move_input.normalized()
		character.face_direction(-character.world_move_input, delta)
	else:
		character.face_direction(target_character.global_position - character.global_position, delta)
		character.world_move_input = Vector3.ZERO
	
	if character.global_position.distance_to(target_character.global_position) <=character.body_base.body_data. melee_range: should_melee = true
	
	if should_fire && !should_melee:
		shots_timer += randf_range(delta, delta * 0.5)
		if shots_timer >= shots_per_second:
			shots_timer = 0.0
			character.gun_base.try_fire_single_press(0, character, delta)
			if character.gun_base.rounds == 0:
				character.gun_base.try_reload()
	elif should_melee:
		character.melee()
