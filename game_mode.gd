class_name GameMode
extends Node

## The rules of a round: what happens when ships die and when the round is
## over. Main adds one as a child, tells it what happens in the arena, and
## shows the results when it emits round_over.

## winners is every player credited with the round; empty for a draw
signal round_over(winners: Array[int])

var ended: bool = false

## The countdown has finished and play has begun
func start():
	pass

## killer is the player whose bullet did it, or -1 for nobody
func on_player_killed(_victim: int, _killer: int):
	pass

## A ship has run out of lives and left the arena
func on_player_eliminated(_player: int):
	pass

func end_round(winners: Array[int]):
	if ended:
		return
	ended = true
	round_over.emit(winners)
