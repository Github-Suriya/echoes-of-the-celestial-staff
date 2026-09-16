# Phase 10 — Metroidvania World System Foundation Implementation Plan

**Document Version:** 1.0.0  
**Status:** In Review  
**Target Engine:** Godot 4.7.2.stable.official.ed1daf0bf  
**Renderer:** GL Compatibility  
**Target Platform:** Windows PC (Intel Core i3-1115G4 / Intel UHD Graphics / 12 GB RAM / 60 FPS)

---

## 1. Executive Summary & Objective

The objective of **Phase 10** is to implement the **FOUNDATION of the Metroidvania world system** for *Echoes of the Celestial Staff*. This moves the project from isolated standalone test rooms into a modular, reusable, interconnected 2D world architecture.

### Key Systems to Implement
1. **WorldController**: Central world manager coordinating active rooms, transitions, player spawning, camera clamping, checkpoints, and persistent state without duplicating game logic.
2. **Room2D Template & Hierarchy**: Extensible base scene and script with deterministic node hierarchy (Geometry, CameraBounds, SpawnPoints, Entrances, Exits, Doors, Enemies, Checkpoints, PersistentObjects).
3. **RoomData Resource**: Decoupled data model specifying room IDs, scene paths, camera bounds, spawn point IDs, and connections.
4. **Deterministic Room Lifecycle**: Explicit state transitions (`UNLOADED` -> `LOADING` -> `LOADED` -> `ACTIVE` -> `EXITING` -> `UNLOADING` -> `UNLOADED`).
5. **Asynchronous-Ready Room Loading & Transitions**: Seamless room swapping, zero velocity drift, no duplicate player instances, and no duplicate EventBus connections.
6. **Camera Bounds**: Automatic updating of the player's `Camera2D` limits (`limit_left`, `limit_top`, `limit_right`, `limit_bottom`) and smoothing reset to prevent camera jumps or exposing out-of-bounds void.
7. **Persistent World State (`WorldState`)**: Deterministic String/StringName key-value flag persistence (`granite_abbot_defeated`, opened gates, chests).
8. **SaveManager Integration**: Clean serialization/deserialization into existing versioned slots without modifying `SaveManager`.
9. **Ability-Gated Doors (`AbilityGate`)**: Progression-based barriers ("Celestial Arc Gate", "Cloud Step Gate") checking progression unlock state.
10. **Player Capabilities Query Interface (`PlayerCapabilities`)**: Clear distinction between combat availability and progression unlocks, with debug grant shortcuts.
11. **Checkpoint Foundation (`Checkpoint`)**: Activation triggers, active respawn tracking, and status restoration.
12. **Persistent World Objects (`PersistentWorldObject`)**: Lightweight state synchronization hooks.
13. **Granite Abbot World Integration**: Defeated boss remains permanently defeated on room re-entry via world state flag `"granite_abbot_defeated"`.
14. **World EventBus Signals**: Decoupled event emissions for world and room transitions.
15. **3-Room Connected Test World (`scenes/world/test_world/`)**: Room A ("Celestial Outskirts"), Room B ("Granite Passage"), and Room C ("Awakening Chamber").
16. **World Debug Telemetry & Controls**: Real-time stats display and debug shortcuts ([R], [T], [C], [F], [1], [2], [3]).
17. **Automated Test Suite (`tests/test_world.gd`)**: 120+ tests validating all systems with zero regressions on existing 826 tests (946+ total).

---

## 2. Architectural Boundaries & Non-Goals

### Strict Architectural Rule
We will **NOT** replace, rewrite, or break existing core singletons or controllers:
- `GameManager`
- `SceneManager`
- `SaveManager`
- `PlayerController`
- `CombatController`
- `EnemyController`
- `BossController`
- `StanceController`
- `SpiritAbilityController`
- `TransformationController`

`WorldController` and `Room2D` coordinate these systems; they do not duplicate their responsibilities.

### Strict Scope Boundaries (Out of Scope for Phase 10)
- Complete game map / full biomes
- Final environmental or background art
- Procedural generation or chunk streaming
- Minimap or full-screen map UI
- Fast travel / leyline teleport network
- Quest system, dialogue, or NPC interactions
- Inventory, equipment, loot, or currencies
- Skill tree or XP progression system

