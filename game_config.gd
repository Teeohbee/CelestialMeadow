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

# Grand Tour palette, after the NASA/JPL poster's print-master inks
const GROUND: Color = Color("#16121F")
const DEEP: Color = Color("#231B30")
const MID: Color = Color("#3A2C48")
const HUE: Color = Color("#27867F")
const LIGHT: Color = Color("#F0A748")
const CREAM: Color = Color("#F3E7D2")
const ENV_INKS: Array[Color] = [
	Color("#C13944"), Color("#E85E3B"), Color("#F0A748"), Color("#8EBB4B"),
	Color("#187A4E"), Color("#27867F"), Color("#76365E")
]

# Background speed bars and film grain; 0 grain hides the overlay
const SPEED_BAR_COUNT: int = 14
const SPEED_BAR_ALPHA: float = 0.5
const GRAIN_STRENGTH: float = 0.22

const PLANET_NAMES: Array[String] = [
	"Ostara", "Verdant", "Halcyon", "Marigold", "Tamsin", "Brisa",
	"Cobalt", "Lanterne", "Odessa", "Perihelion", "Saffra", "Wren"
]

# Player inks; each seat keeps its nearest hue from the old pure colours
const PLAYER_COLORS: Array[Color] = [
	Color("#E8453C"),
	Color("#8CC63F"),
	Color("#F5862A"),
	Color("#F4C430"),
	Color("#C86FC9"),
	Color("#2EC4B6")
]

# Player colour names, shown on the results screen
const PLAYER_COLOR_NAMES: Array[String] = ["Red", "Lime", "Tangerine", "Marigold", "Orchid", "Lagoon"]

# Player Starting Rotation Adjustments (degrees)
const PLAYER_ROTATION_ADJUSTMENTS: Array[int] = [30, 30, -30, -30, 0, 0]
