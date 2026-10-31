class_name Enemy
extends CharacterBody2D

signal died


const TILE_SIZE := 64

@export var start_cell := Vector2i(14, 1)
@export var step_interval := 0.6

var cell := Vector2i.ZERO
var is_moving := false
var is_dead := false
var _neighbors: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]
var floor_rect := Rect2i()
var _timer := 0.0

@onready var tilemap: TileMapLayer = $"../TileMapLayer"
@onready var player: GridPlayer = $"../CharacterBody2D"
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	cell = start_cell
	position = grid_to_world(cell)
	floor_rect = tilemap.get_used_rect()
	sprite.stop()


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if player.is_dead:
		sprite.stop()
		return

	if cell == player.current_grid_pos:
		player.die("caught by an enemy")
		return

	if is_moving:
		return

	_timer += delta
	if _timer < step_interval:
		return
	_timer = 0.0

	var dir := _choose_dir()
	if dir != Vector2i.ZERO:
		_step(dir)


func grid_to_world(c: Vector2i) -> Vector2:
	return Vector2(c.x * TILE_SIZE + TILE_SIZE * 0.5, c.y * TILE_SIZE + TILE_SIZE * 0.5)


func _can_enter(c: Vector2i) -> bool:
	if not floor_rect.has_point(c):
		return false
	return tilemap.get_cell_source_id(c) == -1


func _choose_dir() -> Vector2i:
	var target := player.current_grid_pos
	if target == cell:
		return Vector2i.ZERO

	var came_from := {}
	var visited := {}
	visited[cell] = true
	var queue: Array[Vector2i] = [cell]

	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		if current == target:
			break
		for d in _neighbors:
			var next: Vector2i = current + d
			if visited.has(next):
				continue
			if next != target and not _can_enter(next):
				continue
			visited[next] = true
			came_from[next] = current
			queue.append(next)

	if not came_from.has(target):
		return Vector2i.ZERO

	var step: Vector2i = target
	while came_from[step] != cell:
		step = came_from[step]
	return step - cell


func _step(dir: Vector2i) -> void:
	sprite.play("default")
	is_moving = true
	var tween := create_tween()
	tween.tween_property(self, "position", grid_to_world(cell + dir), 0.15)
	await tween.finished
	cell += dir
	is_moving = false
	if cell == player.current_grid_pos:
		player.die("caught by an enemy")


func die() -> void:
	if is_dead:
		return
	is_dead = true
	sprite.stop()
	print("Enemy crushed by a falling rock")
	died.emit()
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)
