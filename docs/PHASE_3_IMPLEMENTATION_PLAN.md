# Echoes of the Celestial Staff — Phase 3 Implementation Plan
## Core Combat Foundation

**Document Version:** 1.0.0  
**Phase:** Phase 3 — Combat Foundation  
**Engine:** Godot 4.7.2 Stable (`4.7.2.stable.official.ed1daf0bf`)  
**Renderer:** GL Compatibility  
**Language:** Typed GDScript  

---

## 1. Executive Summary & Objectives

The primary objective of Phase 3 is to construct the **Core Combat Foundation** for *Echoes of the Celestial Staff*. This foundation delivers the responsive, high-impact, readable feel inspired by modern character-action masterpieces (such as *Black Myth: Wukong*), while remaining an entirely original intellectual property and preserving the architectural integrity established in Phase 1 and Phase 2.

### Core Deliverables:
1. **Data-Driven Attack System:** Strongly typed `AttackData` resource defining damage, poise damage, startup/active/recovery durations, combo windows, hitstop, and forward movement impulses.
2. **Combat Payloads:** `DamageInfo` payload carrying attacker context, damage, poise depletion, hit vector, and hitstop parameters.
3. **Collision & Hit Resolution Components:** Reusable `Hitbox` (`Area2D`) and `Hurtbox` (`Area2D`) components adhering strictly to the layer matrix in `docs/TECHNICAL_ARCHITECTURE.md`.
4. **Vitals & Stagger Components:** Decoupled `HealthComponent` and `PoiseComponent` tracking vitality, poise depletion, guard-break/stagger states, and recovery timers.
5. **Staff Weapon & Combo Flow:** 3-hit light attack string (`Light 1` -> `Light 2` -> `Light 3`) and dedicated `Heavy Attack 1` with configurable input buffering and combo continuation windows.
6. **State Machine Integration:** Seamless integration of `Attack` and `HeavyAttack` states into the existing locomotion `StateMachine` (`Idle`, `Run`, `Jump`, `Fall`, `Land`).
7. **Facing Direction Stability:** Attack hitbox and impulse positioning respecting `PlayerController.get_facing_direction()` without scaling or inverting physics collision shapes.
8. **Hitstop via GameManager:** Micro-freezes coordinated through `GameManager` using timescale control and unscaled real-time restoration.
9. **Combat Test Dummy & Test Arena:** A dedicated testing dummy (`scenes/enemies/combat_test_dummy.tscn`) and testing arena (`scenes/world/test_combat_room.tscn`) for sandbox combat evaluation.
10. **Automated Verification:** Comprehensive automated test suite (`tests/test_combat_foundation.gd`, `tests/test_combat_runner.tscn`) verifying all 26 combat requirements, alongside 100% regression passing on Phase 1 (45/45) and Phase 2 (48/48).

---

## 2. Component Architecture & Hierarchy

The combat architecture adheres strictly to **Composition Over Deep Inheritance** and **Separation of Concerns**. The `PlayerController` orchestrates components rather than containing monolithic combat code.

```
Player (CharacterBody2D) [Layer 2: Player]
│
├── CollisionShape2D (CapsuleShape2D)
├── Visuals (Node2D)
│   ├── Body, Head, Sash, Eye
│   └── WeaponMount (Node2D)
│       └── CelestialStaff (Visual placeholder staff line / rect)
│
├── Camera2D
│
├── Components (Node)
│   ├── PlayerMovement (Node)
│   ├── PlayerAnimationController (Node)
│   ├── PlayerRespawn (Node)
│   ├── CombatController (Node) [scripts/player/combat_controller.gd]
│   ├── HealthComponent (Node) [scripts/combat/health_component.gd]
│   └── PoiseComponent (Node) [scripts/combat/poise_component.gd]
│
├── Combat (Node2D)
│   ├── PlayerHitbox (Area2D) [scripts/combat/hitbox.gd, Layer 4: PlayerHitbox, Mask: 64]
│   │   └── CollisionShape2D (RectangleShape2D)
│   └── PlayerHurtbox (Area2D) [scripts/combat/hurtbox.gd, Layer 6: PlayerHurtbox, Mask: 0]
│       └── CollisionShape2D (CapsuleShape2D)
│
├── StateMachine (Node) [scripts/systems/state_machine.gd]
│   ├── Idle (Node) [PlayerIdleState]
│   ├── Run (Node) [PlayerRunState]
│   ├── Jump (Node) [PlayerJumpState]
│   ├── Fall (Node) [PlayerFallState]
│   ├── Land (Node) [PlayerLandState]
│   ├── Attack (Node) [PlayerAttackState]
│   └── HeavyAttack (Node) [PlayerHeavyAttackState]
│
└── DebugOverlay (CanvasLayer) [scripts/player/player_debug_overlay.gd]
```

