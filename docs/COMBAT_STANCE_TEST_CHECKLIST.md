# Phase 5 Combat Stances Test Checklist

**Project:** Echoes of the Celestial Staff  
**Engine:** Godot 4.7.2 Stable (`4.7.2.stable.official.ed1daf0bf`)  
**Renderer:** GL Compatibility  
**Phase:** 5 — Combat Stances  
**Suite:** `tests/test_stance_runner.tscn` (`tests/test_combat_stances.gd`)  
**Status:** 64 / 64 Sub-tests Passed (42 Major Criteria 100% Passed)  
**Total Suite Regression:** 332 / 332 Tests Passed Across All Phases (Phase 1: 45, Phase 2: 48, Phase 3: 91, Phase 4: 84, Phase 5: 64)

---

## 1. Stance Data Resources & Configuration

| ID | Specification | Status | Evidence / Implementation |
|---|---|---|---|
| `DATA-01` | `stance_swift.tres` exists and loads cleanly | PASS | Resource instance of `StanceData` loads without errors |
| `DATA-02` | Swift resource enum matches `StanceType.SWIFT` | PASS | `stance_type == StanceType.SWIFT` (0) |
| `DATA-03` | Swift movement speed multiplier is `1.10x` | PASS | `movement_speed_multiplier == 1.10` |
| `DATA-04` | Swift attack speed multiplier is `1.12x` | PASS | `attack_speed_multiplier == 1.12` |
| `DATA-05` | Swift attack damage multiplier is `0.90x` | PASS | `damage_multiplier == 0.90` |
| `DATA-06` | Swift poise damage multiplier is `0.90x` | PASS | `poise_damage_multiplier == 0.90` |
| `DATA-07` | `stance_mountain.tres` exists and loads cleanly | PASS | Resource instance of `StanceData` loads without errors |
| `DATA-08` | Mountain resource enum matches `StanceType.MOUNTAIN` | PASS | `stance_type == StanceType.MOUNTAIN` (1) |
| `DATA-09` | Mountain movement speed multiplier is `0.90x` | PASS | `movement_speed_multiplier == 0.90` |
| `DATA-10` | Mountain attack speed multiplier is `0.88x` | PASS | `attack_speed_multiplier == 0.88` |
| `DATA-11` | Mountain attack damage multiplier is `1.18x` | PASS | `damage_multiplier == 1.18` |
| `DATA-12` | Mountain poise damage multiplier is `1.30x` | PASS | `poise_damage_multiplier == 1.30` |
| `DATA-13` | `stance_storm.tres` exists and loads cleanly | PASS | Resource instance of `StanceData` loads without errors |
| `DATA-14` | Storm resource enum matches `StanceType.STORM` | PASS | `stance_type == StanceType.STORM` (2) |
| `DATA-15` | Storm movement speed multiplier is `1.00x` | PASS | `movement_speed_multiplier == 1.00` |
| `DATA-16` | Storm attack damage multiplier is `1.08x` | PASS | `damage_multiplier == 1.08` |
| `DATA-17` | Storm poise damage multiplier is `1.05x` | PASS | `poise_damage_multiplier == 1.05` |

---

## 2. Stance Controller API & State Persistence

| ID | Specification | Status | Evidence / Implementation |
|---|---|---|---|
| `CTRL-01` | `StanceController` attached as component node to `Player` | PASS | Present at `Components/StanceController` |
| `CTRL-02` | Default initial stance is `SWIFT` | PASS | `current_stance == StanceType.SWIFT` on ready |
| `CTRL-03` | Initial `StanceData` reference non-null | PASS | `current_stance_data != null` |
| `CTRL-04` | `set_stance()` transitions to `MOUNTAIN` | PASS | Returns true, stance updates to Mountain |
| `CTRL-05` | `set_stance()` transitions to `STORM` | PASS | Returns true, stance updates to Storm |
| `CTRL-06` | `cycle_stance()` cycles in sequence: Swift -> Mountain -> Storm -> Swift | PASS | Tested cycling loop returns correctly to Swift |
| `CTRL-07` | `stance_changed` signal emitted with old and new stances | PASS | Dispatched both locally and forwarded to `EventBus` |
| `PERSIST-01` | Player health remains unchanged across stance switch | PASS | Health value preserved across transitions |
| `PERSIST-02` | Player poise remains unchanged across stance switch | PASS | Poise value preserved across transitions |
| `PERSIST-03` | Player position remains unchanged across stance switch | PASS | Coordinates preserved without teleportation |
| `PERSIST-04` | Player velocity is preserved across stance switch | PASS | Locomotion momentum preserved |

---

## 3. Movement Modifiers & Locomotion Integration

| ID | Specification | Status | Evidence / Implementation |
|---|---|---|---|
| `MOVE-01` | Swift max run speed scales by `1.10x` | PASS | Locomotion applies `config.max_speed * 1.10` |
| `MOVE-02` | Swift acceleration scales by `1.10x` | PASS | Acceleration rate increased by 10% |
| `MOVE-03` | Mountain max run speed scales by `0.90x` | PASS | Locomotion applies `config.max_speed * 0.90` |
| `MOVE-04` | Mountain acceleration scales by `0.90x` | PASS | Acceleration rate reduced by 10% |
| `MOVE-05` | Storm max run speed preserves baseline `1.00x` | PASS | Locomotion applies `config.max_speed * 1.00` |

