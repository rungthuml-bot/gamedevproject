extends "res://scripts/characters/npc.gd"

func _ready() -> void:
    npc_name = "Princess"
    portrait_emoji = "👸"
    dialog = [
        {"speaker": "Princess", "text": "Oh, brave knight! You saved me!"},
        {"speaker": "Player", "text": "It was my duty, your highness."}
    ]
    
    # เปลี่ยนสีของ NPC จำลองนี้ให้เป็นสีชมพู เพื่อให้แยกออกชั่วคราว
    if anim:
        anim.modulate = Color(1.0, 0.6, 0.8)
    
    super._ready()
