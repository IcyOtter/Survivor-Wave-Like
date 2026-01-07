extends Resource
class_name WeaponInventory

signal inventory_changed()

# Each entry = { path: String, name: String }
@export var weapons: Array[Dictionary] = []
@export var equipped_index: int = -1

func add_weapon(path: String, display_name: String) -> bool:
	if path == "":
		return false

	for w in weapons:
		if w.path == path:
			return false # prevent duplicates

	weapons.append({
		"path": path,
		"name": display_name
	})

	emit_signal("inventory_changed")
	return true

func get_weapon_path(index: int) -> String:
	if index < 0 or index >= weapons.size():
		return ""
	return weapons[index]["path"]

func get_weapon_name(index: int) -> String:
	if index < 0 or index >= weapons.size():
		return ""
	return weapons[index]["name"]
