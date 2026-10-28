extends Control

## Match setup, between the title and the lobby: the mode and its rules,
## chosen before anyone takes a seat. Any pad drives it. Up and down pick a
## row and left and right change it; Mode and Teams wrap round, numbers stop
## at their ends. A on Pick seats saves the match and goes to the lobby with
## that pad seated, B goes back to the title, View opens the options. It
## opens on the last match set up, on Pick seats, so a crew playing the same
## again goes straight through.

const Options = preload("res://options.gd")
const SeatCard = preload("res://seat_card.gd")
const ROW_WIDTH: float = 960.0
const PICK_SEATS: String = "Pick seats"
## The row for each rule a mode can use (GameState.MODES "rules"), and how
## its value reads
const RULE_ROWS: Dictionary = {
	"lives": {"name": "Lives", "format": "%d"},
	"time_minutes": {"name": "Time", "format": "%d:00"},
}

var mode_index: int
var teams: bool
## Each rule's value, by setting name, for every mode
var rules: Dictionary = {}
## Mode, Teams, then a row for every rule; only the mode's rules are shown
var rows: Array[OptionRow] = []
var pick_seats: PanelContainer
var pick_label: Label
## The selected row's name
var selected: String = PICK_SEATS
var leaving: bool = false
var options: Control
var options_prompt: ButtonPrompt
var back_prompt: ButtonPrompt

@onready var list: VBoxContainer = $List
@onready var hint: ButtonPrompt = $Hint

func _ready():
	Music.play_track("menu")
	mode_index = GameSettings.get_setting("last_mode")
	teams = GameSettings.get_setting("teams")
	for rule in RULE_ROWS:
		rules[rule] = GameSettings.get_setting(rule)

	var heading = Label.new()
	heading.text = "Match setup"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_override("font", Poster.font(600))
	heading.add_theme_font_size_override("font_size", 48)
	heading.add_theme_color_override("font_color", GameConfig.CREAM)
	list.add_child(heading)
	add_row("Mode")
	add_row("Teams")
	for rule in RULE_ROWS:
		add_row(RULE_ROWS[rule].name)
	pick_seats = PanelContainer.new()
	pick_seats.name = PICK_SEATS
	pick_seats.custom_minimum_size.x = ROW_WIDTH
	pick_seats.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	pick_label = Label.new()
	pick_label.text = PICK_SEATS.to_upper()
	pick_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pick_label.add_theme_font_override("font", Poster.font(700, 8))
	pick_label.add_theme_font_size_override("font_size", 40)
	pick_seats.add_child(pick_label)
	list.add_child(pick_seats)

	hint.text = "{dpad_up_down} to choose a row,  {dpad_left_right} to change it"
	options_prompt = ButtonPrompt.on_button($OptionsButton, "%s Options" % SeatCard.action_glyph("options"))
	back_prompt = ButtonPrompt.on_button($BackButton, "%s Back" % SeatCard.action_glyph("ui_cancel"))
	options = Options.new()
	options.name = "Options"
	add_child(options)
	refresh()

func add_row(row_name: String):
	var row = OptionRow.new(row_name, OptionRow.Kind.WORDS, ROW_WIDTH, true)
	row.value_label.custom_minimum_size.x = 360
	row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	rows.append(row)
	list.add_child(row)

func get_row(row_name: String) -> OptionRow:
	for row in rows:
		if row.name == row_name:
			return row
	return null

## The rows on show, top to bottom, ending with Pick seats
func shown_rows() -> Array[Control]:
	var shown: Array[Control] = []
	for row in rows:
		if row.visible:
			shown.append(row)
	shown.append(pick_seats)
	return shown

func _input(event):
	if leaving or options.visible:
		return
	if event.is_action_pressed("options"):
		get_viewport().set_input_as_handled()
		open_options()
	elif event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		back()
	elif MenuInput.pressed(event, "ui_up"):
		get_viewport().set_input_as_handled()
		move(-1)
	elif MenuInput.pressed(event, "ui_down"):
		get_viewport().set_input_as_handled()
		move(1)
	elif MenuInput.pressed(event, "ui_left"):
		get_viewport().set_input_as_handled()
		change(-1)
	elif MenuInput.pressed(event, "ui_right"):
		get_viewport().set_input_as_handled()
		change(1)
	elif event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		if selected == PICK_SEATS:
			pick(event)

func move(step: int):
	var names = shown_rows().map(func(row): return row.name)
	selected = names[posmod(names.find(selected) + step, names.size())]
	Sound.play("focus")
	refresh()

## Mode and Teams wrap round; a rule stops at its ends, silently
func change(step: int):
	match selected:
		"Mode":
			mode_index = posmod(mode_index + step, GameState.MODES.size())
		"Teams":
			teams = not teams
		PICK_SEATS:
			return
		_:
			var rule = rule_named(selected)
			var limits = GameSettings.setting_limits[rule]
			var value = clampi(rules[rule] + step, limits.smallest, limits.largest)
			if value == rules[rule]:
				return
			rules[rule] = value
	Sound.play("focus")
	refresh()

func rule_named(row_name: String) -> String:
	for rule in RULE_ROWS:
		if RULE_ROWS[rule].name == row_name:
			return rule
	return ""

func refresh():
	var mode = GameState.MODES[mode_index]
	for rule in RULE_ROWS:
		get_row(RULE_ROWS[rule].name).visible = rule in mode.rules
	get_row("Mode").show_value(mode.name)
	get_row("Mode").show_blurb(mode.blurb)
	get_row("Teams").show_value("On" if teams else "Off")
	for rule in RULE_ROWS:
		get_row(RULE_ROWS[rule].name).show_value(RULE_ROWS[rule].format % rules[rule])
	for row in rows:
		row.set_selected(row.name == selected)
	var on = selected == PICK_SEATS
	var style = StyleBoxFlat.new()
	style.set_corner_radius_all(32)
	style.content_margin_top = 16
	style.content_margin_bottom = 12
	style.bg_color = GameConfig.LIGHT if on else Color(GameConfig.DEEP, 0.92)
	style.set_border_width_all(4 if on else 2)
	style.border_color = GameConfig.CREAM if on else GameConfig.LIGHT
	pick_seats.add_theme_stylebox_override("panel", style)
	pick_label.add_theme_color_override("font_color", GameConfig.GROUND if on else GameConfig.LIGHT)

## Saves the match and takes everyone to the lobby, with the pad that
## pressed already seated
func pick(event: InputEvent):
	leaving = true
	GameSettings.set_setting("last_mode", mode_index)
	GameSettings.set_setting("teams", teams)
	for rule in rules:
		GameSettings.set_setting(rule, rules[rule])
	GameState.mode_index = mode_index
	var seat = seat_of(event)
	if seat >= 0:
		GameState.join_on_arrival = seat
	Sound.play("confirm")
	SceneManager.go_to("res://menu.tscn")

## The seat whose pad (or shoot key) pressed, or -1
func seat_of(event: InputEvent) -> int:
	for seat in GameConfig.PLAYER_COLORS.size():
		if event.is_action("shoot%d" % seat):
			return seat
	if event is InputEventJoypadButton:
		return GameState.seat_of_device(event.device)
	return -1

func back():
	leaving = true
	Sound.play("back")
	SceneManager.go_to("res://title.tscn")

func open_options():
	get_viewport().gui_release_focus()
	options.open()
