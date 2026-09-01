extends CharacterBody2D
class_name Boss

signal hp_changed(current_hp: int, max_hp: int)
signal died()

# =========================================================
# Gravity & Speed
# =========================================================

const GRAVITY: float = 1200.0
const PATROL_SPEED: float = 40.0

# Base speeds (will change in phase 2)
var chase_speed: float = 80.0

# =========================================================
# AI Detection & Range
# =========================================================

const DETECTION_RANGE: float = 800.0  # ระยะมองเห็นกว้างมาก (ห้องบอส)
const PATROL_DISTANCE: float = 200.0  
const ATTACK_RANGE: float = 100.0     # ระยะโจมตีกว้าง

# =========================================================
# Combat Stats
# =========================================================

const MAX_HP: int = 250
const KNOCKBACK_FORCE: float = 50.0   # บอสโดนผลักแทบจะไม่ถอย
const KNOCKBACK_DURATION: float = 0.1
const BOSS_DAMAGE: int = 15
const CONTACT_DAMAGE: int = 10

var attack_cooldown: float = 2.0

var hp: int = MAX_HP
var knockback_timer: float = 0.0
var attack_timer: float = 0.0
var enrage_stun_timer: float = 0.0
var is_dying: bool = false
var is_attacking: bool = false
var attack_dealt_damage: bool = false

@export var attack_frame: int = 2

# =========================================================
# Boss Phases
# =========================================================
var is_enraged: bool = false

# =========================================================
# State Machine
# =========================================================

enum State { PATROL, CHASE, ATTACK, JUMP }
var current_state: State = State.PATROL

var start_position_x: float = 0.0
var move_direction: float = 1.0

# Leap Attack variables
const JUMP_FORCE: float = 800.0
var jump_cooldown: float = 5.0
var jump_timer: float = 0.0

# =========================================================
# Node References
# =========================================================

@onready var anim: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")
# Smart AI Sensors
var ledge_raycast: RayCast2D
var trap_raycast: RayCast2D
@onready var attack_hitbox: Area2D = $AttackHitbox

# =========================================================
# Ready
# =========================================================

func _ready() -> void:
	start_position_x = global_position.x
	# Initialize Smart AI Sensors
	ledge_raycast = RayCast2D.new()
	add_child(ledge_raycast)
	ledge_raycast.target_position = Vector2(25, 40)
	
	trap_raycast = RayCast2D.new()
	add_child(trap_raycast)
	trap_raycast.target_position = Vector2(30, 0)
	trap_raycast.collide_with_areas = true

	scale = Vector2(2.0, 2.0) # ทำให้ตัวใหญ่เป็น 2 เท่า
	if anim:
		anim.play("Idle")
		anim.modulate = Color(0.8, 0.5, 0.9, 1.0) # สีม่วงเข้มสำหรับบอส
		if not anim.animation_finished.is_connected(_on_anim_animation_finished):
			anim.animation_finished.connect(_on_anim_animation_finished)
		if not anim.animation_looped.is_connected(_on_anim_animation_finished):
			anim.animation_looped.connect(_on_anim_animation_finished)
		if not anim.frame_changed.is_connected(_on_anim_frame_changed):
			anim.frame_changed.connect(_on_anim_frame_changed)

# =========================================================
# Physics Process
# =========================================================

func _physics_process(delta: float) -> void:
	if is_dying:
		return

	# Gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	if enrage_stun_timer > 0.0:
		enrage_stun_timer -= delta
		velocity.x = 0
		if anim: anim.play("Idle")
		move_and_slide()
		return

	# Timers
	if attack_timer > 0.0:
		attack_timer -= delta

	if jump_timer > 0.0:
		jump_timer -= delta

	if knockback_timer > 0.0:
		knockback_timer -= delta
	else:
		update_ai_behavior()

	move_and_slide()
	update_animation()

# =========================================================
# AI Logic
# =========================================================

func update_ai_behavior() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D

	if player != null and not is_attacking:
		var distance_to_player := global_position.distance_to(player.global_position)

		if distance_to_player <= ATTACK_RANGE and attack_timer <= 0.0:
			current_state = State.ATTACK
		elif distance_to_player <= DETECTION_RANGE:
			if jump_timer <= 0.0 and is_on_floor() and distance_to_player > 200.0:
				current_state = State.JUMP
				_start_jump(player)
			else:
				current_state = State.CHASE
		else:
			current_state = State.PATROL
	elif player == null and not is_attacking:
		current_state = State.PATROL

	match current_state:
		State.PATROL:
			process_patrol()
		State.CHASE:
			if player != null:
				process_chase(player.global_position.x)
		State.ATTACK:
			if not is_attacking and player != null:
				process_attack(player)
		State.JUMP:
			process_jump()


func is_facing_hazard() -> bool:
	if is_on_wall(): return true
	if is_on_floor() and ledge_raycast and not ledge_raycast.is_colliding(): return true
	if trap_raycast and trap_raycast.is_colliding():
		var collider = trap_raycast.get_collider()
		if collider is Area2D and collider.has_method("_apply_trap_effect"):
			return true
	return false

func process_patrol() -> void:
	if is_facing_hazard():
		move_direction = -1.0 if move_direction > 0.0 else 1.0
		start_position_x = global_position.x - (move_direction * PATROL_DISTANCE / 2.0)
	elif global_position.x >= start_position_x + PATROL_DISTANCE:
		move_direction = -1.0
	elif global_position.x <= start_position_x - PATROL_DISTANCE:
		move_direction = 1.0

	velocity.x = move_direction * PATROL_SPEED
	update_facing_direction()

