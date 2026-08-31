extends Node2D
class_name BossArena

@export var boss_path: NodePath

# บทสนทนาก่อนสู้บอส (เก็บไว้เป็นคีย์เปล่าๆ เพราะเราจะโหลดจาก LocaleManager แทน)
var intro_dialog: Array = []

var boss: Boss = null

@onready var trigger_area: Area2D = $TriggerArea
@onready var left_wall: StaticBody2D = $LeftWall
@onready var right_wall: StaticBody2D = $RightWall
@onready var boss_ui_layer: CanvasLayer = $BossUI
@onready var hp_bar: ProgressBar = $BossUI/Control/MarginContainer/VBoxContainer/BossHPBar

var is_fight_active: bool = false

func _ready() -> void:
	_set_walls_active(false)
	boss_ui_layer.visible = false
	trigger_area.body_entered.connect(_on_trigger_entered)
	
	if boss_path:
		boss = get_node(boss_path) as Boss
		if boss:
			boss.hp_changed.connect(_on_boss_hp_changed)
			boss.died.connect(_on_boss_died)
			hp_bar.max_value = boss.MAX_HP
			hp_bar.value = boss.hp
			
	if has_node("/root/LocaleManager"):
		get_node("/root/LocaleManager").language_changed.connect(_on_language_changed)
		_apply_translation()

func _apply_translation() -> void:
	if not has_node("/root/LocaleManager"): return
	var lm = get_node("/root/LocaleManager")
	
	$BossUI/Control/MarginContainer/VBoxContainer/BossNameLabel.text = lm.t("BOSS_NAME")

func _on_language_changed(_lang: String) -> void:
	_apply_translation()

func _on_trigger_entered(body: Node2D) -> void:
	if is_fight_active:
		return
	if body.is_in_group("player"):
		_begin_intro()

func _begin_intro() -> void:
	is_fight_active = true
	
	# ล็อคกำแพงก่อน (ยังไม่แสดง HP Bar)
	_set_walls_active(true)
	
	# หยุดบอสไม่ให้เคลื่อนไหวระหว่างบทสนทนา
	if boss:
		boss.current_state = Boss.State.PATROL
	
	# ตั้งค่า DialogManager ให้แสดงชื่อบอส
	var dm = get_tree().root.get_node_or_null("DialogManager")
	if dm:
		var lm = get_tree().root.get_node_or_null("LocaleManager")
		if lm:
			dm.npc_name = lm.t("BOSS_NAME")
			var intro_text1 = lm.get_dynamic_text("boss_intro_1")
			var intro_text2 = lm.get_dynamic_text("boss_intro_2")
			if intro_text1:
				intro_dialog = [
					{"speaker": "Player", "text": "..."},
					{"speaker": "Boss", "text": intro_text1},
					{"speaker": "Player", "text": "!"},
					{"speaker": "Boss", "text": intro_text2},
				]
		else:
			dm.npc_name = "THE PURPLE BRUTE"
			
		dm.npc_portrait_emoji = "👹"
		dm.dialog_finished.connect(_on_intro_dialog_finished, CONNECT_ONE_SHOT)
		dm.start_dialog(intro_dialog)
	else:
		# ถ้าไม่มี DialogManager ก็ข้ามไปสู้เลย
		_start_fight()

func _on_intro_dialog_finished() -> void:
	_start_fight()

func _start_fight() -> void:
	# โชว์ HP Bar บอส
	boss_ui_layer.visible = true
	
	# บอสเริ่มโจมตี
	if boss:
		boss.current_state = Boss.State.CHASE

func _on_boss_hp_changed(current_hp: int, _max_hp: int) -> void:
	var tween = create_tween()
	tween.tween_property(hp_bar, "value", current_hp, 0.2).set_trans(Tween.TRANS_CUBIC)

func _on_boss_died() -> void:
	is_fight_active = false
	
	var tween = create_tween()
	tween.tween_property(boss_ui_layer.get_node("Control"), "modulate:a", 0.0, 1.0)
	await tween.finished
	boss_ui_layer.visible = false
	
	_set_walls_active(false)

func _set_walls_active(active: bool) -> void:
	left_wall.get_node("CollisionShape2D").set_deferred("disabled", not active)
	right_wall.get_node("CollisionShape2D").set_deferred("disabled", not active)
