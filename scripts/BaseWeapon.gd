extends Node2D
class_name BaseWeapon

@export var projectile_scene: PackedScene
@export var fire_rate: float = 8.0          # shots per second
@export var base_damage: int = 5
@export var muzzle_forward_offset: float = 12.0
@export var ignore_layer: int = 1            # Player collision layer

# Visual handling
@export var use_start_position_as_right_offset: bool = true
@export var right_side_offset: Vector2 = Vector2(16, -4)

@export var sprite_path: NodePath = ^"Sprite2D"
@export var muzzle_path: NodePath = ^"Muzzle"

var _cooldown: float = 0.0
var _right_offset: Vector2

@onready var _sprite: Sprite2D = get_node_or_null(sprite_path) as Sprite2D
@onready var _muzzle: Marker2D = get_node_or_null(muzzle_path) as Marker2D

func _ready() -> void:
	if use_start_position_as_right_offset:
		_right_offset = position
	else:
		_right_offset = right_side_offset

func _process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	_update_side_and_flip_from_mouse()

func can_fire() -> bool:
	return _cooldown <= 0.0 and projectile_scene != null and _muzzle != null

func fire() -> void:
	if not can_fire():
		return

	_update_side_and_flip_from_mouse()

	var aim_dir := _get_aim_direction()

	var proj := projectile_scene.instantiate() as Area2D

	# Set properties BEFORE adding to the tree
	proj.direction = aim_dir
	proj.global_position = _muzzle.global_position + aim_dir * muzzle_forward_offset

	# Apply combined damage (weapon → projectile)
	if proj.has_method("apply_weapon_damage"):
		proj.apply_weapon_damage(base_damage)
	elif "damage" in proj:
		# Fallback for simple projectiles
		proj.damage = base_damage


	# Prevent projectile from hitting the player
	proj.set_collision_mask_value(ignore_layer, false)

	get_tree().current_scene.add_child(proj)

	_cooldown = 1.0 / fire_rate

func _get_aim_direction() -> Vector2:
	var mouse_pos := get_global_mouse_position()
	var aim_vec := mouse_pos - _muzzle.global_position
	if aim_vec.length() < 0.001:
		return Vector2.RIGHT
	return aim_vec.normalized()

func _update_side_and_flip_from_mouse() -> void:
	if _sprite == null or _muzzle == null:
		return

	var mouse_pos := get_global_mouse_position()
	var aiming_left := mouse_pos.x < global_position.x
	var dir := -1 if aiming_left else 1

	# Move weapon to left/right side of player
	position = Vector2(abs(_right_offset.x) * dir, _right_offset.y)

	# Flip sprite visually
	_sprite.flip_h = aiming_left

	# Mirror muzzle to the front of the weapon
	_muzzle.position.x = abs(_muzzle.position.x) * dir
