# Phase 6 Implementation Plan: Spirit Abilities

**Project:** Echoes of the Celestial Staff  
**Engine:** Godot 4.7.2 Stable (`4.7.2.stable.official.ed1daf0bf`)  
**Renderer:** GL Compatibility  
**Language:** Strict Typed GDScript  
**Target Platform:** Windows PC (Intel Core i3-1115G4, 12 GB RAM, Intel UHD Graphics, 60 FPS target)  
**Status:** In Preparation (Pre-Implementation Planning)  

---

## 1. Executive Summary & Objective

Phase 6 introduces the **Spirit Ability Foundation** for *Echoes of the Celestial Staff*. Spirit Abilities are supernatural martial techniques that draw upon gathered celestial essence (Spirit) to complement staff-based melee combat.

### Core Objectives:
1. Implement a decoupled, modular, data-driven ability layer via `SpiritAbilityController` and `SpiritAbilityData`.
2. Implement a robust `SpiritComponent` managing celestial essence (clamped between `0.0` and `max_spirit = 100.0`, transactional consumption, combat-based restoration).
3. Implement an allocation-free numerical cooldown management system.
4. Implement three original prototype abilities exercising different architectural domains:
   - **Celestial Arc** (Projectile / ranged pressure)
   - **Heavenly Pulse** (Circular AoE / multi-target crowd control)
   - **Cloud Step** (Supernatural directional mobility burst respecting world geometry)
5. Integrate with the existing combat, defense, stance, movement, and animation pipelines without duplicating systems.
6. Zero regression across the existing 332/332 test baseline; 0 parser errors, 0 runtime errors, 0 warnings.

---

## 2. Architecture & Component Blueprint

```
Player (CharacterBody2D)
├── CollisionShape2D
├── Visuals (Node2D)
├── Camera2D
├── Components (Node)
│   ├── PlayerMovement
│   ├── PlayerAnimationController
│   ├── PlayerRespawn
│   ├── CombatController
│   ├── DefenseController
│   ├── StanceController
│   ├── HealthComponent
│   ├── PoiseComponent
│   ├── SpiritComponent              <-- [NEW in Phase 6]
│   └── SpiritAbilityController       <-- [NEW in Phase 6]
├── Combat (Node2D)
│   ├── PlayerHitbox (Area2D)
│   └── PlayerHurtbox (Area2D)
└── StateMachine (Node)
    ├── Idle, Run, Jump, Fall, Land
    ├── Attack, HeavyAttack, AirAttack
    ├── Dodge, Parry
    └── SpiritAbility                 <-- [NEW in Phase 6: PlayerSpiritAbilityState]
```

### 2.1 Component Responsibilities
- **`SpiritComponent` (`scripts/player/spirit_component.gd`):**
  - Tracks `current_spirit` and `max_spirit` (default `100.0`).
  - Strict clamping: `0.0 <= current_spirit <= max_spirit`.
  - Transactional methods: `has_spirit(amount) -> bool`, `consume_spirit(amount) -> bool` (atomic check-and-consume), `restore_spirit(amount) -> void`, `set_spirit(amount) -> void`.
  - Emits local `spirit_changed(current, max)` and broadcasts to `EventBus.player_spirit_changed(current, max)`.
  - Combat restoration hooks: Restores configured Spirit upon successful combat hits (Light: +4.0, Heavy: +8.0, Perfect Parry: +10.0), with duplicate hit prevention.
- **`SpiritAbilityData` (`scripts/abilities/spirit_ability_data.gd`):**
  - Custom `Resource` defining: `ability_id`, `display_name`, `description`, `ability_type` (Enum: `PROJECTILE`, `AREA`, `MOBILITY`, `BUFF`), `spirit_cost`, `cooldown`, `startup_time`, `active_time`, `recovery_time`, `damage`, `poise_damage`, `knockback_force`, `hitstop_duration`, `is_parryable`, `is_dodgeable`, `can_use_grounded`, `can_use_airborne`, `interruptible`, `movement_multiplier`.
