extends CharacterBody2D

signal died
signal hp_changed(current_hp: int, max_hp: int)
signal potion_count_changed(count: int)


# ==================================================
# CONSTANTS
# ==================================================

const MAX_HP := 100
const HEAL_AMOUNT := 35
const INVINCIBILITY_DURATION := 1.0

const WALK_SPEED := 250.0
const RUN_SPEED := 420.0
const JUMP_VELOCITY := -450.0

const DASH_SPEED := 700.0
const DASH_DURATION := 0.20
const DASH_COOLDOWN := 0.60

const SLIDE_SPEED := 550.0
const SLIDE_DURATION := 0.35
const SLIDE_COOLDOWN := 0.50

const SHAKE_DECAY := 8.0


# ==================================================
# PLAYER
# ==================================================

var hp := MAX_HP
var potion_count := 1


# ==================================================
# STATES
# ==================================================

var is_dead := false
var is_attacking := false
var is_using_potion := false
var is_dashing := false
var is_sliding := false
var is_knockbacked := false
var is_invincible := false


# ==================================================
# ATTACK
# ==================================================

var combo := 0
var attack_queued := false


# ==================================================
# TIMERS
# ==================================================

var knockback_timer := 0.0
var invincibility_timer := 0.0

var dash_timer := 0.0
var dash_cooldown_timer := 0.0

var slide_timer := 0.0
var slide_cooldown_timer := 0.0

var shift_hold_timer := 0.0
var shift_was_pressed := false


# ==================================================
# CAMERA SHAKE
# ==================================================

var shake_intensity := 0.0


# ==================================================
# NODES
# ==================================================

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area = $AttackArea
@onready var attack_collision = $AttackArea/CollisionShape2D
@onready var camera: Camera2D = $Camera2D


# ==================================================
# READY
# ==================================================

func _ready() -> void:

	attack_collision.disabled = true

	load_player_data()

	call_deferred("emit_initial_ui_signals")


# ==================================================
# PHYSICS
# ==================================================

func _physics_process(delta: float) -> void:

	process_camera_shake(delta)
	process_timers(delta)


	# DEAD
	if is_dead:
		process_dead(delta)
		return


	# POTION
	if is_using_potion:
		process_potion(delta)
		return


	# DASH
	if is_dashing:
		process_dash()
		return


	# SLIDE
	if is_sliding:
		process_slide(delta)
		return


	# NORMAL
	apply_gravity(delta)

	var direction := Input.get_axis("Left", "Right")

	process_movement(direction, delta)
	process_facing(direction)
	process_jump()
	process_inputs()

	update_animation()

	move_and_slide()


# ==================================================
# TIMERS
# ==================================================

func process_timers(delta: float) -> void:

	# Dash cooldown
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta

	# Slide cooldown
	if slide_cooldown_timer > 0.0:
		slide_cooldown_timer -= delta

	# Invincibility
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

	# Knockback
	if is_knockbacked:

		knockback_timer -= delta

		if knockback_timer <= 0.0:

			is_knockbacked = false
			update_animation()


# ==================================================
# DEAD STATE
# ==================================================

func process_dead(delta: float) -> void:

	velocity.x = move_toward(
		velocity.x,
		0.0,
		WALK_SPEED * 10.0 * delta
	)

	if not is_on_floor():
		velocity += get_gravity() * delta

	move_and_slide()


# ==================================================
# POTION STATE
# ==================================================

func process_potion(delta: float) -> void:

	velocity.x = 0.0

	if not is_on_floor():
		velocity += get_gravity() * delta

	move_and_slide()


# ==================================================
# DASH STATE
# ==================================================

func process_dash() -> void:

	var facing := -1.0 if anim.flip_h else 1.0

	velocity.x = facing * DASH_SPEED
	velocity.y = 0.0

	move_and_slide()

	dash_timer -= get_physics_process_delta_time()

	if dash_timer <= 0.0:

		is_dashing = false

		update_animation()


# ==================================================
# SLIDE STATE
# ==================================================

func process_slide(delta: float) -> void:

	# ถ้าหลุดจากพื้นระหว่าง Slide
	if not is_on_floor():

		is_sliding = false

		apply_gravity(delta)

		anim.play("Jump")

		move_and_slide()

		return


	# ลดเวลา Slide
	slide_timer -= delta


	# ทิศทาง
	var facing := -1.0 if anim.flip_h else 1.0

	velocity.x = facing * SLIDE_SPEED


	# บังคับ Animation Slide
	if anim.animation != "Slide":

		anim.play("Slide")


	move_and_slide()


	# Slide จบ
	if slide_timer <= 0.0:

		is_sliding = false

		update_animation()


