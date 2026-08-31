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

var base_max_hp := 100
var max_hp := 100
var attack_multiplier := 1.0
@export var attack_frame: int = 1

var walk_speed := 250.0
var run_speed := 420.0
const JUMP_VELOCITY := -450.0

var dash_speed := 700.0
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
var is_charging_heavy := false


# ==================================================
# HEAVY ATTACK CHARGE
# ==================================================

var heavy_charge_timer := 0.0
const HEAVY_MAX_CHARGE := 2.0

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

# SFX
@onready var light_attack_sound: AudioStreamPlayer2D = $Light_Attack
@onready var heavy_attack_sound: AudioStreamPlayer2D = $Heavy_Attack
@onready var health_potion_sound: AudioStreamPlayer2D = $Health_Potion
@onready var slide_sound: AudioStreamPlayer2D = $Slide
@onready var charge_sound: AudioStreamPlayer2D = $Charge
@onready var full_charge_sound: AudioStreamPlayer2D = $Full_Charge


# ==================================================
# READY
# ==================================================

func _ready() -> void:

	attack_collision.disabled = true

	if SaveManager.has_signal("equipped_charms_changed"):
		if not SaveManager.equipped_charms_changed.is_connected(update_stats_from_charms):
			SaveManager.equipped_charms_changed.connect(update_stats_from_charms)

	update_stats_from_charms()
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

	var direction := Input.get_axis(
		"Left",
		"Right"
	)

	process_movement(direction, delta)
	process_facing(direction)
	process_jump()
	process_inputs(delta)

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
				if fmod(
					invincibility_timer,
					0.2
				) > 0.1
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
		walk_speed * 10.0 * delta
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

	velocity.x = facing * dash_speed
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


	slide_timer -= delta


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
			walk_speed * 2.0 * delta
		)

		return


	# Attack
	if is_attacking:

		velocity.x = 0.0

		return


	# Speed
	var speed := walk_speed

	if Input.is_key_pressed(KEY_SHIFT):

		speed = run_speed


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

	if is_attacking or is_sliding or is_charging_heavy:

		return


	if direction > 0:

		anim.flip_h = false
		attack_collision.position.x = 26.0


	elif direction < 0:

		anim.flip_h = true
		attack_collision.position.x = -26.0


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

func process_inputs(delta: float) -> void:

	# Potion
	if Input.is_key_pressed(KEY_H):

		use_potion()


	# ==================================================
	# Heavy Attack Charge
	# ==================================================

	if Input.is_mouse_button_pressed(
		MOUSE_BUTTON_RIGHT
	):

		if (
			not is_charging_heavy
			and is_on_floor()
			and not is_attacking
			and not is_sliding
			and not is_dashing
			and not is_using_potion
			and not is_knockbacked
			and not is_dead
		):

			is_charging_heavy = true
			heavy_charge_timer = 0.0

			anim.play("Attack_4")
			anim.pause()

			# Frame 0 = ท่าเริ่มชาร์จ
			anim.frame = 0

			# ==========================================
			# Charge SFX
			# เล่นครั้งเดียวตอนเริ่มชาร์จ
			# ==========================================

			if not charge_sound.playing:

				charge_sound.play()


		if is_charging_heavy:

			var old_timer := heavy_charge_timer

			heavy_charge_timer = min(
				heavy_charge_timer + delta,
				HEAVY_MAX_CHARGE
			)


			# ==========================================
			# วน Frame 0 และ 1
			# ==========================================

			anim.frame = int(
				heavy_charge_timer * 10.0
			) % 2


			# ==========================================
			# Charge เต็ม
			# ==========================================

			if (
				old_timer < HEAVY_MAX_CHARGE
				and heavy_charge_timer >= HEAVY_MAX_CHARGE
			):

				# หยุด Charge SFX
				charge_sound.stop()


				# เล่น Full Charge SFX ครั้งเดียว
				if not full_charge_sound.playing:

					full_charge_sound.play()


				# Flash
				anim.modulate = Color(
					2.0,
					2.0,
					2.0
				)

				var tween := create_tween()

				tween.tween_property(
					anim,
					"modulate",
					Color(1.0, 1.0, 1.0),
					0.2
				)


			velocity.x = 0.0

			return


	# ==================================================
	# ปล่อยคลิกขวา
	# ==================================================

	elif is_charging_heavy:

		is_charging_heavy = false

		# หยุด Charge SFX
		charge_sound.stop()

		anim.modulate = Color(
			1.0,
			1.0,
			1.0
		)

		start_heavy_attack()

		return


	# ==================================================
	# Attack
	# ==================================================

	if Input.is_action_just_pressed("Attack"):

		handle_attack_input()


	# ==================================================
	# Shift: Tap for Slide, Hold for Run
	# ==================================================

	var shift_pressed := Input.is_key_pressed(
		KEY_SHIFT
	)


	if shift_pressed:

		shift_hold_timer += delta

	else:

		if (
			shift_was_pressed
			and shift_hold_timer < 0.2
			and not is_sliding
		):

			start_slide()


		shift_hold_timer = 0.0


	shift_was_pressed = shift_pressed


	# ==================================================
	# ไม่มี Z Slide แล้ว
	# ==================================================


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
		or is_charging_heavy
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
		or is_charging_heavy
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
# HEAVY ATTACK
# ==================================================

