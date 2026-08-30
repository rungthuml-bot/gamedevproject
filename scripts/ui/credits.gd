extends Control

@onready var back_button: Button = $MarginContainer/VBoxContainer/BackButton

func _ready() -> void:
	if back_button:
		back_button.pressed.connect(_on_back_button_pressed)
		back_button.grab_focus()

func _on_back_button_pressed() -> void:
	SceneTransition.change_scene("res://Scenes/ui/MainMenu.tscn", 0.5)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if back_button and not back_button.disabled:
			get_viewport().set_input_as_handled()
			back_button.pressed.emit()
