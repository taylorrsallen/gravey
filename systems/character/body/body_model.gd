class_name BodyModel extends Node3D

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@onready var skeleton_3d: Skeleton3D = $Model/root/Skeleton3D
@export var l_hand_skeleton_ik_3d: SkeletonIK3D
@export var r_hand_skeleton_ik_3d: SkeletonIK3D
@export var head_bone_attachment: BoneAttachment3D

@export var arp_model: bool = true

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _ready() -> void:
	l_hand_skeleton_ik_3d = get_node_or_null("LHandSkeletonIK3D")
	r_hand_skeleton_ik_3d = get_node_or_null("RHandSkeletonIK3D")
	head_bone_attachment = get_node_or_null("HeadBoneAttachment3D")
	
	if arp_model:
		_init_arp_model()
	else:
		_init_model()

func _init_arp_model() -> void:
	if is_instance_valid(l_hand_skeleton_ik_3d):
		l_hand_skeleton_ik_3d.root_bone = "arm_stretch.l"
		l_hand_skeleton_ik_3d.tip_bone = "hand.l"
		l_hand_skeleton_ik_3d.reparent(skeleton_3d)
	if is_instance_valid(r_hand_skeleton_ik_3d):
		r_hand_skeleton_ik_3d.root_bone = "arm_stretch.r"
		r_hand_skeleton_ik_3d.tip_bone = "hand.r"
		r_hand_skeleton_ik_3d.reparent(skeleton_3d)
	if is_instance_valid(head_bone_attachment):
		head_bone_attachment.reparent(skeleton_3d)
		head_bone_attachment.bone_name = "head.x"

func _init_model() -> void:
	print("I'll do it later")
