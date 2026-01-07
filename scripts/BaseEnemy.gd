extends CharacterBody2D
class_name BaseEnemy

@export var max_health: int = 20
@export var move_speed: float = 140.0
@export var gravity: float = 1200.0
@export var stop_distance: float = 18.0

@export var drops: Array[DropEntry] = []
@export var drop_offset: Vector2 = Vector2(0, -8)
@export var drop_raycast_distance: float = 200.0
@export var drop_clearance: float = 6.0
const GROUND_MASK: int = 1 << 2  # Layer 3 only


@export var contact_damage_per_second: float = 20.0

@onready var contact_area: Area2D = $ContactArea

signal health_changed(current: int, max: int)
var health: int
var player: Node2D

var _damage_accumulator: float = 0.0

func _ready() -> void:
	health = max_health
	emit_signal("health_changed", health, max_health)
	player = get_tree().get_first_node_in_group("player") as Node2D

	# Ensure area overlap checks work reliably
	contact_area.monitoring = true
	contact_area.monitorable = true

func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	chase_player_x()
	move_and_slide()
	apply_contact_damage(delta)

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

func chase_player_x() -> void:
	if player == null or not is_instance_valid(player):
		velocity.x = 0.0
		return

	var dx := player.global_position.x - global_position.x
	if absf(dx) <= stop_distance:
		velocity.x = 0.0
	else:
		velocity.x = signf(dx) * move_speed

func apply_contact_damage(delta: float) -> void:
	# Damage-per-second based on actual overlaps (robust)
	var bodies := contact_area.get_overlapping_bodies()

	var target: Node = null
	for b in bodies:
		if b != null and is_instance_valid(b) and b.has_method("take_damage"):
			target = b
			break

	if target != null:
		_damage_accumulator += contact_damage_per_second * delta
		var whole_damage := int(_damage_accumulator)
		if whole_damage > 0:
			target.take_damage(whole_damage)
			_damage_accumulator -= float(whole_damage)
	else:
		_damage_accumulator = 0.0

func take_damage(amount: int) -> void:
	health -= amount
	health = max(health, 0)
	emit_signal("health_changed", health, max_health)
	if health <= 0:
		die()

func _try_drop_loot() -> void:
	if drops.is_empty():
		return

	# Godot 4 RNG
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	for entry in drops:
		if entry == null:
			continue
		if entry.pickup_scene == null or entry.weapon_scene == null:
			continue

		# Roll per entry (you can change to "one roll total" if you prefer)
		if rng.randf() <= entry.chance:
			_spawn_pickup(entry)
			# If you want ONLY ONE drop max, uncomment the next line:
			# break

func _spawn_pickup(entry: DropEntry) -> void:
	var pickup := entry.pickup_scene.instantiate() as WeaponPickup
	if pickup == null:
		push_warning("Enemy drop: pickup_scene is not a WeaponPickup.")
		return

	pickup.weapon_scene = entry.weapon_scene
	pickup.display_name = entry.display_name

	var ray_from := global_position + Vector2(0, -16)
	var ray_to := ray_from + Vector2(0, 800)

	var space := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(ray_from, ray_to)
	query.collision_mask = GROUND_MASK
	query.exclude = [self]

	var result := space.intersect_ray(query)

	var final_pos := global_position + Vector2(0, -24) # fallback

	if result.size() > 0:
		var hit_pos: Vector2 = result["position"]
		final_pos = hit_pos - Vector2(0, drop_clearance)
		_debug_draw_ray(ray_from, hit_pos, true)
	else:
		_debug_draw_ray(ray_from, ray_to, false)
		print("DROP RAY MISSED GROUND. from=", ray_from, " to=", ray_to, " mask=", GROUND_MASK)

	get_parent().add_child(pickup)
	pickup.global_position = final_pos


func _debug_draw_ray(from: Vector2, to: Vector2, hit: bool) -> void:
	# Draw for one frame using a temporary Line2D
	var line := Line2D.new()
	line.width = 2.0
	line.default_color = Color(0, 1, 0, 1) if hit else Color(1, 0, 0, 1)
	line.points = PackedVector2Array([from, to])

	# Add to the current scene so it renders in world space
	get_tree().current_scene.add_child(line)

	# Remove shortly after
	get_tree().create_timer(0.25).timeout.connect(line.queue_free)


func die() -> void:
	_try_drop_loot()
	queue_free()
