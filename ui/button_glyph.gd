class_name ButtonGlyph
extends Control

## A pad button drawn in one ink: Xbox-layout face buttons, View and Menu,
## the D-pad (optionally with one direction lit) and the triggers. Outlines
## rather than fills, so it reads on any card colour.

const FACE_LETTERS: Dictionary = {"a": "A", "b": "B", "x": "X", "y": "Y"}
const DPAD_DIRECTIONS: Dictionary = {
	"dpad": Vector2.ZERO, "dpad_left": Vector2.LEFT, "dpad_right": Vector2.RIGHT,
	"dpad_up": Vector2.UP, "dpad_down": Vector2.DOWN,
}
const TRIGGER_LABELS: Dictionary = {"rt": "RT", "lt": "LT"}
const TRIGGER_WIDTH: float = 1.6  # times the height

var button: String
var ink: Color

static func knows(button_name: String) -> bool:
	return button_name in FACE_LETTERS or button_name in DPAD_DIRECTIONS \
		or button_name in TRIGGER_LABELS or button_name in ["view", "menu"]

func _init(button_name: String = "a", height: float = 32.0, glyph_ink: Color = Color("#F3E7D2")):
	if not knows(button_name):
		push_error("No glyph for pad button '%s'" % button_name)
	button = button_name
	ink = glyph_ink
	var width = height * TRIGGER_WIDTH if button in TRIGGER_LABELS else height
	custom_minimum_size = Vector2(width, height)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw():
	var s = size.y
	var centre = size * 0.5
	var line = maxf(2.0, s * 0.08)
	var radius = s * 0.5 - line * 0.5
	if button in FACE_LETTERS:
		draw_arc(centre, radius, 0.0, TAU, 48, ink, line, true)
		letter(FACE_LETTERS[button], centre, s * 0.58)
	elif button == "view":
		draw_arc(centre, radius, 0.0, TAU, 48, ink, line, true)
		# Two overlapping windows, the front one filled
		var box = Vector2(s * 0.28, s * 0.22)
		draw_rect(Rect2(centre + Vector2(-0.2, -0.17) * s, box), ink, false, line * 0.8)
		draw_rect(Rect2(centre + Vector2(-0.08, -0.05) * s, box), ink)
	elif button == "menu":
		draw_arc(centre, radius, 0.0, TAU, 48, ink, line, true)
		for row in [-1, 0, 1]:
			var y = centre.y + row * s * 0.14
			Poster.bar(self, Vector2(centre.x - s * 0.2, y), Vector2(centre.x + s * 0.2, y), line * 0.9, ink)
	elif button in DPAD_DIRECTIONS:
		draw_dpad(centre, s, line, DPAD_DIRECTIONS[button])
	elif button in TRIGGER_LABELS:
		var style = StyleBoxFlat.new()
		style.draw_center = false
		style.set_border_width_all(int(line))
		style.border_color = ink
		style.set_corner_radius_all(int(s * 0.22))
		style.corner_radius_top_right = int(s * 0.45)
		style.anti_aliasing = true
		draw_style_box(style, Rect2(Vector2.ONE * line * 0.5, size - Vector2.ONE * line))
		letter(TRIGGER_LABELS[button], centre, s * 0.48)

## A plus outline; the pressed direction's arm filled in
func draw_dpad(centre: Vector2, s: float, line: float, lit: Vector2):
	var half_arm = s * 0.17
	var reach = s * 0.5 - line * 0.5
	var outline = PackedVector2Array()
	for corner in [
		Vector2(-half_arm, -reach), Vector2(half_arm, -reach), Vector2(half_arm, -half_arm),
		Vector2(reach, -half_arm), Vector2(reach, half_arm), Vector2(half_arm, half_arm),
		Vector2(half_arm, reach), Vector2(-half_arm, reach), Vector2(-half_arm, half_arm),
		Vector2(-reach, half_arm), Vector2(-reach, -half_arm), Vector2(-half_arm, -half_arm),
		Vector2(-half_arm, -reach)]:
		outline.append(centre + corner)
	draw_polyline(outline, ink, line, true)
	if lit != Vector2.ZERO:
		var across = Vector2(lit.y, lit.x).abs() * half_arm
		var near = centre + lit * half_arm
		var far = centre + lit * reach
		draw_colored_polygon(PackedVector2Array([near - across, far - across, far + across, near + across]), ink)

func letter(text: String, centre: Vector2, font_size: float):
	# Josefin's capitals sit about 0.7 of the font size tall
	Poster.text_centred(self, centre + Vector2(0, font_size * 0.35), text, int(font_size), ink, 700)
