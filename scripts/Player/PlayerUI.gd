extends CanvasLayer

@onready var health_bar: ProgressBar = $BarContainer/PlayerHealthBar
@onready var health_text: Label = $BarContainer/PlayerHealthBar/HealthText

@onready var xp_bar: ProgressBar = $BarContainer/PlayerXPBar
@onready var xp_text: Label = $BarContainer/PlayerXPBar/XPText

var _player: Node = null
var _total_level: int = 1
var _total_xp: int = 0

func _ready() -> void:
	_bind_player()
	_bind_progression()
	_refresh_xp()

func _bind_player() -> void:
	_player = get_tree().get_first_node_in_group("player")
	if _player == null:
		push_warning("PlayerUI: Player not found in group 'player'.")
		return

	if _player.has_signal("health_changed"):
		if not _player.health_changed.is_connected(_on_player_health_changed):
			_player.health_changed.connect(_on_player_health_changed)

func _bind_progression() -> void:
	if not Progression.total_changed.is_connected(_on_total_changed):
		Progression.total_changed.connect(_on_total_changed)

	_total_level = Progression.total_level
	_total_xp = Progression.total_xp

func _on_player_health_changed(current: int, max_health: int) -> void:
	health_bar.max_value = max_health
	health_bar.value = current
	_refresh_xp()

func _on_total_changed(total_level: int, total_xp: int) -> void:
	_total_level = total_level
	_total_xp = total_xp
	_refresh_xp()

func _refresh_xp() -> void:
	var req: int = Progression.xp_to_next_total(_total_level)

	xp_bar.max_value = req
	xp_bar.value = clamp(_total_xp, 0, req)

	# Display numbers on the bar
	xp_text.text = "%d / %d XP" % [_total_xp, req]
	health_text.text = "%d / %d HP" % [health_bar.value, health_bar.max_value]
