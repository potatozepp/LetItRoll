extends Node2D
class_name TerrainManager

const TerrainChunkScene := preload("res://scripts/world/TerrainChunk.gd")
const BASE_ACTIVE_RADIUS_CHUNKS := 2
const MAX_ACTIVE_RADIUS_CHUNKS := 5

@export var config: GameConfig
@export var run_state: RunState
@export var player: Node2D
@export var world_seed: int = 1977

var chunks := {}

func reset_progress() -> void:
	for chunk in chunks.values():
		if is_instance_valid(chunk):
			chunk.queue_free()
	chunks.clear()
	if player != null:
		_update_chunks()

func _process(_delta: float) -> void:
	if player != null:
		_update_chunks()

# Terrain is sampled as finite hex tiles. This returns physical material records;
# it intentionally never updates RunState or creates invisible growth.
func collect_at(world_position: Vector2, radius: float, ball_size: float, capacity_left: float) -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	if capacity_left <= 0.001:
		return records
	var center_coord := _chunk_coord_for(world_position)
	var remaining := capacity_left
	for y in range(center_coord.y - 1, center_coord.y + 2):
		for x in range(center_coord.x - 1, center_coord.x + 2):
			if remaining <= 0.001:
				return records
			var chunk := chunks.get(Vector2i(x, y)) as TerrainChunk
			if chunk == null:
				continue
			var result := chunk.collect_circle(world_position, radius, ball_size, remaining)
			for record in result:
				records.append(record)
				remaining -= float(record["volume"])
	return records

func water_strength_at(world_position: Vector2, radius: float) -> float:
	var center_coord := _chunk_coord_for(world_position)
	var strength := 0.0
	for y in range(center_coord.y - 1, center_coord.y + 2):
		for x in range(center_coord.x - 1, center_coord.x + 2):
			var chunk := chunks.get(Vector2i(x, y)) as TerrainChunk
			if chunk != null:
				strength = maxf(strength, chunk.water_strength_at(world_position, radius))
	return strength

func _update_chunks() -> void:
	var center := _chunk_coord_for(player.global_position)
	var active_radius := _active_radius_chunks()
	var keep_radius := active_radius + 1
	var needed := {}
	for y in range(center.y - active_radius, center.y + active_radius + 1):
		for x in range(center.x - active_radius, center.x + active_radius + 1):
			var coord := Vector2i(x, y)
			needed[coord] = true
			if not chunks.has(coord):
				_create_chunk(coord)
	for coord in chunks.keys():
		var chunk := chunks[coord] as TerrainChunk
		if abs(coord.x - center.x) <= keep_radius and abs(coord.y - center.y) <= keep_radius:
			chunk.visible = needed.has(coord)
		else:
			chunks.erase(coord)
			chunk.queue_free()

func _create_chunk(coord: Vector2i) -> void:
	var chunk := TerrainChunkScene.new() as TerrainChunk
	chunk.configure(coord, world_seed)
	chunks[coord] = chunk
	add_child(chunk)

func _chunk_coord_for(world_position: Vector2) -> Vector2i:
	return Vector2i(floori(world_position.x / TerrainChunk.CHUNK_SIZE), floori(world_position.y / TerrainChunk.CHUNK_SIZE))

func _active_radius_chunks() -> int:
	return clampi(int(ceil(2.0 + log(maxf(run_state.size, 1.0)) * 0.25)), BASE_ACTIVE_RADIUS_CHUNKS, MAX_ACTIVE_RADIUS_CHUNKS)
