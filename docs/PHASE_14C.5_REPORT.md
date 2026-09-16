# PHASE 14C.5 COMPLETION REPORT
# DESTINED ONE ANIMATION PIPELINE FIX + STAFF SYNC + ANIMATION SOURCE EVALUATION

**Project:** Echoes of the Celestial Staff  
**Engine:** Godot 4.7.2 stable  
**Renderer:** GL Compatibility (OpenGL 3.3)  
**Target Platform:** Windows PC (Intel Core i3-1115G4, 12GB RAM, Intel UHD Graphics, 60 FPS Target)  
**Date:** September 16, 2026  

---

# Phase 14C.5 Status

**PASS**

---

## Bug 1 — 2D Staff

- **Root cause:** In `render_destined_one_animations.gd` (and previously in preview), local bone rotations (`set_bone_pose_rotation`) were copied directly from Destined One to the weapon skeleton. However, the weapon skeleton (`SK_Wukong_weapon_born_mo`) contains an intermediate bone (`Bip`) and rotated rest-axes (`spine_01` has a 90° roll offset relative to the character rig). Copying local rotations caused rotational accumulation that pivoted the weapon arm chain ~90° upward into the sky. Furthermore, the previous camera framing (`size = 3.85`, `pos.y = 1.25`) was too tight for the 2.91-meter polearm, causing staff clipping during wide swings and rolls.
- **Fix:** 
  1. Replaced local rotation copying with Godot's world-space bone pose override:
     ```gdscript
     var d_hand = char_sk.find_bone("hand_r")
     var w_hand = weapon_sk.find_bone("hand_r")
     var d_hand_global = char_sk.get_bone_global_pose(d_hand)
     weapon_sk.set_bone_global_pose_override(w_hand, d_hand_global, 1.0, true)
     weapon_sk.force_update_bone_child_transform(w_hand)
     ```
     This locks the weapon's `hand_r` to the character's `hand_r` in world coordinates with < 0.000001 units offset.
  2. Adjusted orthographic camera to `CANONICAL_CAM_SIZE = 6.0` and `CANONICAL_CAM_POS = Vector3(-0.35, 0.35, 4.0)` to cleanly frame the full 5.25-meter vertical and 4.2-meter horizontal motion envelope across all 5 animations.
  3. Re-rendered all 22 frames in `assets/characters/destined_one/generated/sprites/512_anims/` and re-built `res://assets/characters/destined_one/spriteframes/destined_one_retarget_512_spriteframes.tres`.
- **PNG contains staff:** **YES** — verified by direct image inspection and automated boundary analysis across all 22 frames. The character and staff form a single visual composition within each 512×512 PNG.
- **Staff follows hand_r:** **YES** — verified dynamically across all animation playback frames; maximum distance between `char.hand_r` and `weapon.hand_r` is `0.000000`.
- **Status:** **FIXED**

---

## Bug 2 — Test Runner

- **Root cause:** `test_destined_one_animation.gd` and `test_destined_one_integration.gd` were written with `extends SceneTree` and `_init()` calling `quit()`. However, the runner scenes (`test_destined_one_animation_runner.tscn` and `test_destined_one_integration_runner.tscn`) have a root node of native type `Node`. In Godot 4, `SceneTree` inherits from `MainLoop` (not `Node`), causing Godot's script loader to fail immediately with:
  `"Script inherits from native type 'SceneTree', so it can't be assigned to an object of type 'Node'."`
- **Fix:** Aligned both scripts with the established project test runner architecture (as seen in `test_foundation.gd`, `test_player_controller.gd`, and `test_combat_foundation.gd`):
  1. Changed script declaration to `extends Node`.
  2. Moved test execution logic into `func _ready() -> void:`.
  3. Replaced `quit(...)` with `get_tree().quit(...)`.
- **Runner:** `res://tests/destined_one_animation/test_destined_one_animation_runner.tscn` opens immediately and executes cleanly without any debugger or type errors.
- **Tests executed:** 91 / 91 passed in animation runner; 62 / 62 passed in integration runner.
- **Status:** **FIXED**

---

## 2D Preview

Verified in `res://tests/destined_one_animation/DestinedOne2DAnimationPreview.tscn` with `destined_one_retarget_512_spriteframes.tres`:

- **Idle:** 4 frames @ 5.0 FPS — Staff held firmly in right hand diagonally across chest; perfect transparent background; top margin 27px, bottom margin 226px.
- **Run:** 6 frames @ 10.0 FPS — Destined One leans forward in sprint; staff tracks right hand at waist level; zero clipping (minimum margin 82px).
- **Light:** 4 frames @ 8.0 FPS — Forward strike; staff thrusts and aligns with right arm motion; minimum margin 37px.
- **Heavy:** 4 frames @ 6.0 FPS — Overhead jump and slam anticipation; staff swings back and slams forward; zero clipping (minimum margin 81px, left margin 89px).
- **Dodge:** 4 frames @ 8.0 FPS — Low somersault roll; staff remains firmly locked in right hand during roll; bottom margin 17px, top margin 86px, zero border clipping.

