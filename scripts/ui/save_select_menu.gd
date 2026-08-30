extends Control


# =========================================================
# Export Variables
# =========================================================

@export_file("*.tscn") var main_menu_scene: String = "res://scenes/ui/MainMenu.tscn"
@export_file("*.tscn") var story_intro_scene: String = "res://scenes/story/StoryIntro.tscn"


# =========================================================
# Node References
# =========================================================

# Slot Buttons
@onready var slot1_button: Button = $MarginContainer/VBoxContainer/SlotContainer/Slot1Button
@onready var slot2_button: Button = $MarginContainer/VBoxContainer/SlotContainer/Slot2Button
@onready var slot3_button: Button = $MarginContainer/VBoxContainer/SlotContainer/Slot3Button
@onready var slot4_button: Button = $MarginContainer/VBoxContainer/SlotContainer/Slot4Button

# Delete Buttons
@onready var delete1_button: Button = $MarginContainer/VBoxContainer/DeleteContainer/Delete1Button
@onready var delete2_button: Button = $MarginContainer/VBoxContainer/DeleteContainer/Delete2Button
@onready var delete3_button: Button = $MarginContainer/VBoxContainer/DeleteContainer/Delete3Button
@onready var delete4_button: Button = $MarginContainer/VBoxContainer/DeleteContainer/Delete4Button

# Back Button
@onready var back_button: Button = $MarginContainer/VBoxContainer/BackButton


# =========================================================
# Ready
# =========================================================

func _ready() -> void:

	update_slot_buttons()

	# เชื่อมต่อปุ่มเลือก Profile
	slot1_button.pressed.connect(func(): _on_slot_pressed(1))
	slot2_button.pressed.connect(func(): _on_slot_pressed(2))
	slot3_button.pressed.connect(func(): _on_slot_pressed(3))
	slot4_button.pressed.connect(func(): _on_slot_pressed(4))

	# เชื่อมต่อปุ่มลบ Delete
	if delete1_button != null: delete1_button.pressed.connect(func(): _on_delete_pressed(1))
	if delete2_button != null: delete2_button.pressed.connect(func(): _on_delete_pressed(2))
	if delete3_button != null: delete3_button.pressed.connect(func(): _on_delete_pressed(3))
	if delete4_button != null: delete4_button.pressed.connect(func(): _on_delete_pressed(4))

	back_button.pressed.connect(_on_back_pressed)


# =========================================================
# Update UI
# =========================================================

func update_slot_buttons() -> void:

	var buttons: Array[Button] = [slot1_button, slot2_button, slot3_button, slot4_button]
	var delete_buttons: Array[Button] = [delete1_button, delete2_button, delete3_button, delete4_button]

	for i in range(buttons.size()):
		var slot_number := i + 1
		var btn: Button = buttons[i]
		var del_btn: Button = delete_buttons[i]

		if SaveManager.is_slot_used(slot_number):
			var data = SaveManager.get_slot_info(slot_number)
			var hp: int = data.get("hp", 100)
			var potions: int = data.get("potion_count", 0)

			btn.text = "PROFILE " + str(slot_number) + "\n\nCONTINUE\n\nHP: " + str(hp) + "\nPotions: " + str(potions)

			if del_btn != null:
				del_btn.modulate.a = 1.0
				del_btn.disabled = false
		else:
			btn.text = "PROFILE " + str(slot_number) + "\n\nNEW GAME"

			if del_btn != null:
				del_btn.modulate.a = 0.0
				del_btn.disabled = true


# =========================================================
# Actions
# =========================================================

func _on_slot_pressed(slot: int) -> void:

	if SaveManager.is_slot_used(slot):
		# เล่นต่อ (CONTINUE) -> โหลดเซฟแล้วสลับฉากเข้าเกม
		SaveManager.load_game(slot)
		var target_scene: String = SaveManager.save_data.get("current_scene", SaveManager.default_start_scene)
		SceneTransition.change_scene(target_scene)
	else:
		# สร้างเซฟใหม่ (NEW GAME) -> สลับฉากไปหน้าเล่าเรื่อง
		SaveManager.create_new_save(slot)
		SceneTransition.change_scene(story_intro_scene)


func _on_delete_pressed(slot: int) -> void:

	SaveManager.delete_save(slot)
	update_slot_buttons()


func _on_back_pressed() -> void:

	if main_menu_scene != "" and ResourceLoader.exists(main_menu_scene):
		SceneTransition.change_scene(main_menu_scene)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if back_button and not back_button.disabled:
			get_viewport().set_input_as_handled()
			back_button.pressed.emit()
