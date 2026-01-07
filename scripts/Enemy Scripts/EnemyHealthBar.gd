extends ProgressBar

@export var hide_when_full: bool = true

func _ready() -> void:
	var enemy := get_parent()
	if enemy == null:
		return

	min_value = 0
	max_value = enemy.max_health
	value = enemy.health

	if enemy.has_signal("health_changed"):
		if not enemy.health_changed.is_connected(_on_enemy_health_changed):
			enemy.health_changed.connect(_on_enemy_health_changed)

	_update_visibility()

func _on_enemy_health_changed(current: int, maxh: int) -> void:
	max_value = maxh
	value = current
	_update_visibility()

func _update_visibility() -> void:
	if hide_when_full:
		visible = value < max_value
	else:
		visible = true
