# PHASE 12 IMPLEMENTATION PLAN — FORBIDDEN FOREST VISUAL & AUDIO INTEGRATION

## 1. Executive Summary

Phase 12 elevates Chapter 1 — Forbidden Forest from a functional prototype into a visually and audibly coherent playable slice.
Preserving 100% of the authoritative gameplay mechanics, physics timings, and state machines established in Phases 1–11 (1,132 passing tests), Phase 12 introduces:
1. Complete 3D-to-2D sprite rendering pipeline documentation and 8 fully functional runtime `SpriteFrames` resources (Yuan, 3 normal enemies, 4 bosses).
2. Procedural modular environment textures and a multi-plane parallax background system across all 5 chapter rooms.
3. Enhanced combat visual feedback (staff trails, hit flashes, boss telegraph indicators, celestial awakening auras, phase transition bursts) within an ultra-lean particle budget (<60 active particles).
4. Trauma-based camera shake system (`CameraShakeController`) bounded by room camera limits.
5. In-engine warning-free audio architecture (`AudioLibrary` + `AudioManager`) delivering 5 music states, 4 ambience loops, and 20 responsive SFX events.
6. Chapter HUD presentation polish (low-HP warning pulse, dynamic boss phase 2 crimson styling, victory fanfare).

---

## 2. Invariants & Scope Boundaries

- **Gameplay Integrity**: Authoritative combat state logic, hitbox/hurtbox dimensions, attack data (`startup`, `active`, `recovery` timings), dodge invulnerability frames, parry windows, and boss phase thresholds remain 100% untouched.
- **Hardware Performance**: Engineered strictly for Intel Core i3-1115G4, 12 GB RAM, and Intel UHD Graphics at a solid 60 FPS (GL Compatibility renderer).
- **Decoupling**: All visual effects, camera trauma, and audio triggers listen passively to `EventBus` signals. If an audio or visual component fails, gameplay execution continues uninterrupted.
- **No Scope Creep**: Zero additional mechanics, no Chapter 2 content, no inventory or dialogue subsystems.

---

## 3. Architecture & Subsystems

### 3.1 Sprite & Animation Pipeline
- **Documented Pipeline (`docs/SPRITE_PIPELINE.md`)**:
  - 3D Blender modeling → 15° orthographic camera pitch → 3-point lighting setup → rendered at fixed pixel scale → packed into optimized sprite sheets.
- **Runtime AnimatedSprite2D Integration**:
  - All character and enemy scenes (`player.tscn`, `forest_scout.tscn`, `thorn_beast.tscn`, `spore_caster.tscn`, `verdant_fang.tscn`, `bamboo_warden.tscn`, `hollow_shrine_keeper.tscn`, `corrupted_forest_heart.tscn`) contain an `AnimatedSprite2D` node with pre-baked `SpriteFrames` resources (`assets/art/`).
  - Controllers (`PlayerAnimationController`, `EnemyAnimationController`, `BossAnimationController`) prioritize `AnimatedSprite2D` playback, falling back safely to procedural placeholder animations if frames are missing.

### 3.2 Environmental Atmosphere & Parallax
- **Modular Environment Textures**:
  - `tex_forest_ground.tres`: Rich mossy soil and bedrock tiles for Room 1 & 2.
  - `tex_bamboo_stalks.tres`: Golden-green dense bamboo stalks for Room 3.
  - `tex_shrine_stone.tres`: Weathered cyan/azure runic stone for Room 4.
  - `tex_corrupted_roots.tres`: Pulsing crimson/purple corrupted roots for Room 5.
- **Multi-Plane Parallax Background Controller (`ParallaxBackgroundController`)**:
  - Coordinates Far Background (0.15–0.25x scroll), Mid Background (0.45–0.55x scroll), and Foreground (1.20–1.30x scroll) planes across room boundaries.

### 3.3 Combat Feedback & VFX Architecture
- **VFX Instantiation (`VFXManager`)**:
  - `vfx_staff_trail.tscn`: Flowing qi arcs trailing light and heavy staff swings.
  - `vfx_hit_flash.tscn`: High-contrast brief white/gold flash on hit entities.
  - `vfx_boss_telegraph.tscn`: Pulsing warning rings indicating unblockable or heavy boss strikes.
  - `vfx_awakening_aura.tscn`: Radiant golden flame aura accompanying Celestial Awakening.
  - `vfx_phase_transition.tscn`: Corrupted crimson shockwave bursting during boss phase shifts.
- **Budget Compliance**:
  - Low particle counts (<=30 particles per emitter).
  - Automatic memory cleanup via `vfx_autofree.gd` or `one_shot` emitters.

### 3.4 Trauma-Based Camera Shake
- **`CameraShakeController`**:
  - Quadratic trauma falloff: `Offset = MaxOffset * Trauma^2 * Noise`.
  - Seamless integration with existing `Camera2D` and bounded within room `CameraBounds`.
  - Trauma profiles:
    - Normal Hit: +0.18
    - Heavy Impact: +0.35
    - Perfect Parry: +0.25
    - Boss Ground Slam: +0.45
    - Phase Transition: +0.55
    - Boss Death: +0.75

### 3.5 Warning-Free Audio Engine
- **`AudioLibrary` (`scripts/core/audio_library.gd`)**:
  - Procedural, high-quality 16-bit PCM `AudioStreamWAV` generators using Godot 4's `encode_s16()`.
  - Eliminates external uncompressed asset bloat while guaranteeing zero null audio warnings.
- **Dynamic State Machine (`AudioManager` & `ForbiddenForestWorld`)**:
  - **Music States**: `exploration`, `intermediate_boss`, `final_boss_p1`, `final_boss_p2`, `chapter_complete`.
  - **Ambience Streams**: `forest_wind`, `bamboo_rustle`, `shrine_hum`, `corrupted_heart`.
  - **SFX Events (20 total)**: `footstep`, `jump`, `land`, `staff_swing_light`, `staff_swing_heavy`, `dodge`, `parry`, `perfect_parry`, `hit_light`, `hit_heavy`, `stagger`, `enemy_death`, `awakening_start`, `awakening_end`, `boss_telegraph`, `boss_slam`, `boss_transition`, `boss_defeat`, `checkpoint`, `victory_fanfare`.

### 3.6 Chapter HUD Polish
- **Low-HP Warning**: `HealthBar` smoothly pulses crimson when Yuan's health drops below 25%.
- **Boss Phase 2 Shift**: `BossHealthBar` dynamically switches nameplate to `[BOSS NAME] — UNSTABLE CORRUPTION` with magenta/crimson accents.
- **Victory Presentation**: Polished victory banner with celestial glow and fanfare audio trigger upon Chapter 1 completion.

---

## 4. Verification & Testing Strategy

1. **Automated Visual & Audio Test Suite (`test_visual_audio_p12.gd`)**:
   - 10 distinct test categories validating sprite sheets, animation controllers, VFX instantiation and particle counts, camera trauma mechanics, procedural audio generation, audio playback states, and HUD transitions.
2. **Regression Verification**:
   - Verify that all existing unit tests across Phases 1 through 11 continue to pass without error.
3. **Hardware Profile Compliance**:
   - Zero console errors, zero parser warnings, and full compatibility with GL Compatibility renderer on Intel UHD Graphics.
