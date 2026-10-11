extends PanelContainer

## One seat on the title screen. Shows the seat's colour and ship, whether
## it's empty, joined or ready, and the controls that drive it, read from
## the input map so it stays right if bindings change.

enum State { EMPTY, JOINED, READY }

const JOYPAD_BUTTON_NAMES: Dictionary = {0: "A", 1: "B", 2: "X", 3: "Y", 6: "Start", 13: "D-pad Left", 14: "D-pad Right"}
const JOYPAD_AXIS_NAMES: Dictionary = {4: "LT", 5: "RT"}
const ShipIcon = preload("res://art/ship_icon.gd")

var seat: int = 0
var state: State = State.EMPTY

var header: Label
var ship: Control
var status: Label
var hint: Label

func _init(seat_number: int):
	seat = seat_number

func _ready():
	custom_minimum_size = Vector2(270, 330)
	pivot_offset = custom_minimum_size * 0.5

	var box = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_BEGIN
	box.add_theme_constant_override("separation", 10)
	add_child(box)

	header = Label.new()
	header.text = "P%d  %s" % [seat + 1, GameConfig.PLAYER_COLOR_NAMES[seat]]
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 32)
	header.add_theme_font_override("font", Poster.font(700))
	box.add_child(header)

	ship = ShipIcon.new()
	ship.custom_minimum_size = Vector2(110, 110)
	ship.ink = GameConfig.PLAYER_COLORS[seat]
	box.add_child(ship)

	status = _wrapping_label(30)
	status.custom_minimum_size.y = 84  # room for two lines, so cards line up
	box.add_child(status)
	hint = _wrapping_label(24)
	hint.add_theme_color_override("font_color", Color(GameConfig.CREAM, 0.6))
	box.add_child(hint)

	set_state(state)

func _wrapping_label(font_size: int) -> Label:
	var label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 230
	label.add_theme_font_size_override("font_size", font_size)
	return label

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
			status.text = "Press %s to join" % action_label("shoot%d" % seat)
			status.remove_theme_color_override("font_color")
			hint.text = device_label()
		State.JOINED:
			style.bg_color = Color(GameConfig.DEEP, 0.96)
			style.set_border_width_all(4)
			style.border_color = colour
			header.add_theme_color_override("font_color", colour)
			ship.modulate = Color.WHITE
			status.text = "Press %s when ready" % action_label("shoot%d" % seat)
			status.remove_theme_color_override("font_color")
			hint.text = "%s to leave" % action_label("rotate_left%d" % seat)
		State.READY:
			style.bg_color = colour.lerp(GameConfig.GROUND, 0.6)
			style.set_border_width_all(6)
			style.border_color = colour
			header.add_theme_color_override("font_color", GameConfig.CREAM)
			ship.modulate = Color.WHITE
			status.text = "READY!"
			status.add_theme_color_override("font_color", GameConfig.CREAM)
			hint.text = "%s to cancel" % action_label("rotate_left%d" % seat)
	add_theme_stylebox_override("panel", style)
	if popped:
		scale = Vector2.ONE * 1.06
		create_tween().tween_property(self, "scale", Vector2.ONE, 0.18).set_ease(Tween.EASE_OUT)

## Every binding for an action, keyboard first, e.g. "Space / A"
func action_label(action: String) -> String:
	var keys: Array[String] = []
	var pads: Array[String] = []
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			keys.append(OS.get_keycode_string(event.physical_keycode if event.physical_keycode else event.keycode))
		elif event is InputEventJoypadButton:
			pads.append(JOYPAD_BUTTON_NAMES.get(event.button_index, "Button %d" % event.button_index))
		elif event is InputEventJoypadMotion:
			pads.append(JOYPAD_AXIS_NAMES.get(event.axis, "Stick"))
	return " / ".join(keys + pads)

## Which devices drive this seat, e.g. "Keyboard or Pad 1"
func device_label() -> String:
	var has_keyboard = false
	var pad = -1
	for event in InputMap.action_get_events("shoot%d" % seat):
		if event is InputEventKey:
			has_keyboard = true
		elif event is InputEventJoypadButton and event.device >= 0:
			pad = event.device
	var parts: Array[String] = []
	if has_keyboard:
		parts.append("Keyboard")
	if pad >= 0:
		parts.append("Pad %d" % (pad + 1))
	return " or ".join(parts)
