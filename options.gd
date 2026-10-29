extends Control

## The options panel over the lobby. Any pad's D-pad picks a row and changes
## it, A chooses, and B, View or Start close it. While it's open it takes
## every press, so nobody joins, leaves or changes mode behind it. Changes
## apply and save as they're made.

signal closed

## Each row: its name, and the setting it changes ("" for none). A number
## setting is a volume shown as bars; an on/off one toggles, shown as On/Off
## or as the row's own words for off and on. A number setting with words
## steps through them instead. Display switches DisplayDriver, restarting.
const ROWS: Array[Dictionary] = [
	{"name": "Music", "setting": "music_volume"},
	{"name": "Sounds", "setting": "sound_volume"},
	{"name": "Fullscreen", "setting": "fullscreen"},
	{"name": "Resolution", "setting": "render_1080p", "words": ["Native", "1080p"]},
	# In DisplayServer.VSyncMode order
	{"name": "VSync", "setting": "vsync_mode", "words": ["Off", "On", "Adaptive", "Mailbox"]},
	{"name": "Frame readout", "setting": "perf_readout"},
	{"name": "Display", "setting": "", "display": true},
	{"name": "Back", "setting": ""},
]

var panel: PanelContainer
var hint: ButtonPrompt
var rows: Array[OptionRow] = []
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

	hint = ButtonPrompt.new()
	hint.font_size = 24
	hint.ink = Color(GameConfig.CREAM, 0.6)
	hint.text = "{dpad} to change,  {b} to close"
	box.add_child(hint)
	hide()

func make_row(row: Dictionary) -> OptionRow:
	var kind = OptionRow.Kind.NONE
	if row.has("display"):
		kind = OptionRow.Kind.WORDS
	elif row.setting != "":
		kind = OptionRow.Kind.WORDS if GameSettings.get_setting(row.setting) is bool or row.has("words") else OptionRow.Kind.BARS
	var option_row = OptionRow.new(row.name, kind)
	if row.has("display"):
		option_row.show_blurb("Restarts the game" if DisplayDriver.can_switch() else "Only in the Linux build")
	values.append(option_row.value_label)
	return option_row

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
	elif MenuInput.pressed(event, "ui_up"):
		select(selected - 1)
	elif MenuInput.pressed(event, "ui_down"):
		select(selected + 1)
	elif row.has("display") and (MenuInput.pressed(event, "ui_left") or MenuInput.pressed(event, "ui_right") or event.is_action_pressed("ui_accept")):
		Sound.play("confirm")
		DisplayDriver.switch(get_tree())
	elif toggles and (MenuInput.pressed(event, "ui_left") or MenuInput.pressed(event, "ui_right") or event.is_action_pressed("ui_accept")):
		toggle(row, -1 if MenuInput.pressed(event, "ui_left") else 1)
	elif row.setting != "" and MenuInput.pressed(event, "ui_left", true):
		change_volume(row.setting, -1)
	elif row.setting != "" and MenuInput.pressed(event, "ui_right", true):
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

func toggle(row: Dictionary, step: int):
	var value = GameSettings.get_setting(row.setting)
	if value is bool:
		GameSettings.set_setting(row.setting, not value)
	else:
		GameSettings.set_setting(row.setting, posmod(value + step, row.words.size()))
	Sound.play("confirm")
	refresh()

func refresh():
	for i in rows.size():
		rows[i].set_selected(i == selected)
		var setting = ROWS[i].setting
		if ROWS[i].has("display"):
			rows[i].show_value(DisplayDriver.label())
		elif setting != "":
			var value = GameSettings.get_setting(setting)
			var words = ROWS[i].get("words", ["Off", "On"])
			rows[i].show_value(words[int(value)] if value is bool or ROWS[i].has("words") else value)
