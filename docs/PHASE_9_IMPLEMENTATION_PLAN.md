# Echoes of the Celestial Staff — Phase 9 Implementation Plan: Boss Framework

**Document Version:** 1.0.0  
**Target Engine:** Godot 4.7.2 Stable (`4.7.2.stable.official.ed1daf0bf`)  
**Renderer:** GL Compatibility (`gl_compatibility`)  
**Target Hardware:** Intel Core i3-1115G4, 12GB RAM, Intel UHD Graphics, 60 FPS Target  
**Status:** PROPOSED — Awaiting User Approval  

---

## 1. Executive Summary & Phase Objective

The objective of **Phase 9** is to construct a scalable, reusable **Boss Framework** on top of the established Enemy AI and Combat architecture, and implement the first playable prototype encounter: **The Granite Abbot**.

This phase establishes the architectural foundation for all future multi-phase boss encounters, arena locking mechanisms, readable multi-tier telegraph systems, and boss-specific UI/HUD integration while strictly avoiding duplicate combat systems.

### Key Architectural Tenets:
1. **Reuse Canonical Combat Pipeline:** Bosses utilize the existing `Hitbox` (Layer 5/16), `Hurtbox` (Layer 7/64), `DamageInfo`, `HealthComponent`, `PoiseComponent`, and `StateMachine` architecture.
2. **Defensive Interactivity:** Boss attacks honor player evasion (I-frames, perfect dodge) and defensive parrying (`attacker.interrupt_attack()` on Perfect Parry).
3. **Multi-Phase Architecture:** Data-driven `BossPhaseData` defines phase thresholds, stat multipliers, telegraph tints, and phase-specific attack sets without code duplication.
4. **Deterministic Arena Enclosure:** `BossArenaController` activates physical barrier boundaries upon player entry, seals the arena, coordinates boss intro and defeat, and unseals upon victory.
5. **Hardware Budget (<4ms Script Logic):** Zero per-frame scene tree scans, lightweight procedural telegraphs without GPU particle spam, and clean 60 FPS performance on Intel Core i3.

---

## 2. Boss Architecture & Node Hierarchy

### 2.1 Scene Composition (`scenes/bosses/boss_base.tscn`)

```
BossBase (CharacterBody2D) [scripts/bosses/boss_controller.gd]
├── CollisionShape2D (CapsuleShape2D, collision_layer = 4 [Layer 3], collision_mask = 1 [World])
├── Visuals (Node2D)
│   ├── Body (ColorRect - Heavy stone torso)
│   ├── Crest (ColorRect - Glowing monastic crest)
│   ├── Staff (ColorRect - Ceremonial Granite Staff)
│   ├── Aura (ColorRect - Phase 2 stone resonance glow)
│   └── TelegraphIndicator (Node2D - Visual telegraph shapes & warning arcs)
├── Combat (Node2D)
│   ├── BossHitbox (Area2D, collision_layer = 16 [Layer 5], collision_mask = 32 [PlayerHurtbox])
│   │   └── CollisionShape2D (RectangleShape2D)
│   └── BossHurtbox (Area2D, collision_layer = 64 [Layer 7], collision_mask = 0)
│       └── CollisionShape2D (CapsuleShape2D)
├── Components (Node)
│   ├── HealthComponent (scripts/combat/health_component.gd)
│   ├── PoiseComponent (scripts/combat/poise_component.gd)
│   ├── BossPerception (scripts/enemies/enemy_perception.gd)
│   ├── BossMovement (scripts/enemies/enemy_movement.gd)
│   ├── BossCombatController (scripts/bosses/boss_combat_controller.gd)
│   ├── BossPhaseController (scripts/bosses/boss_phase_controller.gd)
│   ├── BossTelegraphController (scripts/bosses/boss_telegraph_controller.gd)
│   └── BossAnimationController (scripts/bosses/boss_animation_controller.gd)
├── StateMachine (scripts/systems/state_machine.gd)
│   ├── Intro (scripts/bosses/states/boss_intro_state.gd)
│   ├── Idle (scripts/bosses/states/boss_idle_state.gd)
│   ├── Combat (scripts/bosses/states/boss_combat_state.gd)
│   ├── Attack (scripts/bosses/states/boss_attack_state.gd)
│   ├── Hit (scripts/bosses/states/boss_hit_state.gd)
│   ├── Stagger (scripts/bosses/states/boss_stagger_state.gd)
│   ├── PhaseTransition (scripts/bosses/states/boss_phase_transition_state.gd)
│   └── Defeated (scripts/bosses/states/boss_defeated_state.gd)
└── StatusLabel (Label - Diagnostic telemetry)
```

---

## 3. Data-Driven Boss & Phase Resources

