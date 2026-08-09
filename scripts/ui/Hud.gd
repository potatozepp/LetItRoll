extends CanvasLayer
class_name Hud

signal pause_requested
signal resume_requested
signal main_menu_requested
signal start_requested
signal upgrade_requested(upgrade_name: String)

var run_state: RunState

@onready var size_label: Label = %SizeLabel
@onready var score_label: Label = %ScoreLabel
@onready var currency_label: Label = %CurrencyLabel
@onready var health_label: Label = %HealthLabel
@onready var mana_label: Label = %ManaLabel
@onready var legend_list: VBoxContainer = %LegendList
@onready var pause_button: Button = %PauseButton
@onready var menu_layer: PanelContainer = %MenuLayer
@onready var menu_title: Label = %MenuTitle
@onready var menu_body: VBoxContainer = %MenuBody

func setup(state: RunState, legend_entries: Array[Dictionary] = []) -> void:
	run_state = state
	run_state.size_changed.connect(_on_size_changed)
	run_state.score_changed.connect(func(value: int) -> void: score_label.text = "Score: %d" % value)
	run_state.currency_changed.connect(func(value: int) -> void: currency_label.text = "Coins: %d" % value)
	run_state.health_changed.connect(func(value: float) -> void: health_label.text = "Health: %d" % int(value))
	run_state.mana_changed.connect(func(value: float, max_value: float) -> void: mana_label.text = "Mana: %d/%d" % [int(value), int(max_value)])
	pause_button.pressed.connect(func() -> void: pause_requested.emit())
	_on_size_changed(run_state.size)
	_populate_legend(legend_entries)

func show_game() -> void:
	pause_button.visible = true
	menu_layer.visible = false

func show_pause_menu() -> void:
	pause_button.visible = false
	_show_menu("Paused")
	_add_button("Resume", func() -> void: resume_requested.emit())
	_add_button("Main Menu", func() -> void: main_menu_requested.emit())

func show_main_menu(total_currency: int, upgrades: Dictionary) -> void:
	pause_button.visible = false
	_show_menu("Let It Roll")
	_add_label("Coins: %d" % total_currency)
	_add_button("Play", func() -> void: start_requested.emit())
	_add_label("Upgrades")
	_add_upgrade_button("speed", "Speed", total_currency, upgrades)
	_add_upgrade_button("health", "Health", total_currency, upgrades)
	_add_upgrade_button("stickiness", "Stickiness", total_currency, upgrades)

func show_game_over(summary: Dictionary, total_currency: int, upgrades: Dictionary) -> void:
	pause_button.visible = false
	_show_menu("Game Over")
	_add_label("Score: %d" % int(summary.get("score", 0)))
	_add_label("Coins banked: %d" % total_currency)
	_add_button("Try Again", func() -> void: start_requested.emit())
	_add_button("Main Menu", func() -> void: main_menu_requested.emit())

func _show_menu(title: String) -> void:
	menu_layer.visible = true
	menu_title.text = title
	for child in menu_body.get_children():
		child.queue_free()

func _add_label(text: String) -> void:
	var label := Label.new()
	label.text = text
	menu_body.add_child(label)

func _add_button(text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.pressed.connect(callback)
	menu_body.add_child(button)

func _add_upgrade_button(upgrade_name: String, label: String, total_currency: int, upgrades: Dictionary) -> void:
	var level := int(upgrades.get(upgrade_name, 0))
	var cost := 25 + level * 20
	var button := Button.new()
	button.text = "%s Lv %d - %d coins" % [label, level, cost]
	button.disabled = total_currency < cost
	button.pressed.connect(func() -> void: upgrade_requested.emit(upgrade_name))
	menu_body.add_child(button)

func _on_size_changed(value: float) -> void:
	size_label.text = "Size: %s" % _format_scale(value)

func _format_scale(value: float) -> String:
	if value < 2.0:
		return "Dust %.2fx" % value
	if value < 8.0:
		return "Pebble %.1fx" % value
	if value < 40.0:
		return "Rock %.1fx" % value
	if value < 140.0:
		return "Boulder %.0fx" % value
	if value < 500.0:
		return "Hill %.0fx" % value
	return "Mountain %.0fx" % value

func _populate_legend(entries: Array[Dictionary]) -> void:
	for child in legend_list.get_children():
		child.queue_free()
	for entry in entries:
		var row := HBoxContainer.new()
		var swatch := ColorRect.new()
		swatch.custom_minimum_size = Vector2(14.0, 14.0)
		swatch.color = entry.get("color", Color.WHITE)
		var label := Label.new()
		label.text = entry.get("name", "Unknown")
		row.add_child(swatch)
		row.add_child(label)
		legend_list.add_child(row)
