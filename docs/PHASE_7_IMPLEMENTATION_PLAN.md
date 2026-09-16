# Echoes of the Celestial Staff — Phase 7 Implementation Plan
## Celestial Awakening / Transformation Foundation

**Document Version:** 1.0.0  
**Phase:** Phase 7 — Celestial Awakening / Transformation Foundation  
**Target Engine:** Godot 4.7.2 Stable (`4.7.2.stable.official.ed1daf0bf`)  
**Renderer:** GL Compatibility (`gl_compatibility`)  
**Language:** Strict-Typed GDScript  
**Hardware Baseline:** Intel Core i3-1115G4, 12 GB RAM, Intel UHD Graphics, 60 FPS  
**Baseline Test Count:** 427 / 427 Passing (0 Regressions Tolerated)

---

## 1. Architectural Overview & Design Philosophy

### 1.1 Core Principle: Single Player, Layered Modifiers
Celestial Awakening is **NOT**:
- A second player character or duplicate character scene.
- A duplicated combat, movement, or state machine system.
- An entirely separate animation tree or parallel state architecture.

**ONE PLAYER. ONE COMBAT SYSTEM. ONE DEFENSE SYSTEM. ONE MOVEMENT SYSTEM.**  
Celestial Awakening is an ephemeral, data-driven **modifier layer** governed by a dedicated `TransformationController` component. It temporarily alters combat attributes (attack speed, damage, poise damage, hitstop), movement attributes (movement speed, acceleration, deceleration), defense attributes (dodge velocity, dodge recovery), and spirit ability damage, while leaving baseline resources, stance identities, and muscle-memory timing windows (parry and perfect dodge) pristine.

### 1.2 System Interactions
```mermaid
graph TD
    InputManager -->|transformation_activate| TransformationController
    SpiritComponent -->|consume_spirit(100)| TransformationController
    TransformationController -->|TransformationData Multipliers| PlayerMovement
    TransformationController -->|TransformationData Multipliers| CombatController
    TransformationController -->|TransformationData Multipliers| DefenseController
    TransformationController -->|TransformationData Multipliers| SpiritAbilityController
    TransformationController -->|Signal: transformation_started/ended| EventBus
    TransformationController -->|Visual feedback| PlayerAnimationController
    TransformationController -->|Audio cues| AudioManager
    TransformationController -->|Telemetry & Cooldown| SpiritHUD
    TransformationController -->|Debug metrics| PlayerDebugOverlay
    StanceController -.->|Independent Stance Multipliers| PlayerMovement
    StanceController -.->|Independent Stance Multipliers| CombatController
```

---

## 2. Transformation Data Resource (`TransformationData`)

Create `scripts/player/transformation_data.gd` as a strictly typed custom Godot `Resource`.

### 2.1 Properties Schema
```gdscript
class_name TransformationData
extends Resource

@export var transformation_id: StringName = &"celestial_awakening"
@export var display_name: String = "Celestial Awakening"
@export_multiline var description: String = "Channel divine celestial qi to enter an awakened state, empowering martial speed, damage, and mobility."

# Resource & Timing
@export var spirit_cost: float = 100.0
@export var duration: float = 12.0

# Locomotion Modifiers
@export var move_speed_multiplier: float = 1.10
@export var acceleration_multiplier: float = 1.10
@export var deceleration_multiplier: float = 1.10

# Combat Modifiers
@export var attack_speed_multiplier: float = 1.10
@export var damage_multiplier: float = 1.15
@export var poise_damage_multiplier: float = 1.10
@export var hitstop_multiplier: float = 1.05

# Defense Modifiers (Velocity & Recovery only; I-frames & Parry windows invariant)
@export var dodge_velocity_multiplier: float = 1.05
@export var dodge_recovery_multiplier: float = 0.95

# Spirit Ability Modifiers
@export var spirit_ability_damage_multiplier: float = 1.10

# Presentation Profiles
@export var visual_profile_id: StringName = &"celestial_awakening"
@export var audio_profile_id: StringName = &"celestial_awakening"
```

