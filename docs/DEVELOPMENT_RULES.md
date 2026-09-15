# Echoes of the Celestial Staff — Development Rules & GDScript Standards

**Document Version:** 1.0.0  
**Phase:** Phase 0 (Architecture & Design)  
**Target Engine:** Godot 4.7.2 Stable  

---

## 1. GDScript Coding Standards

### 1.1 Strict Static Typing Policy
All GDScript code in *Echoes of the Celestial Staff* must utilize explicit static typing. Unchecked dynamic `Variant` types are strictly forbidden unless handling generic event payloads.

```gdscript
# CORRECT: Explicit types for variables, parameters, and return types
var current_health: float = 100.0
var active_stances: Array[StanceData] = []

func apply_damage(amount: float, attacker: Node2D) -> bool:
    if amount <= 0.0:
        return false
    current_health = maxf(0.0, current_health - amount)
    health_changed.emit(current_health, max_health)
    return current_health == 0.0

# INCORRECT: Untyped declarations
var health = 100
func hit(dmg, source):
    health -= dmg
```

### 1.2 Naming Conventions
| Category | Convention | Examples |
| :--- | :--- | :--- |
| **Files & Folders** | `snake_case` | `player_controller.gd`, `health_component.tscn`, `forest_biome/` |
| **Classes & Custom Resources** | `PascalCase` | `class_name HealthComponent`, `class_name AttackData` |
| **Functions & Methods** | `snake_case` | `calculate_poise_break()`, `transition_to_state()` |
| **Variables & Properties** | `snake_case` | `stamina_regen_rate`, `is_perfect_dodge_ready` |
| **Private / Internal Members** | `_leading_underscore` | `var _input_buffer: Array[InputEvent]`, `func _handle_physics()` |
| **Constants & Enums** | `UPPER_SNAKE_CASE` | `const MAX_BUFFER_FRAMES: int = 8`, `enum Stance { SWIFT, MOUNTAIN, STORM }` |
| **Signals** | `snake_case` (descriptive) | `signal poise_broken`, `signal stance_swapped(new_stance: StanceData)` |

### 1.3 Script Structure & Ordering Template
All scripts must follow this standardized section order:

```gdscript
# 1. Class Name / Tool Declaration
class_name PlayerController
extends CharacterBody2D

# 2. Signals
signal combat_state_entered(state_name: StringName)

# 3. Enums & Constants
enum MoveState { IDLE, RUN, JUMP, FALL, ATTACK, DODGE }
const COYOTE_TIME_MAX: float = 0.12

# 4. Exported Variables (Grouped logically)
@export_group("Locomotion")
@export var move_speed: float = 240.0
@export var jump_force: float = -420.0

@export_group("References")
@export var health_component: HealthComponent
@export var state_machine: StateMachine

# 5. Public Variables
var is_facing_right: bool = true

# 6. Private / Internal Variables
var _coyote_timer: float = 0.0

# 7. @onready Variables
@onready var _animation_player: AnimationPlayer = $Visuals/AnimationPlayer
@onready var _hurtbox: HurtboxComponent = $Components/HurtboxComponent

# 8. Built-in Engine Callbacks (_init, _ready, _process, _physics_process)
func _ready() -> void:
    _setup_components()

func _physics_process(delta: float) -> void:
    _update_timers(delta)

# 9. Public Methods
func enter_cinematic_mode() -> void:
    pass

# 10. Private / Helper Methods
func _setup_components() -> void:
    pass
```

---

## 2. Architectural Design Rules

### 2.1 "Calls Down, Signals Up"
- **Rule:** A parent node can directly call methods on its child nodes (`_health_component.heal(25.0)`).
- **Rule:** A child node **must never** call methods directly on its parent (`get_parent().do_something()`). Child nodes must emit a signal instead (`request_parent_action.emit()`).
- **Violation:** Never use brittle path navigation such as `get_parent().get_parent().get_node("UI")`.

### 2.2 Global Communication via `EventBus`
- Cross-domain interactions (e.g., Player hits Boss -> HUD updates Boss Bar -> Screen Shakes -> Sound plays) must be mediated by the global `EventBus` singleton.
- Systems subscribe in `_ready()` and safely unsubscribe in `_exit_tree()`.

### 2.3 Separation of Logic and Presentation
- Gameplay state machines and combat calculations must not depend on animation frames or visual effects to execute their core logic.
- An attack's duration, hitbox activation window, and damage are dictated by its `AttackData` resource, while the `AnimationPlayer` simply visualizes that data.

### 2.4 Modular File Size Limit
- Scripts should remain focused. If any script exceeds **400 lines**, it must be decomposed into dedicated sub-components, state machine states, or helper utility classes.

---

## 3. Git & Version Control Guidelines

### 3.1 Conventional Commit Format
All git commit messages must adhere to the Conventional Commits specification:
- `feat:` A new gameplay feature, component, or system.
- `fix:` A bug fix in existing code.
- `refactor:` Code restructuring without functional changes.
- `perf:` A code or asset change that improves framerate or memory usage.
- `docs:` Documentation additions or updates.
- `chore:` Maintenance tasks, gitkeep files, project setting updates.

### 3.2 Commit Discipline
- Make **atomic commits** (one logical change per commit).
- Never commit broken or non-compiling code to the `main` branch.
- Ensure `git status` is clean before and after phase milestones.
- Never commit `.godot/` cache files, crash logs, or temporary editor dumps.

---

## 4. Testing & Quality Assurance Standards

### 4.1 Zero Warnings Policy
- All GDScript files must pass Godot's static analyzer with **0 errors and 0 warnings**.
- Treat all engine warnings (untyped variables, unused parameters, shadow variables) as errors to be resolved immediately.

### 4.2 Headless Engine Verification
- Any architectural milestone must be verifiable via the headless console runner:
  ```powershell
  Godot_v4.7.2-stable_win64_console.exe --headless --check-only --path .
  ```
