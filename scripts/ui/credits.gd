extends Control

@onready var back_button: Button = $MarginContainer/VBoxContainer/BackButton

func _ready() -> void:
	if back_button:
		back_button.pressed.connect(_on_back_button_pressed)
		back_button.grab_focus()

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/ui/MainMenu.tscn")
