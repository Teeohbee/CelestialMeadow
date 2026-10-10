extends Control

## Title screen and lobby. Each player takes a seat by pressing their own
## shoot button, presses it again when ready, and rotates left to back out.
## The round launches on its own once enough players are seated and all of
## them are ready, so nobody has to drive a menu for everyone else. Any
## seated player can rotate right to change the mode, and thrusts to pick
## their team.

const SeatCard = preload("res://seat_card.gd")
const SEAT_COUNT: int = 6

## Debug builds let one player launch against an idle dummy ship, so a
## round can be won and the results screen tested with one controller
var debug_dummy: bool = OS.is_debug_build()

var cards: Array = []
var launch_countdown: float = GameConfig.TITLE_LAUNCH_DELAY
var launching: bool = false

@onready var seats_row: HBoxContainer = $Seats
@onready var status: Label = $Status
@onready var mode_label: Label = $ModeLabel
@onready var mode_blurb: Label = $ModeBlurb
@onready var quit_confirm: Control = $QuitConfirm
@onready var stay_button: Button = $QuitConfirm/Center/Panel/VBox/Buttons/StayButton

func _ready():
	for i in SEAT_COUNT:
		var card = SeatCard.new(i)
		seats_row.add_child(card)
		cards.append(card)
	# Coming back from a game, the same crew is still seated
	for i in GameState.players:
		if i not in GameState.dummies:
			cards[i].set_state(SeatCard.State.JOINED)
	spawn_asteroids()
	show_mode()
	quit_confirm.hide()

func spawn_asteroids():
	var asteroid_scene = preload("res://asteroid.tscn")
	var size = get_viewport_rect().size
	for i in GameConfig.TITLE_ASTEROID_COUNT:
		var asteroid = asteroid_scene.instantiate()
		var velocity = Vector2.RIGHT.rotated(randf() * TAU) * GameConfig.TITLE_ASTEROID_SPEED * randf_range(0.6, 1.4)
		asteroid.start(Vector2(randf() * size.x, randf() * size.y), velocity)
		$Backdrop.add_child(asteroid)

func _process(delta):
	var seated = seated_players()
	var ready_count = cards.filter(func(c): return c.state == SeatCard.State.READY).size()
	var solo_test = debug_dummy and seated.size() == 1
	var enough = seated.size() >= GameConfig.TITLE_MIN_PLAYERS or solo_test
	var sides = {}
	for seat in seated:
		sides[GameState.side_of(seat)] = true
	# The debug dummy always flies solo, so a lone tester has an opponent
	var one_side = sides.size() < 2 and not solo_test
	var can_launch = enough and not one_side and ready_count == seated.size()

	if can_launch and not launching:
		launch_countdown -= delta
		if launch_countdown <= 0.0:
			launch(seated)
	else:
		launch_countdown = GameConfig.TITLE_LAUNCH_DELAY

	if not launching and not quit_confirm.visible:
		pick_teams()

	if seated.is_empty():
		status.text = "Press shoot to take a seat"
	elif not enough:
		status.text = "Waiting for another pilot"
	elif one_side:
		status.text = "Pick at least two sides"
	elif not can_launch:
		status.text = "%d of %d ready" % [ready_count, seated.size()]
	elif solo_test:
		status.text = "Launching in %d against a dummy (debug)" % ceili(launch_countdown)
	else:
		status.text = "Launching in %d" % ceili(launch_countdown)

func seated_players() -> Array[int]:
	var seated: Array[int] = []
	for card in cards:
		if card.state != SeatCard.State.EMPTY:
			seated.append(card.seat)
	return seated

func _input(event):
	if launching:
		return
	if quit_confirm.visible:
		if event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			_on_stay_button_pressed()
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_on_quit_button_pressed()
		return
	for i in SEAT_COUNT:
		if event.is_action_pressed("shoot%d" % i):
			get_viewport().set_input_as_handled()
			advance(cards[i])
			return
		if event.is_action_pressed("rotate_left%d" % i):
			get_viewport().set_input_as_handled()
			back(cards[i])
			return
		if event.is_action_pressed("rotate_right%d" % i):
			get_viewport().set_input_as_handled()
			if cards[i].state != SeatCard.State.EMPTY:
				next_mode()
			return

func advance(card):
	if card.state == SeatCard.State.EMPTY:
		card.set_state(SeatCard.State.JOINED)
	elif card.state == SeatCard.State.JOINED:
		card.set_state(SeatCard.State.READY)

func back(card):
	if card.state == SeatCard.State.READY:
		card.set_state(SeatCard.State.JOINED)
	elif card.state == SeatCard.State.JOINED:
		GameState.teams[card.seat] = GameState.SOLO
		card.set_state(SeatCard.State.EMPTY)

## Everyone readied up for the old mode, so they ready again for the new one
func next_mode():
	GameState.mode_index = (GameState.mode_index + 1) % GameState.MODES.size()
	unready_all()
	show_mode()

## Thrust is an analog trigger on pads, which sends a stream of motion
## events per pull; polling the action catches each pull exactly once
func pick_teams():
	for card in cards:
		if card.state != SeatCard.State.EMPTY and Input.is_action_just_pressed("thrust%d" % card.seat):
			next_team(card)

## Solo, then each team in turn, then back to solo. Teams change the
## match for everyone, so everyone readies again.
func next_team(card):
	var team = GameState.teams[card.seat] + 1
	if team >= GameConfig.TEAM_NAMES.size():
		team = GameState.SOLO
	GameState.teams[card.seat] = team
	unready_all()
	card.show_team()

func unready_all():
	for card in cards:
		if card.state == SeatCard.State.READY:
			card.set_state(SeatCard.State.JOINED)

func show_mode():
	var mode = GameState.MODES[GameState.mode_index]
	mode_label.text = "Mode:  %s" % mode.name
	mode_blurb.text = "%s  Rotate right to change mode, thrust to pick a team." % mode.blurb

func launch(seated: Array[int]):
	launching = true
	var dummy_seats: Array[int] = []
	if seated.size() == 1:
		for card in cards:
			if card.state == SeatCard.State.EMPTY:
				dummy_seats.append(card.seat)
				break
	GameState.start_session(seated, dummy_seats)
	get_tree().change_scene_to_file("res://main.tscn")

func _on_quit_button_pressed():
	quit_confirm.show()
	stay_button.grab_focus()

func _on_stay_button_pressed():
	quit_confirm.hide()
	get_viewport().gui_release_focus()

func _on_confirm_quit_button_pressed():
	get_tree().quit()
