class_name RockManager
extends Node2D

const ROCK_SOURCE := 1
const ROCK_ATLAS := Vector2i(4, 2)
const FALL_DELAY := 0.75
const FALL_STEP := 0.12

enum State { RESTING, PENDING, FALLING }

class Rock:
	var cell: Vector2i
	var state: int = State.RESTING
	var timer: float = 0.0


@onready var tilemap: TileMapLayer = $"../TileMapLayer"
@onready var player: GridPlayer = $"../CharacterBody2D"
@onready var enemy: Enemy = $"../Enemy"

var _rocks: Array[Rock] = []
var _bounds := Rect2i()


func _ready() -> void:
	_bounds = tilemap.get_used_rect()
	for y in range(_bounds.position.y, _bounds.end.y):
		for x in range(_bounds.position.x, _bounds.end.x):
			var cell := Vector2i(x, y)
			if tilemap.get_cell_source_id(cell) == ROCK_SOURCE:
				var rock := Rock.new()
				rock.cell = cell
				_rocks.append(rock)


func _physics_process(delta: float) -> void:
	for rock in _rocks:
		if rock.state == State.RESTING:
			if not _has_support(rock.cell):
				rock.state = State.PENDING
				rock.timer = FALL_DELAY
		elif rock.state == State.PENDING:
			rock.timer -= delta
			if rock.timer <= 0.0:
				rock.state = State.FALLING
		elif rock.state == State.FALLING:
			rock.timer -= delta
			if rock.timer <= 0.0:
				if _fall_step(rock):
					rock.timer = FALL_STEP
				else:
					rock.state = State.RESTING


func _has_support(cell: Vector2i) -> bool:
	return tilemap.get_cell_source_id(cell + Vector2i.DOWN) != -1


func _fall_step(rock: Rock) -> bool:
	var below := rock.cell + Vector2i.DOWN
	if not _bounds.has_point(below) or tilemap.get_cell_source_id(below) != -1:
		return false
	tilemap.erase_cell(rock.cell)
	tilemap.set_cell(below, ROCK_SOURCE, ROCK_ATLAS)
	rock.cell = below
	_crush_check(below)
	return true


func try_push(from: Vector2i, to: Vector2i) -> bool:
	if not _bounds.has_point(to):
		return false
	if tilemap.get_cell_source_id(to) != -1:
		return false
	if is_instance_valid(enemy) and enemy.cell == to:
		return false

	tilemap.erase_cell(from)
	tilemap.set_cell(to, ROCK_SOURCE, ROCK_ATLAS)
	for rock in _rocks:
		if rock.cell == from:
			rock.cell = to
			rock.state = State.RESTING
			rock.timer = 0.0
			break
	return true


func _crush_check(cell: Vector2i) -> void:
	if _player_cell() == cell:
		player.die("crushed by a falling rock")
	if is_instance_valid(enemy) and enemy.cell == cell:
		enemy.die()


func _player_cell() -> Vector2i:
	return tilemap.local_to_map(tilemap.to_local(player.global_position))
