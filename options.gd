extends Control

## The options panel over the lobby. Any pad's D-pad picks a row and changes
## it, A chooses, and B, View or Start close it. While it's open it takes
## every press, so nobody joins, leaves or changes mode behind it. Changes
## apply and save as they're made.

signal closed

const ROW_WIDTH: float = 640.0
const PIP_COUNT: int = 10

## Each row: its name, and the setting it changes ("" for none). A number
## setting is a volume shown as bars; an on/off one toggles.
const ROWS: Array[Dictionary] = [
	{"name": "Music", "setting": "music_volume"},
	{"name": "Sounds", "setting": "sound_volume"},
	{"name": "Fullscreen", "setting": "fullscreen"},
	{"name": "Back", "setting": ""},
]

var panel: PanelContainer
var rows: Array[PanelContainer] = []
var labels: Array[Label] = []
## Each row's volume bars, or null
var pip_rows: Array = []
## Each row's On/Off label, or null
var values: Array = []
var selected: int = 0

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim = ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(GameConfig.GROUND, 0.75)
	add_child(dim)
	var centre = CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centre)
	panel = PanelContainer.new()
	centre.add_child(panel)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)

	var heading = Label.new()
	heading.text = "OPTIONS"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_override("font", Poster.font(700, 12))
	heading.add_theme_font_size_override("font_size", 48)
	heading.add_theme_color_override("font_color", GameConfig.LIGHT)
	box.add_child(heading)

	for row in ROWS:
		rows.append(make_row(row))
		box.add_child(rows[-1])

	var hint = Label.new()
	hint.text = "D-pad to change  -  B to close"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 24)
	hint.add_theme_color_override("font_color", Color(GameConfig.CREAM, 0.6))
	box.add_child(hint)
	hide()

func make_row(row: Dictionary) -> PanelContainer:
	var container = PanelContainer.new()
	container.name = row.name
	container.custom_minimum_size.x = ROW_WIDTH
	var line = HBoxContainer.new()
	container.add_child(line)
	var label = Label.new()
	label.text = row.name
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 34)
	line.add_child(label)
	labels.append(label)
	var pips = null
	var value = null
	if row.setting != "" and GameSettings.get_setting(row.setting) is bool:
		value = Label.new()
		value.add_theme_font_size_override("font_size", 34)
		line.add_child(value)
	elif row.setting != "":
		pips = Control.new()
		pips.custom_minimum_size = Vector2(300, 40)
		pips.draw.connect(draw_pips.bind(pips, row.setting, ROWS.find(row)))
		line.add_child(pips)
	pip_rows.append(pips)
	values.append(value)
	return container

func open():
	selected = 0
	show()
	refresh()
	Sound.play("confirm")

func close():
	hide()
	Sound.play("back")
	closed.emit()

func _input(event):
	if not visible:
		return
	# Every press stops here, so the lobby behind never sees it
	get_viewport().set_input_as_handled()
	var row = ROWS[selected]
	var toggles = values[selected] != null
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("options") or event.is_action_pressed("pause"):
		close()
	elif event.is_action_pressed("ui_up"):
		select(selected - 1)
	elif event.is_action_pressed("ui_down"):
		select(selected + 1)
	elif toggles and (event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right") or event.is_action_pressed("ui_accept")):
		toggle(row.setting)
	elif row.setting != "" and event.is_action_pressed("ui_left", true):
		change_volume(row.setting, -1)
	elif row.setting != "" and event.is_action_pressed("ui_right", true):
		change_volume(row.setting, 1)
	elif row.name == "Back" and event.is_action_pressed("ui_accept"):
		close()

func select(index: int):
	selected = posmod(index, rows.size())
	Sound.play("focus")
	refresh()

func change_volume(setting: String, step: int):
	var volume = GameSettings.get_setting(setting)
	GameSettings.set_setting(setting, volume + step)
	# A blip at the new level, rising with it; silence at 0 says it's off
	if GameSettings.get_setting(setting) != volume:
		Sound.play("focus", 0.8 + 0.04 * GameSettings.get_setting(setting))
	refresh()

func toggle(setting: String):
	GameSettings.set_setting(setting, not GameSettings.get_setting(setting))
	Sound.play("confirm")
	refresh()

func refresh():
	for i in rows.size():
		var is_selected = i == selected
		var style = StyleBoxFlat.new()
		style.set_corner_radius_all(32)
		style.content_margin_left = 28
		style.content_margin_right = 28
		style.content_margin_top = 10
		style.content_margin_bottom = 10
		style.bg_color = Color(GameConfig.MID, 0.95) if is_selected else Color(GameConfig.DEEP, 0.92)
		style.set_border_width_all(4 if is_selected else 2)
		style.border_color = GameConfig.LIGHT if is_selected else Color(GameConfig.CREAM, 0.35)
		rows[i].add_theme_stylebox_override("panel", style)
		labels[i].add_theme_color_override("font_color", GameConfig.LIGHT if is_selected else GameConfig.CREAM)
		if pip_rows[i]:
			pip_rows[i].queue_redraw()
		if values[i]:
			values[i].text = "On" if GameSettings.get_setting(ROWS[i].setting) else "Off"
			values[i].add_theme_color_override("font_color", GameConfig.LIGHT if is_selected else GameConfig.CREAM)

## The volume as a row of flat bars, lit up to the level
func draw_pips(pips: Control, setting: String, row_index: int):
	var volume = GameSettings.get_setting(setting)
	var lit = GameConfig.LIGHT if row_index == selected else GameConfig.CREAM
	var gap = pips.size.x / PIP_COUNT
	for i in PIP_COUNT:
		var x = gap * (i + 0.5)
		var height = 14.0 + 18.0 * i / (PIP_COUNT - 1)
		var colour = lit if i < volume else Color(GameConfig.CREAM, 0.18)
		Poster.bar(pips, Vector2(x, pips.size.y * 0.5 + height * 0.5), Vector2(x, pips.size.y * 0.5 - height * 0.5), 10.0, colour)
