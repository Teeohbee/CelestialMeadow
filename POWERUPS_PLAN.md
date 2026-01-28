# Power-ups System Implementation Plan

## Overview
Add collectible power-ups that drop from destroyed asteroids, giving players temporary advantages.

## Power-up Types (Start Simple)
1. **Shield** - Brief invincibility (5 seconds)
2. **Rapid Fire** - Faster shooting (10 seconds)
3. **Speed Boost** - Increased thrust power (8 seconds)

## Implementation Steps (Atomic PRs)

### Step 1: Basic Power-up Scene and Pickup
**Branch:** `powerup-basic`

**What to Add:**
- New scene: `powerup.tscn` (Area2D with sprite/icon)
- New script: `powerup.gd` with type enum
- Collision detection with player
- Visual: Simple colored square (different color per type)
- Power-up floats in space, rotates slowly
- Despawns after 15 seconds if not collected

**Files Created:**
- `powerup.tscn`
- `powerup.gd`

**Key Concepts:**
- Area2D for pickups
- Timer for despawn
- Enum for power-up types

---

### Step 2: Drop from Asteroids
**Branch:** `powerup-drops`

**What to Add:**
- 30% chance to drop power-up when asteroid destroyed
- Random power-up type selection
- Spawn at asteroid's position
- Signal from asteroid when destroyed

**Files Modified:**
- `asteroid.gd` - Add power-up drop chance
- `main.gd` - Instantiate and spawn power-ups

**Key Concepts:**
- Random number generation (randi() % 100)
- Spawning objects at runtime
- Probability systems

---

### Step 3: Shield Power-up
**Branch:** `powerup-shield`

**What to Add:**
- Player becomes invincible when collected
- Visual feedback: Glowing outline or color shift
- Timer for duration (5 seconds)
- Bullets/collisions pass through player

**Files Modified:**
- `player.gd` - Add shield state, disable collision layer
- `powerup.gd` - Shield collection logic

**Key Concepts:**
- Collision layer manipulation
- Timed buffs
- Visual feedback for active effects

---

### Step 4: Rapid Fire Power-up
**Branch:** `powerup-rapidfire`

**What to Add:**
- Reduce shoot cooldown timer
- Visual: Weapon glow or particles
- Duration: 10 seconds
- Stack with existing fire rate (or not - design choice)

**Files Modified:**
- `player.gd` - Modify shoot timer when active

**Key Concepts:**
- Temporary stat modifications
- Timer management
- Stacking vs non-stacking buffs

---

### Step 5: Speed Boost Power-up
**Branch:** `powerup-speed`

**What to Add:**
- Double engine power temporarily
- Visual: Thruster effect enhancement
- Duration: 8 seconds
- Affects movement speed

**Files Modified:**
- `player.gd` - Modify engine_power when active

**Key Concepts:**
- Multiplier-based stat changes
- Restoring original values after buff

---

### Step 6: Visual Polish
**Branch:** `powerup-polish`

**What to Add:**
- Better power-up icons (shapes/symbols per type)
- Pickup sound effect
- Active power-up indicator on HUD
- Glowing/pulsing animation on power-ups
- Particle effect on collection

**Files Modified:**
- `powerup.tscn` - Better visuals
- `hud.gd` - Show active power-up icons
- Audio files added

**Key Concepts:**
- Animation and effects
- HUD updates
- Audio feedback

---

## Design Decisions

### Drop Rate
- 30% chance from asteroids (balanced - not too common/rare)
- Equal chance for each type (33% each)

### Duration
- Shield: 5 seconds (short but powerful)
- Rapid Fire: 10 seconds (fun to spam shots)
- Speed: 8 seconds (good for repositioning)

### Visual Identity
- Shield: Blue/Cyan color
- Rapid Fire: Red/Orange color
- Speed: Yellow/Green color

### Stacking Rules
- Same power-up: Reset timer (don't stack duration)
- Different power-ups: Can have multiple active at once

### Despawn
- 15 seconds before power-up disappears
- Visual warning at 5 seconds (blink faster)

---

## Testing Plan

**After Each Step:**
1. Destroy asteroid
2. Verify power-up spawns
3. Collect power-up
4. Verify effect works
5. Wait for effect to expire
6. Verify stats return to normal

**Edge Cases:**
- Player dies while powered up (effect should end)
- Collect same power-up twice (timer resets)
- Multiple power-ups active simultaneously
- Power-up spawns inside planet/station (push out?)

---

## Future Enhancements (Not in MVP)
- Multi-shot power-up (spread bullets)
- Health restore power-up (gain a life)
- Time slow power-up (bullet time effect)
- Magnet power-up (attracts more power-ups)
- Different drop rates per asteroid size (when implemented)

---

## Estimated Effort
- Step 1: 30 min (basic structure)
- Step 2: 20 min (drops)
- Step 3: 30 min (shield implementation)
- Step 4: 20 min (rapid fire)
- Step 5: 20 min (speed boost)
- Step 6: 45 min (polish)

**Total: ~2.5 hours across 6 PRs**

---

## Notes
- Keep power-ups simple and impactful
- Visual feedback is crucial for player understanding
- Test balance - adjust durations/drop rates as needed
- Each PR should be independently testable
