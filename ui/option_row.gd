class_name OptionRow
extends PanelContainer

## One line of a menu panel: a name and its value, shown as a word (On, 3,
## 2:00) or as a row of bars. The screen that owns it picks which row is
## selected and changes the values; the row only shows them, lit in amber
## while selected. A row can also show < > either side of its value, and a
## line of explanation under it.

enum Kind { NONE, WORDS, BARS }

const FONT_SIZE: int = 34

var label: Label
## The value as a word, or null for bars or no value
var value_label: Label
## Bars lit up to the value, or null for a word or no value
var bars: Control
var bar_count: int = 10
var bar_value: int = 0
var arrows: Array[Control] = []
var blurb: Label
var selected: bool = false

func _init(row_name: String, kind: Kind = Kind.NONE, width: float = 640.0, with_arrows: bool = false):
	name = row_name
	custom_minimum_size.x = width
	var lines = VBoxContainer.new()
	lines.add_theme_constant_override("separation", 0)
	add_child(lines)
	var line = HBoxContainer.new()
	line.add_theme_constant_override("separation", 18)
	lines.add_child(line)
	label = Label.new()
	label.text = row_name
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	line.add_child(label)
	if with_arrows:
		arrows.append(arrow(-1))
		line.add_child(arrows[0])
	if kind == Kind.WORDS:
		value_label = Label.new()
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		value_label.add_theme_font_size_override("font_size", FONT_SIZE)
		line.add_child(value_label)
	elif kind == Kind.BARS:
		bars = Control.new()
		bars.custom_minimum_size = Vector2(300, 40)
		bars.draw.connect(draw_bars)
		line.add_child(bars)
	if with_arrows:
		arrows.append(arrow(1))
		line.add_child(arrows[1])
	blurb = Label.new()
	blurb.add_theme_font_size_override("font_size", 24)
	blurb.add_theme_color_override("font_color", Color(GameConfig.CREAM, 0.7))
	blurb.hide()
	lines.add_child(blurb)
	set_selected(false)

## A small flat triangle pointing left (-1) or right (1)
func arrow(direction: int) -> Control:
	var tip = Control.new()
	tip.custom_minimum_size = Vector2(22, 40)
	tip.draw.connect(func():
		var ink = GameConfig.LIGHT if selected else Color(GameConfig.CREAM, 0.6)
		var mid = tip.size * 0.5
		var points = PackedVector2Array([mid + Vector2(8 * direction, 0), mid + Vector2(-8 * direction, -10), mid + Vector2(-8 * direction, 10)])
		tip.draw_colored_polygon(points, ink))
	return tip

func show_value(value: Variant):
	if value_label:
		value_label.text = str(value)
	elif bars:
		bar_value = value
		bars.queue_redraw()

func show_blurb(text: String):
	blurb.text = text
	blurb.visible = text != ""

func set_selected(on: bool):
	selected = on
	var style = StyleBoxFlat.new()
	style.set_corner_radius_all(32)
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	style.bg_color = Color(GameConfig.MID, 0.95) if on else Color(GameConfig.DEEP, 0.92)
	style.set_border_width_all(4 if on else 2)
	style.border_color = GameConfig.LIGHT if on else Color(GameConfig.CREAM, 0.35)
	add_theme_stylebox_override("panel", style)
	var ink = GameConfig.LIGHT if on else GameConfig.CREAM
	label.add_theme_color_override("font_color", ink)
	if value_label:
		value_label.add_theme_color_override("font_color", ink)
	if bars:
		bars.queue_redraw()
	for tip in arrows:
		tip.queue_redraw()

## The value as a row of flat bars, lit up to it and rising left to right
func draw_bars():
	var lit = GameConfig.LIGHT if selected else GameConfig.CREAM
	var gap = bars.size.x / bar_count
	for i in bar_count:
		var x = gap * (i + 0.5)
		var height = 14.0 + 18.0 * i / (bar_count - 1)
		var colour = lit if i < bar_value else Color(GameConfig.CREAM, 0.18)
		Poster.bar(bars, Vector2(x, bars.size.y * 0.5 + height * 0.5), Vector2(x, bars.size.y * 0.5 - height * 0.5), 10.0, colour)
