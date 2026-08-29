extends CharacterBody2D


# =========================================================
# Gravity & Speed
# =========================================================

const GRAVITY: float = 1200.0
const PATROL_SPEED: float = 60.0
const CHASE_SPEED: float = 130.0


# =========================================================
# AI Detection & Range
# =========================================================

const DETECTION_RANGE: float = 200.0  # ระยะมองเห็น Player
const PATROL_DISTANCE: float = 100.0  # ระยะเดินกลับไปกลับมา


# =========================================================
# HP & Knockback
# =========================================================

const MAX_HP: int = 80
const KNOCKBACK_FORCE: float = 400.0
const KNOCKBACK_DURATION: float = 0.20

var hp: int = MAX_HP
var knockback_timer: float = 0.0
var is_dying: bool = false


# =========================================================
# State Machine
# =========================================================

enum State { PATROL, CHASE }
var current_state: State = State.PATROL

var start_position_x: float = 0.0
var move_direction: float = 1.0


# =========================================================
# Node References
# =========================================================

@onready var hp_bar: ProgressBar = $HPBar
@onready var polygon: Polygon2D = $Polygon2D


# =========================================================
# Ready
# =========================================================

func _ready() -> void:

	hp_bar.max_value = MAX_HP
	hp_bar.value = hp
	start_position_x = global_position.x


# =========================================================
# Physics Process
# =========================================================

func _physics_process(delta: float) -> void:

	if is_dying:
		return

	# Gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Knockback Handling
	if knockback_timer > 0.0:
		knockback_timer -= delta
	else:
		update_ai_behavior()

	move_and_slide()

	# Contact Damage ชน Player
	check_player_collision()


# =========================================================
# AI Logic
# =========================================================

func update_ai_behavior() -> void:

	var player := get_tree().get_first_node_in_group("player") as Node2D

	if player != null:
		var distance_to_player := global_position.distance_to(player.global_position)

		# เช็กระยะว่าเจอ Player หรือไม่
		if distance_to_player <= DETECTION_RANGE:
			current_state = State.CHASE
		else:
			current_state = State.PATROL

	# ทำงานตาม State
	match current_state:
		State.PATROL:
			process_patrol()
		State.CHASE:
			if player != null:
				process_chase(player.global_position.x)


func process_patrol() -> void:

	# เดินกลับไปกลับมาจากจุดเริ่มต้น
	if global_position.x >= start_position_x + PATROL_DISTANCE:
		move_direction = -1.0
	elif global_position.x <= start_position_x - PATROL_DISTANCE:
		move_direction = 1.0

	velocity.x = move_direction * PATROL_SPEED


func process_chase(player_x: float) -> void:

	# วิ่งเข้าหาตำแหน่ง Player
	var dir := signf(player_x - global_position.x)
	if dir != 0.0:
		move_direction = dir

	velocity.x = move_direction * CHASE_SPEED


# =========================================================
# Collision & Damage
# =========================================================

func check_player_collision() -> void:

	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()

		if collider != null and collider.is_in_group("player"):
			if collider.has_method("take_damage"):
				collider.take_damage(15, global_position.x)


func take_damage(amount: int) -> void:

	if is_dying:
		return

	hp -= amount
	hp = max(hp, 0)
	hp_bar.value = hp

	# Flash สีแดง
	if polygon != null:
		var tween := create_tween()
		polygon.modulate = Color.RED
		tween.tween_property(polygon, "modulate", Color.WHITE, 0.1)

	# Knockback
	apply_knockback()

	if hp <= 0:
		die()


func apply_knockback() -> void:

	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player != null:
		var dir := signf(global_position.x - player.global_position.x)
		velocity.x = (1.0 if dir == 0.0 else dir) * KNOCKBACK_FORCE
		knockback_timer = KNOCKBACK_DURATION


func die() -> void:

	is_dying = true
	velocity = Vector2.ZERO

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_property(self, "scale", Vector2(0.1, 0.1), 0.3)

	await tween.finished
	queue_free()
