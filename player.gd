class_name GridPlayer
extends CharacterBody2D

signal died

const TILE_SIZE := 64

var current_grid_pos := Vector2i(8, 5)
var is_moving := false
var is_dead := false

var floor_rect := Rect2i()

@onready var tilemap: TileMapLayer = $"../TileMapLayer"
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var rock_manager: RockManager = $"../RockManager"

func _ready() -> void:
	position = grid_to_world(current_grid_pos)
	sprite.stop()
	floor_rect = tilemap.get_used_rect()

func grid_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * TILE_SIZE + TILE_SIZE * 0.5, cell.y * TILE_SIZE + TILE_SIZE * 0.5)
	

func _physics_process(_delta: float) -> void:
	if is_dead or is_moving:
		return
	
	
	var input_dir = Vector2i.ZERO
	if Input.is_action_just_pressed("ui_right"):
		input_dir = Vector2i.RIGHT
		sprite.frame = 3
	elif Input.is_action_just_pressed("ui_left"):
		input_dir = Vector2i.LEFT
		sprite.frame = 2
	elif Input.is_action_just_pressed("ui_down"):
		input_dir = Vector2i.DOWN
		sprite.frame = 0
	elif Input.is_action_just_pressed("ui_up"):
		input_dir = Vector2i.UP
		sprite.frame = 1
	
	if input_dir != Vector2i.ZERO:
		move_to_grid(current_grid_pos + input_dir)

func move_to_grid(target_grid_pos: Vector2i) -> void:
	if not floor_rect.has_point(target_grid_pos):
		return

	var source := tilemap.get_cell_source_id(target_grid_pos)
	if source == RockManager.ROCK_SOURCE:
		var push_dir := target_grid_pos - current_grid_pos
		if not rock_manager.try_push(target_grid_pos, target_grid_pos + push_dir):
			return
	elif source != -1:
		tilemap.erase_cell(target_grid_pos)

	sprite.play("default")

	is_moving = true
	var tween := create_tween()
	tween.tween_property(self, "position", grid_to_world(target_grid_pos), 0.15)
	await tween.finished

	sprite.stop()
	current_grid_pos = target_grid_pos
	is_moving = false

func die(reason: String = "unknown") -> void:
	if is_dead:
		return
	is_dead = true
	sprite.stop()
	modulate = Color(1, 0.25, 0.25)
	print("Player died — ", reason)
	died.emit()
