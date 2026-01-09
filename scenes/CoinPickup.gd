extends Area2D
class_name CoinPickup

@export var value: int = 1

@onready var label: Label = get_node_or_null("Label") as Label

func _ready() -> void:
	monitoring = true
	monitorable = true

	_update_label()

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func set_value(v: int) -> void:
	value = max(v, 0)
	_update_label()

func _update_label() -> void:
	# Optional: if you added a Label child for debugging
	if label != null:
		label.text = str(value)

func _on_body_entered(body: Node) -> void:
	if body != null and is_instance_valid(body) and body.is_in_group("player"):
		if body.has_method("add_coins"):
			body.call("add_coins", value)
		queue_free()
