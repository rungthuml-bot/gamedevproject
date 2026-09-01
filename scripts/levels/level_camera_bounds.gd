extends Node2D
class_name LevelCameraBounds

@export_group("Camera Limits")
@export var limit_left: int = 0
@export var limit_top: int = -500
@export var limit_right: int = 10000000
@export var limit_bottom: int = 10000000

func _ready() -> void:
    # Try to find Mordred in the current level
    var player = get_node_or_null("Mordred")
    
    if player and player.has_node("Camera2D"):
        var cam: Camera2D = player.get_node("Camera2D")
        cam.limit_left = limit_left
        cam.limit_top = limit_top
        cam.limit_right = limit_right
        cam.limit_bottom = limit_bottom
        print("Set camera limits for level: ", name)
    else:
        print("LevelCameraBounds: Could not find Mordred or Camera2D in ", name)
