extends Node

## Game configuration constants
## Central location for all game balance values and magic numbers

# Player Stats
const PLAYER_ENGINE_POWER: int = 500
const PLAYER_SPIN_POWER: int = 4000
const PLAYER_SHOOT_DELAY: float = 0.25
const PLAYER_LIVES_DEFAULT: int = 3
# Lives for modes where ships respawn forever
const UNLIMITED_LIVES: int = -1
const PLAYER_RESPAWN_DELAY: float = 3.0
const PLAYER_INVINCIBILITY_DURATION: float = 2.0
const PLAYER_INVINCIBILITY_BLINK_DURATION: float = 0.2
const PLAYER_INVINCIBILITY_ALPHA_MIN: float = 0.3
const PLAYER_INVINCIBILITY_BLINK_COUNT: int = 10

# Respawn Marker
const SPAWN_MARKER_RADIUS: float = 36.0
const SPAWN_MARKER_WIDTH: float = 4.0
const SPAWN_MARKER_PULSE_DURATION: float = 0.4
const SPAWN_MARKER_BURST_DURATION: float = 0.4
const SPAWN_MARKER_BURST_SCALE: float = 3.0

# Power-up Durations
const POWERUP_SHIELD_DURATION: float = 5.0
const POWERUP_RAPID_FIRE_DURATION: float = 10.0
const POWERUP_RAPID_FIRE_MULTIPLIER: float = 0.5
const POWERUP_SPEED_DURATION: float = 8.0
const POWERUP_SPEED_MULTIPLIER: float = 2.0
const POWERUP_DROP_CHANCE: float = 0.3
const POWERUP_DESPAWN_TIME: float = 15.0

# Shield Visual
const SHIELD_RADIUS: int = 40
const SHIELD_SEGMENTS: int = 32
const SHIELD_COLOR: Color = Color(0, 0.8, 1.0, 0.3)

# Asteroid Settings
const ASTEROID_INITIAL_COUNT: int = 10
const ASTEROID_MAX_COUNT: int = 10
const ASTEROID_SPAWN_COUNT: int = 2
const ASTEROID_MIN_SPEED: float = 100.0
const ASTEROID_MAX_SPEED: float = 200.0

# Time Attack
const TIME_ATTACK_DURATION: float = 120.0

# Title Screen
const TITLE_MIN_PLAYERS: int = 2
const TITLE_LAUNCH_DELAY: float = 1.5
const TITLE_ASTEROID_COUNT: int = 6
const TITLE_ASTEROID_SPEED: float = 45.0

# Camera Effects
const CAMERA_SHAKE_EXPLOSION: float = 20.0
const CAMERA_SHAKE_ASTEROID: float = 12.0

# Game Flow Timing
const END_GAME_CHECK_DELAY: float = 0.5
const RESULTS_INPUT_LOCK: float = 1.0

# Player Colors
const PLAYER_COLORS: Array[Color] = [
	Color.RED,
	Color.GREEN,
	Color.BLUE,
	Color.YELLOW,
	Color.MAGENTA,
	Color.CYAN
]

# Player colour names, shown on the results screen
const PLAYER_COLOR_NAMES: Array[String] = ["Red", "Green", "Blue", "Yellow", "Magenta", "Cyan"]

# Teams, in the order the title screen cycles through them
const TEAM_NAMES: Array[String] = ["Alpha", "Beta", "Gamma"]
# Shown as a ring around each member's ship; picked to stand apart from
# the player colours
const TEAM_COLORS: Array[Color] = [Color.WHITE, Color(1.0, 0.6, 0.1), Color(0.7, 0.5, 1.0)]

# Player Starting Rotation Adjustments (degrees)
const PLAYER_ROTATION_ADJUSTMENTS: Array[int] = [30, 30, -30, -30, 0, 0]