### Component Responsibilities:
- **`CombatController`**: Coordinates attack initiation, combo progression, attack timing state machine (Startup -> Active -> Recovery), input buffering, hitbox activation toggles, and attack forward displacement.
- **`Hitbox`**: An `Area2D` that remains deactivated until enabled during the attack's `ACTIVE` phase. Detects overlapping `Hurtbox` nodes, prevents duplicate hits against the same target in a single swing, constructs a `DamageInfo` payload, and triggers target damage resolution.
- **`Hurtbox`**: An `Area2D` receiver that validates incoming hits against invulnerability flags and dispatches `DamageInfo` to sibling `HealthComponent` and `PoiseComponent`.
- **`HealthComponent`**: Encapsulates health points, damage intake, healing, and death signals.
- **`PoiseComponent`**: Encapsulates poise points, stagger accumulation, stagger duration timers, and poise regeneration.

---

## 3. Data-Driven Attack System

Attacks are modeled as discrete Godot `Resource` files (`.tres`) extending `AttackData`.

### Class: `AttackData` (`scripts/combat/attack_data.gd`)
```gdscript
class_name AttackData
extends Resource

@export var attack_id: StringName = &""
@export var display_name: String = ""
@export var damage: float = 10.0
@export var poise_damage: float = 12.0
@export var knockback_force: Vector2 = Vector2(120.0, -40.0)
@export var startup_time: float = 0.067      # ~4 frames at 60 FPS
@export var active_time: float = 0.050       # ~3 frames at 60 FPS
@export var recovery_time: float = 0.133     # ~8 frames at 60 FPS
@export var combo_window_start: float = 0.050 # When buffering/chaining is unlocked
@export var combo_window_end: float = 0.220   # Expiration of combo continuation
@export var next_attack_id: StringName = &""  # Next attack in string (empty if finisher)
@export var forward_impulse: float = 25.0     # Small controlled forward movement
@export var hitstop_duration: float = 0.050   # Micro-freeze duration in seconds
@export var attack_priority: int = 1
```

### Initial Phase 3 Attack Assets (`data/attacks/`):
1. **`attack_light_1.tres`**:
   - `attack_id`: `&"light_1"`
   - `damage`: `10.0`, `poise_damage`: `12.0`, `knockback_force`: `Vector2(100.0, -30.0)`
   - `startup_time`: `0.067s` (4 frames), `active_time`: `0.050s` (3 frames), `recovery_time`: `0.133s` (8 frames)
   - `combo_window_start`: `0.050s`, `combo_window_end`: `0.230s`
   - `next_attack_id`: `&"light_2"`, `forward_impulse`: `30.0`, `hitstop_duration`: `0.050s`
2. **`attack_light_2.tres`**:
   - `attack_id`: `&"light_2"`
   - `damage`: `12.0`, `poise_damage`: `14.0`, `knockback_force`: `Vector2(120.0, -40.0)`
   - `startup_time`: `0.083s` (5 frames), `active_time`: `0.050s` (3 frames), `recovery_time`: `0.133s` (8 frames)
   - `combo_window_start`: `0.050s`, `combo_window_end`: `0.240s`
   - `next_attack_id`: `&"light_3"`, `forward_impulse`: `35.0`, `hitstop_duration`: `0.050s`
