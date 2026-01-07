extends Resource
class_name DropEntry

@export var pickup_scene: PackedScene            # ItemPickup.tscn
@export var item_def: ItemDefinition             # BowNormal.tres
@export var quantity: int = 1
@export_range(0.0, 1.0, 0.01) var chance: float = 0.25
