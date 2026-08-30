extends CanvasLayer


# =========================================================
# Node References
# =========================================================

@onready var control: Control = $Control
@onready var inventory_grid: GridContainer = $Control/Background/InventoryGrid
@onready var charm_name_label: Label = $Control/Background/InfoPanel/CharmName
@onready var charm_desc_label: Label = $Control/Background/InfoPanel/CharmDescription


# =========================================================
# Charms Database
# =========================================================

var charms_database: Dictionary = {
	"speed_charm": {
		"name": "Wayward Compass",
		"description": "เพิ่มความเร็วการเคลื่อนที่และการพุ่งหลบ 20%",
		"equipped": false
	},
	"power_charm": {
		"name": "Unbreakable Strength",
		"description": "เพิ่มพลังการโจมตีฟันดาบแรงขึ้นอย่างมาก",
		"equipped": false
	},
	"health_charm": {
		"name": "Heart Container",
		"description": "เพิ่มพลังชีวิตสูงสุดของตัวละคร",
		"equipped": false
	}
}

var is_menu_open: bool = false


# =========================================================
# Ready & Toggle Menu Logic
# =========================================================

func _ready() -> void:

	process_mode = Node.PROCESS_MODE_ALWAYS
	control.hide()
	setup_charm_buttons()


func _unhandled_input(event: InputEvent) -> void:

	# กดปุ่ม E เพื่อ เปิด/ปิด หน้าต่างเครื่องราง
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E:
			toggle_menu()


func toggle_menu() -> void:

	is_menu_open = not is_menu_open
	control.visible = is_menu_open
	
	# หยุดการทำงานของเกมชั่วขณะเมื่อเปิดเมนู
	get_tree().paused = is_menu_open


# =========================================================
# Charm Selection Systems
# =========================================================

func setup_charm_buttons() -> void:

	for charm_id in charms_database.keys():
		var charm_info: Dictionary = charms_database[charm_id]
		var btn := Button.new()
		
		btn.custom_minimum_size = Vector2(64, 64)
		btn.text = charm_info["name"].left(3)
		
		btn.pressed.connect(func(): _on_charm_selected(charm_id))
		
		inventory_grid.add_child(btn)


func _on_charm_selected(charm_id: String) -> void:

	var charm: Dictionary = charms_database[charm_id]
	charm["equipped"] = not charm["equipped"]
	
	var status_text := "\n\n[ EQUIPPED ]" if charm["equipped"] else "\n\n[ NOT EQUIPPED ]"
	charm_name_label.text = charm["name"]
	charm_desc_label.text = charm["description"] + status_text
