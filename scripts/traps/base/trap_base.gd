class_name TrapBase
extends Area2D

@export var damage_amount: int = 10

var bodies_inside: Array[Node2D] = []

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	if bodies_inside.size() > 0:
		for body in bodies_inside:
			if is_instance_valid(body):
				_apply_trap_effect(body)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if not bodies_inside.has(body):
			bodies_inside.append(body)
			_apply_trap_effect(body)

func _on_body_exited(body: Node2D) -> void:
	if bodies_inside.has(body):
		bodies_inside.erase(body)

func _apply_trap_effect(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage_amount, global_position.x)
	elif body.has_method("hit"):
		body.hit()
	else:
		body.queue_free()
