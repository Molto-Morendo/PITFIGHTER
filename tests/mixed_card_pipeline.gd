extends SceneTree

const MAIN_SCENE = preload("res://main.tscn")
const Factions = preload("res://data/faction_data.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _shared(kind: String, name: String, value: int) -> Dictionary:
	return {"id": name.hash(), "kind": kind, "name": name, "value": value, "description": "pipeline test"}


func _set_factions(game: Node, player_id: String, enemy_id: String) -> void:
	var ids: Array = game.get("faction_ids")
	ids[0] = player_id
	ids[1] = enemy_id


func _reset_pipeline(game: Node) -> void:
	var round_flags: Array = game.get("faction_round_flags")
	round_flags[0] = {}
	round_flags[1] = {}
	var chain_counts: Array = game.get("faction_card_plays")
	chain_counts[0] = 0
	chain_counts[1] = 0
	game.set("upgrade_battle_flags", {"player_cards_played": 0, "enemy_cards_played": 0})
	(game.get("upgrade_card_history") as Array).clear()
	game.set("card_play_history", [[], []])
	game.set("hands", [[], []])
	game.set("decks", [[], []])
	var health: Array = game.get("player_health")
	health[0] = 50
	health[1] = 50
	game.set("game_over", false)
	(game.get("owned_upgrade_ids") as Array).clear()


func _spend(game: Node, owner: int, card: Dictionary) -> int:
	var value := int(game.call("_consume_effective_card_value", owner, card))
	game.call("_record_card_play", owner, card, value, {"test": true})
	return value


func _run() -> void:
	var game := MAIN_SCENE.instantiate()
	root.add_child(game)
	await process_frame

	# Gathering Storm must count mixed shared cards, not just faction definitions.
	_reset_pipeline(game)
	_set_factions(game, "tempest_clans", "ironroot_compact")
	_spend(game, 0, _shared("weapon", "Sword", 2))
	_spend(game, 0, _shared("stat", "4", 4))
	_spend(game, 0, _shared("heal", "Small Heal", 5))
	_check(int((game.get("player_health") as Array)[1]) == 49, "Gathering Storm did not trigger on three mixed shared cards")
	_check(int((game.get("faction_card_plays") as Array)[0]) == 3, "Mixed cards did not advance the round chain exactly three")

	# Predictive Lattice must be primed by a shared non-stat and consumed by the next shared stat.
	_reset_pipeline(game)
	_set_factions(game, "velari_collective", "ironroot_compact")
	_spend(game, 0, _shared("weapon", "Sword", 2))
	var boosted_stat := int(game.call("_consume_effective_card_value", 0, _shared("stat", "3", 3)))
	_check(boosted_stat == 4, "Velari shared weapon did not prime the next shared stat")
	game.call("_record_card_play", 0, _shared("stat", "3", 3), boosted_stat)
	_check(int((game.get("faction_round_flags") as Array)[0].get("stat_bonus", 0)) == 0, "Predictive Lattice stat bonus was not consumed")

	# Zero Hour must boost exactly the next three cards even when kinds are mixed.
	_reset_pipeline(game)
	_set_factions(game, "velari_collective", "ironroot_compact")
	var zero_hour: Dictionary = {}
	for card in Factions.cards_for_faction("velari_collective"):
		if String(card["effect"]) == "boost_next_cards":
			zero_hour = card.duplicate(true)
			break
	zero_hour["definition_id"] = zero_hour["id"]
	zero_hour["id"] = 70001
	(game.get("hands") as Array)[0] = [zero_hour]
	_check(bool(game.call("_play_faction_card", 0, 0)), "Zero Hour could not be spent through the faction path")
	var boosted_values := [
		_spend(game, 0, _shared("weapon", "Sword", 2)),
		_spend(game, 0, _shared("stat", "4", 4)),
		_spend(game, 0, _shared("heal", "Small Heal", 5)),
		_spend(game, 0, _shared("shield", "Small Shield", 4)),
	]
	_check(boosted_values == [3, 6, 6, 4], "Zero Hour mixed consumption was not exactly three cards (including Velari's separate +1 stat prime): %s" % str(boosted_values))

	# Static Charge counts the first mixed card twice; Jetstream draws at six actual plays.
	_reset_pipeline(game)
	_set_factions(game, "tempest_clans", "ironroot_compact")
	(game.get("owned_upgrade_ids") as Array).append_array(["tempest_static_charge", "tempest_jetstream"])
	(game.get("decks") as Array)[0] = [_shared("stat", "Jetstream Draw", 1)]
	for index in 6:
		_spend(game, 0, _shared("weapon" if index % 2 == 0 else "stat", "Mixed %d" % index, 2))
	_check(int((game.get("faction_card_plays") as Array)[0]) == 7, "Static Charge did not double only the first mixed card: %s" % str((game.get("faction_card_plays") as Array)[0]))
	_check(int((game.get("upgrade_battle_flags") as Dictionary).get("player_cards_played", 0)) == 6, "Jetstream actual-play counter was distorted by chain counts")
	_check((game.get("hands") as Array)[0].size() == 1, "Jetstream did not draw on the sixth mixed card")

	# Stolen Pattern watches the enemy's third actual play, irrespective of card origin.
	_reset_pipeline(game)
	_set_factions(game, "velari_collective", "tempest_clans")
	(game.get("owned_upgrade_ids") as Array).append("velari_stolen_pattern")
	_spend(game, 1, _shared("stat", "Enemy Stat", 2))
	_spend(game, 1, _shared("weapon", "Enemy Weapon", 3))
	_spend(game, 1, _shared("heal", "Enemy Third Heal", 5))
	var copied_hand: Array = (game.get("hands") as Array)[0]
	_check(copied_hand.size() == 1 and String(copied_hand[0].get("name", "")) == "Enemy Third Heal" and bool(copied_hand[0].get("temporary_copy", false)), "Stolen Pattern did not copy the third mixed enemy card")
	_check((game.get("card_play_history") as Array)[1].size() == 3, "Generic enemy card history did not record exact mixed plays")

	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("Mixed card pipeline passed: Tempest, Velari, Zero Hour, Static Charge, Jetstream, and Stolen Pattern use exact shared history.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
