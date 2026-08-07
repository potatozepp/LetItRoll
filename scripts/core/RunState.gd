extends Node
class_name RunState

signal size_changed(size: float)
signal score_changed(score: int)
signal currency_changed(currency: int)
signal health_changed(health: float)
signal run_ended(summary: Dictionary)

var size: float = 1.0
var score: int = 0
var currency: int = 0
var health: float = 100.0
var objects_collected: int = 0
var elapsed_time: float = 0.0

func reset(config: GameConfig) -> void:
	size = config.start_size
	score = 0
	currency = 0
	health = config.start_health
	objects_collected = 0
	elapsed_time = 0.0
	size_changed.emit(size)
	score_changed.emit(score)
	currency_changed.emit(currency)
	health_changed.emit(health)

func add_growth(amount: float, points: int, coins: int) -> void:
	size += amount
	score += points
	currency += coins
	objects_collected += 1
	size_changed.emit(size)
	score_changed.emit(score)
	currency_changed.emit(currency)

func damage(amount: float) -> void:
	health = maxf(0.0, health - amount)
	health_changed.emit(health)
	if health <= 0.0:
		run_ended.emit(get_summary())

func get_summary() -> Dictionary:
	return {"size": size, "score": score, "currency": currency, "objects_collected": objects_collected, "elapsed_time": elapsed_time}
