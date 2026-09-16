# Phase 4 Advanced Combat & Defense Test Checklist

**Project:** Echoes of the Celestial Staff  
**Engine:** Godot 4.7.2 Stable (`4.7.2.stable.official.ed1daf0bf`)  
**Renderer:** GL Compatibility  
**Phase:** 4 — Advanced Combat & Defense  
**Suite:** `tests/test_defense_runner.tscn` (`tests/test_advanced_combat.gd`)  
**Status:** 84 / 84 Sub-tests Passed (42 Major Criteria 100% Passed)

---

## 1. Ground Dodge & I-frames

| ID | Specification | Status | Evidence / Implementation |
|---|---|---|---|
| `DODGE-01` | Dodge input (`KEY_SHIFT`) activates `PlayerDodgeState` | PASS | `PlayerDodgeState` entered from `Idle`, `Run`, and recovery cancellation |
| `DODGE-02` | Directional velocity impulse applied | PASS | Velocity impulse = `380.0 px/s` with smooth deceleration curve |
| `DODGE-03` | Neutral dodge with facing=+1 dodges right | PASS | `defense.dodge_direction == 1`, positive velocity applied |
| `DODGE-04` | Dodge with negative move axis dodges left | PASS | `defense.dodge_direction == -1`, negative velocity applied |
| `DODGE-05` | World collision remains active at all times | PASS | `CharacterBody2D.collision_layer == 2` & `collision_mask == 1` intact |
| `DODGE-06` | Startup phase is vulnerable (`t < 0.033s`) | PASS | `is_invulnerable_to_damage == false` at `t=0.01s` |
| `DODGE-07` | Active I-frames window (`0.033s` to `0.200s`) | PASS | `is_invulnerable_to_damage == true` at `t=0.05s` |
| `DODGE-08` | Recovery phase is vulnerable (`0.200s` to `0.350s`) | PASS | `is_invulnerable_to_damage == false` at `t=0.25s` |
| `DODGE-09` | Dodge finishes cleanly after total duration (`0.35s`) | PASS | `finish_dodge()` fires, returning cleanly to locomotion |
| `DODGE-10` | Incoming damage during I-frames suppressed | PASS | `Hurtbox` queries `DefenseController.try_intercept_hit()`, zeroes damage |

---

## 2. Perfect Dodge Mechanics

| ID | Specification | Status | Evidence / Implementation |
|---|---|---|---|
| `PERF-DODGE-01` | Perfect dodge window active in first 4 frames (`0.033s - 0.100s`) | PASS | `is_in_perfect_dodge_window()` reports true at `t=0.05s` |
| `PERF-DODGE-02` | `try_intercept_hit()` returns `DODGE_PERFECT` | PASS | Interception returns `DefenseResult.DODGE_PERFECT` |
| `PERF-DODGE-03` | Emits `perfect_dodge` signal locally and via `EventBus` | PASS | Signal received by listener and dispatched on `EventBus` |
| `PERF-DODGE-04` | Applies tactical hitstop (`0.08s`, factor `0.04`) | PASS | Hitstop invoked via `GameManager.apply_hitstop()` |
| `PERF-DODGE-05` | Procedural visual feedback hook executed | PASS | `PlayerAnimationController.play_perfect_dodge_feedback()` triggered |
| `PERF-DODGE-06` | Outside perfect window triggers normal dodge | PASS | At `t=0.15s`, returns `DefenseResult.DODGE_NORMAL` |

---

## 3. Ground Parry & The Perfect Parry

| ID | Specification | Status | Evidence / Implementation |
|---|---|---|---|
| `PARRY-01` | Parry input (`KEY_Q`) activates `PlayerParryState` | PASS | `PlayerParryState` entered from `Idle`, `Run`, or recovery cancel |
| `PARRY-02` | Startup phase is vulnerable (`t < 0.033s`) | PASS | `is_in_parry_window()` reports false at `t=0.01s` |
| `PARRY-03` | Active parry deflection window active (`0.033s - 0.253s`) | PASS | `is_in_parry_window()` reports true at `t=0.06s` |
| `PARRY-04` | Recovery phase is vulnerable (`0.253s - 0.433s`) | PASS | `is_in_parry_window()` reports false at `t=0.28s` |
| `PARRY-05` | Total parry duration cleanly exits to locomotion | PASS | `finish_parry()` executes after total duration |
| `PERF-PARRY-01` | Perfect parry window active in first 4 active frames (`0.033s - 0.116s`) | PASS | `is_in_perfect_parry_window()` reports true at `t=0.05s` |
| `PERF-PARRY-02` | `try_intercept_hit()` returns `PARRY_PERFECT` | PASS | Interception returns `DefenseResult.PARRY_PERFECT` |
| `PERF-PARRY-03` | Emits `perfect_parry` signal locally and via `EventBus` | PASS | Signal received by listener and dispatched on `EventBus` |
| `PERF-PARRY-04` | Inflicts heavy poise damage (`25.0`) on attacker | PASS | `attacker.poise_component.current_poise` depleted |
| `PERF-PARRY-05` | Emits `attack_interrupted` and calls `attacker.interrupt_attack()` | PASS | Attacker enters `INTERRUPTED` state, swing canceled |
| `PARRY-06` | Outside perfect window triggers normal parry | PASS | At `t=0.15s`, returns `DefenseResult.PARRY_NORMAL` |
| `PARRY-07` | Normal parry emits `parry_success` signal | PASS | Signal emitted locally and on `EventBus` |

