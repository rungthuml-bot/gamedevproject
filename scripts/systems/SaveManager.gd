extends Node


# =========================================================
# Variables
# =========================================================

var current_slot: int = 1
var default_start_scene: String = "res://scenes/ui/ui_test_main.tscn"

# ข้อมูลเซฟปัจจุบัน
var save_data: Dictionary = {
	"hp": 100,
	"potion_count": 1,
	"current_scene": "res://scenes/ui/ui_test_main.tscn"
}


# =========================================================
# Path Utilities
# =========================================================

func get_save_path(slot: int) -> String:

	return "user://save_slot_" + str(slot) + ".json"


func is_slot_used(slot: int) -> bool:

	return FileAccess.file_exists(get_save_path(slot))


# =========================================================
# Save, Load & Delete Logic
# =========================================================

func create_new_save(slot: int) -> void:

	current_slot = slot
	save_data = {
		"hp": 100,
		"potion_count": 1,
		"current_scene": default_start_scene
	}
	save_game()


func save_game() -> void:

	var path := get_save_path(current_slot)
	var file := FileAccess.open(path, FileAccess.WRITE)

	if file:
		var json_string := JSON.stringify(save_data, "\t")
		file.store_string(json_string)
		file.close()
		print("SAVED GAME TO SLOT ", current_slot)


func load_game(slot: int) -> bool:

	current_slot = slot
	var path := get_save_path(slot)

	if not FileAccess.file_exists(path):
		return false

	var file := FileAccess.open(path, FileAccess.READ)

	if file:
		var json_string := file.get_as_text()
		file.close()

		var json := JSON.new()
		if json.parse(json_string) == OK:
			save_data = json.data
			print("LOADED GAME FROM SLOT ", slot)
			return true

	return false


# ลบไฟล์เซฟใน Slot ที่ระบุ
func delete_save(slot: int) -> void:

	var path := get_save_path(slot)

	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
		print("DELETED SAVE SLOT ", slot)


func get_slot_info(slot: int) -> Dictionary:

	var path := get_save_path(slot)

	if FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)

		if file:
			var json_string := file.get_as_text()
			file.close()

			var json := JSON.new()
			if json.parse(json_string) == OK:
				return json.data

	return {}
