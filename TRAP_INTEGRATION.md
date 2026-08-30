# Trap System Integration Manifest

## Trap System
```text
TrapBase
├── LavaPit
├── RailSaw
├── Spikes
└── Stalactite
```

## Required Files
To integrate this system into the Main Project, you MUST COPY the following folders:
- `scenes/traps/` (Contains all Trap logic, scripts, and scenes)
- `assets/game/traps/` (Contains all required textures/sprites used by the traps)

## Player Contract
The Trap system expects the player in the Main Project to adhere to the following contract:
- **Group:** `player`
- **Method:** `hit()` (if this method is not found, the trap will fallback to calling `queue_free()` on the body)

## Collision Contract
By default, the traps are configured as `Area2D` nodes using the default collision settings:
- **Trap Collision Layer:** 1
- **Trap Collision Mask:** 1
- The Player node must have a Collision Layer or Mask that allows detection by Layer 1.

## Integration Steps
1. Copy the `scenes/traps/` folder to your main project.
2. Copy the `assets/game/traps/` folder to your main project.
3. Verify that the file structure matches so Resource Paths are maintained (e.g. `res://assets/game/traps/` and `res://scenes/traps/`).
4. Check your Player node in the main project and ensure it is assigned to the `"player"` group.
5. Check your Player script and ensure it has a `hit()` method to handle damage/death.
6. Check your Player's Collision Layer/Mask to ensure it can interact with Layer 1.
7. Instance any trap scene into your main game level.
8. Test the integration by having the player walk into the trap.
