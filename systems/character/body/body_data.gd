class_name BodyData extends Resource

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
enum BodyRole {
	TANK,
	DAMAGE,
	DISRUPTOR,
	TRASH,
}

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@export var name: String

@export_category("Combat")
@export var stagger_threshold: float = 4.0
@export var max_health: float
@export var health_per_second: float
@export var max_shields: float
@export var shields_per_second: float

@export var melee_damage: float
@export var melee_force: float
@export var melee_slow: float

@export var team: int = -1

@export_category("Movement")
@export var weight: float = 1.0
@export var crouch_speed: float = 4.5
@export var walk_speed: float = 1.0
@export var jog_speed: float = 2.5
@export var sprint_speed: float = 8.0
@export var jump_velocity: float = 3.0

@export var navigation_collider_radius: float = 0.434
@export var navigation_collider_height: float = 1.25
@export var walkable_collision_layer: int = 1

@export_category("Model")
@export var body_model: PackedScene

@export_category("Wave Manager")
@export var role: BodyRole
@export var unlock_wave: int
@export var point_value: int

@export_category("AI")
@export var min_desired_distance: float = 10.0
@export var max_desired_distance: float = 20.0
@export var firing_range: float = 30.0
@export var melee_range: float = 1.0

@export var random_sounds: SoundPoolData
@export var collision_layer: int = 2
@export var collision_mask: int = 3
