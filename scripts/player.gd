extends CharacterBody2D

@onready var weapon_manager: WeaponManager = $WeaponManager
@onready var pickup_detector: Area2D = $PickupDetector

@export var move_speed: float = 260.0
@export var jump_velocity: float = -480.0
@export var gravity: float = 1200.0

var _auto_fire_enabled: bool = false
var _nearby_pickups: Array[WeaponPickup] = []

signal health_changed(current: int, max: int)
@export var max_health: int = 100
var health: int

func _ready() -> void:
	health = max_health
	emit_signal("health_changed", health, max_health)

	if pickup_detector != null:
		pickup_detector.area_entered.connect(_on_pickup_area_entered)
		pickup_detector.area_exited.connect(_on_pickup_area_exited)
	else:
		push_warning("Player: PickupDetector node not found.")

func _physics_process(delta: float) -> void:
	# -----------------
	# Movement
	# -----------------
	if not is_on_floor():
		velocity.y += gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	var direction := Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	velocity.x = direction * move_speed
	move_and_slide()

	# -----------------
	# Auto-fire toggle
	# -----------------
	if Input.is_action_just_pressed("toggle_autofire"):
		_auto_fire_enabled = not _auto_fire_enabled

	# -----------------
	# Firing logic
	# -----------------
	if not _auto_fire_enabled and Input.is_action_just_pressed("fire"):
		if weapon_manager != null:
			weapon_manager.try_fire()

	if _auto_fire_enabled:
		if weapon_manager != null:
			weapon_manager.try_fire()

	# -----------------
	# Pickup (E)
	# -----------------
	if Input.is_action_just_pressed("interact"):
		_try_pickup_weapon()

func _on_pickup_area_entered(area: Area2D) -> void:
	if area is WeaponPickup:
		_nearby_pickups.append(area)

func _on_pickup_area_exited(area: Area2D) -> void:
	if area is WeaponPickup:
		_nearby_pickups.erase(area)

func _try_pickup_weapon() -> void:
	# Remove invalid references
	_nearby_pickups = _nearby_pickups.filter(func(p): return p != null and is_instance_valid(p))

	if _nearby_pickups.is_empty():
		return

	# Pick nearest pickup
	var nearest: WeaponPickup = null
	var best_dist := INF

	for p in _nearby_pickups:
		var d := global_position.distance_squared_to(p.global_position)
		if d < best_dist:
			best_dist = d
			nearest = p

	if nearest == null:
		return

	# Add to inventory (does NOT auto-equip)
	var added := weapon_manager.add_weapon_from_pickup(nearest)
	if added:
		print("Picked up:", nearest.get_display_name())
		nearest.queue_free()

# Player takes damage
func take_damage(amount: int) -> void:
	health = max(health - amount, 0)
	emit_signal("health_changed", health, max_health)

	if health <= 0:
		die()

func heal(amount: int) -> void:
	health = min(health + amount, max_health)
	emit_signal("health_changed", health, max_health)

func die() -> void:
	print("Player died")
	queue_free()
