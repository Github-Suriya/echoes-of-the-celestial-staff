# PHASE 11 IMPLEMENTATION PLAN — FORBIDDEN FOREST VERTICAL SLICE

## 1. Executive Summary

Phase 11 delivers the first complete playable chapter of *Echoes of the Celestial Staff*: **Chapter 1 — Forbidden Forest**.
Building directly upon the verified 10-phase foundation (956 / 956 passing tests), Phase 11 constructs 5 compact rooms, 3 normal enemy archetypes, 3 intermediate bosses, and a 2-phase final boss, creating an end-to-end 5-minute vertical slice.

---

## 2. Existing Systems Reused

In accordance with project invariants, zero existing systems will be rewritten or replaced:
- **Core Autoloads**: `GameManager`, `EventBus`, `InputManager`, `AudioManager`, `SceneManager`, `SaveManager`, `DebugManager`.
- **Player Subsystems**: `PlayerController`, `PlayerMovement`, `CombatController`, `DefenseController`, `StanceController`, `SpiritComponent`, `SpiritAbilityController`, `TransformationController`.
- **Metroidvania World Architecture**: `WorldController`, `Room2D`, `RoomData`, `WorldState`, `PlayerCapabilities`, `AbilityGate`, `Checkpoint`, `RoomExit`.
- **Enemy & Boss Frameworks**: `EnemyController`, `EnemyData`, `EnemyAttackData`, `EnemyCombatController`, `EnemyPerception`, `BossController`, `BossData`, `BossPhaseData`, `BossPhaseController`, `BossArenaController`, `BossTelegraphController`.
- **Combat Contracts**: `Hitbox`, `Hurtbox`, `HealthComponent`, `PoiseComponent`, `DamageInfo`, `AttackData`.

---

## 3. New Systems & Components Created

### 1. Enemy Archetypes (`scenes/enemies/`, `data/enemies/`):
- `enemy_forest_scout.tres` + `attack_forest_scout_claw.tres` + `forest_scout.tscn`: Fast melee skirmisher.
- `enemy_thorn_beast.tres` + `attack_thorn_beast_slam.tres` + `thorn_beast.tscn`: Heavy poise brute.
- `enemy_spore_caster.tres` + `attack_spore_caster_cast.tres` + `spore_caster.tscn`: Ranged projectile caster.
- `scripts/enemies/enemy_projectile.gd` + `scenes/effects/enemy_projectile.tscn`: Reusable enemy projectile on Layer 5 (EnemyHitbox) hitting Layer 6 (PlayerHurtbox).

### 2. Intermediate Bosses (`scenes/bosses/`, `data/bosses/`):
- `boss_verdant_fang.tres` + `verdant_fang.tscn`: Fast beast boss with leap and claw attacks.
- `boss_bamboo_warden.tres` + `bamboo_warden.tscn`: Staff guardian with 3-hit combo and sweep.
- `boss_hollow_shrine_keeper.tres` + `hollow_shrine_keeper.tscn`: High-poise supernatural guardian with area slam and spirit projectiles. Defeat opens the Shrine Gate.

### 3. Final Boss — Corrupted Forest Heart (`scenes/bosses/`, `data/bosses/`):
- `boss_corrupted_forest_heart.tres` + `phase_forest_heart_p1.tres` + `phase_forest_heart_p2.tres` + `corrupted_forest_heart.tscn`.
- Phase 1: Melee combo, root strike, spore projectile, punishable recovery.
- Phase 2 (<=50% HP): Speed boost, aggressive combos, frenzy root flurry, ground rupture, corrupted visual aura.
- Defeat: Emits completion signal, sets `chapter_1_completed`, displays victory UI.

### 4. Base VFX Architecture (`scripts/effects/`, `scenes/effects/`):
- `scripts/effects/vfx_manager.gd`: Decoupled singleton / listener responding to `EventBus` signals (`hit_connected`, `perfect_dodge`, `perfect_parry`, `enemy_died`, `boss_phase_changed`).
- Lightweight particle effects (GPUParticles2D / CPUParticles2D) and sprite flashes for hits, dodges, parries, deaths, mist, and floating spores.
- Low particle count (<80 total particles simultaneously) to maintain 60 FPS on Intel UHD.

