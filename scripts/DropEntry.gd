extends Resource
class_name DropEntry

@export var pickup_scene: PackedScene            # usually ItemPickup.tscn
@export var weapon_scene: PackedScene            # e.g. item.tscn
@export var display_name: String = ""            # e.g. "Item Display Name"
@export_range(0.0, 1.0, 0.01) var chance: float = 0.25  # 0.25 = 25% chance
