# Phase 5 — Combat Stances Implementation Plan

**Project:** Echoes of the Celestial Staff  
**Engine:** Godot 4.7.2 Stable (`4.7.2.stable.official.ed1daf0bf`)  
**Renderer:** GL Compatibility  
**Language:** Strict Typed GDScript  
**Phase:** 5 — Combat Stances  
**Target Frame Rate:** Stable 60 FPS (Baseline: Intel Core i3-1115G4, 12 GB RAM, Intel UHD Graphics)

---

## 1. Executive Summary & Architectural Vision

The core architectural principle of Phase 5 is:
> **ONE COMBAT SYSTEM + THREE DISTINCT COMBAT IDENTITIES**

Rather than creating separate controllers (`SwiftCombatController`, `MountainCombatController`, `StormCombatController`), we introduce a single decoupled **Stance Layer** via `StanceController` and data-driven `StanceData` resources.

Existing systems (`PlayerMovement`, `CombatController`, `DefenseController`, `Hitbox`, `Hurtbox`, `PlayerAnimationController`, `PlayerDebugOverlay`) remain unified and query `StanceController` for runtime modifiers. Base resource definitions (such as `.tres` files for attacks or movement) are never mutated at runtime.

```
                         Player (CharacterBody2D)
                                    │
    ┌───────────────────────────────┼──────────────────────────────┐
    │                               │                              │
PlayerMovement               CombatController              DefenseController
    │                               │                              │
    └──────────────────────► StanceController ◄─────────────────────┘
                                    │
                        ┌───────────┴───────────┐
                        │ StanceData Resources  │
                        │  • stance_swift.tres  │
                        │  • stance_mountain.tres│
                        │  • stance_storm.tres  │
                        └───────────────────────┘
```

---

## 2. Stance Taxonomy & Identity Specifications

The player can switch dynamically between three combat stances, each with distinct advantages, tradeoffs, and mechanical feels:

### 2.1 Swift Stance (Style of the Falcon)
- **Identity:** Agility, mobility, rapid flurries, quick recovery.
- **Role:** Countering fast enemies, repositioning, and hit-and-run tactics.
- **Initial Modifiers:**
  - Movement Speed: `1.10x`
  - Acceleration: `1.10x`
  - Deceleration: `1.05x`
  - Attack Speed: `1.12x` (shorter startup, active, and recovery phases)
  - Damage: `0.90x` (tradeoff: lower burst per hit)
  - Poise Damage: `0.90x`
  - Dodge Distance: `1.12x`
  - Dodge Recovery: `0.90x` (returns to locomotion/action faster)
  - Parry Window: `1.00x` (standard precision timing preserved)
  - Hitstop Duration: `0.90x`

### 2.2 Mountain Stance (Style of the Granite Sentinel)
- **Identity:** Weight, power, crushing impacts, unshakable posture.
- **Role:** Armor breaking, guard breaking, punishment of heavy brutes and bosses.
- **Initial Modifiers:**
  - Movement Speed: `0.90x` (tradeoff: deliberate footwork)
  - Acceleration: `0.90x`
  - Deceleration: `0.95x`
  - Attack Speed: `0.88x` (longer startup and recovery, heavier commitment)
  - Damage: `1.18x`
  - Poise Damage: `1.30x` (massive posture depletion)
  - Dodge Distance: `0.90x`
  - Dodge Recovery: `1.10x`
  - Parry Window: `1.00x`
  - Hitstop Duration: `1.15x` (visceral impact crunch)

### 2.3 Storm Stance (Style of the Roaring Dragon)
- **Identity:** Aggressive pressure, relentless offensive flow, balanced rhythm.
- **Role:** Mid-range pressure, combo chaining, swarm control.
- **Initial Modifiers:**
  - Movement Speed: `1.00x`
  - Acceleration: `1.00x`
  - Deceleration: `1.00x`
  - Attack Speed: `1.05x`
  - Damage: `1.08x`
  - Poise Damage: `1.05x`
  - Dodge Distance: `1.00x`
  - Dodge Recovery: `1.00x`
  - Parry Window: `1.00x`
  - Hitstop Duration: `1.00x`

---

## 3. Component Architecture & Data Model

### 3.1 `StanceData` (`scripts/combat/stance_data.gd`)
Custom `Resource` defining typed, inspectable parameters:
```gdscript
class_name StanceData
extends Resource

enum StanceType {
    SWIFT,
    MOUNTAIN,
    STORM
}

@export var stance_type: StanceType = StanceType.SWIFT
@export var stance_id: StringName = &"swift"
@export var display_name: String = "Swift Stance"
@export_multiline var description: String = ""

# Locomotion Modifiers
@export var movement_speed_multiplier: float = 1.0
@export var acceleration_multiplier: float = 1.0
@export var deceleration_multiplier: float = 1.0

# Attack Modifiers
@export var attack_speed_multiplier: float = 1.0
@export var damage_multiplier: float = 1.0
@export var poise_damage_multiplier: float = 1.0

# Defense Modifiers
@export var dodge_distance_multiplier: float = 1.0
@export var dodge_recovery_multiplier: float = 1.0
@export var parry_window_multiplier: float = 1.0
@export var hitstop_multiplier: float = 1.0
```