---

## 3. World & Room Architecture

### 3.1 WorldController (`scripts/world/world_controller.gd`)
The `WorldController` is a persistent `Node2D` that hosts the world scene.
```
WorldController (Node2D)
├── WorldState (Node / RefCounted)
├── PlayerCapabilities (Node / RefCounted)
├── RoomsContainer (Node2D)
│   └── [Active Room2D instance]
├── Player (PlayerController - kept persistent across transitions)
├── WorldDebugOverlay (CanvasLayer)
└── TransitionCurtain (CanvasLayer / ColorRect for fade-to-black)
```

**Responsibilities:**
- Registry of known rooms (`Dictionary[StringName, RoomData]`).
- Tracking `current_room_id: StringName` and `active_room: Room2D`.
- Tracking `active_checkpoint_room_id` and `active_checkpoint_spawn_id`.
- Coordinating room transition requests via `request_room_transition(destination_room_id, destination_spawn_id)`.
- Re-entrancy guard: rejects duplicate transition requests while `is_transitioning == true`.
- Repositioning player at target spawn point and resetting velocity (`player.velocity = Vector2.ZERO`).
- Setting player camera limits to match `active_room.get_camera_bounds()` and calling `camera.reset_smoothing()`.
- Synchronizing room persistent objects with `WorldState`.

### 3.2 Room2D Template (`scenes/world/room_2d.tscn` & `scripts/world/room_2d.gd`)
Standardized node hierarchy:
```
Room2D (Node2D)
├── Geometry (StaticBody2D / TileMapLayer)
├── CameraBounds (ReferenceRect)
├── SpawnPoints (Node2D)
│   ├── Spawn_Default (Marker2D)
│   └── Spawn_From_X (Marker2D)
├── Entrances (Node2D)
├── Exits (Node2D)
│   └── Exit_To_X (RoomExit / Area2D)
├── Doors (Node2D)
│   └── AbilityGate_Arc (AbilityGate)
├── Enemies (Node2D)
├── Checkpoints (Node2D)
│   └── Checkpoint_1 (Checkpoint)
└── PersistentObjects (Node2D)
    └── Persistent_Door_1 (PersistentWorldObject)
```

**Room Lifecycle States:**
```
UNLOADED
  │  (Resource load / instantiate)
  ▼
LOADING
  │  (Node tree ready / initialize)
  ▼
LOADED
  │  (Add to tree, apply state, position player, clamp camera)
  ▼
ACTIVE
  │  (Transition exit triggered)
  ▼
EXITING
  │  (Zero velocity, freeze input, save object states)
  ▼
UNLOADING
  │  (queue_free / remove from tree)
  ▼
UNLOADED
```

### 3.3 RoomData Resource (`scripts/world/room_data.gd`)
```gdscript
class_name RoomData
extends Resource

@export var room_id: StringName = &""
@export var display_name: String = ""
@export_file("*.tscn") var scene_path: String = ""
@export var room_bounds: Rect2 = Rect2(0, 0, 1920, 1080)
@export var spawn_point_ids: Array[StringName] = []
@export var connections: Dictionary = {} # exit_id -> { "destination_room_id": StringName, "destination_spawn_id": StringName }
```

---

## 4. Room Loading & Transition Strategy

