extends Resource
class_name GrowthMode

@export var id: StringName = &"sticky_ball"
@export var display_name: String = "Sticky Ball"
@export var attraction_bonus: float = 1.0
@export var growth_bonus: float = 1.0

func can_absorb(player_size: float, object_size: float, config: GameConfig) -> bool:
	return object_size <= player_size * config.absorb_ratio

func growth_for(object_size: float, value: float, config: GameConfig, player_size: float = 1.0) -> float:
	var base_growth := object_size * 0.055 * value * config.growth_multiplier * growth_bonus

	# Strong diminishing returns as the ball gets larger.
	var size_factor := 1.0 / (1.0 + pow(maxf(player_size, 1.0) / 25.0, 0.6))
	size_factor = clampf(size_factor, 0.08, 1.0)

	return maxf(0.01, base_growth * size_factor)
