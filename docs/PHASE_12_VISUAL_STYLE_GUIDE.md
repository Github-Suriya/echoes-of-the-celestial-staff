# PHASE 12 — FORBIDDEN FOREST VISUAL STYLE GUIDE

**Project**: Echoes of the Celestial Staff  
**Engine**: Godot 4.7.2.stable.official.ed1daf0bf  
**Renderer**: GL Compatibility  
**Target Hardware**: Intel Core i3-1115G4, 12 GB RAM, Intel UHD Graphics, 60 FPS Target  
**Scope**: Chapter 1 — Forbidden Forest Vertical Slice  

---

## 1. Core Visual Direction & Artistic Identity

*Echoes of the Celestial Staff* employs a **stylized cinematic 2D fantasy** visual direction. It evokes classical East Asian mythology, Taoist celestial aesthetics, and mystical martial arts traditions while presenting an entirely original fantasy world.

### Key Pillars:
1. **Bold Silhouettes & Readability**: Combat mechanics (parry windows, dodge I-frames, telegraph windups) require absolute visual clarity. Characters, enemies, and interactive objects possess sharp, distinct outer contours that read instantly against layered backgrounds.
2. **Painterly Lighting & Organic Depth**: Atmospheric depth is communicated through selective value hierarchy, soft mist bands, and distinct parallax planes rather than costly post-processing shaders.
3. **Restrained Color Palettes**: Each zone in the Forbidden Forest has a curated, three-color primary tonal harmony. Vibrant energy bursts (celestial gold, corrupted crimson) are reserved for active gameplay cues.
4. **Authoritative Timing Over Animation**: Art serves gameplay. Keyframe silhouettes snap into action on active hitbox frames and maintain clear anticipation and recovery poses matching physics logic.

---

## 2. Zone Aesthetics & Palette Hierarchy

The Forbidden Forest transitions through 5 distinct atmospheric zones as the player journeys deeper toward the corrupted core:

### Zone 1: Forest Entrance (`room_01_forest_entrance`)
- **Atmosphere**: Awakening at the outer perimeter. Cool morning air, diffused light penetrating morning mist.
- **Dominant Palette**:
  - Primary Base: Deep Slate Teal (`#1c2d27`)
  - Foliage / Accents: Moss Jade (`#2a5a3b`, `#4a855b`)
  - Highlights / Sky: Pale Celadon Mist (`#b8d8c2`)
- **Key Motifs**: Dense ancient oak trunks, soft grass verges, drifting morning ground mist, ruined marker stones.

### Zone 2: Ancient Grove (`room_02_ancient_grove`)
- **Atmosphere**: Deep, shadowed elder glade. Oppressive canopy, wild predatory territory guarded by *Verdant Fang*.
- **Dominant Palette**:
  - Primary Base: Shadow Evergreen (`#0f2118`)
  - Trunk & Stone: Elder Bark Amber (`#3a2618`, `#5c4028`)
  - Accent / Eyes: Emerald Luminescence (`#10c971`)
- **Key Motifs**: Twisted gnarled roots, massive mossy canopy branches, elevated root platforms, predatory scratch marks.

### Zone 3: Cursed Bamboo Path (`room_03_bamboo_path`)
- **Atmosphere**: Dense, vertical bamboo thickets on stepped mountain ridges. Wind swaying slender stalks, watched by *Bamboo Warden*.
- **Dominant Palette**:
  - Primary Base: Dark Forest Moss (`#122319`)
  - Stalks & Nodes: Yellow-Green Bamboo (`#6e8c3b`, `#a4b854`)
  - Atmosphere: Swirling Spore Haze (`#82a87a`)
- **Key Motifs**: Layered foreground/midground bamboo clusters, sharp vertical lines, broken bamboo barricades, drifting wind particles.

### Zone 4: Forgotten Shrine (`room_04_forgotten_shrine`)
- **Atmosphere**: Ancient sacred stone sanctuary falling into ruin. Spiritual wards holding back corruption, overseen by the *Hollow Shrine Keeper*.
- **Dominant Palette**:
  - Primary Base: Weathered Granite Grey (`#242b30`, `#3c454d`)
  - Spiritual Energy: Luminous Cyan Spirit Glow (`#38d9d4`, `#6ef0ec`)
  - Accents: Worn Stone Gold (`#b89442`)
- **Key Motifs**: Carved stone pillars, guardian statues, glowing spirit lanterns, sacred Torii/shrine gateway arches, broken flagstones.

### Zone 5: Forbidden Forest Heart (`room_05_forest_heart`)
- **Atmosphere**: The primeval centerpiece of the forest. The monumental trunk and roots of the ancient world tree consumed by unstable dark celestial resonance.
- **Dominant Palette**:
  - Primary Base: Abyssal Wood (`#120d1c`)
  - Corruption: Vibrant Crimson & Amethyst Violet (`#961536`, `#bd2451`, `#781d6f`)
  - Celestial Contrast: Radiance Gold (`#f5c542`)
- **Key Motifs**: Massive curving root buttresses, pulsing corrupted vascular veins, floating dark celestial spores, cracked stone altar.

---

## 3. Character & Silhouette Design

### 1. Yuan (Player Character)
- **Concept**: Disciplined monk-warrior channeling celestial qi through the Celestial Staff.
- **Silhouette**: Lean, athletic martial stance. Trailing red sash provides immediate kinetic feedback on jumps, dodges, and swings. Long two-handed staff clearly visible in all postures.
- **Colors**:
  - Robes: Deep Jade Green (`#16a085`)
  - Trim & Sash: Crimson Vermilion (`#e74c3c`)
  - Staff: Ancient Celestial Gold & Iron (`#d4ac0d`, `#f39c12`)
  - Headband / Accent: Dark Charcoal (`#2c3e50`)
