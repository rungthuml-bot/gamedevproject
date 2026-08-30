extends Area2D


# =========================================================
# Ready
# =========================================================

func _ready() -> void:

	# เชื่อมต่อ Signal เมื่อมีอะไรมาชน
	body_entered.connect(_on_body_entered)


# =========================================================
# Collision Event
# =========================================================

func _on_body_entered(body: Node2D) -> void:

	# เช็กว่าเป็น Player หรือไม่
	if body.is_in_group("player"):

		if body.has_method("update_checkpoint"):
			body.update_checkpoint()
			print("========== CHECKPOINT SAVED! ==========")
		elif body.has_method("save_player_data"):
			body.save_player_data()
			print("========== CHECKPOINT SAVED! (Fallback) ==========")
