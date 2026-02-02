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
const CAMERA_SHAKE_EXPLOSION: float = 20.0
const CAMERA_SHAKE_ASTEROID: float = 12.0

# Game Flow Timing
const END_GAME_CHECK_DELAY: float = 0.5
const VICTORY_SCREEN_DURATION: float = 3.0

# Player Colors
const PLAYER_COLORS: Array[Color] = [
	Color.RED,
	Color.GREEN,
	Color.BLUE,
	Color.YELLOW
]

# Player Starting Rotation Adjustments (degrees)
const PLAYER_ROTATION_ADJUSTMENTS: Array[int] = [30, 30, -30, -30]
