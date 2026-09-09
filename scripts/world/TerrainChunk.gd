extends Node2D
class_name TerrainChunk

const TILE_RADIUS := 28.0
const TILE_WIDTH := sqrt(3.0) * TILE_RADIUS
const TILE_ROW_HEIGHT := TILE_RADIUS * 1.5
const TILES_PER_SIDE := 8
const CHUNK_SIZE := TILE_WIDTH * TILES_PER_SIDE

var chunk_coord: Vector2i
var tiles: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()

func configure(coord: Vector2i, seed_value: int) -> void:
	chunk_coord = coord
	position = Vector2(coord) * CHUNK_SIZE
	rng.seed = hash("hex:%s:%s:%s" % [seed_value, coord.x, coord.y])
	_generate_tiles()
	queue_redraw()

func collect_circle(world_center: Vector2, radius: float, ball_size: float, maximum_volume: float) -> Array[Dictionary]:
	var collected: Array[Dictionary] = []
	var local_center := to_local(world_center)
	var remaining := maximum_volume
	for tile in tiles:
		if remaining <= 0.001:
			break
		if tile["amount"] <= 0.001 or tile["material"] == "water":
			continue
		if Vector2(tile["center"]).distance_to(local_center) > radius + TILE_RADIUS * 0.55:
			continue
		var material_id := String(tile["material"])
		if not MaterialCatalog.can_collect(material_id, ball_size):
			continue
		var definition := MaterialCatalog.get_definition(material_id)
		var amount := minf(float(tile["amount"]), remaining, float(definition["collect_rate"]))
		if amount <= 0.0:
			continue
		tile["amount"] = float(tile["amount"]) - amount
		remaining -= amount
		collected.append({"material": material_id, "volume": amount, "position": to_global(tile["center"])})
	if not collected.is_empty():
		queue_redraw()
	return collected

func water_strength_at(world_position: Vector2, radius: float) -> float:
	var local_center := to_local(world_position)
	var strength := 0.0
	for tile in tiles:
		if tile["material"] == "water" and Vector2(tile["center"]).distance_to(local_center) < radius + TILE_RADIUS * 0.65:
			strength = maxf(strength, 1.0)
	return strength

func _generate_tiles() -> void:
	tiles.clear()
	for row in range(TILES_PER_SIDE):
		for column in range(TILES_PER_SIDE):
			var center := Vector2((column + 0.5 + (0.5 if row % 2 else 0.0)) * TILE_WIDTH, (row + 0.5) * TILE_ROW_HEIGHT)
			var global_tile := chunk_coord * TILES_PER_SIDE + Vector2i(column, row)
			var material := _material_for(global_tile)
			var amount := 0.0 if material == "water" else (0.55 if material in ["grass", "dirt", "sand"] else 1.5)
			tiles.append({"center": center, "material": material, "amount": amount})

func _material_for(global_tile: Vector2i) -> String:
	# A deliberately constrained starter island: concrete dominates and the center
	# contains only tiny dirt/grass patches. The rest remains data-driven terrain.
	if abs(global_tile.x) <= 2 and abs(global_tile.y) <= 2:
		var starter := {
			Vector2i(-1, -1): "dirt", Vector2i(0, -1): "grass", Vector2i(1, -1): "dirt",
			Vector2i(-1, 0): "grass", Vector2i(0, 0): "concrete", Vector2i(1, 0): "grass",
			Vector2i(-1, 1): "dirt", Vector2i(0, 1): "grass", Vector2i(1, 1): "dirt",
		}
		return starter.get(global_tile, "concrete")
	var distance := Vector2(global_tile).length()
	if distance > 14.0 and rng.randf() < 0.08:
		return "water"
	if distance < 7.0:
		return "concrete"
	var choices := ["concrete", "dirt", "grass", "sand", "gravel", "stone", "asphalt", "rock"]
	var index := clampi(int(distance / 8.0) + rng.randi_range(-1, 1), 0, choices.size() - 1)
	return choices[index]

func _draw() -> void:
	for tile in tiles:
		var material_id := String(tile["material"])
		var definition := MaterialCatalog.get_definition(material_id)
		var amount_ratio := clampf(float(tile["amount"]) / 0.55, 0.0, 1.0)
		var color: Color = definition["color"]
		if material_id != "water" and amount_ratio < 0.98:
			color = color.darkened(0.32 + (1.0 - amount_ratio) * 0.35)
		var points := PackedVector2Array()
		for point_index in range(6):
			points.append(Vector2(tile["center"]) + Vector2.from_angle(TAU * point_index / 6.0 + PI / 6.0) * TILE_RADIUS * 0.92)
		draw_colored_polygon(points, color)
		draw_polyline(points + PackedVector2Array([points[0]]), Color("1a2024"), 1.5)
		if material_id in ["grass", "dirt"] and float(tile["amount"]) > 0.01:
			draw_circle(Vector2(tile["center"]) + Vector2(-6, -3), 3.5, definition["accent"])
			draw_circle(Vector2(tile["center"]) + Vector2(7, 5), 2.5, definition["accent"])
