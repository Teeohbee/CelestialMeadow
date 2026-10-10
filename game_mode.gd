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

## The countdown has finished and play has begun
func start():
	pass

## killer is the player whose bullet did it, or -1 for nobody
func on_player_killed(_victim: int, _killer: int):
	pass

## A ship has run out of lives and left the arena
func on_player_eliminated(_player: int):
	pass

## Ends the round once at most one ship is left flying
func end_if_last_standing():
	# Leaving the arena because the whole scene is going
	if not is_inside_tree():
		return
	await get_tree().create_timer(GameConfig.END_GAME_CHECK_DELAY).timeout
	# Several players can die at once; only the first check to finish ends
	# the round
	if ended:
		return

	var remaining: Array[int] = []
	for player in get_tree().get_nodes_in_group("players"):
		remaining.append(player.player_number)
	if remaining.size() <= 1:
		end_round(remaining)

func end_round(winners: Array[int]):
	if ended:
		return
	ended = true
	round_over.emit(winners)
