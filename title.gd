extends Control

## The first screen: the logo over drifting space and a prompt to press any
## button, which goes on to the match setup. Pressing a player's shoot button
## also takes their seat in the lobby, so the first press isn't wasted. B or
## Menu asks before quitting the game. Arriving here ends the session:
## nobody is seated and the win tally starts again.

const FADE_IN_TIME: float = 0.8

var accepting: bool = false
var leaving: bool = false

@onready var logo: Control = $Logo
@onready var prompt: Label = $Prompt
@onready var fade: ColorRect = $Fade
@onready var quit_confirm: Control = $QuitConfirm
@onready var stay_button: Button = $QuitConfirm/Center/Panel/VBox/Buttons/StayButton

func _ready():
	Music.play_track("menu")
	GameState.end_session()
	quit_confirm.hide()
	prompt.hide()
	fade.modulate.a = 1.0
	create_tween().tween_property(fade, "modulate:a", 0.0, FADE_IN_TIME)

	# The logo settles into place as the screen fades up
	var rest_y = logo.position.y
	logo.position.y -= 40
	logo.modulate.a = 0.0
	var drop = create_tween().set_parallel()
	drop.tween_property(logo, "modulate:a", 1.0, 0.9).set_delay(0.2)
	drop.tween_property(logo, "position:y", rest_y, 0.9).set_delay(0.2) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# Presses while the game boots would otherwise skip straight past
	await get_tree().create_timer(GameConfig.TITLE_INTRO_TIME).timeout
	accepting = true
	prompt.show()
	var pulse = prompt.create_tween().set_loops()
	pulse.tween_property(prompt, "modulate:a", 0.35, 0.8).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(prompt, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)

func _input(event):
	if event is InputEventMouseMotion or event is InputEventJoypadMotion:
		return
	# The dialog's buttons take every other press
	if quit_confirm.visible:
		if event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			_on_stay_button_pressed()
		return
	if not event.is_pressed() or event.is_echo():
		return
	get_viewport().set_input_as_handled()
	if not accepting or leaving:
		return
	if event.is_action("ui_cancel") or event.is_action("pause"):
		_on_quit_button_pressed()
		return
	for i in GameConfig.PLAYER_COLORS.size():
		if event.is_action("shoot%d" % i):
			GameState.join_on_arrival = i
			break
	leave()

func leave():
	leaving = true
	Sound.play("confirm")
	prompt.modulate.a = 1.0
	SceneManager.go_to("res://match_setup.tscn")

func _on_quit_button_pressed():
	quit_confirm.show()
	stay_button.grab_focus()

func _on_stay_button_pressed():
	quit_confirm.hide()
	get_viewport().gui_release_focus()

func _on_confirm_quit_button_pressed():
	get_tree().quit()
