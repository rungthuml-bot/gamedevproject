extends CanvasLayer


# =========================================================
# Export Variables
# =========================================================

@export_file("*.tscn") var main_menu_scene: String = "res://scenes/MainMenu.tscn"


# =========================================================
# Node References
# =========================================================

@onready var control: Control = $Control
@onready var resume_button: Button = $Control/MarginContainer/VBoxContainer/ResumeButton
@onready var save_button: Button = $Control/MarginContainer/VBoxContainer/SaveButton
@onready var main_menu_button: Button = $Control/MarginContainer/VBoxContainer/MainMenuButton
@onready var exit_button: Button = $Control/MarginContainer/VBoxContainer/ExitButton


# =========================================================
# Ready
# =========================================================

func _ready() -> void:

	# ทำงานได้ตลอดเวลาแม้เกมจะ Paused
	process_mode = Node.PROCESS_MODE_ALWAYS

	# ซ่อนหน้า Pause ไว้ก่อน
	control.hide()

	# เชื่อมต่อ Signal ของปุ่มต่างๆ
	if resume_button != null:
		resume_button.pressed.connect(_on_resume_button_pressed)

	if save_button != null:
		save_button.pressed.connect(_on_save_button_pressed)

	if main_menu_button != null:
		main_menu_button.pressed.connect(_on_main_menu_button_pressed)

	if exit_button != null:
		exit_button.pressed.connect(_on_exit_button_pressed)


# =========================================================
# Input Management
# =========================================================

func _unhandled_input(event: InputEvent) -> void:

	if event.is_action_pressed("ui_cancel"): # ปุ่ม ESC
		toggle_pause()


# =========================================================
# Pause System Logic
# =========================================================

func toggle_pause() -> void:

	get_tree().paused = not get_tree().paused

	if get_tree().paused:
		control.show()
		if resume_button != null:
			resume_button.grab_focus()
	else:
		control.hide()


# =========================================================
# Button Actions
# =========================================================

func _on_resume_button_pressed() -> void:

	toggle_pause()


func _on_save_button_pressed() -> void:

	var player := get_tree().get_first_node_in_group("player")

	if player != null and player.has_method("save_player_data"):
		player.save_player_data()
		print("========== SAVED GAME FROM PAUSE MENU ==========")


func _on_main_menu_button_pressed() -> void:

	get_tree().paused = false

	if main_menu_scene != "" and ResourceLoader.exists(main_menu_scene):
		get_tree().change_scene_to_file(main_menu_scene)
	else:
		print("PAUSE MENU ERROR: Cannot find main_menu_scene")


func _on_exit_button_pressed() -> void:

	get_tree().quit()
