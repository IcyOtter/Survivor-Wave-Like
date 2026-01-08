extends CanvasLayer

@onready var total_label: Label = $Panel/VBox/TotalLabel
@onready var total_xp_bar: ProgressBar = $Panel/VBox/TotalXPBar
@onready var range_label: Label = $Panel/VBox/RangeLabel

var _total_level: int = 1
var _total_xp: int = 0
var _range_level: int = 1
var _range_xp: int = 0

func _ready() -> void:
	if not Progression.total_changed.is_connected(_on_total_changed):
		Progression.total_changed.connect(_on_total_changed)

	if not Progression.skill_changed.is_connected(_on_skill_changed):
		Progression.skill_changed.connect(_on_skill_changed)

	_total_level = Progression.total_level
	_total_xp = Progression.total_xp
	_range_level = Progression.get_skill_level("range")
	_range_xp = Progression.get_skill_xp("range")

	_refresh()

func _on_total_changed(total_level: int, total_xp: int) -> void:
	_total_level = total_level
	_total_xp = total_xp
	_refresh()

func _on_skill_changed(skill_id: String, level: int, xp: int) -> void:
	if skill_id == "range":
		_range_level = level
		_range_xp = xp
		_refresh()

func _refresh() -> void:
	var req: int = Progression.xp_to_next_total(_total_level)

	total_label.text = "Level: %d" % _total_level
	total_xp_bar.max_value = req
	total_xp_bar.value = clamp(_total_xp, 0, req)
	total_xp_bar.tooltip_text = "%d / %d XP" % [_total_xp, req]

	var range_req: int = Progression.xp_to_next_skill(_range_level)
	range_label.text = "Range: %d  (%d / %d XP)" % [_range_level, _range_xp, range_req]
