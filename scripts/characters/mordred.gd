extends CharacterBody2D

signal died
signal hp_changed(current_hp: int, max_hp: int)
signal potion_count_changed(count: int)

# =========================
# CONSTANTS
# =========================

const MAX_HP := 100
const HEAL_AMOUNT := 35
const INVINCIBILITY_DURATION := 1.0

const WALK_SPEED := 250.0
const RUN_SPEED := 420.0
const JUMP_VELOCITY := -450.0

const DASH_SPEED := 700.0
const DASH_DURATION := 0.20
const DASH_COOLDOWN := 0.60

const SHAKE_DECAY := 8.0


# =========================
# STATS / STATE
# =========================

var hp := MAX_HP
var potion_count := 1

var is_dead := false
var is_attacking := false
var is_using_potion := false
var is_dashing := false
var is_knockbacked := false
var is_invincible := false

var combo := 0
var attack_queued := false

var knockback_timer := 0.0
var invincibility_timer := 0.0
var dash_cooldown_timer := 0.0
var shift_hold_timer := 0.0

var shift_was_pressed := false
var shake_intensity := 0.0


# =========================
# NODES
# =========================

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area = $AttackArea
@onready var attack_collision = $AttackArea/CollisionShape2D
@onready var camera: Camera2D = $Camera2D


# =========================
# READY
# =========================

func _ready() -> void:

	attack_collision.disabled = true

	load_player_data()

	call_deferred("emit_initial_ui_signals")


# =========================
# PHYSICS
# =========================

func _physics_process(delta: float) -> void:

	process_camera_shake(delta)
	process_timers(delta)

	if is_dead:
		process_dead(delta)
		return

	if is_using_potion:
		process_potion(delta)
		return

	if is_dashing:
		process_dash()
		return

	apply_gravity(delta)

	var direction := Input.get_axis("Left", "Right")

	process_movement(direction, delta)
	process_facing(direction)
	process_jump()
	process_inputs(direction)

	update_animation()

	move_and_slide()


# =========================
# TIMERS
# =========================

func process_timers(delta: float) -> void:

	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta

	if is_invincible:
		invincibility_timer -= delta

		if invincibility_timer <= 0.0:
			is_invincible = false
			anim.modulate.a = 1.0
		else:
			anim.modulate.a = (
				0.3
				if fmod(invincibility_timer, 0.2) > 0.1
				else 0.8
			)

	if is_knockbacked:
		knockback_timer -= delta

		if knockback_timer <= 0.0:
			is_knockbacked = false
			update_animation()


# =========================
# DEAD
# =========================

func process_dead(delta: float) -> void:

	velocity.x = move_toward(
		velocity.x,
		0.0,
		WALK_SPEED * 10.0 * delta
	)

	if not is_on_floor():
		velocity += get_gravity() * delta

	move_and_slide()


# =========================
# POTION STATE
# =========================

func process_potion(delta: float) -> void:

	velocity.x = 0.0

	if not is_on_floor():
		velocity += get_gravity() * delta

	move_and_slide()


# =========================
# DASH STATE
# =========================

func process_dash() -> void:

	var facing := -1.0 if anim.flip_h else 1.0

	velocity.x = facing * DASH_SPEED
	velocity.y = 0.0

	move_and_slide()


# =========================
# GRAVITY
# =========================

func apply_gravity(delta: float) -> void:

	if not is_on_floor():
		velocity += get_gravity() * delta


# =========================
# MOVEMENT
# =========================

func process_movement(
	direction: float,
	delta: float
) -> void:

	if is_knockbacked:

		velocity.x = move_toward(
			velocity.x,
			0.0,
			WALK_SPEED * 2.0 * delta
		)

		return


	# หยุดเดินระหว่างโจมตี
	if is_attacking:

		velocity.x = 0.0

		return


	var speed := WALK_SPEED

	if Input.is_key_pressed(KEY_SHIFT):
		speed = RUN_SPEED


	if direction != 0:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(
			velocity.x,
			0.0,
			speed
		)


# =========================
# FACING
# =========================

func process_facing(direction: float) -> void:

	if is_attacking:
		return

	if direction > 0:

		anim.flip_h = false
		attack_area.scale.x = 1

	elif direction < 0:

		anim.flip_h = true
		attack_area.scale.x = -1


# =========================
# JUMP
# =========================

func process_jump() -> void:

	if is_attacking:
		return

	if (
		Input.is_action_just_pressed("Jump")
		and is_on_floor()
	):
		velocity.y = JUMP_VELOCITY


