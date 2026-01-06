extends CharacterBody2D

@onready var weapon_manager: WeaponManager = $WeaponManager

@export var move_speed: float = 260.0
@export var jump_velocity: float = -480.0
@export var gravity: float = 1200.0


var _auto_fire_enabled: bool = false
var _fire_cooldown: float = 0.0


signal health_changed(current: int, max: int)

@export var max_health: int = 100
var health: int


func _ready() -> void:
	health = max_health
	emit_signal("health_changed", health, max_health)



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
	# Manual fire only when autofire is OFF
	if not _auto_fire_enabled and Input.is_action_just_pressed("fire"):
		if weapon_manager != null:
			weapon_manager.try_fire()

	# Autofire when enabled
	if _auto_fire_enabled:
		if weapon_manager != null:
			weapon_manager.try_fire()


func _try_fire() -> void:

	if _fire_cooldown > 0.0:
		return



# Player takes damage
func take_damage(amount: int) -> void:
	health = max(health - amount, 0)
	emit_signal("health_changed", health, max_health)

	if health <= 0:
		die()

func heal(amount: int) -> void:
	health = min(health + amount, max_health)
	emit_signal("health_changed", health, max_health)

# Player death
func die() -> void:
	print("Player died")
	queue_free()
