extends Control

var transitioning := false

# =========================================================
# BGM
# =========================================================
var title_music: AudioStream = preload("res://assets/audio/bgm/sound_main.mp3")


func _ready() -> void:
	AudioManager.play_music(title_music)
	
	# Translation
	if has_node("/root/LocaleManager"):
		var lm = get_node("/root/LocaleManager")
		lm.language_changed.connect(_on_language_changed)
		_apply_translation()

func _apply_translation() -> void:
	if not has_node("/root/LocaleManager"): return
	var lm = get_node("/root/LocaleManager")
	
	if $PromptLabel: $PromptLabel.text = lm.t("PRESS_ANY_BUTTON")
	if $VersionLabel: $VersionLabel.text = lm.t("PROTOTYPE_VERSION")

func _on_language_changed(_lang: String) -> void:
	_apply_translation()


# =========================================================
# INPUT
# =========================================================
func _input(event: InputEvent) -> void:
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