func start_heavy_attack() -> void:

	if not is_on_floor():

		return


	is_attacking = true

	combo = 1

	attack_queued = false


	# Bonus multiplier based on charge time
	var bonus_mult := (
		1.0
		+ (
			heavy_charge_timer
			/ HEAVY_MAX_CHARGE
		) * 2.0
	)

	attack_multiplier = bonus_mult


	# Resume Attack_4
	if anim.animation == "Attack_4":

		anim.play()

	else:

		anim.play("Attack_4")


	heavy_charge_timer = 0.0


# ==================================================
# CANCEL ATTACK
# ==================================================

func cancel_attack() -> void:

	is_attacking = false

	attack_queued = false

	combo = 0

	update_stats_from_charms()


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
		or is_charging_heavy
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


	# ==================================================
	# ATTACK 1-3
	# ==================================================

	if (
		attacking
		and not is_charging_heavy
		and anim.animation != "Attack_4"
		and anim.frame == attack_frame
	):

		attack_collision.set_deferred(
			"disabled",
			false
		)


		# Light Attack SFX
		if not light_attack_sound.playing:

			light_attack_sound.play()


		return


	# ==================================================
	# ATTACK 4 NORMAL
	# ==================================================

	if (
		anim.animation == "Attack_4"
		and not is_charging_heavy
		and anim.frame == attack_frame
	):

		attack_collision.set_deferred(
			"disabled",
			false
		)


		# Heavy Attack SFX
		if not heavy_attack_sound.playing:

			heavy_attack_sound.play()


		return


	# ==================================================
	# OTHER FRAMES
	# ==================================================

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

		enemy.take_damage(
			int(10 * attack_multiplier)
		)

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


	# ==================================================
	# ยกเลิก Heavy Charge เมื่อโดนตี
	# ==================================================

	if is_charging_heavy:

		is_charging_heavy = false

		heavy_charge_timer = 0.0

		# หยุดเสียง Charge
		charge_sound.stop()

		# รีเซ็ต Full Charge sound state
		anim.modulate = Color(
			1.0,
			1.0,
			1.0
		)

		attack_collision.set_deferred(
			"disabled",
			true
		)


	# ==================================================
	# CANCEL CURRENT STATE
	# ==================================================

	cancel_attack()

	is_using_potion = false
	is_sliding = false
	is_dashing = false


	# ==================================================
	# DAMAGE
	# ==================================================

	hp = max(
		hp - amount,
		0
	)


	hp_changed.emit(
		hp,
		max_hp
	)


	apply_camera_shake(10.0)


	# ==================================================
	# DEATH
	# ==================================================

	if hp <= 0:

		die()

		return


	# ==================================================
	# INVINCIBILITY
	# ==================================================

	is_invincible = true

	invincibility_timer = (
		INVINCIBILITY_DURATION
	)


	# ==================================================
	# KNOCKBACK
	# ==================================================

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

	is_charging_heavy = false
	heavy_charge_timer = 0.0

	attack_queued = false
	combo = 0


	# หยุดเสียง Charge
	charge_sound.stop()

	attack_collision.set_deferred(
		"disabled",
		true
	)


	velocity.x = 0.0

	anim.modulate.a = 1.0

	anim.play("Death")


