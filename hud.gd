extends CanvasLayer

## Each pilot's corner of the poster: an outlined numeral, a tracked
## "PILOT n" label and their lives as trail-shaped pills, or their kills
## when lives are unlimited.

const MARGIN: float = 34.0
## Where each seat's block sits: x anchor (0 left, 0.5 centre, 1 right), top or bottom
const SLOTS: Array = [
	[0.0, true], [1.0, false], [0.0, false], [1.0, true], [0.5, true], [0.5, false],
]

var lives: Dictionary = {}
## Pill slots per pilot: the most lives they've had, so a lost life shows as
## an empty pill and unlimited lives (negative) show none
var pill_slots: Dictionary = {}
var scores: Dictionary = {}
var hidden: Dictionary = {}
var canvas := Node2D.new()
var clock: Label
var side_scores: Label
var banner: Label

func _ready():
	add_child(canvas)
	canvas.draw.connect(_draw_hud)

	clock = Label.new()
	clock.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	clock.position.y = 12
	clock.grow_horizontal = Control.GROW_DIRECTION_BOTH
	clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	clock.add_theme_font_size_override("font_size", 44)
	clock.add_theme_constant_override("outline_size", 8)
	clock.add_theme_color_override("font_outline_color", Color.BLACK)
	clock.hide()
	add_child(clock)

	side_scores = Label.new()
	side_scores.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	side_scores.position.y = 64
	side_scores.grow_horizontal = Control.GROW_DIRECTION_BOTH
	side_scores.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	side_scores.add_theme_font_size_override("font_size", 28)
	side_scores.add_theme_constant_override("outline_size", 6)
	side_scores.add_theme_color_override("font_outline_color", Color.BLACK)
	side_scores.hide()
	add_child(side_scores)

	banner = Label.new()
	banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	banner.grow_vertical = Control.GROW_DIRECTION_BOTH
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_theme_font_size_override("font_size", 96)
	banner.add_theme_color_override("font_color", Color(1, 0.35, 0.25))
	banner.add_theme_constant_override("outline_size", 12)
	banner.add_theme_color_override("font_outline_color", Color.BLACK)
	banner.hide()
	# Finish fading even if the round ends and pauses mid-announcement
	banner.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(banner)

func update_lives(player_number: int, remaining: int):
	lives[player_number] = remaining
	pill_slots[player_number] = maxi(pill_slots.get(player_number, 0), remaining)
	canvas.queue_redraw()

func hide_player(player_number: int):
	hidden[player_number] = true
	canvas.queue_redraw()

func update_score(player_number: int, score: int):
	scores[player_number] = score
	canvas.queue_redraw()

## Pilots whose block is drawn, in seat order
func shown_players() -> Array:
	return lives.keys().filter(func(i): return i not in hidden)

## Team totals under the clock, e.g. "Alpha 3  -  Beta 2"
func set_team_scores(totals: Dictionary):
	var parts: Array[String] = []
	for team in GameConfig.TEAM_NAMES.size():
		if team in totals:
			parts.append("%s %d" % [GameConfig.TEAM_NAMES[team], totals[team]])
	side_scores.text = "  -  ".join(parts)
	side_scores.visible = not parts.is_empty()
	canvas.queue_redraw()

## Shows the time left as m:ss, top centre
func set_clock(seconds: float):
	if not clock.visible:
		clock.show()
		canvas.queue_redraw()
	var whole = ceili(seconds)
	clock.text = "%d:%02d" % [whole / 60, whole % 60]
	clock.modulate = Color(1, 0.4, 0.3) if seconds <= 10 else Color.WHITE

## Big centred announcement that fades after a moment
func show_banner(text: String):
	banner.text = text
	banner.show()
	banner.modulate.a = 1.0
	banner.pivot_offset = banner.size * 0.5
	banner.scale = Vector2.ONE * 1.4
	var tween = banner.create_tween()
	tween.tween_property(banner, "scale", Vector2.ONE, 0.25).set_ease(Tween.EASE_OUT)
	tween.tween_interval(1.5)
	tween.tween_property(banner, "modulate:a", 0.0, 0.6)
	tween.tween_callback(banner.hide)

## Player 5's corner is top centre, shared with the clock and team totals;
## keep it below whichever of those are showing
func top_centre_offset() -> float:
	var y = 0.0
	if clock.visible:
		y += 56.0
	if side_scores.visible:
		y += 40.0
	return y

func _draw_hud():
	var size = canvas.get_viewport_rect().size
	var numeral_font = Poster.font(700)
	var label_font = Poster.font(600, 4)
	for i in shown_players():
		var slot = SLOTS[i]
		var ink = GameConfig.PLAYER_COLORS[i]
		var top = MARGIN if slot[1] else size.y - MARGIN - 56.0
		if i == 4:
			top += top_centre_offset()
		var numeral = str(i + 1)
		var label = "PILOT %d" % (i + 1)
		var score = str(scores[i]) if i in scores else ""
		var slots = pill_slots[i]
		var numeral_w = numeral_font.get_string_size(numeral, HORIZONTAL_ALIGNMENT_LEFT, -1, 58).x
		var label_w = label_font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		var score_w = label_font.get_string_size(score, HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x
		var pills_w = 26.0 * slots
		var row_w = pills_w + (score_w + (8.0 if slots > 0 else 0.0) if score else 0.0)
		var block_w = 46.0 + maxf(label_w, row_w)
		# Mirror on the right so the numeral always sits nearest the corner
		var right = slot[0] == 1.0
		var x0 = MARGIN + 12.0
		if right:
			x0 = size.x - MARGIN - 12.0 - block_w
		elif slot[0] == 0.5:
			x0 = (size.x - block_w) * 0.5
		var num_x = x0 + block_w - numeral_w if right else x0
		var text_x = x0 if right else x0 + 46.0
		canvas.draw_string_outline(numeral_font, Vector2(num_x, top + numeral_font.get_ascent(58) - 8), numeral, HORIZONTAL_ALIGNMENT_LEFT, -1, 58, 3, ink)
		var label_x = x0 + block_w - 46.0 - label_w if right else text_x
		canvas.draw_string(label_font, Vector2(label_x, top + 8 + label_font.get_ascent(14)), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(GameConfig.CREAM, 0.8))
		for n in slots:
			var px = x0 + block_w - 46.0 - 20.0 - n * 26.0 if right else text_x + n * 26.0
			var colour = ink if n < lives[i] else Color(GameConfig.CREAM, 0.18)
			Poster.bar(canvas, Vector2(px + 4, top + 36), Vector2(px + 16, top + 36), 8, colour)
		if score:
			var sx = x0 + block_w - 46.0 - row_w if right else text_x + row_w - score_w
			canvas.draw_string(label_font, Vector2(sx, top + 46), score, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, ink)
