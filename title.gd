extends Control

## The first screen: the logo over drifting space and a prompt to press any
## button. Pressing a player's shoot button also takes their seat in the
## lobby, so the first press isn't wasted.

const FADE_IN_TIME: float = 0.8

var accepting: bool = false
var leaving: bool = false

@onready var logo: Control = $Logo
@onready var prompt: Label = $Prompt
@onready var fade: ColorRect = $Fade

func _ready():
	Music.play_track("menu")
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
	if not event.is_pressed() or event.is_echo():
		return
	get_viewport().set_input_as_handled()
	if not accepting or leaving or event.is_action("ui_cancel"):
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
	SceneManager.go_to("res://menu.tscn")
