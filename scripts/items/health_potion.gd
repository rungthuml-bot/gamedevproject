extends Area2D


# =========================================================
# Export Variables
# =========================================================

@export var potion_amount: int = 1


# =========================================================
# Ready
# =========================================================

func _ready() -> void:

	# เชื่อมต่อ Signal เมื่อมี Body เดินมาชน
	body_entered.connect(_on_body_entered)


# =========================================================
# Collision Event
# =========================================================

func _on_body_entered(body: Node2D) -> void:

	if body.is_in_group("player"):

		if body.has_method("add_potion"):

			body.add_potion(potion_amount)
			queue_free() # ลบไอเทมออกจากฉากหลังจากเก็บแล้ว
