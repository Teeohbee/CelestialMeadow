extends Control

## The pause menu in a round. Start on any pad (or Esc) dims the arena under
## a grainy wash and pops in a poster panel: Resume, Restart, Main Menu. The
## music ducks while it's open. The panel wears the ink of whoever paused
## and names them, though anyone can resume. The results screen pauses the
## game itself, so Start does nothing there.

const POP_IN_TIME: float = 0.3
const PANEL_WIDTH: float = 560.0

const Grain = preload("res://art/grain.gd")
const SeatCard = preload("res://seat_card.gd")

var panel: PanelContainer
var heading: Label
var paused_by: Label
var hint: ButtonPrompt
var resume_button: Button
var pop_in: Tween

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim = ColorRect.new()
	dim.name = "Dim"
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(GameConfig.GROUND, 0.7)
	add_child(dim)
	var grain = ColorRect.new()
	grain.name = "Grain"
	grain.set_script(Grain)
	grain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(grain)
	var centre = CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centre)

	panel = PanelContainer.new()
	panel.custom_minimum_size.x = PANEL_WIDTH
	centre.add_child(panel)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	panel.add_child(box)

	heading = Label.new()
	heading.text = "PAUSED"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_override("font", Poster.font(700, 12))
	heading.add_theme_font_size_override("font_size", 64)
	heading.add_theme_color_override("font_color", GameConfig.CREAM)
	heading.add_theme_constant_override("shadow_offset_x", 5)
	heading.add_theme_constant_override("shadow_offset_y", 5)
	box.add_child(heading)

	paused_by = Label.new()
	paused_by.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	paused_by.add_theme_font_size_override("font_size", 28)
	box.add_child(paused_by)

	resume_button = add_button(box, "Resume", toggle_pause)
	add_button(box, "Restart", _on_restart_button_pressed)
	add_button(box, "Main Menu", _on_main_menu_button_pressed)

	hint = ButtonPrompt.new()
	hint.font_size = 24
	hint.ink = Color(GameConfig.CREAM, 0.6)
	hint.text = "{a} to choose,  %s to resume" % SeatCard.action_glyph("pause")
	box.add_child(hint)
	wear_ink_of(-1)
	hide()

func panel_style(ink: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = GameConfig.DEEP
	style.set_border_width_all(4)
	style.border_color = ink
	style.set_corner_radius_all(40)
	style.content_margin_left = 56
	style.content_margin_right = 56
	style.content_margin_top = 36
	style.content_margin_bottom = 32
	return style

func add_button(box: VBoxContainer, text: String, action: Callable) -> Button:
	var button = Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", 34)
	button.pressed.connect(action)
	box.add_child(button)
	return button

func _input(event):
	if event.is_action_pressed("pause"):
		# Something else (the results screen) has paused the game
		if get_tree().paused and not visible:
			return
		toggle_pause(seat_of(event))

## seat is whoever paused, or -1 for nobody in particular
func toggle_pause(seat: int = -1):
	visible = !visible
	get_tree().paused = visible
	Music.duck(visible)
	if visible:
		wear_ink_of(seat)
		pop()
		resume_button.grab_focus()

## The seated pilot whose pad sent this, or -1 for the keyboard, a pad with
## no seat, or a dummy's
func seat_of(event: InputEvent) -> int:
	if not event is InputEventJoypadButton:
		return -1
	for seat in GameState.players:
		if seat in GameState.dummies:
			continue
		for bound in InputMap.action_get_events("shoot%d" % seat):
			if bound is InputEventJoypadButton and bound.device == event.device:
				return seat
	return -1

func wear_ink_of(seat: int):
	var ink = GameConfig.CREAM if seat < 0 else GameConfig.PLAYER_COLORS[seat]
	panel.add_theme_stylebox_override("panel", panel_style(ink))
	heading.add_theme_color_override("font_shadow_color", GameConfig.HUE if seat < 0 else ink)
	paused_by.visible = seat >= 0
	if seat >= 0:
		paused_by.text = "%s paused" % GameConfig.PLAYER_COLOR_NAMES[seat]
		paused_by.add_theme_color_override("font_color", ink)

## The panel grows from a little small with a slight overshoot, as the
## countdown numbers do
func pop():
	if pop_in:
		pop_in.kill()
	panel.pivot_offset = panel.size * 0.5
	panel.scale = Vector2(0.85, 0.85)
	panel.modulate.a = 0.0
	pop_in = create_tween().set_parallel().set_ignore_time_scale(true)
	pop_in.tween_property(panel, "scale", Vector2.ONE, POP_IN_TIME) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop_in.tween_property(panel, "modulate:a", 1.0, POP_IN_TIME * 0.6)

# Leaving for the lobby or a restart from here mustn't leave the music ducked
func _exit_tree():
	if visible:
		Music.duck(false)

func _on_restart_button_pressed():
	SceneManager.go_to(get_tree().current_scene.scene_file_path)

func _on_main_menu_button_pressed():
	SceneManager.go_to("res://menu.tscn")
