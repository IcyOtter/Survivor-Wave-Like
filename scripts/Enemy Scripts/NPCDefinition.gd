extends Resource
class_name NPCDefinition

@export var id: String = ""

@export var max_health: int = 20
@export var move_speed: float = 140.0
@export var stop_distance: float = 18.0

@export var contact_damage: int = 10
@export var contact_damage_interval: float = 1.0

@export var xp_reward: int = 5

@export var sprite_texture: Texture2D
@export var sprite_scale: Vector2 = Vector2(1, 1)

@export var drops: Array[DropEntry] = []