### 2.2 Celestial Awakening Resource Asset
Create `data/characters/transformation_celestial_awakening.tres` populated with the baseline tuning parameters above.

---

## 3. Transformation Controller Component (`TransformationController`)

Attach to `Player/Components/TransformationController` in `scenes/player/player.tscn`.

### 3.1 Lifecycle States
```gdscript
enum LifecycleState {
    INACTIVE,
    ACTIVATING,
    ACTIVE,
    ENDING
}
```

### 3.2 State Machine & Gatekeeping Rules
Activation is evaluated via `can_activate() -> bool`:
- **Allowed In:**
  - Locomotion states: `Idle`, `Run`, `Jump`, `Fall`, `Land`.
  - Combat recovery: Attack `Recovery` phase (`can_cancel_attack() == true`).
- **Strictly Blocked In:**
  - Attack `Startup` and `Active` phases.
  - Heavy charge loop (`is_charging_heavy == true`).
  - Active Dodge I-frames (`is_dodging && is_invulnerable_to_damage`).
  - Active Parry deflection window (`is_parrying && is_in_parry_window()`).
  - Active Spirit Ability cast (`is_casting`).
  - Existing active transformation (`is_active() == true` or `current_state != INACTIVE`).
  - Insufficient Spirit: Player Spirit balance < `transformation_data.spirit_cost` (100.0).

### 3.3 Atomic Activation Sequence
1. User presses `ACTION_TRANSFORMATION_ACTIVATE` (or calls `activate()`).
2. Controller calls `can_activate()`. If false, emits `activation_failed(reason)` and returns `false`.
3. Calls `spirit_component.consume_spirit(transformation_data.spirit_cost)`. If false, fails safely.
4. Transitions state to `ACTIVATING`, then immediately `ACTIVE`.
5. Starts numeric countdown timer `_remaining_duration = transformation_data.duration`.
6. Triggers visual and audio cues (`play_transformation_activate()`).
7. Emits `transformation_started(transformation_id, duration)` locally and on `EventBus`.
8. Returns `true`.

### 3.4 Duration Processing & Safe Deactivation
- In `_physics_process(delta)`:
  - If `current_state == LifecycleState.ACTIVE`:
    - Decrements `_remaining_duration -= delta`.
    - If `_remaining_duration <= 0.0`:
      - Sets `_remaining_duration = 0.0`.
      - Calls `deactivate()`.
- `deactivate()`:
  - Idempotency guard: If `current_state == LifecycleState.INACTIVE`, return immediately.
  - Transitions to `ENDING`, then `INACTIVE`.
  - Removes all active modifiers (subsequent multiplier queries return `1.0`).
  - Calls `play_transformation_end()`.
  - Emits `transformation_ended(transformation_id)` locally and on `EventBus`.
  - Preserves health, poise, world position, velocity, and current stance without alteration.

---

## 4. Modifier Pipeline Integration

### 4.1 Locomotion Integration (`PlayerMovement`)
Horizontal speed, acceleration, and deceleration compose multiplicatively:
$$\text{Effective Speed} = \text{Base Speed} \times \text{Stance Speed Mult} \times \text{Trans Speed Mult}$$
$$\text{Effective Accel} = \text{Base Accel} \times \text{Stance Accel Mult} \times \text{Trans Accel Mult}$$
$$\text{Effective Decel} = \text{Base Decel} \times \text{Stance Decel Mult} \times \text{Trans Decel Mult}$$

### 4.2 Combat Integration (`CombatController` & `Hitbox`)
- Attack Phase Timers:
  $$\text{Startup Time} = \frac{\text{Base Startup}}{\text{Stance Attack Speed} \times \text{Trans Attack Speed}}$$
  $$\text{Active Time} = \frac{\text{Base Active}}{\text{Stance Attack Speed} \times \text{Trans Attack Speed}}$$
