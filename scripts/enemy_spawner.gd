extends Node2D

@export var enemy_scenes: Array[PackedScene] = []
@export var spawn_interval: float = 2.0
@export var max_alive_enemies: int = 10
@export var spawn_enabled: bool = true

@export var spawn_parent_path: NodePath = ^"../Enemies"
@export var spawn_points_path: NodePath = ^"SpawnPoints"

var _spawn_timer: float = 0.0

func _physics_process(delta: float) -> void:
	if not spawn_enabled:
		return

	if enemy_scenes.is_empty():
		return

	_spawn_timer -= delta
	if _spawn_timer > 0.0:
		return

	_spawn_timer = spawn_interval

	var enemies_parent := get_node_or_null(spawn_parent_path)
	if enemies_parent == null:
		return

	if enemies_parent.get_child_count() >= max_alive_enemies:
		return

	_spawn_enemy(enemies_parent)

func _spawn_enemy(enemies_parent: Node) -> void:
	var spawns := _get_spawn_points()
	if spawns.is_empty():
		return

	# Random spawn point
	var spawn_marker: Marker2D = spawns[randi() % spawns.size()]

	# Random enemy type
	var scene := enemy_scenes[randi() % enemy_scenes.size()]
	var enemy := scene.instantiate()
	enemies_parent.add_child(enemy)

	if enemy is Node2D:
		(enemy as Node2D).global_position = spawn_marker.global_position

func _get_spawn_points() -> Array[Marker2D]:
	var result: Array[Marker2D] = []

	var spawns_root := get_node_or_null(spawn_points_path)
	if spawns_root == null:
		return result

	for child in spawns_root.get_children():
		if child is Marker2D:
			result.append(child)

	return result
