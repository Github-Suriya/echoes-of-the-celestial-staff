# Echoes of the Celestial Staff — Phase 7 Celestial Awakening Test Checklist

**Phase:** Phase 7 — Celestial Awakening / Transformation Foundation  
**Target Engine:** Godot 4.7.2 Stable (`4.7.2.stable.official.ed1daf0bf`)  
**Renderer:** GL Compatibility  
**Test Scene:** `res://scenes/world/test_transformation_room.tscn`  
**Test Runner:** `res://tests/test_transformation_runner.tscn`  
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
| **Phase 7: Celestial Awakening** | `res://tests/test_transformation_runner.tscn` | 113 | 113 | **PASSED** |
| **GRAND TOTAL** | **All 7 Test Suites** | **540** | **540** | **100% CLEAN** |

---

## 2. Interactive Manual Testing Checklist (`test_transformation_room.tscn`)

Launch the interactive arena:
`Godot_v4.7.2-stable_win64_console.exe res://scenes/world/test_transformation_room.tscn`

### 2.1 Default State & HUD Verification
- [ ] **HUD Alignment:** Top-left Spirit HUD contains:
  - Spirit Bar (`100 / 100`).
  - Ability Slots (Arc, Pulse, Step).
  - Awakening Card reading `[F] AWAKENING: READY`.
- [ ] **Debug Overlay (F3):** Observe telemetry:
  - `Awakening: INACTIVE (0.0s, 0%)`
  - Multipliers: `Spd: 1.0x | Atk: 1.0x | Dmg: 1.0x | Abi: 1.0x`

### 2.2 Activation & Resource Transaction
- [ ] **Activate Awakening:** Press `F`.
  - Player triggers radiant golden/cyan visual feedback tween.
  - Spirit drops immediately by 100 (100 -> 0).
  - HUD displays `CELESTIAL AWAKENING: 12.0s` with animated progress bar.
  - Debug overlay displays `Awakening: ACTIVE (12.0s, 100%)`.
  - Multipliers display: `Spd: 1.10x | Atk: 1.10x | Dmg: 1.15x | Pse: 1.10x | Abi: 1.10x`.
- [ ] **Insufficient Spirit:** After Awakening expires and Spirit is 0, press `F`:
  - Activation fails safely.
  - HUD reads `[F] AWAKENING: NEED 100 SP`.
  - No resource is consumed.
- [ ] **Refill Spirit:** Press `T`:
  - Spirit instantly refills to 100 / 100.
  - HUD updates to `[F] AWAKENING: READY`.

### 2.3 Combat & Defense Interaction during Awakening
- [ ] **Light Combo Scaling:** Strike Dummy 1 with Light Attack 1 / 2 / 3:
  - Attack speed is noticeably snappier (1.10x faster startup/active).
  - Damage dealt is scaled by 1.15x.
- [ ] **Heavy & Charged Attack:** Perform heavy attack (`K`) and hold-to-charge heavy:
  - Damage scales multiplicatively with both charge multiplier and 1.15x transformation multiplier.
- [ ] **Air Attack:** Perform jump + attack (`Space -> J`):
  - Downward strike deals empowered damage.
- [ ] **Dodge Velocity & Recovery:** Press `Shift`:
  - Dodge travels further and faster (1.05x velocity).
  - Dodge recovery is 5% shorter (0.95x recovery).
- [ ] **Timing Invariance:**
  - Parry window and perfect parry window are identical to baseline (no timing desync).
  - Perfect dodge window is identical to baseline (0.033s - 0.100s).

### 2.4 Stance Stacking & Invariance
- [ ] **Swift + Awakening:** In Swift Stance, activate Awakening:
  - Movement speed stacks: $1.10 \times 1.10 = 1.21x$.
  - Attack speed stacks: $1.12 \times 1.10 = 1.232x$.
- [ ] **Mountain + Awakening:** Switch to Mountain (`C`) and activate Awakening:
  - Poise damage stacks: $1.30 \times 1.10 = 1.43x$.
  - Crushing hits break dummy poise in fewer swings.
- [ ] **Storm + Awakening:** Switch to Storm (`C`):
  - Balanced high damage: $1.08 \times 1.15 = 1.242x$.
- [ ] **Stance Preservation:** Wait for Awakening timer to expire:
  - Stance remains Mountain / Storm / Swift without resetting.

### 2.5 Spirit Ability Synergy
- [ ] **Celestial Arc (`Key 1`):** Fire projectile while Awakening is active:
  - Crescent blade deals 19.8 damage ($18.0 \times 1.10$).
  - Cooldown remains exactly 2.0s; Spirit cost remains 20.
- [ ] **Heavenly Pulse (`Key 2`):** Trigger area shockwave while Awakening is active:
  - Shockwave deals 26.4 damage ($24.0 \times 1.10$).
  - Cooldown remains exactly 4.0s; Spirit cost remains 30.
- [ ] **Cloud Step (`Key 3`):** Trigger burst dash:
  - Dashes forward 550 px/s; collision with obstacle wall remains solid without clipping.

### 2.6 Automatic Expiration & Clean Deactivation
- [ ] **Countdown Expiry:** Allow 12 seconds to elapse:
  - Transformation automatically exits to `INACTIVE`.
  - HUD returns to inactive state.
  - Multipliers cleanly revert to 1.0x.
  - Health, poise, position, and velocity remain undisturbed.

---

## 3. Stability & Performance Criteria
- [ ] Rock-solid 60 FPS maintained during Awakening active aura and multi-dummy collisions.
- [ ] 0 parser errors, 0 runtime errors, 0 warnings.
- [ ] Zero memory growth across repeated activation/expiration cycles.
