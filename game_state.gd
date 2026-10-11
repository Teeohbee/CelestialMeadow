extends Node

# Seats taken this session. A seat is a player number, which fixes that
# player's colour, start position and controls (the shoot0..shoot5 actions).
var players: Array[int] = []
# Seats filled by idle dummy ships for solo testing; nobody controls them
var dummies: Array[int] = []
var lives_per_player: int = GameConfig.PLAYER_LIVES_DEFAULT
const MODES: Array[Dictionary] = [
	{"name": "Last Ship Standing", "blurb": "Three lives each. Last ship flying wins.", "script": preload("res://last_ship_standing.gd")},
	{"name": "Time Attack", "blurb": "Two minutes, endless respawns. Most kills wins.", "script": preload("res://time_attack.gd")},
]
# The mode chosen on the title screen, an index into MODES
var mode_index: int = 0
# The rules for this session's rounds, a GameMode script
var mode: Script = MODES[0].script

# Rounds won by each player since the session started from the main menu.
# Rematches keep the tally; returning to the menu clears it.
var wins: Array[int] = [0, 0, 0, 0, 0, 0]

func start_session(seats: Array[int], dummy_seats: Array[int] = []):
	players = seats.duplicate()
	players.append_array(dummy_seats)
	players.sort()
	dummies = dummy_seats.duplicate()
	mode = MODES[mode_index].script
	wins.fill(0)

func record_win(player_number: int):
	wins[player_number] += 1
