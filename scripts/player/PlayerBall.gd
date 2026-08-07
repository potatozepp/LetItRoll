extends CharacterBody2D
class_name PlayerBall

signal absorbed(pickup: Absorbable)

@export var config: GameConfig
@export var run_state: RunState
@export var growth_mode: GrowthMode
@export var terrain_manager: TerrainManager

var input_vector: Vector2 = Vector2.ZERO
var drag_origin: Vector2 = Vector2.ZERO
var dragging := false

@onready var visual: ColorRect = $Visual
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var absorb_area: Area2D = $AbsorbArea
@onready var absorb_shape: CollisionShape2D = $AbsorbArea/CollisionShape2D

func _ready() -> void:
	if config != null and run_state != null:
		_update_scale()

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
	var move_input := keyboard if keyboard.length() > 0.05 else input_vector
	var size_speed_penalty := clampf(1.0 / sqrt(run_state.size), 0.28, 1.0)
	velocity = move_input * config.base_speed * size_speed_penalty
	move_and_slide()
	_consume_terrain()
	_pull_nearby_pickups(delta)
	_try_absorb_overlaps()

func _consume_terrain() -> void:
	if terrain_manager == null:
		return
	terrain_manager.consume_at(global_position, _radius() * 0.88, run_state.size, growth_mode)
	_update_scale()

func _pull_nearby_pickups(delta: float) -> void:
	for body in absorb_area.get_overlapping_areas():
		if body is Absorbable and growth_mode.can_absorb(run_state.size, body.object_size, config):
			var direction := global_position.direction_to(body.global_position)
			body.global_position -= direction * config.attraction_radius * growth_mode.attraction_bonus * delta

func _try_absorb_overlaps() -> void:
	for index in range(get_slide_collision_count()):
		var collider := get_slide_collision(index).get_collider()
		if collider is Absorbable:
			_absorb(collider)
	for area in absorb_area.get_overlapping_areas():
		if area is Absorbable and global_position.distance_to(area.global_position) <= _radius() + area.radius:
			_absorb(area)

func _absorb(pickup: Absorbable) -> void:
	if not is_instance_valid(pickup) or not growth_mode.can_absorb(run_state.size, pickup.object_size, config):
		return
	var growth := growth_mode.growth_for(pickup.object_size, pickup.value, config)
	run_state.add_growth(growth, pickup.score_value, pickup.currency_value)
	absorbed.emit(pickup)
	pickup.queue_free()
	_update_scale()

func _update_scale() -> void:
	var radius := _radius()
	visual.size = Vector2.ONE * radius * 2.0
	visual.position = -visual.size * 0.5
	visual.pivot_offset = visual.size * 0.5
	var circle := collision_shape.shape as CircleShape2D
	circle.radius = radius
	var absorb_circle := absorb_shape.shape as CircleShape2D
	absorb_circle.radius = radius + config.attraction_radius

func _radius() -> float:
	return 14.0 * pow(run_state.size, 0.42)
