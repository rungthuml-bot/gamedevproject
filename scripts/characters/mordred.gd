extends CharacterBody2D

signal died
signal hp_changed(current_hp: int, max_hp: int)
signal potion_count_changed(count: int)

const MAX_HP := 100
const INVINCIBILITY_DURATION := 1.0
const HEAL_AMOUNT := 35

var hp := MAX_HP
var is_invincible := false
var invincibility_timer := 0.0
var is_dead := false
var is_knockbacked := false
var knockback_timer := 0.0
var potion_count := 1

const WALK_SPEED = 250.0
const RUN_SPEED = 420.0
const JUMP_VELOCITY = -450.0

# DASH CONSTANTS
const DASH_SPEED := 700.0
const DASH_DURATION := 0.20
const DASH_COOLDOWN := 0.60

var is_dashing := false
var dash_cooldown_timer := 0.0
var shift_was_pressed := false
var shift_hold_timer := 0.0

# CAMERA SHAKE CONSTANTS
const SHAKE_DECAY: float = 8.0
var shake_intensity: float = 0.0

@onready var anim = $AnimatedSprite2D
@onready var attack_area = $AttackArea
@onready var attack_collision = $AttackArea/CollisionShape2D
@onready var camera: Camera2D = $Camera2D

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

	# ดึงค่า HP และขวดยาที่เซฟไว้ใน SaveManager มาใช้งาน
	if SaveManager.save_data.has("hp"):
		hp = SaveManager.save_data["hp"]

	if SaveManager.save_data.has("potion_count"):
		potion_count = SaveManager.save_data["potion_count"]

	# ส่งค่าให้ UI แสดงผล (ดีเลย์ 1 เฟรมเพื่อให้ HUD _ready() เสร็จก่อน)
	call_deferred("emit_initial_ui_signals")

func emit_initial_ui_signals() -> void:
	hp_changed.emit(hp, MAX_HP)
	potion_count_changed.emit(potion_count)

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

	var shift_pressed = Input.is_key_pressed(KEY_SHIFT)
	var trigger_dash = false
	
	if shift_pressed:
		shift_hold_timer += delta
	else:
		if shift_was_pressed and shift_hold_timer < 0.2:
			trigger_dash = true
		shift_hold_timer = 0.0
		
	shift_was_pressed = shift_pressed

	if is_dead:
		velocity.x = move_toward(velocity.x, 0, WALK_SPEED)
		if not is_on_floor():
			velocity += get_gravity() * delta
		move_and_slide()
		return
		
	# Camera Shake Process
	process_camera_shake(delta)

	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta

	if is_dashing:
		var facing := -1.0 if anim.flip_h else 1.0
		velocity.x = facing * DASH_SPEED
		velocity.y = 0.0
		move_and_slide()
		return

	if is_knockbacked:
		knockback_timer -= delta
		if knockback_timer <= 0.0:
			is_knockbacked = false

	if is_invincible:
		invincibility_timer -= delta
		if invincibility_timer <= 0.0:
			is_invincible = false
			anim.modulate.a = 1.0
		else:
			anim.modulate.a = 0.3 if fmod(invincibility_timer, 0.2) > 0.1 else 0.8

	# GRAVITY
	if not is_on_floor():

		velocity += get_gravity() * delta

	# RESET AIR ATTACK
	# เมื่อกลับมาถึงพื้น
	if is_on_floor():

		air_attacks_used = 0
		air_combo = 0

	# JUMP
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var current_speed := WALK_SPEED
	if shift_pressed and shift_hold_timer >= 0.2:
		current_speed = RUN_SPEED

	# MOVEMENT INPUT
	var direction = Input.get_axis("Left", "Right")

	# MOVEMENT

	if is_knockbacked:
		
		# ปล่อยให้ลอยตามแรงกระเด็น และลดความเร็วลงช้าๆ
		velocity.x = move_toward(velocity.x, 0, current_speed * 2.0 * delta)

	# กรณีปกติ
	else:

		if direction != 0:

			velocity.x = direction * current_speed

		else:

			velocity.x = move_toward(
				velocity.x,
				0,
				current_speed
			)

	# TURN LEFT / RIGHT
	if direction > 0:
		anim.flip_h = false
		attack_area.scale.x = 1

	elif direction < 0:
		anim.flip_h = true
		attack_area.scale.x = -1

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

	# DASH INPUT
	if trigger_dash and dash_cooldown_timer <= 0.0 and not is_knockbacked:
		dash()
		return

	# NORMAL ANIMATION
	if not is_attacking:

		update_animation()

	# USE POTION
	# เนื่องจากไม่มี Input Action สำหรับยา จึงใช้ KEY_H ตามต้นฉบับ
	if Input.is_key_pressed(KEY_H):
		use_potion()

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
	_deal_damage(area.get_parent())

