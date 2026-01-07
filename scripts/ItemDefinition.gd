extends Resource
class_name ItemDefinition

@export var id: String = ""                   # unique identifier, e.g. "bow_normal"
@export var display_name: String = "Item"
@export var item_type: String = "weapon"      # "weapon" for now

# Visuals
@export var icon: Texture2D                   # sprite shown in the world + inventory later

# For weapons: what scene should be equipped/spawned on the weapon socket
@export var weapon_scene: PackedScene

# Stacking
@export var stackable: bool = true
@export var max_stack: int = 999
