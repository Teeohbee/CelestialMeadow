extends RoundSuite
# The Grand Tour HUD: team colours stand apart from the pilots' inks and each other, and in a busy time attack
# round every pilot block is on screen and clear of the clock and team totals.

func distance(a: Color, b: Color) -> float:
	return Vector3(a.r - b.r, a.g - b.g, a.b - b.b).length()

# Time attack, two teams, pilot 5 seated so the top centre is busy
func busy_hud() -> Node:
	await new_round([0, 1, 2, 4], [0, 0, 1, -1, 1, -1], 1)
	return scene().get_node("HUD")

func test_every_team_colour_stands_apart_from_every_pilot_ink() -> void:
	for team in GameConfig.TEAM_COLORS:
		for ink in GameConfig.PLAYER_COLORS:
			assert_float(distance(team, ink)).is_greater(0.2)

func test_team_colours_differ_from_each_other() -> void:
	var colours := GameConfig.TEAM_COLORS
	for t in colours.size():
		for u in range(t + 1, colours.size()):
			assert_float(distance(colours[t], colours[u])).is_greater(0.3)

func test_the_clock_and_team_totals_show() -> void:
	var hud := await busy_hud()
	assert_bool(hud.clock.visible).is_true()
	assert_bool(hud.side_scores.visible).is_true()

func test_every_pilot_block_is_on_screen() -> void:
	var hud := await busy_hud()
	var screen := get_tree().root.get_visible_rect()
	for pilot in hud.shown_players():
		assert_bool(screen.encloses(hud.block_rect(pilot))) \
			.override_failure_message("pilot %d block off screen: %s" % [pilot + 1, hud.block_rect(pilot)]).is_true()

func test_pilot_5_is_clear_of_the_clock_and_team_totals() -> void:
	var hud := await busy_hud()
	var block: Rect2 = hud.block_rect(4)
	assert_bool(block.intersects(hud.clock.get_global_rect())).is_false()
	assert_bool(block.intersects(hud.side_scores.get_global_rect())).is_false()

func test_pilot_5_stays_in_the_top_row() -> void:
	var hud := await busy_hud()
	assert_float(hud.block_rect(4).position.y).is_less_equal(hud.block_rect(0).position.y + 1)
