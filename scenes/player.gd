extends CharacterBody2D

@export var move_speed: float = 260.0
@export var jump_velocity: float = -480.0
@export var gravity: float = 1200.0

func _physics_process(delta: float) -> void:
	# 1) Apply gravity when not on the ground
	if not is_on_floor():
		velocity.y += gravity * delta

	# 2) Handle jump (only when on the floor)
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# 3) Horizontal movement: left/right only
	var direction := Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	velocity.x = direction * move_speed

	# 4) Move with collision handling
	move_and_slide()
