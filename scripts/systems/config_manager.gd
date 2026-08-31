extends Node

# =========================================================
# ConfigManager – Saves and loads user settings
# =========================================================

const SETTINGS_PATH := "user://settings.cfg"

var config := ConfigFile.new()

# Default values
var master_volume: float = 100.0

# Keybind defaults  (action_name -> readable_key_name)
var default_bindings: Dictionary = {
	"move_left": "A",
	"move_right": "D",
	"jump": "SPACE",
	"Attack": "LMB",
	"attack_heavy": "RMB",
	"dash": "C",
}

var language: String = "en"

func _ready() -> void:
	load_settings()
	apply_volume()
	apply_keybinds()
	
	# Delay applying language slightly so LocaleManager is ready
	call_deferred("apply_language")

func apply_language() -> void:
	if has_node("/root/LocaleManager"):
		var lm = get_node("/root/LocaleManager")
		lm.set_language(language)

# =========================================================
# SAVE / LOAD
# =========================================================

func save_settings() -> void:
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("general", "language", language)
	
	# Save keybinds
	for action_name in default_bindings.keys():
		var events = InputMap.action_get_events(action_name)
		if events.size() > 0:
			var event = events[0]
			config.set_value("keybinds", action_name, var_to_str(event))
	
	config.save(SETTINGS_PATH)

func load_settings() -> void:
	var err = config.load(SETTINGS_PATH)
	if err != OK:
		# No settings file yet, use defaults
		return
	
	# Load volume
	master_volume = config.get_value("audio", "master_volume", 100.0)
	
	# Load language
	language = config.get_value("general", "language", "en")

# =========================================================
# VOLUME
# =========================================================

func set_master_volume(value: float) -> void:
	master_volume = value
	apply_volume()
	save_settings()

func set_language(lang: String) -> void:
	language = lang
	apply_language()
	save_settings()

func apply_volume() -> void:
	var bus_index = AudioServer.get_bus_index("Master")
	if master_volume <= 0.0:
		AudioServer.set_bus_mute(bus_index, true)
	else:
		AudioServer.set_bus_mute(bus_index, false)
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(master_volume / 100.0))

# =========================================================
# KEYBINDS
# =========================================================

func apply_keybinds() -> void:
	# Load saved keybinds from config and apply them to InputMap
	for action_name in default_bindings.keys():
		if config.has_section_key("keybinds", action_name):
			var event_str = config.get_value("keybinds", action_name)
			var event = str_to_var(event_str)
			if event is InputEvent:
				InputMap.action_erase_events(action_name)
				InputMap.action_add_event(action_name, event)

func rebind_action(action_name: String, new_event: InputEvent) -> void:
	InputMap.action_erase_events(action_name)
	InputMap.action_add_event(action_name, new_event)
	save_settings()

func get_action_key_name(action_name: String) -> String:
	var events = InputMap.action_get_events(action_name)
	if events.size() == 0:
		return "???"
	
	var event = events[0]
	
	if event is InputEventKey:
		var keycode = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		if keycode == KEY_SPACE:
			return "SPACE"
		elif keycode == KEY_SHIFT:
			return "SHIFT"
		elif keycode == KEY_CTRL:
			return "CTRL"
		elif keycode == KEY_ALT:
			return "ALT"
		elif keycode == KEY_TAB:
			return "TAB"
		elif keycode == KEY_ESCAPE:
			return "ESC"
		elif keycode == KEY_ENTER:
			return "ENTER"
		elif keycode == KEY_BACKSPACE:
			return "BACKSPACE"
		else:
			return OS.get_keycode_string(keycode).to_upper()
	
	elif event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				return "LMB"
			MOUSE_BUTTON_RIGHT:
				return "RMB"
			MOUSE_BUTTON_MIDDLE:
				return "MMB"
			_:
				return "MOUSE " + str(event.button_index)
	
	elif event is InputEventJoypadButton:
		return "PAD " + str(event.button_index)
	
	return "???"

func reset_to_defaults() -> void:
	# Reset all keybinds to the project defaults
	# Reload from ProjectSettings
	InputMap.load_from_project_settings()
	save_settings()
