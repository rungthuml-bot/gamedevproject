extends Area2D
class_name Arrow

const SPEED: float = 400.0
const DAMAGE: int = 15

var direction: float = 1.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
	# Destroy arrow after 3 seconds to prevent memory leaks if it flies off-screen
	await get_tree().create_timer(3.0).timeout
	if is_inside_tree():
		queue_free()

func _physics_process(delta: float) -> void:
	position.x += direction * SPEED * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(DAMAGE, global_position.x)
		queue_free()
	elif body.collision_layer == 1:
		# Hit the ground/wall
		queue_free()