# ==================================================
# GRAVITY
# ==================================================

func apply_gravity(delta: float) -> void:

	if not is_on_floor():

		velocity += get_gravity() * delta


# ==================================================
# MOVEMENT
# ==================================================

func process_movement(
	direction: float,
	delta: float
) -> void:

	# Knockback
	if is_knockbacked:

		velocity.x = move_toward(
			velocity.x,
			0.0,
			WALK_SPEED * 2.0 * delta
		)

		return


	# Attack
	if is_attacking:

		velocity.x = 0.0

		return


	# Speed
	var speed := WALK_SPEED

	if Input.is_key_pressed(KEY_SHIFT):

		speed = RUN_SPEED


	# Move
	if direction != 0:

		velocity.x = direction * speed

	else:

		velocity.x = move_toward(
			velocity.x,
			0.0,
			speed
		)


# ==================================================
# FACING
# ==================================================

func process_facing(
	direction: float
) -> void:

	if is_attacking or is_sliding:

		return


	if direction > 0:

		anim.flip_h = false
		attack_area.scale.x = 1


	elif direction < 0:

		anim.flip_h = true
		attack_area.scale.x = -1


# ==================================================
# JUMP
# ==================================================

func process_jump() -> void:

	if (
		is_attacking
		or is_sliding
		or is_dashing
	):
		return


	if (
		Input.is_action_just_pressed("Jump")
		and is_on_floor()
	):

		velocity.y = JUMP_VELOCITY


# ==================================================
# INPUT
# ==================================================

func process_inputs() -> void:

	# Potion
	if Input.is_key_pressed(KEY_H):

		use_potion()


	# Attack
	if Input.is_action_just_pressed("Attack"):

		handle_attack_input()


	# Slide = Z
	if Input.is_action_just_pressed("Slide"):
		
		start_slide()


	# Dash / Run
	handle_dash_input()


# ==================================================
# ATTACK INPUT
# ==================================================

func handle_attack_input() -> void:

	# ห้ามโจมตีกลางอากาศ
	if not is_on_floor():

		return


	if (
		is_dead
		or is_using_potion
		or is_dashing
		or is_sliding
		or is_knockbacked
	):
		return


	# Combo
	if is_attacking:

		if combo < 4:

			attack_queued = true

	else:

		start_attack()


# ==================================================
# START ATTACK
# ==================================================

func start_attack() -> void:

	if (
		is_dead
		or is_using_potion
		or is_dashing
		or is_sliding
		or is_knockbacked
	):
		return


	if not is_on_floor():

		return


	if not is_attacking:

		# Attack แรก
		is_attacking = true

		combo = 1

		attack_queued = false

	else:

		# Combo ต่อ
		combo += 1


	if combo <= 4:

		anim.play(
			"Attack_" + str(combo)
		)


# ==================================================
# CANCEL ATTACK
# ==================================================

func cancel_attack() -> void:

	is_attacking = false

	attack_queued = false

	combo = 0

	attack_collision.set_deferred(
		"disabled",
		true
	)


# ==================================================
# NORMAL ANIMATION
# ==================================================

func update_animation() -> void:

	if (
		is_dead
		or is_using_potion
		or is_dashing
		or is_sliding
		or is_attacking
	):
		return


	# Jump
	if not is_on_floor():

		if anim.animation != "Jump":

			anim.play("Jump")

		return


	# Run
	if abs(velocity.x) > 1.0:

		if anim.animation != "Run":

			anim.play("Run")

		return


	# Idle
	if anim.animation != "Idle":

		anim.play("Idle")


# ==================================================
# ANIMATION FINISHED
# ==================================================

func _on_animated_sprite_2d_animation_finished() -> void:

	# -------------------------
	# DEATH
	# -------------------------

	if anim.animation == "Death":

		# Death จบแล้วค่อยไป Game Over
		died.emit()

		return


	# -------------------------
	# HEALTH
	# -------------------------

	if (
		anim.animation == "Health"
		and is_using_potion
	):

		finish_potion()

		return


	# -------------------------
	# ATTACK
	# -------------------------

	if (
		is_attacking
		and anim.animation.begins_with("Attack")
	):

		# Combo ต่อ
		if (
			attack_queued
			and combo < 4
		):

			attack_queued = false

			start_attack()

			return


		# Attack จบ
		cancel_attack()

		update_animation()


