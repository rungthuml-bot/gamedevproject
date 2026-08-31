extends CanvasLayer


# =========================================================
# Export Variables
# =========================================================

@export_file("*.tscn") var main_menu_scene: String = "res://scenes/ui/MainMenu.tscn"


# =========================================================
# Node References
# =========================================================

@onready var control: Control = $Control
@onready var retry_button: Button = $Control/MarginContainer/VBoxContainer/RetryButton
@onready var main_menu_button: Button = $Control/MarginContainer/VBoxContainer/MainMenuButton


# =========================================================
# Ready
# =========================================================

func _ready() -> void:

	# ทำงานได้ตลอดเวลาแม้เกมจะ Paused
	process_mode = Node.PROCESS_MODE_ALWAYS

	# ซ่อนหน้า Game Over ไว้ก่อน
	control.hide()

	# เชื่อมต่อ Signal ของปุ่มกด
	retry_button.pressed.connect(_on_retry_button_pressed)
	main_menu_button.pressed.connect(_on_main_menu_button_pressed)

	# เชื่อมต่อกับ Signal ของ Player
	var player := get_tree().get_first_node_in_group("player") as Node

	if player != null:
		if player.has_signal("died"):
			player.died.connect(_on_player_died)
	else:
		print("GAME OVER MENU ERROR: Player not found!")

	# Translation
	if has_node("/root/LocaleManager"):
		var lm = get_node("/root/LocaleManager")
		lm.language_changed.connect(_on_language_changed)
		_apply_translation()

func _apply_translation() -> void:
	if not has_node("/root/LocaleManager"): return
	var lm = get_node("/root/LocaleManager")
	
	if $Control/MarginContainer/VBoxContainer/TitleLabel:
		$Control/MarginContainer/VBoxContainer/TitleLabel.text = lm.t("YOU_DIED")
	
	if retry_button: retry_button.text = lm.t("RETRY")
	if main_menu_button: main_menu_button.text = lm.t("MAIN_MENU")

func _on_language_changed(_lang: String) -> void:
	_apply_translation()


# =========================================================
# Player Died Event
# =========================================================

func _on_player_died() -> void:

	print("========== SHOW GAME OVER UI ==========")

	# หยุดเกมชั่วคราว
	get_tree().paused = true

	# แสดงหน้า Game Over
	control.show()
	if control.has_node("AnimationPlayer"):
		control.get_node("AnimationPlayer").play("fade_in")
	retry_button.grab_focus()


# =========================================================
# Button Actions
# =========================================================

func _on_retry_button_pressed() -> void:

	# ปลด Pause ก่อน
	get_tree().paused = false
	
	# เปิด Flag แจ้งระบบโหลดให้รู้ว่านี่คือการ Respawn
	SaveManager.is_respawning = true
	
	# หาสถานที่ Checkpoint
	var target_scene: String = SaveManager.save_data.get("checkpoint_scene", "")
	if target_scene == "":
		target_scene = SaveManager.save_data.get("current_scene", "")
		
	if target_scene != "" and ResourceLoader.exists(target_scene):
		SceneTransition.change_scene(target_scene, 0.5)
	else:
		get_tree().reload_current_scene()


func _on_main_menu_button_pressed() -> void:

	# ปลด Pause ก่อนกลับหน้า Main Menu
	get_tree().paused = false

	if main_menu_scene != "" and ResourceLoader.exists(main_menu_scene):
		get_tree().change_scene_to_file(main_menu_scene)
	else:
		print("ERROR: Cannot find main_menu_scene")
