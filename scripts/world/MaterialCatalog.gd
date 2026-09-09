extends Resource
class_name MaterialCatalog

# Data-driven terrain/material definitions. Volumes are deliberately small so the
# starter ball can always lift the loose dirt and grass in the tutorial patch.
const DEFINITIONS := {
	"grass": {"label": "Grass", "color": Color("67a94b"), "accent": Color("b4db67"), "hardness": 0.15, "minimum_size": 1.0, "density": 0.55, "collect_rate": 0.18, "fresh": true},
	"dirt": {"label": "Dirt", "color": Color("8f5938"), "accent": Color("c58a57"), "hardness": 0.10, "minimum_size": 1.0, "density": 0.82, "collect_rate": 0.20, "fresh": true},
	"sand": {"label": "Sand", "color": Color("d6bd77"), "accent": Color("f2dfa1"), "hardness": 0.25, "minimum_size": 1.5, "density": 0.70, "collect_rate": 0.15, "fresh": true},
	"gravel": {"label": "Gravel", "color": Color("74746a"), "accent": Color("b0ab94"), "hardness": 0.75, "minimum_size": 2.8, "density": 1.2, "collect_rate": 0.10, "fresh": true},
	"stone": {"label": "Stone", "color": Color("697381"), "accent": Color("a8b1bb"), "hardness": 1.3, "minimum_size": 5.0, "density": 1.7, "collect_rate": 0.07, "fresh": true},
	"asphalt": {"label": "Asphalt", "color": Color("343b42"), "accent": Color("697078"), "hardness": 2.3, "minimum_size": 9.0, "density": 2.0, "collect_rate": 0.05, "fresh": true},
	"concrete": {"label": "Concrete", "color": Color("50545a"), "accent": Color("81858b"), "hardness": 3.2, "minimum_size": 15.0, "density": 2.4, "collect_rate": 0.04, "fresh": true},
	"rock": {"label": "Rock", "color": Color("42484d"), "accent": Color("788078"), "hardness": 5.0, "minimum_size": 28.0, "density": 2.8, "collect_rate": 0.03, "fresh": true},
	"water": {"label": "Water", "color": Color("2b90bf"), "accent": Color("8fd8e8"), "hardness": 0.0, "minimum_size": 0.0, "density": 0.0, "collect_rate": 0.0, "fresh": false},
}

static func get_definition(material_id: String) -> Dictionary:
	return DEFINITIONS.get(material_id, DEFINITIONS["concrete"]).duplicate()

static func can_collect(material_id: String, ball_size: float) -> bool:
	var definition := get_definition(material_id)
	return material_id != "water" and ball_size >= float(definition["minimum_size"])
