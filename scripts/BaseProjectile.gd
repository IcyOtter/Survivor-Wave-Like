extends Area2D
class_name BaseProjectile

@export var ignore_layer: int = 1

var direction: Vector2 = Vector2.RIGHT
var speed: float = 900.0
var lifetime: float = 2.0
var rotate_to_direction: bool = true

# Damage is set by the weapon only
var damage: int = 0

func _ready() -> void:
	set_collision_mask_value(ignore_layer, false)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	global_position += direction.normalized() * speed * delta

	if rotate_to_direction and direction.length() > 0.0001:
		rotation = direction.angle()

func configure(speed_in: float, lifetime_in: float, rotate_in: bool, damage_in: int) -> void:
	speed = speed_in
	lifetime = lifetime_in
	rotate_to_direction = rotate_in
	damage = damage_in

func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.call("take_damage", damage)
	queue_free()