- **`SpiritAbilityController` (`scripts/player/spirit_ability_controller.gd`):**
  - Stores equipped ability slots (Slots 1, 2, 3 mapped to `spirit_ability_1`, `spirit_ability_2`, `spirit_ability_3`).
  - Tracks ability cooldowns via lightweight numeric floats (`_cooldown_timers: Dictionary[StringName, float]`).
  - Validates cast eligibility (`can_cast_ability`).
  - Manages casting lifecycle phases (`READY`, `STARTUP`, `ACTIVE`, `RECOVERY`, `COOLDOWN`).
  - Handles ability execution callbacks:
    - Celestial Arc: spawns and activates `SpiritProjectile`.
    - Heavenly Pulse: triggers circular area shockwave against nearby target hurtboxes.
    - Cloud Step: applies high-speed directional velocity burst through `PlayerMovement`.
  - Dispatches local signals: `ability_started`, `ability_activated`, `ability_completed`, `ability_failed`.
- **`PlayerSpiritAbilityState` (`scripts/player/states/player_spirit_ability_state.gd`):**
  - State machine integration state.
  - Entered when an ability begins execution; updates ability timers and motion; exits cleanly to `Idle`, `Run`, or `Fall` when ability recovery ends.
  - Allows recovery phase cancellation into `Dodge` or `Parry` if configured.

---

## 3. Prototype Abilities Specification

### 3.1 Ability 1 — Celestial Arc
- **Type:** `PROJECTILE`
- **Data Resource:** `data/abilities/ability_celestial_arc.tres`
- **Concept:** Staff releases a compressed crescent wave of spiritual force in the facing direction.
- **Tuning:**
  - Spirit Cost: `20.0`
  - Cooldown: `2.0s`
  - Startup: `0.08s` | Active: `0.05s` | Recovery: `0.15s`
  - Base Damage: `18.0` | Poise Damage: `15.0` | Knockback: `Vector2(140.0, -20.0)`
  - Hitstop: `0.04s` (light hitstop via `GameManager.apply_hitstop`)
  - Ground & Airborne: Allowed in both
- **Projectile Infrastructure:**
  - Node: `scenes/effects/spirit_projectile.tscn` with script `scripts/abilities/spirit_projectile.gd`.
  - Area2D on Layer 4 (`PlayerHitbox`, mask 64 `EnemyHurtbox`).
  - Travels horizontally at `520.0 px/s` along `facing_direction`.
  - Max travel distance / lifespan: `1.2s` or until boundary/wall contact.
  - Delivers `DamageInfo` payload to target Hurtbox; tracks `_hit_hurtboxes` to ensure each target is damaged only once.

### 3.2 Ability 2 — Heavenly Pulse
- **Type:** `AREA`
- **Data Resource:** `data/abilities/ability_heavenly_pulse.tres`
- **Concept:** Drives spiritual force through the staff into a circular 360-degree shockwave.
- **Tuning:**
  - Spirit Cost: `30.0`
  - Cooldown: `4.0s`
  - Startup: `0.12s` | Active: `0.10s` | Recovery: `0.22s`
  - Base Damage: `24.0` | Poise Damage: `35.0` (heavy posture break) | Knockback: `Vector2(180.0, -40.0)`
  - Hitstop: `0.08s` (medium hitstop)
  - Ground & Airborne: Grounded only (`can_use_grounded = true`, `can_use_airborne = false`)
- **Area Infrastructure:**
  - Circular Area2D hit zone (`radius = 64.0 px`) centered on player.
  - Queries overlapping hurtboxes; each target hurtbox receives damage exactly once per activation.
  - Distant targets outside radius are completely unaffected.

### 3.3 Ability 3 — Cloud Step
- **Type:** `MOBILITY`
- **Data Resource:** `data/abilities/ability_cloud_step.tres`
- **Concept:** High-speed supernatural directional repositioning burst.
- **Tuning:**
  - Spirit Cost: `25.0`
  - Cooldown: `5.0s`
  - Startup: `0.033s` | Active: `0.18s` | Recovery: `0.15s`
  - Damage: `0.0` | Poise Damage: `0.0` | Hitstop: `0.0`
  - Ground & Airborne: Allowed in both
- **Mobility & Collision Rules:**
  - Directional: Follows movement input vector, or facing direction if neutral.
  - Applies high-speed velocity impulse (`550.0 px/s`) via `CharacterBody2D.move_and_slide()`.
  - **Collision Safety:** World collision (`collision_mask = 1`) remains 100% active at all times. Cannot pass through solid geometry, walls, or map boundaries.
  - **No Dodge Collision / Perfect Dodge Confusion:** Cloud Step does NOT grant automatic I-frames or perfect-dodge status. It is purely resource-based repositioning.

