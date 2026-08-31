extends Node2D
class_name BaseLevel

var player_scene: PackedScene = preload("res://scenes/characters/Mordred.tscn")
var hud_scene: PackedScene = preload("res://scenes/ui/HUD.tscn")

func _ready() -> void:
	# Instantiate Player
	var player = player_scene.instantiate()
	add_child(player)
	
	# Instantiate HUD
	var hud = hud_scene.instantiate()
	add_child(hud)
	
	# Position Player
	var spawn_id = SceneTransition.target_spawn_id
	var spawn_node = null
	
	if has_node("Spawns"):
		if spawn_id != "" and has_node("Spawns/" + spawn_id):
			spawn_node = get_node("Spawns/" + spawn_id)
		elif has_node("Spawns/Default"):
			spawn_node = get_node("Spawns/Default")
			
		if spawn_node:
			player.global_position = spawn_node.global_position
			
	# Optional: Setup camera limits here if needed
