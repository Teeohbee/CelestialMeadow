extends Node

# Seats taken this session. A seat is a player number, which fixes that
# player's colour, start position and controls (the shoot0..shoot5 actions).
var players: Array[int] = [0, 1]
var lives_per_player: int = GameConfig.PLAYER_LIVES_DEFAULT

# Rounds won by each player since the session started from the main menu.
# Rematches keep the tally; returning to the menu clears it.
var wins: Array[int] = [0, 0, 0, 0, 0, 0]

func start_session(seats: Array[int]):
	players = seats.duplicate()
	players.sort()
	wins.fill(0)

func record_win(player_number: int):
	wins[player_number] += 1
