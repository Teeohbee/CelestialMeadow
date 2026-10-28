extends GameSuite
# Controller glyphs: every ButtonGlyph draws at the size asked for, ButtonPrompt lays words and glyphs out
# in order from a template, and the lobby prompts with pad glyphs only, never a keyboard key.

const BUTTONS: Array[String] = ["a", "b", "x", "y", "view", "menu", "dpad", "dpad_left", "dpad_right", "dpad_up", "dpad_down", "dpad_up_down", "dpad_left_right", "rt", "lt"]

var menu: Node

# Each piece of a prompt: a glyph's button or a word
func pieces(prompt: ButtonPrompt) -> Array:
	return prompt.get_children().map(func(c): return c.button if c is ButtonGlyph else c.text)

func prompt_with(text: String) -> ButtonPrompt:
	var prompt: ButtonPrompt = auto_free(ButtonPrompt.new())
	prompt.font_size = 30
	get_tree().root.add_child(prompt)
	prompt.text = text
	return prompt

# Every visible Label's text under a node, glyph prompts included
func all_text(node: Node, found: Array[String] = []) -> Array[String]:
	if node is Label and node.is_visible_in_tree():
		found.append(node.text)
	for child in node.get_children():
		all_text(child, found)
	return found

func lobby() -> void:
	menu = await open("res://menu.tscn")
	await frames(2)

func test_every_glyph_is_as_tall_as_asked() -> void:
	for button in BUTTONS:
		var glyph: ButtonGlyph = auto_free(ButtonGlyph.new(button, 40.0))
		get_tree().root.add_child(glyph)
		await frames(1)
		assert_float(glyph.get_combined_minimum_size().y) \
			.override_failure_message("%s isn't 40 tall" % button).is_equal(40.0)

func test_the_d_pad_can_light_both_arms_of_one_axis() -> void:
	assert_bool(ButtonGlyph.knows("dpad_up_down")).is_true()
	assert_bool(ButtonGlyph.knows("dpad_left_right")).is_true()
	assert_array(ButtonGlyph.DPAD_ARMS["dpad_up_down"]).is_equal([Vector2.UP, Vector2.DOWN])

func test_triggers_are_wider_than_they_are_tall() -> void:
	var rt: ButtonGlyph = auto_free(ButtonGlyph.new("rt", 40.0))
	assert_float(rt.custom_minimum_size.x).is_greater(40.0)

func test_a_prompt_lays_out_words_and_glyphs_in_order() -> void:
	assert_array(pieces(prompt_with("Press {a} to join"))).is_equal(["Press", "a", "to", "join"])

func test_setting_the_text_again_rebuilds_it() -> void:
	var prompt := prompt_with("Press {a} to join")
	prompt.text = "{dpad_left} to leave"
	assert_array(pieces(prompt)).is_equal(["dpad_left", "to", "leave"])
	assert_str(prompt.text).is_equal("{dpad_left} to leave")

func test_an_unknown_token_shows_as_text_so_a_typo_is_visible() -> void:
	assert_array(pieces(prompt_with("Mind the {gap}"))).is_equal(["Mind", "the", "{gap}"])

func test_the_lobby_status_asks_for_a() -> void:
	await lobby()
	assert_str(menu.status.text).is_equal("Press {a} to take a seat")

func test_the_mode_blurb_shows_the_trigger_for_teams() -> void:
	await lobby()
	assert_str(menu.mode_blurb.text).contains("{rt}").not_contains("{dpad_right}")

func test_the_corners_show_b_and_view() -> void:
	await lobby()
	assert_str(menu.back_prompt.text).contains("{b}")
	assert_str(menu.options_prompt.text).contains("{view}")

func test_each_corner_fits_on_one_line() -> void:
	await lobby()
	await frames(1)
	for corner in [menu.back_prompt, menu.options_prompt]:
		var middles: Array = corner.get_children().map(func(piece): return piece.position.y + piece.size.y / 2)
		assert_float(middles.max() - middles.min()) \
			.override_failure_message("%s wraps: %s" % [corner.text, middles]).is_less(4.0)

func test_empty_seats_ask_for_a() -> void:
	await lobby()
	assert_str(menu.cards[0].status.text).is_equal("Press {a} to join")
	assert_str(menu.cards[4].status.text).is_equal("Press {a} to join")

func test_a_seat_names_only_its_pad() -> void:
	await lobby()
	assert_str(menu.cards[0].hint.text).is_equal("Pad 1")

func test_a_joined_seat_prompts_to_ready_or_leave() -> void:
	await lobby()
	menu.advance(menu.cards[0])
	assert_str(menu.cards[0].status.text).is_equal("Press {a} when ready")
	assert_str(menu.cards[0].hint.text).is_equal("{dpad_left} to leave")

func test_a_ready_seat_prompts_to_cancel() -> void:
	await lobby()
	menu.advance(menu.cards[0])
	menu.advance(menu.cards[0])
	assert_str(menu.cards[0].hint.text).is_equal("{dpad_left} to cancel")

func test_the_options_hint_shows_b() -> void:
	await lobby()
	menu.open_options()
	await frames(1)
	assert_str(menu.options.hint.text).contains("{b}")

func test_no_keyboard_key_shows_anywhere_in_the_lobby() -> void:
	await lobby()
	menu.advance(menu.cards[0])
	menu.open_options()
	await frames(1)
	var words := " ".join(all_text(menu))
	for key_name in ["Space", "Esc", "Tab", "Keyboard", "Enter"]:
		assert_str(words).not_contains(key_name)