### 3.2 Resource Definitions (`data/characters/`)
- `data/characters/stance_swift.tres`
- `data/characters/stance_mountain.tres`
- `data/characters/stance_storm.tres`

### 3.3 `StanceController` (`scripts/player/stance_controller.gd`)
Node component attached under `Player/Components/StanceController`:
- **State:**
  - `current_stance: StanceData.StanceType`
  - `current_stance_data: StanceData`
  - Preloaded dictionary of `StanceData` resources (`_stances: Dictionary[int, StanceData]`).
- **Signals:**
  - `stance_changed(new_stance: StanceData.StanceType, old_stance: StanceData.StanceType)`
  - Dispatches `EventBus.player_stance_changed(new_stance_id: StringName)`
- **Public API:**
  - `get_current_stance() -> StanceData.StanceType`
  - `get_current_stance_data() -> StanceData`
  - `set_stance(stance: StanceData.StanceType) -> bool`
  - `cycle_stance() -> bool`
  - `can_change_stance() -> bool`
  - Modifiers:
    - `get_movement_speed_multiplier() -> float`
    - `get_acceleration_multiplier() -> float`
    - `get_deceleration_multiplier() -> float`
    - `get_attack_speed_multiplier() -> float`
    - `get_damage_multiplier() -> float`
    - `get_poise_damage_multiplier() -> float`
    - `get_dodge_distance_multiplier() -> float`
    - `get_dodge_recovery_multiplier() -> float`
    - `get_parry_window_multiplier() -> float`
    - `get_hitstop_multiplier() -> float`

---

## 4. Stance Switching Rules & Validation

Stance switching is strictly gated to preserve combat commitment while enabling responsive tactical flow:

### 4.1 Blocked Transition Conditions (Forbidden)
1. **Attack Startup Phase:** `combat_controller.get_attack_phase() == AttackPhase.STARTUP`
2. **Attack Active Phase:** `combat_controller.get_attack_phase() == AttackPhase.ACTIVE`
3. **Heavy Attack Charging:** `combat_controller.is_charging_heavy == true`
4. **Dodge Invulnerability Window:** `defense_controller.is_dodging and defense_controller.is_invulnerable_to_damage`
5. **Active Parry Deflection Window:** `defense_controller.is_parrying and defense_controller.is_in_parry_window()`
6. **Air Attack Active Phase:** In `PlayerAirAttackState` during active strike frames.

### 4.2 Allowed Transition Conditions (Permitted)
1. **Locomotion States:** `Idle`, `Run`, `Jump`, `Fall`, `Land`.
2. **Attack Recovery Phase:** `combat_controller.get_attack_phase() == AttackPhase.RECOVERY` (enables fluid stance cancels and combo branching).
3. **Dodge Recovery Phase:** After I-frames have expired (`t > 0.200s`).
4. **Parry Recovery Phase:** After active deflection window has expired (`t > 0.253s`).

### 4.3 Transition Invariants (State Persistence)
Stance transitions **never**:
- Reset player health, poise, position, or facing direction.
- Reset vertical gravity or fall velocity.
- Re-instantiate player nodes.

---

## 5. System Integration Pipeline

### 5.1 Movement Integration (`PlayerMovement`)
- Calculates effective movement values dynamically:
  ```gdscript
  var speed_mult: float = stance_controller.get_movement_speed_multiplier() if stance_controller != null else 1.0
  var target_speed: float = current_move_axis * config.max_speed * speed_mult
  ```
- Acceleration and deceleration are similarly scaled, maintaining razor-sharp kinematic feel.

### 5.2 Attack Pipeline Integration (`CombatController` & `Hitbox`)
- **Attack Speed Scaling:**
  - Startup, active, and recovery durations are divided by `attack_speed_multiplier`:
    `effective_startup = attack_data.startup_time / attack_speed`
  - Base `AttackData` resource is **never mutated**.
- **Damage & Poise Scaling:**
  - Multipliers are applied to the active `Hitbox`:
    `hitbox.damage_multiplier = charge_multiplier * stance_damage_mult`
    `hitbox.poise_multiplier = poise_charge_multiplier * stance_poise_mult`
  - `Hitbox` constructs `DamageInfo` using these calculated values, feeding cleanly into `HealthComponent` and `PoiseComponent`.

### 5.3 Defense Pipeline Integration (`DefenseController`)
- **Dodge:**
  - `dodge_speed` scales with `dodge_distance_multiplier`.
  - `dodge_duration` scales with `dodge_recovery_multiplier`.
- **Parry:**
  - Active and perfect parry windows maintain exact precision timing (`0.033s - 0.253s` and `0.033s - 0.116s`).
  - Perfect parry poise damage to attacker scales with `poise_damage_multiplier`.
  - Parry recovery scales with `dodge_recovery_multiplier`.

