extends GameMode

## Classic rules: everyone has a few lives, the last ship flying wins

func _init():
	name = "LastShipStanding"

func on_player_eliminated(_player: int):
	# Leaving the arena because the whole scene is going
	if not is_inside_tree():
		return
	await get_tree().create_timer(GameConfig.END_GAME_CHECK_DELAY).timeout
	# Several players can die at once; only the first check to finish ends
	# the round
	if ended:
		return

	var remaining: Array[int] = []
	for player in get_tree().get_nodes_in_group("players"):
		remaining.append(player.player_number)
	if remaining.size() <= 1:
		end_round(remaining)