---

## Animation Source Evaluation

- **Current source:** `res://assets/characters/knight_test/KnightCharacter.fbx`
- **Strengths:**
  1. Humanoid bone structure maps cleanly to Godot's humanoid `BoneMap` profile.
  2. 100% stable retargeting to Destined One's 227-bone skeleton with zero scale collapse or gimbal locking.
  3. Proved the viability of the entire 3D retargeting → orthographic SubViewport → 512×512 PNG → SpriteFrames → 2D AnimatedSprite2D pipeline.
  4. Provides a rock-solid technical baseline for locomotion and state transitions.
- **Limitations:**
  1. **Western Knight Rig:** Authored for a one-handed sword and shield fighter, resulting in rigid, one-handed weapon swings rather than fluid two-handed Chinese martial arts polearm techniques.
  2. **Static Hand Gripping:** The right hand holds the staff like a sword hilt near the end, rather than sliding along the shaft, spinning, or employing two-handed wushu holds.
  3. **Combat Cadence Mismatch:** Sourced clips feature slow, cinematic wind-ups (~0.83s light attack, ~1.17s heavy attack) compared to authoritative 2D gameplay data (0.25s light attack, 0.62s heavy attack).
  4. **Lack of Wushu Acrobatics:** Does not include Monkey King signatures (pole-vaulting pillar stance, rapid multi-hit flurries, 360° low staff sweeps, airborne downward chops).
- **Required future source characteristics:**
  1. **Discipline:** Authentic Chinese martial arts (Wushu / Gunshu - 棍术) or Monkey Style staff combat (猴棍).
  2. **Grip Mechanics:** Rigging that supports two-handed staff grips, dynamic sliding grips, and mid-shaft hand placement.
  3. **Action Repertoire:**
     - Alert wushu combat idle (two-handed low guard).
     - 3-hit wushu light combo: thrust, circular sweep, overhead strike.
     - Heavy slam and aerial polearm smash.
     - Pillar stance (balancing atop the staff) / staff deflection spin.
     - Acrobatic dodges (low cartwheel, handspring, duck-roll).
     - Directional hit flinches, stagger, knockdown, and kip-up recovery.
  4. **Cadence:** Authored with snappy 3-5 frame action startups matching fast-paced 2D combat.
  5. **Licensing:** Clear, permissive commercial game development license (e.g. CC0, MIT, or royalty-free commercial license permitting 2D sprite baking and distribution).

---

## Performance

- **FPS:** 60 FPS (stable, capped at target)
- **Memory:** 
  - 2D Preview: ~78.8 MB static memory (reduced from 81.8 MB)
  - 3D Retarget Scene: ~87.2 MB static memory
- **Frame switching:** < 0.02 ms per animation switch in `AnimatedSprite2D`

---

## Tests

- **Core Foundation (`test_runner.tscn`):** 45 / 45 PASSED
- **Player Controller (`test_player_runner.tscn`):** 48 / 48 PASSED
- **Combat Foundation (`test_combat_runner.tscn`):** 91 / 91 PASSED
- **Destined One Integration (`test_destined_one_integration_runner.tscn`):** 62 / 62 PASSED
- **Phase 14C / 14C.5 Animation Suite (`test_destined_one_animation_runner.tscn`):** 91 / 91 PASSED
- **Total Active Tests Executed:** **337 / 337 PASSED (100% Pass Rate)**

**Legacy Suites:**
- **Knight Direct Import / 3D→2D:** NOT RUN — ARCHIVED
- **Black Myth Wukong Asset Audit:** NOT RUN — ARCHIVED

---

## Production Files Modified

No production gameplay architecture files modified.

*(All gameplay systems, including `PlayerController`, `PlayerMovement`, `CombatController`, `DefenseController`, `SpiritAbilityController`, `HealthComponent`, `PoiseComponent`, `Hitbox`, `Hurtbox`, `AttackData`, and `PlayerAnimationController`, remain completely untouched).*

---

## Known Limitations

1. **Temporary Animation Baseline:** Current animations use the retargeted Knight baseline. Sourced animations look functional and adhere strictly to hand sockets, but exhibit medieval sword motion rather than authentic Eastern staff martial arts.
2. **Kinematic Duration Scaling:** 3D source animations feature longer kinematic arcs than the fast 2D combat timings in `AttackData`. In production sprite baking, keyframes are sampled to match authoritative 2D frames.

---

## Phase 15 Recommendation

**Phase 15 Recommendation:**
Sourcing and evaluation of a legal, high-quality Wushu / Polearm martial arts animation pack (or keyframed wushu staff set) meeting the exact specifications defined in Section 4, followed by retargeting and high-density 2D sprite baking synchronized with authoritative `AttackData` hitboxes.

*(DO NOT implement at this stage).*
