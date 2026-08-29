# DEVELOPMENT_BASELINE

This document captures the precise state of the project following the integration, cleanup, and restructuring phases. It serves as the baseline for all future development.

## 1. Project Status

- **Branch:** เทสๆ
- **Current Commit:** 636cb08 (chore: remove confirmed duplicate legacy files)
- **Working Tree:** CLEAN
- **Main Scene:** `uid://6larbte3yono` (`res://scenes/levels/Level_Test.tscn`)
- **Godot Version:** 4.7 (GL Compatibility)

## 2. Project Structure

Current directory structure:
- `assets/` - Contains raw and imported assets (images, sprites, tilesets, PSDs, audio, etc.) grouped logically.
- `scenes/` - Contains all `.tscn` files.
  - `characters/` - Main player and character-related scenes.
  - `enemies/` - Enemy and dummy target scenes.
  - `items/` - Interactable items like potions.
  - `levels/` - Playable and test levels/maps.
  - `story/` - Story introduction and narrative scenes.
  - `systems/` - Global systems, transitions, and save points.
  - `traps/` - Environmental hazard scenes.
  - `ui/` - User interface elements and UI test environments.
- `scripts/` - Contains all `.gd` scripts, following the exact same directory layout as `scenes/` to pair behaviors with visual nodes.
- `project.godot` - Core engine configuration file.

## 3. Main Game Architecture

**Entry Point:** `project.godot` -> `Level_Test.tscn`

**Level_Test.tscn Dependencies:**
- **Map:** `scenes/levels/level_1.tscn`
- **Player:** `scenes/characters/Mordred.tscn`
- **Enemy Test:** `scenes/enemies/enemy_test.tscn`

*Note: UI and Systems are largely decoupled from the main scene currently. UI integration is pending.*

## 4. Player

- **Main Player Scene:** `scenes/characters/Mordred.tscn`
- **Main Player Script:** `scripts/characters/mordred.gd`
- **Player Dependencies:** Utilizes `assets/Mordred_Knight/` textures (Idle, Run, Jump, Attacks, etc.).
- **Player Input:** Relies on global input actions (`move_left`, `move_right`, `jump`, `attack_light`, `attack_heavy`, `dash`, etc.).
- **Player Combat:** IMPLEMENTED (Handles animations, hitboxes, and gravity mechanics).

## 5. Enemy

- **Dummy:** 
  - Scene: `scenes/enemies/Dummy.tscn`
  - Script: `scripts/enemies/dummy.gd`
  - Current Functionality: IMPLEMENTED (Receives damage and displays numbers).
- **Enemy:** 
  - Scene: `scenes/enemies/Enemy.tscn`
  - Script: `scripts/enemies/enemy.gd`
  - Current Functionality: IMPLEMENTED (Basic AI/Stats).
- **Enemy Test:**
  - Scene: `scenes/enemies/enemy_test.tscn`
  - Script: `scripts/enemies/enemy_test.gd`

## 6. Traps

- **trap_lava_pit:** `scenes/traps/trap_lava_pit.tscn` / `scripts/traps/trap_lava_pit.gd`
- **trap_rail_saw:** `scenes/traps/trap_rail_saw.tscn` / `scripts/traps/trap_rail_saw.gd`
- **trap_spikes:** `scenes/traps/trap_spikes.tscn` / `scripts/traps/trap_spikes.gd`
- **trap_stalactite:** `scenes/traps/trap_stalactite.tscn` / `scripts/traps/trap_stalactite.gd`

**Known Issue (PRE-EXISTING MISSING ASSETS):**
- `res://trap_stalactite/PNG/Tiles_lava/lava_tile11.png`
- `res://trap_stalactite/PNG/Tiles_lava/lava_tile12.png`
- `res://PNG/trap_saw.png`
- `res://traps/6 Traps/4.png`
- `res://trap_stalactite/PNG/Details/lava/lava_drop1_1.png` to `lava_drop1_4.png`

## 7. UI

**Main Game UI (NOT INTEGRATED):**
- `HUD` (`scenes/ui/HUD.tscn`)
- `MainMenu` (`scenes/ui/MainMenu.tscn`)
- `PauseMenu` (`scenes/ui/PauseMenu.tscn`)
- `EquipmentMenu` (`scenes/ui/EquipmentMenu.tscn`)
- `SaveSelectMenu` (`scenes/ui/SaveSelectMenu.tscn`)
- `GameOverMenu` (`scenes/ui/GameOverMenu.tscn`)
- `DamageNumber` (`scenes/ui/DamageNumber.tscn`)

**UI Test (TEST ONLY):**
- `ui_test_main.tscn` (Test environment for UI logic)
- `ui_test_player.tscn` (Test player for UI logic)

## 8. Systems

- **SaveManager:**
  - Autoload: `*uid://dtnjfa2plofur` -> `scripts/systems/SaveManager.gd`
  - Dependencies: Handles save/load I/O operations.
- **SceneTransition:**
  - Autoload: `*uid://um4ro0bix7p4` -> `scenes/systems/SceneTransition.tscn`
  - Script: `scripts/systems/scene_transition.gd`
- **SavePoint:**
  - Scene: `scenes/systems/SavePoint.tscn`
  - Script: `scripts/systems/save_point.gd`

## 9. Story

- **StoryIntro:**
  - Scene: `scenes/story/StoryIntro.tscn`
  - Script: `scripts/story/story_intro.gd`
  - Current integration status: NOT INTEGRATED (Standalone scene available for transition testing).

## 10. Input

Extracted from `project.godot`:
- `Left` (A)
- `Right` (D)
- `Up` (W)
- `Down` (S)
- `Jump` (Space)
- `Attack` (Mouse Left)
- `move_left` (A)
- `move_right` (D)
- `jump` (W, Space)
- `crouch` (S)
- `attack_light` (Mouse Left)
- `attack_heavy` (Mouse Right)
- `dash` (C)

## 11. Known Issues

### PRE-EXISTING
- Trap Missing Assets (Listed in Section 6).
- Map path spaces (`assets/Floor/map 9/...` folder names).

### MIGRATION
- None.

### UNKNOWN
- None.

## 12. Git Branch Policy

- **Main branch:** `main` (Preserved, unmodified state).
- **Development/Test branch:** `เทสๆ` (Integration / Development branch where all current work happens).
- **Original feature branches:** `player`, `map`, `traps`, `ui-item-story` (Kept intact).

## 13. Development Rules

1. Do not modify main unless explicitly instructed.
2. Do not push unless explicitly instructed.
3. Work on the current development branch.
4. Do not restructure folders without a specific reason.
5. Do not delete files without dependency verification.
6. Do not refactor unrelated systems while implementing a feature.
7. Preserve existing gameplay unless the feature requires a change.
8. Test affected systems after every major change.
9. Commit logically after verified changes.
10. Report assumptions and unknowns instead of guessing.

## 14. Feature Development Workflow

REQUEST
   ↓
ANALYZE EXISTING CODE
   ↓
IDENTIFY AFFECTED FILES
   ↓
PLAN
   ↓
IMPLEMENT
   ↓
VERIFY
   ↓
TEST
   ↓
COMMIT
   ↓
REPORT
