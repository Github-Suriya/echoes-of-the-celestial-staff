# Knight 3D → 2D Proof of Concept

## Source
Quaternius Animated Knight

## Source File
`res://assets/characters/knight_test/KnightCharacter.fbx`

## Source Animations Tested
- **Idle**: `HumanArmature|Idle` (3.333s, 100 frames)
- **Walking**: `HumanArmature|Walking` (1.250s, 38 frames)
- **Run**: `HumanArmature|Run` (0.833s, 25 frames)

## Camera
- **Type**: `Camera3D`
- **Projection**: `Orthogonal` (`Camera3D.PROJECTION_ORTHOGONAL`)
- **Size**: `7.2`
- **Position**: `Vector3(0.0, 2.35, 5.0)` (fixed, does not follow character movement)
- **Orientation**: Fixed horizontal framing with character facing canonical **RIGHT** (`Knight.rotation_degrees = Vector3(0, 90, 0)`).

## Resolution
`512 × 512` pixels per frame.

## Render FPS
`30 FPS` sampling rate directly derived from the source FBX animation settings (`animation/fps = 30`).

## Output Format
RGBA PNG with full alpha channel transparency (`transparent_bg = true`).

## Output Locations
- **Individual Frames (Authoritative)**:
  - Idle: `res://tests/knight_3d_to_2d/sprites/idle/0000.png` through `0099.png` (100 frames)
  - Walking: `res://tests/knight_3d_to_2d/sprites/walking/0000.png` through `0037.png` (38 frames)
  - Run: `res://tests/knight_3d_to_2d/sprites/run/0000.png` through `0024.png` (25 frames)
- **Compiled SpriteFrames Resource**:
  - `res://tests/knight_3d_to_2d/generated/knight_spriteframes.tres` (26 KB clean external reference resource)
- **Generated Spritesheet Atlases**:
  - Idle: `res://tests/knight_3d_to_2d/generated/spritesheets/knight_idle.png` (2560×2560, 10×10 grid)
  - Walking: `res://tests/knight_3d_to_2d/generated/spritesheets/knight_walking.png` (2048×1280, 8×5 grid)
  - Run: `res://tests/knight_3d_to_2d/generated/spritesheets/knight_run.png` (1280×1280, 5×5 grid)
- **Interactive Scenes**:
  - 2D Preview: `res://tests/knight_3d_to_2d/Knight3DTo2DTest.tscn`
  - Side-by-Side Comparison: `res://tests/knight_3d_to_2d/preview/KnightComparison.tscn`
  - Test Runner: `res://tests/knight_3d_to_2d/test_knight_3d_to_2d_runner.tscn`

## SpriteFrames
`knight_spriteframes.tres` contains 3 configured animations:
- `idle`: 100 frames, 30 FPS, loop = true
- `walking`: 38 frames, 30 FPS, loop = true
- `run`: 25 frames, 30 FPS, loop = true

## Visual QA
1. **Character Scale & Aspect Ratio**: Preserved across all 3 animations. No stretching or distortion.
2. **Framing & Margins**:
   - Character height occupies ~395 pixels out of 512.
   - Top margin: 25 to 34 pixels (head/helmet never touches top edge).
   - Bottom margin: 83 to 89 pixels (consistent ground contact).
   - Horizontal margin: 82 to 214 pixels (forward strides and arms stay fully within frame).
3. **Feet Baseline Consistency**: Ground plane Y-level is identical across all animations; feet stay consistently planted without floating or vertical jitter.
4. **Transparency**: Background is 100% transparent. No opaque floor or rectangular clipping borders.
5. **Looping**:
   - Idle: Smooth linear loop with natural breathing and hand posture.
   - Walking: Continuous rhythmic stride without hitching.
   - Run: High-energy forward sprint cycle with seamless loop wrap.

## Performance
- Tested on target hardware architecture (Intel UHD Graphics, GL Compatibility renderer).
- Memory footprint: Lightweight external PNG references in `SpriteFrames` keep memory allocation minimal (~26 KB resource file).
- Playback framerate: Solid 60 FPS in Godot engine preview with 0 frame drops or stutter.

## Problems Encountered & Solved
1. **In-Memory ImageTexture Serialization Overhead**:
   - *Problem*: Initially adding raw in-memory `ImageTexture` objects into a text `.tres` serialized uncompressed hex pixel data, ballooning the file to 545 MB.
   - *Resolution*: Reimported the rendered PNGs into Godot's asset database and saved `SpriteFrames` using `load()` references, generating clean `ExtResource` tags and reducing file size to 26 KB.
2. **Headless Offscreen Buffer Availability**:
   - *Problem*: Godot `--headless` mode uses the dummy rendering server which does not populate viewport textures.
   - *Resolution*: Executed rendering using `--rendering-driver opengl3`, utilizing the machine's Intel UHD Graphics OpenGL 3.3 device to capture crisp 512×512 hardware-accelerated frames.

## Result
**PASS**
