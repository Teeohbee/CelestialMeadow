extends GameMode

## Classic rules: everyone has a few lives, the last ship flying wins

func _init():
	name = "LastShipStanding"

func on_player_eliminated(_player: int):
	end_if_last_standing()
