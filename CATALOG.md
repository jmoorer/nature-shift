# Catalog: Nature Shift - Source of Truth Preservation

This file distinguishes between abilities explicitly listed in `Nature Transformations.xlsx` and prototype gameplay additions.

## Spreadsheet Source (Explicit Facts from Sheet)

From `Nature Chart` sheet (A1:F13):
- **Fire Release**: Katon (火遁) — Strong vs Wind, Weak vs Water. Source: Narutopedia Nature Transformation page.
- **Wind Release**: Fūton (風遁) — Strong vs Lightning, Weak vs Fire.
- **Lightning Release**: Raiton (雷遁) — Strong vs Earth, Weak vs Wind.
- **Earth Release**: Doton (土遁) — Strong vs Water, Weak vs Lightning.
- **Water Release**: Suiton (水遁) — Strong vs Fire, Weak vs Earth.
- **Yin/Yang**: Non-elemental (spiritual/physical energy). Note: Yin-Release and Yang-Release are NOT the five-nature cycle.

From `Combined Natures` sheet (A1:J19):
- **Wood Release** (Mokuton, 木遁): Earth + Water; Kekkei Genkai. Confirmed (Hashirama)
- **Ice Release** (Hyōton, 氍遁): Water + Wind; Confirmed (Haku)
- **Lava Release** (Yōton, 熔遁/溶遁): Fire + Earth; Confirmed (Mei Terumī)
- **Boil Release** (Futton, 沸遁): Fire + Water; Confirmed (Kokuō, Mei)
- **Storm Release** (Ranton, 嵐遁): Lightning + Water; Confirmed (Darui)
- **Scorch Release** (Shakuton, 灼遁): Fire + Wind; Suggested (Naruto + Sasuke combo, ch. 634)
- **Explosion Release** (Bakuton, 爆遁): Earth + Lightning; Suggested (Deidara)
- **Magnet Release** (Jiton, 磁遁): Wind + Earth; Suggested
- **Crystal Release** (Shōton, 晶遁): Unknown components; Anime-only (Guren); Earth suggested by elimination

From `Sources & Notes` (A1:B37):
- All descriptions are paraphrases, not quotations.
- Source pages: Narutopedia, Pixiv Encyclopedia, Naruto Boutique, Mirrored blogs.
- Verification labels used: Verified, Single source, Unverified, Title only.
- Corrections: Mud Release = Novel-only; Blaze Release mobile-game pairing.

## Prototype Gameplay Additions (NOT Spreadsheet Facts)

These are design decisions for the Phase 1 prototype ONLY. They are not presented as established facts from the spreadsheet.

- **Conductive Pool (Water)**: A mechanic where Water creates a grounded area that marks targets for Lightning interaction. Not listed as a named jutsu.
- **Lightning Chain**: A mechanic where Lightning can propagate to targets marked by Conductive Pool. Not listed as a named jutsu, though Storm Release (Lightning + Water) is confirmed.
- **Water + Lightning Interaction**: The specific rule (Water pool = Lightning chains) is a prototype design choice, NOT a spreadsheet-derived relationship. The spreadsheet confirms Storm = Water + Lightning exists, but does NOT specify interaction mechanics.
- **Enemy "Conductive" Status**: A gameplay tag for prototype interaction testing.
- **Cooldown and Damage Values**: Balance choices for prototype, not reference values.

## Technical Architecture Decisions

- Engine: HTML5 Canvas + vanilla JS (no build dependencies)
- Catalog stored in `src/config.js` with explicit `prototype: true/false` flags
- All spreadsheet references preserve source sheet names and row references
- No invented relationships between elements (cycle verified from `Nature Chart`)