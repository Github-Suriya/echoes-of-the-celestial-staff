# Echoes of the Celestial Staff — Phase 8 Implementation Plan: Enemy AI Foundation

**Document Version:** 1.0.0  
**Target Engine:** Godot 4.7.2 Stable (`4.7.2.stable.official.ed1daf0bf`)  
**Renderer:** GL Compatibility (`gl_compatibility`)  
**Target Hardware:** Intel Core i3-1115G4, 12GB RAM, Intel UHD Graphics, 60 FPS Target  
**Status:** PROPOSED — Awaiting User Approval  

---

## 1. Executive Summary & Phase Objective

The objective of **Phase 8** is to establish the reusable, extensible **Enemy AI Foundation** for *Echoes of the Celestial Staff*. This phase does not build a complete enemy roster or boss encounters; rather, it creates the standardized architecture that all future standard enemies, elite units, minibosses, and bosses will build upon.

### Architectural Imperatives:
1. **Reuse Existing Combat Pipeline:** Enemies must interact seamlessly through the existing `Hitbox` (Layer 5/16), `Hurtbox` (Layer 7/64), `DamageInfo`, `HealthComponent`, and `PoiseComponent` architecture. No duplicate damage mechanisms.
2. **Zero Player Regression:** Player combat, defense (parries, dodges, I-frames), stances, spirit abilities, and transformation must remain 100% functional (540/540 existing tests passing).
3. **Data-Driven Decoupling:** All balance values (speed, health, poise, ranges, cooldowns, attack timings) reside in `EnemyData` and `EnemyAttackData` resources.
4. **Hardware Performance (<4ms AI Budget):** Throttled perception updates (10–15 Hz), no expensive per-frame `get_tree()` searches, no global A* path recalculation spikes, lightweight 2D physics.

---

## 2. Enemy Architecture & Component Hierarchy

### 2.1 Scene Composition (`scenes/enemies/enemy_base.tscn`)

```
EnemyBase (CharacterBody2D) [scripts/enemies/enemy_controller.gd]
├── CollisionShape2D (CapsuleShape2D, collision_layer = 4 [Layer 3], collision_mask = 1 [World])
├── Visuals (Node2D)
│   ├── Body (ColorRect)
│   ├── Eye (ColorRect)
│   ├── Arm (ColorRect)
│   └── Indicator (ColorRect - Telegraph/Alert glyph)
├── Combat (Node2D)
│   ├── EnemyHitbox (Area2D, collision_layer = 16 [Layer 5], collision_mask = 32 [PlayerHurtbox])
│   │   └── CollisionShape2D (RectangleShape2D)
│   └── EnemyHurtbox (Area2D, collision_layer = 64 [Layer 7], collision_mask = 0)
│       └── CollisionShape2D (CapsuleShape2D)
├── Components (Node)
│   ├── HealthComponent (scripts/combat/health_component.gd)
│   ├── PoiseComponent (scripts/combat/poise_component.gd)
│   ├── EnemyPerception (scripts/enemies/enemy_perception.gd)
│   ├── EnemyMovement (scripts/enemies/enemy_movement.gd)
│   ├── EnemyCombatController (scripts/enemies/enemy_combat_controller.gd)
│   └── EnemyAnimationController (scripts/enemies/enemy_animation_controller.gd)
├── StateMachine (scripts/systems/state_machine.gd)
│   ├── Idle (scripts/enemies/states/enemy_idle_state.gd)
│   ├── Patrol (scripts/enemies/states/enemy_patrol_state.gd)
│   ├── Alert (scripts/enemies/states/enemy_alert_state.gd)
│   ├── Chase (scripts/enemies/states/enemy_chase_state.gd)
│   ├── Combat (scripts/enemies/states/enemy_combat_state.gd)
│   ├── Hit (scripts/enemies/states/enemy_hit_state.gd)
│   ├── Stagger (scripts/enemies/states/enemy_stagger_state.gd)
│   └── Dead (scripts/enemies/states/enemy_dead_state.gd)
└── StatusLabel (Label - Diagnostics & Telemetry)
```

---

## 3. Data Definitions (`EnemyData` & `EnemyAttackData`)

### 3.1 `EnemyData` (`scripts/enemies/enemy_data.gd`)
Custom `Resource` defining actor statistics and behavioral parameters:
- **Identification:** `enemy_id: StringName`, `display_name: String`
- **Vitality & Posture:**
  - `max_health: float = 80.0`
  - `max_poise: float = 30.0`
  - `stagger_duration: float = 1.4`
  - `poise_regen_delay: float = 2.5`
  - `poise_regen_rate: float = 15.0`
