# Echoes of the Celestial Staff — Phase 4 Implementation Plan
## Advanced Combat & Defense Foundation

**Document Version:** 1.0.0  
**Phase:** Phase 4 — Advanced Combat & Defense  
**Engine:** Godot 4.7.2 Stable (`4.7.2.stable.official.ed1daf0bf`)  
**Renderer:** GL Compatibility  
**Language:** Strict Typed GDScript  

---

## 1. Executive Summary & Objectives

Phase 4 evolves the combat foundation established in Phase 3 from an offensive loop (`ATTACK -> HIT -> DAMAGE`) into a complete, high-agency interactive combat dialogue:

```
                  ENEMY ATTACK
                       │
       ┌───────────────┴───────────────┐
       ↓                               ↓
     DODGE                           PARRY
   ┌───┴───┐                       ┌───┴───┐
   ↓       ↓                       ↓       ↓
 NORMAL  PERFECT                 NORMAL  PERFECT
 EVADE   DODGE                   PARRY   PARRY
```

Alongside the defensive suite, Phase 4 establishes:
1. **Attack Cancellation Rules**: Fluid cancellation of attack recovery into defensive actions (`Dodge` / `Parry`).
2. **Aerial Combat Foundation**: Dedicated `AirAttack` state and `attack_air_1.tres` (Celestial Falling Strike).
3. **Charged Heavy Attack Foundation**: Hold-to-charge input mechanic for heavy attacks with scaled damage, poise damage, and visual pulse feedback.
4. **Combat Training Attacker**: A deterministic training dummy (`scenes/enemies/combat_training_attacker.tscn`) executing telegraphed enemy attacks to test dodge and parry mechanics.
5. **Defense Test Arena**: An interactive testing laboratory (`scenes/world/test_defense_room.tscn`) supporting 7 distinct test scenarios.
6. **Comprehensive Automated Test Suite**: Headless test suite (`tests/test_advanced_combat.gd`, `tests/test_defense_runner.tscn`) covering all 42 required criteria with 100% regression passing on Phases 1 (45/45), 2 (48/48), and 3 (91/91).

---

## 2. Component Architecture & Hierarchy

The architecture preserves modularity and strictly adheres to **Composition Over Deep Inheritance**. The defense systems are encapsulated in a dedicated `DefenseController` component rather than bloating `PlayerController`.

```
Player (CharacterBody2D) [Layer 2: Player]
│
├── CollisionShape2D (CapsuleShape2D)
├── Visuals (Node2D)
│   ├── Body, Head, Sash, Eye, Staff
│   └── AfterimageHook (Node2D)
│
├── Camera2D
│
├── Components (Node)
│   ├── PlayerMovement (Node)
│   ├── PlayerAnimationController (Node)
│   ├── PlayerRespawn (Node)
│   ├── CombatController (Node) [scripts/player/combat_controller.gd]
│   ├── DefenseController (Node) [scripts/player/defense_controller.gd]
│   ├── HealthComponent (Node) [scripts/combat/health_component.gd]
│   └── PoiseComponent (Node) [scripts/combat/poise_component.gd]
│
├── Combat (Node2D)
│   ├── PlayerHitbox (Area2D, Layer 4) [scripts/combat/hitbox.gd]
│   └── PlayerHurtbox (Area2D, Layer 6) [scripts/combat/hurtbox.gd]
│
├── StateMachine (Node) [scripts/systems/state_machine.gd]
│   ├── Idle (PlayerIdleState)
│   ├── Run (PlayerRunState)
│   ├── Jump (PlayerJumpState)
│   ├── Fall (PlayerFallState)
│   ├── Land (PlayerLandState)
│   ├── Attack (PlayerAttackState)
│   ├── HeavyAttack (PlayerHeavyAttackState)
│   ├── AirAttack (PlayerAirAttackState) [NEW]
│   ├── Dodge (PlayerDodgeState) [NEW]
│   └── Parry (PlayerParryState) [NEW]
│
└── DebugOverlay (CanvasLayer) [scripts/player/player_debug_overlay.gd]
```

### Component Roles & Responsibilities:
- **`DefenseController`**:
  - Encapsulates dodge duration, velocity impulse, invulnerability window (I-frames), and perfect dodge window.
  - Encapsulates parry startup, active parry window, perfect parry window, and recovery.
  - Exposes `try_intercept_hit(damage_info: DamageInfo) -> DefenseResult` called by `Hurtbox` upon incoming attacks.
- **`Hurtbox`**:
  - Intercepts incoming attacks through `DefenseController.try_intercept_hit(damage_info)`.
  - If intercepted by parry or dodge, suppresses health and poise damage.
