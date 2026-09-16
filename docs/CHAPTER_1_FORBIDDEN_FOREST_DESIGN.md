# CHAPTER 1 — FORBIDDEN FOREST DESIGN

## 1. Chapter Objective & Overview

**Echoes of the Celestial Staff** — Chapter 1: Forbidden Forest is the first fully playable vertical slice of the game.
It demonstrates the cohesive integration of all foundational systems established across Phases 1 through 10:
- Fluid 2D combat locomotion (run, jump, fall, landing, ledge/platform traversal).
- 3 Combat Stances (Swift, Mountain, Storm) with unique damage, poise, and timing profiles.
- Defensive mechanics (Dodge, Perfect Dodge, Parry, Perfect Parry) with invulnerability and counter windows.
- Spirit Abilities (Celestial Arc, Heavenly Pulse, Cloud Step) consuming Spirit resources.
- Celestial Awakening (Wukong transformation with extended reach, damage boost, and golden radiance).
- Metroidvania Room lifecycle: deterministic loading, transitions, camera bounds, checkpoints, and persistent world state.
- Compact enemy roster (Forest Scout, Thorn Beast, Spore Caster).
- 3 Intermediate Bosses (Verdant Fang, Bamboo Warden, Hollow Shrine Keeper).
- Multi-phase Final Boss (Corrupted Forest Heart: Phase 1 Guardian -> Phase 2 Unstable Corruption -> Chapter Complete).

**Target Playtime**: Approximately 5 minutes for a competent first-time player.
**Target Hardware & Performance**: Stable 60 FPS on Intel Core i3-1115G4, 12 GB RAM, Intel UHD Graphics, GL Compatibility renderer in Godot 4.7.2.

---

## 2. Story-Free Gameplay Premise

The player (Yuan) awakens at the boundary of the Forbidden Forest, a primeval woodland corrupted by dark celestial resonance. Armed with the Celestial Staff, the player journeys deeper through five contiguous zones:
1. **Forest Entrance**: Awakening and initial orientation against corrupted scouts.
2. **Ancient Grove**: Overgrown elder glade guarded by the agile predator *Verdant Fang*.
3. **Cursed Bamboo Path**: Misty stalks and narrow ridges watched by the disciplined martial guardian *Bamboo Warden*.
4. **Forgotten Shrine**: Ancient stone ruins protected by the supernatural *Hollow Shrine Keeper*, whose defeat breaks the celestial barrier gating the inner sanctum.
5. **Forbidden Forest Heart**: The massive roots of the primordial world tree where the *Corrupted Forest Heart* unleashes two phases of corrupted wrath.

---

## 3. Room Layout & Architecture

The chapter consists of 5 tightly structured rooms managed by `WorldController` and `Room2D`:

```
+---------------------------+     +---------------------------+
|          ROOM 01          | --> |          ROOM 02          |
|      Forest Entrance      | <-- |       Ancient Grove       |
|    (Checkpoint 1)         |     |       (Checkpoint 2)      |
|  2-3 Forest Scouts        |     |   Boss 1: Verdant Fang    |
+---------------------------+     +---------------------------+
                                                |
                                                v
+---------------------------+     +---------------------------+
|          ROOM 04          | <-- |          ROOM 03          |
|     Forgotten Shrine      | --> |    Cursed Bamboo Path     |
|      (Checkpoint 4)       |     |       (Checkpoint 3)      |
| Boss 3: Hollow Keeper     |     |   Boss 2: Bamboo Warden   |
+---------------------------+     +---------------------------+
              |
         [Shrine Gate]
              v
+---------------------------+
|          ROOM 05          |
|   Forbidden Forest Heart  |
|      (Checkpoint 5)       |
| Final Boss: Forest Heart  |
|      (Phases 1 & 2)       |
+---------------------------+
```

### Room Specifications:
1. **Room 01: Forest Entrance (`room_01_forest_entrance`)**
   - Dimensions: 2400 x 1080 px
   - Purpose: Introduce forest aesthetics, immediate movement, basic combat with 2-3 Forest Scouts, Checkpoint 1, exit to Ancient Grove.
   - Spawns: `spawn_start` (x: 180, y: 920), `spawn_from_grove` (x: 2280, y: 920)
