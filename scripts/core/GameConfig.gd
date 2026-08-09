extends Resource
class_name GameConfig

@export var base_speed: float = 275.0
@export var start_size: float = 1.0
@export var start_health: float = 100.0
@export var absorb_ratio: float = 0.92
@export var growth_multiplier: float = 1.0
@export var attraction_radius: float = 72.0
@export var camera_min_zoom: float = 1.8
@export var camera_zoom_smoothing: float = 4.0
@export var spawn_radius: float = 1200.0
@export var despawn_radius: float = 1800.0
@export var max_pickups: int = 80
@export var max_pickups_cap: int = 180
@export var hazard_damage_cooldown: float = 0.75
@export var hazard_knockback: float = 360.0

@export var boost_multiplier: float = 1.7
@export var mana_max: float = 100.0
@export var mana_drain_per_second: float = 35.0
@export var mana_regen_per_second: float = 18.0
@export var consumed_terrain_cooldown: float = 18.0
@export var consumed_terrain_value_multiplier: float = 0.35
