extends Resource
class_name CoinDropEntry

@export var chance: float = 1.0

# Random coin value range
@export var min_value: int = 1
@export var max_value: int = 1

# Scene that represents the coin pickup in the world
@export var coin_pickup_scene: PackedScene
