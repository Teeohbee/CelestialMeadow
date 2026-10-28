extends GdUnitTestSuite
# OptionRow, one line of a menu panel: it shows its value as a word or as bars, < > only when asked for, a
# blurb only when it has one, and amber while selected.

func test_a_word_row_shows_its_value() -> void:
	var row: OptionRow = auto_free(OptionRow.new("Lives", OptionRow.Kind.WORDS))
	row.show_value(3)
	assert_str(row.value_label.text).is_equal("3")
	assert_object(row.bars).is_null()

func test_a_bar_row_keeps_its_level() -> void:
	var row: OptionRow = auto_free(OptionRow.new("Music", OptionRow.Kind.BARS))
	row.show_value(7)
	assert_int(row.bar_value).is_equal(7)
	assert_object(row.value_label).is_null()

func test_arrows_only_when_asked_for() -> void:
	assert_array(auto_free(OptionRow.new("Music", OptionRow.Kind.BARS)).arrows).is_empty()
	assert_int(auto_free(OptionRow.new("Mode", OptionRow.Kind.WORDS, 860.0, true)).arrows.size()).is_equal(2)

func test_the_blurb_shows_only_with_text() -> void:
	var row: OptionRow = auto_free(OptionRow.new("Mode", OptionRow.Kind.WORDS))
	assert_bool(row.blurb.visible).is_false()
	row.show_blurb("Last ship flying wins.")
	assert_bool(row.blurb.visible).is_true()
	row.show_blurb("")
	assert_bool(row.blurb.visible).is_false()

func test_selected_rows_are_amber() -> void:
	var row: OptionRow = auto_free(OptionRow.new("Teams", OptionRow.Kind.WORDS))
	row.set_selected(true)
	assert_object(row.label.get_theme_color("font_color")).is_equal(GameConfig.LIGHT)
	assert_object(row.get_theme_stylebox("panel").border_color).is_equal(GameConfig.LIGHT)
	row.set_selected(false)
	assert_object(row.value_label.get_theme_color("font_color")).is_equal(GameConfig.CREAM)
