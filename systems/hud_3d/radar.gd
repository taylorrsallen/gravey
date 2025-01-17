class_name HUD3DRadar extends MeshInstance3D

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
const RADAR_BLIP: PackedScene = preload("res://systems/hud_3d/radar_blip.scn")

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@onready var blips: Node3D = $Blips
@export var existing_blips: Dictionary = {}

@export var radar_update_sound_pool: SoundPoolData
@export var new_blip_sound_pool: SoundPoolData

@export var radar_update_frequency: float = 2.0
var radar_update_timer: float

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _place_blip(camera_rig: CameraRig, character: Character, other_character: Character) -> void:
	if existing_blips.has(other_character):
		existing_blips[other_character].update_position(camera_rig, character, other_character)
		return
	
	var blip: RadarBlip = RADAR_BLIP.instantiate()
	blips.add_child(blip, true)
	existing_blips[other_character] = blip
	blip.update_position(camera_rig, character, other_character)

func update_display(camera_rig: CameraRig, character: Character, delta: float) -> void:
	#for blip in blips.get_children():
		#blip.reduce_alpha(delta)
	
	radar_update_timer += delta
	if radar_update_timer >= radar_update_frequency:
		radar_update_timer -= radar_update_frequency
	else:
		return
	
	if radar_update_sound_pool:
		var sound: SoundReferenceData = radar_update_sound_pool.pool.pick_random()
		SoundManager.play_ui_sfx(sound.id, sound.type, sound.volume_db)
	
	var results: Array[PhysicsBody3D] = AreaQueryManager.query_area(character.global_position, 15.0, 2, [character])
	for result in results:
		_place_blip(camera_rig, character, result)
	
	for other_character in existing_blips.keys():
		if !is_instance_valid(other_character):
			existing_blips[other_character].queue_free()
			existing_blips.erase(other_character)
			continue
		if !results.has(other_character):
			existing_blips[other_character].queue_free()
			existing_blips.erase(other_character)
