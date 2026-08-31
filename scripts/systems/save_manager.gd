extends Node


# =========================================================
# Variables
# =========================================================

signal equipped_charms_changed

var current_slot: int = 1
var default_start_scene: String = "res://scenes/levels/level_1.tscn"

# ข้อมูลเซฟปัจจุบัน
var save_data: Dictionary = {
	"hp": 100,
	"potion_count": 1,
	"current_scene": "res://scenes/levels/level_1.tscn",
	"equipped_charms": []
}

# ใช้สำหรับบอกให้ระบบรู้ว่าเป็นการตายแล้วเกิดใหม่
var is_respawning: bool = false


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
		"current_scene": default_start_scene,
		"equipped_charms": []
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

# =========================================================
# Charm Management
# =========================================================

func is_charm_equipped(charm_id: String) -> bool:
	if save_data.has("equipped_charms") and save_data["equipped_charms"] is Array:
		return save_data["equipped_charms"].has(charm_id)
	return false

func toggle_charm(charm_id: String) -> void:
	if not save_data.has("equipped_charms") or not (save_data["equipped_charms"] is Array):
		save_data["equipped_charms"] = []
		
	var charms: Array = save_data["equipped_charms"]
	
	if charms.has(charm_id):
		charms.erase(charm_id)
	else:
		charms.append(charm_id)
		
	save_game()
	equipped_charms_changed.emit()
