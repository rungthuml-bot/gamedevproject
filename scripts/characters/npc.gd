extends StaticBody2D

@export var dialog: Array = [
	{"speaker": "NPC", "text": "Greetings traveler! I don't have much to say right now..."},
	{"speaker": "Player", "text": "That's fine, thanks."},
	{"speaker": "NPC", "text": "Good luck on your journey!"}
]
@export var npc_name: String = "Stranger"
@export var portrait_emoji: String = "🧙"

@onready var prompt_label: Label = $PromptLabel
@onready var interaction_area: Area2D = $InteractionArea

var player_nearby: bool = false

func _ready() -> void:
	prompt_label.visible = false
	interaction_area.body_entered.connect(_on_interaction_area_body_entered)
	interaction_area.body_exited.connect(_on_interaction_area_body_exited)
	
	if has_node("/root/LocaleManager"):
		get_node("/root/LocaleManager").language_changed.connect(_on_language_changed)
		_apply_translation()

func _apply_translation() -> void:
	if not has_node("/root/LocaleManager"): return
	var lm = get_node("/root/LocaleManager")
	prompt_label.text = lm.t("TALK")

func _on_language_changed(_lang: String) -> void:
	_apply_translation()

func _unhandled_input(event: InputEvent) -> void:
	if player_nearby and event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_T:
			_talk()

func _talk() -> void:
	var dm = get_tree().root.get_node_or_null("DialogManager")
	if dm == null:
		push_error("DialogManager autoload not found!")
		return
	if dm.is_dialog_active:
		return
	
	# Pass NPC name and portrait into DialogManager
	if has_node("/root/LocaleManager"):
		var lm = get_node("/root/LocaleManager")
		var greeting = lm.get_dynamic_text("npc_greeting")
		if greeting:
			dialog = [
				{"speaker": "NPC", "text": greeting},
			]
			
	dm.npc_name = npc_name
	dm.npc_portrait_emoji = portrait_emoji
	dm.start_dialog(dialog)

func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = true
		prompt_label.visible = true

func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = false
		prompt_label.visible = false