# ==================================================
# ANIMATION FRAME
# ==================================================

func _on_animated_sprite_2d_frame_changed() -> void:

	var attacking := anim.animation.begins_with(
		"Attack"
	)


	if (
		attacking
		and anim.frame == 1
	):

		attack_collision.set_deferred(
			"disabled",
			false
		)

	else:

		attack_collision.set_deferred(
			"disabled",
			true
		)


# ==================================================
# ATTACK AREA
# ==================================================

func _on_attack_area_area_entered(
	area
) -> void:

	_deal_damage(
		area.get_parent()
	)


func _on_attack_area_body_entered(
	body
) -> void:

	_deal_damage(body)


func _deal_damage(
	enemy: Node
) -> void:

	if enemy == null:

		return


	if enemy.has_method("take_damage"):

		enemy.take_damage(10)

		apply_camera_shake(5.0)


# ==================================================
# PLAYER DAMAGE
# ==================================================

func hit() -> void:

	take_damage(10)


func take_damage(
	amount: int,
	source_position_x: float = 0.0
) -> void:

	if is_dead or is_invincible:

		return


	# -------------------------
	# CANCEL CURRENT STATE
	# -------------------------

	cancel_attack()

	is_using_potion = false
	is_sliding = false
	is_dashing = false


	# -------------------------
	# DAMAGE
	# -------------------------

	hp = max(
		hp - amount,
		0
	)


	hp_changed.emit(
		hp,
		MAX_HP
	)


	apply_camera_shake(10.0)


	# -------------------------
	# DEATH
	# -------------------------

	if hp <= 0:

		die()

		return


	# -------------------------
	# INVINCIBILITY
	# -------------------------

	is_invincible = true

	invincibility_timer = (
		INVINCIBILITY_DURATION
	)


	# -------------------------
	# KNOCKBACK
	# -------------------------

	if source_position_x != 0.0:

		var knockback_direction := (
			1.0
			if global_position.x > source_position_x
			else -1.0
		)


		velocity.x = (
			knockback_direction * 200.0
		)

		velocity.y = -150.0

		is_knockbacked = true

		knockback_timer = 0.2


# ==================================================
# DEATH
# ==================================================

func die() -> void:

	if is_dead:

		return


	is_dead = true

	is_attacking = false
	is_using_potion = false
	is_dashing = false
	is_sliding = false
	is_knockbacked = false

	attack_queued = false
	combo = 0


	attack_collision.set_deferred(
		"disabled",
		true
	)


	velocity.x = 0.0

	anim.modulate.a = 1.0


	# เล่น Death
	anim.play("Death")


	# ไม่ emit died ตรงนี้
	# จะ emit หลัง Animation Death จบ


# ==================================================
# POTION
# ==================================================

func use_potion() -> void:

	if (
		is_dead
		or is_using_potion
		or is_attacking
		or is_dashing
		or is_sliding
	):
		return


	if potion_count <= 0:

		return


	if hp >= MAX_HP:

		return


	is_using_potion = true

	velocity.x = 0.0

	anim.play("Health")


# ==================================================
# FINISH POTION
# ==================================================

func finish_potion() -> void:

	if not is_using_potion:

		return


	if is_dead:

		is_using_potion = false

		return


	# ลด Potion

	potion_count -= 1


	# Heal

	hp = min(
		hp + HEAL_AMOUNT,
		MAX_HP
	)


	# Update UI

	hp_changed.emit(
		hp,
		MAX_HP
	)

	potion_count_changed.emit(
		potion_count
	)


	# Save

	save_player_data()


	# Unlock

	is_using_potion = false

	update_animation()


# ==================================================
# ADD POTION
# ==================================================

func add_potion(
	amount: int
) -> void:

	potion_count += amount

	potion_count_changed.emit(
		potion_count
	)

	save_player_data()


# ==================================================
# SLIDE
# ==================================================

func start_slide() -> void:

	# ตาย
	if is_dead:

		return


	# --------------------------------
	# ห้าม Slide กลางอากาศ
	# --------------------------------

	if not is_on_floor():

		return


	# --------------------------------
	# State อื่น
	# --------------------------------

	if (
		is_attacking
		or is_using_potion
		or is_dashing
		or is_sliding
		or is_knockbacked
	):
		return


	# --------------------------------
	# Cooldown
	# --------------------------------

	if slide_cooldown_timer > 0.0:

		return


	# --------------------------------
	# Start
	# --------------------------------

	is_sliding = true

	slide_timer = SLIDE_DURATION

	slide_cooldown_timer = SLIDE_COOLDOWN


	# เล่น Animation
	anim.play("Slide")


