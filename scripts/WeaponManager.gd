extends Node
class_name WeaponManager

signal weapon_equipped(weapon: Node)
signal inventory_updated()

@export var weapon_socket_path: NodePath = ^"../WeaponSocket"

# Starting items (add ItemDefinition .tres files here)
@export var starting_items: Array[ItemDefinition] = []

# Inventory resource (can be saved later)
@export var inventory: ItemInventory

var _socket: Node2D
var current_weapon: BaseWeapon = null


func _ready() -> void:
	_socket = get_node_or_null(weapon_socket_path) as Node2D
	if _socket == null:
		push_error("WeaponManager: WeaponSocket not found. Check weapon_socket_path.")
		return

	if inventory == null:
		inventory = ItemInventory.new()

	if not inventory.inventory_changed.is_connected(_on_inventory_changed):
		inventory.inventory_changed.connect(_on_inventory_changed)

	# Add starting items into inventory
	for item_def in starting_items:
		if item_def != null:
			inventory.add_item(item_def, 1)

	# Optional: auto-equip first weapon item if nothing equipped
	if not inventory.has_equipped_weapon():
		var idx := _find_first_weapon_index()
		if idx != -1:
			equip_from_inventory(idx)


func _on_inventory_changed() -> void:
	emit_signal("inventory_updated")


func try_fire() -> void:
	if current_weapon == null:
		print("WeaponManager: current_weapon is NULL (nothing equipped or cast failed).")
		return

	if not current_weapon.has_method("fire"):
		print("WeaponManager: current_weapon has no fire() method:", current_weapon)
		return

	current_weapon.fire()



func add_item_from_pickup(pickup: ItemPickup) -> bool:
	if pickup == null or pickup.item_def == null:
		return false

	if inventory == null:
		inventory = ItemInventory.new()
		if not inventory.inventory_changed.is_connected(_on_inventory_changed):
			inventory.inventory_changed.connect(_on_inventory_changed)

	inventory.add_item(pickup.item_def, pickup.quantity)
	return true


func equip_from_inventory(index: int) -> void:
	if inventory == null:
		return
	if index < 0 or index >= inventory.items.size():
		return

	if inventory.get_item_type(index) != "weapon":
		push_warning("WeaponManager: Selected item is not a weapon.")
		return

	var weapon_path := inventory.get_weapon_path(index)
	if weapon_path == "":
		push_warning("WeaponManager: Weapon item has no weapon_path.")
		return

	# If something equipped, return it first (and clear existing weapon node)
	if inventory.has_equipped_weapon():
		unequip()

	# Consume 1 from the inventory stack and store equipped entry
	var entry := inventory.items[index].duplicate(true)
	entry["qty"] = 1

	# IMPORTANT: keep the ItemDefinition reference so BaseWeapon can read stats (fire_rate/base_damage)
	# This requires ItemInventory._make_entry() to include: "def": def
	if not entry.has("def") or entry["def"] == null:
		push_warning("WeaponManager: Inventory entry has no 'def'. Ensure ItemInventory entries include {'def': ItemDefinition}.")
	inventory.equipped_weapon = entry

	inventory.remove_item_by_index(index, 1)

	# Spawn equipped weapon
	var scene := load(weapon_path) as PackedScene
	if scene == null:
		push_warning("WeaponManager: Could not load weapon scene at path: %s" % weapon_path)
		inventory.equipped_weapon = {}
		inventory.emit_signal("inventory_changed")
		return

	_equip_scene(scene)
	inventory.emit_signal("inventory_changed")


func unequip() -> void:
	if inventory == null or not inventory.has_equipped_weapon():
		return

	_return_equipped_to_inventory()

	# Remove current weapon instance
	if _socket != null:
		for child in _socket.get_children():
			child.queue_free()

	current_weapon = null
	inventory.emit_signal("inventory_changed")


func _return_equipped_to_inventory() -> void:
	if inventory == null or not inventory.has_equipped_weapon():
		return

	var entry := inventory.equipped_weapon
	inventory.equipped_weapon = {}

	var id := String(entry.get("id", ""))
	if id == "":
		return

	var stackable := bool(entry.get("stackable", true))
	var max_stack := int(entry.get("max_stack", 999))

	if stackable:
		for i in range(inventory.items.size()):
			if String(inventory.items[i].get("id", "")) == id:
				var current := int(inventory.items[i].get("qty", 0))
				inventory.items[i]["qty"] = clamp(current + 1, 0, max_stack)
				return

	entry["qty"] = 1
	inventory.items.append(entry)


func _equip_scene(scene: PackedScene) -> void:
	if _socket == null or scene == null:
		return

	for child in _socket.get_children():
		child.queue_free()

	var weapon_node := scene.instantiate()
	_socket.add_child(weapon_node)

	current_weapon = weapon_node as BaseWeapon
	if current_weapon == null:
		push_warning("WeaponManager: Equipped scene is not a BaseWeapon. Attach BaseWeapon.gd to the weapon root.")
	else:
		# Push ItemDefinition stats into the weapon (fire_rate/base_damage live on ItemDefinition now)
		if inventory != null and inventory.has_equipped_weapon():
			var def: ItemDefinition = inventory.equipped_weapon.get("def", null) as ItemDefinition
			if def != null:
				current_weapon.set_item_definition(def)
			else:
				push_warning("WeaponManager: Equipped entry 'def' is missing or not an ItemDefinition.")

	emit_signal("weapon_equipped", weapon_node)


func _find_first_weapon_index() -> int:
	if inventory == null:
		return -1
	for i in range(inventory.items.size()):
		if inventory.get_item_type(i) == "weapon" and inventory.get_weapon_path(i) != "":
			return i
	return -1