func process_chase(player_x: float) -> void:
	var dir := signf(player_x - global_position.x)
	if dir != 0.0:
		move_direction = dir

		if is_facing_hazard():
			velocity.x = 0
	else:
		velocity.x = move_direction * chase_speed
	update_facing_direction()

func _start_jump(player: Node2D) -> void:
	var dir := signf(player.global_position.x - global_position.x)
	var jump_target_x = player.global_position.x + (dir * 150.0)
	
	velocity.y = -JUMP_FORCE
	
	var distance_x = jump_target_x - global_position.x
	var time_in_air = (2.0 * JUMP_FORCE) / GRAVITY
	velocity.x = distance_x / time_in_air
	
	jump_cooldown = 3.0 if is_enraged else 6.0
	jump_timer = jump_cooldown
	
	if anim:
		anim.play("Idle")

func process_jump() -> void:
	move_direction = signf(velocity.x)
	update_facing_direction()
	
	if is_on_floor() and velocity.y >= 0:
		_deal_landing_damage()
		current_state = State.CHASE
		velocity.x = 0

func _deal_landing_damage() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player and player.has_method("apply_camera_shake"):
		player.apply_camera_shake(15.0)
		
	if player and global_position.distance_to(player.global_position) <= 200.0:
		if player.has_method("take_damage"):
			player.take_damage(BOSS_DAMAGE, global_position.x)

func update_facing_direction() -> void:
	if move_direction != 0:
		if anim:
			anim.flip_h = (move_direction < 0)
			
		attack_hitbox.position.x = 16 * move_direction
		
		# Flip Smart AI Sensors
		if ledge_raycast: ledge_raycast.target_position.x = 25 * move_direction
		if trap_raycast: trap_raycast.target_position.x = 30 * move_direction

func update_animation() -> void:
	if is_dying or is_attacking or not anim:
		return
		
	if current_state == State.JUMP:
		return
		
	if velocity.x != 0:
		anim.play("Walk")
	else:
		anim.play("Idle")

func process_attack(player: Node2D) -> void:
	is_attacking = true
	attack_dealt_damage = false
	velocity.x = 0 # Stop moving
	
	# Face the player before attacking
	var dir := signf(player.global_position.x - global_position.x)
	if dir != 0:
		move_direction = dir
		update_facing_direction()

	if anim:
		if is_enraged and anim.sprite_frames.has_animation("Attack2"):
			anim.play("Attack2")
		elif anim.sprite_frames.has_animation("Attack1"):
			anim.play("Attack1")
		elif anim.sprite_frames.has_animation("Attack"):
			anim.play("Attack")
	else:
		# Fallback if no animation node is present
		var windup_time = 0.5 if not is_enraged else 0.2
		await get_tree().create_timer(windup_time).timeout
		_deal_damage()
		var recovery = 0.4 if not is_enraged else 0.2
		await get_tree().create_timer(recovery).timeout
		_reset_attack()

func _on_anim_frame_changed() -> void:
	if not is_attacking or not anim: return
	
	var is_attack_anim = anim.animation.begins_with("Attack")
	if is_attack_anim and anim.frame == attack_frame and not attack_dealt_damage:
		_deal_damage()

func _on_anim_animation_finished() -> void:
	if is_attacking and anim and anim.animation.begins_with("Attack"):
		_reset_attack()

func _deal_damage() -> void:
	if is_dying: return
	attack_dealt_damage = true
	
	var bodies = attack_hitbox.get_overlapping_bodies()
	for b in bodies:
		if b.is_in_group("player") and b.has_method("take_damage"):
			b.take_damage(BOSS_DAMAGE, global_position.x)

func _reset_attack() -> void:
	attack_timer = attack_cooldown
	is_attacking = false
	current_state = State.CHASE

# =========================================================
# Collision & Damage & Phases
# =========================================================

func take_damage(amount: int) -> void:
	if is_dying:
		return

	hp -= amount
	hp = max(hp, 0)
	hp_changed.emit(hp, MAX_HP)

	# Phase Check
	if hp <= (MAX_HP * 0.5) and not is_enraged:
		trigger_enrage()

	if anim != null:
		var tween := create_tween()
		var base_color = Color(1.0, 0.4, 0.4, 1.0) if is_enraged else Color(0.8, 0.5, 0.9, 1.0)
		anim.modulate = Color.RED
		tween.tween_property(anim, "modulate", base_color, 0.1)

	apply_knockback()

	if hp <= 0:
		die()

func trigger_enrage() -> void:
	is_enraged = true
	enrage_stun_timer = 2.0 # สตั้นตอนโกรธ 2 วินาที
	# เพิ่มสเตตัสความบ้าคลั่ง
	chase_speed = 130.0
	attack_cooldown = 1.0
	
	# เปลี่ยนสีเป็นแดง
	if anim:
		anim.modulate = Color(1.0, 0.4, 0.4, 1.0)
	
	# เอฟเฟกต์สะเทือนนิดหน่อยตอนเปลี่ยนร่าง
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("apply_camera_shake"):
		player.apply_camera_shake(10.0)

func apply_knockback() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player != null:
		var dir := signf(global_position.x - player.global_position.x)
		velocity.x = (1.0 if dir == 0.0 else dir) * KNOCKBACK_FORCE
		knockback_timer = KNOCKBACK_DURATION

func die() -> void:
	died.emit()
	is_dying = true
	velocity = Vector2.ZERO

	if anim:
		anim.play("Die")

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 1.5)

	await get_tree().create_timer(1.5).timeout
	queue_free()
