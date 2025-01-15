class_name BodyModel extends Node3D

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
	print("I'll do it later")

func set_hands(hands: GunData.Hands) -> void:
	if !animation_tree: return
	if hands == GunData.Hands.ONE_HANDED:
		animation_tree["parameters/idle_hands_blend/blend_amount"] = 0.0
		animation_tree["parameters/walk_hands_blend/blend_amount"] = 0.0
	elif hands == GunData.Hands.TWO_HANDED:
		animation_tree["parameters/idle_hands_blend/blend_amount"] = 1.0
		animation_tree["parameters/walk_hands_blend/blend_amount"] = 1.0

func _on_damageable_area_3d_damaged(damage_data: DamageData, area_id: int, source: Node) -> void:
	get_parent()._on_damageable_area_3d_damaged(damage_data, area_id, source)

func get_matter_id_for_damageable_area_3d(area_id: int) -> int:
	return get_parent().get_matter_id_for_damageable_area_3d(area_id)

func set_melee_active(active: bool) -> void:
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
