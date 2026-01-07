extends Node
class_name WeaponManager

signal weapon_equipped(weapon: Node)
signal inventory_updated()

@export var weapon_socket_path: NodePath = ^"../WeaponSocket"

# Optional: starting weapon(s)
@export var starting_weapons: Array[PackedScene] = []

# Inventory resource (can be saved later)
@export var inventory: WeaponInventory

var _socket: Node2D
var current_weapon: BaseWeapon = null

func _ready() -> void:
	_socket = get_node_or_null(weapon_socket_path) as Node2D
	if _socket == null:
		push_error("WeaponManager: WeaponSocket not found. Check weapon_socket_path.")
		return

	if inventory == null:
		inventory = WeaponInventory.new()

	if not inventory.inventory_changed.is_connected(_on_inventory_changed):
		inventory.inventory_changed.connect(_on_inventory_changed)

	# Add starting weapons into inventory
	for w in starting_weapons:
		if w != null and w.resource_path != "":
			var path := w.resource_path
			var display_name := path.get_file().get_basename()
			inventory.add_weapon(path, display_name)

	# Optional: auto-equip first weapon if any
	if inventory.weapons.size() > 0 and inventory.equipped_index == -1:
		equip_index(0)

func _on_inventory_changed() -> void:
	emit_signal("inventory_updated")

func try_fire() -> void:
	if current_weapon != null:
		current_weapon.fire()

func add_weapon_scene(scene: PackedScene, display_name: String = "", auto_equip: bool = false) -> bool:
	if scene == null:
		return false
	if scene.resource_path == "":
		push_warning("WeaponManager: Weapon scene has no resource_path. Save the .tscn to disk.")
		return false

	var path := scene.resource_path
	if display_name.strip_edges() == "":
		display_name = path.get_file().get_basename()

	var added := inventory.add_weapon(path, display_name)

	# Only equip if explicitly requested
	if added and auto_equip:
		equip_index(inventory.weapons.size() - 1)

	return added

func add_weapon_from_pickup(pickup: WeaponPickup) -> bool:
	if pickup == null:
		return false

	var path := pickup.get_weapon_path()
	var display_name := pickup.get_display_name()

	var added := inventory.add_weapon(path, display_name)
	# inventory.add_weapon emits inventory_changed which triggers inventory_updated already
	return added

func equip_index(index: int) -> void:
	if inventory == null:
		return
	if index < 0 or index >= inventory.weapons.size():
		return

	var path := inventory.get_weapon_path(index)
	var scene := load(path) as PackedScene
	if scene == null:
		push_warning("WeaponManager: Could not load weapon scene at path: %s" % path)
		return

	_equip_scene(scene)
	inventory.equipped_index = index
	emit_signal("inventory_updated")

func _equip_scene(scene: PackedScene) -> void:
	if _socket == null or scene == null:
		return

	# Remove current weapon instance
	for child in _socket.get_children():
		child.queue_free()

	var weapon_node := scene.instantiate()
	_socket.add_child(weapon_node)

	current_weapon = weapon_node as BaseWeapon
	if current_weapon == null:
		push_warning("WeaponManager: Equipped scene is not a BaseWeapon. Attach BaseWeapon.gd to the weapon root.")

	emit_signal("weapon_equipped", weapon_node)

func unequip() -> void:
	if inventory == null:
		return
	if not inventory.has_equipped_weapon():
		return

	_return_equipped_to_inventory()

	# Remove current weapon instance
	if _socket != null:
		for child in _socket.get_children():
			child.queue_free()

	current_weapon = null
	inventory.emit_signal("inventory_changed")

func _return_equipped_to_inventory() -> void:
	if not inventory.has_equipped_weapon():
		return

	var entry := inventory.equipped_weapon
	inventory.equipped_weapon = {}
	inventory.weapons.append(entry)


func equip_from_inventory(index: int) -> void:
	if inventory == null:
		return
	if index < 0 or index >= inventory.weapons.size():
		return

	# If something is already equipped, return it to inventory first
	if inventory.has_equipped_weapon():
		_return_equipped_to_inventory()

	# Move selected entry into equipped slot
	var entry: Dictionary = inventory.weapons[index]
	inventory.weapons.remove_at(index)
	inventory.equipped_weapon = entry

	# Spawn the weapon scene on the socket
	var scene := load(String(entry["path"])) as PackedScene
	if scene == null:
		push_warning("WeaponManager: Could not load equipped weapon scene: %s" % String(entry["path"]))
		inventory.equipped_weapon = {}
		inventory.emit_signal("inventory_changed")
		return

	_equip_scene(scene)

	# Notify UI
	inventory.emit_signal("inventory_changed")