- **Animation States**:
  - Locomotion: Low-center sprint, crisp vertical jump tuck, ground-plant landing.
  - Combat: Fluid 3-hit staff combo (horizontal thrust, sweep, downward overhead slam), charged heavy stance windup.
  - Defense: Low forward roll dodge, rigid horizontal deflection parry posture.
  - Transformation (Celestial Awakening): Radiant golden silhouette outline, extended staff reach, trailing golden energy particles.

### 2. Forest Scout (Normal Enemy)
- **Concept**: Corrupted agile beast-stalker hunting in packs.
- **Silhouette**: Low quad/bipedal hunched predator. Elongated clawed forearms, predatory head tilt.
- **Colors**: Ferrous rust orange (`#d35400`), darkened earth brown, luminous amber eye slit.

### 3. Thorn Beast (Normal Enemy)
- **Concept**: Armored lumbering bruiser encased in petrified bark and brambles.
- **Silhouette**: Broad, massive rectangular silhouette. Heavily weighted shoulders, ground-scraping fists. Unflinching poise.
- **Colors**: Dark stony bark (`#424949`), moss green accents, sharp thorn ochre (`#b9770e`).

### 4. Spore Caster (Normal Enemy)
- **Concept**: Twisted fungal shaman channeling corrupted airborne spores.
- **Silhouette**: Tall, thin, swaying ascetic robe silhouette. Crowned by a glowing fungal spore bell.
- **Colors**: Faded lichen grey-green (`#566573`), toxic violet and luminous lime-green spore bulb (`#a569bd`, `#58d68d`).

### 5. Verdant Fang (Intermediate Boss 1)
- **Concept**: Apex predator of the Ancient Grove, bonded with elder bramble roots.
- **Silhouette**: Massive feline/canine beast silhouette with extended muscular shoulders and root-plated spine.
- **Colors**: Midnight green pelt (`#0e3d26`), bright emerald eyes and fangs (`#2ecc71`).

### 6. Bamboo Warden (Intermediate Boss 2)
- **Concept**: Corrupted martial monk bound in bamboo armor, wielding an extended heavy polearm.
- **Silhouette**: Tall, imposing conical straw hat silhouette. Wide stance, deliberate long-range staff thrusts and sweeps.
- **Colors**: Weathered woven bamboo amber (`#9a7d0a`), dark moss cloth, weathered iron mask.

### 7. Hollow Shrine Keeper (Intermediate Boss 3)
- **Concept**: Ancient animated temple guardian holding the key to the Inner Sanctum.
- **Silhouette**: Massive stone automaton silhouette. Carved ceremonial great-cleaver, floating spirit core visible through cracked ribcage.
- **Colors**: Ancient granite (`#515a5a`), weathered moss, glowing ethereal cyan spirit flame (`#00f2fe`).

### 8. Corrupted Forest Heart (Final Boss)
- **Concept**: The living avatar of the corrupted ancient woodland.
- **Silhouette**:
  - **Phase 1 (Ancient Guardian)**: Colossal humanoid root construct rooted into the forest floor. Heavy wooden plate shoulders, deliberate sweeping branch strikes.
  - **Phase 2 (Unstable Corruption)**: Breaks free from roots. Wild, elongated bramble limbs, glowing exposed pulsing heart core, jagged silhouette.
- **Colors**:
  - Phase 1: Primordial petrified wood (`#211a14`), deep amber sap, dark corrupted red cracks (`#922b21`).
  - Phase 2: Frenzied glowing violet-magenta core (`#881470`, `#e91e63`), jagged black briar claws, blazing red aura.

---

## 4. Animation Timing & State Authoritative Principle

All visual animation frames strictly adhere to the authoritative frame data established in previous phases:

| Action | Total Duration | Startup Window | Active Hitbox Window | Recovery Window |
| :--- | :--- | :--- | :--- | :--- |
| **Light Attack 1** | 0.400s | 0.067s (Frames 1–2) | 0.133s (Frames 3–5) | 0.200s (Frames 6–10) |
| **Light Attack 2** | 0.433s | 0.083s (Frames 1–3) | 0.150s (Frames 4–7) | 0.200s (Frames 8–12) |
| **Light Attack 3** | 0.533s | 0.100s (Frames 1–4) | 0.167s (Frames 5–9) | 0.266s (Frames 10–16) |
| **Heavy Attack 1** | 0.633s | 0.233s (Frames 1–7) | 0.150s (Frames 8–11) | 0.250s (Frames 12–18) |
| **Dodge Roll** | 0.400s | 0.033s | 0.167s (I-Frames) | 0.200s |
| **Parry Deflect** | 0.350s | 0.033s | 0.187s (Deflect Window) | 0.130s |

Animations must never artificially delay or accelerate these physics windows.

---

## 5. Visual Consistency & Performance Directives

1. **Orthographic Consistency**: All sprite renders, environment layers, and props maintain a uniform 15° top-down pitch with an orthographic projection.
2. **Fixed Scale**: Yuan stands at 46px collision height. Enemies and bosses scale proportionally (Scout: 48px, Thorn Beast: 64px, Shrine Keeper: 76px, Forest Heart: 110px).
3. **Hardware Budget Enforcement**:
   - Particle Systems: Maximum 20 particles per individual emitter; maximum 60 total concurrent particles active across the screen.
   - Texture Resolutions: Character frames 64x64 to 128x128. Environment atlases 256x256 to 512x512. No 2K/4K uncompressed textures.
   - Zero Full-Screen Post-Processing Shaders: Rely on Godot's built-in `CanvasModulate`, gradient blending, and multi-plane parallax for lighting moods.
