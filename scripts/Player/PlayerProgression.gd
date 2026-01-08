extends Node
class_name PlayerProgression

signal total_changed(total_level: int, total_xp: int)
signal skill_changed(skill_id: String, level: int, xp: int)

# ---------------------------
# Total progression
# ---------------------------
var total_level: int = 1
var total_xp: int = 0

# ---------------------------
# Skills
# Each entry:
# { "level": int, "xp": int }
# ---------------------------
var skills: Dictionary = {}

func _ready() -> void:
	_init_skill("range")
	_emit_all()

func _init_skill(skill_id: String) -> void:
	if not skills.has(skill_id):
		skills[skill_id] = {
			"level": 1,
			"xp": 0
		}

# ---------------------------
# XP curves (tweak freely)
# ---------------------------
func xp_to_next_total(level: int) -> int:
	return int(round(100.0 * pow(float(level), 0.5)))

func xp_to_next_skill(level: int) -> int:
	return int(round(80.0 * pow(float(level), 0.6)))

# ---------------------------
# Public API
# ---------------------------
func gain_xp(amount: int, skill_id: String = "") -> void:
	if amount <= 0:
		return

	# Total XP
	total_xp += amount
	_process_total_levelups()

	# Skill XP
	if skill_id != "":
		_init_skill(skill_id)
		var data: Dictionary = skills[skill_id]
		data["xp"] = int(data["xp"]) + amount
		skills[skill_id] = data
		_process_skill_levelups(skill_id)

	_emit_all()

func get_skill_level(skill_id: String) -> int:
	_init_skill(skill_id)
	return int(skills[skill_id]["level"])

func get_skill_xp(skill_id: String) -> int:
	_init_skill(skill_id)
	return int(skills[skill_id]["xp"])

# ---------------------------
# Internals
# ---------------------------
func _process_total_levelups() -> void:
	while total_xp >= xp_to_next_total(total_level):
		total_xp -= xp_to_next_total(total_level)
		total_level += 1

func _process_skill_levelups(skill_id: String) -> void:
	var data: Dictionary = skills[skill_id]

	while int(data["xp"]) >= xp_to_next_skill(int(data["level"])):
		data["xp"] -= xp_to_next_skill(int(data["level"]))
		data["level"] += 1

	skills[skill_id] = data

func _emit_all() -> void:
	emit_signal("total_changed", total_level, total_xp)

	for k in skills.keys():
		var d: Dictionary = skills[k]
		emit_signal(
			"skill_changed",
			String(k),
			int(d["level"]),
			int(d["xp"])
		)
