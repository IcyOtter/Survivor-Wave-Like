extends Resource
class_name ItemDefinition

@export var id: String = ""                   # unique identifier, e.g. "bow_normal"
@export var display_name: String = "Item"
@export var item_type: String = "weapon"      # "weapon" for now

# Visuals (used by ItemPickup, later by inventory UI)
@export var icon: Texture2D

# --- Weapon data (used when item_type == "weapon") ---
@export var weapon_scene: PackedScene         # the scene to instantiate when equipped
@export var fire_rate: float = 4.0            # shots per second (4 = one shot every 0.25s)
@export var base_damage: int = 5              # weapon base damage

# Stacking
@export var stackable: bool = true
@export var max_stack: int = 999
