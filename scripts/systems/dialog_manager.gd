extends CanvasLayer

@onready var dialog_box = $Control
@onready var text_label = $Control/MarginContainer/VBoxContainer/DialogText
@onready var left_portrait = $Control/LeftPortrait
@onready var right_portrait = $Control/RightPortrait
@onready var left_name_label = $Control/LeftPortrait/NameLabel
@onready var right_name_label = $Control/RightPortrait/NameLabel
@onready var click_indicator = $Control/ClickIndicator

var dialog_data: Array = []
var current_index: int = 0
var is_dialog_active: bool = false
var is_typing: bool = false

const TYPE_SPEED: float = 0.03
var type_timer: float = 0.0
var target_text: String = ""
var visible_chars: int = 0

signal dialog_finished

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # Run even when paused
	dialog_box.visible = false

func start_dialog(data: Array) -> void:
	if is_dialog_active or data.is_empty():
		return
		
	dialog_data = data
	current_index = 0
	is_dialog_active = true
	
	# Pause the game
	get_tree().paused = true
	dialog_box.visible = true
	
	_show_current_dialog()

func _show_current_dialog() -> void:
	if current_index >= dialog_data.size():
		_end_dialog()
		return
		
	var entry = dialog_data[current_index]
	var speaker = entry.get("speaker", "Unknown")
	target_text = entry.get("text", "")
	
	# Configure UI based on speaker
	if speaker == "Player":
		left_portrait.modulate = Color.WHITE
		right_portrait.modulate = Color.DIM_GRAY
		left_name_label.text = "Mordred"
		right_name_label.text = ""
	else:
		left_portrait.modulate = Color.DIM_GRAY
		right_portrait.modulate = Color.WHITE
		left_name_label.text = ""
		right_name_label.text = speaker
		
	# Start Typewriter Effect
	text_label.visible_characters = 0
	text_label.text = target_text
	visible_chars = 0
	is_typing = true
	type_timer = 0.0
	click_indicator.visible = false

func _process(delta: float) -> void:
	if not is_dialog_active:
		return
		
	if is_typing:
		type_timer += delta
		if type_timer >= TYPE_SPEED:
			type_timer = 0.0
			visible_chars += 1
			text_label.visible_characters = visible_chars
			
			if visible_chars >= target_text.length():
				is_typing = false
				click_indicator.visible = true

func _input(event: InputEvent) -> void:
	if not is_dialog_active:
		return
		
	if event.is_action_pressed("Attack") or (event is InputEventKey and event.pressed and event.physical_keycode == KEY_E):
		# If typing, finish it instantly
		if is_typing:
			is_typing = false
			text_label.visible_characters = target_text.length()
			click_indicator.visible = true
		else:
			# If done typing, move to next dialog
			current_index += 1
			_show_current_dialog()

func _end_dialog() -> void:
	is_dialog_active = false
	dialog_box.visible = false
	get_tree().paused = false
	dialog_finished.emit()