2. **Room 02: Ancient Grove (`room_02_ancient_grove`)**
   - Dimensions: 2560 x 1080 px
   - Purpose: First elite/intermediate boss encounter. Checkpoint 2 placed safely before the arena trigger. Arena bounds lock player into combat with *Verdant Fang*. Defeat unlocks the right exit to Cursed Bamboo Path.
   - Spawns: `spawn_from_entrance` (x: 150, y: 920), `spawn_from_bamboo` (x: 2420, y: 920)
3. **Room 03: Cursed Bamboo Path (`room_03_bamboo_path`)**
   - Dimensions: 2880 x 1080 px
   - Purpose: Elevation variation, mixed enemy encounters (Forest Scout, Thorn Beast, Spore Caster), Checkpoint 3, Boss arena with *Bamboo Warden*. Defeat unlocks exit to Forgotten Shrine.
   - Spawns: `spawn_from_grove` (x: 150, y: 920), `spawn_from_shrine` (x: 2720, y: 920)
4. **Room 04: Forgotten Shrine (`room_04_forgotten_shrine`)**
   - Dimensions: 2560 x 1080 px
   - Purpose: Atmospheric stone ruins and ancient lanterns. Encounters with Spore Caster and Thorn Beast. Checkpoint 4. Boss arena with *Hollow Shrine Keeper*. Defeating the Keeper sets persistent flag `hollow_shrine_keeper_defeated`, opening the celestial `AbilityGate` barrier into the Forest Heart.
   - Spawns: `spawn_from_bamboo` (x: 150, y: 920), `spawn_from_heart` (x: 2420, y: 920)
5. **Room 05: Forbidden Forest Heart (`room_05_forest_heart`)**
   - Dimensions: 2560 x 1080 px
   - Purpose: Final boss arena dominated by the corrupted ancient tree structure. Checkpoint 5 located at entrance. Boss encounter with *Corrupted Forest Heart* (Phase 1 -> Phase 2 transition at <=50% HP). Defeating the final boss triggers Chapter Completion UI and records `chapter_1_completed`.

---

## 4. Enemy Roster

All normal enemies utilize the existing `EnemyController` architecture and inherit `res://scenes/enemies/enemy_base.tscn`:

### 1. Forest Scout (`enemy_forest_scout`)
- **Role**: Fast agile melee skirmisher.
- **Stats**: Health 50, Poise 20, Move Speed 90, Chase Speed 140.
- **Behavior**: Aggressively patrols, detects player, sprints into range, and unleashes quick claw strikes.
- **Attack**: Claw Swipe — Damage 12, Poise Damage 8, Telegraph 0.30s, Active 0.12s, Recovery 0.30s, Cooldown 1.4s.
- **Counterplay**: Susceptible to parry, light combo stagger, or Mountain stance heavy impact.

### 2. Thorn Beast (`enemy_thorn_beast`)
- **Role**: Heavy frontline brute with high poise.
- **Stats**: Health 100, Poise 45, Move Speed 40, Chase Speed 70.
- **Behavior**: Slow, deliberate footsteps. Unflinching advance.
- **Attack**: Thorn Slam — Damage 22, Poise Damage 25, Telegraph 0.55s, Active 0.15s, Recovery 0.60s, Cooldown 2.2s.
- **Counterplay**: High poise resists light attacks; requires Mountain stance attacks, Perfect Dodge counter-windows, or Spirit abilities to stagger.

### 3. Spore Caster (`enemy_spore_caster`)
- **Role**: Stationary/kiting ranged caster.
- **Stats**: Health 45, Poise 15, Move Speed 50, Preferred Distance 180.
- **Behavior**: Maintains distance. Charges a telegraphed spore burst, launching a homing/linear spore projectile toward the player.
- **Attack**: Spore Shot — Spawns `EnemyProjectile` (Damage 15, Poise Damage 10, Speed 260 px/s). Telegraph 0.60s with luminous spore indicator.
- **Counterplay**: Can be dodged with I-frames, parried/reflected, or rushed down with Cloud Step / Swift stance.

---

## 5. Boss Roster & Mechanics

All bosses inherit `res://scenes/bosses/boss_base.tscn` and configure `BossData` resources.