### Transition Pipeline
1. Player enters `RoomExit` trigger Area2D.
2. `RoomExit` signals `WorldController.request_room_transition(destination_room_id, destination_spawn_id)`.
3. If `is_transitioning == true`, request is safely rejected.
4. Set `is_transitioning = true`. Emit `EventBus.room_exit_started(from_id, to_id)`.
5. Freeze player velocity (`player.velocity = Vector2.ZERO`).
6. Active room state is recorded: persistent objects write to `WorldState`.
7. Active room lifecycle becomes `EXITING` -> `UNLOADING`. Room is removed from tree and freed via `queue_free()`.
8. Emit `EventBus.room_unloaded(old_room_id)`.
9. Target room is loaded and instantiated: `LOADING` -> `LOADED`.
10. Emit `EventBus.room_loading_started(new_room_id)` and `EventBus.room_loaded(new_room_id)`.
11. Add new room to `RoomsContainer`.
12. Resolve target spawn point: `new_room.get_spawn_position(destination_spawn_id)`.
13. Set player position: `player.global_position = spawn_pos`.
14. Set player facing direction matching spawn point or transition direction.
15. Clamp camera limits:
    - `player.camera.limit_left = int(bounds.position.x)`
    - `player.camera.limit_top = int(bounds.position.y)`
    - `player.camera.limit_right = int(bounds.position.x + bounds.size.x)`
    - `player.camera.limit_bottom = int(bounds.position.y + bounds.size.y)`
    - `player.camera.reset_smoothing()`
16. Sync room persistent objects: `new_room.sync_persistent_objects(world_state)`.
17. Activate room: `new_room.activate_room()`.
18. Emit `EventBus.room_activated(new_room_id)`.
19. Reset `is_transitioning = false`.

---

## 5. Camera Bounds System

In `scenes/player/player.tscn`, `PlayerController` has a child `Camera2D` with smoothing enabled (`position_smoothing_speed = 8.0`) and horizontal look-ahead (`camera.offset.x`).
- `WorldController` updates `limit_left`, `limit_top`, `limit_right`, and `limit_bottom` on the player camera directly whenever a room activates.
- Calling `camera.reset_smoothing()` ensures the camera snaps to the new clamped room coordinates instantaneously during transition without panning across the black void between rooms.
- Normal look-ahead offset continues to function smoothly within the clamped camera limits.

---

## 6. Persistent World State & Save Integration

### 6.1 WorldState (`scripts/world/world_state.gd`)
- Tracks arbitrary boolean flags and state dictionaries using string/StringName keys.
- Methods:
  - `set_flag(flag: StringName, value: bool = true) -> void`
  - `get_flag(flag: StringName, default_val: bool = false) -> bool`
  - `has_flag(flag: StringName) -> bool`
  - `clear_flag(flag: StringName) -> void`
  - `reset() -> void`
  - `serialize() -> Dictionary`
  - `deserialize(data: Dictionary) -> void`
- Emits `EventBus.world_flag_changed(flag_name, value)`.

### 6.2 SaveManager Integration
Existing `SaveManager` (`scripts/core/save_manager.gd`) accepts an `extra_data: Dictionary` parameter in `save_to_slot(slot, extra_data)`:
```gdscript
var payload: Dictionary = {
    "world_state": world_state.serialize(),
    "player_capabilities": capabilities.serialize(),
    "active_checkpoint": {
        "room_id": active_checkpoint_room_id,
        "spawn_id": active_checkpoint_spawn_id
    }
}
SaveManager.save_to_slot(slot, payload)
```
When loading:
```gdscript
var data: Dictionary = SaveManager.load_from_slot(slot)
if data.has("world_state"):
    world_state.deserialize(data["world_state"])
if data.has("player_capabilities"):
    capabilities.deserialize(data["player_capabilities"])
if data.has("active_checkpoint"):
    active_checkpoint_room_id = data["active_checkpoint"].get("room_id", &"")
    active_checkpoint_spawn_id = data["active_checkpoint"].get("spawn_id", &"")
```
This achieves 100% backward and forward compatibility with zero modifications required in `SaveManager`.

---

## 7. Ability Gates & Player Capabilities

### 7.1 Player Capabilities (`scripts/world/player_capabilities.gd`)
Clear separation between combat actions and progression unlocks:
- Combat abilities (Phase 6) are active gameplay skills.
- Player capabilities (Phase 10) are progression gating flags.
- Methods:
  - `has_ability(ability_id: StringName) -> bool`
  - `unlock_ability(ability_id: StringName) -> void`
  - `lock_ability(ability_id: StringName) -> void`
  - `clear_capabilities() -> void`
  - `get_unlocked_abilities() -> Array[StringName]`
  - `serialize() -> Array[String]`
  - `deserialize(data: Array) -> void`

