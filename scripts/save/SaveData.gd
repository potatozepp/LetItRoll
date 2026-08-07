extends Node
class_name SaveData

const SAVE_PATH := "user://let_it_roll.save"

var total_currency: int = 0
var upgrades := {"speed": 0, "stickiness": 0, "growth": 0, "resistance": 0, "starting_size": 0, "attraction": 0, "max_health": 0}

func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data := JSON.parse_string(file.get_as_text())
	if data is Dictionary:
		total_currency = data.get("total_currency", total_currency)
		upgrades.merge(data.get("upgrades", {}), true)

func save_data() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({"total_currency": total_currency, "upgrades": upgrades}))
