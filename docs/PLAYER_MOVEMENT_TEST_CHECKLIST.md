# Player Movement Manual Test Checklist

**Project:** Echoes of the Celestial Staff  
**Phase:** Phase 2 (Player Controller)  
**Test Scene:** `res://scenes/world/test_player_room.tscn`  

Use this checklist during manual interactive testing sessions to verify feel, precision, and responsiveness.

---

### MOVEMENT
- [ ] **Move Left:** Pressing `A` / `Left Arrow` immediately accelerates player leftward without sluggish input delay.
- [ ] **Move Right:** Pressing `D` / `Right Arrow` immediately accelerates player rightward without sluggish input delay.
- [ ] **Stop Smoothly:** Releasing horizontal keys decelerates player crisply to a full stop within ~0.13s without ice-like sliding.
- [ ] **Maximum Speed:** Player reaches the 260 px/s speed cap quickly and sustains constant running velocity.
- [ ] **Visual Direction:** Player's visual indicator (red sash & eye) flips immediately upon changing movement direction.

---

### JUMP
- [ ] **Normal Jump:** Pressing `SPACE` launches the player upward with immediate crisp impulse.
- [ ] **Short Jump (Tap):** Quickly tapping `SPACE` cuts upward velocity early, producing a low hop suitable for low obstacles.
- [ ] **Full Jump (Hold):** Holding `SPACE` reaches the maximum jump height (~190 px, reaching the highest test platform).
- [ ] **Coyote Time:** Running off a platform ledge and tapping `SPACE` within ~7 frames (0.12s) successfully executes a jump mid-air.
- [ ] **Jump Buffer:** Pressing `SPACE` ~7 frames before touching the ground automatically triggers an immediate jump the instant the player lands.

---

### AIR CONTROL
- [ ] **Move in Air:** Left and right movement inputs adjust player horizontal trajectory while airborne.
- [ ] **Reverse Direction:** Reversing horizontal input mid-jump cleanly redirects trajectory without losing control.
- [ ] **Fall Acceleration:** Falling downward feels noticeably snappier and faster than ascending (`fall_gravity_multiplier = 1.4`).
- [ ] **Terminal Velocity:** Descending velocity caps predictably at `max_fall_speed = 650 px/s`.

---

### LANDING
- [ ] **Landing Detected:** Floor impact immediately switches state from `Fall` to `Land`.
- [ ] **No Unwanted Bounce:** Landing on solid ground is stable without jittering, floor snapping bugs, or unintended bounces.
- [ ] **Smooth Transition:** Brief landing state transitions seamlessly into `Run` if horizontal input is held, or `Idle` if stationary.

---

### RESPAWN
- [ ] **Falling Out of Bounds:** Jumping into the pit (Y > 1200 px) triggers the boundary check.
- [ ] **Player Respawns:** Player immediately teleports back to the test room `SpawnPoint`.
- [ ] **Velocity Reset:** All vertical and horizontal momentum is completely zeroed upon respawning.
- [ ] **State Reset:** State machine returns cleanly to `Idle`.

---

### GAME STATES & INTEGRATION
- [ ] **Pause Stops Movement:** Pressing `ESC` toggles pause; player freeze in place, horizontal inputs and gravity cease processing.
- [ ] **Resume Restores Movement:** Pressing `ESC` again resumes normal locomotion and physics processing without velocity spikes.

---

### PERFORMANCE & GAME FEEL
- [ ] **No Visible Stutter:** Movement remains at a locked 60 FPS on Intel UHD graphics baseline.
- [ ] **Telemetry Overlay (F3):** Pressing `F3` toggles the diagnostic overlay displaying real-time FPS, State, Facing, and Timers.
- [ ] **Zero Console Errors:** No warnings or parser errors appear in Godot console output during play.
