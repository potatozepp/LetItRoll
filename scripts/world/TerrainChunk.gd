extends Node2D
class_name TerrainChunk

const CELL_SIZE := 32.0
const CELLS_PER_SIDE := 16
const CHUNK_SIZE := CELL_SIZE * CELLS_PER_SIDE

var chunk_coord: Vector2i
var cells: Array[Dictionary] = []
var exposed_layer_indices := {}
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
			var cell_center := Vector2((x + 0.5) * CELL_SIZE, (y + 0.5) * CELL_SIZE)
			if cell_center.distance_to(local_center) > radius:
				continue
			var cell := cells[y * CELLS_PER_SIDE + x]
			var layers: Array = cell["layers"]
			var layer_index := int(exposed_layer_indices.get(key, 0))
			if layer_index >= layers.size():
				continue
			var layer: Dictionary = layers[layer_index]
			if not growth_mode.can_absorb(player_mass, layer["mass"], config):
				continue
			exposed_layer_indices[key] = layer_index + 1
			result["growth"] += growth_mode.growth_for(layer["mass"], layer["value"], config)
			result["score"] += int(layer["mass"] * 8.0)
			result["currency"] += maxi(1, int(sqrt(layer["mass"])))
			result["cells"] += 1
	if result["cells"] > 0:
		queue_redraw()
	return result

func is_empty() -> bool:
	return exposed_layer_indices.size() >= CELLS_PER_SIDE * CELLS_PER_SIDE

func _generate_cells() -> void:
	cells.clear()
	for y in range(CELLS_PER_SIDE):
		for x in range(CELLS_PER_SIDE):
			var world_cell := chunk_coord * CELLS_PER_SIDE + Vector2i(x, y)
			var distance_from_origin := Vector2(world_cell).length()
			var tier_bias := clampf(distance_from_origin / 120.0, 0.0, 6.0)
			var surface_mass := maxf(0.35, 0.55 + tier_bias * 0.35 + rng.randf_range(-0.18, 0.3))
			var layers := []
			for layer_index in range(5):
				var mass := surface_mass * pow(1.95, layer_index) + tier_bias * float(layer_index) * 0.35
				layers.append({"mass": mass, "value": rng.randf_range(0.8, 1.25), "color": _color_for_mass(mass, layer_index)})
			cells.append({"layers": layers})

func _draw() -> void:
	for y in range(CELLS_PER_SIDE):
		for x in range(CELLS_PER_SIDE):
			var key := Vector2i(x, y)
			var cell := cells[y * CELLS_PER_SIDE + x]
			var layers: Array = cell["layers"]
			var layer_index := int(exposed_layer_indices.get(key, 0))
			var color := Color("141414")
			if layer_index < layers.size():
				color = layers[layer_index]["color"]
			draw_rect(Rect2(Vector2(x, y) * CELL_SIZE, Vector2.ONE * CELL_SIZE), color, true)
			if layer_index > 0 and layer_index < layers.size():
				draw_rect(Rect2(Vector2(x, y) * CELL_SIZE + Vector2.ONE * 3.0, Vector2.ONE * (CELL_SIZE - 6.0)), color.lightened(0.12), false, 2.0)

func _color_for_mass(mass: float, layer_index: int = 0) -> Color:
	if mass < 1.0:
		return Color("ead8b3").darkened(layer_index * 0.06)
	if mass < 2.5:
		return Color("b98555").darkened(layer_index * 0.05)
	if mass < 5.0:
		return Color("6f7d5a").darkened(layer_index * 0.05)
	return Color("535a66").darkened(layer_index * 0.04)
