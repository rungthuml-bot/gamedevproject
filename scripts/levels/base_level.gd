extends Node2D
class_name BaseLevel

var player_scene: PackedScene = preload("res://scenes/characters/Mordred.tscn")
var hud_scene: PackedScene = preload("res://scenes/ui/HUD.tscn")
var pause_scene: PackedScene = preload("res://scenes/ui/PauseMenu.tscn")
var game_over_scene: PackedScene = preload("res://scenes/ui/GameOverMenu.tscn")
var equipment_scene: PackedScene = preload("res://scenes/ui/EquipmentMenu.tscn")

func _ready() -> void:
	# Instantiate Player
	var player = player_scene.instantiate()
	add_child(player)
	
	# Instantiate HUD
	var hud = hud_scene.instantiate()
	add_child(hud)
	
	# Instantiate Other UIs
	var pause_menu = pause_scene.instantiate()
	add_child(pause_menu)
	
	var game_over_menu = game_over_scene.instantiate()
	add_child(game_over_menu)
	
	var equipment_menu = equipment_scene.instantiate()
	add_child(equipment_menu)
	
	# Position Player
	var spawn_id = SceneTransition.target_spawn_id
	var spawn_node = null
	
	if spawn_id != "":
		spawn_node = find_child(spawn_id, true, false)
		
	if spawn_node != null:
		player.global_position = spawn_node.global_position
		
		# ชดเชยแกน Y ให้เท้า (y=0 ของตัวละคร) ไปแตะที่ขอบล่างของประตูพอดี (ซึ่งตรงกับพื้น y=550)
		player.global_position.y += 50
		
		if spawn_node.global_position.x < 600:
			player.global_position.x += 40
		else:
			player.global_position.x -= 40
			
		# โหลดความเร็วและล้างค่าเพื่อให้เดินต่อเนื่อง
		player.velocity = SceneTransition.player_velocity
		SceneTransition.player_velocity = Vector2.ZERO
	else:
		# ถ้าไม่ระบุประตู ให้อ่านจากเซฟ (เช่น Load Game หรือ ตายแล้วเกิดใหม่)
		if SaveManager.save_data.has("checkpoint_pos_x") and SaveManager.save_data.has("checkpoint_pos_y"):
			player.global_position = Vector2(SaveManager.save_data["checkpoint_pos_x"], SaveManager.save_data["checkpoint_pos_y"])
		elif SaveManager.save_data.has("pos_x") and SaveManager.save_data.has("pos_y"):
			player.global_position = Vector2(SaveManager.save_data["pos_x"], SaveManager.save_data["pos_y"])
		else:
			player.global_position = Vector2(100, 480)