### Intermediate Boss 1: "Verdant Fang"
- **Arena**: Room 02 (Ancient Grove)
- **Stats**: Health 220, Poise 45, Stagger Duration 1.8s, Move Speed 70, Chase Speed 120.
- **Theme**: Corrupted predator with rapid lunges and claw combos.
- **Attacks**:
  1. *Quick Pounce*: Fast leap forward across 140 px. Telegraph 0.35s, Damage 16.
  2. *Ground Claw Combo*: 2-hit swipe. Telegraph 0.40s, Damage 14 + 14.
  3. *Leap Back Reposition*: Quick retreat to reset spacing when pressured.
- **Recovery Window**: 0.7s vulnerable recovery after pounce landing.
- **Persistence Flag**: `&"verdant_fang_defeated"`

### Intermediate Boss 2: "Bamboo Warden"
- **Arena**: Room 03 (Cursed Bamboo Path)
- **Stats**: Health 280, Poise 55, Stagger Duration 1.8s, Move Speed 60, Chase Speed 100.
- **Theme**: Disciplined staff guardian with measured combos and sweeping strikes.
- **Attacks**:
  1. *Staff Triple Combo*: 3-hit cadence (Poke -> Overhead -> Sweeping Finisher). Telegraph 0.45s, Damage 12, 12, 18.
  2. *Bamboo Sweep*: Wide horizontal sweep covering 70 px. Telegraph 0.50s, Damage 20.
  3. *Defensive Stance / Guard Window*: Holds staff defensively; attacks against guard deflect unless broken with Mountain stance or heavy attack.
- **Persistence Flag**: `&"bamboo_warden_defeated"`

### Intermediate Boss 3: "Hollow Shrine Keeper"
- **Arena**: Room 04 (Forgotten Shrine)
- **Stats**: Health 340, Poise 70, Stagger Duration 2.0s, Move Speed 40, Chase Speed 70.
- **Theme**: Supernatural stone guardian wielding ancient spiritual sorcery.
- **Attacks**:
  1. *Earthquake Slam*: Slams stone weapon into the ground causing shockwave. Telegraph 0.65s (distinct warning tint), Damage 28, large hitbox.
  2. *Spiritual Spore Blast*: Conjures 2 homing spirit projectiles launched in quick succession.
  3. *Spirit Cleave*: Heavy sweeping strike with wide knockback. Telegraph 0.50s, Damage 22.
- **Persistence Flag**: `&"hollow_shrine_keeper_defeated"`. Opens the Shrine Gate barrier into Forest Heart.

---

## 6. Final Boss: "Corrupted Forest Heart" (Two Phases)

The apex encounter in Room 05. Uses `BossPhaseController` and two distinct `BossPhaseData` configurations.

### Phase 1: Corrupted Guardian
- **Stats**: Health 420 (Phase 1: 420 -> 210 HP), Poise 75.
- **Visuals**: Gnarled ancient bark, dark jade aura, steady menacing cadence.
- **Phase 1 Attacks**:
  1. *Root Strike Combo*: 2-hit crushing branch sweep. Damage 18, 20.
  2. *Root Spire*: Ground root eruption underneath player's position. Telegraph 0.60s with ground dust warning. Damage 25.
  3. *Spore Projectile*: Launches corrupted spore orb forward. Damage 16.
- **Pacing**: Deliberate, readable telegraphs with 0.8s punishable recovery windows. Teaches player attack cadences.

### Phase Transition (at 50% HP / 210 HP)
- Triggered seamlessly by `BossPhaseController`:
  - 1.0s Hitstop / cinematic freeze.
  - Phase transition visual: Boss flashes crimson/violet, shockwave particles erupt from core.
  - Boss state machine enters `BossPhaseTransitionState`, invulnerable during transition.
  - Arena lighting shifts to deeper corrupted purple/red tones.
  - Boss HUD phase badge updates: `PHASE 2: UNSTABLE CORRUPTION`.

### Phase 2: Unstable Corruption
- **Stats**: Health 210 -> 0 HP. Speed Multiplier: 1.35x, Attack Speed Multiplier: 1.25x, Damage Multiplier: 1.20x.
- **Visuals**: Pulsing violent violet aura, floating corrupted embers, aggressive animation speed.
- **Phase 2 Attacks**:
  1. *Frenzy Root Flurry*: Rapid 3-hit berserk combo with forward momentum. Damage 16, 16, 24. Shorter recovery (0.35s).
  2. *Corrupted Spore Burst*: Triple fan of homing spore projectiles.
  3. *Ground Rupture*: Arena-wide double shockwave requiring well-timed jumps or Cloud Step. Telegraph 0.50s, Damage 30.
