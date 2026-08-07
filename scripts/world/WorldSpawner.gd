extends Node2D
class_name WorldSpawner

const ABSORBABLE_SCENE := preload("res://scenes/Absorbable.tscn")

@export var config: GameConfig
@export var run_state: RunState
@export var player: Node2D

var rng := RandomNumberGenerator.new()
var material_tiers := [
	{"name": "dust", "size": 0.5, "radius": 4.0, "color": Color("d9c8a9")},
	{"name": "sand", "size": 1.0, "radius": 6.0, "color": Color("e7d37a")},
	{"name": "dirt", "size": 2.0, "radius": 8.0, "color": Color("8b5a2b")},
	{"name": "leaf", "size": 4.0, "radius": 10.0, "color": Color("69b34c")},
	{"name": "stone", "size": 8.0, "radius": 13.0, "color": Color("8e99a4")},
	{"name": "rock", "size": 18.0, "radius": 18.0, "color": Color("6b7078")},
	{"name": "tree", "size": 42.0, "radius": 25.0, "color": Color("2f7d32")},
	{"name": "building", "size": 120.0, "radius": 40.0, "color": Color("6272a4")},
	{"name": "mountain", "size": 420.0, "radius": 72.0, "color": Color("7f8c8d")}
]

func _ready() -> void:
	rng.randomize()

func _process(_delta: float) -> void:
	if player == null:
		return
	_trim_far_objects()
	while get_child_count() < config.max_pickups:
		_spawn_pickup()

func _spawn_pickup() -> void:
	var tier := _choose_tier()
	var pickup := ABSORBABLE_SCENE.instantiate() as Absorbable
	var angle := rng.randf_range(0.0, TAU)
	var distance := rng.randf_range(config.spawn_radius * 0.25, config.spawn_radius)
	pickup.global_position = player.global_position + Vector2.from_angle(angle) * distance
	pickup.configure({
		"size": tier["size"] * rng.randf_range(0.85, 1.2),
		"value": rng.randf_range(0.8, 1.4),
		"score": maxi(1, int(tier["size"] * 5.0)),
		"currency": maxi(1, int(sqrt(tier["size"]))),
		"radius": tier["radius"],
		"color": tier["color"],
	})
	add_child(pickup)

func _choose_tier() -> Dictionary:
	var reachable_size := run_state.size * 1.35
	var candidates := material_tiers.filter(func(tier: Dictionary) -> bool: return tier["size"] <= reachable_size)
	if candidates.is_empty():
		return material_tiers[0]
	if rng.randf() < 0.18 and candidates.size() < material_tiers.size():
		return material_tiers[candidates.size()]
	return candidates[rng.randi_range(0, candidates.size() - 1)]

func _trim_far_objects() -> void:
	for child in get_children():
		if child is Node2D and child.global_position.distance_to(player.global_position) > config.despawn_radius:
			child.queue_free()
