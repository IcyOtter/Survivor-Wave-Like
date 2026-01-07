extends Panel

@onready var weapon_list: ItemList = $VBoxContainer/WeaponList
@onready var hint_label: Label = $VBoxContainer/HintLabel
@onready var equip_button: Button = $VBoxContainer/ButtonsRow/EquipButton
@onready var close_button: Button = $VBoxContainer/ButtonsRow/CloseButton

@export var equipment_panel_path: NodePath

var _weapon_manager: WeaponManager = null
var _equipment_ui: Node = null

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)

	if not equip_button.pressed.is_connected(_on_equip_pressed):
		equip_button.pressed.connect(_on_equip_pressed)
	if not close_button.pressed.is_connected(_on_close_pressed):
		close_button.pressed.connect(_on_close_pressed)

	if not weapon_list.item_selected.is_connected(_on_item_selected):
		weapon_list.item_selected.connect(_on_item_selected)

	_equipment_ui = get_node_or_null(equipment_panel_path)
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

	if not _weapon_manager.inventory_updated.is_connected(_on_inventory_updated):
		_weapon_manager.inventory_updated.connect(_on_inventory_updated)

	print("InventoryUI: Bound to WeaponManager successfully.")

func _on_inventory_updated() -> void:
	_refresh()

func _refresh() -> void:
	weapon_list.clear()

	if _weapon_manager == null or _weapon_manager.inventory == null:
		hint_label.text = "Inventory not available."
		equip_button.disabled = true
		equip_button.text = "Equip"
		return

	var inv := _weapon_manager.inventory

	for i in range(inv.items.size()):
		var item_name := inv.get_item_name(i)
		var qty := inv.get_item_qty(i)
		weapon_list.add_item("%s  x%d" % [item_name, qty])

	# Button enable + label based on selection
	_update_equip_button_state()

	# Equipped status
	var weapon_text := "(none)"
	if inv.has_equipped_weapon():
		weapon_text = inv.get_equipped_weapon_name()


	hint_label.text = "Items: %d | Weapon: %s" % [inv.items.size(), weapon_text]

func _on_item_selected(_index: int) -> void:
	_update_equip_button_state()

func _update_equip_button_state() -> void:
	if _weapon_manager == null or _weapon_manager.inventory == null:
		equip_button.disabled = true
		equip_button.text = "Equip"
		return

	var inv := _weapon_manager.inventory
	var selected := weapon_list.get_selected_items()
	if selected.is_empty():
		equip_button.disabled = true
		equip_button.text = "Equip"
		return

	var index := selected[0]
	var t := inv.get_item_type(index)

	var can_equip := (t == "weapon")
	equip_button.disabled = not can_equip

	# Optional UX: change button text based on item type
	if t == "weapon":
		equip_button.text = "Equip Weapon"
	else:
		equip_button.text = "Equip"

func _on_equip_pressed() -> void:
	if _weapon_manager == null or _weapon_manager.inventory == null:
		print("Equip: WeaponManager or inventory is null.")
		return

	var selected := weapon_list.get_selected_items()
	if selected.is_empty():
		print("Equip: nothing selected.")
		return

	var index := selected[0]
	var inv := _weapon_manager.inventory
	var t := inv.get_item_type(index)

	print("Equip: index=", index, "type=", t, "name=", inv.get_item_name(index))

	if t == "weapon":
		_weapon_manager.equip_from_inventory(index)
	else:
		push_warning("Equip: Unsupported item type: %s" % t)
		return

	# Open equipment panel (optional)
	if _equipment_ui != null and _equipment_ui.has_method("open"):
		_equipment_ui.call("open")

	# Refresh UI (note: inventory_changed will also trigger refresh via signal)
	_refresh()

func _on_close_pressed() -> void:
	visible = false
