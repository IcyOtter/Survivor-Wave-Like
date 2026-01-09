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

# Runtime-applied stats (from npc_def)
var max_health: int = 20
var move_speed: float = 140.0
var stop_distance: float = 18.0
@export var contact_damage: int = 10
@export var contact_damage_interval: float = 1.0
var _touching_target: Node = null
var _contact_timer: float = 0.0
var drops: Array[DropEntry] = []
var coin_drops: Array[CoinDropEntry] = []

@export var drop_offset: Vector2 = Vector2(0, -8)
@export var drop_raycast_distance: float = 200.0
@export var drop_clearance: float = 6.0
const GROUND_MASK: int = 1 << 2  # Layer 3 only

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player") as Node2D

	# Ensure overlap checks work reliably
	contact_area.monitoring = true
	contact_area.monitorable = true
	if not contact_area.body_entered.is_connected(_on_contact_body_entered):
		contact_area.body_entered.connect(_on_contact_body_entered)

	if not contact_area.body_exited.is_connected(_on_contact_body_exited):
		contact_area.body_exited.connect(_on_contact_body_exited)

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
	contact_damage = npc_def.contact_damage
	drops = npc_def.drops
	coin_drops = npc_def.coin_drops

	# Optional sprite convenience
	if sprite != null:
		if npc_def.sprite_texture != null:
			sprite.texture = npc_def.sprite_texture
		sprite.scale = npc_def.sprite_scale

func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_chase_player_x()
	move_and_slide()
	apply_contact_damage(delta)

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

func apply_contact_damage(delta: float) -> void:
	if _touching_target == null or not is_instance_valid(_touching_target):
		_touching_target = null
		_contact_timer = 0.0
		return

	_contact_timer += delta

	while _contact_timer >= contact_damage_interval:
		_touching_target.call("take_damage", contact_damage)
		_contact_timer -= contact_damage_interval



func take_damage(amount: int) -> void:
	health = max(health - amount, 0)
	emit_signal("health_changed", health, max_health)
	if health <= 0:
		die()

func die() -> void:
	_try_drop_loot()
	_try_drop_coins()

		# Award XP (total + range skill for now)
	if npc_def != null and npc_def.xp_reward > 0:
		Progression.gain_xp(npc_def.xp_reward, "range")

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

func _try_drop_coins() -> void:
	if coin_drops.is_empty():
		return

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()

	for entry: CoinDropEntry in coin_drops:
		if entry == null:
			continue
		if entry.coin_pickup_scene == null:
			continue

		if rng.randf() <= entry.chance:
			var min_v: int = maxi(entry.min_value, 0)
			var max_v: int = maxi(entry.max_value, min_v)
			var value: int = rng.randi_range(min_v, max_v)

			# Defer spawn to avoid physics flush issues (same as your item drop)
			call_deferred("_spawn_coin_pickup_deferred", entry, value)
			# If you only want ONE coin drop entry max, you can break here:
			# break

func _spawn_coin_pickup_deferred(entry: CoinDropEntry, value: int) -> void:
	var coin := entry.coin_pickup_scene.instantiate()
	if coin == null:
		push_warning("Enemy coin drop: failed to instantiate coin_pickup_scene.")
		return

	# Standardized API: CoinPickup.gd implements set_value(v)
	if coin.has_method("set_value"):
		coin.call("set_value", value)
	else:
		push_warning("Enemy coin drop: coin pickup scene script is missing set_value(v).")

	# Ground placement (same as your item drop)
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

	parent.call_deferred("add_child", coin)
	coin.set_deferred("global_position", final_pos)

func _on_contact_body_entered(body: Node) -> void:
	# If you want to be stricter, check group "player" instead.
	if body != null and is_instance_valid(body) and body.has_method("take_damage"):
		_touching_target = body
		_contact_timer = 0.0

func _on_contact_body_exited(body: Node) -> void:
	if body == _touching_target:
		_touching_target = null
		_contact_timer = 0.0
