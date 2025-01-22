class_name BodyModel extends Node3D

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
signal footstep()
signal dealt_melee_damage(area: DamageableArea3D, will_die: bool)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@onready var skeleton_3d: Skeleton3D

@export var l_hand_skeleton_ik_3d: SkeletonIK3D
@export var r_hand_skeleton_ik_3d: SkeletonIK3D
@export var l_shoulder_bone_attachment_3d: BoneAttachment3D
@export var r_shoulder_bone_attachment_3d: BoneAttachment3D

@export var r_hand_bone_attachment_3d: BoneAttachment3D

@export var head_bone_attachment: BoneAttachment3D
@export var animation_tree: AnimationTree

@export var melee_damaging_area_3d: DamagingArea3D

@export var arp_model: bool = true

@export var power_brick: Node3D

var damageable_areas: Array[DamageableArea3D]
var damageable_area_rids: Array[RID]

@export var invisible_type: bool
@export var invisible_time: float = 1.0
@export var invisible_timer: float

@export var primary_material: Material
@export var secondary_material: Material
@export var tertiary_material: Material
@export var special_material: Material

var move_input: Vector2
var move_direction: Vector2
var vehicle_target: float
var vehicle_blend: float
var sprint_target: float
var sprint_blend: float

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _enter_tree() -> void:
	set_multiplayer_authority(get_parent().get_multiplayer_authority())

func _ready() -> void:
	l_hand_skeleton_ik_3d = get_node_or_null("LHandSkeletonIK3D")
	l_shoulder_bone_attachment_3d = get_node_or_null("LShoulderBoneAttachment3D")
	r_hand_skeleton_ik_3d = get_node_or_null("RHandSkeletonIK3D")
	r_shoulder_bone_attachment_3d = get_node_or_null("RShoulderBoneAttachment3D")
	
	r_hand_bone_attachment_3d = get_node_or_null("RHandBoneAttachment3D")
	
	head_bone_attachment = get_node_or_null("HeadBoneAttachment3D")
	animation_tree = get_node_or_null("AnimationTree")
	
	melee_damaging_area_3d = get_node_or_null("MeleeDamagingArea3D")
	
	if arp_model:
		_init_arp_model()
	else:
		_init_model()
	
	_init_children()

func _physics_process(delta: float) -> void:
	move_direction = move_direction.move_toward(move_input, delta * 5.0)
	vehicle_blend = move_toward(vehicle_blend, vehicle_target, delta * 5.0)
	sprint_blend = move_toward(sprint_blend, sprint_target, delta * 5.0)
	
	if !invisible_type: return
	if $Model.visible:
		invisible_timer += delta
		if invisible_timer >= invisible_time:
			invisible_timer = 0.0
			$Model.hide()

func _init_children() -> void:
	damageable_areas = []
	damageable_area_rids = []
	for child in get_children(): _parse_child_recursive(child)
	
	if is_instance_valid(melee_damaging_area_3d):
		melee_damaging_area_3d.exclude_areas = damageable_areas

func _parse_child_recursive(parent: Node) -> void:
	if parent is DamageableArea3D:
		damageable_areas.append(parent)
		damageable_area_rids.append(parent.get_rid())
		if !parent.damaged.is_connected(_on_damageable_area_3d_damaged): parent.damaged.connect(_on_damageable_area_3d_damaged)
		parent.source = self
	elif parent is MeshInstance3D:
		if parent.is_in_group("primary_material"):
			parent.set_surface_override_material(0, primary_material)
		elif parent.is_in_group("secondary_material"):
			parent.set_surface_override_material(0, secondary_material)
		elif parent.is_in_group("tertiary_material"):
			parent.set_surface_override_material(0, tertiary_material)
		elif special_material:
			parent.set_surface_override_material(0, special_material)
	else:
		for child in parent.get_children(): _parse_child_recursive(child)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _init_arp_model() -> void:
	skeleton_3d = $Model/root/Skeleton3D
	
	if is_instance_valid(l_hand_skeleton_ik_3d):
		l_hand_skeleton_ik_3d.root_bone = "arm_stretch.l"
		l_hand_skeleton_ik_3d.tip_bone = "hand.l"
		l_hand_skeleton_ik_3d.reparent(skeleton_3d)
	if is_instance_valid(l_shoulder_bone_attachment_3d):
		l_shoulder_bone_attachment_3d.reparent(skeleton_3d)
		l_shoulder_bone_attachment_3d.bone_name = "shoulder.l"
	
	if is_instance_valid(r_hand_skeleton_ik_3d):
		r_hand_skeleton_ik_3d.root_bone = "arm_stretch.r"
		r_hand_skeleton_ik_3d.tip_bone = "hand.r"
		r_hand_skeleton_ik_3d.reparent(skeleton_3d)
	if is_instance_valid(r_shoulder_bone_attachment_3d):
		r_shoulder_bone_attachment_3d.reparent(skeleton_3d)
		r_shoulder_bone_attachment_3d.bone_name = "shoulder.r"
	
	if is_instance_valid(r_hand_bone_attachment_3d):
		r_hand_bone_attachment_3d.reparent(skeleton_3d)
		r_hand_bone_attachment_3d.bone_name = "hand.r"
	
	if is_instance_valid(head_bone_attachment):
		head_bone_attachment.reparent(skeleton_3d)
		head_bone_attachment.bone_name = "head.x"

