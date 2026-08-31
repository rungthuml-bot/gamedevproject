extends CharacterBody2D
class_name EnemySword

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
const ATTACK_RANGE: float = 60.0      # ระยะฟันดาบ

# =========================================================
# Combat Stats
# =========================================================

const MAX_HP: int = 80
const KNOCKBACK_FORCE: float = 400.0
const KNOCKBACK_DURATION: float = 0.20
const ATTACK_COOLDOWN: float = 1.5
const SWORD_DAMAGE: int = 20
const CONTACT_DAMAGE: int = 5

var hp: int = MAX_HP
var knockback_timer: float = 0.0
var attack_timer: float = 0.0
var is_dying: bool = false
var is_attacking: bool = false

# =========================================================
# State Machine
# =========================================================

enum State { PATROL, CHASE, ATTACK }
var current_state: State = State.PATROL

var start_position_x: float = 0.0
var move_direction: float = 1.0

# =========================================================
# Node References
# =========================================================

@onready var hp_bar: ProgressBar = $HPBar
@onready var polygon: Polygon2D = $Polygon2D
@onready var sword_visual: Polygon2D = $SwordVisual
@onready var attack_hitbox: Area2D = $AttackHitbox

# =========================================================
# Ready
# =========================================================

func _ready() -> void:
	hp_bar.max_value = MAX_HP
	hp_bar.value = hp
	start_position_x = global_position.x
	sword_visual.visible = false

# =========================================================
# Physics Process
# =========================================================

func _physics_process(delta: float) -> void:
	if is_dying:
		return

	# Gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Timers
	if attack_timer > 0.0:
		attack_timer -= delta

	if knockback_timer > 0.0:
		knockback_timer -= delta
	else:
		update_ai_behavior()

	move_and_slide()

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

func process_patrol() -> void:
	if global_position.x >= start_position_x + PATROL_DISTANCE:
		move_direction = -1.0
	elif global_position.x <= start_position_x - PATROL_DISTANCE:
		move_direction = 1.0

	velocity.x = move_direction * PATROL_SPEED
	update_facing_direction()

func process_chase(player_x: float) -> void:
	var dir := signf(player_x - global_position.x)
	if dir != 0.0:
		move_direction = dir

	velocity.x = move_direction * CHASE_SPEED
	update_facing_direction()

func update_facing_direction() -> void:
	if move_direction != 0:
		# Flip visuals and hitboxes depending on direction
		polygon.scale.x = move_direction
		sword_visual.position.x = 16 * move_direction
		sword_visual.scale.x = move_direction
		attack_hitbox.position.x = 16 * move_direction
		attack_hitbox.scale.x = move_direction

func process_attack(player: Node2D) -> void:
	is_attacking = true
	velocity.x = 0 # Stop moving
	
	# Face the player before attacking
	var dir := signf(player.global_position.x - global_position.x)
	if dir != 0:
		move_direction = dir
		update_facing_direction()

	# Telegraph (ง้างดาบ)
	sword_visual.visible = true
	sword_visual.color = Color.YELLOW
	
	# Wait for wind-up
	await get_tree().create_timer(0.3).timeout
	
	if is_dying:
		return
		
	# Attack!
	sword_visual.color = Color.WHITE
	
	# Check if player is in hitbox
	var bodies = attack_hitbox.get_overlapping_bodies()
	for b in bodies:
		if b.is_in_group("player") and b.has_method("take_damage"):
			b.take_damage(SWORD_DAMAGE, global_position.x)
			
	# Cooldown
	attack_timer = ATTACK_COOLDOWN
	
	# Wait for swing recovery
	await get_tree().create_timer(0.2).timeout
	sword_visual.visible = false
	is_attacking = false
	current_state = State.CHASE

# =========================================================
# Collision & Damage
# =========================================================

func take_damage(amount: int) -> void:
	if is_dying:
		return

	hp -= amount
	hp = max(hp, 0)
	hp_bar.value = hp

	if polygon != null:
		var tween := create_tween()
		polygon.modulate = Color.RED
		tween.tween_property(polygon, "modulate", Color.WHITE, 0.1)

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
