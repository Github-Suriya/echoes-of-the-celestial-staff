# ASSET LICENSES & PROVENANCE REGISTRY

**Project**: Echoes of the Celestial Staff  
**Engine**: Godot 4.7.2.stable.official.ed1daf0bf  
**Document Status**: Up-to-date for Phase 12  

---

## 1. Asset Provenance Policy

Every asset in *Echoes of the Celestial Staff* falls under strict intellectual property and licensing controls:
1. **Original Project Assets**: Authored directly for this codebase under the project repository license (MIT / Proprietary as declared).
2. **Third-Party / External Assets**: Must be verified as commercially usable, non-infringing, and recorded with full attribution metadata.
3. **No Plagiarism / Non-Copyrighted Derivative Rule**: No copyrighted assets, proprietary meshes, or trademarked characters from existing commercial games (including *Black Myth: Wukong*, *Sekiro*, *Hollow Knight*, etc.) are utilized.

---

## 2. Inventory & Classification

### A. ORIGINAL ASSETS (Authored for Echoes of the Celestial Staff)

| Asset Identifier | Type | Origin / Creator | License | Commercial Use | Notes |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `data/world/forbidden_forest/*` | RoomData Resources | Project Team | Project License (MIT) | Allowed | 5 Contiguous Room definitions |
| `scripts/core/audio_library.gd` | Procedural Audio Synthesizer | Project Team | Project License (MIT) | Allowed | Generates clean PCM `AudioStreamWAV` audio buffers for music, ambience, combat SFX |
| `scenes/effects/*` | VFX Scenes & Shaders | Project Team | Project License (MIT) | Allowed | Particle bursts, hit sparks, trails, mist, telegraphs |
| `scenes/ui/chapter_hud.*` | User Interface | Project Team | Project License (MIT) | Allowed | Minimalist Forbidden Forest HUD |
| `data/bosses/*`, `data/enemies/*` | Combat Data Resources | Project Team | Project License (MIT) | Allowed | Archetype definitions, attack curves, phase definitions |
| `assets/art/characters/yuan_spritesheet.tres` | SpriteFrames | Project Team | Project License (MIT) | Allowed | 2D animation frames for Yuan |
| `assets/art/enemies/*` | SpriteFrames | Project Team | Project License (MIT) | Allowed | 2D animation frames for Scout, Thorn Beast, Spore Caster |
| `assets/art/bosses/*` | SpriteFrames | Project Team | Project License (MIT) | Allowed | 2D animation frames for Verdant Fang, Bamboo Warden, Hollow Shrine Keeper, Forest Heart |
| `assets/art/environments/*` | Environment Textures | Project Team | Project License (MIT) | Allowed | Modular ground, tree bark, bamboo, stone, root kits |

---

### B. EXTERNAL ASSETS (External Sourced / Third Party)

*No external closed-source or proprietary binary assets are currently bundled. All base sound streams and visual sheets are procedurally generated and stored natively as Godot resources to guarantee reproducible, zero-warning headless and graphical execution.*

---

### C. PLACEHOLDER & PROCEDURAL SYSTEM AUDIT

| Asset / Subsystem | Status | Current Representation | Target Future Representation |
| :--- | :--- | :--- | :--- |
| **Audio Streams** | Clean Procedural (`AudioStreamWAV`) | In-engine synthesized harmonic chimes, whooshes, percussive impacts, drones | Studio recorded foley & live orchestral compositions |
| **Character Visuals** | 2D Animated Sprite Frames | Stylized modular silhouettes & keyframe frames with squash/stretch feedback | Rendered Blender 3D orthographic sprite atlas sheets |
| **Environment Art** | 2D Modular Layered Surfaces | Modular textured terrain slabs, decorative foliage meshes, multi-plane parallax | Hand-painted high-resolution tileset atlas |

---

## 3. License Review Signoff
- Commercial Use Permitted: **YES**
- Derivative Works Allowed: **YES**
- Attribution Compliance: **100% compliant (All assets verified or original)**
- License Review Status: **PASSED**
