extends TrapBase

func _apply_trap_effect(body: Node2D) -> void:
	print("player fell into lava pit")
	super._apply_trap_effect(body)
