extends Node2D

@onready var run_state: RunState = $RunState
@onready var config: GameConfig = preload("res://scripts/core/GameConfig.gd").new()
@onready var growth_mode: GrowthMode = preload("res://scripts/modes/GrowthMode.gd").new()
@onready var player: PlayerBall = $PlayerBall
@onready var camera: ScaleCamera = $ScaleCamera
@onready var terrain_manager: TerrainManager = $TerrainManager
@onready var spawner: WorldSpawner = $WorldSpawner
@onready var hud: Hud = $Hud

var upgrades := {"speed": 0, "health": 0, "stickiness": 0}
var total_currency := 0
var game_started := false
var game_over := false

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
	hud.setup(run_state, spawner.get_legend_entries())
	hud.pause_requested.connect(_pause_game)
	hud.resume_requested.connect(_resume_game)
	hud.main_menu_requested.connect(_show_main_menu)
	hud.start_requested.connect(_start_game)
	hud.upgrade_requested.connect(_buy_upgrade)
	run_state.run_ended.connect(_on_run_ended)
	_apply_upgrades()
	hud.show_main_menu(total_currency, upgrades)
	get_tree().paused = true

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and game_started and not game_over:
		if get_tree().paused:
			_resume_game()
		else:
			_pause_game()

func _process(delta: float) -> void:
	if game_started and not get_tree().paused and not game_over:
		run_state.elapsed_time += delta

func _start_game() -> void:
	game_started = true
	game_over = false
	get_tree().paused = false
	_apply_upgrades()
	run_state.reset(config)
	player.global_position = Vector2.ZERO
	player.velocity = Vector2.ZERO
	player.reset_mana()
	player._update_scale()
	hud.show_game()

func _pause_game() -> void:
	if not game_started or game_over:
		return
	get_tree().paused = true
	hud.show_pause_menu()

func _resume_game() -> void:
	if not game_started or game_over:
		return
	get_tree().paused = false
	hud.show_game()

func _show_main_menu() -> void:
	get_tree().paused = true
	game_started = false
	hud.show_main_menu(total_currency, upgrades)

func _on_run_ended(summary: Dictionary) -> void:
	if game_over:
		return
	game_over = true
	total_currency += int(summary.get("currency", 0))
	get_tree().paused = true
	hud.show_game_over(summary, total_currency, upgrades)

func _buy_upgrade(upgrade_name: String) -> void:
	if not upgrades.has(upgrade_name):
		return
	var cost := _upgrade_cost(upgrade_name)
	if total_currency < cost:
		return
	total_currency -= cost
	upgrades[upgrade_name] += 1
	_apply_upgrades()
	hud.show_main_menu(total_currency, upgrades)

func _upgrade_cost(upgrade_name: String) -> int:
	return 25 + int(upgrades.get(upgrade_name, 0)) * 20

func _apply_upgrades() -> void:
	config.base_speed = 275.0 + float(upgrades["speed"]) * 24.0
	config.start_health = 100.0 + float(upgrades["health"]) * 20.0
	config.attraction_radius = 72.0 + float(upgrades["stickiness"]) * 14.0