- **Defeat & Completion**:
  - On HP <= 0, boss transitions to `BossDefeatedState` (shattering burst VFX, qi bounty).
  - Emits `EventBus.boss_defeated("Corrupted Forest Heart")`.
  - Sets persistent flag `&"chapter_1_completed"` and `&"corrupted_forest_heart_defeated"`.
  - Displays Chapter Completion Banner: "CHAPTER 1 COMPLETE — FORBIDDEN FOREST CLEARED".
  - Player remains controllable with no softlocks; checkpoint 5 remains available for testing or restart.

---

## 7. Checkpoints & Persistence Architecture

### Checkpoints:
1. `cp_entrance`: Room 01 (x: 400, y: 940) — Forest Entrance.
2. `cp_grove`: Room 02 (x: 350, y: 940) — Before Verdant Fang.
3. `cp_bamboo`: Room 03 (x: 400, y: 940) — Before Bamboo Warden.
4. `cp_shrine`: Room 04 (x: 350, y: 940) — Before Hollow Shrine Keeper.
5. `cp_heart`: Room 05 (x: 350, y: 940) — Before Corrupted Forest Heart.

### Persistence Contracts:
- `WorldState` flags:
  - `checkpoint_active_<id>`: Tracks activated checkpoints.
  - `verdant_fang_defeated`: Prevents Verdant Fang from respawning; arena barriers stay down.
  - `bamboo_warden_defeated`: Prevents Bamboo Warden from respawning; arena barriers stay down.
  - `hollow_shrine_keeper_defeated`: Prevents Hollow Shrine Keeper from respawning; keeps Shrine Gate open.
  - `corrupted_forest_heart_defeated`: Prevents Final Boss from respawning; preserves clear state.
  - `chapter_1_completed`: Persists chapter completion across saves.
- When player dies:
  - Respawns at the active checkpoint in the corresponding room.
  - Health (100) and Spirit (100) restored.
  - Defeated bosses stay defeated; no duplicate entities.

---

## 8. Base VFX Pass & Atmosphere

Conservative particle counts designed specifically for Intel UHD Graphics at stable 60 FPS:

### Player VFX:
- **Staff Attack Trail**: Translucent white/cyan motion trail following staff swing arcs.
- **Hit Sparks**: Crisp golden sparks erupting upon contact with enemy hurtboxes.
- **Heavy Impact**: Ring shockwave and dust burst for Mountain stance and heavy attacks.
- **Dodge Burst**: Swift white dust burst at player's feet upon dodge initiation.
- **Perfect Dodge**: Temporal distortion flash and jade ghost afterimage.
- **Parry Spark**: Bright radial golden spark burst upon successful parry.
- **Perfect Parry**: Radiant shockwave ring and brief hitstop flash.
- **Celestial Awakening Aura**: Golden particle emission and radiant hue overlay.

### Enemy & Boss VFX:
- **Hit Flash**: 0.08s white flash on hurtbox hit reception.
- **Telegraph Warning**: Subtle colored rectangular indicator tinting before attack frames.
- **Phase Transition Burst**: Radial dark violet energy ring emitted during Forest Heart Phase 2 transition.
- **Death Dissolve**: Fade-out and upward drifting qi motes on entity defeat.

### Environmental Atmosphere:
- **Forest Mist**: Low-density horizontal particle system simulating rolling ground mist.
- **Floating Spores / Leaves**: 15–20 ambient floating leaves and luminous spores drifting across the viewport.
- **Shrine Lantern Glow**: Gentle pulsing ambient lighting around stone lanterns in Room 04.

---

## 9. Performance Budget & Verification Plan

- **Draw Calls**: < 60 per frame.
- **Active Physics Bodies**: < 20 per room.
- **Particle Count**: < 80 total particles active simultaneously across environment and combat.
- **Target Frame Time**: <= 16.6 ms (stable 60 FPS).
- **Target Platform**: Windows 64-bit, Intel Core i3-1115G4, 12 GB RAM, Intel UHD Graphics, GL Compatibility.
