# Echoes of the Celestial Staff — Phase 6 Spirit Abilities Test Checklist

**Phase:** Phase 6 — Spirit Abilities  
**Target Engine:** Godot 4.7.2 Stable (`4.7.2.stable.official.ed1daf0bf`)  
**Renderer:** GL Compatibility  
**Test Scene:** `res://scenes/world/test_spirit_room.tscn`  
**Test Runner:** `res://tests/test_spirit_runner.tscn`  
**Hardware Baseline:** Intel Core i3-1115G4, 12 GB RAM, Intel UHD Graphics, 60 FPS  

---

## 1. Automated Test Verification

| Test Suite | Scene Path | Expected Passed | Actual Passed | Status |
| :--- | :--- | :--- | :--- | :--- |
| **Phase 1: Foundation** | `res://tests/test_runner.tscn` | 45 | 45 | **PASSED** |
| **Phase 2: Locomotion** | `res://tests/test_player_runner.tscn` | 48 | 48 | **PASSED** |
| **Phase 3: Combat** | `res://tests/test_combat_runner.tscn` | 91 | 91 | **PASSED** |
| **Phase 4: Advanced Defense** | `res://tests/test_defense_runner.tscn` | 84 | 84 | **PASSED** |
| **Phase 5: Combat Stances** | `res://tests/test_stance_runner.tscn` | 64 | 64 | **PASSED** |
| **Phase 6: Spirit Abilities** | `res://tests/test_spirit_runner.tscn` | 95 | 95 | **PASSED** |
| **GRAND TOTAL** | **All 6 Test Suites** | **427** | **427** | **100% CLEAN** |

---

## 2. Interactive Manual Testing Checklist (`test_spirit_room.tscn`)

Launch the test gym using:
`Godot_v4.7.2-stable_win64_console.exe res://scenes/world/test_spirit_room.tscn`

### 2.1 Default State & HUD Verification
- [ ] **HUD Alignment:** Observe top-left Spirit HUD containing:
  - Spirit bar (`100.0 / 100.0`) filled with celestial cyan/gold styling.
  - Three ability cards: Slot 1: Celestial Arc (20 SP), Slot 2: Heavenly Pulse (30 SP), Slot 3: Cloud Step (25 SP).
  - Status labels reading `[READY]`.
- [ ] **Debug Overlay:** Observe top-right telemetry panel displaying `Spirit: 100/100`, `Spirit State: READY`, and slot cooldown timers.

### 2.2 Ability 1: Celestial Arc (`Key 1` or `J / U`)
- [ ] **Activation:** Face right and press `1`.
  - Spirit drops by exactly 20 (100 -> 80).
  - Player transitions into `SpiritAbility` state with golden flash and cast animation.
  - Ethereal cyan crescent projectile spawns and travels horizontally to the right at 480 px/s.
- [ ] **Target Collision:** Projectile impacts Dummy 1:
  - Deals 18.0 damage (Dummy HP 100 -> 82).
  - Deals 15.0 poise damage (Dummy Poise 35 -> 20).
  - Projectile passes through or terminates according to piercing rule without dealing duplicate hits.
- [ ] **Left Direction:** Turn left and press `1`.
  - Projectile cleanly flips horizontally (-1 scale) and travels leftward.
- [ ] **Cooldown:** Slot 1 enters cooldown (2.0s). Cooldown overlay fills and ticks down to 0.0s before allowing recast.

### 2.3 Ability 2: Heavenly Pulse (`Key 2` or `I`)
- [ ] **Activation:** Stand between Dummy 1 and Dummy 2 and press `2`.
  - Spirit drops by exactly 30 (e.g. 80 -> 50).
  - Radiating circular expanding shockwave expands outward to 64px radius.
- [ ] **Multi-Target Detection:**
  - Both Dummy 1 and Dummy 2 take 24.0 damage and 35.0 poise damage simultaneously.
  - Poise is completely depleted, triggering guard break and yellow stagger outline.
- [ ] **Range Check:** Dummy 3 (behind obstacle wall) is unaffected if outside 64px radius.
- [ ] **Single-Hit Window:** Targets within radius take damage exactly once per shockwave cast.

### 2.4 Ability 3: Cloud Step (`Key 3` or `O`)
- [ ] **Activation:** Press `3` while facing forward.
  - Spirit drops by exactly 25.
  - Player bursts forward at 550 px/s for 0.20s with cyan martial trail.
- [ ] **Collision Preserved:** Dash into solid obstacle wall or room boundaries:
  - Player does NOT clip or pass through solid terrain; physics collision remains intact.
- [ ] **Vulnerability:** Cloud Step does not grant automatic I-frames; player can still take damage if hitting active enemy hitboxes.

### 2.5 Combat Spirit Restoration Pipeline
- [ ] **Deplete Spirit:** Cast abilities until Spirit reaches < 10.
- [ ] **Light Attack Hit:** Strike a test dummy with Light 1 / 2 / 3:
  - Observe `+4.0 Spirit` per confirmed hit.
- [ ] **Heavy Attack Hit:** Strike a test dummy with Heavy 1:
  - Observe `+8.0 Spirit` per confirmed hit.
- [ ] **Perfect Parry:** Step near Training Attacker (`Key T` to trigger attack) and tap Parry:
  - Intercepting the strike inside the 5-frame window yields `+10.0 Spirit` instantly.
- [ ] **Cap Clamping:** Restore Spirit until 100.0; confirm it stops cleanly at `100.0` without overflowing.

### 2.6 Gatekeeping & Safety Rules
- [ ] **During Attack Startup/Active:** Press Light Attack (`J`), immediately mash `1` or `2`:
  - Ability cast is rejected; attack animation finishes cleanly.
- [ ] **During Attack Recovery:** After Light Attack strike connects, tap `1`:
  - Ability smoothly cancels recovery frames and executes immediately.
- [ ] **During Dodge I-Frames:** Press Dodge (`K`), immediately mash `1`:
  - Ability cast is blocked; dodge invulnerability is preserved.
- [ ] **Ability Recovery Cancel:** While in ability recovery phase, tap Dodge (`K`) or Parry (`L`):
  - Casting animation cleanly cancels into defensive action.
- [ ] **Stance Interaction:** Switch stance between Swift (`C`), Mountain, and Storm while casting:
  - Stance switching is blocked during ability Startup and Active phases.
  - Ability damage and spirit cost remain consistent across all stances.

---

## 3. Performance & Stability Verification
- [ ] **Framerate:** Rock-solid 60 FPS maintained during multi-dummy shockwave and projectile emissions.
- [ ] **Memory:** Static memory remains flat; no orphan nodes generated on projectile despawn or dummy reset.
- [ ] **Zero Console Errors:** 0 errors, 0 warnings during extended play sessions.
