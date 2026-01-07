@tool
extends Area2D
class_name WeaponPickup

@export var weapon_scene: PackedScene:
	set(value):
		weapon_scene = value
		_update_visual()

@export var display_name: String = ""
@export var fallback_texture: Texture2D

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	_update_visual()

func _update_visual() -> void:
	if sprite == null:
		return

	var tex := _extract_weapon_texture()
	if tex != null:
		sprite.texture = tex
	elif fallback_texture != null:
		sprite.texture = fallback_texture
	else:
		sprite.texture = null

	sprite.visible = true
	sprite.modulate = Color(1, 1, 1, 1)
	sprite.scale = Vector2.ONE
	sprite.z_index = 10

func _extract_weapon_texture() -> Texture2D:
	if weapon_scene == null:
		return null

	var inst := weapon_scene.instantiate()
	if inst == null:
		return null

	var found := _find_first_sprite(inst)
	var tex: Texture2D = found.texture if found != null else null

	inst.queue_free()
	return tex

func _find_first_sprite(node: Node) -> Sprite2D:
	for child in node.get_children():
		if child is Sprite2D:
			return child
		if child is Node:
			var nested := _find_first_sprite(child)
			if nested != null:
				return nested
	return null

func get_weapon_path() -> String:
	return weapon_scene.resource_path if weapon_scene != null else ""

func get_display_name() -> String:
	if display_name.strip_edges() != "":
		return display_name
	if weapon_scene != null and weapon_scene.resource_path != "":
		return weapon_scene.resource_path.get_file().get_basename()
	return "Unknown Weapon"
