extends StaticBody2D

@export var dialog: Array = [
	{"speaker": "NPC", "text": "สวัสดีนักเดินทาง! ยังไม่มีอะไรจะบอกมากนักตอนนี้..."},
	{"speaker": "Player", "text": "ไม่เป็นไร ขอบคุณนะ"},
	{"speaker": "NPC", "text": "โชคดีในการเดินทางนะ!"}
]
@export var npc_name: String = "คนแปลกหน้า"
@export var portrait_emoji: String = "🧙"

@onready var prompt_label: Label = $PromptLabel
@onready var interaction_area: Area2D = $InteractionArea

var player_nearby: bool = false

func _ready() -> void:
	prompt_label.visible = false
	interaction_area.body_entered.connect(_on_interaction_area_body_entered)
	interaction_area.body_exited.connect(_on_interaction_area_body_exited)

func _unhandled_input(_event: InputEvent) -> void:
	pass

func take_damage(_amount: int) -> void:
	# โดนโจมตีแทนที่จะเจ็บ ให้เปิดบทสนทนาแทน
	_talk()

func _talk() -> void:
	var dm = get_tree().root.get_node_or_null("DialogManager")
	if dm == null:
		push_error("DialogManager autoload not found!")
		return
	if dm.is_dialog_active:
		return
	
	# Pass NPC name and portrait into DialogManager
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
