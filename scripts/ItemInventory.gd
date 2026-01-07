extends Resource
class_name ItemInventory

signal inventory_changed()

# Each stack is a Dictionary:
# {
#   "id": String,
#   "name": String,
#   "type": String,
#   "weapon_path": String,
#   "qty": int,
#   "stackable": bool,
#   "max_stack": int
# }
@export var items: Array[Dictionary] = []

# Equipped weapon slot stores a single item entry (qty always 1)
@export var equipped_weapon: Dictionary = {}

func add_item(def: ItemDefinition, amount: int = 1) -> void:
	if def == null or amount <= 0:
		return
	if def.id.strip_edges() == "":
		push_warning("ItemInventory: ItemDefinition id is empty. Set a unique id.")
		return

	# If stackable, try to add to an existing stack
	if def.stackable:
		for i in range(items.size()):
			if String(items[i].get("id", "")) == def.id:
				var max_stack := int(items[i].get("max_stack", 999))
				var current := int(items[i].get("qty", 0))
				items[i]["qty"] = clamp(current + amount, 0, max_stack)
				emit_signal("inventory_changed")
				return

	# Otherwise create a new stack (or new entry)
	items.append(_make_entry(def, amount))
	emit_signal("inventory_changed")

func remove_item_by_index(index: int, amount: int = 1) -> bool:
	if index < 0 or index >= items.size() or amount <= 0:
		return false

	var current := int(items[index].get("qty", 0))
	current -= amount

	if current <= 0:
		items.remove_at(index)
	else:
		items[index]["qty"] = current

	emit_signal("inventory_changed")
	return true

func get_item_name(index: int) -> String:
	if index < 0 or index >= items.size():
		return ""
	return String(items[index].get("name", ""))

func get_item_qty(index: int) -> int:
	if index < 0 or index >= items.size():
		return 0
	return int(items[index].get("qty", 0))

func get_item_type(index: int) -> String:
	if index < 0 or index >= items.size():
		return ""
	return String(items[index].get("type", ""))

func get_weapon_path(index: int) -> String:
	if index < 0 or index >= items.size():
		return ""
	return String(items[index].get("weapon_path", ""))

func has_equipped_weapon() -> bool:
	return equipped_weapon.has("id") and String(equipped_weapon["id"]) != ""

func get_equipped_weapon_name() -> String:
	return String(equipped_weapon.get("name", ""))

func get_equipped_weapon_path() -> String:
	return String(equipped_weapon.get("weapon_path", ""))

func _make_entry(def: ItemDefinition, amount: int) -> Dictionary:
	var weapon_path := ""
	if def.weapon_scene != null and def.weapon_scene.resource_path != "":
		weapon_path = def.weapon_scene.resource_path


	return {
		"def": def,
		"id": def.id,
		"name": def.display_name,
		"type": def.item_type,
		"weapon_path": weapon_path,
		"qty": amount,
		"stackable": def.stackable,
		"max_stack": def.max_stack
	}

