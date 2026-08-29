extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("player fell into lava pit")
		if body.has_method("hit"):
			body.hit()
		else:
			body.queue_free()
