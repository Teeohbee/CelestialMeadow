class_name ButtonPrompt
extends HFlowContainer

## A line of text with pad buttons in it: "Press {a} when ready" shows the
## words with an A glyph between them. Each word is its own piece so the
## line wraps between words. A token with no glyph stays as text, so a typo
## shows on screen rather than vanishing.

## Setting any of these rebuilds the line, unless nothing changed: the lobby
## sets its status every frame
@export var text: String = "":
	set(value):
		if value != text:
			text = value
			rebuild()
@export var font_size: int = 32:
	set(value):
		if value != font_size:
			font_size = value
			rebuild()
@export var font_weight: int = 600:
	set(value):
		if value != font_weight:
			font_weight = value
			rebuild()
@export var ink: Color = Color("#F3E7D2"):
	set(value):
		if value != ink:
			ink = value
			rebuild()

func _init():
	alignment = FlowContainer.ALIGNMENT_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE

## A corner button's face: its pad button and what it does
static func on_button(button: Button, prompt_text: String) -> ButtonPrompt:
	var centre = CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(centre)
	var prompt = ButtonPrompt.new()
	prompt.font_size = 28
	# The whole width, or the centre box squeezes it onto two lines
	prompt.custom_minimum_size.x = button.size.x - 16
	prompt.text = prompt_text
	centre.add_child(prompt)
	return prompt

func rebuild():
	for child in get_children():
		remove_child(child)
		child.queue_free()
	add_theme_constant_override("h_separation", int(font_size * 0.3))
	for word in text.split(" ", false):
		var token = word.trim_prefix("{").trim_suffix("}")
		if word.begins_with("{") and word.ends_with("}") and ButtonGlyph.knows(token):
			add_child(ButtonGlyph.new(token, font_size * 1.15, ink))
		else:
			var label = Label.new()
			label.text = word
			label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			label.add_theme_font_override("font", Poster.font(font_weight))
			label.add_theme_font_size_override("font_size", font_size)
			label.add_theme_color_override("font_color", ink)
			add_child(label)
