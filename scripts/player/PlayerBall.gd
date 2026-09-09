extends CharacterBody2D
class_name PlayerBall

signal absorbed(pickup: Absorbable)
signal material_collected(material_id: String, volume: float)

const SECTOR_COUNT := 16
const BASE_RADIUS := 14.0

@export var config: GameConfig
@export var run_state: RunState
@export var growth_mode: GrowthMode # Retained for future bonus-object modes.
@export var terrain_manager: TerrainManager

var input_vector := Vector2.ZERO
var drag_origin := Vector2.ZERO
var dragging := false
var boosting := false
var mobile_input_vector := Vector2.ZERO
var mobile_boost_pressed := false
var current_speed := 0.0
var fresh_sectors: Array[Dictionary] = []
var compacted_sectors: Array[Dictionary] = []
var failure_timer := 0.0
var feedback_timer := 0.0
var feedback_text := ""

@onready var visual: CanvasItem = $Visual
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var absorb_shape: CollisionShape2D = $AbsorbArea/CollisionShape2D

func _ready() -> void:
	reset_materials()
	if config != null and run_state != null:
		_update_scale()

func reset_materials() -> void:
	fresh_sectors.clear()
	compacted_sectors.clear()
	for index in range(SECTOR_COUNT):
		fresh_sectors.append({})
		compacted_sectors.append({})
	failure_timer = 0.0
	feedback_text = ""
	feedback_timer = 0.0
	if run_state != null:
		run_state.set_physical_size(1.0)
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		dragging = event.pressed
		drag_origin = event.position
		if not dragging:
			input_vector = Vector2.ZERO
	elif event is InputEventScreenDrag and dragging:
		input_vector = (event.position - drag_origin).limit_length(160.0) / 160.0

func _physics_process(delta: float) -> void:
	var keyboard := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var touch_input := mobile_input_vector if mobile_input_vector.length() > 0.05 else input_vector
	var move_input := keyboard if keyboard.length() > 0.05 else touch_input
	if (Input.is_action_pressed("boost") or mobile_boost_pressed) and move_input.length() > 0.05 and run_state.use_mana(config.mana_drain_per_second * delta):
		boosting = true
	else:
		boosting = false
		run_state.restore_mana(config.mana_regen_per_second * delta)
	var boost_factor := config.boost_multiplier if boosting else 1.0
	current_speed = config.base_speed * clampf(1.0 + log(maxf(run_state.size, 1.0)) * 0.06, 0.8, 1.45) * boost_factor
	velocity = move_input * current_speed
	move_and_slide()
	_collect_terrain(move_input)
	_compress_material(delta, move_input.length())
	_wash_in_water(delta)
	_check_deformation_failure(delta, move_input.length())
	feedback_timer = maxf(0.0, feedback_timer - delta)
	_update_scale()

func _collect_terrain(move_input: Vector2) -> void:
	if terrain_manager == null or move_input.length() < 0.02:
		return
	var capacity_left := maxf(0.0, _surface_capacity() - _fresh_volume())
	if capacity_left <= 0.001:
		_show_feedback("SURFACE FULL — ROLL TO COMPACT", Color("ffd36b"))
		return
	var records := terrain_manager.collect_at(global_position, _radius() * 0.85, run_state.size, capacity_left)
	if records.is_empty():
		return
	for record in records:
		_add_material(String(record["material"]), float(record["volume"]), move_input)
		material_collected.emit(String(record["material"]), float(record["volume"]))
		_show_feedback("+ %s" % MaterialCatalog.get_definition(String(record["material"]))["label"], Color("efffc8"))

func _add_material(material_id: String, volume: float, direction: Vector2) -> void:
	# The rolling direction picks the leading contact sectors; repeated straight
	# rolling therefore builds a wheel-like lopsided shell.
	var contact_angle := direction.angle() + PI * 0.5
	var sector := posmodi(int(round(contact_angle / TAU * SECTOR_COUNT)), SECTOR_COUNT)
	for offset in [-1, 0, 1]:
		var target := posmodi(sector + offset, SECTOR_COUNT)
		var share := volume * (0.56 if offset == 0 else 0.22)
		fresh_sectors[target][material_id] = float(fresh_sectors[target].get(material_id, 0.0)) + share

func _compress_material(delta: float, movement_amount: float) -> void:
	if movement_amount < 0.05:
		return
	var compression := delta * 0.09 * movement_amount
	for sector in range(SECTOR_COUNT):
		for material_id in fresh_sectors[sector].keys():
			var available := float(fresh_sectors[sector][material_id])
			var used := minf(available, compression)
			if used <= 0.0:
				continue
			fresh_sectors[sector][material_id] = available - used
			var transformed := "dirt" if material_id == "grass" else String(material_id)
			compacted_sectors[sector][transformed] = float(compacted_sectors[sector].get(transformed, 0.0)) + used * 0.82

