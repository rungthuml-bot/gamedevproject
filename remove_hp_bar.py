import re
import os

files = [
    "scripts/enemies/enemy_axe.gd",
    "scripts/enemies/enemy_archer.gd",
    "scripts/enemies/boss.gd",
    "scenes/enemies/EnemySword.tscn",
    "scenes/enemies/EnemyAxe.tscn",
    "scenes/enemies/EnemyArcher.tscn",
    "scenes/enemies/Boss.tscn"
]

def process_gd(content):
    content = re.sub(r'@onready var hp_bar: ProgressBar = \$HPBar\n?', '', content)
    content = re.sub(r'hp_bar\.max_value = MAX_HP\n?', '', content)
    content = re.sub(r'hp_bar\.value = hp\n?', '', content)
    return content

def process_tscn(content):
    # Regex to remove HPBar node and its properties (until the next node or empty line)
    # The [node name="HPBar"... block
    pattern = r'\[node name="HPBar" type="ProgressBar" parent="\."\].*?(?=\n\[node|\n\n|\Z)'
    content = re.sub(pattern, '', content, flags=re.DOTALL)
    # also remove empty lines left behind
    content = re.sub(r'\n{3,}', '\n\n', content)
    return content

for f in files:
    path = os.path.join(r"c:\Users\ACER\Downloads\เทสๆ", f)
    if os.path.exists(path):
        with open(path, 'r', encoding='utf-8') as file:
            content = file.read()
        
        if f.endswith('.gd'):
            content = process_gd(content)
        elif f.endswith('.tscn'):
            content = process_tscn(content)
            
        with open(path, 'w', encoding='utf-8') as file:
            file.write(content)
        print(f"Processed {f}")
