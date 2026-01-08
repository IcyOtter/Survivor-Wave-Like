extends BaseWeapon
class_name ProjectileWeapon

@export var muzzle_path: NodePath = ^"Muzzle"
@export var aim_at_mouse: bool = true
@export var muzzle_offset: Vector2 = Vector2.ZERO

@onready var muzzle: Node2D = get_node_or_null(muzzle_path) as Node2D

func _do_fire() -> void:
	if item_def == null:
		push_warning("ProjectileWeapon: item_def is null (WeaponManager did not inject ItemDefinition).")
		return

	if item_def.projectile_scene == null:
		push_warning("ProjectileWeapon: item_def.projectile_scene is not set.")
		return

	var spawn_pos := global_position
	if muzzle != null:
		spawn_pos = muzzle.global_position
	else:
		spawn_pos = global_position + muzzle_offset

	var dir := Vector2.RIGHT
	if aim_at_mouse:
		dir = (get_global_mouse_position() - spawn_pos).normalized()
	else:
		dir = global_transform.x.normalized()

	var proj := item_def.projectile_scene.instantiate() as BaseProjectile
	if proj == null:
		push_warning("ProjectileWeapon: projectile_scene root is not BaseProjectile.")
		return

	proj.global_position = spawn_pos
	proj.direction = dir
	var range_bonus: int = Progression.get_skill_level("range") - 1
	var final_damage: int = base_damage + range_bonus

	proj.configure(
		item_def.projectile_speed,
		item_def.projectile_lifetime,
		item_def.projectile_rotate_to_direction,
		final_damage
	)


	get_tree().current_scene.add_child(proj)
