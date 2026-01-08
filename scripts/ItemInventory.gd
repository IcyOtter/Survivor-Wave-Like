extends Resource
class_name ItemInventory

signal inventory_changed()

@export var items: Array[Dictionary] = []

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
				var max_stack := def.max_stack
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

func get_item_def(index: int) -> ItemDefinition:
	if index < 0 or index >= items.size():
		return null
	return items[index].get("def", null) as ItemDefinition

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
	var weapon_path: String = ""
	if def.weapon_scene != null:
		var p := def.weapon_scene.resource_path
		if p != null and p != "":
			weapon_path = p

	var projectile_path: String = ""
	if def.projectile_scene != null:
		var pp := def.projectile_scene.resource_path
		if pp != null and pp != "":
			projectile_path = pp

	return {
		"def": def,
		"id": def.id,
		"name": def.display_name,
		"type": def.item_type,

		"weapon_path": weapon_path,
		"projectile_path": projectile_path,

		"qty": amount,
		"stackable": def.stackable,
		"max_stack": def.max_stack
	}

func find_stack_index_by_id(item_id: String) -> int:
	for i in range(items.size()):
		if String(items[i].get("id", "")) == item_id:
			return i
	return -1

func get_count_by_id(item_id: String) -> int:
	var idx := find_stack_index_by_id(item_id)
	if idx == -1:
		return 0
	return int(items[idx].get("qty", 0))

func consume_by_id(item_id: String, amount: int = 1) -> bool:
	if amount <= 0:
		return true

	var idx := find_stack_index_by_id(item_id)
	if idx == -1:
		return false

	var current := int(items[idx].get("qty", 0))
	if current < amount:
		return false

	items[idx]["qty"] = current - amount
	if int(items[idx]["qty"]) <= 0:
		items.remove_at(idx)

	emit_signal("inventory_changed")
	return true

func get_equipped_weapon_def() -> ItemDefinition:
	return equipped_weapon.get("def", null) as ItemDefinition

