extends Control


# =========================================================
# Export Variables
# =========================================================

@export_file("*.tscn") var save_select_scene: String = "res://scenes/ui/SaveSelectMenu.tscn"

# =========================================================
# BGM
# =========================================================
var title_music: AudioStream = preload("res://assets/audio/bgm/sound_main.mp3")


# =========================================================
# Node References
# =========================================================

@onready var start_button: Button = $MarginContainer/VBoxContainer/StartButton
@onready var options_button: Button = $MarginContainer/VBoxContainer/OptionsButton
@onready var credits_button: Button = $MarginContainer/VBoxContainer/StartButton2
@onready var exit_button: Button = $MarginContainer/VBoxContainer/ExitButton


# =========================================================
# Ready
# =========================================================

func _ready() -> void:
	AudioManager.play_music(title_music)

	# เชื่อมต่อ Signal ของปุ่มกด
	if start_button != null:
		start_button.pressed.connect(_on_start_button_pressed)

	if options_button != null:
		options_button.pressed.connect(_on_options_button_pressed)

	if credits_button != null:
		credits_button.pressed.connect(_on_credits_button_pressed)

	if exit_button != null:
		exit_button.pressed.connect(_on_exit_button_pressed)

	# โฟกัสปุ่ม Start อัตโนมัติ (รองรับ Keyboard / Gamepad)
	if start_button != null:
		start_button.grab_focus()
		
	# Translation
	if has_node("/root/LocaleManager"):
		var lm = get_node("/root/LocaleManager")
		lm.language_changed.connect(_on_language_changed)
		_apply_translation()

func _apply_translation() -> void:
	if not has_node("/root/LocaleManager"): return
	var lm = get_node("/root/LocaleManager")
	
	if start_button: start_button.text = lm.t("START_GAME")
	if options_button: options_button.text = lm.t("SETTING")
	if credits_button: credits_button.text = lm.t("CREDIT")
	if exit_button: exit_button.text = lm.t("EXIT_GAME")

func _on_language_changed(_lang: String) -> void:
	_apply_translation()


# =========================================================
# Button Actions
# =========================================================

func _on_start_button_pressed() -> void:

	# เปลี่ยนไปยังหน้าเลือก Save Profile (SaveSelectMenu)
	if save_select_scene != "" and ResourceLoader.exists(save_select_scene):
		SceneTransition.change_scene(save_select_scene, 0.5)
	else:
		print("MAIN MENU ERROR: Save select scene not found at path: ", save_select_scene)


func _on_options_button_pressed() -> void:
	SceneTransition.change_scene("res://scenes/ui/Settings.tscn", 0.5)

func _on_credits_button_pressed() -> void:
	SceneTransition.change_scene("res://scenes/ui/Credits.tscn", 0.5)

func _on_exit_button_pressed() -> void:

	get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		go_back()

func go_back() -> void:
	if SceneTransition.is_transitioning:
		return
	
	get_viewport().set_input_as_handled()
	AudioManager.play_ui_click()
	SceneTransition.change_scene("res://scenes/ui/TitleScreen.tscn", 0.5)
