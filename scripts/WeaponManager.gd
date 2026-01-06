extends Node
class_name WeaponManager

signal weapon_equipped(weapon: Node)

@export var weapon_socket_path: NodePath = ^"../WeaponSocket"

# Drag your weapon scenes here in the Inspector (Bow.tscn, Staff.tscn, etc.)
@export var slot_1_scene: PackedScene
@export var slot_2_scene: PackedScene
@export var slot_3_scene: PackedScene

var _socket: Node2D
var current_weapon: BaseWeapon = null

func _ready() -> void:
	_socket = get_node_or_null(weapon_socket_path) as Node2D
	if _socket == null:
		push_error("WeaponManager: WeaponSocket not found. Check weapon_socket_path.")
		return

	# Equip slot 1 by default if available
	if slot_1_scene != null:
		equip_scene(slot_1_scene)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("equip_slot_1"):
		equip_slot(1)
	elif Input.is_action_just_pressed("equip_slot_2"):
		equip_slot(2)
	elif Input.is_action_just_pressed("equip_slot_3"):
		equip_slot(3)

func equip_slot(slot: int) -> void:
	match slot:
		1:
			if slot_1_scene: equip_scene(slot_1_scene)
		2:
			if slot_2_scene: equip_scene(slot_2_scene)
		3:
			if slot_3_scene: equip_scene(slot_3_scene)

func equip_scene(scene: PackedScene) -> void:
	if _socket == null or scene == null:
		return

	# Remove existing weapon instance
	for child in _socket.get_children():
		child.queue_free()

	var weapon_node := scene.instantiate()
	_socket.add_child(weapon_node)

	current_weapon = weapon_node as BaseWeapon
	if current_weapon == null:
		push_warning("WeaponManager: Equipped scene is not a BaseWeapon. Attach BaseWeapon.gd to the weapon root.")

	emit_signal("weapon_equipped", weapon_node)

func try_fire() -> void:
	if current_weapon != null:
		current_weapon.fire()