### 7.2 AbilityGate (`scripts/world/ability_gate.gd`)
- `gate_id: StringName`
- `required_ability: StringName` (e.g. `&"celestial_arc"`, `&"cloud_step"`)
- `required_flag: StringName` (optional secondary requirement)
- `is_open: bool = false`
- Visual representation: Glowing celestial barrier pillar with distinct runes/colors for Celestial Arc (golden/cyan) and Cloud Step (wind/white).
- Collision: `StaticBody2D` on Layer 1 (World Geometry).
- Interaction: When player approaches or strikes, checks `world_controller.capabilities.has_ability(required_ability)`.
  - If unlocked: barrier dissolves (`collision_layer = 0`, `visible = false`), sets flag `&"gate_opened_" + gate_id`, emits `EventBus.ability_gate_opened(gate_id)`.
  - If locked: barrier remains solid, emits feedback pulse.
  - On room load: if `world_state.has_flag(&"gate_opened_" + gate_id)`, initializes directly in open state.

---

## 8. Checkpoint Foundation (`scripts/world/checkpoint.gd`)

- `checkpoint_id: StringName`
- `room_id: StringName`
- `spawn_point_id: StringName`
- `is_active: bool = false`
- Visual indicator: Spirit shrine monolith changing from dormant jade to active radiant gold upon activation.
- Behavior:
  - When touched by player:
    - Sets active checkpoint on `WorldController`.
    - Restores player Health (`HealthComponent.restore_health(max_health)`) and Spirit (`SpiritComponent.restore_spirit(max_spirit)`).
    - Records `&"checkpoint_active_" + checkpoint_id` in `WorldState`.
    - Emits `EventBus.checkpoint_activated(String(checkpoint_id))`.
- Player respawn:
  - When player dies or resets, `WorldController.respawn_player_at_checkpoint()` transitions to the checkpoint room at the checkpoint spawn point.

---

## 9. Granite Abbot Encounter Persistence

- Defeat flag: `"granite_abbot_defeated"`.
- In `BossArenaController` / Boss Room:
  - When the boss room loads, it queries `world_state.has_flag("granite_abbot_defeated")`.
  - If `true`:
    - Granite Abbot node is disabled / removed.
    - Arena barriers remain lowered / open.
    - Boss HUD is hidden.
    - Trigger zone is deactivated.
  - If `false`:
    - Boss encounter functions normally.
    - When Granite Abbot is defeated, `BossArenaController._on_boss_defeated()` marks `world_state.set_flag("granite_abbot_defeated", true)`.

---

## 10. Test World Design (`scenes/world/test_world/`)

We construct a 3-room test world:
```
           ┌────────────────────────────────────────┐
           │        Room C: Awakening Chamber       │
           │        (Celestial Arc Gate required)   │
           └───────────────────▲────────────────────┘
                               │ (Celestial Arc Gate)
┌──────────────────────────────┴────────────────────┐      Normal Exit      ┌──────────────────────────────────────────────┐
│            Room A: Celestial Outskirts            │ ◄───────────────────► │          Room B: Granite Passage             │
│   - Initial Player Spawn ("start")                │                       │   - Granite Abbot Boss Arena                 │
│   - Spirit Checkpoint ("checkpoint_a")            │                       │   - Cloud Step Gate to side cavern           │
│   - Exit to Room B ("exit_to_b")                  │                       │   - Return Exit to Room A ("exit_to_a")      │
│   - Celestial Arc Gate to Room C ("gate_arc")     │                       └──────────────────────────────────────────────┘
└───────────────────────────────────────────────────┘
```

1. **Room A ("Celestial Outskirts", `room_a.tscn`)**:
   - Size: 1920 x 1080.
   - Spawns: `&"start"`, `&"from_room_b"`, `&"from_room_c"`.
   - Checkpoint: `&"checkpoint_a"`.
   - Normal exit to Room B.
   - Celestial Arc Gate guarding upper path to Room C.
2. **Room B ("Granite Passage", `room_b.tscn`)**:
   - Size: 2400 x 1080.
   - Spawns: `&"from_room_a"`.
   - Normal exit back to Room A.
   - Cloud Step Gate guarding a secondary path.
   - Granite Abbot encounter with world persistence integration.
