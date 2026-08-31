extends TrapBase

func _apply_trap_effect(body: Node2D) -> void:
	print("Player fell into posion pit!")
	super._apply_trap_effect(body)
