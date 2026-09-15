# Echoes of the Celestial Staff — Art Direction & Visual Style Guide

**Document Version:** 1.0.0  
**Phase:** Phase 0 (Architecture & Design)  
**Target Engine:** Godot 4.7.2 Stable (GL Compatibility)  
**Target Platform:** Windows PC (Intel UHD Integrated Graphics Baseline)  

---

## 1. Visual Philosophy & Identity

### 1.1 The High Concept: "Celestial Guofeng"
*Echoes of the Celestial Staff* fuses the timeless elegance of traditional East Asian brushwork (*Shan Shui* / Ink Wash) with modern, stylized 2D cel-shaded action aesthetics. The world feels painterly yet razor-sharp, grounding mythic martial arts in rich natural textures and punctuating high-stakes combat with luminous celestial effects.

### 1.2 Originality Mandate
All visual motifs, character costumes, architecture, monster designs, and VFX runes are strictly original creations inspired by classical Asian mythology (the five elements, celestial constellations, Taoist harmony) without replicating any contemporary game or media property.

---

## 2. Visual Hierarchy & Readability

In a lightning-fast action game, visual clarity is a core gameplay mechanic. Players must identify terrain, threats, and telegraphs within milliseconds.

```
+-------------------------------------------------------------+
| Layer 4: Near Foreground   | Soft blur, dark vignette, 1.2x |
+----------------------------+--------------------------------+
| Layer 3: PLAYABLE PLANE    | Sharpest focus, crisp outline  |
|                            | High contrast, distinct lights |
+----------------------------+--------------------------------+
| Layer 2: Mid Background    | Desaturated 30%, parallax 0.5x |
+----------------------------+--------------------------------+
| Layer 1: Far Background    | Atmospheric haze, parallax 0.2x|
+-------------------------------------------------------------+
```

### 2.1 The Four Parallax Depth Planes
1. **Layer 1: Far Background (Sky & Distant Mountains):**
   - Palette: Low saturation, pale atmospheric haze.
   - Parallax Ratio: `0.15 - 0.25`.
   - Motion: Drifting clouds, distant celestial rings, soft mountain silhouettes.
2. **Layer 2: Mid Background (Distant Architecture & Terrain):**
   - Palette: Medium saturation, silhouetted pagodas, waterfalls, towering bamboo.
   - Parallax Ratio: `0.45 - 0.60`.
3. **Layer 3: Playable Plane (Action & Collision Layer):**
   - Palette: Full saturation, high-contrast edges, clean walkable ground lines.
   - Distinct 1px subtle darker outline to separate characters from backgrounds.
   - No distracting background clutter intersecting character silhouettes.
4. **Layer 4: Near Foreground (Atmospheric Framing):**
   - Soft, out-of-focus foreground elements (bamboo leaves, temple eaves, dangling chains).
   - Parallax Ratio: `1.15 - 1.30`.

---

## 3. Character & Combat Telegraph Design

### 3.1 Protagonist: Yuan
- **Silhouette Recognition:** Wears a streamlined martial robe with a high collar and a signature flowing **Celestial Crimson Sash** that extends behind him, creating clear visual arcs during runs, jumps, and staff swings.
- **Weapon Visual Feedback:**
  - **Swift Stance:** Staff glows with faint jade wind trails (`#55E6C1`).
  - **Mountain Stance:** Staff glows with molten amber embers (`#F39C12`).
  - **Storm Stance:** Staff crackles with electric violet lightning (`#9B59B6`).
  - **Awakened Form:** Entire staff radiates pure solar gold (`#F1C40F`).

### 3.2 Enemy Visual Archetypes & Telegraph Hierarchy
Telegraphs use universal, high-contrast visual signifiers:

| Attack Telegraph Type | Visual Cue | Sound Cue | Player Defensive Response |
| :--- | :--- | :--- | :--- |
| **Standard Parryable Strike** | Crisp **White Flash** at weapon tip during windup. | Metallic glint shimmer. | Block or Parry. |
| **Heavy Armored Strike** | **Molten Gold Aura** surrounding enemy; hyper-armor active. | Heavy low hum. | Dodge, or Mountain Stance Counter. |
| **Unblockable Perilous Strike** | Glowing **Crimson Glyph** flaring above enemy's head. | Piercing tension chime. | Evade or Jump (Cannot be blocked/parried). |
| **Grab / Binding Attack** | Ethereal **Violet Ghost Tendrils** emerging from hands. | Distorted suction sound. | Directional Dodge out of range. |

---

## 4. Biome Color Palette Matrix

```
[Monkey Village]       [Forbidden Forest]     [Mountain Temple]
  Gold:   #E67E22        Emerald: #16A085       Granite:  #7F8C8D
  Bamboo: #27AE60        Violet:  #8E44AD       Crimson:  #C0392B
  Cream:  #F5EEF8        Murk:    #1E272C       Cinder:   #D35400

[Underground Kingdom]  [Thunder Peaks]        [Celestial Palace]
  Obsidian: #2C3E50      Slate:   #34495E       Imperial: #F1C40F
  Amethyst: #9B59B6      Electric:#00D2D3       Pearl:    #ECF0F1
  Bronze:   #D35400      Indigo:  #1B1464       Cosmic:   #6C5CE7
```

---

## 5. Technical Asset Specifications (Hardware Optimized)

To guarantee consistent 60 FPS performance on Intel UHD integrated graphics:

### 5.1 Texture Atlas Rules
- **Maximum Texture Size:** `2048 x 2048 px`. Never exceed 2048 to prevent VRAM bus bottlenecks.
- **Power of Two:** All atlases and spritesheets must strictly adhere to power-of-two dimensions (e.g., `1024x1024`, `2048x1024`, `2048x2048`).
- **Compression:** Use VRAM-compressed textures (`Texture2D` in Lossy/ETC2 or WebP format for 2D sprites) configured via Godot import docks.

### 5.2 Animation Standards
- **Frame Rate:** Hand-crafted 2D keyframed sprite animations at **24 FPS** (interpolated smoothly across Godot's 60 FPS physics tick).
- **Scale:** Standard player height = 96 pixels tall; canvas viewport = 1920x1080 (ensures crisp sub-pixel alignment and detailed rendering).

### 5.3 Shader Performance Rules
- **Zero Heavy Multi-Pass Shaders:** No screen-space blur, complex refraction, or multi-pass Bloom shaders.
- **Lightweight Canvas Shaders:** Custom 2D shaders are restricted to single-pass fragment shaders (e.g., flash white on damage, silhouette highlight when occluded behind walls).
- **GL Compatibility Adherence:** All custom shaders must use standard Godot 4 `canvas_item` shader features fully compatible with OpenGL 3.3 / GLES3.
