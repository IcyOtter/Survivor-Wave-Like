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

	# Wire buttons (do this once)
	if not equip_button.pressed.is_connected(_on_equip_pressed):
		equip_button.pressed.connect(_on_equip_pressed)
	if not close_button.pressed.is_connected(_on_close_pressed):
		close_button.pressed.connect(_on_close_pressed)

	# Wire list selection to enable equip
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
		return

	var inv := _weapon_manager.inventory

	for i in range(inv.weapons.size()):
		var display_name := inv.get_weapon_name(i)
		weapon_list.add_item(display_name)

	# Enable equip only if something is selected
	equip_button.disabled = weapon_list.get_selected_items().is_empty()

	# Show equipped status in the hint (optional)
	var equipped_text := "(none)"
	if inv.has_equipped_weapon():
		equipped_text = inv.get_equipped_name()

	hint_label.text = "Weapons: %d | Equipped: %s" % [inv.weapons.size(), equipped_text]


func _on_item_selected(_index: int) -> void:
	equip_button.disabled = false

func _on_equip_pressed() -> void:
	if _weapon_manager == null or _weapon_manager.inventory == null:
		print("Equip: WeaponManager or inventory is null.")
		return

	var selected := weapon_list.get_selected_items()
	print("Equip: selected indices =", selected)

	if selected.is_empty():
		print("Equip: nothing selected.")
		return

	var index := selected[0]
	print("Equip: equipping index", index, "name=", _weapon_manager.inventory.get_weapon_name(index))

	_weapon_manager.equip_from_inventory(index)

	# Open equipment panel if provided (optional)
	if _equipment_ui != null and _equipment_ui.has_method("open"):
		_equipment_ui.call("open")

	_refresh()

func _on_close_pressed() -> void:
	visible = false