3. **`attack_light_3.tres`**:
   - `attack_id`: `&"light_3"` (Finisher)
   - `damage`: `18.0`, `poise_damage`: `22.0`, `knockback_force`: `Vector2(180.0, -60.0)`
   - `startup_time`: `0.100s` (6 frames), `active_time`: `0.067s` (4 frames), `recovery_time`: `0.200s` (12 frames)
   - `combo_window_start`: `0.0s`, `combo_window_end`: `0.0s` (Finisher terminates combo)
   - `next_attack_id`: `&""`, `forward_impulse`: `50.0`, `hitstop_duration`: `0.080s`
4. **`attack_heavy_1.tres`**:
   - `attack_id`: `&"heavy_1"`
   - `damage`: `25.0`, `poise_damage`: `35.0`, `knockback_force`: `Vector2(240.0, -80.0)`
   - `startup_time`: `0.233s` (14 frames), `active_time`: `0.083s` (5 frames), `recovery_time`: `0.300s` (18 frames)
   - `combo_window_start`: `0.0s`, `combo_window_end`: `0.0s`
   - `next_attack_id`: `&""`, `forward_impulse`: `40.0`, `hitstop_duration`: `0.120s`

---

## 4. Damage Pipeline & Components

### 4.1 `DamageInfo` (`scripts/combat/damage_info.gd`)
A strongly typed value object encapsulating attack payload information:
```gdscript
class_name DamageInfo
extends RefCounted

var damage: float = 0.0
var poise_damage: float = 0.0
var knockback_force: Vector2 = Vector2.ZERO
var hit_direction: int = 1 # +1 or -1
var attack_id: StringName = &""
var attacker: Node2D = null
var source_hitbox: Area2D = null
var hitstop_duration: float = 0.0
```

### 4.2 `Hitbox` (`scripts/combat/hitbox.gd`)
- Extends `Area2D`.
- Layer: Configurable (defaults to Layer 4 `PlayerHitbox`, mask Layer 7 `EnemyHurtbox`).
- State: Disabled by default (`monitoring = false`, `monitorable = false`). Enabled only when explicitly instructed by `CombatController` during `ACTIVE` phase.
- Duplicate Guard: Maintains an `Array[Hurtbox]` of already-damaged hurtboxes during the active swing to prevent multiple ticks of damage within one attack. Cleared on activation.
- Dispatches: Calls `hurtbox.receive_hit(damage_info)` upon `area_entered`.

### 4.3 `Hurtbox` (`scripts/combat/hurtbox.gd`)
- Extends `Area2D`.
- Layer: Configurable (defaults to Layer 6 `PlayerHurtbox` or Layer 7 `EnemyHurtbox`, mask 0).
- Delegates damage reception to sibling or assigned `HealthComponent` and `PoiseComponent`.
- Applies knockback to parent `CharacterBody2D`.
- Emits local signal `hit_received(damage_info: DamageInfo)`.

### 4.4 `HealthComponent` (`scripts/combat/health_component.gd`)
- Properties: `max_health: float = 100.0`, `current_health: float = 100.0`, `is_invulnerable: bool = false`.
- Methods: `take_damage(amount: float) -> void`, `heal(amount: float) -> void`, `reset() -> void`.
- Signals: `health_changed(current: float, max_val: float)`, `damaged(amount: float)`, `healed(amount: float)`, `died()`.

### 4.5 `PoiseComponent` (`scripts/combat/poise_component.gd`)
- Properties: `max_poise: float = 50.0`, `current_poise: float = 50.0`, `stagger_duration: float = 1.5`, `poise_regen_delay: float = 2.0`, `poise_regen_rate: float = 20.0`, `is_staggered: bool = false`.
- Logic: Poise damage accumulates. When `current_poise <= 0.0`, triggers `stagger_started(duration)` and enters staggered state. After `stagger_duration`, resets poise and emits `stagger_ended()`. If undamaged for `poise_regen_delay`, regenerates poise up to `max_poise`.
- Methods: `take_poise_damage(amount: float) -> void`, `reset() -> void`.
- Signals: `poise_changed(current: float, max_val: float)`, `poise_broken()`, `stagger_started(duration: float)`, `stagger_ended()`.

