extends RoundSuite
# Bullets belong to the round, so a rematch clears shots in flight, and when sudden death knocks a pilot out
# their shots go with them.

func speed() -> float:
	return 4.0

func bullets() -> Array[Node]:
	return get_tree().get_nodes_in_group("bullets")

func owners() -> Array:
	return bullets().map(func(bullet): return bullet.player_number)

func time_attack() -> Node:
	return await new_round([0, 1, 2], [], 1)

func test_bullets_belong_to_the_round() -> void:
	await time_attack()
	ship(1).shoot()
	await frames(1)
	assert_int(bullets().size()).is_equal(1)
	assert_object(bullets()[0].get_parent()).is_same(scene())

func test_a_rematch_clears_shots_in_flight() -> void:
	await time_attack()
	ship(1).shoot()
	await frames(1)
	get_tree().reload_current_scene()
	await get_tree().scene_changed
	await frames(1)
	assert_array(bullets()).is_empty()

# Pilots 0 and 1 tie on a kill each, so sudden death knocks pilot 2 out. Pilots 2 and 0 get a shot away first,
# held still mid-arena so nothing else can take them.
func shots_into_sudden_death() -> void:
	var round := await time_attack()
	ship(2).destroy(0)
	ship(0).destroy(1)
	await respawned(2)
	await respawned(0)
	await calm()
	ship(2).shoot()
	ship(0).shoot()
	await frames(1)
	for bullet in bullets():
		bullet.velocity = Vector2.ZERO
		bullet.position = Vector2(960, 300)
	assert_array(owners()).contains_exactly_in_any_order([0, 2])
	round.mode.clock.start(0.05)
	await wait_until(func(): return round.mode.sudden_death)
	await frames(1)

func test_a_knocked_out_pilots_shots_vanish() -> void:
	await shots_into_sudden_death()
	assert_array(owners()).not_contains([2])

func test_contenders_shots_stay() -> void:
	await shots_into_sudden_death()
	assert_array(owners()).contains([0])