### 3.1 `BossPhaseData` (`scripts/bosses/boss_phase_data.gd`)
Custom `Resource` defining phase parameters:
- `phase_id: int` (1 or 2)
- `phase_name: String` ("Stone Discipline" / "Awakened Granite")
- `health_threshold_ratio: float` (1.0 for Phase 1, 0.5 for Phase 2)
- `movement_speed_multiplier: float` (1.0x in Phase 1, 1.25x in Phase 2)
- `attack_speed_multiplier: float` (1.0x in Phase 1, 1.20x in Phase 2)
- `damage_multiplier: float` (1.0x in Phase 1, 1.25x in Phase 2)
- `poise_damage_multiplier: float` (1.0x in Phase 1, 1.30x in Phase 2)
- `attacks: Array[EnemyAttackData]` (phase attack set)
- `attack_weights: Array[float]` (weighted selection preferences)
- `aura_color: Color` (stone grey in Phase 1, glowing amber/cyan in Phase 2)

### 3.2 `BossData` (`scripts/bosses/boss_data.gd`)
Custom `Resource` configuring boss statistics:
- `boss_id: StringName = &"granite_abbot"`
- `display_name: String = "The Granite Abbot"`
- `max_health: float = 300.0`
- `max_poise: float = 60.0`
- `stagger_duration: float = 1.8`
- `poise_regen_delay: float = 3.0`
- `poise_regen_rate: float = 12.0`
- `movement_speed: float = 55.0`
- `chase_speed: float = 90.0`
- `acceleration: float = 400.0`
- `deceleration: float = 650.0`
- `preferred_combat_distance: float = 50.0`
- `detection_range: float = 300.0`
- `intro_duration: float = 1.5`
- `defeat_duration: float = 2.0`
- `phase_transition_duration: float = 1.8`
- `phases: Array[BossPhaseData]`
- `bounty_qi: int = 50`

---

## 4. The Granite Abbot Encounter Specification

### 4.1 Character Concept & Philosophy
- **Identity:** Ancient stone monastic guardian wielding a massive ceremonial granite staff.
- **Combat Identity:** High posture, deliberate heavy strikes, unmistakably readable telegraphs, punishing counter-opportunities upon parry deflection or poise stagger.

### 4.2 Combat Phases
1. **Phase 1: "Stone Discipline" (100% - 50% HP):**
   - Deliberate, rhythmic martial forms.
   - Attacks:
     - `attack_granite_sweep.tres`: Horizontal sweeping staff attack (20 DMG, 25 Poise, 0.50s Telegraph, 0.15s Active, 0.45s Recovery, 2.0s Cooldown).
     - `attack_stone_overhead.tres`: Crushing vertical slam (30 DMG, 35 Poise, 0.70s Telegraph, 0.12s Active, 0.50s Recovery, 2.5s Cooldown).
     - `attack_step_strike.tres`: Quick lunging thrust (16 DMG, 18 Poise, 0.35s Telegraph, 0.10s Active, 0.35s Recovery, 1.6s Cooldown).
2. **Phase 2: "Awakened Granite" (<= 50% HP):**
   - Awakened celestial energy infuses the stone staff; movement and attacks accelerate.
   - Modifiers: +25% move speed, +20% attack speed, +25% damage, +30% poise damage.
   - Additional Attacks:
     - `attack_awakened_sweep.tres`: Accelerated empowered staff sweep (25 DMG, 30 Poise, 0.38s Telegraph, 0.15s Active, 0.35s Recovery, 1.5s Cooldown).
     - `attack_granite_shockwave.tres`: Heavy staff ground plunge emitting a 75px radiating shockwave (35 DMG, 45 Poise, 0.65s Telegraph, 0.18s Active, 0.55s Recovery, 3.0s Cooldown).

---

## 5. Phase Transitions & Determinism

- **Health Monitoring:** `BossPhaseController` subscribes to `health_changed` from `HealthComponent`.
- **Threshold Check:** Triggered strictly when `current_health / max_health <= 0.50`.
- **Idempotency Guarantee:** Monitored by a boolean flag `_phase_2_triggered`. Once executed, it cannot trigger again.
- **Transition Sequence:**
  1. Cancels active attack and immediately disables hitbox.
  2. Boss enters `PhaseTransition` state (cannot attack or take poise breaks during transition).
  3. Plays stone resonance burst visual (flashing amber aura, pulsing crest).
  4. Emits `EventBus.boss_phase_changed("The Granite Abbot", 2)`.
  5. Multipliers and Phase 2 attack pool are applied to `BossCombatController`.
  6. When transition timer finishes (1.8s), boss transitions smoothly back to `Combat` state.

---

## 6. Telegraph & Readability System (`BossTelegraphController`)

To support precision dodging and parrying without high particle overhead:
- **Telegraph Indicators:**
  - Staff tip indicator / overhead flash during windup.
  - Directional warning arc indicating horizontal sweeps.
  - Ground warning marker displaying upcoming shockwave radius.
- **Timing Readability:**
  - Warning colors match attack danger (Phase 1: amber yellow `Color(1.0, 0.75, 0.1)`; Phase 2: radiant gold/crimson `Color(1.0, 0.3, 0.1)`).
  - Gives the player unambiguous windows for normal dodge, perfect dodge, parry, or perfect parry.

---

## 7. Arena Encounter Controller & Escape Prevention (`BossArenaController`)

- **Arena Boundaries:**
  - `LeftBarrier` and `RightBarrier`: Physical `StaticBody2D` walls on Layer 1 (World Geometry).
  - Initially lowered (`collision_layer = 0`, `visible = false`).
