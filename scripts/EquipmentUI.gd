extends Panel
class_name EquipmentUI

@onready var weapon_icon: TextureRect = $VBoxContainer/WeaponRow/WeaponIcon
@onready var weapon_value: Label = $VBoxContainer/WeaponRow/WeaponValue
@onready var unequip_weapon_button: Button = $VBoxContainer/ButtonsRow/UnequipWeaponButton
@onready var close_button: Button = $VBoxContainer/ButtonsRow/CloseButton

var _weapon_manager: WeaponManager = null

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)

	_bind_weapon_manager()

	if not unequip_weapon_button.pressed.is_connected(_on_unequip_weapon_pressed):
		unequip_weapon_button.pressed.connect(_on_unequip_weapon_pressed)

	if not close_button.pressed.is_connected(_on_close_pressed):
		close_button.pressed.connect(_on_close_pressed)

	# Optional: keep your double-click unequip on the label
	weapon_value.mouse_filter = Control.MOUSE_FILTER_STOP
	if not weapon_value.gui_input.is_connected(_on_weapon_value_gui_input):
		weapon_value.gui_input.connect(_on_weapon_value_gui_input)

	_refresh()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("toggle_equipment"):
		visible = not visible
		if visible:
			_refresh()

	if visible and Input.is_action_just_pressed("ui_cancel"):
		visible = false

func _bind_weapon_manager() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		push_warning("EquipmentUI: Player not found in group 'player'.")
		return

	_weapon_manager = player.get_node_or_null("WeaponManager") as WeaponManager
	if _weapon_manager == null:
		push_warning("EquipmentUI: WeaponManager not found under Player.")
		return

	if not _weapon_manager.inventory_updated.is_connected(_on_inventory_updated):
		_weapon_manager.inventory_updated.connect(_on_inventory_updated)

func _on_inventory_updated() -> void:
	_refresh()

func _refresh() -> void:
	if _weapon_manager == null or _weapon_manager.inventory == null:
		weapon_value.text = "(none)"
		weapon_icon.texture = null
		unequip_weapon_button.disabled = true
		return

	var inv := _weapon_manager.inventory

	if inv.has_equipped_weapon():
		weapon_value.text = inv.get_equipped_weapon_name()
		unequip_weapon_button.disabled = false

		var def: ItemDefinition = inv.get_equipped_weapon_def()
		if def != null and def.icon != null:
			weapon_icon.texture = def.icon
		else:
			weapon_icon.texture = null
	else:
		weapon_value.text = "(none)"
		weapon_icon.texture = null
		unequip_weapon_button.disabled = true

func _on_unequip_weapon_pressed() -> void:
	if _weapon_manager != null:
		_weapon_manager.unequip()

func _on_close_pressed() -> void:
	visible = false

func _on_weapon_value_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed and mb.double_click:
			if _weapon_manager != null and _weapon_manager.inventory != null:
				if _weapon_manager.inventory.has_equipped_weapon():
					_weapon_manager.unequip()
					_refresh()

func open() -> void:
	visible = true
	_refresh()