---

## 4. Ability Lifecycle & State Machine Gatekeeping

### 4.1 Lifecycle Phases
$$\text{READY} \xrightarrow{\text{Validated Request}} \text{STARTUP} \xrightarrow{t \ge \text{startup}} \text{ACTIVE} \xrightarrow{t \ge \text{active}} \text{RECOVERY} \xrightarrow{t \ge \text{recovery}} \text{READY (or COOLDOWN)}$$

1. **Validation & Cost Commitment:**
   - Ability request checked for equipped slot, cooldown expiry, spirit sufficiency, state permissions, and environment (grounded vs. airborne).
   - If valid, Spirit is consumed immediately on commit.
   - Cooldown timer starts immediately.
2. **Gatekeeping Restrictions:**
   - **BLOCKED during:** Attack `STARTUP`, attack `ACTIVE`, heavy attack charging, dodge I-frames (`defense.is_invulnerable_to_damage`), active parry deflection window, and another active ability.
   - **ALLOWED during:** `Idle`, `Run`, `Jump`, `Fall`, `Land`, and attack `RECOVERY` (enables seamless ability-cancel sequences).
3. **Stance Invariance:**
   - Abilities function identically across `SWIFT`, `MOUNTAIN`, and `STORM` stances.
   - Base damage, poise damage, and Spirit costs remain invariant to avoid unintended stat skewing.

---

## 5. Input, UI, and Visual Feedback

### 5.1 Input Action Mapping
`InputManager` already registers:
- `ability_1` (`KEY_1`) -> Celestial Arc
- `ability_2` (`KEY_2`) -> Heavenly Pulse
- `ability_3` (`KEY_3`) -> Cloud Step
- `ability_4` (`KEY_4`) -> Reserved for Phase 7 Transformation / Future

### 5.2 Development HUD & Diagnostics
- **Spirit HUD (`scenes/ui/spirit_hud.tscn`):**
  - Real-time Spirit Bar (`Current / Max`).
  - Three ability slot cards showing ability name, spirit cost, and live cooldown remaining (or `READY`).
- **`PlayerDebugOverlay`:**
  - Extended to display: `Spirit: current/max (ratio%)`, `Active Ability: ID & Phase`, and `Slots 1-3 Cooldowns`.
- **Visuals:**
  - Procedural tween feedback: Crescent projectile for Celestial Arc, expanding circular shockwave for Heavenly Pulse, horizontal motion blur/squash for Cloud Step.

---

## 6. Testing & Verification Strategy

### 6.1 Automated Test Suite (`tests/test_spirit_abilities.gd` & `tests/test_spirit_runner.tscn`)
Will cover 66 individual assertions across:
1. `SpiritComponent`: Max spirit, current spirit, consume, restore, upper clamp, lower clamp, `spirit_changed` signal.
2. Ability Data Resources: Loading, valid costs, cooldowns, timings.
3. Ability Controller: Initialization, request validation, cost consumption, cooldown countdown, return to ready.
4. Celestial Arc: Spawning, right/left facing, travel, hurtbox collision, damage, poise damage, expiration, single-hit rule.
5. Heavenly Pulse: Activation, nearby target hit, distant target unaffected, multi-target hit, single-hit per target, poise break.
6. Cloud Step: Start, directionality, velocity, solid wall collision preservation, return to movement, no accidental perfect dodge.
7. State Gatekeeping: Blocked during attack active, dodge active, parry active, active ability; allowed in neutral and recovery.
8. Stance Compatibility: Verified across Swift, Mountain, and Storm with stable damage and spirit costs.
9. Combat Spirit Gain: Light hit (+4), heavy hit (+8), perfect parry (+10), clamp adherence, duplicate hit prevention.
10. Full Regression: Phase 1 (45), Phase 2 (48), Phase 3 (91), Phase 4 (84), Phase 5 (64) -> All 332 tests must pass 100%.

### 6.2 Interactive Sandbox Arena (`scenes/world/test_spirit_room.tscn`)
- Arena with Player, multiple `CombatTestDummy` instances, `CombatTrainingAttacker`, solid obstacle wall for Cloud Step validation, Spirit HUD, and control overlay.
- Hotkeys: `1`, `2`, `3` for abilities; `R` to reset dummies; `T` to restore Spirit; `F3` for debug overlay.
