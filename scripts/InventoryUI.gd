extends Panel

@onready var weapon_list: ItemList = $VBoxContainer/WeaponList
@onready var hint_label: Label = $VBoxContainer/HintLabel

var _weapon_manager: WeaponManager = null

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)

	# Force WeaponList to have space inside VBoxContainer
	weapon_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	weapon_list.custom_minimum_size = Vector2(0, 260)

	_bind_weapon_manager()
	_refresh()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("toggle_inventory"):
		visible = not visible
		if visible:
			_refresh()

	if visible and Input.is_action_just_pressed("ui_cancel"):
		visible = false

func _bind_weapon_manager() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		push_warning("InventoryUI: Player not found in group 'player'.")
		return

	_weapon_manager = player.get_node_or_null("WeaponManager") as WeaponManager
	if _weapon_manager == null:
		push_warning("InventoryUI: WeaponManager not found under Player.")
		return

	# Connect to inventory updates so UI refreshes after pickups
	if not _weapon_manager.inventory_updated.is_connected(_on_inventory_updated):
		_weapon_manager.inventory_updated.connect(_on_inventory_updated)

	# Equip by double click / Enter
	if not weapon_list.item_activated.is_connected(_on_item_activated):
		weapon_list.item_activated.connect(_on_item_activated)

	print("InventoryUI: Bound to WeaponManager successfully.")

func _on_inventory_updated() -> void:
	_refresh()

func _refresh() -> void:
	weapon_list.clear()

	if _weapon_manager == null or _weapon_manager.inventory == null:
		hint_label.text = "Inventory not available."
		return

	var inv := _weapon_manager.inventory

	for i in range(inv.weapons.size()):
		var display_name := inv.get_weapon_name(i)

		if i == inv.equipped_index:
			display_name += "  (EQUIPPED)"

		weapon_list.add_item(display_name)

	hint_label.text = "Weapons: %d | Enter/Double-click to equip | I to toggle" % inv.weapons.size()

	# Debug (remove later)
	print("Inventory entries:", inv.weapons)
	print("WeaponList item_count=", weapon_list.item_count, " rect_size=", weapon_list.size)

func _on_item_activated(index: int) -> void:
	if _weapon_manager != null:
		_weapon_manager.equip_index(index)
		_refresh()
