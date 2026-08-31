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
		"description": "Increases movement and dash speed by 20%",
		"equipped": false
	},
	"power_charm": {
		"name": "Unbreakable Strength",
		"description": "Significantly increases sword attack power",
		"equipped": false
	},
	"health_charm": {
		"name": "Heart Container",
		"description": "Increases maximum health",
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
	
	# Translation
	if has_node("/root/LocaleManager"):
		var lm = get_node("/root/LocaleManager")
		lm.language_changed.connect(_on_language_changed)
		_apply_translation()

func _apply_translation() -> void:
	if not has_node("/root/LocaleManager"): return
	var lm = get_node("/root/LocaleManager")
	
	if $Control/Title: $Control/Title.text = lm.t("CHARMS")
	if $Control/Background/EquippedTitle: $Control/Background/EquippedTitle.text = lm.t("EQUIPPED_CHARMS")
	if $Control/Background/BackButton: $Control/Background/BackButton.text = lm.t("BACK")
	
	if charm_name_label.text == "Select a Charm" or charm_name_label.text == "เลือกเครื่องราง":
		charm_name_label.text = lm.t("SELECT_A_CHARM")
		charm_desc_label.text = lm.t("HOVER_CHARM_DESC")
	else:
		# Need to update the currently selected charm
		_update_selected_charm_text()

func _on_language_changed(_lang: String) -> void:
	_apply_translation()


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


var current_selected_charm: String = ""

func _on_charm_selected(charm_id: String) -> void:
	var charm: Dictionary = charms_database[charm_id]
	charm["equipped"] = not charm["equipped"]
	current_selected_charm = charm_id
	_update_selected_charm_text()

func _update_selected_charm_text() -> void:
	if current_selected_charm == "": return
	
	var charm: Dictionary = charms_database[current_selected_charm]
	
	var charm_name = charm["name"]
	var charm_desc = charm["description"]
	var equipped_text = "\n\n[ EQUIPPED ]" if charm["equipped"] else "\n\n[ NOT EQUIPPED ]"
	
	if has_node("/root/LocaleManager"):
		var lm = get_node("/root/LocaleManager")
		if current_selected_charm == "speed_charm":
			charm_name = lm.t("CHARM_SPEED_NAME")
			charm_desc = lm.t("CHARM_SPEED_DESC")
		elif current_selected_charm == "power_charm":
			charm_name = lm.t("CHARM_POWER_NAME")
			charm_desc = lm.t("CHARM_POWER_DESC")
		elif current_selected_charm == "health_charm":
			charm_name = lm.t("CHARM_HEALTH_NAME")
			charm_desc = lm.t("CHARM_HEALTH_DESC")
			
		# Optional: Translate EQUIPPED/NOT EQUIPPED but skip for now to save time
	
	charm_name_label.text = charm_name
	charm_desc_label.text = charm_desc + equipped_text
