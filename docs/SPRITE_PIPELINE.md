# 3D MODEL → 2D SPRITE PIPELINE SPECIFICATION

**Project**: Echoes of the Celestial Staff  
**Engine**: Godot 4.7.2.stable.official.ed1daf0bf  
**Target**: 2D AnimatedSprite2D Gameplay Implementation  

---

## 1. Overview & Philosophy

While source character assets or animation rigs may originate in 3D (Blender / Maya / sculpting tools), *Echoes of the Celestial Staff* runs strictly as a high-performance **2D platformer**. 

Characters are rendered to **orthographic 2D sprite sheets / PNG frame sequences** before import into Godot. This eliminates 3D mesh evaluation, complex runtime skinning, and dynamic shadow passes, guaranteeing:
- Rock-solid 60 FPS on low-power hardware (Intel UHD Graphics / i3-1115G4).
- Deterministic 2D hitboxes, hurtboxes, and contact points.
- Zero 3D camera clipping or depth-sorting artifacts.

```
+------------------+
|  3D Rig / Model  | (Blender)
+------------------+
         |
         v
+------------------+
| Fixed Ortho Cam  | (15° pitch, fixed scale, 3-point lighting)
+------------------+
         |
         v
+------------------+
| Frame Rendering  | (Transparent PNG sequences)
+------------------+
         |
         v
+------------------+
|  Atlas Packing   | (Optimized sprite atlas / Godot SpriteFrames)
+------------------+
         |
         v
+------------------+
| AnimatedSprite2D | (Godot Engine character node)
+------------------+
```

---

## 2. Blender Render Specifications

To achieve complete visual harmony across all characters, enemies, and bosses, every render batch must conform to the following camera, lighting, and output parameters:

### A. Camera Setup
- **Camera Type**: Orthographic (Orthographic Scale = `2.4` for normal characters, `4.0` for large bosses).
- **Camera Pitch**: `15.0°` looking down from the front.
- **Camera Yaw**: `0.0°` (Strict horizontal side-profile for 2D platforming).
- **Camera Roll**: `0.0°`.
- **Clip Start / End**: `0.1m` / `50.0m`.

### B. Lighting Rig (Standard 3-Point Studio Setup)
1. **Key Light (Sun / Area)**:
   - Position: Top-left-front (X: -2.5m, Y: -3.0m, Z: 4.0m)
   - Color: Warm Sun (`#fff8e7`, 5500K)
   - Energy: 3.5
2. **Fill Light (Area)**:
   - Position: Bottom-right-front (X: 3.0m, Y: -2.0m, Z: 1.5m)
   - Color: Cool Sky Blue (`#d4e6f1`, 7500K)
   - Energy: 1.2
3. **Rim / Accent Light (Spot)**:
   - Position: High rear (X: 0.0m, Y: 3.5m, Z: 3.5m)
   - Color: Subtle Celestial White (`#ffffff`)
   - Energy: 4.0 (Provides crisp edge separation from dark backgrounds)

### C. Ground Contact & Pivot Invariant
- The model's origin `(0, 0, 0)` must rest precisely at the lowest point of ground contact (the soles of the character's feet).
- In Godot, the `AnimatedSprite2D` offset must ensure this ground pivot corresponds to `Vector2(0, 0)` in character local space.
- Never let character feet sink into or float above the ground line between animation loops.

---

## 3. Render Output & Dimensions

| Entity Category | Target In-Game Collision Size | Render Canvas Per Frame | Frames Per Second |
| :--- | :--- | :--- | :--- |
| **Yuan (Player)** | 18w x 46h px | 64 x 64 px | 24 fps |
| **Forest Scout** | 22w x 48h px | 64 x 64 px | 16 fps |
| **Thorn Beast** | 44w x 64h px | 96 x 96 px | 12 fps |
| **Spore Caster** | 20w x 52h px | 64 x 64 px | 12 fps |
| **Verdant Fang (Boss)** | 56w x 56h px | 128 x 96 px | 16 fps |
| **Bamboo Warden (Boss)** | 32w x 72h px | 96 x 128 px | 16 fps |
| **Hollow Shrine Keeper** | 48w x 76h px | 128 x 128 px | 16 fps |
| **Corrupted Forest Heart** | 96w x 110h px | 192 x 192 px | 16 fps |

---

## 4. Godot Import & Integration Rules

1. **Format**: 32-bit PNG with clean alpha channel (no fringe / premultiplied black halo).
2. **Texture Filtering**: Linear with Mipmaps (or Nearest-Neighbor if stylized pixel-art kit is chosen). In GL Compatibility mode on Intel UHD, 8-bit paletted or compressed PNGs are optimal.
3. **State Machine Binding**:
   - The animation controller drives `AnimatedSprite2D.play("animation_name")`.
   - Animation speeds match physics durations:
     `frame_speed = total_frames / action_duration`.
4. **Procedural Fallback**:
   - If an asset is missing or in development, `PlayerAnimationController`, `EnemyAnimationController`, and `BossAnimationController` gracefully fall back to procedural squash-and-stretch tweening to guarantee zero test breaks and zero crashes.