- Damage & Poise Payload:
  $$\text{Damage} = \text{Base Damage} \times \text{Charge Mult} \times \text{Stance Dmg Mult} \times \text{Trans Dmg Mult}$$
  $$\text{Poise Damage} = \text{Base Poise} \times \text{Charge Poise Mult} \times \text{Stance Poise Mult} \times \text{Trans Poise Mult}$$
- Hitstop:
  $$\text{Hitstop Duration} = \text{Base Hitstop} \times \text{Trans Hitstop Mult}$$

### 4.3 Defense Integration (`DefenseController`)
- Dodge Impulse:
  $$\text{Dodge Velocity} = \text{Base Dodge Speed} \times \text{Stance Dodge Mult} \times \text{Trans Dodge Velocity Mult}$$
- Dodge Recovery:
  $$\text{Effective Recovery} = \text{Base Recovery} \times \text{Stance Recovery Mult} \times \text{Trans Dodge Recovery Mult}$$
- **Invariant Timing Rule:**
  - `dodge_iframe_start`, `dodge_iframe_end`: **IMMUTABLE** (preserving learned evasion timing).
  - `perfect_dodge_window`: **IMMUTABLE** (preserving 4-frame / 67ms window).
  - `parry_window`, `perfect_parry_window`: **IMMUTABLE** (preserving precision deflection window).

### 4.4 Spirit Ability Integration (`SpiritAbilityController`)
- Projectile (`SpiritProjectile` / Celestial Arc) & Area (`_execute_area_shockwave` / Heavenly Pulse):
  $$\text{Ability Damage} = \text{Base Damage} \times \text{Trans Spirit Ability Dmg Mult}$$
- Mobility (`Cloud Step`): Burst velocity and collision checks remain stable and responsive.
- Spirit Costs & Cooldowns: **IMMUTABLE** (costs and cooldown timers are not altered by transformation).

### 4.5 Stance Invariance & Stacking
- Current stance is completely preserved across transformation activation and expiration.
- Multipliers stack cleanly:
  - Swift + Awakening: High speed & rapid flurry attacks.
  - Mountain + Awakening: Crushing poise damage & heavy hyper-armor blows.
  - Storm + Awakening: Balanced martial empowerment.
- No bespoke combination states (e.g. `SwiftAwakening`); pure mathematical composition.

---

## 5. Input, UI, Presentation & Audio

### 5.1 Input Mapping (`InputManager`)
- Register `ACTION_TRANSFORMATION_ACTIVATE = &"transformation_activate"`.
- Default binding: `KEY_F` (and secondary `KEY_V`), keeping WASD, JKL, Shift, Q, and 123 free.
- Fully registered in `InputManager.ALL_ACTIONS`.

### 5.2 EventBus Signals
Add to `scripts/core/event_bus.gd`:
```gdscript
signal transformation_started(transformation_id: StringName, duration: float)
signal transformation_ended(transformation_id: StringName)
signal transformation_state_changed(state: int)
```

### 5.3 Presentation & Visual Feedback (`PlayerAnimationController`)
Lightweight, procedural presentation designed for Intel UHD Graphics (zero performance spikes):
- Activation flash: Golden/cyan radiance tween on `visuals_root`.
- Active aura: Procedural subtle oscillating scale / color modulation (`#F1C40F` celestial gold and `#00FFFF` divine cyan).
- Deactivation cue: Smooth return to baseline stance tint.
- Procedural squash/stretch impulse on activation.

### 5.4 Audio Hooks (`AudioManager`)
- Safe hooks for `play_sfx("transformation_activate")` and `play_sfx("transformation_end")`.
- Graceful warning logging on missing audio streams without crashes.

