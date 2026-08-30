extends CharacterBody2D

var health = 100

func take_damage(damage: int):

	health -= damage

	print("Enemy Hit!")
	print("Health:", health)

	if health <= 0:
		print("Enemy Dead!")
		queue_free()
