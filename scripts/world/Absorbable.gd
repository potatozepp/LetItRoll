extends Area2D
class_name Absorbable

@export var object_size: float = 1.0
@export var value: float = 1.0
@export var score_value: int = 1
@export var currency_value: int = 1
@export var radius: float = 8.0
@export var color: Color = Color.WHITE

func configure(data: Dictionary) -> void:
	object_size = data.get("size", object_size)
	value = data.get("value", value)
	score_value = data.get("score", score_value)
	currency_value = data.get("currency", currency_value)
	radius = data.get("radius", radius)
	color = data.get("color", color)
	_update_visuals()

func _ready() -> void:
	_update_visuals()

func _update_visuals() -> void:
	if not is_inside_tree():
		return
	$Visual.size = Vector2.ONE * radius * 2.0
	$Visual.position = -$Visual.size * 0.5
	$Visual.color = color
	($CollisionShape2D.shape as CircleShape2D).radius = radius