- **`CombatController`**:
  - Extended to support aerial attacks (`attack_air_1.tres`) and charged heavy attacks (`is_chargeable`, `charge_ratio`, hold/release input).
  - Exposes `can_cancel_attack()` allowing immediate transitions into `Dodge` or `Parry` during recovery.
- **`PlayerAnimationController`**:
  - Exposes hooks: `play_dodge_animation()`, `play_perfect_dodge_feedback()`, `play_parry_animation()`, `play_perfect_parry_feedback()`, `play_air_attack_animation()`, `play_charge_animation()`.

---

## 3. Detailed Defensive Systems Design

### 3.1 Ground Dodge & The Perfect Dodge
- **Input**: `InputManager.ACTION_DODGE` (`KEY_SHIFT`).
- **State**: `PlayerDodgeState`.
- **Direction Rules**:
  - If horizontal movement input is active (`abs(axis) > 0.05`): Dodge in input direction.
  - If stationary: Dodge in current `facing_direction` (+1 for right, -1 for left).
  - Never invert collision shapes.
- **Timing & Windows** (at 60 FPS):
  - Total Duration: `0.35s` (~21 frames).
  - Normal Invulnerability (I-frames): `0.033s` to `0.200s` (~10 frames).
  - **Perfect Dodge Window**: `0.033s` to `0.100s` (first 4 frames of the invulnerability window).
  - Recovery Window: `0.200s` to `0.35s` (vulnerable to hits, returns to locomotion).
- **Collision Integrity**: Physical world collision (`collision_mask = 1`) remains **fully active** at all times. Dodge invulnerability only affects combat damage reception.
- **Perfect Dodge Results**:
  - Complete damage and knockback negation.
  - Hitstop applied via `GameManager.apply_hitstop(0.08, 0.05)`.
  - Visual feedback hook (afterimage flash and squash/stretch).
  - Emits `perfect_dodge` signal locally and via `EventBus`.
  - Grants tactical advantage window (immediate cancel into attack/movement).

### 3.2 Ground Parry & The Perfect Parry
- **Input**: `InputManager.ACTION_PARRY` (`KEY_Q`).
- **State**: `PlayerParryState`.
- **Timing & Windows** (at 60 FPS):
  - Startup: `0.033s` (2 frames, vulnerable).
  - Active Parry Window: `0.033s` to `0.220s` (frames 3 to 13).
  - **Perfect Parry Window**: `0.033s` to `0.090s` (frames 3 to 6, first ~4 frames of active parry).
  - Recovery: `0.220s` to `0.350s` (vulnerable, returns to movement).
- **Parry Interception Flow**:
  1. Enemy Hitbox intersects Player Hurtbox.
  2. Hurtbox queries `defense_controller.try_intercept_hit(damage_info)`.
  3. If within active parry window and `damage_info.is_parryable`:
     - **If inside Perfect Parry window**:
       - Complete damage and knockback negation.
       - Heavy hitstop via `GameManager.apply_hitstop(0.12, 0.02)`.
       - Inflicts heavy poise damage (25.0) on the attacker.
       - Interrupts attacker swing via `attack_interrupted` signal.
       - Emits `perfect_parry` signal locally and on `EventBus`.
     - **If outside Perfect window (Normal Parry)**:
       - Complete damage and knockback negation.
       - Standard hitstop via `GameManager.apply_hitstop(0.06, 0.05)`.
       - Emits `parry_success` signal locally and on `EventBus`.
  4. If parry is inactive, on startup, or in recovery:
     - Hit connects normally; player takes full damage and poise reduction.

---

## 4. Extended Combat Systems Design

### 4.1 Aerial Attack Foundation
- **Asset**: `data/attacks/attack_air_1.tres` (Celestial Falling Strike).
  - `damage`: `14.0`, `poise_damage`: `16.0`, `knockback_force`: `Vector2(120, 80)`.
  - `startup_time`: `0.067s` (4 frames), `active_time`: `0.067s` (4 frames), `recovery_time`: `0.133s` (8 frames).
- **Execution Rules**:
  - Triggers only when player is airborne (`not is_on_floor()`) and presses `light_attack`.
  - State: `PlayerAirAttackState`.
  - Physics: Controlled downward glide (`velocity.y` clamped to safe rate) while maintaining forward momentum.
  - If player lands during the air attack, immediately transitions cleanly to `Land` state.
  - If recovery completes in mid-air, transitions cleanly to `Fall` state.