- **Locomotion:**
  - `patrol_speed: float = 50.0`
  - `chase_speed: float = 110.0`
  - `acceleration: float = 500.0`
  - `deceleration: float = 700.0`
  - `gravity: float = 980.0`
- **Perception & Ranges:**
  - `detection_range: float = 180.0`
  - `lose_target_range: float = 260.0`
  - `preferred_combat_distance: float = 34.0`
  - `attack_range: float = 42.0`
  - `alert_duration: float = 0.35`
- **Patrol:**
  - `patrol_distance: float = 90.0`
  - `patrol_wait_time: float = 1.2`
- **Combat & Rewards:**
  - `attack_cooldown: float = 1.8`
  - `bounty_qi: int = 10`
  - `default_attack: EnemyAttackData`

### 3.2 `EnemyAttackData` (`scripts/enemies/enemy_attack_data.gd`)
Extends `AttackData` directly to maintain 100% polymorphic compatibility with `Hitbox` and `DamageInfo`:
- Inherits: `attack_id`, `damage`, `poise_damage`, `knockback_force`, `startup_time`, `active_time`, `recovery_time`, `hitstop_duration`, `is_parryable`, `is_dodgeable`, `is_interruptible`.
- Additional fields:
  - `attack_range: float = 42.0`
  - `cooldown: float = 1.8`
  - `telegraph_duration: float = 0.40`
  - `hitbox_size: Vector2 = Vector2(36.0, 32.0)`
  - `hitbox_offset: Vector2 = Vector2(24.0, -20.0)`

Canonical resource: `data/enemies/attacks/attack_celestial_guard_slash.tres`  
Canonical enemy data: `data/enemies/enemy_celestial_guard.tres`

---

## 4. Subsystem Specifications

### 4.1 Perception System (`scripts/enemies/enemy_perception.gd`)
- **Execution Budget:** Throttled update interval (`update_interval = 0.08s`, ~12.5 Hz). Does NOT perform full scene scans every frame.
- **Target Tracking:** Default target is `PlayerController`. Caches target reference.
- **Line-of-Sight Check:** Evaluates 2D raycast against Layer 1 (Solid World). If solid geometry obstructs direct line to player, detection fails.
- **Target Validity:** Validates `is_instance_valid(target)` and ensures `not target.health_component.is_dead()`.
- **Target Acquisition & Loss:**
  - Acquire: Target within `detection_range` AND line-of-sight clear -> emits `target_detected(target)`.
  - Loss: Target exceeds `lose_target_range` OR target invalid/dead -> emits `target_lost()`.

### 4.2 Locomotion & Navigation Foundation (`scripts/enemies/enemy_movement.gd`)
- **Direct 2D Steering:** Horizontal velocity application with gravity and floor snapping.
- **Why Direct Steering over NavigationAgent2D:**
  - For standard 2D platformer enemies, Godot's `NavigationAgent2D` introduces unnecessary polygon baking, path server polling, and synchronization overhead for simple horizontal platform traversal.
  - Direct horizontal steering with raycast ledge/wall detection provides 100% deterministic, high-performance behavior well within the Intel Core i3 budget.
- **Patrol Boundaries:** Tracks left and right waypoints relative to spawn origin (`spawn_x - patrol_distance` to `spawn_x + patrol_distance`).
- **Hysteresis & Facing:** Uses a minimum velocity threshold (10.0 px/s) to prevent rapid left/right flipping or oscillation when holding combat distance.

### 4.3 Combat Controller & Attack Lifecycle (`scripts/enemies/enemy_combat_controller.gd`)
- **Attack Machine:** `READY` -> `TELEGRAPH` (startup/windup) -> `ACTIVE` (hitbox enabled) -> `RECOVERY` (hitbox disabled) -> `COOLDOWN`.
- **Hitbox Synchronization:** Hitbox is active ONLY during the `ACTIVE` window.
- **Defensive Interception Integration:**
  - Implements `interrupt_attack()`: Called directly when Yuan executes a Perfect Parry.
  - Immediately deactivates hitbox, aborts attack, and transitions enemy into interrupted stun state (`attack_interrupted` signal).

### 4.4 Hit Reaction, Poise & Stagger Integration
- **Damage Reaction:** Hurtbox delegates damage to `HealthComponent` and poise reduction to `PoiseComponent`. Emits hit flash and knockback via `EnemyAnimationController`.
- **Stagger:** When poise drops to 0, `PoiseComponent` emits `stagger_started(duration)`.
  - State machine transitions immediately to `Stagger`.
  - AI logic, movement, and attacks are completely disabled.
  - Golden visual flash displayed.
  - When `stagger_ended` fires -> returns to `Combat` or `Chase`.

