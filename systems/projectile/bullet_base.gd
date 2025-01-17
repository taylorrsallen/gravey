class_name BulletBase extends Area3D

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@export var data: BulletData

var lifetime_timer: float = 0.0

#@onready var trail_3d: Trail3D = $Trail3D
@export var previous_position: Vector3

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _enter_tree() -> void:
	set_multiplayer_authority(get_parent().get_multiplayer_authority())
	
	if !is_multiplayer_authority():
		collision_layer = 0
		collision_mask = 0

func _physics_process(delta: float) -> void:
	DebugDraw3D.draw_line(global_position, global_position - global_basis.z * data.speed, Color.RED, delta * 4.0)
	
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(global_position, global_position - global_basis.z * data.speed, 5, [])
	query.hit_from_inside = true
	var result: Dictionary = space_state.intersect_ray(query)
	
	if result.has("collider"):
		var hit_point: Vector3 = result["position"]
		var hit_normal: Vector3 = result["normal"]
		var hit_collider: Node3D = result["collider"]
		
		global_position = hit_point
		if is_multiplayer_authority(): _hit(hit_point, hit_normal, hit_collider)
	else:
		global_position += -global_basis.z * data.speed #+ Vector3.UP * sin(lifetime_timer * 10.0) * 0.05
	
	previous_position = global_position
	
	if !is_multiplayer_authority(): return
	lifetime_timer += delta
	if lifetime_timer >= data.lifetime: queue_free()

func _hit(point: Vector3, _normal: Vector3, collider: Node3D) -> void:
	if collider is DamageableArea3D:
		var player_controller: PlayerController = get_parent().get_parent()
		if collider.team != player_controller.character.body_base.body_data.team:
			# Headshot
			if collider.id == 1 && collider.will_die_from_damage(data.damage_data):
				player_controller.points += 10 + collider.source.get_parent().body_data.bonus_points_for_kill
			elif collider.will_die_from_damage(data.damage_data):
				player_controller.points += 5 + collider.source.get_parent().body_data.bonus_points_for_kill
			else:
				player_controller.points += 1
		
		collider.damage(data.damage_data, null)
	
	Util.play_bullet_hit_effects(collider, point, Basis.looking_at(point + global_basis.z), data)
	
	queue_free()
