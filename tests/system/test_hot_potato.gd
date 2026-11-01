extends RoundSuite
# Hot Potato: only the bomb takes lives. One ship carries it at a time, with a fuse of random length shown as
# a shrinking ring. The carrier's shot passes it to the ship it hits; anyone else's shot shoves that ship
# without harm. When the fuse runs out the carrier loses a life and a fresh bomb goes to a flying ship. Last
# side flying wins.

const HOT_POTATO := 3

func speed() -> float:
	return 4.0

var mark := 0

func before_test() -> void:
	super()
	mark = Sound.next_player_index

func hot_potato(seats: Array[int] = [0, 1], teams: Array[int] = []) -> Node:
	return await new_round(seats, teams, HOT_POTATO)

# The bomb on this ship, past the moment it can't be passed on
func carrying(round: Node, number: int) -> void:
	round.mode.give_bomb_to(number)
	await wait_until(func(): return round.mode.can_pass())

func marked(number: int) -> bool:
	return ship(number).get_node("Ship").has_node("Fuse")

func blow(round: Node) -> void:
	round.mode.fuse.start(0.05)
	await wait_until(func(): return round.mode.carrier < 0)

func played() -> Array:
	var names := []
	while mark != Sound.next_player_index:
		names.append(Sound.sounds.find_key(Sound.players[mark].stream))
		mark = (mark + 1) % Sound.players.size()
	return names

func test_hot_potato_uses_lives() -> void:
	assert_str(GameState.MODES[HOT_POTATO].name).is_equal("Hot Potato")
	assert_array(GameState.MODES[HOT_POTATO].rules).is_equal(["lives"])

func test_a_flying_ship_gets_the_bomb_when_play_starts() -> void:
	var round := await hot_potato()
	assert_array([0, 1]).contains([round.mode.carrier])
	assert_bool(marked(round.mode.carrier)).is_true()

func test_the_fuse_is_eight_to_fifteen_seconds() -> void:
	var round := await hot_potato()
	assert_float(round.mode.fuse.wait_time).is_between(GameConfig.HOT_POTATO_FUSE_MIN, GameConfig.HOT_POTATO_FUSE_MAX)

func test_the_carriers_shot_passes_the_bomb() -> void:
	var round := await hot_potato()
	await carrying(round, 0)
	await fire(0, 1)
	assert_int(round.mode.carrier).is_equal(1)
	assert_bool(marked(1)).is_true()
	assert_bool(marked(0)).is_false()
	assert_bool(ship(1).dead).is_false()
	assert_int(ship(1).lives).is_equal(GameState.lives_per_player)

func test_passing_keeps_the_fuse_burning() -> void:
	var round := await hot_potato()
	await carrying(round, 0)
	var left: float = round.mode.fuse.time_left
	await fire(0, 1)
	assert_float(round.mode.fuse.time_left).is_less(left)

func test_a_new_carrier_cant_pass_it_straight_back() -> void:
	var round := await hot_potato()
	await carrying(round, 0)
	await fire(0, 1)
	await fire(1, 0)
	assert_int(round.mode.carrier).is_equal(1)

func test_anyone_elses_shot_shoves_without_harm() -> void:
	var round := await hot_potato()
	await carrying(round, 0)
	await fire(1, 0)
	# The push lands on the next physics step
	assert_bool(await wait_until(func(): return ship(0).linear_velocity.x > 100.0, 1.0)).is_true()
	assert_bool(ship(0).dead).is_false()
	assert_int(ship(0).lives).is_equal(GameState.lives_per_player)
	assert_int(round.mode.carrier).is_equal(0)

func test_an_allys_shot_doesnt_pass_the_bomb() -> void:
	var round := await hot_potato([0, 1, 2], [0, 0, 1, GameState.SOLO, GameState.SOLO, GameState.SOLO])
	await carrying(round, 0)
	await fire(0, 1)
	assert_int(round.mode.carrier).is_equal(0)

func test_the_fuse_running_out_costs_the_carrier_a_life() -> void:
	var round := await hot_potato()
	await carrying(round, 0)
	await blow(round)
	assert_int(ship(0).lives).is_equal(GameState.lives_per_player - 1)
	assert_int(ship(1).lives).is_equal(GameState.lives_per_player)

func test_a_fresh_bomb_follows_the_blast() -> void:
	var round := await hot_potato()
	await carrying(round, 0)
	await blow(round)
	assert_bool(await wait_until(func(): return round.mode.carrier >= 0)).is_true()
	assert_bool(ship(round.mode.carrier).dead).is_false()

func test_the_fuse_ticks() -> void:
	var round := await hot_potato()
	await carrying(round, 0)
	played()
	await seconds(1.0)
	assert_array(played()).contains(["tick"])

func test_the_last_side_flying_wins() -> void:
	GameSettings.set_setting("lives", 1)
	var round := await hot_potato()
	await carrying(round, 0)
	await blow(round)
	await results()
	assert_str(results_title()).is_equal("Lime Wins!")
