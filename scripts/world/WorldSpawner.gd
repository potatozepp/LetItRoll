extends Node2D
class_name WorldSpawner

const ABSORBABLE_SCENE := preload("res://scenes/Absorbable.tscn")
const BATCH_SPAWN_CHANCE := 0.16
const BATCH_MIN_SIZE := 6

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
	{"name": "Mountain", "size": 420.0, "radius": 72.0, "color": Color("7f8c8d")},
	{"name": "Sea", "size": 900.0, "radius": 105.0, "color": Color("1976d2")},
	{"name": "Metro", "size": 1700.0, "radius": 145.0, "color": Color("455a64")},
	{"name": "Range", "size": 3200.0, "radius": 205.0, "color": Color("5d6d7e")}
]

var hazard_tiers := [
	{"name": "Thorns", "size": 1.25, "radius": 9.0, "color": Color("d81b60"), "damage": 12.0, "safe_size": 18.0},
	{"name": "Fire", "size": 6.0, "radius": 14.0, "color": Color("ff5722"), "damage": 18.0, "safe_size": 55.0},
	{"name": "Spikes", "size": 24.0, "radius": 21.0, "color": Color("b71c1c"), "damage": 28.0, "safe_size": 135.0},
	{"name": "Magma", "size": 170.0, "radius": 46.0, "color": Color("e65100"), "damage": 38.0},
	{"name": "Maelstrom", "size": 620.0, "radius": 78.0, "color": Color("006064"), "damage": 52.0},
	{"name": "Void", "size": 1500.0, "radius": 118.0, "color": Color("4a148c"), "damage": 68.0},
	{"name": "Singularity", "size": 4200.0, "radius": 170.0, "color": Color("120a3d"), "damage": 90.0}
]

var batch_templates := [
	{"name": "Grove", "tier": "Tree", "min_size": 25.0, "count_min": 7, "count_max": 14, "spread": 230.0, "loot_bonus": 0.72},
	{"name": "Small City", "tier": "Building", "min_size": 85.0, "count_min": 8, "count_max": 15, "spread": 310.0, "loot_bonus": 0.62},
	{"name": "Mountain Range", "tier": "Mountain", "min_size": 300.0, "count_min": 6, "count_max": 12, "spread": 520.0, "loot_bonus": 0.58},
	{"name": "Big Sea", "tier": "Sea", "min_size": 680.0, "count_min": 5, "count_max": 10, "spread": 680.0, "loot_bonus": 0.52},
	{"name": "Thorny Loot Patch", "tier": "Rock", "hazard": "Thorns", "min_size": 16.0, "count_min": 6, "count_max": 11, "hazard_count": 7, "spread": 260.0, "loot_bonus": 0.9},
]

func _ready() -> void:
	rng.randomize()

func _process(_delta: float) -> void:
	if player == null:
		return
	_trim_far_objects()
	var target_pickups := _target_pickup_count()
	while get_child_count() < target_pickups:
		if rng.randf() < BATCH_SPAWN_CHANCE and get_child_count() + BATCH_MIN_SIZE < target_pickups:
			_spawn_batch(target_pickups - get_child_count())
		else:
			_spawn_pickup()

func _spawn_pickup(position := Vector2.INF, forced_tier := {}) -> void:
	var tier := forced_tier if not forced_tier.is_empty() else _choose_spawn_tier()
	var pickup := ABSORBABLE_SCENE.instantiate() as Absorbable
	pickup.global_position = position if position != Vector2.INF else _random_spawn_position()
	pickup.configure({
		"size": tier["size"] * rng.randf_range(0.85, 1.2),
		"value": rng.randf_range(0.8, 1.4),
		"score": maxi(1, int(tier["size"] * 5.0)),
		"currency": _coin_value_for(tier),
		"radius": tier["radius"],
		"color": tier["color"],
		"name": tier["name"],
		"hazard": tier.get("hazard", false),
		"damage": tier.get("damage", 0.0),
		"safe_size": tier.get("safe_size", 0.0),
	})
	add_child(pickup)

