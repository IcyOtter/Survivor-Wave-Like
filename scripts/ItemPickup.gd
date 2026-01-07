@tool
extends Area2D
class_name ItemPickup

@export var item_def: ItemDefinition:
	set(value):
		item_def = value
		_update_visual()

@export var quantity: int = 1

# Optional fallback if item_def has no icon set
@export var fallback_texture: Texture2D

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	_update_visual()

func _update_visual() -> void:
	# In editor, setters can run before _ready(), so sprite may be null.
	if sprite == null:
		sprite = get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null:
		return

	var tex: Texture2D = null
	if item_def != null and item_def.icon != null:
		tex = item_def.icon
	elif fallback_texture != null:
		tex = fallback_texture

	sprite.texture = tex
	sprite.visible = (tex != null)

	# Keep it visible above tiles
	sprite.z_index = 50

func get_display_name() -> String:
	if item_def != null:
		return item_def.display_name
	return "Unknown Item"
