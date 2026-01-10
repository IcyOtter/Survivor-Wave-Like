extends BaseWeapon
class_name MeleeWeapon

@export var hitbox_path: NodePath = ^"Hitbox"

# How long the hitbox is active for a swing (seconds)
@export var swing_active_time: float = 0.12

# Optional: small delay before hitbox turns on (for animation timing)
@export var windup_time: float = 0.02

# Optional knockback applied to enemies that support it
@export var knockback_strength: float = 0.0

var _hitbox: Area2D
var _already_hit: Dictionary = {}  # InstanceID -> true
var _swinging: bool = false

func _ready() -> void:
	super._ready()

	_hitbox = get_node_or_null(hitbox_path) as Area2D
	if _hitbox == null:
		push_warning("%s: Hitbox not found at %s" % [name, hitbox_path])
		return

	# Start disabled; we only enable during a swing
	_hitbox.monitoring = false
	_hitbox.monitorable = true

	if not _hitbox.body_entered.is_connected(_on_hitbox_body_entered):
		_hitbox.body_entered.connect(_on_hitbox_body_entered)

func _do_fire() -> void:
	if _hitbox == null:
		return
	if _swinging:
		return

	_swinging = true
	_already_hit.clear()

	# Aim the weapon/hitbox toward mouse (optional but recommended)
	_face_mouse()

	# Windup (optional)
	if windup_time > 0.0:
		await get_tree().create_timer(windup_time).timeout

	# Enable hitbox briefly
	_hitbox.set_deferred("monitoring", true)

	await get_tree().create_timer(swing_active_time).timeout

	_hitbox.set_deferred("monitoring", false)
	_swinging = false

func _face_mouse() -> void:
	# Rotate weapon to face mouse (works well if weapon socket follows player)
	var dir: Vector2 = (get_global_mouse_position() - global_position)
	if dir.length() < 0.001:
		return
	rotation = dir.angle()

	# If you don't want rotation, comment rotation line above and instead flip sprite
	# e.g., $Sprite2D.flip_v or flip_h depending on your art.

func _on_hitbox_body_entered(body: Node) -> void:
	if body == null or not is_instance_valid(body):
		return

	# Prevent multi-hits in the same swing
	var id := body.get_instance_id()
	if _already_hit.has(id):
		return
	_already_hit[id] = true

	# Apply damage (damage is defined by the weapon via item_def/base_damage)
	if body.has_method("take_damage"):
		body.call("take_damage", base_damage)

	# Optional knockback if enemy supports velocity
	if knockback_strength > 0.0 and body is CharacterBody2D:
		var cb := body as CharacterBody2D
		var away := (cb.global_position - global_position).normalized()
		cb.velocity.x += away.x * knockback_strength
