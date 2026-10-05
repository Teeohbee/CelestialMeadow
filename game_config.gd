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
const SHIELD_COLOR: Color = Color(0, 0.8, 1.0, 0.3)

# Asteroid Settings
const ASTEROID_INITIAL_COUNT: int = 10
const ASTEROID_MAX_COUNT: int = 10
const ASTEROID_SPAWN_COUNT: int = 2
const ASTEROID_MIN_SPEED: float = 100.0
const ASTEROID_MAX_SPEED: float = 200.0

# Camera Effects
const ABERRATION_PER_SHAKE: float = 0.6  # aberration pixels per unit of shake
const ABERRATION_DECAY: float = 6.0
const CAMERA_SHAKE_EXPLOSION: float = 20.0
const CAMERA_SHAKE_ASTEROID: float = 12.0

# Game Flow Timing
const END_GAME_CHECK_DELAY: float = 0.5
const VICTORY_SCREEN_DURATION: float = 3.0

# Player Colors (neon palette)
const PLAYER_COLORS: Array[Color] = [
	Color(1.0, 0.15, 0.6),   # Hot pink
	Color(0.45, 1.0, 0.15),  # Lime
	Color(0.2, 0.45, 1.0),   # Electric blue
	Color(1.0, 0.7, 0.0),    # Amber
	Color(0.7, 0.3, 1.0),    # Violet
	Color(0.0, 0.9, 1.0)     # Cyan
]

# Neon Rendering
## Multiplier pushing neon colours above 1.0 so the glow post-process picks them up
const NEON_GLOW: float = 2.5
# Particles
const SPARK_LIFETIME: float = 0.7
const SPARK_SPEED_MIN: float = 150.0
const SPARK_SPEED_MAX: float = 550.0
const SPARK_DAMPING: float = 400.0
const SPARK_COUNT_ASTEROID: int = 40
const SPARK_COUNT_PLAYER: int = 90
const BULLET_TRAIL_LENGTH: float = 120.0  # in bullet-local units (bullet is scaled 0.5)

const ASTEROID_COLOR: Color = Color(0.85, 0.85, 1.0)
const HOLOGRAM_COLORS: Array[Color] = [
	Color(0.0, 0.8, 1.0),   # Cyan
	Color(0.15, 0.3, 1.0),  # Deep blue
	Color(0.55, 0.3, 1.0)   # Violet
]

# Player Starting Rotation Adjustments (degrees)
const PLAYER_ROTATION_ADJUSTMENTS: Array[int] = [30, 30, -30, -30, 0, 0]