func _init_model() -> void:
	pass # TODO: Something? Anything?

func set_hands(hands: GunData.Hands) -> void:
	if !animation_tree: return
	if hands == GunData.Hands.ONE_HANDED:
		animation_tree["parameters/idle_hands_blend/blend_amount"] = 0.0
		animation_tree["parameters/walk_hands_blend/blend_amount"] = 0.0
	elif hands == GunData.Hands.TWO_HANDED:
		animation_tree["parameters/idle_hands_blend/blend_amount"] = 1.0
		animation_tree["parameters/walk_hands_blend/blend_amount"] = 1.0

func _on_damageable_area_3d_damaged(damage_data: DamageData, area_id: int, source: Node) -> void:
	var model: Node3D = get_node_or_null("Model")
	if is_instance_valid(model):
		$Model.show()
		invisible_timer = 0.0
	get_parent()._on_damageable_area_3d_damaged(damage_data, area_id, source)

func get_matter_id_for_damageable_area_3d(area_id: int) -> int:
	return get_parent().get_matter_id_for_damageable_area_3d(area_id)

func set_melee_active(active: bool) -> void:
	var model: Node3D = get_node_or_null("Model")
	if is_instance_valid(model):
		$Model.show()
		invisible_timer = 0.0
	
	if !is_multiplayer_authority(): return
	if is_instance_valid(melee_damaging_area_3d):
		melee_damaging_area_3d.active = active

func will_die_from_damage(damage_data: DamageData, area_id: int) -> bool:
	return get_parent().will_die_from_damage(damage_data, area_id)

func deactivate() -> void:
	for child in get_children(): _deactivate_recursive(child)

func _deactivate_recursive(parent: Node) -> void:
	if parent is DamageableArea3D:
		parent.collision_layer = 0
		parent.collision_mask = 0
	else:
		for child in parent.get_children(): _deactivate_recursive(child)

func set_team(team: int) -> void:
	for area in damageable_areas:
		area.team = team

func set_melee_stats(melee_damage: float, melee_force: float, _melee_slow: float) -> void:
	if !is_instance_valid(melee_damaging_area_3d): return
	melee_damaging_area_3d.damage_data = DamageData.new()
	melee_damaging_area_3d.damage_data.damage_strength = melee_damage
	melee_damaging_area_3d.damage_data.damage_force = melee_force

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _footstep() -> void:
	footstep.emit()

func _on_melee_damaging_area_3d_dealt_damage(area: DamageableArea3D, will_die: bool) -> void:
	dealt_melee_damage.emit(area, will_die)

func set_move_input(_move_input: Vector2) -> void:
	move_input = _move_input
	animation_tree["parameters/1h_walk/blend_position"] = Vector2(-move_direction.y, move_direction.x).normalized()
	animation_tree["parameters/2h_heavy_walk/blend_position"] = Vector2(-move_direction.y, move_direction.x).normalized()

func set_vehicle_anim(_vehicle_target: float) -> void:
	if !is_instance_valid(animation_tree): return
	if !animation_tree.has_animation("drop_pod"): return
	vehicle_target = _vehicle_target
	animation_tree["parameters/vehicle_blend/blend_amount"] = vehicle_blend

func set_sprinting(_sprint_target: float) -> void:
	if !is_instance_valid(animation_tree): return
	if !animation_tree.has_animation("1h_pistol_sprint_forward"): return
	sprint_target = _sprint_target
	animation_tree["parameters/sprint_blend/blend_amount"] = sprint_blend