### 4.2 Charged Heavy Attack Foundation
- **Input**: Hold `InputManager.ACTION_HEAVY_ATTACK` (`KEY_K` / RMB).
- **Mechanics**:
  - In `PlayerHeavyAttackState`, holding the attack button enters a charging state.
  - `minimum_charge_time`: `0.15s`
  - `maximum_charge_time`: `0.75s`
  - `charge_ratio`: smoothly interpolates from `0.0` to `1.0`.
  - Damage scales from base damage (`25.0`) up to `2.0x` (`50.0`).
  - Poise damage scales from base (`35.0`) up to `2.0x` (`70.0`).
  - Releasing the button (or reaching max charge) executes the heavy strike.
  - Visual feedback: Pulse scaling on staff and player visual container.

### 4.3 Attack Cancellation Framework
- **Startup Phase**: Zero cancellation (preserves commitment and prevents feint exploits).
- **Active Phase**: Zero cancellation (hitbox must complete resolution).
- **Recovery Phase**: **Immediate cancellation** allowed into `Dodge` or `Parry` as soon as recovery starts. This ensures fluid, high-responsiveness combat feel without clunkiness.

---

## 5. Combat Training Attacker & Defense Room

### 5.1 `CombatTrainingAttacker` (`scenes/enemies/combat_training_attacker.tscn`)
- Stationary automaton designed to deterministically test defensive mechanics.
- Contains:
  - `Hitbox` on Layer 5 (`EnemyHitbox`, mask Layer 6 `PlayerHurtbox`).
  - `Hurtbox` on Layer 7 (`EnemyHurtbox`), `HealthComponent` (100 HP), `PoiseComponent` (40 Poise).
  - Visual telegraph indicator: Flashes bright warning before striking.
  - Methods: `trigger_attack()`, `interrupt_attack()`, `reset_attacker()`.

### 5.2 `TestDefenseRoom` (`scenes/world/test_defense_room.tscn`)
- Dedicated arena supporting 7 scenarios:
  - Scenario 1: Normal dodge timing
  - Scenario 2: Perfect dodge timing & feedback
  - Scenario 3: Normal parry timing
  - Scenario 4: Perfect parry & counter-stagger
  - Scenario 5: Failed defense (damage verification)
  - Scenario 6: Air attack against elevated platforms and dummy
  - Scenario 7: Charged heavy attack with scaled impact

---

## 6. Collision Layer Matrix (Strict Adherence)

| Layer ID | Name | Purpose |
| :--- | :--- | :--- |
| **Layer 1** | `WorldGeometry` | Environment, terrain, floors, walls. Player physics collider always masks this. |
| **Layer 2** | `Player` | Player CharacterBody2D physics collider. |
| **Layer 3** | `Enemies` | Enemy/Dummy CharacterBody2D physics collider. |
| **Layer 4** | `PlayerHitbox` | Player attack hit area. Masks Layer 7 (`EnemyHurtbox`). |
| **Layer 5** | `EnemyHitbox` | Enemy/Training attacker hit area. Masks Layer 6 (`PlayerHurtbox`). |
| **Layer 6** | `PlayerHurtbox` | Player damage reception area. Masks `0`. Intercepted by `DefenseController`. |
| **Layer 7** | `EnemyHurtbox` | Enemy/Dummy damage reception area. Masks `0`. |
| **Layer 8** | `Triggers` | Interaction zones and reset triggers. |

---

## 7. Automated Testing Strategy (`tests/test_advanced_combat.gd`)

Covers at minimum 42 test cases across 6 domains:
1. **Dodge (1-9)**: Input detection, state transition, movement impulse, recovery end, return to locomotion, invulnerability active during I-frames, world collision preserved, direction respects movement, direction uses facing when stationary.
2. **Perfect Dodge (10-14)**: Perfect window active, attack during perfect window triggers perfect dodge, damage negated, event emitted, distinct from normal dodge.
3. **Parry (15-20)**: Input detection, state transition, parry window active, incoming hit intercepted, damage negated, normal parry event emitted.
4. **Perfect Parry (21-25)**: Perfect window active, timing produces perfect parry, damage negated, poise damage inflicted on attacker, stronger hitstop emitted.
5. **Failed Defense (26-28)**: Failed dodge receives damage, failed parry receives damage, no false positive perfect triggers.
6. **Air Attack (29-33)**: Triggers only while airborne, ground attack blocked in air, hitbox active, damage delivered, returns to locomotion.
7. **Charged Attack (34-39)**: Charge initiates, timer increases, releases on button release, min charge works, max charge works, damage and poise scale accurately.
8. **Regressions (40-42)**: Phase 1 tests pass (45/45), Phase 2 tests pass (48/48), Phase 3 tests pass (91/91).
