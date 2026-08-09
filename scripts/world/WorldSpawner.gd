extends Node2D
class_name WorldSpawner

const ABSORBABLE_SCENE := preload("res://scenes/Absorbable.tscn")

@export var config: GameConfig
@export var run_state: RunState
@export var player: Node2D

var rng := RandomNumberGenerator.new()
var material_tiers := [
	{"name": "Dust", "size": 0.5, "radius": 4.0, "color": Color("d9c8a9")},
	{"name": "Sand", "size": 1.0, "radius": 6.0, "color": Color("e7d37a")},
	{"name": "Dirt", "size": 2.0, "radius": 8.0, "color": Color("8b5a2b")},
	{"name": "Leaf", "size": 4.0, "radius": 10.0, "color": Color("69b34c")},
	{"name": "Stone", "size": 8.0, "radius": 13.0, "color": Color("8e99a4")},
	{"name": "Rock", "size": 18.0, "radius": 18.0, "color": Color("6b7078")},
	{"name": "Tree", "size": 42.0, "radius": 25.0, "color": Color("2f7d32")},
	{"name": "Building", "size": 120.0, "radius": 40.0, "color": Color("6272a4")},
	{"name": "Mountain", "size": 420.0, "radius": 72.0, "color": Color("7f8c8d")}
]

var hazard_tiers := [
	{"name": "Thorns", "size": 1.25, "radius": 9.0, "color": Color("d81b60"), "damage": 12.0},
	{"name": "Fire", "size": 6.0, "radius": 14.0, "color": Color("ff5722"), "damage": 18.0},
	{"name": "Spikes", "size": 24.0, "radius": 21.0, "color": Color("b71c1c"), "damage": 28.0},
	{"name": "Void", "size": 95.0, "radius": 34.0, "color": Color("4a148c"), "damage": 42.0}
]

func _ready() -> void:
	rng.randomize()

func _process(_delta: float) -> void:
	if player == null:
		return
	_trim_far_objects()
	var target_pickups := _target_pickup_count()
	while get_child_count() < target_pickups:
		_spawn_pickup()

func _spawn_pickup() -> void:
	var tier := _choose_spawn_tier()
	var pickup := ABSORBABLE_SCENE.instantiate() as Absorbable
	var angle := rng.randf_range(0.0, TAU)
	var spawn_radius := _current_spawn_radius()
	var distance := rng.randf_range(spawn_radius * 0.25, spawn_radius)
	pickup.global_position = player.global_position + Vector2.from_angle(angle) * distance
	pickup.configure({
		"size": tier["size"] * rng.randf_range(0.85, 1.2),
		"value": rng.randf_range(0.8, 1.4),
		"score": maxi(1, int(tier["size"] * 5.0)),
		"currency": maxi(1, int(sqrt(tier["size"]))),
		"radius": tier["radius"],
		"color": tier["color"],
		"name": tier["name"],
		"hazard": tier.get("hazard", false),
		"damage": tier.get("damage", 0.0),
	})
	add_child(pickup)

func _choose_spawn_tier() -> Dictionary:
	if rng.randf() < _hazard_chance():
		return _choose_hazard_tier()
	return _choose_material_tier()

func _choose_material_tier() -> Dictionary:
	var reachable_size := run_state.size * 1.35
	var candidates := material_tiers.filter(func(tier: Dictionary) -> bool: return tier["size"] <= reachable_size)
	if candidates.is_empty():
		return material_tiers[0]
	if rng.randf() < 0.18 and candidates.size() < material_tiers.size():
		return material_tiers[candidates.size()]
	return candidates[rng.randi_range(0, candidates.size() - 1)]

func _choose_hazard_tier() -> Dictionary:
	var reachable_size := maxf(run_state.size, 1.0) * 2.2
	var candidates := hazard_tiers.filter(func(tier: Dictionary) -> bool: return tier["size"] <= reachable_size)
	if candidates.is_empty():
		return hazard_tiers[0]
	var hazard := candidates[rng.randi_range(0, candidates.size() - 1)].duplicate()
	hazard["hazard"] = true
	return hazard

func _hazard_chance() -> float:
	return clampf(0.12 + log(maxf(run_state.size, 1.0)) * 0.025, 0.12, 0.28)

func _scale_view_factor() -> float:
	return pow(maxf(run_state.size, 1.0), 0.22)

func _current_spawn_radius() -> float:
	return config.spawn_radius * _scale_view_factor()

func _current_despawn_radius() -> float:
	return config.despawn_radius * _scale_view_factor()

func _target_pickup_count() -> int:
	return mini(config.max_pickups_cap, int(config.max_pickups * pow(_scale_view_factor(), 1.25)))

func get_legend_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for tier in material_tiers:
		entries.append({"name": tier["name"], "color": tier["color"]})
	for tier in hazard_tiers:
		entries.append({"name": tier["name"], "color": tier["color"]})
	return entries

func _trim_far_objects() -> void:
	var despawn_radius := _current_despawn_radius()
	for child in get_children():
		if child is Node2D and child.global_position.distance_to(player.global_position) > despawn_radius:
			child.queue_free()