- **Encounter Trigger (`Area2D`):**
  - Detects `PlayerController` crossing into the arena center.
  - Immediately seals barriers (`collision_layer = 1`, `visible = true`).
  - Emits `EventBus.boss_arena_locked` and `EventBus.boss_started("The Granite Abbot")`.
  - Wakes boss from inactive wait into `Intro` state.
- **Encounter Resolution:**
  - Boss health reaches 0 -> `boss_defeated` signal emitted.
  - Barriers lower, allowing player free traversal.
  - Boss HUD hides smoothly.
- **Encounter Reset:**
  - Resets barriers, boss position, health, poise, phase, and state machine for seamless iterative testing.

---

## 8. Boss HUD (`BossHealthBar`)

- Positioned at screen top/bottom center via `CanvasLayer`.
- Displays:
  - Boss Display Name: "The Granite Abbot"
  - Phase Badge: "PHASE 1: Stone Discipline" / "PHASE 2: Awakened Granite"
  - Health ProgressBar: Smooth lerping damage bar behind instant health bar.
  - Poise indicator: Displays current posture / stagger status.

---

## 9. State Machine Lifecycle

```
             [Player Enters Arena]
                       │
                       ▼
                   ┌───────┐
                   │ INTRO │ (1.5s visual wake-up)
                   └───┬───┘
                       │ Intro Finished
                       ▼
                   ┌───────┐
            ┌─────►│ IDLE  │◄────┐
            │      └───┬───┘     │
            │          │ In Range│ Cooldown
            │          ▼         │
            │     ┌─────────┐    │
            │     │ COMBAT  ├────┘
            │     └───┬──┬──┘
            │         │  │ Attack Selected
            │         │  ▼
            │         │ ┌────────┐
            │         │ │ ATTACK │ (Telegraph -> Active -> Recovery -> Cooldown)
            │         │ └──┬─────┘
            │         │    │ Perfect Parry Interruption
            │         │    ▼
            │         │ ┌─────┐
            │         │ │ HIT │
            │         │ └─────┘
            │         │
            │ Poise=0 │ HP <= 50%
            ▼         ▼
       ┌─────────┐ ┌──────────────────┐
       │ STAGGER │ │ PHASE_TRANSITION │
       └─────────┘ └────────┬─────────┘
                            │ Complete (1.8s)
                            ▼
                         [COMBAT]
                            │
                            │ HP = 0
                            ▼
                       ┌──────────┐
                       │ DEFEATED │ (Unlocks Arena)
                       └──────────┘
```

---

## 10. Test Strategy & Verification Plan

### 10.1 Automated Test Suite (`tests/test_boss_runner.tscn` & `tests/test_boss.gd`)
Targeting **120+ comprehensive automated tests** across 12 categories:
1. **Boss Data:** Loading, validation, phases array, attack sets.
2. **Architecture:** Base scene instantiates cleanly, collision layers (Layer 3, Mask 1), hitbox (Layer 5, Mask 32), hurtbox (Layer 7, Mask 0).
3. **State Machine:** Intro -> Idle -> Combat -> Attack -> Hit -> Stagger -> PhaseTransition -> Defeated. Invalid transition protection.
4. **Phases & Thresholds:** Phase 1 defaults, 50% HP threshold detection, deterministic single transition, Phase 2 stat multipliers.
5. **Attack System:** Weighted selection, attack ranges, cooldown enforcement, active window exclusivity.
6. **Telegraph System:** Indicator visibility, timing accuracy, visual reset on interruption.
7. **Combat Integration:** Player damages boss, boss damages player, knockback, hitstop.
8. **Poise & Stagger:** Poise reduction, stagger lock (no attacks while staggered), poise recovery.
9. **Perfect Parry Interruption:** `interrupt_attack()` disables active hitbox, halts attack, forces hit/recoil state.
10. **Arena Controller:** Player trigger activation, physical barrier locking, boss defeat unlocking, reset logic.
11. **Boss Defeat:** Idempotent defeat, collision disabling, AI stop, signal broadcast.
12. **Multi-System Compatibility:** Player stances, spirit abilities, and celestial awakening against boss.

### 10.2 Full Regression Baseline
- Phase 1 Foundation: 45 / 45
- Phase 2 Locomotion: 48 / 48
- Phase 3 Combat: 91 / 91
- Phase 4 Advanced Defense: 84 / 84
- Phase 5 Combat Stances: 64 / 64
- Phase 6 Spirit Abilities: 95 / 95
- Phase 7 Transformation: 113 / 113
- Phase 8 Enemy AI: 133 / 133
- **Required Baseline:** 673 + Phase 9 Tests (**100% Pass, 0 Regressions, 0 Warnings**).

---

## 11. Scope Boundaries

### Strictly Out of Scope for Phase 9:
- No final artwork, production sprites, or frame-by-frame animation.
- No final music tracks, voice acting, or orchestral mastering.
- No second or third boss encounters (only Granite Abbot).
- No world progression gating, loot drops, or inventory items.
- No complex cinematic cutscene engine or camera framing tracks.
