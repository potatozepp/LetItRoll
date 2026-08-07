extends Node2D

@onready var run_state: RunState = $RunState
@onready var config: GameConfig = preload("res://scripts/core/GameConfig.gd").new()
@onready var growth_mode: GrowthMode = preload("res://scripts/modes/GrowthMode.gd").new()
@onready var player: PlayerBall = $PlayerBall
@onready var camera: ScaleCamera = $ScaleCamera
@onready var terrain_manager: TerrainManager = $TerrainManager
@onready var spawner: WorldSpawner = $WorldSpawner
@onready var hud: Hud = $Hud

func _ready() -> void:
	player.config = config
	player.run_state = run_state
	player.growth_mode = growth_mode
	player.terrain_manager = terrain_manager
	camera.config = config
	camera.run_state = run_state
	camera.target = player
	terrain_manager.config = config
	terrain_manager.run_state = run_state
	terrain_manager.player = player
	spawner.config = config
	spawner.run_state = run_state
	spawner.player = player
	hud.setup(run_state)
	run_state.reset(config)
	player._update_scale()

func _process(delta: float) -> void:
	run_state.elapsed_time += delta
