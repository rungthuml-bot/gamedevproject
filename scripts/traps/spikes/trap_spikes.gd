extends TrapBase

func _apply_trap_effect(body: Node2D) -> void:
	print("Player hit spikes!")
	super._apply_trap_effect(body)
