extends Node

var music_player: AudioStreamPlayer
var ui_player: AudioStreamPlayer
var ui_hover_player: AudioStreamPlayer
var transition_player: AudioStreamPlayer
var ui_click_sound: AudioStream = preload("res://assets/audio/bgm/universfield-computer-mouse-click-352734.mp3")
var ui_hover_sound: AudioStream = preload("res://assets/audio/bgm/666herohero-click-21156.mp3")
var transition_impact_sound: AudioStream = preload("res://assets/audio/bgm/lordsonny-cinematic-boom-171285.mp3")

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	
	ui_player = AudioStreamPlayer.new()
	# Set a reasonable volume for UI clicks so they aren't overpowering
	ui_player.volume_db = -5.0 
	add_child(ui_player)
	
	ui_hover_player = AudioStreamPlayer.new()
	# Hover sounds should be quieter than click sounds
	ui_hover_player.volume_db = -12.0
	add_child(ui_hover_player)
	
	transition_player = AudioStreamPlayer.new()
	# Transition impact needs volume but shouldn't overpower everything
	transition_player.volume_db = -2.0
	add_child(transition_player)
	
	# Connect to all future buttons added to the tree
	get_tree().node_added.connect(_on_node_added)
	
	# Connect to all existing buttons already in the tree
	_connect_buttons(get_tree().root)

func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		if not node.pressed.is_connected(play_ui_click):
			node.pressed.connect(play_ui_click)
		if not node.mouse_entered.is_connected(play_ui_hover):
			node.mouse_entered.connect(play_ui_hover)

func _connect_buttons(node: Node) -> void:
	if node is BaseButton:
		if not node.pressed.is_connected(play_ui_click):
			node.pressed.connect(play_ui_click)
		if not node.mouse_entered.is_connected(play_ui_hover):
			node.mouse_entered.connect(play_ui_hover)
	
	for child in node.get_children():
		_connect_buttons(child)

func play_music(stream: AudioStream) -> void:
	if music_player.stream == stream and music_player.playing:
		return

	music_player.stream = stream
	music_player.play()

func stop_music() -> void:
	music_player.stop()

func play_ui_click() -> void:
	ui_player.stream = ui_click_sound
	ui_player.play()

func play_ui_hover() -> void:
	ui_hover_player.stream = ui_hover_sound
	ui_hover_player.play()

func play_transition_impact() -> void:
	transition_player.stream = transition_impact_sound
	transition_player.play()
