extends Area2D
class_name BaseProjectile

@export var speed: float = 900.0
@export var lifetime: float = 2.0

# Projectile-specific damage modifiers
@export var damage_multiplier: float = 1.0   # e.g. 1.25 for magic bolt
@export var flat_damage_bonus: int = 0        # e.g. +2 for heavy arrow

@export var ignore_layer: int = 1

var direction: Vector2 = Vector2.RIGHT
var damage: int = 0   # FINAL damage, set by weapon

func _ready() -> void:
	set_collision_mask_value(ignore_layer, false)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	global_position += direction.normalized() * speed * delta

func apply_weapon_damage(weapon_damage: int) -> void:
	damage = int(round(weapon_damage * damage_multiplier)) + flat_damage_bonus

func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()

