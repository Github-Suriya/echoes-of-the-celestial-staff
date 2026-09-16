# Echoes of the Celestial Staff — Combat Foundation Test Checklist

**Phase:** Phase 3 — Combat Foundation  
**Version:** 1.0.0  
**Test Environment:** `res://scenes/world/test_combat_room.tscn`  
**Engine:** Godot 4.7.2 Stable (`4.7.2.stable.official.ed1daf0bf`)  
**Renderer:** GL Compatibility  

This checklist documents manual and automated verification criteria for the Phase 3 Core Combat Foundation.

---

### BASIC ATTACK
- [x] **Attack button works**: Pressing `KEY_J` or Left Mouse Button initiates attack.
- [x] **Attack starts immediately**: Zero perceived input latency upon action press.
- [x] **Startup feels responsive**: Quick 4-frame (67ms) windup creates snappy feedback without feeling instantaneous or disconnected.
- [x] **Hitbox appears only during active phase**: Hitbox monitoring is enabled strictly during active frames.
- [x] **Hitbox disappears afterward**: Hitbox monitoring is disabled immediately upon entering recovery.
- [x] **Attack returns to movement**: State machine cleanly returns to `Idle`, `Run`, or `Fall` upon recovery completion.

### COMBO
- [x] **Light 1 works**: Staff jab deals 10 damage and 12 poise damage with minor step forward.
- [x] **Light 2 works**: Follow-up horizontal staff sweep deals 12 damage and 14 poise damage.
- [x] **Light 3 works**: Combo finisher deals 18 damage and 22 poise damage with high knockback.
- [x] **Combo buffer works**: Chained attack inputs pressed early during active or recovery are stored and chained.
- [x] **Combo timing feels natural**: Fluid rhythm inspired by character action standards; combo window allows comfortable chaining without frame-perfect execution.
- [x] **Combo expires correctly**: If attack input is withheld during recovery, sequence resets to neutral locomotion.

### HEAVY
- [x] **Heavy attack works**: Pressing `KEY_K` or Right Mouse Button initiates Heavy Overhead Smash.
- [x] **Heavy feels slower**: 14-frame windup (233ms) communicates deliberate, weighty commitment.
- [x] **Heavy deals more impact**: 25 damage with heavy visual squash/stretch.
- [x] **Heavy produces more poise damage**: 35 poise damage immediately threatens enemy posture.
- [x] **Heavy knockback works**: High velocity knockback Vector2(240, -80) launches targets across the floor.

### HIT DETECTION
- [x] **Attack hits dummy**: Hitbox overlaps dummy Hurtbox, delivering payload.
- [x] **Attack misses correctly**: Swings outside hurtbox range register as whiffs without triggering damage or hitstop.
- [x] **No hits outside active frames**: Overlapping target during startup or recovery inflicts zero damage.
- [x] **No duplicate damage from one hit**: Hitbox tracks damaged hurtboxes per swing, preventing multiple hits per swing.

### FACING
- [x] **Right attack hits right side**: Facing right (+1) positions hitbox at `+28.0` on X axis.
- [x] **Left attack hits left side**: Facing left (-1) positions hitbox at `-28.0` on X axis.
- [x] **Collision remains stable**: Collision shapes are never inverted, scaled negatively, or deformed during facing changes.

### REACTION
- [x] **Dummy loses HP**: Target `HealthComponent` decreases by exact attack damage amount.
- [x] **Dummy receives knockback**: Knockback velocity impulse pushes target along hit vector.
- [x] **Dummy loses poise**: Target `PoiseComponent` accumulates poise damage.
- [x] **Dummy staggers**: When poise reaches zero, dummy enters `STAGGERED` guard break state with celestial gold visual indication for 1.5s.
- [x] **Hitstop occurs**: `GameManager.apply_hitstop()` produces momentary micro-freeze on hit without freezing the engine permanently.

### INPUT
- [x] **Attack buffering works**: Early attack inputs captured up to 350ms before execution.
- [x] **Movement remains responsive**: Transition between locomotion and combat is seamless with ground friction dampening.
- [x] **Pause prevents attack processing**: Pausing via `ESC` halts combat timers and input execution.

### DEBUG
- [x] **Combat debug overlay works**: F3 overlay displays FPS, Player State, Attack ID, Attack Phase, Phase Timer, Combo Index, Hitbox status, and Hitstop state.
- [x] **Hitbox visualization works**: Godot debug collision shapes / overlay shows exact hit areas.
- [x] **No runtime errors**: Console runs with zero errors, zero warnings, zero orphan nodes.

### PERFORMANCE
- [x] **No visible stutter**: Constant 60 FPS physics processing on GL Compatibility renderer.
- [x] **No excessive allocations**: Hitboxes and hurtboxes pre-allocated and toggled; zero runtime Area2D churn.
- [x] **No frame spikes during attacks**: Zero dynamic script compilation or unpooled instantiation during hits.
