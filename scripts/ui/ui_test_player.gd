extends CharacterBody2D


# =========================================================
# Signals
# =========================================================

signal hp_changed(current_hp: int, max_hp: int)
signal potion_count_changed(count: int)
signal died


# =========================================================
# Movement ( Walk & Run )
# =========================================================

const WALK_SPEED := 250.0
const RUN_SPEED := 420.0
const JUMP_VELOCITY := -450.0
const GRAVITY := 1200.0


# =========================================================
# Dash ( พุ่งหลบ )
# =========================================================

const DASH_SPEED := 700.0
const DASH_DURATION := 0.20
const DASH_COOLDOWN := 0.60

var is_dashing := false
var dash_cooldown_timer := 0.0


# =========================================================
# Health & Invincibility
# =========================================================

const MAX_HP := 100
const INVINCIBILITY_DURATION := 1.0
const KNOCKBACK_FORCE := 200.0

var hp := MAX_HP
var is_invincible := false
var invincibility_timer := 0.0


# =========================================================
# Potions & Healing
# =========================================================

const HEAL_AMOUNT := 35
var potion_count := 1


# =========================================================
# Combat (Light Attack & Heavy Attack)
# =========================================================

# โจมตีเบา (คลิกซ้าย)
const LIGHT_ATTACK_DAMAGE := 20
const LIGHT_ATTACK_WINDUP := 0.10
const LIGHT_ATTACK_ACTIVE_TIME := 0.15
const LIGHT_ATTACK_COOLDOWN := 0.30

# โจมตีหนัก (คลิกขวา)
const HEAVY_ATTACK_DAMAGE := 45
const HEAVY_ATTACK_WINDUP := 0.25
const HEAVY_ATTACK_ACTIVE_TIME := 0.20
const HEAVY_ATTACK_COOLDOWN := 0.60

const ATTACK_DISTANCE := 40.0

var is_attacking := false
var attack_cooldown := 0.0


# =========================================================
# Camera Shake
# =========================================================

const SHAKE_DECAY: float = 8.0
var shake_intensity: float = 0.0


# =========================================================
# Facing Direction
# =========================================================

var facing_direction := 1


# =========================================================
# Node References
# =========================================================

@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var camera: Camera2D = $Camera2D


# =========================================================
# Ready
# =========================================================

func _ready() -> void:

	update_attack_direction()
	attack_hitbox.monitoring = true

	# ดึงค่า HP และขวดยาที่เซฟไว้ใน SaveManager มาใช้งาน
	if SaveManager.save_data.has("hp"):
		hp = SaveManager.save_data["hp"]

	if SaveManager.save_data.has("potion_count"):
		potion_count = SaveManager.save_data["potion_count"]

	# ส่งค่าให้ UI แสดงผล
	hp_changed.emit(hp, MAX_HP)
	potion_count_changed.emit(potion_count)


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


# =========================================================
# Physics Process
# =========================================================

func _physics_process(delta: float) -> void:

	# Cooldown Timers
	if attack_cooldown > 0.0:
		attack_cooldown -= delta

	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta

	# Invincibility Timer
	if is_invincible:
		invincibility_timer -= delta
		modulate.a = 0.3 if fmod(invincibility_timer, 0.2) > 0.1 else 0.8

		if invincibility_timer <= 0.0:
			is_invincible = false
			modulate.a = 1.0

	# Camera Shake Process
	process_camera_shake(delta)

	# ขณะ Dash ให้พุ่งไปข้างหน้าโดยไม่สน Gravity และการเดินปกติ
	if is_dashing:
		velocity.x = facing_direction * DASH_SPEED
		velocity.y = 0.0
		move_and_slide()
		return

	# Gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Check Dash Input (กดปุ่ม C หรือ action 'dash')
	if (Input.is_key_pressed(KEY_C) or Input.is_action_just_pressed("dash")) and dash_cooldown_timer <= 0.0:
		dash()
		return

	# Check Running (กด Shift ค้างเพื่อวิ่ง)
	var current_speed := WALK_SPEED
	if Input.is_key_pressed(KEY_SHIFT):
		current_speed = RUN_SPEED

	# Movement
	var direction := Input.get_axis("move_left", "move_right")

	if direction != 0:
		if direction != facing_direction:
			facing_direction = int(direction)
			update_attack_direction()

		velocity.x = direction * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)

	# Combat Inputs
	if not is_attacking and attack_cooldown <= 0.0:
		if Input.is_action_just_pressed("attack_light"):
			light_attack()
		elif Input.is_action_just_pressed("attack_heavy") or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			heavy_attack()

	# Use Potion
	if Input.is_key_pressed(KEY_H):
		use_potion()

	move_and_slide()


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
	invincibility_timer = DASH_DURATION

	apply_camera_shake(3.0)

	await get_tree().create_timer(DASH_DURATION).timeout

	is_dashing = false


# =========================================================
# Combat Systems
# =========================================================

func update_attack_direction() -> void:

	attack_hitbox.position.x = ATTACK_DISTANCE * facing_direction


func light_attack() -> void:

	is_attacking = true
	attack_cooldown = LIGHT_ATTACK_COOLDOWN

	await get_tree().create_timer(LIGHT_ATTACK_WINDUP).timeout

	var targets := attack_hitbox.get_overlapping_bodies()

	for target in targets:
		if target.has_method("take_damage"):
			target.take_damage(LIGHT_ATTACK_DAMAGE)
			apply_camera_shake(4.0)

	await get_tree().create_timer(LIGHT_ATTACK_ACTIVE_TIME).timeout

	is_attacking = false


func heavy_attack() -> void:

	is_attacking = true
	attack_cooldown = HEAVY_ATTACK_COOLDOWN

	await get_tree().create_timer(HEAVY_ATTACK_WINDUP).timeout

	var targets := attack_hitbox.get_overlapping_bodies()

	for target in targets:
		if target.has_method("take_damage"):
			target.take_damage(HEAVY_ATTACK_DAMAGE)
			apply_camera_shake(9.0)

	await get_tree().create_timer(HEAVY_ATTACK_ACTIVE_TIME).timeout

	is_attacking = false


# =========================================================
# Item & Potion Logic
# =========================================================

func add_potion(amount: int) -> void:

	potion_count += amount
	potion_count_changed.emit(potion_count)

	# เซฟเกมอัตโนมัติเมื่อเก็บยาได้
	save_player_data()


func use_potion() -> void:

	if potion_count > 0 and hp < MAX_HP:
		potion_count -= 1
		hp = min(hp + HEAL_AMOUNT, MAX_HP)
		hp_changed.emit(hp, MAX_HP)
		potion_count_changed.emit(potion_count)

		# เซฟเกมอัตโนมัติเมื่อดื่มยา
		save_player_data()


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
# Damage & Death
# =========================================================

func take_damage(amount: int, source_position_x: float = 0.0) -> void:

	if hp <= 0 or is_invincible:
		return

	hp -= amount
	hp = max(hp, 0)

	hp_changed.emit(hp, MAX_HP)
	apply_camera_shake(10.0)

	if source_position_x != 0.0:
		var knockback_dir := 1.0 if position.x > source_position_x else -1.0
		velocity.x = knockback_dir * KNOCKBACK_FORCE
		velocity.y = -150.0

	is_invincible = true
	invincibility_timer = INVINCIBILITY_DURATION

	if hp <= 0:
		die()


func die() -> void:

	died.emit()
