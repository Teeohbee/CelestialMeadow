extends "res://time_attack.gd"

## Time Attack with a price on the leader: whoever alone has the most kills
## is Wanted, marked on their ship and their HUD corner, and shooting them
## scores the bounty instead of one. A tie for the lead means nobody is.

## The Wanted player, or -1 for nobody
var wanted: int = -1

func _init():
	name = "Wanted"

func kill_target() -> int:
	return 0

func score_unit() -> String:
	return "point"

func points_for(victim: int) -> int:
	return GameConfig.WANTED_BOUNTY if victim == wanted else 1

func on_player_killed(victim: int, killer: int):
	super(victim, killer)
	if not sudden_death:
		set_wanted(leader())

## The one player with the most kills, or -1 if nobody has any or it's a tie
func leader() -> int:
	var best = scores.values().max()
	if best == null or best == 0 or scores.values().count(best) > 1:
		return -1
	return scores.find_key(best)

func set_wanted(player: int):
	if player == wanted:
		return
	var old = ship_of(wanted)
	if old and old.has_node("Ship/WantedMark"):
		var sights = old.get_node("Ship/WantedMark")
		sights.get_parent().remove_child(sights)
		sights.queue_free()
	wanted = player
	var ship = ship_of(player)
	if ship:
		ship.get_node("Ship").add_child(mark())
	hud.set_wanted(player)

## The bounty's sights, drawn over the ship: a ring with four ticks
func mark() -> Node2D:
	var sights = Node2D.new()
	sights.name = "WantedMark"
	sights.draw.connect(func():
		var r = GameConfig.WANTED_MARK_RADIUS
		sights.draw_arc(Vector2.ZERO, r, 0, TAU, 48, GameConfig.LIGHT, 3, true)
		for i in 4:
			var out = Vector2.RIGHT.rotated(i * TAU / 4 + TAU / 8)
			sights.draw_line(out * (r - 10), out * (r + 10), GameConfig.LIGHT, 4, true))
	return sights

func ship_of(player: int) -> Node:
	if player < 0:
		return null
	for ship in get_tree().get_nodes_in_group("players"):
		if ship.player_number == player:
			return ship
	return null

func start_sudden_death(leaders: Array[int]):
	set_wanted(-1)
	super(leaders)
