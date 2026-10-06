extends Node

var num_players: int = 2
var lives_per_player: int = GameConfig.PLAYER_LIVES_DEFAULT

# Rounds won by each player since the session started from the main menu.
# Rematches keep the tally; returning to the menu clears it.
var wins: Array[int] = [0, 0, 0, 0, 0, 0]

func start_session(players: int):
	num_players = players
	wins.fill(0)

func record_win(player_number: int):
	wins[player_number] += 1
