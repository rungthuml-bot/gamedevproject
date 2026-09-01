extends Node

# =========================================================
# LocaleManager - Handles translation and language switching
# =========================================================

signal language_changed(new_lang: String)

var current_lang: String = "en"

# Dictionary of translations
var translations: Dictionary = {
	"en": {
		# Title & Main Menu
		"PRESS_ANY_BUTTON": "- PRESS ANY BUTTON -",
		"START_GAME": "START GAME",
		"SETTING": "SETTING",
		"CREDIT": "CREDIT",
		"EXIT_GAME": "EXIT GAME",
		"PROTOTYPE_VERSION": "Prototype v0.1",
		
		# Save Select
		"SELECT_PROFILE": "SELECT PROFILE",
		"NEW_GAME": "NEW GAME",
		"CONTINUE": "CONTINUE",
		"DELETE": "DELETE",
		"BACK": "BACK",
		
		# Pause Menu
		"PAUSED": "PAUSED",
		"RESUME": "RESUME",
		"SAVE_GAME": "SAVE GAME",
		"MAIN_MENU": "MAIN MENU",
		
		# Game Over
		"YOU_DIED": "YOU DIED",
		"RETRY": "RETRY",
		
		# Settings
		"SETTINGS_TITLE": "SETTINGS",
		"AUDIO": "AUDIO",
		"MASTER_VOLUME": "Master Volume",
		"CONTROLS": "CONTROLS (Click to rebind)",
		"MOVE_LEFT": "Move Left",
		"MOVE_RIGHT": "Move Right",
		"JUMP": "Jump",
		"LIGHT_ATTACK": "Light Attack",
		"HEAVY_ATTACK": "Heavy Attack",
		"DASH": "Dash",
		"LANGUAGE": "Language",
		
		# HUD & In-game
		"POTIONS": "Potions: ",
		"TALK": "[T] TALK",
		"NEXT": "▼ NEXT",
		
		# Equipment
		"CHARMS": "CHARMS",
		"EQUIPPED_CHARMS": "EQUIPPED CHARMS: ",
		"SELECT_A_CHARM": "Select a Charm",
		"HOVER_CHARM_DESC": "Hover or select a charm from your inventory to view its details and properties here.",
		
		# Charms
		"CHARM_SPEED_NAME": "Wayward Compass",
		"CHARM_SPEED_DESC": "Increases movement and dash speed by 20%",
		"CHARM_POWER_NAME": "Unbreakable Strength",
		"CHARM_POWER_DESC": "Significantly increases sword attack power",
		"CHARM_HEALTH_NAME": "Heart Container",
		"CHARM_HEALTH_DESC": "Increases maximum health",
		
		# Boss
		"BOSS_NAME": "THE PURPLE BRUTE",
		
		# Credits
		"CREDITS_TITLE": "CREDITS",
		"GAME_TITLE": "Mordred: Path of the Tolerant",
		"TEAM_MEMBERS": "TEAM MEMBERS",
		"MEMBER_1": "Member 1",
		"MEMBER_2": "Member 2",
		"MEMBER_3": "Member 3",
		"GAME_DESIGN": "Game Design: Member 1",
		"PROGRAMMING": "Programming: Member 2",
		"ART_AUDIO": "Art & Audio: Member 3"
	},
	"th": {
		# Title & Main Menu
		"PRESS_ANY_BUTTON": "- กดปุ่มใดก็ได้ -",
		"START_GAME": "เริ่มเกม",
		"SETTING": "ตั้งค่า",
		"CREDIT": "ผู้จัดทำ",
		"EXIT_GAME": "ออกเกม",
		"PROTOTYPE_VERSION": "รุ่นทดสอบ v0.1",
		
		# Save Select
		"SELECT_PROFILE": "เลือกโปรไฟล์",
		"NEW_GAME": "เริ่มเกมใหม่",
		"CONTINUE": "เล่นต่อ",
		"DELETE": "ลบ",
		"BACK": "กลับ",
		
		# Pause Menu
		"PAUSED": "หยุดชั่วคราว",
		"RESUME": "เล่นต่อ",
		"SAVE_GAME": "บันทึกเกม",
		"MAIN_MENU": "เมนูหลัก",
		
		# Game Over
		"YOU_DIED": "คุณตายแล้ว",
		"RETRY": "ลองใหม่",
		
		# Settings
		"SETTINGS_TITLE": "ตั้งค่า",
		"AUDIO": "เสียง",
		"MASTER_VOLUME": "ความดังเสียงหลัก",
		"CONTROLS": "การควบคุม (คลิกเพื่อเปลี่ยน)",
		"MOVE_LEFT": "เดินซ้าย",
		"MOVE_RIGHT": "เดินขวา",
		"JUMP": "กระโดด",
		"LIGHT_ATTACK": "โจมตีเบา",
		"HEAVY_ATTACK": "โจมตีหนัก",
		"DASH": "พุ่งตัว",
		"LANGUAGE": "ภาษา",
		
		# HUD & In-game
		"POTIONS": "ขวดยา: ",
		"TALK": "[T] พูดคุย",
		"NEXT": "▼ ถัดไป",
		
		# Equipment
		"CHARMS": "เครื่องราง",
		"EQUIPPED_CHARMS": "เครื่องรางที่สวมใส่: ",
		"SELECT_A_CHARM": "เลือกเครื่องราง",
		"HOVER_CHARM_DESC": "ชี้หรือเลือกเครื่องรางจากช่องเก็บของเพื่อดูรายละเอียดและคุณสมบัติที่นี่",
		
		# Charms
		"CHARM_SPEED_NAME": "เข็มทิศพเนจร",
		"CHARM_SPEED_DESC": "เพิ่มความเร็วการเดินและพุ่งตัว 20%",
		"CHARM_POWER_NAME": "ความแข็งแกร่งไร้เทียมทาน",
		"CHARM_POWER_DESC": "เพิ่มพลังโจมตีของดาบอย่างมาก",
		"CHARM_HEALTH_NAME": "ชิ้นส่วนหัวใจ",
		"CHARM_HEALTH_DESC": "เพิ่มพลังชีวิตสูงสุด",
		
		# Boss
		"BOSS_NAME": "ยักษ์ม่วงบ้าคลั่ง",
		
		# Credits
		"CREDITS_TITLE": "ผู้จัดทำ",
		"GAME_TITLE": "Mordred: เส้นทางแห่งความอดทน",
		"TEAM_MEMBERS": "สมาชิกในทีม",
		"MEMBER_1": "สมาชิกคนที่ 1",
		"MEMBER_2": "สมาชิกคนที่ 2",
		"MEMBER_3": "สมาชิกคนที่ 3",
		"GAME_DESIGN": "ออกแบบเกม: สมาชิกคนที่ 1",
		"PROGRAMMING": "เขียนโปรแกรม: สมาชิกคนที่ 2",
		"ART_AUDIO": "ศิลป์และเสียง: สมาชิกคนที่ 3"
	}
}

