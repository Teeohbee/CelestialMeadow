class_name GameMode
extends Node

## The rules of a round: what happens when ships die and when the round is
## over. Main adds one as a child, tells it what happens in the arena, and
## shows the results when it emits round_over.

## winners is every player credited with the round; empty for a draw
signal round_over(winners: Array[int])

var ended: bool = false
## Set by Main before the mode joins the scene
var hud: CanvasLayer

## Lives each ship starts with, or GameConfig.UNLIMITED_LIVES
func starting_lives() -> int:
	return GameState.lives_per_player

## Each player's score this round, for the results; empty if the mode
## doesn't keep score
func round_scores() -> Dictionary:
	return {}

## The countdown has finished and play has begun
func start():
	pass

## killer is the player whose bullet did it, or -1 for nobody
func on_player_killed(_victim: int, _killer: int):
	pass

## A ship has run out of lives and left the arena
func on_player_eliminated(_player: int):
	pass

## Ends the round once ships from at most one side are left flying. The
## whole side wins, including members already shot down.
func end_if_last_standing():
	# Leaving the arena because the whole scene is going
	if not is_inside_tree():
		return
	await get_tree().create_timer(GameConfig.END_GAME_CHECK_DELAY).timeout
	# Several players can die at once; only the first check to finish ends
	# the round
	if ended:
		return

	var sides = {}
	for player in get_tree().get_nodes_in_group("players"):
		sides[GameState.side_of(player.player_number)] = true
	if sides.is_empty():
		end_round([])
	elif sides.size() == 1:
		end_round(GameState.members_of(sides.keys()[0]))

func end_round(winners: Array[int]):
	if ended:
		return
	ended = true
	round_over.emit(winners)