3. **Room C ("Awakening Chamber", `room_c.tscn`)**:
   - Size: 1920 x 1080.
   - Spawns: `&"from_room_a"`.
   - Exit back to Room A.
   - Sacred altar & checkpoint `&"checkpoint_c"`.

---

## 11. Debug Tools & Telemetry

Overlay in `test_world.tscn`:
- Current Room ID & Room Name
- Room Lifecycle State (`LOADED`, `ACTIVE`, etc.)
- Player Coordinates & Spawn Point ID
- Active Checkpoint ID
- Unlocked Capabilities (`celestial_arc`, `cloud_step`)
- Active World Flags
- Transition Lock State

Debug keybindings:
- `[R]`: Respawn at active checkpoint
- `[T]`: Restore 100 Spirit
- `[C]`: Cycle combat stance (Swift -> Mountain -> Storm)
- `[F]`: Activate Celestial Awakening
- `[1]`: Toggle unlock capability: Celestial Arc
- `[2]`: Toggle unlock capability: Cloud Step
- `[3]`: Clear all unlocked capabilities

---

## 12. Automated Testing Strategy (`tests/test_world.gd`)

We implement 120+ tests in `tests/test_world.gd` executed by `tests/test_world_runner.tscn`.

### Test Categories (120 Tests Target)
1. **WORLD-DATA (10 tests)**: RoomData resource creation, property validation, scene paths existence, bounding boxes, spawn mapping, exit connection mappings.
2. **CAPABILITIES (10 tests)**: Progression query API, unlock/lock abilities, serialization/deserialization, debug grants, decoupling from combat spirit costs.
3. **WORLD-STATE (12 tests)**: Set flag, get flag, has flag, clear flag, persistence across state queries, serialization, deserialization, idempotency.
4. **ROOM-LIFECYCLE (12 tests)**: Unloaded -> Loading -> Loaded -> Active -> Exiting -> Unloading deterministic progression, duplicate load prevention.
5. **TRANSITIONS (12 tests)**: Room A -> Room B, Room B -> Room A, destination spawn resolution, player repositioning, velocity reset to zero, no duplicate player nodes.
6. **CAMERA-BOUNDS (10 tests)**: Camera limit assignment (`limit_left`, `limit_top`, `limit_right`, `limit_bottom`), bounds updating on room transition, smoothing reset verification, look-ahead offset preservation.
7. **ABILITY-GATES (12 tests)**: Locked barrier blocks player on Layer 1, query capability requirement, open gate when capability granted, Celestial Arc Gate, Cloud Step Gate, persistent open state on room re-entry.
8. **CHECKPOINTS (10 tests)**: Activation trigger, active checkpoint tracking, player respawn coordinates matching checkpoint, persistent checkpoint flag, health/spirit restoration.
9. **PERSISTENT-OBJECTS (8 tests)**: PersistentWorldObject registration, unique persistent IDs, recording state to WorldState, restoring state on room load.
10. **BOSS-PERSISTENCE (10 tests)**: Granite Abbot encounter sets `"granite_abbot_defeated"` upon victory, room re-entry suppresses boss reactivation, barriers remain unlocked, boss HUD not displayed.
11. **SAVE-INTEGRATION (10 tests)**: Integration with SaveManager slot serialization, restoring world state, capabilities, and checkpoint from slot without breaking SaveManager schema.
12. **SAFETY-AND-ERRORS (14 tests)**: Simultaneous transition rejection, invalid room handling, invalid spawn fallback, null safety, signal disconnection safety.

### Full Regression Verification
All 826 existing tests across Phase 1 through Phase 9.1 must pass with 0 failures, 0 parser errors, and 0 warnings:
- Foundation: 45/45
- Locomotion: 48/48
- Combat Foundation: 91/91
- Advanced Defense: 84/84
- Stances: 64/64
- Spirit Abilities: 95/95
- Transformation: 113/113
- Enemy AI: 133/133
- Boss Framework: 153/153
- **Total Existing Baseline: 826 / 826**
- **Phase 10 Target: 120 / 120**
- **Expected Total: 946+ / 946+**
