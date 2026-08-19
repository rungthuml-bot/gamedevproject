extends CharacterBody2D

const SPEED = 200.0
const JUMP_VELOCITY = -400.0

@onready var anim = $AnimatedSprite2D

# ATTACK VARIABLES
var combo = 0
var air_combo = 0

var is_attacking = false
var attack_queued = false

# จำว่าโจมตีบนพื้นหรือกลางอากาศ
var attack_type = ""

# START ATTACK
func start_attack():

	# เริ่มโจมตีครั้งแรก
	if not is_attacking:

		is_attacking = true
		attack_queued = false

		if is_on_floor():
			attack_type = "ground"
			combo = 1
			anim.play("Attack_1")

		else:
			attack_type = "air"
			air_combo = 1
			anim.play("Attack_1")

		return

	# GROUND COMBO
	if attack_type == "ground":

		combo += 1

		if combo <= 4:
			anim.play("Attack_" + str(combo))

	# AIR COMBO
	elif attack_type == "air":

		air_combo += 1

		if air_combo <= 2:
			anim.play("Attack_" + str(air_combo))

# NORMAL ANIMATION
func update_animation():

	if not is_on_floor():
		anim.play("Jump")

	elif velocity.x != 0:
		anim.play("Run")

	else:
		anim.play("Idle")

# PHYSICS PROCESS
func _physics_process(delta: float) -> void:

	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Jump
	if Input.is_action_just_pressed("Jump") and is_on_floor() and not is_attacking:
		velocity.y = JUMP_VELOCITY

	# Movement Input
	var direction = Input.get_axis("Left", "Right")

	# MOVEMENT
	# Ground Attack = หยุดนิ่ง
	if is_attacking and attack_type == "ground":

		velocity.x = 0

	else:

		if direction != 0:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)


	# TURN LEFT / RIGHT
	if direction > 0:
		anim.flip_h = false

	elif direction < 0:
		anim.flip_h = true

	# ATTACK INPUT
	if Input.is_action_just_pressed("Attack"):

		if is_attacking:
			# เก็บไว้ให้โจมตีต่อ
			attack_queued = true

		else:
			start_attack()

	# NORMAL ANIMATION
	if not is_attacking:
		update_animation()

	move_and_slide()

# ANIMATION FINISHED
func _on_animated_sprite_2d_animation_finished():

	# GROUND ATTACK
	if attack_type == "ground":

		if attack_queued and combo < 4:

			attack_queued = false
			start_attack()

		else:

			is_attacking = false
			attack_queued = false
			combo = 0
			attack_type = ""

			update_animation()

	# AIR ATTACK
	elif attack_type == "air":

		if attack_queued and air_combo < 2:

			attack_queued = false
			start_attack()

		else:

			is_attacking = false
			attack_queued = false
			air_combo = 0
			attack_type = ""

			update_animation()
