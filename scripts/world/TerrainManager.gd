extends Node2D
class_name TerrainManager

const TerrainChunkScene := preload("res://scripts/world/TerrainChunk.gd")
const BASE_ACTIVE_RADIUS_CHUNKS := 3
const MAX_ACTIVE_RADIUS_CHUNKS := 7

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

func _process(_delta: float) -> void:
	if player == null:
		return
	_update_chunks()

func consume_at(world_position: Vector2, radius: float, player_mass: float, growth_mode: GrowthMode) -> void:
	var center_coord := _chunk_coord_for(world_position)

	# Terrain can provide at most 1% growth per physics tick.
	var growth_rate := 0.002 / pow(maxf(player_mass, 1.0), 0.15)
	var growth_budget := maxf(0.02, player_mass * growth_rate)
	
	for y in range(center_coord.y - 1, center_coord.y + 2):
		for x in range(center_coord.x - 1, center_coord.x + 2):
			if growth_budget <= 0.0:
				return

			var coord := Vector2i(x, y)
			var chunk := chunks.get(coord) as TerrainChunk
			if chunk == null:
				continue

			var result := chunk.consume_circle(
				world_position,
				radius,
				player_mass,
				growth_mode,
				config,
				growth_budget
			)

			if result["cells"] > 0:
				run_state.add_growth(
					result["growth"],
					result["score"],
					result["currency"]
				)

				growth_budget -= result["growth"]

func _update_chunks() -> void:
	var center := _chunk_coord_for(player.global_position)
	var active_radius := _active_radius_chunks()
	var keep_radius := active_radius + 2
	var needed := {}
	for y in range(center.y - active_radius, center.y + active_radius + 1):
		for x in range(center.x - active_radius, center.x + active_radius + 1):
			var coord := Vector2i(x, y)
			needed[coord] = true
			if not chunks.has(coord):
				_create_chunk(coord)
	for coord in chunks.keys():
		var chunk := chunks[coord] as TerrainChunk
		var inside_keep = abs(coord.x - center.x) <= keep_radius and abs(coord.y - center.y) <= keep_radius
		if inside_keep:
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
	var size_factor := pow(maxf(run_state.size, 1.0), 0.22)
	return clampi(int(ceil(3.0 + size_factor)), BASE_ACTIVE_RADIUS_CHUNKS, MAX_ACTIVE_RADIUS_CHUNKS)
