extends CanvasLayer

## Each pilot's corner of the poster: an outlined numeral, a tracked
## "PILOT n" label and their lives as trail-shaped pills.

const MARGIN: float = 34.0
## Where each seat's block sits: x anchor (0 left, 0.5 centre, 1 right), top or bottom
const SLOTS: Array = [
	[0.0, true], [1.0, false], [0.0, false], [1.0, true], [0.5, true], [0.5, false],
]

var lives: Dictionary = {}
var canvas := Node2D.new()

func _ready():
	add_child(canvas)
	canvas.draw.connect(_draw_hud)
	for i in GameState.players:
		lives[i] = GameState.lives_per_player
	canvas.queue_redraw()

func update_lives(player_number: int, remaining: int):
	lives[player_number] = remaining
	canvas.queue_redraw()

func _draw_hud():
	var size = canvas.get_viewport_rect().size
	var numeral_font = Poster.font(700)
	var label_font = Poster.font(600, 4)
	for i in lives:
		var slot = SLOTS[i]
		var ink = GameConfig.PLAYER_COLORS[i]
		var top = MARGIN if slot[1] else size.y - MARGIN - 56.0
		var numeral = str(i + 1)
		var label = "PILOT %d" % (i + 1)
		var numeral_w = numeral_font.get_string_size(numeral, HORIZONTAL_ALIGNMENT_LEFT, -1, 58).x
		var label_w = label_font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		var block_w = 46.0 + maxf(label_w, 26.0 * GameState.lives_per_player)
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
		for n in GameState.lives_per_player:
			var px = x0 + block_w - 46.0 - 20.0 - n * 26.0 if right else text_x + n * 26.0
			var colour = ink if n < lives[i] else Color(GameConfig.CREAM, 0.18)
			Poster.bar(canvas, Vector2(px + 4, top + 36), Vector2(px + 16, top + 36), 8, colour)
