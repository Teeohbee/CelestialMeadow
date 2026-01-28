# Game Modes Implementation Plan

## Overview
Add two distinct game modes to create different play styles:
1. **Last Ship Standing** - Elimination mode with limited lives
2. **Timed Battle** - Score attack mode with respawning

---

## Implementation Steps (Each = One PR)

### Step 1: Lives System ✨
**Branch:** `lives-system`
**Description:** Add lives tracking for each player

**What to Add:**
- `lives` variable in `player.gd` (default: 3)
- Pass lives count from main scene to players
- Don't call `queue_free()` when destroyed - set invisible instead
- Decrement lives on death
- Only `queue_free()` when lives reach 0

**Files Modified:**
- `player.gd` - Add lives variable, modify `destroy()` method
- `game_state.gd` - Add `lives_per_player` variable

**Testing:**
- Player should survive first 2 deaths
- On 3rd death, player is eliminated
- Other players can still play

**Godot Concepts:**
- State management in nodes
- Conditional node removal

---

### Step 2: Respawn System 🔄
**Branch:** `respawn-system`
**Description:** Respawn players after death if they have lives remaining

**What to Add:**
- Timer in `main.gd` to respawn players
- Reset player position to starting location
- Reset player velocity
- Brief invincibility period (2 seconds) after respawn
- Visual indicator for invincibility (blinking/transparent)

**Files Modified:**
- `player.gd` - Add `respawn()` method, invincibility flag, visual feedback
- `main.gd` - Add respawn timer and logic

**Testing:**
- Player dies, waits 3 seconds, respawns at start position
- Invincible for 2 seconds after respawn
- Player blinks while invincible
- Bullets/collisions pass through during invincibility

**Godot Concepts:**
- Timers and delayed actions
- Collision layers/masks for invincibility
- Sprite modulation for visual effects
- `set_deferred()` for physics properties

---

### Step 3: Scoring System 📊
**Branch:** `scoring-system`
**Description:** Track points for destroying asteroids and players

**What to Add:**
- Score dictionary in `game_state.gd` (player_number -> score)
- Award points when bullet hits something:
  - Asteroid: 100 points
  - Enemy player: 300 points
- Signal from bullet to award points to shooter
- Pass player_number through bullet to track who shot

**Files Modified:**
- `game_state.gd` - Add scores dictionary, functions to add/get scores
- `bullet.gd` - Emit signal with shooter info when hit
- `main.gd` - Connect signals, award points
- `asteroid.gd` - Emit signal when destroyed (if not already)

**Testing:**
- Shoot asteroid, score goes up by 100
- Shoot enemy player, score goes up by 300
- Each player tracks their own score separately

**Godot Concepts:**
- Signals for game events
- Dictionary data structures
- Autoload/singleton pattern for game state

---

### Step 4: HUD System 🎮
**Branch:** `hud-system`
**Description:** Display lives, scores, and timer on screen

**What to Add:**
- New scene: `hud.tscn` (CanvasLayer with UI elements)
- Lives display for each player
- Score display for each player
- Timer display (for timed mode)
- Color-code each player's info to match ship color
- Update in real-time via signals or polling

**Files Created:**
- `hud.tscn` - UI layout
- `hud.gd` - Update display logic

**Files Modified:**
- `main.tscn` - Add HUD as child

**Testing:**
- Lives decrease when player dies
- Scores increase when player gets kills
- Timer counts down (initially always visible, will hide in elimination mode later)
- Each player's info is color-coded correctly

**Godot Concepts:**
- CanvasLayer for UI
- VBoxContainer/HBoxContainer for layout
- Label updates from code
- Color modulation for player identification

---

### Step 5: Timer System ⏱️
**Branch:** `timer-system`
**Description:** Add countdown timer for timed mode

**What to Add:**
- Timer in `main.gd` (default: 5 minutes)
- Countdown logic
- When timer reaches 0, trigger game end
- Show "Time's Up!" message
- Determine winner by highest score
- Handle ties (multiple winners)

