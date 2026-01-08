extends Resource
class_name NPCDefinition

@export var id: String = ""
@export var display_name: String = "Enemy"

# Core stats
@export var max_health: int = 20
@export var move_speed: float = 140.0
@export var stop_distance: float = 18.0

# Combat
@export var contact_damage_per_second: float = 20.0

# Rewards (optional, for later)
@export var xp_reward: int = 0

# Visuals (optional convenience)
@export var sprite_texture: Texture2D
@export var sprite_scale: Vector2 = Vector2.ONE

# Drops (optional, if you already have drops working)
@export var drops: Array[DropEntry] = []
