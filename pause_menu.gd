extends Control

## The pause menu in a round. Start on any pad (or Esc) dims the arena under
## a grainy wash and pops in a poster panel: Resume, Restart, Main Menu. The
## music ducks while it's open. The results screen pauses the game itself,
## so Start does nothing there.

const POP_IN_TIME: float = 0.3
const PANEL_WIDTH: float = 560.0

const Grain = preload("res://art/grain.gd")
const SeatCard = preload("res://seat_card.gd")

var panel: PanelContainer
var heading: Label
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
	panel.add_theme_stylebox_override("panel", panel_style())
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
	box.add_child(heading)

	resume_button = add_button(box, "Resume", toggle_pause)
	add_button(box, "Restart", _on_restart_button_pressed)
	add_button(box, "Main Menu", _on_main_menu_button_pressed)

	hint = ButtonPrompt.new()
	hint.font_size = 24
	hint.ink = Color(GameConfig.CREAM, 0.6)
	hint.text = "{a} to choose,  %s to resume" % SeatCard.action_glyph("pause")
	box.add_child(hint)
	hide()

func panel_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = GameConfig.DEEP
	style.set_border_width_all(4)
	style.border_color = GameConfig.CREAM
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
		toggle_pause()

func toggle_pause():
	visible = !visible
	get_tree().paused = visible
	Music.duck(visible)
	if visible:
		pop()
		resume_button.grab_focus()

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
