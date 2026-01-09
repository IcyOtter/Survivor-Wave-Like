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

@export var item_pickup_scene: PackedScene  # set to your ItemPickup.tscn in Inspector

@export var drop_offset: Vector2 = Vector2(16, -8)
@export var drop_raycast_distance: float = 800.0
@export var drop_clearance: float = 6.0
@export var ground_mask: int = 1 << 2  # Layer 3 (match what you use for ground)



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
		emit_signal("weapon_equipped", weapon_node)
		return

	current_weapon.weapon_manager = self

	# Push ItemDefinition stats into the weapon (fire_rate/base_damage live on ItemDefinition)
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

func drop_item_from_inventory(index: int, amount: int = 1) -> void:
	if inventory == null:
		return
	if item_pickup_scene == null:
		push_warning("WeaponManager: item_pickup_scene is not set.")
		return
	if index < 0 or index >= inventory.items.size():
		return
	if amount <= 0:
		return

	var def: ItemDefinition = inventory.get_item_def(index)
	if def == null:
		push_warning("WeaponManager: Inventory item has no ItemDefinition.")
		return

	# Determine how many we can drop from this stack
	var current_qty: int = inventory.get_item_qty(index)
	var drop_qty: int = mini(amount, current_qty)
	if drop_qty <= 0:
		return

	# Remove from inventory first
	inventory.remove_item_by_index(index, drop_qty)

	# Spawn pickup deferred (safe around physics)
	call_deferred("_spawn_item_pickup_deferred", def, drop_qty)

func _spawn_item_pickup_deferred(def: ItemDefinition, qty: int) -> void:
	if def == null or qty <= 0:
		return
	if item_pickup_scene == null:
		return

	var pickup := item_pickup_scene.instantiate() as ItemPickup
	if pickup == null:
		push_warning("WeaponManager: item_pickup_scene is not an ItemPickup.")
		return

	pickup.item_def = def
	pickup.quantity = qty

	# Player position
	var owner_node := get_parent() as Node2D
	if owner_node == null:
		owner_node = get_tree().get_first_node_in_group("player") as Node2D
	if owner_node == null:
		push_warning("WeaponManager: Could not find player to drop near.")
		return

	var start_pos: Vector2 = owner_node.global_position + drop_offset

	# Raycast down to ground so the pickup doesn't spawn inside/under floor
	var space := owner_node.get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(
		start_pos,
		start_pos + Vector2(0, drop_raycast_distance)
	)
	query.collision_mask = ground_mask
	query.exclude = [owner_node]

	var result := space.intersect_ray(query)

	var final_pos := start_pos
	if result.size() > 0:
		final_pos = result["position"] - Vector2(0, drop_clearance)

	var parent := owner_node.get_parent()
	if parent == null:
		parent = get_tree().current_scene

	parent.add_child(pickup)
	pickup.global_position = final_pos
