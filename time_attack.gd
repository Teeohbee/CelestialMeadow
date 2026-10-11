extends GameMode

## Ships respawn forever and every kill scores for the killer's side. Most
## kills when the clock runs out wins; a tie goes to sudden death, where
## only the tied sides' ships remain with one life each.

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
	hud.set_team_scores(side_scores())
	hud.set_clock(GameConfig.TIME_ATTACK_DURATION)

func starting_lives() -> int:
	return GameConfig.UNLIMITED_LIVES

func round_scores() -> Dictionary:
	return scores

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
	hud.set_team_scores(side_scores())

func on_player_eliminated(_player: int):
	if sudden_death:
		end_if_last_standing()

## Total kills for each side
func side_scores() -> Dictionary:
	var totals = {}
	for player in scores:
		var side = GameState.side_of(player)
		totals[side] = totals.get(side, 0) + scores[player]
	return totals

func _on_time_up():
	hud.set_clock(0)
	var totals = side_scores()
	var best = totals.values().max()
	var leaders: Array[int] = []
	for side in totals:
		if totals[side] == best:
			leaders.append_array(GameState.members_of(side))
	if totals.values().count(best) == 1:
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
	# Knocked-out pilots don't get a parting shot
	for bullet in get_tree().get_nodes_in_group("bullets"):
		if bullet.player_number not in leaders:
			bullet.queue_free()
