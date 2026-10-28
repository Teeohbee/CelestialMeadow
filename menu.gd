extends Control

## The lobby, "Who's flying?", for the match chosen in the match setup,
## shown as chips under the heading. Each player takes a seat by pressing
## their own A, presses it again when ready, and backs out with their own B:
## unready, then leave. The round launches on its own once enough players
## are seated and all of them are ready, so nobody has to drive a menu for
## everyone else. With Teams on in the match setup, every seated pilot is on
## Alpha, Beta or Gamma, joining the smallest side, and D-pad left/right on
## their own card changes it; with Teams off everyone is solo. Any pad's View
## button opens the options. B on a pad with no seat goes back to the match
## setup, but only while every seat is empty. Unplugging a seated pad
## empties its seat.

const SeatCard = preload("res://seat_card.gd")
const Options = preload("res://options.gd")
const SEAT_COUNT: int = 6

## Rotate left, right, left, right on an empty seat's pad toggles the dummy
## pilot (GameState.dummy_pilot), so one controller can test a round on a
## release build. Empty seats ignore rotation, so it can't happen by accident.
const DUMMY_COMBO: Array[String] = ["rotate_left", "rotate_right", "rotate_left", "rotate_right"]
const DUMMY_COMBO_WINDOW_MS: int = 2000
const NOTICE_MS: int = 2000

## How far each seat is through the combo, and when it started
var combo_steps: Array[int] = [0, 0, 0, 0, 0, 0]
var combo_started_at: Array[int] = [0, 0, 0, 0, 0, 0]
var notice: String = ""
var notice_until: int = 0

var cards: Array = []
var launch_countdown: float = GameConfig.TITLE_LAUNCH_DELAY
var launching: bool = false
var leaving: bool = false
## The countdown second last ticked, so each one ticks once
var ticked_second: int = 0
var options: Control
## The match's Teams setting
var teams_on: bool
var back_prompt: ButtonPrompt
var options_prompt: ButtonPrompt

@onready var seats_row: HBoxContainer = $Seats
@onready var status: ButtonPrompt = $Status
@onready var chips: HBoxContainer = $Chips
@onready var mode_blurb: ButtonPrompt = $ModeBlurb

func _ready():
	Music.play_track("menu")
	teams_on = GameSettings.get_setting("teams")
	for i in SEAT_COUNT:
		var card = SeatCard.new(i)
		seats_row.add_child(card)
		cards.append(card)
	# Coming back from a game, the same crew is still seated, on their
	# sides if the match still has teams
	for i in GameState.players:
		if not teams_on or i in GameState.dummies:
			GameState.teams[i] = GameState.SOLO
	for i in GameState.players:
		if i not in GameState.dummies:
			take_seat(cards[i])
	# The match set up last, this session or the last
	GameState.mode_index = GameSettings.get_setting("last_mode")
	if GameState.join_on_arrival >= 0 and cards[GameState.join_on_arrival].state == SeatCard.State.EMPTY:
		take_seat(cards[GameState.join_on_arrival])
		GameState.join_on_arrival = -1
	show_match()
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	back_prompt = ButtonPrompt.on_button($BackButton, "%s Back" % SeatCard.action_glyph("ui_cancel"))
	options_prompt = ButtonPrompt.on_button($OptionsButton, "%s Options" % SeatCard.action_glyph("options"))
	options = Options.new()
	options.name = "Options"
	add_child(options)

func _process(delta):
	var seated = seated_players()
	var ready_count = cards.filter(func(c): return c.state == SeatCard.State.READY).size()
	var solo_test = GameState.dummy_pilot and seated.size() == 1
	var enough = seated.size() >= GameConfig.TITLE_MIN_PLAYERS or solo_test
	var sides = {}
	for seat in seated:
		sides[GameState.side_of(seat)] = true
	# The debug dummy always flies solo, so a lone tester has an opponent
	var one_side = sides.size() < 2 and not solo_test
	var can_launch = enough and not one_side and ready_count == seated.size() and not options.visible

	if can_launch and not launching:
		if ceili(launch_countdown) != ticked_second:
			ticked_second = ceili(launch_countdown)
			Sound.play("tick")
		launch_countdown -= delta
		if launch_countdown <= 0.0:
			launch(seated)
	else:
		launch_countdown = GameConfig.TITLE_LAUNCH_DELAY
		ticked_second = 0

	if seated.is_empty():
		status.text = "Press %s to take a seat" % SeatCard.action_glyph("shoot0")
	elif not enough:
		status.text = "Waiting for another pilot"
	elif one_side:
		status.text = "Pick at least two sides"
	elif not can_launch:
		status.text = "%d of %d ready" % [ready_count, seated.size()]
	elif solo_test:
		status.text = "Launching in %d against a dummy" % ceili(launch_countdown)
	else:
		status.text = "Launching in %d" % ceili(launch_countdown)
	if Time.get_ticks_msec() < notice_until:
		status.text = notice

func seated_players() -> Array[int]:
	var seated: Array[int] = []
	for card in cards:
		if card.state != SeatCard.State.EMPTY:
			seated.append(card.seat)
	return seated

