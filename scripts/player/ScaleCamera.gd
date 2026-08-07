extends Camera2D
class_name ScaleCamera

@export var config: GameConfig
@export var run_state: RunState
@export var target: Node2D

func _process(delta: float) -> void:
	if target != null:
		global_position = global_position.lerp(target.global_position, 1.0 - exp(-8.0 * delta))
	var zoom_value := config.camera_min_zoom / pow(maxf(run_state.size, 1.0), 0.22)
	zoom_value = clampf(zoom_value, 0.035, config.camera_min_zoom)
	zoom = zoom.lerp(Vector2.ONE * zoom_value, 1.0 - exp(-config.camera_zoom_smoothing * delta))
