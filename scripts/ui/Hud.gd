extends CanvasLayer
class_name Hud

var run_state: RunState

@onready var size_label: Label = %SizeLabel
@onready var score_label: Label = %ScoreLabel
@onready var currency_label: Label = %CurrencyLabel
@onready var health_label: Label = %HealthLabel
@onready var legend_list: VBoxContainer = %LegendList

func setup(state: RunState, legend_entries: Array[Dictionary] = []) -> void:
	run_state = state
	run_state.size_changed.connect(_on_size_changed)
	run_state.score_changed.connect(func(value: int) -> void: score_label.text = "Score: %d" % value)
	run_state.currency_changed.connect(func(value: int) -> void: currency_label.text = "Coins: %d" % value)
	run_state.health_changed.connect(func(value: float) -> void: health_label.text = "Health: %d" % int(value))
	_on_size_changed(run_state.size)
	_populate_legend(legend_entries)

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