func _spawn_batch(available_slots: int) -> void:
	var template := _choose_batch_template()
	if template.is_empty():
		_spawn_pickup()
		return
	var center := _random_spawn_position()
	var count = mini(available_slots, rng.randi_range(template["count_min"], template["count_max"]))
	var spread := float(template["spread"]) * _scale_view_factor()
	var tier := _material_by_name(template["tier"])
	for index in range(count):
		var offset := Vector2.from_angle(rng.randf_range(0.0, TAU)) * rng.randf_range(spread * 0.15, spread)
		var cluster_tier := tier.duplicate()
		cluster_tier["currency_multiplier"] = template.get("loot_bonus", 0.6)
		_spawn_pickup(center + offset, cluster_tier)
	if template.has("hazard"):
		var hazard := _hazard_by_name(template["hazard"])
		if not hazard.is_empty():
			hazard["hazard"] = true
			var hazard_count := mini(available_slots - count, int(template.get("hazard_count", 0)))
			for index in range(maxi(0, hazard_count)):
				var offset := Vector2.from_angle(rng.randf_range(0.0, TAU)) * rng.randf_range(spread * 0.1, spread * 0.9)
				_spawn_pickup(center + offset, hazard)

func _random_spawn_position() -> Vector2:
	var angle := rng.randf_range(0.0, TAU)
	var spawn_radius := _current_spawn_radius()
	var inner_radius := spawn_radius * clampf(0.2 + log(maxf(run_state.size, 1.0)) * 0.015, 0.2, 0.38)
	var distance := rng.randf_range(inner_radius, spawn_radius)
	return player.global_position + Vector2.from_angle(angle) * distance

func _choose_spawn_tier() -> Dictionary:
	if rng.randf() < _hazard_chance():
		return _choose_hazard_tier()
	return _choose_material_tier()

func _choose_material_tier() -> Dictionary:
	var reachable_size := run_state.size * 1.35
	var candidates := material_tiers.filter(func(tier: Dictionary) -> bool: return tier["size"] <= reachable_size)
	if candidates.is_empty():
		return material_tiers[0]
	if rng.randf() < 0.12 and candidates.size() < material_tiers.size():
		return material_tiers[candidates.size()]
	var roll := rng.randf()
	var index := rng.randi_range(0, candidates.size() - 1)
	if roll < 0.45:
		index = maxi(0, candidates.size() - 2 - rng.randi_range(0, 1))
	return candidates[index]

func _choose_hazard_tier() -> Dictionary:
	var reachable_size := maxf(run_state.size, 1.0) * 2.0
	var candidates := hazard_tiers.filter(func(tier: Dictionary) -> bool: return tier["size"] <= reachable_size)
	if candidates.is_empty():
		return hazard_tiers[0]
	var hazard = candidates[rng.randi_range(maxi(0, candidates.size() - 3), candidates.size() - 1)].duplicate()
	hazard["hazard"] = true
	return hazard

func _choose_batch_template() -> Dictionary:
	var candidates := batch_templates.filter(func(template: Dictionary) -> bool: return run_state.size >= template["min_size"])
	if candidates.is_empty():
		return {}
	return candidates[rng.randi_range(0, candidates.size() - 1)]

func _material_by_name(tier_name: String) -> Dictionary:
	for tier in material_tiers:
		if tier["name"] == tier_name:
			return tier.duplicate()
	return material_tiers[0].duplicate()

func _hazard_by_name(tier_name: String) -> Dictionary:
	for tier in hazard_tiers:
		if tier["name"] == tier_name:
			return tier.duplicate()
	return {}

func _coin_value_for(tier: Dictionary) -> int:
	if tier.get("hazard", false):
		return 0
	var scaled_value := sqrt(tier["size"]) * 0.45 * tier.get("currency_multiplier", 1.0)
	var coins := int(floor(scaled_value))
	var fractional_chance := scaled_value - float(coins)
	if rng.randf() < fractional_chance:
		coins += 1
	return maxi(0, coins)

func _hazard_chance() -> float:
	return clampf(0.10 + log(maxf(run_state.size, 1.0)) * 0.018, 0.10, 0.24)

func _scale_view_factor() -> float:
	return pow(maxf(run_state.size, 1.0), 0.28)

func _current_spawn_radius() -> float:
	return config.spawn_radius * _scale_view_factor()

func _current_despawn_radius() -> float:
	return config.despawn_radius * _scale_view_factor()

func _target_pickup_count() -> int:
	return mini(config.max_pickups_cap, int(config.max_pickups * pow(_scale_view_factor(), 1.05)))

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