---

## 5. Player Combat Integration & State Machine

### 5.1 State Machine Extensions
Two new states will be added to the Player's `StateMachine`:
1. **`PlayerAttackState` (`scripts/player/states/player_attack_state.gd`)**:
   - Manages light attack sequence execution.
   - Enters `CombatController.start_light_attack()`.
   - Physics update advances combat timers, maintains grounded friction / forward step, and checks for combo continuation.
   - Upon attack completion with no buffered continuation, transitions cleanly back to `Idle` (or `Run` if horizontal axis is held, or `Fall` if ledge left).
2. **`PlayerHeavyAttackState` (`scripts/player/states/player_heavy_attack_state.gd`)**:
   - Manages heavy attack execution.
   - Enters `CombatController.start_heavy_attack()`.
   - Higher commitment: zero horizontal movement control, longer recovery, transitions back to `Idle`/`Run`/`Fall` when finished.

### 5.2 Transition Rules from Locomotion:
- In `PlayerIdleState` & `PlayerRunState`:
  - `InputManager.is_action_just_pressed(ACTION_LIGHT_ATTACK)` -> Transition to `Attack`.
  - `InputManager.is_action_just_pressed(ACTION_HEAVY_ATTACK)` -> Transition to `HeavyAttack`.
- In `PlayerAttackState`:
  - Windup / Active / Early Recovery: Locomotion inputs are locked (cannot cancel into jump/run).
  - Combo Window Active: If `ACTION_LIGHT_ATTACK` is pressed, buffers next combo stage. If `ACTION_HEAVY_ATTACK` is pressed, branches to `HeavyAttack`.
  - Recovery Finished: Transitions to `Idle` or `Run`.

### 5.3 Facing Direction Integration:
- Attack hitbox position is updated according to `PlayerController.get_facing_direction()`:
  `hitbox.position.x = abs(base_offset_x) * player.get_facing_direction()`
- The collision shape geometry and scale are **never** inverted or manipulated, guaranteeing complete physics stability.

---

## 6. Hitstop & Audio Integration

### 6.1 Hitstop Architecture
- Coordinated through `GameManager` (`scripts/core/game_manager.gd`):
  ```gdscript
  func apply_hitstop(duration: float, time_scale: float = 0.05) -> void:
      set_time_scale(time_scale)
      var timer: SceneTreeTimer = get_tree().create_timer(duration, true, false, true)
      timer.timeout.connect(reset_time_scale)
  ```
- Uses `ignore_time_scale = true` on the `SceneTreeTimer` to ensure real-world precision without permanently locking the engine.
- Triggered by `Hitbox` on confirmed hit connection with any `Hurtbox`.

### 6.2 Audio Integration
- Hooks into `AudioManager.play_sfx()` on:
  - Attack start (whiff)
  - Attack hit
  - Heavy attack impact
  - Poise break / stagger
- If audio streams are `null`, `AudioManager` handles them gracefully with no crashes.

---

## 7. Combat Test Dummy & Combat Arena

### 7.1 Combat Test Dummy (`scenes/enemies/combat_test_dummy.tscn`)
- Root: `CharacterBody2D` with `CollisionShape2D` (Layer 3 `Enemies`, Mask 1 `WorldGeometry`).
- Components: `Hurtbox` (Layer 7 `EnemyHurtbox`), `HealthComponent` (100 HP), `PoiseComponent` (35 Poise).
- Presentation: Placeholder `ColorRect` (crimson/purple, 24x48) with overhead status label displaying HP, Poise, and Stagger state.
- Behavior:
  - Knockback applied upon taking hit (`velocity += knockback_vector`).
  - Standard deceleration/friction applied in `_physics_process`.
  - Staggers when poise reaches zero (visual flash to celestial gold, pauses knockback recovery).
  - Can be manually reset via `reset_dummy()` or room reset trigger.

