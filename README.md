# NATURE SHIFT: The Shattered Cycle

Godot 4.7 (GDScript, GL Compatibility). Phase 1: combat prototype.

- **3D third-person, mouse-aimed** (default, `scenes/main_3d.tscn`)
- 2D top-down version kept for reference (`scenes/main.tscn`; run with `godot --path . scenes/main.tscn`)

## Run

```bash
godot --path . # or open the folder in the Godot editor and press F5
```

| Input | Action |
|---|---|
| WASD / arrows | Move |
| Mouse | Look / aim at the crosshair (ESC frees the mouse, click recaptures) |
| LMB (or J / 1) | Lightning Bolt (0.55s cooldown) |
| RMB (or K / 2) | Water Pool (4s cooldown, range 330) |
| Space / Shift | Dash (brief invulnerability, 0.8s cooldown) |
| R | Restart encounter |

## The combo (prototype rule, not a spreadsheet fact)

1. Water Pool makes a pool that applies **Wet** (3s, refreshed while inside) to anyone standing in it, you included.
2. A Lightning Bolt that **passes through a pool**, or **hits a Wet target standing in a pool**, electrifies that pool: every Wet occupant takes 40 damage and is stunned 1.2s. The pool is then spent.
3. A bolt on any Wet target deals x1.5 damage even outside a pool (no shock).

Counterplay: the enemy must actually be inside the pool; the bolt can miss; the pool expires after 6s; **you get shocked too** if you stand in it; a stunned enemy's swing is cancelled; a dash through the enemy's swing dodges it.

## Test

```bash
godot --headless --path . -s tests/run_tests_3d.gd   # 3D, 30 checks
godot --headless --path . -s tests/run_tests.gd      # 2D, 39 checks
```

Checks cover cooldowns, Wet application, every branch of the Water+Lightning rule, enemy interrupt/dodge, and a main-scene smoke build.

## Layout

```
data/catalog/catalog.json   all 19 spreadsheet sheets, raw (regenerate: python3 tools/export_catalog.py)
data/abilities/3d/*.tres    AbilityData for the 3D game (metres); data/abilities/*.tres = 2D (pixels)
scripts/abilities/          AbilityData, AbilityCaster (slots+cooldowns), effect registry, effects
scripts/core/               Health, StatusController, Statuses, InputSetup
scripts/actors3d/           3D: Combatant3D, Player3D (camera rig), Enemy3D, Bolt3D, GroundZone3D, Arena3D
scripts/actors/             2D versions of the same
scripts/ui/hud.gd           HUD (code-drawn)
scripts/main.gd             encounter setup + restart
tests/run_tests.gd          headless rule tests
```

See `docs/DESIGN.md` for decisions, risks and the roadmap.
