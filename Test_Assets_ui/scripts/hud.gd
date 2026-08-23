extends CanvasLayer


# =========================================================
# Node References
# =========================================================

@onready var hp_bar: ProgressBar = $HPBar
@onready var potion_label: Label = $PotionLabel


# =========================================================
# Ready
# =========================================================

func _ready() -> void:

	# ค้นหา Player ในกลุ่ม "player"
	var player := get_tree().get_first_node_in_group("player") as Node

	if player != null:

		# เชื่อมต่อ Signal HP
		if player.has_signal("hp_changed"):

			player.hp_changed.connect(_on_player_hp_changed)
			_on_player_hp_changed(player.get("hp"), player.get("MAX_HP"))

		# เชื่อมต่อ Signal ขวดยา
		if player.has_signal("potion_count_changed"):

			player.potion_count_changed.connect(_on_potion_count_changed)
			_on_potion_count_changed(player.get("potion_count"))

	else:

		print("HUD ERROR: Player not found!")


# =========================================================
# Signal Callbacks
# =========================================================

func _on_player_hp_changed(current_hp: int, max_hp: int) -> void:

	if hp_bar != null:

		hp_bar.max_value = max_hp
		hp_bar.value = current_hp


func _on_potion_count_changed(count: int) -> void:

	if potion_label != null:

		potion_label.text = "Potions: " + str(count)