func _wash_in_water(delta: float) -> void:
	if terrain_manager == null:
		return
	var strength := terrain_manager.water_strength_at(global_position, _radius())
	if strength <= 0.0 or _fresh_volume() <= 0.001:
		return
	var wash_amount := delta * 0.32 * strength
	for sector in range(SECTOR_COUNT):
		for material_id in fresh_sectors[sector].keys():
			var removed := minf(float(fresh_sectors[sector][material_id]), wash_amount / SECTOR_COUNT)
			fresh_sectors[sector][material_id] = float(fresh_sectors[sector][material_id]) - removed
	_show_feedback("WATER WASHES LOOSE MATERIAL", Color("a8e8ff"))

func _check_deformation_failure(delta: float, movement_amount: float) -> void:
	var deformation := _deformation_ratio()
	if deformation > 1.72:
		_show_feedback("UNSTABLE SHAPE — BALANCE IT!", Color("ff9d86"))
	if deformation > 2.15 and movement_amount > 0.6:
		failure_timer += delta
		if failure_timer > 1.4:
			run_state.damage(run_state.health)
	else:
		failure_timer = maxf(0.0, failure_timer - delta * 0.6)

func _surface_capacity() -> float:
	return 1.45 + _radius() * 0.105

func _fresh_volume() -> float:
	return _volume_in(fresh_sectors)

func _total_volume() -> float:
	return _fresh_volume() + _volume_in(compacted_sectors)

func _volume_in(sectors: Array[Dictionary]) -> float:
	var total := 0.0
	for sector in sectors:
		for amount in sector.values():
			total += float(amount)
	return total

func _sector_volume(index: int) -> float:
	var total := 0.0
	for amount in fresh_sectors[index].values(): total += float(amount)
	for amount in compacted_sectors[index].values(): total += float(amount)
	return total

func _deformation_ratio() -> float:
	var minimum := INF
	var maximum := 0.0
	for index in range(SECTOR_COUNT):
		var thickness := 1.0 + _sector_volume(index) * 0.42
		minimum = minf(minimum, thickness)
		maximum = maxf(maximum, thickness)
	return maximum / maxf(minimum, 0.01)

func _update_scale() -> void:
	var physical_size := 1.0 + _total_volume() * 0.72
	run_state.set_physical_size(physical_size)
	var radius := _radius()
	visual.visible = false
	(collision_shape.shape as CircleShape2D).radius = radius
	(absorb_shape.shape as CircleShape2D).radius = radius + config.attraction_radius
	queue_redraw()

func _radius() -> float:
	return BASE_RADIUS * pow(maxf(run_state.size, 1.0), 0.42)

func _show_feedback(text: String, _color: Color) -> void:
	feedback_text = text
	feedback_timer = 0.45

func set_mobile_input(direction: Vector2) -> void:
	mobile_input_vector = direction.limit_length(1.0)

func set_mobile_boost(pressed: bool) -> void:
	mobile_boost_pressed = pressed

func reset_mana() -> void:
	if run_state != null and config != null:
		run_state.max_mana = config.mana_max
		run_state.mana = run_state.max_mana
		run_state.mana_changed.emit(run_state.mana, run_state.max_mana)

func _draw() -> void:
	var base_radius := _radius()
	var outline := PackedVector2Array()
	for index in range(SECTOR_COUNT):
		var angle := TAU * index / SECTOR_COUNT
		outline.append(Vector2.from_angle(angle) * (base_radius + _sector_volume(index) * 5.8))
	draw_colored_polygon(outline, Color("d6d1c1"))
	draw_polyline(outline + PackedVector2Array([outline[0]]), Color("30363a"), maxf(1.5, base_radius * 0.09))
	for index in range(SECTOR_COUNT):
		var angle := TAU * (index + 0.5) / SECTOR_COUNT
		var sector_radius := base_radius + _sector_volume(index) * 4.4
		var material_id := _dominant_material(index)
		if material_id.is_empty():
			continue
		var definition := MaterialCatalog.get_definition(material_id)
		var chunks := clampi(int(ceil(_sector_volume(index) * 5.0)), 1, 4)
		for chunk in range(chunks):
			var wobble := sin(float(index * 19 + chunk * 7)) * 0.14
			var point := Vector2.from_angle(angle + wobble) * (sector_radius - 3.0 - chunk * 3.0)
			draw_circle(point, clampf(2.5 + _sector_volume(index) * 1.8, 2.5, 6.5), definition["color"])
			draw_circle(point - Vector2(1.2, 1.2), 1.1, definition["accent"])
	draw_circle(Vector2(-base_radius * 0.24, -base_radius * 0.28), maxf(2.0, base_radius * 0.13), Color(1, 1, 1, 0.56))
	if feedback_timer > 0.0:
		draw_string(ThemeDB.fallback_font, Vector2(-base_radius * 2.2, -base_radius - 25), feedback_text, HORIZONTAL_ALIGNMENT_CENTER, base_radius * 4.4, 14, Color.WHITE)

func _dominant_material(index: int) -> String:
	var selected := ""
	var largest := 0.0
	for source in [fresh_sectors[index], compacted_sectors[index]]:
		for material_id in source.keys():
			if float(source[material_id]) > largest:
				largest = float(source[material_id])
				selected = String(material_id)
	return selected
