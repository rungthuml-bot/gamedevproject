extends Control

# =========================================================
# Node References
# =========================================================

@onready var back_button: Button = $MarginContainer/VBoxContainer/BackButton
@onready var volume_slider: HSlider = $MarginContainer/VBoxContainer/AudioSection/SliderRow/MasterVolumeSlider
@onready var volume_label: Label = $MarginContainer/VBoxContainer/AudioSection/MasterVolumeLabel
@onready var lang_button: Button = $MarginContainer/VBoxContainer/GeneralSection/LangRow/LangKey

# Keybind buttons (will be found dynamically)
var keybind_buttons: Dictionary = {}

# The action currently being rebound (empty string = not rebinding)
var rebinding_action: String = ""
var rebinding_button: Button = null

# Map of action names to display names
const ACTION_DISPLAY_NAMES: Dictionary = {
	"move_left": "Move Left",
	"move_right": "Move Right",
	"jump": "Jump",
	"Attack": "Light Attack",
	"attack_heavy": "Heavy Attack",
	"dash": "Dash",
}

func _ready() -> void:
	# Back button
	if back_button:
		back_button.pressed.connect(_on_back_button_pressed)
	
	# Volume slider
	if volume_slider:
		volume_slider.value = ConfigManager.master_volume
		volume_slider.value_changed.connect(_on_volume_changed)
		_update_volume_label(ConfigManager.master_volume)
		
	# Language Button
	if lang_button:
		lang_button.pressed.connect(_on_lang_button_pressed)
		_update_lang_button_text()
	
	# Find and connect all keybind buttons
	var controls_section = $MarginContainer/VBoxContainer/ControlsSection
	for child in controls_section.get_children():
		if child is HBoxContainer:
			for sub in child.get_children():
				if sub is Button and sub.name.ends_with("Key"):
					var action_name = sub.get_meta("action_name", "")
					if action_name != "":
						keybind_buttons[action_name] = sub
						sub.pressed.connect(_on_keybind_button_pressed.bind(action_name, sub))
						# Update the button text to show current binding
						sub.text = ConfigManager.get_action_key_name(action_name)
	
	# Focus the first keybind button or back button
	if back_button:
		back_button.grab_focus()
		
	# Listen to language changes to update UI
	if has_node("/root/LocaleManager"):
		get_node("/root/LocaleManager").language_changed.connect(_on_language_changed)
	
	# Apply translation
	_apply_translation()

func _apply_translation() -> void:
	if not has_node("/root/LocaleManager"): return
	var lm = get_node("/root/LocaleManager")
	
	$MarginContainer/VBoxContainer/TitleLabel.text = lm.t("SETTINGS_TITLE")
	$MarginContainer/VBoxContainer/GeneralSection/GeneralTitle.text = lm.t("GENERAL")
	$MarginContainer/VBoxContainer/GeneralSection/LangRow/LangAction.text = lm.t("LANGUAGE")
	$MarginContainer/VBoxContainer/AudioSection/AudioSectionTitle.text = lm.t("AUDIO")
	$MarginContainer/VBoxContainer/ControlsSection/ControlsTitle.text = lm.t("CONTROLS")
	
	$MarginContainer/VBoxContainer/ControlsSection/MoveLeftRow/MoveLeftAction.text = lm.t("MOVE_LEFT")
	$MarginContainer/VBoxContainer/ControlsSection/MoveRightRow/MoveRightAction.text = lm.t("MOVE_RIGHT")
	$MarginContainer/VBoxContainer/ControlsSection/JumpRow/JumpAction.text = lm.t("JUMP")
	$MarginContainer/VBoxContainer/ControlsSection/AttackRow/AttackAction.text = lm.t("LIGHT_ATTACK")
	$MarginContainer/VBoxContainer/ControlsSection/HeavyAttackRow/HeavyAttackAction.text = lm.t("HEAVY_ATTACK")
	$MarginContainer/VBoxContainer/ControlsSection/DashRow/DashAction.text = lm.t("DASH")
	
	if back_button:
		back_button.text = lm.t("BACK")
		
	_update_volume_label(ConfigManager.master_volume)

func _on_language_changed(_lang: String) -> void:
	_apply_translation()
	_update_lang_button_text()

# =========================================================
# LANGUAGE
# =========================================================

func _on_lang_button_pressed() -> void:
	var current = ConfigManager.language
	var new_lang = "th" if current == "en" else "en"
	ConfigManager.set_language(new_lang)

func _update_lang_button_text() -> void:
	if lang_button:
		if ConfigManager.language == "th":
			lang_button.text = "ไทย"
		else:
			lang_button.text = "ENGLISH"

# =========================================================
# VOLUME
# =========================================================

func _on_volume_changed(value: float) -> void:
	ConfigManager.set_master_volume(value)
	_update_volume_label(value)

func _update_volume_label(value: float) -> void:
	if volume_label:
		var prefix = "Master Volume: "
		if has_node("/root/LocaleManager"):
			prefix = get_node("/root/LocaleManager").t("MASTER_VOLUME") + ": "
		volume_label.text = prefix + str(int(value)) + "%"

# =========================================================
# KEY REBINDING
# =========================================================

func _on_keybind_button_pressed(action_name: String, button: Button) -> void:
	if rebinding_action != "":
		# Cancel previous rebind
		_cancel_rebind()
	
	rebinding_action = action_name
	rebinding_button = button
	button.text = "PRESS ANY KEY..."
	
	# Change button color to indicate listening state
	button.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))

func _input(event: InputEvent) -> void:
	# Handle ESC to go back (only when not rebinding)
	if rebinding_action == "":
		if event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			if back_button and not back_button.disabled:
				back_button.pressed.emit()
		return
	
	# We are rebinding - wait for a valid input
	if event is InputEventKey and event.pressed and not event.echo:
		# ESC cancels the rebind
		if event.physical_keycode == KEY_ESCAPE or event.keycode == KEY_ESCAPE:
			_cancel_rebind()
			get_viewport().set_input_as_handled()
			return
		
		_apply_rebind(event)
		get_viewport().set_input_as_handled()
	
	elif event is InputEventMouseButton and event.pressed:
		# Don't rebind if it's the same button click that started the rebind
		_apply_rebind(event)
		get_viewport().set_input_as_handled()

func _apply_rebind(event: InputEvent) -> void:
	if rebinding_action == "" or rebinding_button == null:
		return
	
	# Apply the new binding
	ConfigManager.rebind_action(rebinding_action, event)
	
	# Update button text
	rebinding_button.text = ConfigManager.get_action_key_name(rebinding_action)
	rebinding_button.remove_theme_color_override("font_color")
	
	# Reset state
	rebinding_action = ""
	rebinding_button = null

func _cancel_rebind() -> void:
	if rebinding_button != null:
		rebinding_button.text = ConfigManager.get_action_key_name(rebinding_action)
		rebinding_button.remove_theme_color_override("font_color")
	rebinding_action = ""
	rebinding_button = null

# =========================================================
# BACK
# =========================================================

func _on_back_button_pressed() -> void:
	SceneTransition.change_scene("res://scenes/ui/MainMenu.tscn", 0.5)
