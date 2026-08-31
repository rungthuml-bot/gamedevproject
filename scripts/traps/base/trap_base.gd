class_name TrapBase
extends Area2D

@export var damage_amount: int = 10

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_apply_trap_effect(body)

func _apply_trap_effect(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage_amount, global_position.x)
	elif body.has_method("hit"):
		body.hit()
	else:
		body.queue_free()
