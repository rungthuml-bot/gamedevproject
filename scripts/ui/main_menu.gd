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
	SceneTransition.change_scene("res://Scenes/ui/Settings.tscn", 0.5)

func _on_credits_button_pressed() -> void:
	SceneTransition.change_scene("res://Scenes/ui/Credits.tscn", 0.5)

func _on_exit_button_pressed() -> void:

	get_tree().quit()
