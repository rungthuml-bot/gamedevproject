extends Control

@onready var back_button: Button = $MarginContainer/VBoxContainer/BackButton

func _ready() -> void:
	if back_button:
		back_button.pressed.connect(_on_back_button_pressed)
		back_button.grab_focus()

func _on_back_button_pressed() -> void:
	SceneTransition.change_scene("res://Scenes/ui/MainMenu.tscn", 0.5)
