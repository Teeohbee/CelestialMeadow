extends GameMode

## Ships respawn forever and every kill scores. Most kills when the clock
## runs out wins; a tie goes to sudden death, where only the tied ships
## remain with one life each.

var scores: Dictionary = {}
var sudden_death: bool = false
var clock: Timer

func _init():
	name = "TimeAttack"

func _ready():
	clock = Timer.new()
	clock.one_shot = true
	clock.wait_time = GameConfig.TIME_ATTACK_DURATION
	clock.timeout.connect(_on_time_up)
	add_child(clock)
	for player in GameState.players:
		scores[player] = 0
		hud.update_score(player, 0)
	hud.set_clock(GameConfig.TIME_ATTACK_DURATION)

func starting_lives() -> int:
	return GameConfig.UNLIMITED_LIVES

func start():
	clock.start()

func _process(_delta):
	if not clock.is_stopped():
		hud.set_clock(clock.time_left)

func on_player_killed(victim: int, killer: int):
	if sudden_death or killer < 0 or killer == victim:
		return
	scores[killer] += 1
	hud.update_score(killer, scores[killer])

func on_player_eliminated(_player: int):
	if sudden_death:
		end_if_last_standing()

func _on_time_up():
	hud.set_clock(0)
	var best = scores.values().max()
	var leaders: Array[int] = []
	for player in scores:
		if scores[player] == best:
			leaders.append(player)
	if leaders.size() == 1:
		end_round(leaders)
	else:
		start_sudden_death(leaders)

func start_sudden_death(leaders: Array[int]):
	sudden_death = true
	hud.show_banner("SUDDEN DEATH")
	for ship in get_tree().get_nodes_in_group("players"):
		if ship.player_number in leaders:
			ship.lives = 1
			hud.update_lives(ship.player_number, 1)
		else:
			ship.queue_free()
			hud.hide_player(ship.player_number)