---

## 4. Failed Defense & Edge Cases

| ID | Specification | Status | Evidence / Implementation |
|---|---|---|---|
| `FAIL-DEF-01` | Unparryable attack (`is_parryable = false`) bypasses parry | PASS | `try_intercept_hit()` returns `NONE`, full damage dealt |
| `FAIL-DEF-02` | Attack received during parry startup deals full damage | PASS | At `t=0.01s`, returns `NONE` |
| `FAIL-DEF-03` | Attack received during dodge recovery deals full damage | PASS | At `t=0.25s`, returns `NONE` |

---

## 5. Aerial Attack Foundation

| ID | Specification | Status | Evidence / Implementation |
|---|---|---|---|
| `AIR-01` | `attack_air_1.tres` exists and loads cleanly | PASS | Base resource loaded with all required parameters |
| `AIR-02` | Air attack damage matches spec (`14.0`) | PASS | Verified `damage = 14.0` |
| `AIR-03` | Air attack poise damage matches spec (`16.0`) | PASS | Verified `poise_damage = 16.0` |
| `AIR-04` | Mid-air light attack triggers `start_air_attack()` | PASS | `start_air_attack()` returns true |
| `AIR-05` | Initial phase is `STARTUP` | PASS | Verified `current_phase == STARTUP` |
| `AIR-06` | Player transitions to `PlayerAirAttackState` | PASS | State machine changes to `AirAttack` state |
| `AIR-07` | Landing during air attack transitions cleanly to `Land` | PASS | Floor contact calls `finish_combat()` and enters `Land` |

---

## 6. Charged Heavy Attack Foundation

| ID | Specification | Status | Evidence / Implementation |
|---|---|---|---|
| `CHARGE-01` | `attack_heavy_1.tres` marked `is_chargeable = true` | PASS | Verified `is_chargeable == true` |
| `CHARGE-02` | Maximum damage multiplier is `2.0x` | PASS | Verified `maximum_damage_multiplier == 2.0` |
| `CHARGE-03` | Maximum poise multiplier is `2.0x` | PASS | Verified `maximum_poise_multiplier == 2.0` |
| `CHARGE-04` | Holding heavy attack initiates charge loop | PASS | `is_charging_heavy == true`, phase reports `CHARGING` |
| `CHARGE-05` | Charge ratio interpolates smoothly over time | PASS | Ratio advances from `0.0` to `1.0` between `0.15s` and `0.75s` |
| `CHARGE-06` | Reaching max charge caps multipliers at `2.0x` | PASS | Damage and poise multipliers cap at `2.0` |
| `CHARGE-07` | Release applies scaled multipliers to Hitbox | PASS | `hitbox.damage_multiplier == 2.0`, `hitbox.poise_multiplier == 2.0` |

---

## 7. Attack Cancellation Framework

| ID | Specification | Status | Evidence / Implementation |
|---|---|---|---|
| `CANCEL-01` | Attack in `STARTUP` phase cannot be cancelled | PASS | `can_cancel_attack()` returns false |
| `CANCEL-02` | Attack in `ACTIVE` phase cannot be cancelled | PASS | `can_cancel_attack()` returns false |
| `CANCEL-03` | Attack in `RECOVERY` phase can be cancelled into Dodge/Parry | PASS | `can_cancel_attack()` returns true |

---

## 8. Test Arena & Training Automation

| ID | Specification | Status | Evidence / Implementation |
|---|---|---|---|
| `ROOM-01` | `CombatTrainingAttacker` scene loads and instantiates | PASS | Hitbox, Hurtbox, Poise, Health verified |
| `ROOM-02` | `trigger_attack()` triggers telegraphed swing | PASS | Enters `TELEGRAPH` state with visual warning |
| `ROOM-03` | `interrupt_attack()` cancels attack and applies deflection stun | PASS | Hitbox disabled, enters `INTERRUPTED` state |
| `ROOM-04` | `test_defense_room.tscn` boots with Player, Attacker, and Dummy | PASS | Arena initialized cleanly into `PLAYING` state |

---

## Regression Verification Summary
- **Phase 1 Foundation Suite (`test_runner.tscn`):** 45 / 45 PASSED (100%)
- **Phase 2 Player Suite (`test_player_runner.tscn`):** 48 / 48 PASSED (100%)
- **Phase 3 Combat Suite (`test_combat_runner.tscn`):** 91 / 91 PASSED (100%)
- **Phase 4 Advanced Combat Suite (`test_defense_runner.tscn`):** 84 / 84 PASSED (100%)
- **Total Passing Automated Tests:** **268 / 268 PASSED (0 FAILED)**