# ==================================================
# DASH / RUN
# ==================================================

func handle_dash_input() -> void:

	var shift_pressed := Input.is_key_pressed(
		KEY_SHIFT
	)


	# Shift ค้าง
	if shift_pressed:

		shift_hold_timer += (
			get_physics_process_delta_time()
		)


	# Shift ปล่อย
	else:

		# Dash ต้อง:
		# - กด Shift เร็ว
		# - อยู่บนพื้น

		if (
			shift_was_pressed
			and shift_hold_timer < 0.2
			and is_on_floor()
		):

			start_dash()


		shift_hold_timer = 0.0


	shift_was_pressed = shift_pressed


# ==================================================
# START DASH
# ==================================================

func start_dash() -> void:

	# ห้าม Dash กลางอากาศ
	if not is_on_floor():

		return


	# State
	if (
		is_dead
		or is_attacking
		or is_using_potion
		or is_sliding
		or is_knockbacked
		or is_dashing
	):
		return


	# Cooldown
	if dash_cooldown_timer > 0.0:

		return


	# Start
	is_dashing = true

	dash_timer = DASH_DURATION

	dash_cooldown_timer = DASH_COOLDOWN


	# Invincibility
	is_invincible = true

	invincibility_timer = max(
		invincibility_timer,
		DASH_DURATION
	)


	apply_camera_shake(3.0)


# ==================================================
# CAMERA SHAKE
# ==================================================

func process_camera_shake(
	delta: float
) -> void:

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


# ==================================================
# LOAD PLAYER DATA
# ==================================================

func load_player_data() -> void:

	if SaveManager.is_respawning:

		hp = MAX_HP


		if SaveManager.save_data.has(
			"checkpoint_potion"
		):

			potion_count = (
				SaveManager.save_data[
					"checkpoint_potion"
				]
			)


		SaveManager.is_respawning = false


	else:

		if SaveManager.save_data.has("hp"):

			hp = SaveManager.save_data["hp"]


		if SaveManager.save_data.has(
			"potion_count"
		):

			potion_count = (
				SaveManager.save_data[
					"potion_count"
				]
			)


	# Position
	var has_position := false

	var spawn_position := Vector2.ZERO


	if (
		SaveManager.save_data.has(
			"checkpoint_pos_x"
		)
		and
		SaveManager.save_data.has(
			"checkpoint_pos_y"
		)
	):

		spawn_position = Vector2(

			SaveManager.save_data[
				"checkpoint_pos_x"
			],

			SaveManager.save_data[
				"checkpoint_pos_y"
			]

		)

		has_position = true


	elif (
		SaveManager.save_data.has("pos_x")
		and
		SaveManager.save_data.has("pos_y")
	):

		spawn_position = Vector2(

			SaveManager.save_data[
				"pos_x"
			],

			SaveManager.save_data[
				"pos_y"
			]

		)

		has_position = true


	if has_position:

		call_deferred(
			"_apply_saved_position",
			spawn_position
		)


# ==================================================
# APPLY POSITION
# ==================================================

func _apply_saved_position(
	saved_position: Vector2
) -> void:

	global_position = saved_position


# ==================================================
# INITIAL UI
# ==================================================

func emit_initial_ui_signals() -> void:

	hp_changed.emit(
		hp,
		MAX_HP
	)

	potion_count_changed.emit(
		potion_count
	)


# ==================================================
# CHECKPOINT
# ==================================================

func update_checkpoint() -> void:

	if get_tree().current_scene != null:

		SaveManager.save_data[
			"checkpoint_scene"
		] = (
			get_tree().current_scene.scene_file_path
		)


	SaveManager.save_data[
		"checkpoint_pos_x"
	] = global_position.x


	SaveManager.save_data[
		"checkpoint_pos_y"
	] = global_position.y


	SaveManager.save_data[
		"checkpoint_potion"
	] = potion_count


	save_player_data()


# ==================================================
# SAVE
# ==================================================

func save_player_data() -> void:

	SaveManager.save_data[
		"hp"
	] = hp


	SaveManager.save_data[
		"potion_count"
	] = potion_count


	if get_tree().current_scene != null:

		SaveManager.save_data[
			"current_scene"
		] = (
			get_tree().current_scene.scene_file_path
		)


	SaveManager.save_game()
