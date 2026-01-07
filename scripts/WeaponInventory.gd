extends Resource
class_name WeaponInventory

signal inventory_changed()

# Each entry = { "path": String, "name": String }
@export var weapons: Array[Dictionary] = []

# Equipped slot (empty dict means nothing equipped)
@export var equipped_weapon: Dictionary = {}

func add_weapon(path: String, display_name: String) -> bool:
	if path == "":
		return false

	# Prevent duplicates (optional)
	for w in weapons:
		if w.get("path", "") == path:
			return false

	weapons.append({
		"path": path,
		"name": display_name
	})
	emit_signal("inventory_changed")
	return true

func get_weapon_path(index: int) -> String:
	if index < 0 or index >= weapons.size():
		return ""
	return weapons[index].get("path", "")

func get_weapon_name(index: int) -> String:
	if index < 0 or index >= weapons.size():
		return ""
	return weapons[index].get("name", "")

func has_equipped_weapon() -> bool:
	return equipped_weapon.has("path") and String(equipped_weapon["path"]) != ""

func get_equipped_name() -> String:
	return String(equipped_weapon.get("name", ""))

func get_equipped_path() -> String:
	return String(equipped_weapon.get("path", ""))
