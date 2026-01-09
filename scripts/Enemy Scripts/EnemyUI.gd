extends Control
@export var enemy_path: NodePath

@onready var name_label: Label = $EnemyUIContainer/EnemyName
@onready var health_bar: ProgressBar = $EnemyUIContainer/EnemyHealthBar

var _enemy: Node = null

func _ready() -> void:
	_bind_enemy()

func _bind_enemy() -> void:
	_enemy = get_node_or_null(enemy_path)
	if _enemy == null:
		# Common pattern: UI is a child of the enemy, so parent is the enemy
		_enemy = get_parent()

	if _enemy == null:
		push_warning("EnemyUI: Could not find enemy node.")
		return

	# Set name immediately
	_set_enemy_name()

	# Bind health updates
	if _enemy.has_signal("health_changed"):
		if not _enemy.health_changed.is_connected(_on_health_changed):
			_enemy.health_changed.connect(_on_health_changed)

		# If enemy already has health/max_health variables, set initial value
		if "health" in _enemy and "max_health" in _enemy:
			_on_health_changed(int(_enemy.get("health")), int(_enemy.get("max_health")))

func _set_enemy_name() -> void:
	if name_label == null:
		return

	# Preferred: npc_def.display_name if present
	if "npc_def" in _enemy:
		var def = _enemy.get("npc_def")
		if def != null:
			# if NPCDefinition has display_name
			if "display_name" in def and String(def.get("display_name")).strip_edges() != "":
				name_label.text = String(def.get("display_name"))
				return
			# fallback to id
			if "id" in def and String(def.get("id")).strip_edges() != "":
				name_label.text = String(def.get("id"))
				return

	# Final fallback
	name_label.text = "Enemy"

func _on_health_changed(current: int, max_health: int) -> void:
	health_bar.max_value = max_health
	health_bar.value = current
