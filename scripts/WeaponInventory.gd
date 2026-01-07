extends Resource
class_name WeaponInventory

signal inventory_changed()

# Store weapon scene paths for easy saving/loading later
@export var weapon_paths: Array[String] = []
@export var equipped_index: int = -1

func add_weapon(path: String) -> bool:
	if path == "":
		return false
	if weapon_paths.has(path):
		return false # prevent duplicates (remove this if you want duplicates)
	weapon_paths.append(path)
	emit_signal("inventory_changed")
	return true

func remove_weapon_at(index: int) -> void:
	if index < 0 or index >= weapon_paths.size():
		return
	weapon_paths.remove_at(index)

	if equipped_index == index:
		equipped_index = -1
	elif equipped_index > index:
		equipped_index -= 1

	emit_signal("inventory_changed")

func get_weapon_path(index: int) -> String:
	if index < 0 or index >= weapon_paths.size():
		return ""
	return weapon_paths[index]
