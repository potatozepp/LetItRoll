extends Node2D
class_name TerrainChunk

const CELL_SIZE := 32.0
const CELLS_PER_SIDE := 16
const CHUNK_SIZE := CELL_SIZE * CELLS_PER_SIDE

var chunk_coord: Vector2i
var cells: Array[Dictionary] = []
var consumed_cells := {}
var rng := RandomNumberGenerator.new()

func configure(coord: Vector2i, seed_value: int) -> void:
	chunk_coord = coord
	position = Vector2(coord) * CHUNK_SIZE
	rng.seed = hash("%s:%s:%s" % [seed_value, coord.x, coord.y])
	_generate_cells()
	queue_redraw()

func consume_circle(world_center: Vector2, radius: float, player_mass: float, growth_mode: GrowthMode, config: GameConfig) -> Dictionary:
	var local_center := to_local(world_center)
	var min_x := clampi(floori((local_center.x - radius) / CELL_SIZE), 0, CELLS_PER_SIDE - 1)
	var max_x := clampi(floori((local_center.x + radius) / CELL_SIZE), 0, CELLS_PER_SIDE - 1)
	var min_y := clampi(floori((local_center.y - radius) / CELL_SIZE), 0, CELLS_PER_SIDE - 1)
	var max_y := clampi(floori((local_center.y + radius) / CELL_SIZE), 0, CELLS_PER_SIDE - 1)
	var result := {"growth": 0.0, "score": 0, "currency": 0, "cells": 0}

	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var key := Vector2i(x, y)
			if consumed_cells.has(key) and Time.get_ticks_msec() - int(consumed_cells[key]) < int(config.consumed_terrain_cooldown * 1000.0):
				continue
			var cell_center := Vector2((x + 0.5) * CELL_SIZE, (y + 0.5) * CELL_SIZE)
			if cell_center.distance_to(local_center) > radius:
				continue
			var cell := cells[y * CELLS_PER_SIDE + x]
			if not growth_mode.can_absorb(player_mass, cell["mass"], config):
				continue
			var was_consumed := consumed_cells.has(key)
			consumed_cells[key] = Time.get_ticks_msec()
			var value_multiplier := config.consumed_terrain_value_multiplier if was_consumed else 1.0
			result["growth"] += growth_mode.growth_for(cell["mass"], cell["value"] * value_multiplier, config)
			result["score"] += int(cell["mass"] * 8.0 * value_multiplier)
			result["currency"] += maxi(1, int(sqrt(cell["mass"]) * value_multiplier))
			result["cells"] += 1
	if result["cells"] > 0:
		queue_redraw()
	return result

func is_empty() -> bool:
	return consumed_cells.size() >= CELLS_PER_SIDE * CELLS_PER_SIDE

func _generate_cells() -> void:
	cells.clear()
	for y in range(CELLS_PER_SIDE):
		for x in range(CELLS_PER_SIDE):
			var world_cell := chunk_coord * CELLS_PER_SIDE + Vector2i(x, y)
			var distance_from_origin := Vector2(world_cell).length()
			var tier_bias := clampf(distance_from_origin / 120.0, 0.0, 6.0)
			var mass := maxf(0.35, 0.6 + tier_bias + rng.randf_range(-0.25, 0.45))
			cells.append({"mass": mass, "value": rng.randf_range(0.8, 1.25), "color": _color_for_mass(mass)})

func _draw() -> void:
	for y in range(CELLS_PER_SIDE):
		for x in range(CELLS_PER_SIDE):
			var cell := cells[y * CELLS_PER_SIDE + x]
			var color: Color = cell["color"]
			if consumed_cells.has(Vector2i(x, y)):
				color = color.darkened(0.45)
			draw_rect(Rect2(Vector2(x, y) * CELL_SIZE, Vector2.ONE * CELL_SIZE), color, true)

func _color_for_mass(mass: float) -> Color:
	if mass < 1.0:
		return Color("d8c7a3")
	if mass < 2.5:
		return Color("a8794a")
	if mass < 5.0:
		return Color("65724f")
	return Color("545862")
