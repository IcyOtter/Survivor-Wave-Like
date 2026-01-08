extends CharacterBody2D
class_name BaseEnemy

@export var gravity: float = 1200.0

# Assign this in the enemy scene or by spawner
@export var npc_def: NPCDefinition

@onready var contact_area: Area2D = $ContactArea
@onready var sprite: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D

signal health_changed(current: int, max: int)

var health: int = 1
var player: Node2D = null
var _damage_accumulator: float = 0.0

# Runtime-applied stats (from npc_def)
var max_health: int = 20
var move_speed: float = 140.0
var stop_distance: float = 18.0
var contact_damage_per_second: float = 20.0
var drops: Array[DropEntry] = []

@export var drop_offset: Vector2 = Vector2(0, -8)
@export var drop_raycast_distance: float = 200.0
@export var drop_clearance: float = 6.0
const GROUND_MASK: int = 1 << 2  # Layer 3 only

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player") as Node2D

	# Ensure overlap checks work reliably
	contact_area.monitoring = true
	contact_area.monitorable = true

	_apply_definition()

	health = max_health
	emit_signal("health_changed", health, max_health)

func _apply_definition() -> void:
	if npc_def == null:
		push_warning("BaseEnemy: npc_def is null. Using defaults.")
		return

	if npc_def.id.strip_edges() == "":
		push_warning("BaseEnemy: npc_def.id is empty. Set a unique id.")

	max_health = npc_def.max_health
	move_speed = npc_def.move_speed
	stop_distance = npc_def.stop_distance
	contact_damage_per_second = npc_def.contact_damage_per_second
	drops = npc_def.drops

	# Optional sprite convenience
	if sprite != null:
		if npc_def.sprite_texture != null:
			sprite.texture = npc_def.sprite_texture
		sprite.scale = npc_def.sprite_scale

func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_chase_player_x()
	move_and_slide()
	_apply_contact_damage(delta)

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

func _chase_player_x() -> void:
	if player == null or not is_instance_valid(player):
		velocity.x = 0.0
		return

	var dx := player.global_position.x - global_position.x
	if absf(dx) <= stop_distance:
		velocity.x = 0.0
	else:
		velocity.x = signf(dx) * move_speed

func _apply_contact_damage(delta: float) -> void:
	var bodies := contact_area.get_overlapping_bodies()

	var target: Node = null
	for b in bodies:
		if b != null and is_instance_valid(b) and b.has_method("take_damage"):
			target = b
			break

	if target != null:
		_damage_accumulator += contact_damage_per_second * delta
		var whole := int(_damage_accumulator)
		if whole > 0:
			target.call("take_damage", whole)
			_damage_accumulator -= float(whole)
	else:
		_damage_accumulator = 0.0

func take_damage(amount: int) -> void:
	health = max(health - amount, 0)
	emit_signal("health_changed", health, max_health)
	if health <= 0:
		die()

func die() -> void:
	_try_drop_loot()
	queue_free()

func _try_drop_loot() -> void:
	if drops.is_empty():
		return

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()

	for entry: DropEntry in drops:
		if entry == null:
			continue
		if entry.pickup_scene == null or entry.item_def == null:
			continue

		if rng.randf() <= entry.chance:
			var qty_min: int = maxi(entry.min_qty, 1)
			var qty_max: int = maxi(entry.max_qty, qty_min)
			var qty: int = rng.randi_range(qty_min, qty_max)

			# Defer the actual instantiation/add_child until after physics flush
			call_deferred("_spawn_pickup_deferred", entry, qty)
			# If you want ONLY ONE drop max, uncomment:
			# break

func _spawn_pickup_deferred(entry: DropEntry, qty: int) -> void:
	if entry == null or entry.pickup_scene == null or entry.item_def == null:
		return

	var pickup: ItemPickup = entry.pickup_scene.instantiate() as ItemPickup
	if pickup == null:
		push_warning("Enemy drop: pickup_scene is not an ItemPickup.")
		return

	pickup.item_def = entry.item_def
	pickup.quantity = qty

	var start_pos := global_position + Vector2(0, -16)

	var space := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(
		start_pos,
		start_pos + Vector2(0, 800)
	)
	query.collision_mask = GROUND_MASK
	query.exclude = [self]

	var result := space.intersect_ray(query)

	var final_pos := start_pos
	if result.size() > 0:
		final_pos = result["position"] - Vector2(0, drop_clearance)

	var parent := get_parent()
	if parent == null:
		parent = get_tree().current_scene

	parent.call_deferred("add_child", pickup)
	pickup.set_deferred("global_position", final_pos)