# ---------------------------------------------------------
# Dynamic Text (Dialogs & Story)
# ---------------------------------------------------------

var dynamic_text: Dictionary = {
	"en": {
		"story_intro": [
			"The realm of Eldoria once thrived in peace...",
			"But dark forces have awakened from the Abyss.",
			"Only one knight remains to stand against the tide...",
			"Mordred, the Tolerant."
		],
		"npc_greeting": [
			{"speaker": "Stranger", "text": "Whoa there! You look a bit lost."},
			{"speaker": "Player", "text": "Where am I? What is this place?"},
			{"speaker": "Stranger", "text": "This is the edge of the forgotten ruins. Danger lies ahead."},
			{"speaker": "Stranger", "text": "Use [A]/[D] or Left/Right arrows to move. Press [Space] to jump."},
			{"speaker": "Stranger", "text": "Press [J] for a light attack and [K] for a heavy attack."},
			{"speaker": "Stranger", "text": "And don't forget to use [Shift] to dash through enemies!"},
			{"speaker": "Player", "text": "Got it. Thanks."}
		],
		"princess_greeting": [
			{"speaker": "Princess", "text": "You... you actually defeated that monstrosity. I thought I would perish in this abyss."},
			{"speaker": "Mordred", "text": "It is finally over. You are safe now, Your Highness."},
			{"speaker": "Princess", "text": "Your armor is battered, and you bleed for my sake... Who are you, brave knight?"},
			{"speaker": "Mordred", "text": "I am Mordred. And I have merely fulfilled my oath."},
			{"speaker": "Princess", "text": "Mordred... I shall never forget that name. Let us return home."}
		],
		"boss_intro_1": "You dare challenge me, weakling?",
		"boss_intro_2": "I will crush you to dust!"
	},
	"th": {
		"story_intro": [
			"ดินแดนเอลดอเรียเคยสงบสุขร่มเย็น...",
			"แต่พลังมืดได้ตื่นขึ้นจากขุมนรก",
			"มีเพียงอัศวินคนเดียวที่ยังคงยืนหยัดต้านทาน...",
			"มอร์เดรด ผู้มีความอดทน"
		],
		"npc_greeting": [
			{"speaker": "ชายแปลกหน้า", "text": "ช้าก่อน! ดูเหมือนเจ้าจะหลงทางนะ"},
			{"speaker": "Player", "text": "ข้าอยู่ที่ไหน? ที่นี่คือที่ไหนกัน?"},
			{"speaker": "ชายแปลกหน้า", "text": "ที่นี่คือขอบเขตรอยต่อของซากปรักหักพังที่ถูกลืม ข้างหน้ามีแต่อันตราย"},
			{"speaker": "ชายแปลกหน้า", "text": "ใช้ปุ่ม [A]/[D] หรือลูกศร ซ้าย/ขวา เพื่อเดิน และกด [Space] เพื่อกระโดด"},
			{"speaker": "ชายแปลกหน้า", "text": "กด [J] เพื่อโจมตีเบา และ [K] เพื่อโจมตีหนัก"},
			{"speaker": "ชายแปลกหน้า", "text": "อ้อ... อย่าลืมกด [Shift] เพื่อพุ่งตัว (Dash) หลบหลีกศัตรูล่ะ!"},
			{"speaker": "Player", "text": "เข้าใจล่ะ ขอบใจมาก"}
		],
		"princess_greeting": [
			{"speaker": "เจ้าหญิง", "text": "ท่าน... ท่านปราบเจ้าอสูรกายนั่นได้จริงๆ ข้าคิดว่าชีวิตข้าคงต้องจบสิ้นในขุมนรกนี้เสียแล้ว"},
			{"speaker": "Mordred", "text": "ทุกอย่างจบลงแล้วพะยะค่ะองค์หญิง บัดนี้ท่านปลอดภัยแล้ว"},
			{"speaker": "เจ้าหญิง", "text": "ชุดเกราะของท่านเต็มไปด้วยรอยแตกร้าว ท่านหลั่งเลือดเพื่อข้า... ท่านคือใครกัน อัศวินผู้กล้า?"},
			{"speaker": "Mordred", "text": "ข้าคือ มอร์เดรด... และข้าเพียงแค่ทำตามคำสัตย์สาบานเท่านั้น"},
			{"speaker": "เจ้าหญิง", "text": "มอร์เดรด... ข้าจะไม่มีวันลืมชื่อนี้เลย เรากลับบ้านกันเถอะ"}
		],
		"boss_intro_1": "เจ้ากล้าท้าทายข้ารึ เจ้าพวกอ่อนหัด?",
		"boss_intro_2": "ข้าจะบดขยี้เจ้าให้เป็นผุยผง!"
	}
}

func _ready() -> void:
	pass

func set_language(lang: String) -> void:
	if translations.has(lang):
		current_lang = lang
		language_changed.emit(lang)

func t(key: String) -> String:
	if translations[current_lang].has(key):
		return translations[current_lang][key]
	return key

func get_dynamic_text(category: String) -> Variant:
	if dynamic_text[current_lang].has(category):
		return dynamic_text[current_lang][category]
	return null