**Files Modified:**
- `main.gd` - Add game timer, end-of-game logic
- `hud.gd` - Format and display time remaining

**Testing:**
- Timer counts down from 5:00 to 0:00
- At 0:00, game ends
- Winner declared based on highest score
- Tie message if multiple players have same top score

**Godot Concepts:**
- Time formatting (minutes:seconds)
- Finding max value in dictionary
- Multiple winners handling

---

### Step 6: Game Mode Selection 🎯
**Branch:** `game-mode-selection`
**Description:** Add mode selection to menu and configure gameplay accordingly

**What to Add:**
- New screen in menu flow: after player count, choose mode
- Two buttons: "Last Ship Standing" and "Timed Battle"
- Store choice in `game_state.gd`
- Configure `main.gd` based on mode:
  - **Elimination Mode:**
    - Enable lives system
    - Enable respawning
    - Disable timer
    - Hide score display
    - Use existing end-game (one player remains)
  - **Timed Battle:**
    - Infinite lives (or high number like 99)
    - Enable respawning
    - Enable timer
    - Show score display
    - End game when timer expires

**Files Created:**
- `mode_select.tscn` - Mode selection screen
- `mode_select.gd` - Mode selection logic

**Files Modified:**
- `menu.gd` - Navigate to mode select instead of main
- `game_state.gd` - Add `game_mode` variable
- `main.gd` - Configure based on selected mode

**Testing:**
- Select 2 players → Choose "Last Ship Standing" → Elimination gameplay
- Select 2 players → Choose "Timed Battle" → Score attack gameplay
- Each mode behaves correctly with its rules

**Godot Concepts:**
- Scene transitions and flow
- Conditional game logic based on mode
- UI navigation patterns

---

### Step 7: Polish & Balance 💎
**Branch:** `gamemode-polish`
**Description:** Tune values and add polish to both modes

**What to Add:**
- Tweak respawn delay (2-5 seconds?)
- Adjust invincibility duration
- Balance score values (asteroid vs player kills)
- Add sound effects for:
  - Respawn
  - Life lost
  - Timer warning (last 10 seconds?)
  - Victory fanfare
- Better victory screen formatting for timed mode (show all scores)
- Add "Press [button] to continue" instead of auto-return

**Files Modified:**
- Various files - constants and values
- Victory screen logic for better score display

**Testing:**
- Game feels balanced and fun in both modes
- Audio feedback is satisfying
- Victory screens are clear and informative

---

## Order of Implementation

**Phase 1: Core Systems (Steps 1-3)**
1. Lives System
2. Respawn System  
3. Scoring System

*At this point, you have all the mechanics but no UI/mode selection*

**Phase 2: Display & Timer (Steps 4-5)**
4. HUD System
5. Timer System

*Now you can see everything and timer works, but both modes run together*

**Phase 3: Mode Selection (Steps 6-7)**
6. Game Mode Selection
7. Polish & Balance

*Complete feature with two distinct, polished game modes*

---

## Alternative: Faster MVP Approach

If you want to see one complete mode faster:

**Option A: Elimination Mode First**
1. Lives System
2. Respawn System
3. HUD System (lives only)
4. Game Mode Selection (elimination only)
5. *Later: Add timed mode*

**Option B: Timed Mode First**
1. Scoring System
2. Respawn System (infinite lives)
3. Timer System
4. HUD System (score + timer)
5. Game Mode Selection (timed only)
6. *Later: Add elimination mode*

---

## Notes

- Each step should be small enough to complete and test independently
- Keep PRs focused on one feature
- Write educational PR descriptions explaining Godot concepts learned
- Test thoroughly before merging
- Update ROADMAP.md with each merge

## Estimated Complexity

- **Easy:** Steps 1, 3, 5 (Lives, Scoring, Timer)
- **Medium:** Steps 2, 4 (Respawn, HUD)
- **Moderate:** Steps 6, 7 (Mode Selection, Polish)

Total: ~7 PRs over multiple sessions