# =========================
# INPUTS
# =========================

func process_inputs(direction: float) -> void:

	# Potion
	if Input.is_key_pressed(KEY_H):
		use_potion()

	# Attack
	if Input.is_action_just_pressed("Attack"):
		handle_attack_input()

	# Dash
	handle_dash_input()


# =========================
# ATTACK INPUT
# =========================

func handle_attack_input() -> void:

	if not is_on_floor():
		return

	if is_using_potion or is_dashing:
		return

	if is_attacking:

		if combo < 4:
			attack_queued = true

	else:
		start_attack()


# =========================
# START ATTACK
# =========================

func start_attack() -> void:

	if is_dead or is_using_potion or is_dashing:
		return

	if not is_on_floor():
		return

	if not is_attacking:

		is_attacking = true
		combo = 1
		attack_queued = false

	else:

		combo += 1


	if combo <= 4:
		anim.play("Attack_" + str(combo))


# =========================
# CANCEL ATTACK
# =========================

func cancel_attack() -> void:

	if not is_attacking:
		return

	is_attacking = false
	attack_queued = false
	combo = 0

	attack_collision.set_deferred(
		"disabled",
		true
	)


# =========================
# ANIMATION
# =========================

func update_animation() -> void:

	if is_dead:
		return

	if is_using_potion:
		return

	if is_dashing:
		return

	if is_attacking:
		return


	if not is_on_floor():

		if anim.animation != "Jump":
			anim.play("Jump")

	elif abs(velocity.x) > 1.0:

		if anim.animation != "Run":
			anim.play("Run")

	else:

		if anim.animation != "Idle":
			anim.play("Idle")


# =========================
# ATTACK ANIMATION FINISHED
# =========================

func _on_animated_sprite_2d_animation_finished() -> void:

	# Death
	if anim.animation == "Death":

		died.emit()
		return


	# Attack
	if (
		is_attacking
		and anim.animation.begins_with("Attack")
	):

		if attack_queued and combo < 4:

			attack_queued = false
			start_attack()

		else:

			cancel_attack()
			update_animation()


# =========================
# ATTACK FRAME
# =========================

func _on_animated_sprite_2d_frame_changed() -> void:

	var attacking := anim.animation.begins_with("Attack")

	if attacking and anim.frame == 1:

		attack_collision.set_deferred(
			"disabled",
			false
		)

	else:

		attack_collision.set_deferred(
			"disabled",
			true
		)


# =========================
# DAMAGE
# =========================

func _on_attack_area_area_entered(area) -> void:

	_deal_damage(area.get_parent())


func _on_attack_area_body_entered(body) -> void:

	_deal_damage(body)


func _deal_damage(enemy: Node) -> void:

	if enemy != null and enemy.has_method("take_damage"):

		enemy.take_damage(10)

		apply_camera_shake(5.0)


# =========================
# PLAYER DAMAGE
# =========================

func hit() -> void:

	take_damage(10)


func take_damage(
	amount: int,
	source_position_x: float = 0.0
) -> void:

	if is_dead or is_invincible:
		return


	# สำคัญมาก
	# Enemy ชนระหว่าง Attack = ยกเลิก Attack
	cancel_attack()


	# ถ้ากำลังกินยา ให้ยกเลิก
	is_using_potion = false


	hp = max(hp - amount, 0)

	hp_changed.emit(hp, MAX_HP)

	apply_camera_shake(10.0)


	if hp <= 0:

		die()
		return


	is_invincible = true
	invincibility_timer = INVINCIBILITY_DURATION


	# Knockback
	if source_position_x != 0.0:

		var knockback_direction := (
			1.0
			if global_position.x > source_position_x
			else -1.0
		)

		velocity.x = knockback_direction * 200.0
		velocity.y = -150.0

		is_knockbacked = true
		knockback_timer = 0.2


# =========================
# DEATH
# =========================

func die() -> void:

	if is_dead:
		return

	is_dead = true
	is_dashing = false
	is_using_potion = false
	is_knockbacked = false

	cancel_attack()

	velocity.x = 0.0

	anim.modulate.a = 1.0

	anim.play("Death")


# =========================
# POTION
# =========================

func use_potion() -> void:

	if is_dead:
		return

	if is_using_potion:
		return

	if is_attacking:
		return

	if is_dashing:
		return

	if potion_count <= 0:
		return

	if hp >= MAX_HP:
		return


	is_using_potion = true

	velocity.x = 0.0

	anim.play("Health")

	await anim.animation_finished


	# ถ้ามี Animation อื่นแทรก
	if anim.animation != "Health":

		is_using_potion = false
		return


	if is_dead:

		is_using_potion = false
		return


	potion_count -= 1

	hp = min(
		hp + HEAL_AMOUNT,
		MAX_HP
	)

	hp_changed.emit(hp, MAX_HP)

	potion_count_changed.emit(potion_count)

	save_player_data()

	is_using_potion = false

	update_animation()


