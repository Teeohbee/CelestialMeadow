extends GameSuite
# The Grand Tour results panel: a cream poster title offset in the winner's ink, tracked capitals for the
# small print, a tally centred in the panel, and kill counts in each pilot's ink. Team Alpha's cream never
# vanishes against the cream title or hull.

func before_test() -> void:
	super()
	GameState.start_session([0, 1, 2, 3] as Array[int])
	GameState.wins[0] = 2
	GameState.wins[2] = 1

# The panel on its own, laid out
func shown(winners: Array[int], scores: Dictionary = {}) -> Node:
	var results: Node = auto_free(load("res://results.tscn").instantiate())
	get_tree().root.add_child(results)
	results.show_result(winners, scores)
	await frames(3)
	return results

func centre_x(control: Control) -> float:
	return control.get_global_rect().get_center().x

func panel_centre_x(results: Node) -> float:
	return centre_x(results.get_node("Center/Panel"))

func test_the_title_is_cream() -> void:
	var results := await shown([0])
	assert_str(results.title.get_theme_color("font_color").to_html()).is_equal(GameConfig.CREAM.to_html())

func test_the_title_is_offset_in_the_winners_ink() -> void:
	var results := await shown([0])
	assert_str(results.title.get_theme_color("font_shadow_color").to_html()) \
		.is_equal(GameConfig.PLAYER_COLORS[0].to_html())
	assert_int(results.title.get_theme_constant("shadow_offset_x")).is_greater(0)

func test_there_is_a_gap_before_the_tally_heading() -> void:
	var results := await shown([0])
	var gap: float = results.heading.get_global_rect().position.y - results.subtitle.get_global_rect().end.y
	assert_float(gap).is_greater_equal(24.0)

func test_the_subtitle_and_heading_are_tracked_capitals() -> void:
	var results := await shown([0])
	assert_bool(results.subtitle.uppercase).is_true()
	assert_bool(results.heading.uppercase).is_true()

func test_the_tally_hugs_its_rows() -> void:
	var results := await shown([0])
	assert_float(results.tally.size.x).is_less(results.tally.get_parent().size.x - 40)

func test_the_tally_is_centred_in_the_panel() -> void:
	var results := await shown([0])
	assert_float(centre_x(results.tally)).is_equal_approx(panel_centre_x(results), 2.0)

func test_the_heading_is_centred_in_the_panel() -> void:
	var results := await shown([0])
	assert_float(centre_x(results.heading)).is_equal_approx(panel_centre_x(results), 2.0)

func test_kills_are_listed() -> void:
	var results := await shown([1], {0: 3, 1: 4, 2: 0, 3: 1})
	assert_str(results.tally.get_child(1).get_node("Kills").text).is_equal("4 kills")

func test_kills_are_in_the_pilots_ink() -> void:
	var results := await shown([1], {0: 3, 1: 4, 2: 0, 3: 1})
	var kills: Label = results.tally.get_child(1).get_node("Kills")
	assert_str(kills.get_theme_color("font_color").to_html()).is_equal(GameConfig.PLAYER_COLORS[1].to_html())

func test_the_kill_column_lines_up() -> void:
	var results := await shown([1], {0: 3, 1: 4, 2: 0, 3: 1})
	var first: float = results.tally.get_child(0).get_node("Kills").get_global_rect().position.x
	for row in results.tally.get_children():
		assert_float(row.get_node("Kills").get_global_rect().position.x).is_equal_approx(first, 0.5)

func test_a_team_win_names_the_team() -> void:
	GameState.teams.assign([0, 0, 1, 1, -1, -1])
	var results := await shown([0, 1])
	assert_str(results.title.text).is_equal("Team Alpha Wins!")

func test_alphas_offset_stands_off_the_cream_title() -> void:
	GameState.teams.assign([0, 0, 1, 1, -1, -1])
	var results := await shown([0, 1])
	assert_str(results.title.get_theme_color("font_shadow_color").to_html()).is_not_equal(GameConfig.CREAM.to_html())

func test_alphas_ship_ink_shows_on_the_cream_hull() -> void:
	GameState.teams.assign([0, 0, 1, 1, -1, -1])
	var results := await shown([0, 1])
	assert_str(results.ship.ink.to_html()).is_not_equal(GameConfig.CREAM.to_html())
