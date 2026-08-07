extends Resource
class_name GrowthMode

@export var id: StringName = &"sticky_ball"
@export var display_name: String = "Sticky Ball"
@export var attraction_bonus: float = 1.0
@export var growth_bonus: float = 1.0

func can_absorb(player_size: float, object_size: float, config: GameConfig) -> bool:
	return object_size <= player_size * config.absorb_ratio

func growth_for(object_size: float, value: float, config: GameConfig) -> float:
	return maxf(0.01, object_size * 0.055 * value * config.growth_multiplier * growth_bonus)
