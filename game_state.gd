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

# Each seat's team, an index into GameConfig.TEAM_NAMES, or SOLO. Every
# solo player is a side of their own, so free-for-all is everyone solo.
const SOLO: int = -1
var teams: Array[int] = [SOLO, SOLO, SOLO, SOLO, SOLO, SOLO]

# A seat whose shoot button got past the title screen, to be seated in the
# lobby on arrival; -1 for none
var join_on_arrival: int = -1

# Rounds won by each player since the session started from the main menu.
# Rematches keep the tally; returning to the menu clears it.
var wins: Array[int] = [0, 0, 0, 0, 0, 0]

func start_session(seats: Array[int], dummy_seats: Array[int] = []):
	players = seats.duplicate()
	players.append_array(dummy_seats)
	players.sort()
	dummies = dummy_seats.duplicate()
	for dummy in dummies:
		teams[dummy] = SOLO
	mode = MODES[mode_index].script
	wins.fill(0)

## Which side a player fights for: their team, or just themselves
func side_of(player_number: int) -> int:
	if teams[player_number] == SOLO:
		return GameConfig.TEAM_NAMES.size() + player_number
	return teams[player_number]

func allies(a: int, b: int) -> bool:
	return side_of(a) == side_of(b)

## Everyone playing on a side, whether or not their ship is still flying
func members_of(side: int) -> Array[int]:
	return players.filter(func(p): return side_of(p) == side)

func record_win(player_number: int):
	wins[player_number] += 1
