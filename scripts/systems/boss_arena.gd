extends Node2D
class_name BossArena

@export var boss_path: NodePath
var boss: Boss = null

@onready var trigger_area: Area2D = $TriggerArea
@onready var left_wall: StaticBody2D = $LeftWall
@onready var right_wall: StaticBody2D = $RightWall
@onready var boss_ui_layer: CanvasLayer = $BossUI
@onready var hp_bar: ProgressBar = $BossUI/Control/MarginContainer/VBoxContainer/BossHPBar

var is_fight_active: bool = false

func _ready() -> void:
	# ซ่อนกำแพงและปิด collision
	_set_walls_active(false)
	
	# ซ่อน UI
	boss_ui_layer.visible = false
	
	# เชื่อม Trigger
	trigger_area.body_entered.connect(_on_trigger_entered)
	
	if boss_path:
		boss = get_node(boss_path) as Boss
		if boss:
			boss.hp_changed.connect(_on_boss_hp_changed)
			boss.died.connect(_on_boss_died)
			
			hp_bar.max_value = boss.MAX_HP
			hp_bar.value = boss.hp

func _on_trigger_entered(body: Node2D) -> void:
	if is_fight_active:
		return
		
	if body.is_in_group("player"):
		start_boss_fight()

func start_boss_fight() -> void:
	is_fight_active = true
	
	# เปิดกำแพงกันหนี
	_set_walls_active(true)
	
	# โชว์ UI เลือดบอส
	boss_ui_layer.visible = true
	
	# ให้บอสตื่นทันที (Optional)
	if boss and boss.current_state == Boss.State.PATROL:
		boss.current_state = Boss.State.CHASE

func _on_boss_hp_changed(current_hp: int, max_hp: int) -> void:
	# ทำ Animate หลอดเลือดลดลงได้ถ้าต้องการ ตอนนี้ตั้งค่าตรงๆ ไปก่อน
	var tween = create_tween()
	tween.tween_property(hp_bar, "value", current_hp, 0.2).set_trans(Tween.TRANS_CUBIC)

func _on_boss_died() -> void:
	is_fight_active = false
	
	# ซ่อน UI
	var tween = create_tween()
	tween.tween_property(boss_ui_layer.get_node("Control"), "modulate:a", 0.0, 1.0)
	await tween.finished
	boss_ui_layer.visible = false
	
	# เปิดกำแพงให้ผ่านได้
	_set_walls_active(false)

func _set_walls_active(active: bool) -> void:
	left_wall.get_node("CollisionShape2D").set_deferred("disabled", not active)
	right_wall.get_node("CollisionShape2D").set_deferred("disabled", not active)
