extends GdUnitTestSuite
# GameState.MODES: each mode names the match settings it uses, which the match setup shows as rows, so its
# blurb leaves the numbers to them.

func test_last_ship_standing_uses_lives() -> void:
	assert_array(GameState.MODES[0].rules).is_equal(["lives"])

func test_time_attack_uses_the_time() -> void:
	assert_array(GameState.MODES[1].rules).is_equal(["time_minutes"])

func test_every_rule_is_a_saved_setting() -> void:
	for mode in GameState.MODES:
		for rule in mode.rules:
			assert_bool(GameSettings.setting_limits.has(rule)).override_failure_message("%s isn't a setting" % rule).is_true()

func test_the_blurbs_leave_the_numbers_to_the_rows() -> void:
	assert_str(GameState.MODES[0].blurb).is_equal("Last ship flying wins.")
	assert_str(GameState.MODES[1].blurb).is_equal("Endless respawns. Most kills wins.")
