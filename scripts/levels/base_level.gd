extends Node2D
class_name BaseLevel

func _ready() -> void:
	var player = get_node_or_null("Player")
	if not player:
		return
	
	var spawn_id = SceneTransition.target_spawn_id
	var spawn_node = null
	
	if spawn_id != "":
		spawn_node = find_child(spawn_id, true, false)
		
	if spawn_node != null:
		player.global_position = spawn_node.global_position
		player.global_position.y += 50
		
		if spawn_node.global_position.x < 600:
			player.global_position.x += 40
		else:
			player.global_position.x -= 40
			
		player.velocity = SceneTransition.player_velocity
		SceneTransition.player_velocity = Vector2.ZERO
	else:
		if SaveManager.save_data.has("checkpoint_pos_x") and SaveManager.save_data.has("checkpoint_pos_y"):
			player.global_position = Vector2(SaveManager.save_data["checkpoint_pos_x"], SaveManager.save_data["checkpoint_pos_y"])
		elif SaveManager.save_data.has("pos_x") and SaveManager.save_data.has("pos_y"):
			player.global_position = Vector2(SaveManager.save_data["pos_x"], SaveManager.save_data["pos_y"])
