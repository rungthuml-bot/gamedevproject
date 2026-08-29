extends Control


# =========================================================
# Export Variables
# =========================================================

@export_file("*.tscn") var save_select_scene: String = "res://scenes/SaveSelectMenu.tscn"


# =========================================================
# Node References
# =========================================================

@onready var start_button: Button = $MarginContainer/VBoxContainer/StartButton
@onready var options_button: Button = $MarginContainer/VBoxContainer/OptionsButton
@onready var exit_button: Button = $MarginContainer/VBoxContainer/ExitButton


# =========================================================
# Ready
# =========================================================

func _ready() -> void:

	# เชื่อมต่อ Signal ของปุ่มกด
	if start_button != null:
		start_button.pressed.connect(_on_start_button_pressed)

	if options_button != null:
		options_button.pressed.connect(_on_options_button_pressed)

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
		get_tree().change_scene_to_file(save_select_scene)
	else:
		print("MAIN MENU ERROR: Save select scene not found at path: ", save_select_scene)


func _on_options_button_pressed() -> void:

	print("Options Button Pressed")


func _on_exit_button_pressed() -> void:

	get_tree().quit()
