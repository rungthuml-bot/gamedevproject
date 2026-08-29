extends Control


# =========================================================
# Node References
# =========================================================

@onready var story_label: Label = $Background/CenterContainer/VBoxContainer/StoryLabel
@onready var author_label: Label = $Background/CenterContainer/VBoxContainer/AuthorLabel

# ฉากที่จะเล่นต่อหลังจากคัตซีนจบ
@export_file("*.tscn") var next_scene_path: String = "res://scenes/Level_Test.tscn"

var tween: Tween
var is_transitioning: bool = false


# =========================================================
# Ready
# =========================================================

func _ready() -> void:

	# ตั้งค่าเริ่มต้นให้ข้อความโปร่งแสงซ่อนอยู่
	story_label.modulate.a = 0.0
	author_label.modulate.a = 0.0
	
	play_story_sequence()


# =========================================================
# Cutscene Sequence (Fade In -> Wait -> Fade Out)
# =========================================================

func play_story_sequence() -> void:

	tween = create_tween()
	
	# 1. แสดงบทกลอนเนื้อเรื่อง (Fade In 2.5 วินาที)
	tween.tween_property(story_label, "modulate:a", 1.0, 2.5)
	
	# 2. แสดงชื่อผู้เขียน (Fade In 1.5 วินาที)
	tween.tween_property(author_label, "modulate:a", 1.0, 1.5)
	
	# 3. ค้างให้ผู้เล่นอ่าน (4.0 วินาที)
	tween.tween_interval(4.0)
	
	# 4. จางหายไปพร้อมกัน (Fade Out 2.0 วินาที)
	tween.tween_property(story_label, "modulate:a", 0.0, 2.0)
	tween.parallel().tween_property(author_label, "modulate:a", 0.0, 2.0)
	
	# 5. จบแล้วเข้าสู่เกมหลัก
	tween.tween_callback(go_to_next_scene)


# =========================================================
# Input Handler (กดข้าม)
# =========================================================

func _unhandled_input(event: InputEvent) -> void:

	# กดปุ่มใดก็ได้ (Space, Enter, Esc, คลิกเมาส์) เพื่อข้ามทันที
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel") or (event is InputEventMouseButton and event.pressed):
		go_to_next_scene()


func go_to_next_scene() -> void:

	if is_transitioning:
		return
		
	is_transitioning = true
	
	if tween and tween.is_running():
		tween.kill()
		
	# เปลี่ยนฉากผ่าน SceneTransition
	SceneTransition.change_scene(next_scene_path)
