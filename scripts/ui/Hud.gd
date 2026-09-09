extends CanvasLayer
class_name Hud

signal pause_requested
signal resume_requested
signal main_menu_requested
signal start_requested
signal upgrade_requested(upgrade_name: String)
signal mobile_move_changed(direction: Vector2)
signal mobile_boost_changed(pressed: bool)

const JOYSTICK_RADIUS := 118.0
const JOYSTICK_MARGIN := Vector2(84.0, 84.0)
var run_state: RunState
var joystick_touch_index := -1
var boost_touch_index := -1
var joystick_center := Vector2.ZERO
var joystick_vector := Vector2.ZERO
var current_speed := 0.0
var max_health := 100.0

@onready var size_label: Label = %SizeLabel
@onready var score_label: Label = %ScoreLabel
@onready var currency_label: Label = %CurrencyLabel
@onready var health_label: Label = %HealthLabel
@onready var mana_label: Label = %ManaLabel
@onready var speed_label: Label = %SpeedLabel
@onready var pause_button: Button = %PauseButton
@onready var menu_layer: PanelContainer = %MenuLayer
@onready var menu_title: Label = %MenuTitle
@onready var menu_body: VBoxContainer = %MenuBody
@onready var joystick_base: Control = %JoystickBase
@onready var joystick_knob: Control = %JoystickKnob
@onready var boost_button: Button = %BoostButton

func setup(state: RunState, _legend_entries: Array[Dictionary] = []) -> void:
	run_state = state
	run_state.size_changed.connect(_on_size_changed)
	run_state.score_changed.connect(func(value: int) -> void: score_label.text = "Score %d" % value)
	run_state.currency_changed.connect(func(value: int) -> void: currency_label.text = "Coins %d" % value)
	run_state.health_changed.connect(func(value: float) -> void: health_label.text = "HP %d/%d" % [int(value), int(max_health)])
	run_state.mana_changed.connect(func(value: float, max_value: float) -> void: mana_label.text = "Boost %d/%d" % [int(value), int(max_value)])
	pause_button.pressed.connect(func() -> void: pause_requested.emit())
	boost_button.button_down.connect(func() -> void: _set_boost(true))
	boost_button.button_up.connect(func() -> void: _set_boost(false))
	_on_size_changed(run_state.size)
	_update_speed(0.0)
	_reset_joystick()

func set_max_health(value: float) -> void:
	max_health = value
	if run_state != null:
		health_label.text = "HP %d/%d" % [int(run_state.health), int(max_health)]

func update_speed(value: float) -> void:
	current_speed = value
	_update_speed(value)

func show_game() -> void:
	pause_button.visible = true
	joystick_base.visible = true
	boost_button.visible = true
	menu_layer.visible = false
	_place_joystick_at_default()

func show_pause_menu() -> void:
	_reset_boost()
	pause_button.visible = false
	joystick_base.visible = false
	boost_button.visible = false
	_show_menu("Paused")
	_add_button("Resume", func() -> void: resume_requested.emit())
	_add_button("Main Menu", func() -> void: main_menu_requested.emit())

func show_main_menu(total_currency: int, upgrades: Dictionary) -> void:
	_reset_boost()
	pause_button.visible = false
	joystick_base.visible = false
	boost_button.visible = false
	_show_menu("Let It Roll")
	_add_label("Collect tiles, carry their material, and keep your ball balanced.")
	_add_label("Coins: %d" % total_currency)
	_add_button("Play", func() -> void: start_requested.emit())
	_add_label("Upgrades")
	_add_upgrade_button("speed", "Speed", total_currency, upgrades)
	_add_upgrade_button("health", "Health", total_currency, upgrades)
	_add_upgrade_button("stickiness", "Stickiness", total_currency, upgrades)

