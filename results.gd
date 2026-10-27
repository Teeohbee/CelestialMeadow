extends CanvasLayer

## End-of-round results: who won, the session's win tally, and a fast route
## into the next round. Any player's controls can drive it: rotate to choose,
## shoot to confirm.

const PIP_SIZE: Vector2 = Vector2(22, 10)

var locked: bool = true
var chosen: bool = false

@onready var ship: Control = $Center/Panel/Margin/VBox/Ship
@onready var title: Label = $Center/Panel/Margin/VBox/Title
@onready var subtitle: Label = $Center/Panel/Margin/VBox/Subtitle
@onready var heading: Label = $Center/Panel/Margin/VBox/TallyHeading
@onready var tally: VBoxContainer = $Center/Panel/Margin/VBox/Tally
@onready var rematch_button: Button = $Center/Panel/Margin/VBox/Buttons/RematchButton
@onready var menu_button: Button = $Center/Panel/Margin/VBox/Buttons/MenuButton

func _ready():
	# Poster type: a cream title offset in the winner's ink, like the HUD
	# banner; the small print is tracked capitals like the pilot labels
	title.add_theme_font_override("font", Poster.font(700))
	title.add_theme_color_override("font_color", GameConfig.CREAM)
	title.add_theme_constant_override("shadow_offset_x", 5)
	title.add_theme_constant_override("shadow_offset_y", 5)
	subtitle.add_theme_font_override("font", Poster.font(600, 6))
	subtitle.add_theme_color_override("font_color", Color(GameConfig.CREAM, 0.8))
	heading.add_theme_font_override("font", Poster.font(600, 6))
	heading.add_theme_color_override("font_color", GameConfig.LIGHT)

## winners is every player credited with the round; empty for a draw.
## scores is each player's score this round, if the mode keeps one.
func show_result(winners: Array[int], scores: Dictionary = {}):
	var team = GameState.teams[winners[0]] if not winners.is_empty() else GameState.SOLO
	if team != GameState.SOLO:
		var colour = GameConfig.TEAM_COLORS[team]
		# Alpha's cream would vanish against the cream title and hull
		if colour == GameConfig.CREAM:
			colour = GameConfig.HUE
		title.text = "Team %s Wins!" % GameConfig.TEAM_NAMES[team]
		title.add_theme_color_override("font_shadow_color", colour)
		subtitle.text = names(winners)
		ship.ink = colour
	elif winners.size() == 1:
		var winner_number = winners[0]
		var colour = GameConfig.PLAYER_COLORS[winner_number]
		title.text = "%s Wins!" % GameConfig.PLAYER_COLOR_NAMES[winner_number]
		title.add_theme_color_override("font_shadow_color", colour)
		subtitle.text = "Player %d" % (winner_number + 1)
		ship.ink = colour
	else:
		title.text = "Draw!"
		title.add_theme_color_override("font_shadow_color", GameConfig.HUE)
		subtitle.text = "Everyone lost"
		ship.hide()
	build_tally(winners, scores)

	get_tree().paused = true
	set_buttons_disabled(true)
	# Everyone is mashing shoot when the last ship dies; don't let that
	# skip the screen
	await get_tree().create_timer(GameConfig.RESULTS_INPUT_LOCK).timeout
	locked = false
	set_buttons_disabled(false)
	rematch_button.grab_focus()

## "Red", "Red & Green", "Red, Green & Blue"
func names(players: Array[int]) -> String:
	var colour_names = players.map(func(p): return GameConfig.PLAYER_COLOR_NAMES[p])
	if colour_names.size() == 1:
		return colour_names[0]
	return "%s & %s" % [", ".join(colour_names.slice(0, -1)), colour_names[-1]]

func build_tally(winners: Array[int], scores: Dictionary):
	for i in GameState.players:
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var name_label = Label.new()
		name_label.text = GameConfig.PLAYER_COLOR_NAMES[i]
		name_label.custom_minimum_size.x = 130
		name_label.add_theme_font_override("font", Poster.font(600))
		name_label.add_theme_color_override("font_color", GameConfig.PLAYER_COLORS[i])
		name_label.add_theme_font_size_override("font_size", 22)
		row.add_child(name_label)
		if i in scores:
			var kills = Label.new()
			kills.name = "Kills"
			kills.text = "%d kill%s" % [scores[i], "" if scores[i] == 1 else "s"]
			kills.custom_minimum_size.x = 100
			kills.add_theme_font_override("font", Poster.font(700))
			kills.add_theme_color_override("font_color", GameConfig.PLAYER_COLORS[i])
			kills.add_theme_font_size_override("font_size", 22)
			row.add_child(kills)
		for w in GameState.wins[i]:
			var pip = pill(GameConfig.PLAYER_COLORS[i])
			row.add_child(pip)
			# The win just earned fades in
			if i in winners and w == GameState.wins[i] - 1:
				pip.modulate.a = 0.0
				var tween = create_tween()
				tween.tween_interval(0.4)
				tween.tween_property(pip, "modulate:a", 1.0, 0.5)
		tally.add_child(row)

## A win as a trail-shaped pill, like the HUD's lives
func pill(colour: Color) -> Control:
	var pip = Control.new()
	pip.custom_minimum_size = PIP_SIZE
	pip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pip.draw.connect(func():
		var r = PIP_SIZE.y * 0.5
		Poster.bar(pip, Vector2(r, r), Vector2(PIP_SIZE.x - r, r), PIP_SIZE.y, colour))
	return pip

func set_buttons_disabled(disabled: bool):
	rematch_button.disabled = disabled
	menu_button.disabled = disabled

func _input(event):
	if not is_player_event(event):
		return
	get_viewport().set_input_as_handled()
	if locked or chosen:
		return
	for i in GameConfig.PLAYER_COLORS.size():
		if event.is_action_pressed("shoot%d" % i):
			var focused = get_viewport().gui_get_focus_owner()
			if focused is Button:
				focused.pressed.emit()
			return
		if event.is_action_pressed("rotate_left%d" % i):
			rematch_button.grab_focus()
			return
		if event.is_action_pressed("rotate_right%d" % i):
			menu_button.grab_focus()
			return

func is_player_event(event: InputEvent) -> bool:
	for i in GameConfig.PLAYER_COLORS.size():
		for action in ["shoot%d", "rotate_left%d", "rotate_right%d"]:
			if event.is_action(action % i):
				return true
	return false

func _on_rematch_button_pressed():
	if chosen:
		return
	chosen = true
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_menu_button_pressed():
	if chosen:
		return
	chosen = true
	get_tree().paused = false
	get_tree().change_scene_to_file("res://menu.tscn")
