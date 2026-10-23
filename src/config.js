/**
 * Data-driven configuration for abilities and natures.
 *
 * This file preserves the distinction between:
 *   - Abilities explicitly listed in the Nature Transformations.xlsx spreadsheet
 *   - Proposed gameplay additions for the prototype
 *
 * Spreadsheet reference (Nature Chart sheet):
 *   - Core cycle: Fire > Wind > Lightning > Earth > Water > Fire
 *   - Combined: Storm = Water + Lightning (Kekkei Genkai)
 *
 * Prototype decisions (NOT in spreadsheet):
 *   - Water "Conductive Pool": prototype-specific mechanic
 *   - Lightning "Chain": prototype-specific mechanic
 *   - The interaction (Water enables Lightning chain) is a prototype design choice
 */

export const NATURE_CONFIG = {
  elements: {
    fire:   { name: "Fire Release",     strongVs: ["wind"],    weakVs: ["water"],  color: "#e53935" },
    wind:   { name: "Wind Release",     strongVs: ["lightning"], weakVs: ["fire"],   color: "#90caf9" },
    lightning: { name: "Lightning Release", strongVs: ["earth"],  weakVs: ["wind"],   color: "#f5e619" },
    earth:  { name: "Earth Release",    strongVs: ["water"],    weakVs: ["lightning"], color: "#8d6e63" },
    water:  { name: "Water Release",    strongVs: ["fire"],     weakVs: ["earth"],  color: "#4a90e2" }
  },
  combined: {
    // From Combined Natures sheet: Storm = Water + Lightning (Kekkei Genkai)
    storm: {
      name: "Storm Release",
      components: ["water", "lightning"],
      type: "Kekkei Genkai",
      source: "Combined Natures sheet — Storm Release row"
    }
  }
};

export const ABILITY_CATALOG = {
  // From spreadsheet Wood sheet: "Basic wood control"
  wood_basic: {
    name: "Wood Release: Basic",
    source: "Wood sheet — 'Wood Release Technique (basic)'",
    nature: "wood",
    description: "Basic wood control: angular timber grows from the ground.",
    prototype: false  // Explicitly spreadsheet-sourced
  },

  // PROTOTYPE-SPECIFIC ABILITIES (not in spreadsheet as game mechanics)
  water_conductive_pool: {
    id: "water_conductive_pool",
    name: "Water: Conductive Pool",
    nature: "water",
    key: "Q",
    cooldown: 3.0,
    duration: 5.0,
    radius: 3.5,
    prototype: true,
    description: "Creates a conductive water pool on the ground. Enemies inside become 'Conductive' (tagged for Lightning chain).",
    // Prototype-only interaction design
    interaction: {
      appliesStatus: "conductive",
      statusDuration: 5.0
    }
  },

  lightning_chain: {
    id: "lightning_chain",
    name: "Lightning: Chain",
    nature: "lightning",
    key: "E",
    cooldown: 6.0,
    baseDamage: 25,
    chainDamage: 15,
    range: 8,
    maxTargets: 3,
    prototype: true,
    description: "Fires a lightning bolt at a target. If target is Conductive (from Water pool), chains to nearby enemies.",
    interaction: {
      bonusVsConductive: true,
      chainOnConductive: true
    }
  }
};

export const ENEMY_CONFIG = {
  // Prototype enemy archetype placeholder for Phase 2 expansion
  conductive_target: {
    id: "conductive_target",
    name: "Conductive Enemy",
    health: 100,
    speed: 2.5,
    aggroRange: 8,
    // This enemy is NOT naturally conductive; needs Water pool
    naturallyConductive: false
  }
};

export const PLAYER_CONFIG = {
  health: 100,
  speed: 5.5,
  // Placeholder for future unlockable abilities
  unlockedAbilities: ["water_conductive_pool", "lightning_chain"]
};