---

## 4. Attack Speed & Damage Modifiers

| ID | Specification | Status | Evidence / Implementation |
|---|---|---|---|
| `ATK-01` | Swift shortens Light 1 startup timer (`startup_time / 1.12`) | PASS | Phase timer matches startup time divided by 1.12 |
| `ATK-02` | Swift sets `hitbox.stance_damage_multiplier` to `0.90x` | PASS | Hitbox payload scales damage by 0.90 |
| `ATK-03` | Canonical base `AttackData` resource remains completely unmutated | PASS | Base `attack_light_1.tres` retains `10.0` base damage |
| `ATK-04` | Mountain extends Light 1 startup timer (`startup_time / 0.88`) | PASS | Phase timer matches startup time divided by 0.88 |
| `ATK-05` | Mountain sets `hitbox.stance_damage_multiplier` to `1.18x` | PASS | Hitbox payload scales damage by 1.18 |
| `ATK-06` | Storm sets `hitbox.stance_damage_multiplier` to `1.08x` | PASS | Hitbox payload scales damage by 1.08 |

---

## 5. Poise Modifiers

| ID | Specification | Status | Evidence / Implementation |
|---|---|---|---|
| `POISE-01` | Swift sets `hitbox.stance_poise_multiplier` to `0.90x` | PASS | Verified `stance_poise_multiplier == 0.90` |
| `POISE-02` | Mountain sets `hitbox.stance_poise_multiplier` to `1.30x` | PASS | Verified `stance_poise_multiplier == 1.30` |
| `POISE-03` | Storm sets `hitbox.stance_poise_multiplier` to `1.05x` | PASS | Verified `stance_poise_multiplier == 1.05` |

---

## 6. Dodge & Defense Modifiers

| ID | Specification | Status | Evidence / Implementation |
|---|---|---|---|
| `DODGE-01` | Swift scales dodge velocity impulse by `1.12x` | PASS | Velocity impulse = `380.0 * 1.12 = 425.6 px/s` |
| `DODGE-02` | Mountain reduces dodge velocity impulse by `0.90x` | PASS | Velocity impulse = `380.0 * 0.90 = 342.0 px/s` |
| `DODGE-03` | Swift shortens dodge recovery by `0.90x` | PASS | Recovery phase duration scaled by 0.90 |
| `DODGE-04` | Mountain lengthens dodge recovery by `1.10x` | PASS | Recovery phase duration scaled by 1.10 |

---

## 7. Parry Window Timing & Precision Protection

| ID | Specification | Status | Evidence / Implementation |
|---|---|---|---|
| `PARRY-01` | Parry active window multiplier is strictly `1.00x` across all stances | PASS | `parry_window_multiplier == 1.00` in Swift, Mountain, and Storm |
| `PARRY-02` | Perfect parry window (first 4 active frames) is identical in all stances | PASS | Timing preserved for competitive muscle memory |
| `PARRY-03` | Stance switching blocked during active parry deflection window | PASS | `can_change_stance()` returns false |
| `PARRY-04` | Stance switching allowed immediately when parry completes | PASS | `can_change_stance()` returns true after recovery |

---

## 8. State Machine Stance Switching Gatekeeping

| ID | Specification | Status | Evidence / Implementation |
|---|---|---|---|
| `SAFE-01` | Stance switching blocked during attack `STARTUP` | PASS | Returns false; current stance unchanged |
| `SAFE-02` | Stance switching blocked during attack `ACTIVE` | PASS | Returns false; current stance unchanged |
| `SAFE-03` | Stance switching allowed during attack `RECOVERY` | PASS | Stance cancel allowed; buffered or immediate switch succeeds |
| `SAFE-04` | Stance switching blocked during dodge I-frames | PASS | Returns false during invulnerable frames |
| `SAFE-05` | Stance switching blocked while charging heavy attack | PASS | Returns false while `is_charging_heavy == true` |

---

## 9. Visual Feedback & Debug HUD

| ID | Specification | Status | Evidence / Implementation |
|---|---|---|---|
| `VIS-01` | Stance change triggers color aura flash on player visuals | PASS | Color tweens: Swift (Cyan), Mountain (Amber), Storm (Electric Blue) |
| `VIS-02` | Procedural squash/stretch feedback on stance transition | PASS | Non-zero tweener scale applied cleanly |
| `VIS-03` | `PlayerDebugOverlay` displays active Stance and live multipliers | PASS | Telemetry formatted: Stance, Spd, AtkSpd, Dmg, Poise, Ddg |

---

## 10. Test Stance Arena Sandbox

| ID | Specification | Status | Evidence / Implementation |
|---|---|---|---|
| `ROOM-01` | `test_stance_room.tscn` loads and boots cleanly | PASS | Verified headless run to PLAYING state |
| `ROOM-02` | Room contains Player with full locomotion & combat | PASS | Player initialized at `(200, 480)` |
| `ROOM-03` | Room contains `CombatTrainingAttacker` | PASS | Attacker ready for parry/dodge testing |
| `ROOM-04` | Room contains `CombatTestDummy` | PASS | Target dummy ready for combo and poise break validation |
| `ROOM-05` | Stance HUD provides hotkeys (`1`=Swift, `2`=Mountain, `3`=Storm, `C`=Cycle, `R`=Reset) | PASS | Control guidance and live stance status displayed |
