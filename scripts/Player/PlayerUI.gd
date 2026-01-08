extends CanvasLayer

# Player Health Bar UI
@onready var health_bar: ProgressBar = $PlayerHealthBar

func _ready() -> void:
	health_bar.visible = true
	health_bar.min_value = 0
	call_deferred("_bind_player")


func _bind_player() -> void:
	var player := get_tree().get_first_node_in_group("player")

	if player == null:
		push_error("PlayerUI: Player not found. Ensure Player is in group 'player'.")
		return

	if not player.has_signal("health_changed"):
		push_error("PlayerUI: Player missing signal 'health_changed'.")
		return

	# Initialize bar
	health_bar.max_value = player.max_health
	health_bar.value = player.health

	# Connect updates (avoid double-connect)
	if not player.health_changed.is_connected(_on_player_health_changed):
		player.health_changed.connect(_on_player_health_changed)

	print("PlayerUI: Health bar bound to player.")

func _on_player_health_changed(current: int, maxh: int) -> void:
	health_bar.max_value = maxh
	health_bar.value = current