func _on_attack_area_body_entered(body):
	_deal_damage(body)

func _deal_damage(enemy: Node) -> void:
	if enemy.has_method("take_damage"):
		enemy.take_damage(10)
		apply_camera_shake(5.0)

# =========================================================
# Health & Damage
# =========================================================

func hit() -> void:
	# Alias สำหรับดัก Trap ที่พยายามเรียก hit()
	take_damage(10)

func take_damage(amount: int, source_position_x: float = 0.0) -> void:
	if is_dead or is_invincible:
		return

	hp -= amount
	hp = max(hp, 0)
	hp_changed.emit(hp, MAX_HP)
	apply_camera_shake(10.0)

	if hp <= 0:
		die()
	else:
		is_invincible = true
		invincibility_timer = INVINCIBILITY_DURATION
		
		# Knockback
		if source_position_x != 0.0:
			var knockback_dir := 1.0 if global_position.x > source_position_x else -1.0
			velocity.x = knockback_dir * 200.0
			velocity.y = -150.0
			is_knockbacked = true
			knockback_timer = 0.2

func die() -> void:
	if is_dead:
		return
		
	is_dead = true
	is_attacking = false
	attack_collision.set_deferred("disabled", true)
	
	anim.play("Death")
	died.emit()

# =========================================================
# Items (Potions)
# =========================================================

func add_potion(amount: int) -> void:
	potion_count += amount
	potion_count_changed.emit(potion_count)
	
	# เซฟเกมอัตโนมัติเมื่อเก็บยาได้
	save_player_data()

func use_potion() -> void:
	# ป้องกันการกินยารัวๆ ในเฟรมเดียวด้วยการเช็คเลือดว่าเต็มหรือยัง
	if potion_count > 0 and hp < MAX_HP:
		potion_count -= 1
		hp = min(hp + HEAL_AMOUNT, MAX_HP)
		hp_changed.emit(hp, MAX_HP)
		potion_count_changed.emit(potion_count)
		
		# เซฟเกมอัตโนมัติเมื่อดื่มยา
		save_player_data()

# =========================================================
# Dash Logic
# =========================================================

func dash() -> void:
	if is_dashing or dash_cooldown_timer > 0.0:
		return
		
	is_dashing = true
	dash_cooldown_timer = DASH_COOLDOWN
	
	# สถานะอมตะชั่วขณะระหว่าง Dash
	is_invincible = true
	invincibility_timer = max(invincibility_timer, DASH_DURATION)
	
	# เนื่องจากยังไม่มีแอนิเมชัน Dash ให้เล่น Run ไปก่อนถ้าอยู่บนพื้น
	if is_on_floor():
		anim.play("Run")
	
	apply_camera_shake(3.0)
	
	await get_tree().create_timer(DASH_DURATION).timeout
	is_dashing = false

# =========================================================
# Camera Shake Logic
# =========================================================

func process_camera_shake(delta: float) -> void:
	if camera == null:
		return

	if shake_intensity > 0.0:
		shake_intensity = lerp(shake_intensity, 0.0, SHAKE_DECAY * delta)
		camera.offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
	else:
		camera.offset = Vector2.ZERO

func apply_camera_shake(intensity: float = 5.0) -> void:
	shake_intensity = intensity

# =========================================================
# Save Helper Logic
# =========================================================

func save_player_data() -> void:
	# บันทึกข้อมูลลง SaveManager
	SaveManager.save_data["hp"] = hp
	SaveManager.save_data["potion_count"] = potion_count
	
	if get_tree().current_scene != null:
		SaveManager.save_data["current_scene"] = get_tree().current_scene.scene_file_path

	# สั่งเขียนไฟล์ลงเครื่อง
	SaveManager.save_game()
