extends PanelContainer

## One seat on the title screen. Shows the seat's colour and ship, whether
## it's empty, joined or ready, and the pad buttons that drive it, read from
## the input map so it stays right if bindings change.

enum State { EMPTY, JOINED, READY }

## Pad buttons and triggers as ButtonPrompt tokens
const JOYPAD_BUTTON_GLYPHS: Dictionary = {0: "a", 1: "b", 2: "x", 3: "y", 4: "view", 6: "menu", 11: "dpad_up", 12: "dpad_down", 13: "dpad_left", 14: "dpad_right"}
const JOYPAD_AXIS_GLYPHS: Dictionary = {4: "lt", 5: "rt"}
const ShipIcon = preload("res://art/ship_icon.gd")

var seat: int = 0
var state: State = State.EMPTY

var header: Label
var ship: Control
var team_label: Label
var status: ButtonPrompt
var hint: ButtonPrompt

func _init(seat_number: int):
	seat = seat_number

func _ready():
	custom_minimum_size = Vector2(270, 330)
	pivot_offset = custom_minimum_size * 0.5

	var box = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_BEGIN
	box.add_theme_constant_override("separation", 6)
	add_child(box)

	header = Label.new()
	header.text = "P%d  %s" % [seat + 1, GameConfig.PLAYER_COLOR_NAMES[seat]]
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 32)
	header.add_theme_font_override("font", Poster.font(700))
	box.add_child(header)

	ship = ShipIcon.new()
	ship.custom_minimum_size = Vector2(80, 80)
	ship.ink = GameConfig.PLAYER_COLORS[seat]
	box.add_child(ship)

	team_label = _wrapping_label(24)
	box.add_child(team_label)

	status = _prompt(30)
	status.custom_minimum_size.y = 84  # room for two lines, so cards line up
	box.add_child(status)
	hint = _prompt(24)
	hint.ink = Color(GameConfig.CREAM, 0.6)
	box.add_child(hint)

	set_state(state)

func _wrapping_label(font_size: int) -> Label:
	var label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 230
	label.add_theme_font_size_override("font_size", font_size)
	return label

func _prompt(font_size: int) -> ButtonPrompt:
	var prompt = ButtonPrompt.new()
	prompt.custom_minimum_size.x = 230
	prompt.font_size = font_size
	return prompt

func set_state(new_state: State):
	var popped = new_state > state
	state = new_state
	var colour = GameConfig.PLAYER_COLORS[seat]
	var style = StyleBoxFlat.new()
	style.set_corner_radius_all(20)
	style.set_content_margin_all(18)
	match state:
		State.EMPTY:
			style.bg_color = Color(GameConfig.GROUND, 0.94)
			style.set_border_width_all(2)
			style.border_color = Color(GameConfig.CREAM, 0.2)
			header.add_theme_color_override("font_color", Color(colour, 0.75))
			ship.modulate = Color(1, 1, 1, 0.25)
			status.ink = GameConfig.CREAM
			status.text = "Press %s to join" % action_glyph("shoot%d" % seat)
			hint.text = device_label()
		State.JOINED:
			style.bg_color = Color(GameConfig.DEEP, 0.96)
			style.set_border_width_all(4)
			style.border_color = colour
			header.add_theme_color_override("font_color", colour)
			ship.modulate = Color.WHITE
			status.ink = GameConfig.CREAM
			status.text = "Press %s when ready" % action_glyph("shoot%d" % seat)
			hint.text = "%s to leave" % action_glyph("back%d" % seat)
		State.READY:
			style.bg_color = colour.lerp(GameConfig.GROUND, 0.6)
			style.set_border_width_all(6)
			style.border_color = colour
			header.add_theme_color_override("font_color", GameConfig.CREAM)
			ship.modulate = Color.WHITE
			status.ink = GameConfig.CREAM
			status.text = "READY!"
			hint.text = "%s to cancel" % action_glyph("back%d" % seat)
	add_theme_stylebox_override("panel", style)
	show_team()
	if popped:
		scale = Vector2.ONE * 1.06
		create_tween().tween_property(self, "scale", Vector2.ONE, 0.18).set_ease(Tween.EASE_OUT)

func show_team():
	var team = GameState.teams[seat]
	team_label.visible = state != State.EMPTY
	if team == GameState.SOLO:
		team_label.text = "Free for all"
		team_label.add_theme_color_override("font_color", Color(GameConfig.CREAM, 0.6))
	else:
		team_label.text = "Team %s" % GameConfig.TEAM_NAMES[team]
		team_label.add_theme_color_override("font_color", GameConfig.TEAM_COLORS[team])

## The pad button for an action as a prompt token, e.g. "{a}". Keyboard
## keys still work but aren't shown: the game is played on pads.
static func action_glyph(action: String) -> String:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton and JOYPAD_BUTTON_GLYPHS.has(event.button_index):
			return "{%s}" % JOYPAD_BUTTON_GLYPHS[event.button_index]
		if event is InputEventJoypadMotion and JOYPAD_AXIS_GLYPHS.has(event.axis):
			return "{%s}" % JOYPAD_AXIS_GLYPHS[event.axis]
	return action

## Which pad drives this seat, e.g. "Pad 1"
func device_label() -> String:
	var device = GameState.device_of(seat)
	return "" if device < 0 else "Pad %d" % (device + 1)
