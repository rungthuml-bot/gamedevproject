extends CharacterBody2D


const SPEED = 400.0
const JUMP_VELOCITY = -450.0

@onready var anim = $AnimatedSprite2D
@onready var attack_area = $AttackArea
@onready var attack_collision = $AttackArea/CollisionShape2D

# ATTACK VARIABLES
# Combo บนพื้น
var combo = 0

# Combo กลางอากาศ
var air_combo = 0

# กำลังโจมตีอยู่หรือไม่
var is_attacking = false

# เก็บการกดโจมตีไว้สำหรับ Combo ถัดไป
var attack_queued = false

# ประเภทการโจมตี
# "ground" หรือ "air"
var attack_type = ""

# จำนวนครั้งที่โจมตีกลางอากาศ
var air_attacks_used = 0

func _ready():
	attack_collision.disabled = true

# START ATTACK
func start_attack():

	# เริ่มโจมตีครั้งแรก
	if not is_attacking:

		attack_queued = false
		
		# GROUND ATTACK
		if is_on_floor():

			is_attacking = true
			attack_type = "ground"

			combo = 1

			anim.play("Attack_1")

		# AIR ATTACK
		else:

			# ถ้าโจมตีบนอากาศครบ 2 ครั้งแล้ว
			if air_attacks_used >= 2:
				return

			is_attacking = true
			attack_type = "air"

			air_combo += 1
			air_attacks_used += 1

			anim.play("Attack_" + str(air_combo))

		return
	# COMBO ATTACK ระหว่างโจมตีอยู่
	# GROUND COMBO
	if attack_type == "ground":

		combo += 1

		if combo <= 4:

			anim.play("Attack_" + str(combo))

	# AIR COMBO
	elif attack_type == "air":

		# ถ้าโจมตีบนอากาศครบแล้ว
		if air_attacks_used >= 2:
			return

		air_combo += 1
		air_attacks_used += 1

		if air_combo <= 2:

			anim.play("Attack_" + str(air_combo))

# UPDATE NORMAL ANIMATION
func update_animation():

	# กลางอากาศ
	if not is_on_floor():

		# ป้องกันไม่ให้ Jump เริ่มใหม่ทุก Frame
		if anim.animation != "Jump":
			anim.play("Jump")

	# กำลังวิ่ง
	elif velocity.x != 0:

		if anim.animation != "Run":
			anim.play("Run")

	# ยืนนิ่ง
	else:

		if anim.animation != "Idle":
			anim.play("Idle")

# PLAYER PHYSICS
func _physics_process(delta: float) -> void:

	# GRAVITY
	if not is_on_floor():

		velocity += get_gravity() * delta

	# RESET AIR ATTACK
	# เมื่อกลับมาถึงพื้น
	if is_on_floor():

		air_attacks_used = 0
		air_combo = 0

	# JUMP
	if Input.is_action_just_pressed("Jump") and is_on_floor() and not is_attacking:

		velocity.y = JUMP_VELOCITY

	# MOVEMENT INPUT
	var direction = Input.get_axis("Left", "Right")

	# MOVEMENT

	# ถ้าโจมตีบนพื้น
	# → หยุดนิ่ง
	if is_attacking and attack_type == "ground":

		velocity.x = 0

	# กรณีปกติ หรือโจมตีกลางอากาศ
	else:

		if direction != 0:

			velocity.x = direction * SPEED

		else:

			velocity.x = move_toward(
				velocity.x,
				0,
				SPEED
			)

	# TURN LEFT / RIGHT
	# ถ้าโจมตีบนพื้น
	# → ล็อกทิศทาง ห้ามหัน
	if not (is_attacking and attack_type == "ground"):

		if direction > 0:

			anim.flip_h = false

		elif direction < 0:

			anim.flip_h = true

	# ATTACK INPUT
	if Input.is_action_just_pressed("Attack"):

		# กำลังโจมตีอยู่
		if is_attacking:

			# GROUND COMBO
			if attack_type == "ground":

				if combo < 4:

					attack_queued = true

			# AIR COMBO
			elif attack_type == "air":

				if air_combo < 2 and air_attacks_used < 2:

					attack_queued = true

		# ยังไม่ได้โจมตี
		else:

			# ถ้าอยู่กลางอากาศและตีครบ 2 ครั้งแล้ว
			if not is_on_floor() and air_attacks_used >= 2:

				pass

			else:

				start_attack()

	# NORMAL ANIMATION
	if not is_attacking:

		update_animation()


	move_and_slide()

# ANIMATION FINISHED
func _on_animated_sprite_2d_animation_finished():

	# GROUND ATTACK FINISHED
	if attack_type == "ground":

		# ถ้ากดโจมตีต่อ
		if attack_queued and combo < 4:

			attack_queued = false

			start_attack()

		# ไม่มีการโจมตีต่อ
		else:

			is_attacking = false
			attack_queued = false

			combo = 0
			attack_type = ""

			update_animation()

	# AIR ATTACK FINISHED
	elif attack_type == "air":

		# ถ้ากดโจมตีต่อ
		if attack_queued and air_combo < 2:

			attack_queued = false

			start_attack()

		# ไม่มีการโจมตีต่อ
		else:

			is_attacking = false
			attack_queued = false

			attack_type = ""

			# ไม่ Reset air_combo
			# ไม่ Reset air_attacks_used
			# จะ Reset ก็ต่อเมื่อลงพื้น

			update_animation()

func _on_animated_sprite_2d_frame_changed():

	var is_attack_animation = (
		anim.animation.begins_with("Attack")
		or anim.animation.begins_with("AirAttack")
	)

	if is_attack_animation and anim.frame == 1:
		attack_collision.set_deferred("disabled", false)

	else:
		attack_collision.set_deferred("disabled", true)

func _on_attack_area_area_entered(area):

	print("Hit something!")

	var enemy = area.get_parent()

	if enemy.has_method("take_damage"):
		enemy.take_damage(10)