# ==================================================
# SYSTEM INTEGRATIONS
# ==================================================

func update_stats_from_charms() -> void:

	max_hp = base_max_hp
	attack_multiplier = 1.0
	walk_speed = 250.0
	run_speed = 420.0
	dash_speed = 700.0


	if SaveManager.is_charm_equipped(
		"health_charm"
	):

		max_hp += 50


	if SaveManager.is_charm_equipped(
		"power_charm"
	):

		attack_multiplier += 0.5


	if SaveManager.is_charm_equipped(
		"speed_charm"
	):

		walk_speed *= 1.2
		run_speed *= 1.2
		dash_speed *= 1.2


	hp = min(
		hp,
		max_hp
	)


	hp_changed.emit(
		hp,
		max_hp
	)


func _input(
	event: InputEvent
) -> void:

	if (
		event is InputEventKey
		and event.pressed
		and event.keycode == KEY_E
	):

		_try_interact()


func _try_interact() -> void:

	var interactables = (
		get_tree().get_nodes_in_group(
			"interactable"
		)
	)


	for node in interactables:

		if (
			node.has_method("interact")
			and global_position.distance_to(
				node.global_position
			) < 80.0
		):

			node.interact()

			return


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
		or is_charging_heavy
	):

		return


	if potion_count <= 0:

		return


	if hp >= max_hp:

		return


	is_using_potion = true

	velocity.x = 0.0


	# Health Potion SFX
	if not health_potion_sound.playing:

		health_potion_sound.play()


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
		max_hp
	)


	# Effect
	var heal_particles = CPUParticles2D.new()

	heal_particles.emitting = false
	heal_particles.one_shot = true
	heal_particles.amount = 30
	heal_particles.lifetime = 1.0

	heal_particles.emission_shape = (
		CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	)

	heal_particles.emission_rect_extents = Vector2(
		15,
		20
	)

	heal_particles.direction = Vector2(
		0,
		-1
	)

	heal_particles.gravity = Vector2(
		0,
		-50
	)

	heal_particles.initial_velocity_min = 30.0
	heal_particles.initial_velocity_max = 60.0

	heal_particles.scale_amount_min = 2.0
	heal_particles.scale_amount_max = 4.0

	heal_particles.color = Color(
		0.2,
		1.0,
		0.4,
		0.8
	)

	add_child(heal_particles)

	heal_particles.emitting = true

	get_tree().create_timer(
		1.5
	).timeout.connect(
		heal_particles.queue_free
	)


	# Update UI
	hp_changed.emit(
		hp,
		max_hp
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


	# ห้าม Slide กลางอากาศ
	if not is_on_floor():

		return


	# State อื่น
	if (
		is_attacking
		or is_using_potion
		or is_dashing
		or is_sliding
		or is_knockbacked
		or is_charging_heavy
	):

		return


	# Cooldown
	if slide_cooldown_timer > 0.0:

		return


	# Start
	is_sliding = true

	slide_timer = SLIDE_DURATION

	slide_cooldown_timer = SLIDE_COOLDOWN


	# Slide SFX
	if not slide_sound.playing:

		slide_sound.play()


	# Animation
	anim.play("Slide")


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
		or is_charging_heavy
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

		hp = max_hp


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
		max_hp
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
