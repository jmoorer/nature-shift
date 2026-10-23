# Design notes

## Source of truth: the spreadsheet
`Nature Transformations.xlsx` is exported unchanged to `data/catalog/catalog.json` (sheets: Nature Chart, Combined Natures, one per combined nature, Sources & Notes). It is **reference data only**; nothing loads it at runtime yet.

What the spreadsheet states: five-nature cycle Fire > Wind > Lightning > Earth > Water > Fire; Yin/Yang as non-elemental; combined natures with component natures and a certainty column; per-technique rows with a verification status (many are "title only").

What it does **not** state: any Water + Lightning interaction. That is a prototype decision. Both playable abilities are `source = "proposed"` and only point at their element row (`catalog_ref`). When a real spreadsheet technique is implemented, its `AbilityData` gets `source = "spreadsheet"` and a precise `catalog_ref`.

IP note: the catalog is third-party series material (Narutopedia-sourced). Fine for a private prototype; before any release, gameplay names/lore need to be original. Abilities already use their own ids and names, so this is a data rename, not a code change.

## Decisions (mine, not agreed upfront)
- **Godot 4, GDScript.** Started 2D top-down for the fastest playable loop; after playtesting the user chose **3D third-person, mouse-aimed** (camera style was their pick). 3D is now the default scene.
- **Logic/presentation split** so a 3D port is cheap: Health, StatusController, AbilityData/Caster/effects and the reaction rules are engine-view-agnostic; movement, aiming, drawing and the HUD are the 2D-specific parts.
- **No physics engine.** Hits, pools and bounds are distance checks against circles. Deterministic and headless-testable; swap for physics bodies/areas if/when shapes get complex.
- **Scenes built in code**, one tiny `main.tscn`. Less editor-friendly, far less brittle to hand-author. Revisit when art arrives.
- **Placeholder visuals** drawn with `_draw()`; no imported assets.
- **Input actions registered in code** (`InputSetup`) instead of project.godot.
- Water+Lightning numbers live in the `.tres` files (`params`), not code. The reaction logic itself (wet bonus, electrify) is still in `Bolt`; it should move to a rules table once a second reaction exists.

- **3D port reuses** Health, StatusController, AbilityData, AbilityCaster and the effect registry (dispatches on `caster is Node3D`). Bolt/GroundZone/Combatant/Player/Enemy are duplicated per dimension; the reaction rules are therefore written twice. If 2D is retired, delete `scripts/actors/`, its effects, `data/abilities/*.tres` and `tests/run_tests.gd`.
- 3D gameplay math is on the XZ plane (aim height is ignored); physics is only used for movement, walls and the camera spring arm.
- Ability numbers are per-dimension data files (px vs metres).

## Extension points
- New ability = new `.tres` using an existing effect (`projectile`, `ground_zone`); new behaviour = new class in `scripts/abilities/effects/` + a line in `AbilityEffects`.
- New status = id in `Statuses` + `StatusController.apply`.
- New enemy = subclass `Combatant`/`Enemy`; stats are plain exported vars today.

## Risks / likely rework
1. Reaction logic hard-wired in `Bolt`/`GroundZone`. Cheap now, will need a data-driven reaction table at Phase 2 (element + status -> effects).
2. Distance-check collisions have no walls/obstacles; real arena geometry means moving to physics.
3. Abilities are 2 fixed slots; a loadout/unlock system (Phase 4) needs slot management.
4. Combat *feel* (speeds, damage, cooldowns, telegraph timing) is untuned: tests prove rules, not fun.

## Not done (deliberately)
Multiple enemies, bosses, combined natures, progression, audio, art, save data, spreadsheet-driven abilities, multiplayer.

## Roadmap
P1 combat prototype (this) -> P2 reaction system + ability roster -> P3 enemy archetypes + boss -> P4 progression/builds -> P5 exploration/quests/region -> P6 content expansion -> P7 polish/release. Multiplayer: separate evaluation.