### 4.5 Death Lifecycle
- `HealthComponent.died` triggers `EnemyController.die()`.
- Idempotent: Calling `die()` multiple times produces no side-effects.
- Deactivates Hitbox and disables Hurtbox collision.
- Stops movement (`velocity = Vector2.ZERO`) and halts state machine.
- Emits `EventBus.enemy_died(self, bounty_qi)`.

---

## 5. Enemy State Machine Graph

```
           [Spawn]
              │
              ▼
           ┌──────┐
      ┌───►│ IDLE │◄───┐
      │    └──┬───┘    │
Timer │       │ Timer  │ Target Lost
      │       ▼        │
      │   ┌────────┐   │
      └───┤ PATROL ├───┘
          └───┬────┘
              │ Target Detected
              ▼
          ┌───────┐
          │ ALERT │
          └───┬───┘
              │ Alert Timer Finished
              ▼
          ┌───────┐
      ┌──►│ CHASE │◄──┐
      │   └───┬───┘   │ Target Moves Out of Range
Target│       │ Within Attack Range
Lost  │       ▼       │
      │   ┌────────┐  │
      └───┤ COMBAT ├──┘
          └───┬────┘
              │
    ┌─────────┼─────────┐
    │ Hit     │ Poise=0 │ HP=0
    ▼         ▼         ▼
 ┌─────┐ ┌─────────┐ ┌──────┐
 │ HIT │ │ STAGGER │ │ DEAD │
 └─────┘ └─────────┘ └──────┘
```

---

## 6. Primary Prototype: Celestial Guard

The **Celestial Guard** is Yuan's first technical prototype enemy:
- **Role:** Sturdy frontline melee disciple automaton.
- **Stats:** 80 HP, 30 Poise, 1.4s Stagger Duration, 50 px/s Patrol, 110 px/s Chase.
- **Attack:** Celestial Guard Slash (15 Damage, 20 Poise Damage, 0.4s Telegraph, 0.12s Active, 0.4s Recovery, 1.8s Cooldown). Parryable and dodgeable.
- **Visuals:** Placeholder ColorRects with dynamic eye tracking and procedural squash/stretch.

---

## 7. Test Strategy & Verification Plan

### 7.1 Automated Test Suite (`tests/test_enemy_runner.tscn` & `tests/test_enemy.gd`)
Targeting **100+ comprehensive automated tests** across 11 distinct categories:
1. **Enemy Data:** Resource loading, field population, defaults, attack data inheritance.
2. **Controller Lifecycle:** Node discovery, initialization, facing API, reset logic.
3. **State Machine Transitions:** Idle -> Patrol -> Alert -> Chase -> Combat -> Hit -> Stagger -> Dead. Protection against invalid transitions.
4. **Perception System:** Range detection, loss radius, line-of-sight obstruction, invalid target handling, interval throttling.
5. **Patrol Behavior:** Horizontal traversal, boundary turning, pause timer.
6. **Chase Behavior:** Target pursuit, facing orientation, deceleration at combat distance, target loss.
7. **Combat Positioning:** Distance maintenance, deadzone jitter prevention.
8. **Attack Lifecycle:** Telegraph -> Active -> Recovery -> Cooldown. Hitbox active window exclusivity. No spamming during cooldown.
9. **Hit Reaction & Poise:** Damage application, knockback application, poise reduction, stagger lock, stagger recovery.
10. **Death Mechanics:** Idempotent death, collision disabling, AI stop, signal broadcast.
11. **Multi-Enemy Independence:** Two distinct instances running concurrently with independent states, targets, cooldowns, and health pools.

### 7.2 Full Project Regression Baseline
- Phase 1 Foundation: 45 / 45
- Phase 2 Locomotion: 48 / 48
- Phase 3 Combat: 91 / 91
- Phase 4 Advanced Defense: 84 / 84
- Phase 5 Combat Stances: 64 / 64
- Phase 6 Spirit Abilities: 95 / 95
- Phase 7 Transformation: 113 / 113
- **Required Total:** 540 + Phase 8 Tests (100% Pass, 0 Regressions, 0 Warnings).

---

## 8. Scope Boundaries

### Strictly Out of Scope for Phase 8:
- No Bosses or Minibosses (`Phase 9`).
- No complex enemy factions or threat tables.
- No XP, loot drops, inventory, or item rewards.
- No final art assets or sprite animation production.
- No procedural map generation or room streaming integration.
