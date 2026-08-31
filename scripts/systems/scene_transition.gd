extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect
var is_transitioning: bool = false
var target_spawn_id: String = ""

func _ready() -> void:
	# ตั้งค่าเริ่มต้นให้จอมืดโปร่งแสงมองไม่เห็น และไม่ขัดขวางการกดปุ่ม
	color_rect.modulate.a = 0.0
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE


# ฟังก์ชันสลับฉากแบบ Fade Out -> เปลี่ยนฉาก -> Fade In
func change_scene(target_path: String, fade_duration: float = 0.5, spawn_id: String = "") -> void:
	if is_transitioning:
		return
	is_transitioning = true
	target_spawn_id = spawn_id
	
	# บล็อกการกดปุ่มระหว่างเปลี่ยนฉาก
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# 1. Fade Out (จอดำค่อยๆ สว่างขึ้นมาทับ)
	var tween_out := create_tween()
	tween_out.tween_property(color_rect, "modulate:a", 1.0, fade_duration)
	await tween_out.finished
	
	# 2. เปลี่ยนฉาก
	get_tree().change_scene_to_file(target_path)
	
	# 3. Fade In (จอดำค่อยๆ จางหายไป)
	var tween_in := create_tween()
	tween_in.tween_property(color_rect, "modulate:a", 0.0, fade_duration)
	await tween_in.finished
	
	# คืนค่าให้คลิกปุ่มต่างๆ ได้ตามปกติ
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	is_transitioning = false