### 5.4 Presentation & Animation Hooks (`PlayerAnimationController`)
- `play_stance_change_feedback(new_stance: StanceData.StanceType)`:
  - **Swift:** Crisp procedural squash/stretch (scale 1.10x, 0.90y returning in 0.12s) with brief cyan hue pulse.
  - **Mountain:** Heavy grounded squash (scale 1.18x, 0.82y returning in 0.15s) with warm amber hue pulse.
  - **Storm:** Energetic dynamic stretch (scale 0.92x, 1.12y returning in 0.12s) with electric violet hue pulse.

### 5.5 Diagnostics & Telemetry (`PlayerDebugOverlay`)
Overlay extended to display:
- Active Stance: Name, Stance ID, Stance Enum.
- Live Multipliers: Speed (`x%.2f`), Atk Speed (`x%.2f`), Damage (`x%.2f`), Poise (`x%.2f`), Dodge (`x%.2f`).
- Real-time Phase, Charge, I-frame, and Parry status.

---

## 6. Testing Strategy & Validation Plan

### 6.1 Automated Test Suite (`tests/test_combat_stances.gd` & `tests/test_stance_runner.tscn`)
Will validate all 42 required Phase 5 criteria:

1. **Stance Data Resources (1-5):**
   - Swift, Mountain, and Storm `.tres` resources load cleanly.
   - Modifiers match specifications.
   - Enums and IDs are valid.
2. **StanceController API (6-12):**
   - Initial stance defaults to `SWIFT`.
   - Explicit `set_stance()` transitions work for all 3 stances.
   - `cycle_stance()` advances cyclically (`SWIFT -> MOUNTAIN -> STORM -> SWIFT`).
   - Local `stance_changed` and `EventBus.player_stance_changed` signals emitted with correct payloads.
3. **Movement Integration (13-15):**
   - Swift increases horizontal target speed and acceleration.
   - Mountain decreases horizontal target speed and acceleration.
   - Storm maintains baseline locomotion.
4. **Attack Speed & Damage Modifiers (16-20):**
   - Attack phase durations decrease in Swift and increase in Mountain.
   - Hitbox damage multiplier reflects stance modifier (Swift 0.90x, Mountain 1.18x, Storm 1.08x).
   - Base `AttackData` resources remain strictly unmutated.
5. **Poise Modifiers (21-23):**
   - Target dummy poise depletion reflects stance modifier (Mountain deals 1.30x poise damage).
6. **Dodge & Defense Modifiers (24-26):**
   - Swift increases dodge velocity/distance and shortens recovery.
   - Mountain applies heavier dodge velocity and recovery.
7. **Parry Integration & Integrity (27-29):**
   - Parry active deflection window is not oversized.
   - Stance switching is blocked during active parry window.
8. **State Machine Safety (30-34):**
   - Stance switching blocked during attack startup.
   - Stance switching blocked during attack active.
   - Stance switching allowed during attack recovery.
   - Stance switching blocked during active dodge I-frames.
   - Stance switching blocked during air attack active frames.
9. **State Persistence (35-38):**
   - Player HP, poise, and position remain unchanged across stance switches.
   - Switching during movement does not freeze or reset velocity.
10. **Full Regression Suite (39-42):**
    - Phase 1 Foundation: 45 / 45 PASS
    - Phase 2 Player Locomotion: 48 / 48 PASS
    - Phase 3 Combat Foundation: 91 / 91 PASS
    - Phase 4 Advanced Combat: 84 / 84 PASS
    - **Total Regression Requirement: 268 / 268 PASS (100%)**

### 6.2 Interactive Arena (`scenes/world/test_stance_room.tscn`)
Dedicated sandbox scene containing:
- Player character with StanceController and all components.
- Stance UI display showing `[ SWIFT ]`, `[ MOUNTAIN ]`, `[ STORM ]`.
- `CombatTestDummy` (measure damage, poise, stagger across stances).
- `CombatTrainingAttacker` (test defense, parry, dodge across stances).
- Platform geometry for air attacks.
- Controls:
  - `TAB` / `C`: Cycle stance
  - `1`, `2`, `3`: Direct stance hotkeys (Swift, Mountain, Storm)
  - `T`: Trigger attacker swing
  - `Y`: Toggle auto-attacker
  - `R`: Reset dummy and attacker
  - `F3`: Toggle diagnostic telemetry overlay

---

## 7. Performance & Memory Target

- **Zero per-frame allocations:** StanceData resources are preloaded and cached at startup; no new Objects, Dictionaries, or Arrays created in `_physics_process`.
- **Target Hardware:** Intel Core i3-1115G4, 12GB RAM, Intel UHD Graphics.
- **Frame Rate:** Locked 60 FPS in GL Compatibility mode with 0 parser errors, 0 runtime errors, and 0 warnings.
