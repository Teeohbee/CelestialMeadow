extends GameMode

## Lives, but only the bomb takes them. One ship at a time carries it, with
## a fuse of random length shown as a shrinking ring and ticks that speed
## up. A shot from the carrier passes the bomb to the ship it hits; anyone
## else's shot just shoves that ship. When the fuse runs out the carrier
## blows up and loses a life, and a fresh bomb goes to a flying ship. Last
## side flying wins.

## The player with the bomb, or -1 between bombs
var carrier: int = -1
var fuse: Timer
## Running while a new carrier can't pass the bomb on yet
var catching: Timer
var until_tick: float = 0.0

func _init():
	name = "HotPotato"

func _ready():
	fuse = Timer.new()
	fuse.one_shot = true
	fuse.timeout.connect(_on_fuse_out)
	add_child(fuse)
	catching = Timer.new()
	catching.one_shot = true
	catching.wait_time = GameConfig.HOT_POTATO_CATCH
	add_child(catching)

func start():
	hand_out_bomb()

func _process(delta):
	if carrier < 0:
		return
	var sights = fuse_mark()
	if sights:
		sights.queue_redraw()
	# Ticks come faster as the fuse burns down
	until_tick -= delta
	if until_tick <= 0.0:
		Sound.play("tick")
		until_tick = clampf(fuse.time_left / 8.0, 0.12, 0.8)

func can_pass() -> bool:
	return catching.is_stopped()

func ship_shot(shooter: int, ship: Node, bullet: Node):
	if shooter == carrier and can_pass():
		give_bomb_to(ship.player_number)
	else:
		ship.apply_central_impulse(bullet.velocity.normalized() * GameConfig.HOT_POTATO_SHOVE)

## A fresh bomb, with a fresh fuse, to a random ship that's flying
func hand_out_bomb():
	if ended or not is_inside_tree():
		return
	var flying = get_tree().get_nodes_in_group("players").filter(func(ship): return not ship.dead)
	if flying.is_empty():
		await get_tree().create_timer(GameConfig.HOT_POTATO_REARM).timeout
		hand_out_bomb()
		return
	fuse.start(randf_range(GameConfig.HOT_POTATO_FUSE_MIN, GameConfig.HOT_POTATO_FUSE_MAX))
	give_bomb_to(flying.pick_random().player_number)

## The bomb, fuse still burning, moves to this player
func give_bomb_to(player: int):
	remove_fuse_mark()
	carrier = player
	until_tick = 0.0
	catching.start()
	var ship = ship_of(player)
	if ship:
		ship.get_node("Ship").add_child(new_fuse_mark())

func _on_fuse_out():
	var ship = ship_of(carrier)
	remove_fuse_mark()
	carrier = -1
	if ship:
		ship.destroy()
	await get_tree().create_timer(GameConfig.HOT_POTATO_REARM).timeout
	hand_out_bomb()

func on_player_eliminated(player: int):
	# Only a leaving pilot can take the bomb with them
	if player == carrier:
		carrier = -1
		fuse.stop()
		hand_out_bomb()
	end_if_last_standing()

## The fuse as a ring round the carrier, burning away clockwise from the top
## and turning red for the last few seconds
func new_fuse_mark() -> Node2D:
	var ring = Node2D.new()
	ring.name = "Fuse"
	ring.draw.connect(func():
		var r = GameConfig.HOT_POTATO_MARK_RADIUS
		var left = fuse.time_left / fuse.wait_time if fuse.wait_time > 0 else 0.0
		var colour = GameConfig.ENV_INKS[0] if fuse.time_left < 3.0 else GameConfig.LIGHT
		# The ship turns, the fuse shouldn't
		var top = -PI / 2 - ring.get_parent().global_rotation
		ring.draw_arc(Vector2.ZERO, r, 0, TAU, 48, Color(GameConfig.CREAM, 0.18), 6, true)
		ring.draw_arc(Vector2.ZERO, r, top, top + TAU * left, 48, colour, 6, true))
	return ring

func fuse_mark() -> Node2D:
	var ship = ship_of(carrier)
	return ship.get_node_or_null("Ship/Fuse") if ship else null

func remove_fuse_mark():
	var ring = fuse_mark()
	if ring:
		ring.get_parent().remove_child(ring)
		ring.queue_free()

func ship_of(player: int) -> Node:
	if player < 0:
		return null
	for ship in get_tree().get_nodes_in_group("players"):
		if ship.player_number == player:
			return ship
	return null
