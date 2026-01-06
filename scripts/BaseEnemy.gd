extends CharacterBody2D
class_name BaseEnemy

@export var max_health: int = 20
@export var move_speed: float = 140.0
@export var gravity: float = 1200.0
@export var stop_distance: float = 18.0


@export var contact_damage_per_second: float = 20.0

@onready var contact_area: Area2D = $ContactArea

var health: int
var player: Node2D

var _damage_accumulator: float = 0.0

func _ready() -> void:
	health = max_health
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
	if health <= 0:
		die()

func die() -> void:
	queue_free()
