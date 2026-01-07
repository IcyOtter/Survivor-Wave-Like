extends BaseWeapon
class_name ProjectileWeapon

@export var projectile_scene: PackedScene
@export var muzzle_path: NodePath = ^"Muzzle"

# If true, projectile direction is from spawn -> mouse
@export var aim_at_mouse: bool = true

# Used if aim_at_mouse is false
@export var fallback_forward: Vector2 = Vector2.RIGHT

# Optional: spawn offset if you don’t want to use a Muzzle node
@export var muzzle_offset: Vector2 = Vector2.ZERO

@onready var muzzle: Node2D = get_node_or_null(muzzle_path) as Node2D

func _ready() -> void:
	super._ready()

	if projectile_scene == null:
		push_warning("ProjectileWeapon: projectile_scene is not assigned.")

func _do_fire() -> void:
	if projectile_scene == null:
		return

	var spawn_pos := global_position
	if muzzle != null:
		spawn_pos = muzzle.global_position
	else:
		spawn_pos = global_position + muzzle_offset

	var dir := fallback_forward.normalized()
	if aim_at_mouse:
		dir = (get_global_mouse_position() - spawn_pos).normalized()
	else:
		dir = global_transform.x.normalized()

	var proj := projectile_scene.instantiate() as BaseProjectile
	if proj == null:
		push_warning("ProjectileWeapon: projectile_scene root is not BaseProjectile. Attach BaseProjectile.gd to the projectile root.")
		return

	proj.global_position = spawn_pos
	proj.direction = dir
	proj.apply_weapon_damage(base_damage)

	get_tree().current_scene.add_child(proj)
