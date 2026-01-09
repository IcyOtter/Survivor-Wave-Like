extends Panel

@onready var coins_label: Label = $VBoxContainer/CoinsLabel
@onready var weapon_list: ItemList = $VBoxContainer/ItemList
@onready var hint_label: Label = $VBoxContainer/HintLabel
@onready var equip_button: Button = $VBoxContainer/ButtonsRow/EquipButton
@onready var close_button: Button = $VBoxContainer/ButtonsRow/CloseButton

@export var equipment_panel_path: NodePath

var _weapon_manager: WeaponManager = null
var _equipment_ui: Node = null
var _player: Node = null

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

	_bind_player_and_weapon_manager()
	_refresh()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("toggle_inventory"):
		visible = not visible
		if visible:
			_refresh()

	if visible and Input.is_action_just_pressed("ui_cancel"):
		visible = false

func _bind_player_and_weapon_manager() -> void:
	_player = get_tree().get_first_node_in_group("player")
	if _player == null:
		push_warning("InventoryUI: Player not found in group 'player'.")
		return

	_weapon_manager = _player.get_node_or_null("WeaponManager") as WeaponManager
	if _weapon_manager == null:
		push_warning("InventoryUI: WeaponManager not found under Player.")
		return

	if not _weapon_manager.inventory_updated.is_connected(_on_inventory_updated):
		_weapon_manager.inventory_updated.connect(_on_inventory_updated)

	# Bind coins signal (live updates)
	if _player.has_signal("coins_changed"):
		if not _player.coins_changed.is_connected(_on_coins_changed):
			_player.coins_changed.connect(_on_coins_changed)

	print("InventoryUI: Bound to WeaponManager successfully.")

func _on_inventory_updated() -> void:
	_refresh()

func _on_coins_changed(_coins: int) -> void:
	# If inventory is closed, you can still update; it’s cheap.
	_refresh_coins()

func _refresh() -> void:
	_refresh_coins()

	weapon_list.clear()

	if _weapon_manager == null or _weapon_manager.inventory == null:
		hint_label.text = "Inventory not available."
		equip_button.disabled = true
		return

	var inv := _weapon_manager.inventory

	for i in range(inv.items.size()):
		var item_name := inv.get_item_name(i)
		var qty := inv.get_item_qty(i)
		weapon_list.add_item("%s  x%d" % [item_name, qty])

	# Enable equip only if something is selected (weapon or ammo)
	var selected := weapon_list.get_selected_items()
	if selected.is_empty():
		equip_button.disabled = true
	else:
		var t := inv.get_item_type(selected[0])
		equip_button.disabled = not (t == "weapon" or t == "ammo")

	var equipped_text := "(none)"
	if inv.has_equipped_weapon():
		equipped_text = inv.get_equipped_weapon_name()

	hint_label.text = "Items: %d | Equipped: %s" % [inv.items.size(), equipped_text]

func _refresh_coins() -> void:
	if coins_label == null:
		return
	if _player == null or not is_instance_valid(_player):
		coins_label.text = "Coins: 0"
		return

	# Use property if present; fallback to method if you added get_coins()
	var coins_value: int = 0
	if "coins" in _player:
		coins_value = int(_player.get("coins"))
	elif _player.has_method("get_coins"):
		coins_value = int(_player.call("get_coins"))

	coins_label.text = "Coins: %d" % coins_value

func _on_item_selected(index: int) -> void:
	if _weapon_manager == null or _weapon_manager.inventory == null:
		equip_button.disabled = true
		return

	var t := _weapon_manager.inventory.get_item_type(index)
	equip_button.disabled = not (t == "weapon" or t == "ammo")

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
	elif t == "ammo":
		_weapon_manager.equip_ammo_from_inventory(index)
	else:
		push_warning("Equip: Unsupported item type: %s" % t)

	_refresh()

	if _equipment_ui != null and _equipment_ui.has_method("open"):
		_equipment_ui.call("open")

func _on_close_pressed() -> void:
	visible = false
