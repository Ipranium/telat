extends Node2D

@onready var restart_ui: Control = $UI/RestartUI
@onready var reset_button: TextureButton = $UI/RestartUI/ResetButton
@onready var redo_button: TextureButton = $UI/RestartUI/RedoButton
@onready var player: GridPlayer = $CharacterBody2D
@onready var enemy: Enemy = $Enemy


func _ready() -> void:
	restart_ui.hide()
	reset_button.pressed.connect(_on_reset_pressed)
	redo_button.pressed.connect(_on_redo_pressed)
	player.died.connect(_show_end)
	enemy.died.connect(_show_end)


func _show_end() -> void:
	if restart_ui.visible:
		return
	restart_ui.show()
	var tree := get_tree()
	if tree:
		tree.paused = true


func _on_reset_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_redo_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://main_menu.tscn")
