extends Resource
class_name DropEntry

@export_range(0.0, 1.0, 0.01) var chance: float = 0.25

# Should be your universal pickup scene that has ItemPickup.gd attached
@export var pickup_scene: PackedScene

# What item is dropped (ItemDefinition .tres)
@export var item_def: ItemDefinition

# Quantity range (for stackable items)
@export var min_qty: int = 1
@export var max_qty: int = 1
