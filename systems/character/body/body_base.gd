class_name BodyBase extends Node3D

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
signal body_changed()

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@export var body_id: int: set = _set_body_id
@export var body_data: BodyData: set = _set_body_data
@export var body_model: BodyModel

@export var walk_target: float
@export var walk_blend: float

@export var melee_right: bool
@export var melee_target: float
@export var melee_blend: float

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _physics_process(delta: float) -> void:
	if !is_instance_valid(body_model): return
	if !is_instance_valid(body_model.animation_tree): return
	
	walk_blend = move_toward(walk_blend, walk_target, delta * 3.0)
	body_model.animation_tree["parameters/walk_blend/blend_amount"] = walk_blend
	
	melee_blend = move_toward(melee_blend, melee_target, delta * 3.0)
	if melee_right:
		body_model.animation_tree["parameters/r_melee_blend/blend_amount"] = melee_blend
		body_model.animation_tree["parameters/l_melee_blend/blend_amount"] = move_toward(body_model.animation_tree["parameters/l_melee_blend/blend_amount"], 0.0, delta * 3.0)
	else:
		body_model.animation_tree["parameters/l_melee_blend/blend_amount"] = melee_blend
		body_model.animation_tree["parameters/r_melee_blend/blend_amount"] = move_toward(body_model.animation_tree["parameters/r_melee_blend/blend_amount"], 0.0, delta * 3.0)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _set_body_id(_body_id: int) -> void:
	body_id = _body_id
	body_data = Util.BODY_DATABASE.database[body_id]

func _set_body_data(_body_data: BodyData) -> void:
	body_data = _body_data
	
	if is_instance_valid(body_model): body_model.queue_free()
	body_model = body_data.body_model.instantiate()
	add_child(body_model)
	
	body_changed.emit()

func disable_left_hand() -> void:
	if !is_instance_valid(body_model): return
	if is_instance_valid(body_model.l_hand_skeleton_ik_3d):
		body_model.l_hand_skeleton_ik_3d.stop()

func enable_left_hand() -> void:
	if !is_instance_valid(body_model): return
	if is_instance_valid(body_model.l_hand_skeleton_ik_3d):
		body_model.l_hand_skeleton_ik_3d.stop()
		body_model.l_hand_skeleton_ik_3d.start()

func disable_right_hand() -> void:
	if !is_instance_valid(body_model): return
	if is_instance_valid(body_model.r_hand_skeleton_ik_3d):
		body_model.r_hand_skeleton_ik_3d.stop()

func enable_right_hand() -> void:
	if !is_instance_valid(body_model): return
	if is_instance_valid(body_model.r_hand_skeleton_ik_3d):
		body_model.r_hand_skeleton_ik_3d.stop()
		body_model.r_hand_skeleton_ik_3d.start()

func set_hands(hands: GunData.Hands) -> void:
	if !is_instance_valid(body_model): return
	body_model.set_hands(hands)

func set_magnet(magnet: Vector3) -> void:
	if !is_instance_valid(body_model): return
	if is_instance_valid(body_model.l_hand_skeleton_ik_3d): body_model.l_hand_skeleton_ik_3d.magnet = -magnet
	if is_instance_valid(body_model.r_hand_skeleton_ik_3d): body_model.r_hand_skeleton_ik_3d.magnet = magnet

func set_walking(_walk_target: float) -> void:
	if !is_instance_valid(body_model): return
	walk_target = _walk_target

func set_ik_active(active: bool) -> void:
	if !is_instance_valid(body_model): return
	if !active:
		if body_model.l_hand_skeleton_ik_3d: body_model.l_hand_skeleton_ik_3d.active = false
		if body_model.r_hand_skeleton_ik_3d: body_model.r_hand_skeleton_ik_3d.active = false
	else:
		if body_model.l_hand_skeleton_ik_3d: body_model.l_hand_skeleton_ik_3d.active = true
		if body_model.r_hand_skeleton_ik_3d: body_model.r_hand_skeleton_ik_3d.active = true

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _on_damageable_area_3d_damaged(damage_data: DamageData, area_id: int, source: Node) -> void:
	get_parent().get_parent()._on_damageable_area_3d_damaged(damage_data, area_id, source)

func get_matter_id_for_damageable_area_3d(area_id: int) -> int:
	return get_parent().get_parent().get_matter_id_for_damageable_area_3d(area_id)

func will_die_from_damage(damage_data: DamageData, area_id: int) -> bool:
	return get_parent().get_parent().will_die_from_damage(damage_data, area_id)
