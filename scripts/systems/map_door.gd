extends Area2D
class_name MapDoor

@export_file("*.tscn") var target_scene_path: String
@export var target_spawn_id: String = ""

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	print("[MapDoor] Body entered: ", body.name)
	if body.is_in_group("player"):
		print("[MapDoor] Player detected! target_scene: ", target_scene_path)
		if target_scene_path != "":
			# เก็บความเร็วผู้เล่นก่อนเปลี่ยนด่านเพื่อให้เดินต่อเนื่อง
			SceneTransition.player_velocity = body.velocity
			
			# Call the autoload SceneTransition
			SceneTransition.change_scene(target_scene_path, 0.5, target_spawn_id)
		else:
			push_warning("MapDoor has no target_scene_path set!")