func show_game_over(summary: Dictionary, total_currency: int, upgrades: Dictionary) -> void:
	_reset_boost()
	pause_button.visible = false
	joystick_base.visible = false
	boost_button.visible = false
	_show_menu("Game Over")
	_add_label("Score: %d" % int(summary.get("score", 0)))
	_add_label("Best size: %.2fx" % float(summary.get("size", 1.0)))
	_add_label("Coins banked: %d" % total_currency)
	_add_button("Try Again", func() -> void: start_requested.emit())
	_add_button("Main Menu", func() -> void: main_menu_requested.emit())

func _input(event: InputEvent) -> void:
	if not boost_button.visible or not (event is InputEventScreenTouch):
		return
	var boost_rect := Rect2(boost_button.global_position, boost_button.size)
	if event.pressed and boost_touch_index == -1 and boost_rect.has_point(event.position):
		boost_touch_index = event.index
		_set_boost(true)
		get_viewport().set_input_as_handled()
	elif not event.pressed and event.index == boost_touch_index:
		boost_touch_index = -1
		_set_boost(false)
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if not joystick_base.visible:
		return
	if event is InputEventScreenTouch:
		if event.pressed and joystick_touch_index == -1 and not _is_blocked_touch_position(event.position):
			joystick_touch_index = event.index
			_place_joystick_at(event.position)
			_update_joystick(event.position)
		elif event.index == joystick_touch_index:
			_reset_joystick()
	elif event is InputEventScreenDrag and event.index == joystick_touch_index:
		_update_joystick(event.position)

func _update_joystick(position: Vector2) -> void:
	joystick_vector = (position - joystick_center).limit_length(JOYSTICK_RADIUS) / JOYSTICK_RADIUS
	joystick_knob.position = joystick_base.size * 0.5 - joystick_knob.size * 0.5 + joystick_vector * JOYSTICK_RADIUS
	mobile_move_changed.emit(joystick_vector)

func _reset_joystick() -> void:
	joystick_touch_index = -1
	joystick_vector = Vector2.ZERO
	if joystick_knob != null and joystick_base != null:
		_place_joystick_at_default()
		joystick_knob.position = joystick_base.size * 0.5 - joystick_knob.size * 0.5
	mobile_move_changed.emit(Vector2.ZERO)

func _place_joystick_at_default() -> void:
	if joystick_base == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var center := Vector2(viewport_size.x - JOYSTICK_MARGIN.x - joystick_base.size.x * 0.5, viewport_size.y - JOYSTICK_MARGIN.y - joystick_base.size.y * 0.5)
	_place_joystick_at(center)

func _place_joystick_at(position: Vector2) -> void:
	joystick_center = position
	joystick_base.global_position = joystick_center - joystick_base.size * 0.5

func _is_blocked_touch_position(position: Vector2) -> bool:
	if boost_button.visible and Rect2(boost_button.global_position, boost_button.size).has_point(position):
		return true
	return menu_layer.visible and Rect2(menu_layer.global_position, menu_layer.size).has_point(position)

func _set_boost(pressed: bool) -> void:
	mobile_boost_changed.emit(pressed)

func _reset_boost() -> void:
	boost_touch_index = -1
	_set_boost(false)

func _show_menu(title: String) -> void:
	menu_layer.visible = true
	menu_title.text = title
	for child in menu_body.get_children():
		child.queue_free()

func _add_label(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_body.add_child(label)

func _add_button(text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0.0, 86.0)
	button.pressed.connect(callback)
	menu_body.add_child(button)

func _add_upgrade_button(upgrade_name: String, label: String, total_currency: int, upgrades: Dictionary) -> void:
	var level := int(upgrades.get(upgrade_name, 0))
	var cost := 25 + level * 20
	var button := Button.new()
	button.text = "%s Lv %d  •  %d coins" % [label, level, cost]
	button.custom_minimum_size = Vector2(0.0, 74.0)
	button.disabled = total_currency < cost
	button.pressed.connect(func() -> void: upgrade_requested.emit(upgrade_name))
	menu_body.add_child(button)

func _on_size_changed(value: float) -> void:
	size_label.text = _format_scale(value)

func _update_speed(value: float) -> void:
	if speed_label != null:
		speed_label.text = "Speed %d" % int(value)

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
