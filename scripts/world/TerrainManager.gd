extends Node2D
class_name TerrainManager

const TerrainChunkScene := preload("res://scripts/world/TerrainChunk.gd")
const ACTIVE_RADIUS_CHUNKS := 2
const DRAW_RADIUS_CHUNKS := 4

@export var config: GameConfig
@export var run_state: RunState
@export var player: Node2D
@export var world_seed: int = 1977

var chunks := {}

func _process(_delta: float) -> void:
	if player == null:
		return
	_update_chunks()

func consume_at(world_position: Vector2, radius: float, player_mass: float, growth_mode: GrowthMode) -> void:
	var center_coord := _chunk_coord_for(world_position)
	for y in range(center_coord.y - 1, center_coord.y + 2):
		for x in range(center_coord.x - 1, center_coord.x + 2):
			var coord := Vector2i(x, y)
			var chunk := chunks.get(coord) as TerrainChunk
			if chunk == null:
				continue
			var result := chunk.consume_circle(world_position, radius, player_mass, growth_mode, config)
			if result["cells"] > 0:
				run_state.add_growth(result["growth"], result["score"], result["currency"])

func _update_chunks() -> void:
	var center := _chunk_coord_for(player.global_position)
	var needed := {}
	for y in range(center.y - ACTIVE_RADIUS_CHUNKS, center.y + ACTIVE_RADIUS_CHUNKS + 1):
		for x in range(center.x - ACTIVE_RADIUS_CHUNKS, center.x + ACTIVE_RADIUS_CHUNKS + 1):
			var coord := Vector2i(x, y)
			needed[coord] = true
			if not chunks.has(coord):
				_create_chunk(coord)
	for coord in chunks.keys():
		var chunk := chunks[coord] as TerrainChunk
		chunk.visible = abs(coord.x - center.x) <= DRAW_RADIUS_CHUNKS and abs(coord.y - center.y) <= DRAW_RADIUS_CHUNKS

func _create_chunk(coord: Vector2i) -> void:
	var chunk := TerrainChunkScene.new() as TerrainChunk
	chunk.configure(coord, world_seed)
	chunks[coord] = chunk
	add_child(chunk)

func _chunk_coord_for(world_position: Vector2) -> Vector2i:
	return Vector2i(floori(world_position.x / TerrainChunk.CHUNK_SIZE), floori(world_position.y / TerrainChunk.CHUNK_SIZE))
