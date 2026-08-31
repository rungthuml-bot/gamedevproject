extends Label


# =========================================================
# Settings
# =========================================================

const FLOAT_DISTANCE := 40.0
const DURATION := 0.5


# =========================================================
# Variables
# =========================================================

var start_position := Vector2.ZERO
var elapsed := 0.0


# =========================================================
# Ready
# =========================================================

func _ready() -> void:

	# ตั้งค่า Label
	text = text

	# จัดข้อความให้อยู่ตรงกลาง
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# จำตำแหน่งเริ่มต้น
	start_position = position


# =========================================================
# Process
# =========================================================

func _process(delta: float) -> void:

	elapsed += delta

	# คำนวณความคืบหน้า
	var progress := elapsed / DURATION

	# ลอยขึ้น
	position.y = start_position.y - (FLOAT_DISTANCE * progress)

	# ค่อย ๆ จาง
	modulate.a = clamp(1.0 - progress, 0.0, 1.0)

	# ครบเวลาแล้วลบตัวเอง
	if elapsed >= DURATION:
		queue_free()
