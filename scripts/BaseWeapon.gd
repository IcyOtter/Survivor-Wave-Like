extends Node2D
class_name BaseWeapon

@export var item_def: ItemDefinition

# These are derived from item_def; do not edit per weapon scene anymore.
var fire_rate: float = 4.0
var base_damage: int = 5

var _cooldown: float = 0.0

func _ready() -> void:
	_apply_item_def()

func _physics_process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta

func _apply_item_def() -> void:
	if item_def == null:
		return

	# Only apply weapon stats if this is a weapon item
	if item_def.item_type == "weapon":
		fire_rate = max(item_def.fire_rate, 0.01)
		base_damage = max(item_def.base_damage, 0)

func set_item_definition(def: ItemDefinition) -> void:
	item_def = def
	_apply_item_def()

func can_fire() -> bool:
	return _cooldown <= 0.0

func fire() -> void:
	# Base implementation: enforce fire rate, then call _do_fire() in subclasses
	if not can_fire():
		return

	_cooldown = 1.0 / fire_rate
	_do_fire()

func _do_fire() -> void:
	# Override in specific weapon scripts (Bow, Wand, etc.)
	pass