### 7.2 Combat Test Arena (`scenes/world/test_combat_room.tscn`)
- Arena containing solid floor, boundary walls, and floating platforms.
- Instantiates Player and Combat Test Dummy.
- Provides interactive reset trigger and instructions for testing light combos, heavy attacks, knockback, and stagger.

---

## 8. Combat Debug Overlay & Visualizations

### 8.1 Combat Debug Diagnostics
Extends `PlayerDebugOverlay` (F3 toggle):
- Attack State (`IDLE`, `ATTACK`, `HEAVY_ATTACK`)
- Current Attack ID (`light_1`, `light_2`, `light_3`, `heavy_1`)
- Attack Phase (`STARTUP`, `ACTIVE`, `RECOVERY`, `NONE`)
- Phase Timer / Duration
- Combo Index & Window Open / Closed
- Hitbox Status (`ACTIVE` / `INACTIVE`)
- Target HP & Target Poise (last hit target)
- Hitstop State

### 8.2 Visual Debug Shapes
Optional runtime toggle (or via Godot debug collision view):
- Red outline for active attack `Hitbox`.
- Blue outline for `Hurtbox`.

---

## 9. Collision Layer Matrix Confirmation

| Layer ID | Name | Bitmask | Assigned Purpose |
| :--- | :--- | :--- | :--- |
| **Layer 1** | `WorldGeometry` | `1` (0x1) | Terrain, floors, walls, platforms. |
| **Layer 2** | `Player` | `2` (0x2) | Player CharacterBody2D physics collider. |
| **Layer 3** | `Enemies` | `4` (0x4) | Enemy/Dummy CharacterBody2D physics collider. |
| **Layer 4** | `PlayerHitbox` | `8` (0x8) | Player attack hit areas. Detects Layer 7 (`EnemyHurtbox`). |
| **Layer 5** | `EnemyHitbox` | `16` (0x10) | Enemy attack hit areas. Detects Layer 6 (`PlayerHurtbox`). |
| **Layer 6** | `PlayerHurtbox` | `32` (0x20) | Player damage reception area. Mask = 0. |
| **Layer 7** | `EnemyHurtbox` | `64` (0x40) | Enemy/Dummy damage reception area. Mask = 0. |
| **Layer 8** | `Triggers` | `128` (0x80) | Arena reset triggers, room portals. |

---

## 10. Automated Testing Strategy

A dedicated test runner (`tests/test_combat_runner.tscn` running `tests/test_combat_foundation.gd`) will execute headless validation covering all 26 required criteria:
1. Combat system and scripts load cleanly
2. Attack data resources load and contain valid properties
3. Light attack starts properly from neutral
4. Light attack enters startup phase
5. Light attack enters active phase
6. Light attack enters recovery phase
7. Hitbox activates strictly during active phase
8. Hitbox deactivates immediately upon active phase termination
9. Hitbox detects overlapping hurtbox
10. Damage payload is correctly generated
11. Target health decreases by correct damage amount
12. Target poise decreases by correct poise damage amount
13. Knockback force is applied in direction of attack/facing
14. Target hit reaction and flash trigger cleanly
15. Hitstop request triggers timescale adjustment
16. Facing right creates right-side attack alignment
17. Facing left creates left-side attack alignment
18. Light combo progresses through chain (`Light 1` -> `Light 2` -> `Light 3`)
19. Combo input buffer captures input during combo window
20. Combo expires cleanly if input is withheld
21. Heavy attack initiates with correct timing
22. Heavy attack deals greater damage and poise impact than light attack
23. Attack finishes and returns cleanly to movement (`Idle`/`Run`)
24. Game pause suspends attack timers and combat processing
25. Phase 2 movement regression passes (48/48)
26. Phase 1 foundation regression passes (45/45)

Target: **100% tests passing, zero warnings, zero parser errors.**
