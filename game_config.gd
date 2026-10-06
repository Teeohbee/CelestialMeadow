extends Node

## Game configuration constants
## Central location for all game balance values and magic numbers

# Player Stats
const PLAYER_ENGINE_POWER: int = 500
const PLAYER_SPIN_POWER: int = 4000
const PLAYER_SHOOT_DELAY: float = 0.25
const PLAYER_LIVES_DEFAULT: int = 3
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
const SHIELD_COLOR: Color = Color(0.17, 0.31, 0.63, 0.25)  # Ultramarine wash

# Asteroid Settings
const ASTEROID_INITIAL_COUNT: int = 10
const ASTEROID_MAX_COUNT: int = 10
const ASTEROID_SPAWN_COUNT: int = 2
const ASTEROID_MIN_SPEED: float = 100.0
const ASTEROID_MAX_SPEED: float = 200.0

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

# Star Chart Style
const CHART_INK: Color = Color("#2a2016")
const CHART_PAPER: Color = Color("#e8dcc0")
const CHART_GOLD: Color = Color("#c9a13b")

# Player Colors: watercolour pigments used to hand-tint antique plates,
# pushed a little brighter so six players stay distinct across a room
const PLAYER_COLORS: Array[Color] = [
	Color("#b8402a"), # Vermilion
	Color("#3e8a55"), # Verdigris
	Color("#2b4fa0"), # Ultramarine
	Color("#c8932a"), # Ochre
	Color("#8a3a78"), # Madder
	Color("#2f8a94")  # Slate teal
]

# Player colour names, shown on the results screen
const PLAYER_COLOR_NAMES: Array[String] = ["Red", "Green", "Blue", "Yellow", "Magenta", "Cyan"]

# Player Starting Rotation Adjustments (degrees)
const PLAYER_ROTATION_ADJUSTMENTS: Array[int] = [30, 30, -30, -30, 0, 0]
