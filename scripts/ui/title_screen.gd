extends Control

var transitioning := false


func _unhandled_input(event: InputEvent) -> void:
	if transitioning:
		return

	var pressed := false

	# Keyboard
	if event is InputEventKey and event.pressed and not event.echo:
		pressed = true

	# Mouse
	elif event is InputEventMouseButton and event.pressed:
		pressed = true

	# Controller
	elif event is InputEventJoypadButton and event.pressed:
		pressed = true

	if pressed:
		transition_to_main_menu()


func transition_to_main_menu() -> void:
	if transitioning:
		return

	transitioning = true

	get_tree().change_scene_to_file("res://Scenes/ui/MainMenu.tscn")
