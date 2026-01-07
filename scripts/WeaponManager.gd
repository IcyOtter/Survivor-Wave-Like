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
			inventory.add_weapon(w.resource_path)

	# Auto-equip first weapon if any
	if inventory.weapon_paths.size() > 0 and inventory.equipped_index == -1:
		equip_index(0)

func _on_inventory_changed() -> void:
	emit_signal("inventory_updated")

func try_fire() -> void:
	if current_weapon != null:
		current_weapon.fire()

func add_weapon_scene(scene: PackedScene, auto_equip: bool = false) -> bool:
	if scene == null:
		return false
	if scene.resource_path == "":
		push_warning("WeaponManager: Weapon scene has no resource_path. Save the .tscn to disk.")
		return false

	var added := inventory.add_weapon(scene.resource_path)

	# Only equip if explicitly requested
	if added and auto_equip:
		equip_index(inventory.weapon_paths.size() - 1)

	return added

func add_weapon_path(path: String, auto_equip: bool = false) -> bool:
	var added := inventory.add_weapon(path)

	# Only equip if explicitly requested
	if added and auto_equip:
		equip_index(inventory.weapon_paths.size() - 1)

	return added


func equip_index(index: int) -> void:
	if inventory == null:
		return
	if index < 0 or index >= inventory.weapon_paths.size():
		return

	var path := inventory.weapon_paths[index]
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