### 5.5 UI & Debug Telemetry
- **`SpiritHUD` (`scenes/ui/spirit_hud.tscn` & `scripts/ui/spirit_hud.gd`):**
  - Add Awakening Card with state text:
    - Inactive: `[AWAKENING READY]` (when Spirit == 100) or `[INSUFFICIENT SPIRIT]`.
    - Active: `[CELESTIAL AWAKENING]` with remaining duration countdown (e.g. `11.4s`) and progress bar.
- **`PlayerDebugOverlay` (`scripts/player/player_debug_overlay.gd`):**
  - Displays: Transformation state (`INACTIVE`, `ACTIVATING`, `ACTIVE`, `ENDING`), remaining duration, duration ratio %, and active transformation multipliers.

---

## 6. Interactive Testing Gym (`test_transformation_room.tscn`)

Create `scenes/world/test_transformation_room.tscn` and `scripts/world/test_transformation_room.gd`:
- Full test arena containing:
  - `PlayerController` with all subsystems.
  - 3 `CombatTestDummy` instances.
  - 1 `CombatTrainingAttacker` for parry testing.
  - Platforms, obstacle walls, and boundary colliders.
  - Live `SpiritHUD` and `PlayerDebugOverlay`.
  - On-screen control legends:
    - `T`: Restore Spirit (+100)
    - `F`: Activate Celestial Awakening
    - `1 / 2 / 3`: Spirit Abilities
    - `C`: Cycle Stance
    - `R`: Reset Dummies
    - `Y`: Trigger Attacker
    - `F3`: Toggle Telemetry

---

## 7. Automated Testing Plan (`test_transformation_runner.tscn`)

Create `tests/test_transformation_runner.tscn` and `tests/test_transformation.gd` implementing at least 60 targeted assertions across 8 test suites:

1. **Resource & Data Validation (DATA-01 to 05):**
   - `TransformationData` loads cleanly.
   - Initial resource has 100 Spirit cost, 12s duration, valid multipliers.
2. **Component Lifecycle & Timing (CTRL-01 to 10):**
   - Component initialization, inactive state, duration countdown, ratio calculation, clean expiration, idempotency.
3. **Spirit Consumption & Transaction (COST-01 to 06):**
   - Atomic consumption of 100 Spirit; rejection when Spirit < 100; no duplicate consumption.
4. **State Machine Gatekeeping (GATE-01 to 12):**
   - Permitted in Idle, Run, Jump, Fall, Attack Recovery.
   - Blocked in Attack Startup, Active, Heavy Charge, Dodge I-frames, Active Parry, Active Spirit Ability.
5. **Stance Integration & Stacking (STANCE-01 to 08):**
   - Stacking with Swift, Mountain, Storm; stance preservation across activation and expiration.
6. **Combat & Defense Multiplier Verification (COMBAT-01 to 12):**
   - Light attack, heavy attack, charged attack, and air attack damage & poise scaling.
   - Dodge velocity and recovery scaling; parry and perfect dodge windows strictly unchanged.
7. **Spirit Ability Synergy (ABILITY-01 to 06):**
   - Celestial Arc, Heavenly Pulse damage scaling; cooldown and costs unaffected.
8. **Arena & System Integration (INT-01 to 06):**
   - EventBus signals, HUD bindings, debug overlay, clean room load.
9. **Zero-Regression Suite (REG-01 to 06):**
   - Phase 1 (45/45), Phase 2 (48/48), Phase 3 (91/91), Phase 4 (84/84), Phase 5 (64/64), Phase 6 (95/95) all 100% PASS.

---

## 8. Verification & Performance Criteria

- **Zero Regression:** All 427 previous tests + 60+ new Phase 7 tests = **487+ tests passing**.
- **Static Quality:** 0 parser errors, 0 runtime errors, 0 warnings under `--headless --editor --quit`.
- **Target Hardware:** Stable 60 FPS on Intel UHD Graphics baseline with 0 runtime memory leaks.
- **Git Commit:** Review diff, verify working tree, and commit as: `Phase 7: implement celestial awakening`.