### 5. Chapter 1 Rooms & World (`scenes/world/forbidden_forest/`, `data/world/forbidden_forest/`):
- `room_01_forest_entrance.tscn`: Checkpoint 1, 2 Forest Scouts, tutorial-free orientation.
- `room_02_ancient_grove.tscn`: Checkpoint 2, normal enemies, Verdant Fang arena.
- `room_03_bamboo_path.tscn`: Checkpoint 3, mixed encounters, Bamboo Warden arena.
- `room_04_forgotten_shrine.tscn`: Checkpoint 4, Hollow Shrine Keeper arena, Shrine Gate barrier.
- `room_05_forest_heart.tscn`: Checkpoint 5, ancient tree backdrop, Corrupted Forest Heart arena (Phase 1 & 2).
- `forbidden_forest_world.tscn`: Root world scene inheriting `WorldController` with registered room resources, persistent world state, and HUD.

### 6. Chapter HUD & Feedback (`scenes/ui/`, `scripts/ui/`):
- `chapter_hud.tscn` + `scripts/ui/chapter_hud.gd`: Combines Player HP/Spirit/Stance, Boss Health Bar, Checkpoint Activated notification banner, Death/Respawn overlay, and Chapter Complete victory screen.

---

## 4. Scene Hierarchy & Invariants

```
forbidden_forest_world.tscn (WorldController)
├── RoomsContainer (Node2D)
│   └── [Active Room2D] (e.g. room_01_forest_entrance)
│       ├── Geometry (StaticBody2D / TileMap / Platforms)
│       ├── CameraBounds (ReferenceRect)
│       ├── SpawnPoints (Marker2D nodes: default, entrance, exit)
│       ├── Exits (RoomExit Area2Ds)
│       ├── Doors (AbilityGate barriers)
│       ├── Checkpoints (Checkpoint Area2Ds)
│       ├── Enemies (EnemyController instances)
│       └── PersistentObjects (BossArenaController instances)
├── Player (PlayerController - preserved across room transitions)
├── ChapterHUD (CanvasLayer)
│   ├── PlayerStatusPanel (HP, Spirit, Stance)
│   ├── BossHealthBar (Boss HP, Poise, Phase title)
│   ├── NotificationBanner (Checkpoint & ability alerts)
│   └── ChapterCompleteOverlay (Victory feedback)
└── VFXManager (Node2D - decoupled visual feedback listener)
```

---

## 5. Persistence Architecture

- **WorldState Flags**:
  - `checkpoint_active_<id>`: Active checkpoint tracking.
  - `verdant_fang_defeated`: Persists Boss 1 defeat.
  - `bamboo_warden_defeated`: Persists Boss 2 defeat.
  - `hollow_shrine_keeper_defeated`: Persists Boss 3 defeat & unlocks Shrine Gate.
  - `corrupted_forest_heart_defeated`: Persists Final Boss defeat.
  - `chapter_1_completed`: Persists chapter clearance.
- **Safety Invariant**:
  - Defeated bosses are permanently disabled on room reload; barriers remain open.
  - Safe deferred collision changes prevent Godot physics callback re-entrancy.

---

## 6. Testing & Regression Strategy

1. **Automated Test Suite**:
   - `tests/test_chapter_1.gd` + `tests/test_chapter_1_runner.tscn`
   - Test categories:
     - World & room registration (5 rooms registered, valid bounds).
     - Checkpoint registration and respawn functionality.
     - 3 Enemy archetypes (initialization, perception, attack, poise, death).
     - 3 Intermediate bosses (initialization, attacks, damage, stagger, defeat persistence).
     - Final boss 2-phase progression (Phase 1 -> 50% HP threshold -> Phase 2 -> Defeated -> Chapter Complete).
     - VFX instantiation and cleanup.
     - Persistence across room transitions and simulated save/load.
2. **Regression Verification**:
   - Run all 10 previous test runners (Foundation, Locomotion, Combat, Defense, Stance, Spirit, Transformation, Enemy, Boss, World) + Chapter 1 runner.
   - Target: 100% passing across all 11 runners (1,070+ tests), 0 parser errors, 0 runtime errors, 0 warnings.
3. **Manual Playthrough**:
   - Complete end-to-end manual playthrough using `forbidden_forest_world.tscn`.
   - Measure 60 FPS stability and verify ~5-minute game flow.