# =========================
# DASH INPUT
# =========================

func handle_dash_input() -> void:

	var shift_pressed := Input.is_key_pressed(KEY_SHIFT)

	if shift_pressed:

		shift_hold_timer += get_physics_process_delta_time()

	else:

		if (
			shift_was_pressed
			and shift_hold_timer < 0.2
		):
			start_dash()

		shift_hold_timer = 0.0


	shift_was_pressed = shift_pressed


# =========================
# DASH
# =========================

func start_dash() -> void:

	if is_dead:
		return

	if is_attacking:
		return

	if is_using_potion:
		return

	if is_knockbacked:
		return

	if is_dashing:
		return

	if dash_cooldown_timer > 0.0:
		return


	is_dashing = true
	dash_cooldown_timer = DASH_COOLDOWN

	is_invincible = true
	invincibility_timer = max(
		invincibility_timer,
		DASH_DURATION
	)

	apply_camera_shake(3.0)

	await get_tree().create_timer(
		DASH_DURATION
	).timeout

	is_dashing = false

	update_animation()


# =========================
# POTION
# =========================

func add_potion(amount: int) -> void:

	potion_count += amount

	potion_count_changed.emit(potion_count)

	save_player_data()


# =========================
# CAMERA SHAKE
# =========================

func process_camera_shake(delta: float) -> void:

	if camera == null:
		return

	if shake_intensity > 0.0:

		shake_intensity = lerp(
			shake_intensity,
			0.0,
			SHAKE_DECAY * delta
		)

		camera.offset = Vector2(
			randf_range(
				-shake_intensity,
				shake_intensity
			),
			randf_range(
				-shake_intensity,
				shake_intensity
			)
		)

	else:

		camera.offset = Vector2.ZERO


func apply_camera_shake(
	intensity: float = 5.0
) -> void:

	shake_intensity = intensity


# =========================
# SAVE / LOAD
# =========================

func load_player_data() -> void:

	if SaveManager.is_respawning:

		hp = MAX_HP

		if SaveManager.save_data.has("checkpoint_potion"):
			potion_count = SaveManager.save_data["checkpoint_potion"]

		SaveManager.is_respawning = false


	else:

		if SaveManager.save_data.has("hp"):
			hp = SaveManager.save_data["hp"]

		if SaveManager.save_data.has("potion_count"):
			potion_count = SaveManager.save_data["potion_count"]


	var has_position := false
	var spawn_position := Vector2.ZERO


	if (
		SaveManager.save_data.has("checkpoint_pos_x")
		and SaveManager.save_data.has("checkpoint_pos_y")
	):

		spawn_position = Vector2(
			SaveManager.save_data["checkpoint_pos_x"],
			SaveManager.save_data["checkpoint_pos_y"]
		)

		has_position = true


	elif (
		SaveManager.save_data.has("pos_x")
		and SaveManager.save_data.has("pos_y")
	):

		spawn_position = Vector2(
			SaveManager.save_data["pos_x"],
			SaveManager.save_data["pos_y"]
		)

		has_position = true


	if has_position:

		call_deferred(
			"_apply_saved_position",
			spawn_position
		)


func _apply_saved_position(
	saved_position: Vector2
) -> void:

	global_position = saved_position


func emit_initial_ui_signals() -> void:

	hp_changed.emit(hp, MAX_HP)

	potion_count_changed.emit(potion_count)


func update_checkpoint() -> void:

	if get_tree().current_scene != null:

		SaveManager.save_data["checkpoint_scene"] = (
			get_tree().current_scene.scene_file_path
		)


	SaveManager.save_data["checkpoint_pos_x"] = (
		global_position.x
	)

	SaveManager.save_data["checkpoint_pos_y"] = (
		global_position.y
	)

	SaveManager.save_data["checkpoint_potion"] = (
		potion_count
	)

	save_player_data()


func save_player_data() -> void:

	SaveManager.save_data["hp"] = hp

	SaveManager.save_data["potion_count"] = (
		potion_count
	)


	if get_tree().current_scene != null:

		SaveManager.save_data["current_scene"] = (
			get_tree().current_scene.scene_file_path
		)


	SaveManager.save_game()
