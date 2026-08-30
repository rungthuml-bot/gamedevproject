extends TrapBase

func _apply_trap_effect(body: Node2D) -> void:
	print("Player hit rail saw!")
	super._apply_trap_effect(body)