func _input(event):
	if launching or leaving:
		return
	for i in SEAT_COUNT:
		if event.is_action_pressed("back%d" % i):
			get_viewport().set_input_as_handled()
			if cards[i].state == SeatCard.State.EMPTY:
				back_to_setup()
			else:
				back(cards[i])
			return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		back_to_setup()
		return
	if event.is_action_pressed("options"):
		get_viewport().set_input_as_handled()
		open_options()
		return
	for i in SEAT_COUNT:
		if event.is_action_pressed("shoot%d" % i):
			get_viewport().set_input_as_handled()
			advance(cards[i])
			return
		if event.is_action_pressed("rotate_left%d" % i):
			get_viewport().set_input_as_handled()
			if cards[i].state == SeatCard.State.EMPTY:
				dummy_combo(i, "rotate_left")
			else:
				change_team(cards[i], -1)
			return
		if event.is_action_pressed("rotate_right%d" % i):
			get_viewport().set_input_as_handled()
			if cards[i].state == SeatCard.State.EMPTY:
				dummy_combo(i, "rotate_right")
			else:
				change_team(cards[i], 1)
			return

func dummy_combo(seat: int, step: String):
	var now = Time.get_ticks_msec()
	if now - combo_started_at[seat] > DUMMY_COMBO_WINDOW_MS or DUMMY_COMBO[combo_steps[seat]] != step:
		combo_steps[seat] = 0
	if DUMMY_COMBO[combo_steps[seat]] != step:
		return
	if combo_steps[seat] == 0:
		combo_started_at[seat] = now
	combo_steps[seat] += 1
	if combo_steps[seat] == DUMMY_COMBO.size():
		combo_steps[seat] = 0
		GameState.dummy_pilot = not GameState.dummy_pilot
		notice = "Dummy pilot on" if GameState.dummy_pilot else "Dummy pilot off"
		notice_until = now + NOTICE_MS

func advance(card):
	if card.state == SeatCard.State.EMPTY:
		take_seat(card)
		Sound.play("seat")
	elif card.state == SeatCard.State.JOINED:
		card.set_state(SeatCard.State.READY)
		Sound.play("ready")

func back(card):
	if card.state == SeatCard.State.READY:
		card.set_state(SeatCard.State.JOINED)
		Sound.play("back")
	elif card.state == SeatCard.State.JOINED:
		GameState.teams[card.seat] = GameState.SOLO
		card.set_state(SeatCard.State.EMPTY)
		Sound.play("back")

func _on_joy_connection_changed(device: int, connected: bool):
	var seat = GameState.seat_of_device(device)
	if connected or launching or seat < 0 or cards[seat].state == SeatCard.State.EMPTY:
		return
	GameState.teams[seat] = GameState.SOLO
	cards[seat].set_state(SeatCard.State.EMPTY)
	Sound.play("back")
	notice = "%s's controller unplugged" % GameConfig.PLAYER_COLOR_NAMES[seat]
	notice_until = Time.get_ticks_msec() + NOTICE_MS

## Seats a pilot, on the smallest side if the match has teams. A returning
## pilot keeps their side.
func take_seat(card):
	if teams_on and GameState.teams[card.seat] == GameState.SOLO:
		GameState.teams[card.seat] = smallest_team()
	card.set_state(SeatCard.State.JOINED)

## The team with fewest seated members, the lowest on a tie
func smallest_team() -> int:
	var counts = []
	counts.resize(GameConfig.TEAM_NAMES.size())
	counts.fill(0)
	for card in cards:
		var team = GameState.teams[card.seat]
		if card.state != SeatCard.State.EMPTY and team != GameState.SOLO:
			counts[team] += 1
	return counts.find(counts.min())

## Round the three teams, no solo. Teams change the match for everyone, so
## everyone readies again.
func change_team(card, step: int):
	if not teams_on or card.state != SeatCard.State.JOINED:
		return
	GameState.teams[card.seat] = posmod(GameState.teams[card.seat] + step, GameConfig.TEAM_NAMES.size())
	Sound.play("focus")
	unready_all()
	card.show_team()

func unready_all():
	for card in cards:
		if card.state == SeatCard.State.READY:
			card.set_state(SeatCard.State.JOINED)

## The match as chips: the mode, teams or not, and the mode's rules
func show_match():
	var mode = GameState.MODES[GameState.mode_index]
	for text in match_chips():
		chips.add_child(chip_for(text))
	mode_blurb.text = mode.blurb
	if teams_on:
		mode_blurb.text += "  {dpad_left_right} to change team."

func match_chips() -> Array[String]:
	var mode = GameState.MODES[GameState.mode_index]
	var texts: Array[String] = [mode.name, "Teams" if GameSettings.get_setting("teams") else "Free for all"]
	for rule in mode.rules:
		var value = GameSettings.get_setting(rule)
		match rule:
			"lives":
				texts.append("1 life" if value == 1 else "%d lives" % value)
			"time_minutes":
				texts.append("%d min" % value)
	return texts

func chip_for(text: String) -> PanelContainer:
	var chip = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.draw_center = false
	style.set_border_width_all(2)
	style.border_color = Color(GameConfig.CREAM, 0.45)
	style.set_corner_radius_all(22)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 6
	style.content_margin_bottom = 4
	chip.add_theme_stylebox_override("panel", style)
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", GameConfig.CREAM)
	chip.add_child(label)
	return chip

func launch(seated: Array[int]):
	launching = true
	Sound.play("confirm")
	var dummy_seats: Array[int] = []
	if seated.size() == 1:
		for card in cards:
			if card.state == SeatCard.State.EMPTY:
				dummy_seats.append(card.seat)
				break
	GameState.start_session(seated, dummy_seats)
	SceneManager.go_to("res://main.tscn")

func open_options():
	get_viewport().gui_release_focus()
	options.open()

## Only from an empty room, so a stray press can't pull everyone out
func back_to_setup():
	if launching or leaving or not seated_players().is_empty():
		return
	leaving = true
	Sound.play("back")
	SceneManager.go_to("res://match_setup.tscn")
