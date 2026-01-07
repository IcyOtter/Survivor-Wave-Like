extends Resource
class_name ItemDefinition

@export var id: String = ""
@export var display_name: String = "Item"
@export var item_type: String = "weapon" # keep for future expansion

@export var icon: Texture2D

# Weapon scene to instantiate on equip
@export var weapon_scene: PackedScene

# Weapon stats (damage is ONLY here now)
@export var fire_rate: float = 4.0
@export var base_damage: int = 5

# Weapon-owned projectile config (arrow is tied to bow)
@export var projectile_scene: PackedScene
@export var projectile_speed: float = 900.0
@export var projectile_lifetime: float = 2.0
@export var projectile_rotate_to_direction: bool = true

# Stacking (weapons usually not stackable)
@export var stackable: bool = false
@export var max_stack: int = 1
