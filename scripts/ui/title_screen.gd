extends Control

var transitioning := false

# =========================================================
# BGM
# =========================================================
var title_music: AudioStream = preload("res://assets/audio/bgm/sound_main.mp3")


func _ready() -> void:
	AudioManager.play_music(title_music)


# =========================================================
# INPUT
# =========================================================
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


# =========================================================
# SCENE TRANSITION
# =========================================================
func transition_to_main_menu() -> void:
	if transitioning:
		return

	transitioning = true
	
	AudioManager.play_transition_impact()

	SceneTransition.change_scene("res://scenes/ui/MainMenu.tscn", 0.5)
