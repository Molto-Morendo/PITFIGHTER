extends SceneTree

const Factions = preload("res://data/faction_data.gd")
const Upgrades = preload("res://data/upgrade_data.gd")
const MAIN_SCENE = preload("res://main.tscn")
const TIMEOUT_SECONDS := 15.0

var failures: Array[String] = []
var finished := false


func _init() -> void:
	call_deferred("_run")
	call_deferred("_timeout_watchdog")


func _timeout_watchdog() -> void:
	await create_timer(TIMEOUT_SECONDS).timeout
	if not finished:
		push_error("Expansion smoke test exceeded %.1f seconds" % TIMEOUT_SECONDS)
		quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _faction_card_count(game: Node, owner: int, faction_id: String) -> int:
	var count := 0
	var decks: Array = game.get("decks")
	var hands: Array = game.get("hands")
	for card in decks[owner]:
		if String(card.get("faction_id", "")) == faction_id:
			count += 1
	for card in hands[owner]:
		if String(card.get("faction_id", "")) == faction_id:
			count += 1
	return count


func _run() -> void:
	var game := MAIN_SCENE.instantiate()
	root.add_child(game)
	await process_frame

	var faction_layer: Control = game.get("faction_layer")
	var faction_begin_button: Button = game.get("faction_begin_button")
	_check(is_instance_valid(faction_layer), "Faction selection layer was not created on ready")
	_check(is_instance_valid(faction_begin_button), "Faction selection begin button was not created on ready")
	_check(Factions.all_factions().size() == 6, "Faction selection does not expose exactly six factions")

	for faction in Factions.all_factions():
		var faction_id := String(faction["id"])
		game.call("_select_faction", faction_id)
		game.call("_begin_selected_faction_run")
		await process_frame

		var chosen_ids: Array = game.get("faction_ids")
		var enemy_id := String(chosen_ids[1])
		_check(String(chosen_ids[0]) == faction_id, "%s was not assigned to the player" % faction_id)
		_check(enemy_id != faction_id, "%s was also assigned to the AI" % faction_id)
		_check(not Factions.faction_by_id(enemy_id).is_empty(), "%s received invalid AI faction %s" % [faction_id, enemy_id])
		_check(_faction_card_count(game, 0, faction_id) == 10, "%s player deck/hand did not contain exactly 10 chosen-faction cards" % faction_id)
		_check(_faction_card_count(game, 1, enemy_id) == 10, "%s AI deck/hand did not contain exactly 10 rival-faction cards" % faction_id)

	# Force a normal player victory through the same game-over gate combat uses.
	game.set("encounter_enemy_fighters_killed", 5)
	var health: Array = game.get("player_health")
	health[1] = 0
	game.call("_check_game_over")
	await process_frame
	var artifact_choice_layer: Control = game.get("artifact_choice_layer")
	var offered_artifacts: Array = game.get("pending_artifact_choices")
	_check(is_instance_valid(artifact_choice_layer) and artifact_choice_layer.visible, "Victory did not open the three-artifact choice overlay")
	_check(offered_artifacts.size() == 3, "Victory did not offer exactly three artifacts")
	_check((game.get("owned_artifact_ids") as Array).is_empty(), "An artifact was assigned before the player chose one")
	if not offered_artifacts.is_empty():
		game.call("_select_artifact_reward", String(offered_artifacts[0]["id"]))
	await process_frame
	var artifact_popup: Control = game.get("artifact_popup")
	var artifact_bar_panel: Control = game.get("artifact_bar_panel")
	_check(is_instance_valid(artifact_popup) and artifact_popup.visible, "Artifact acquisition popup was not shown after choosing a reward")
	_check(artifact_popup.position.distance_to(Vector2(480, 305)) < 2.0, "Artifact acquisition popup was not centered on screen")
	_check(is_instance_valid(artifact_bar_panel) and artifact_bar_panel.visible, "Artifact strip did not appear in the upper-left after victory")
	game.call("_dismiss_artifact_popup")
	await create_timer(0.15).timeout
	await process_frame

	var upgrade_layer: Control = game.get("upgrade_layer")
	_check(bool(game.get("game_over")), "Forced victory did not end the encounter")
	_check((game.get("owned_artifact_ids") as Array).size() == 1, "Victory did not drop a persistent artifact")
	_check(is_instance_valid(upgrade_layer) and upgrade_layer.visible, "Victory did not open the upgrade overlay")
	_check(String(game.get("last_one_shot")) == "LEVELUP.mp3", "Completing the encounter did not play the level-up one-shot")

	var player_faction_id := String((game.get("faction_ids") as Array)[0])
	var available := Upgrades.available_upgrades(player_faction_id, game.get("owned_upgrade_ids"))
	var affordable: Dictionary = {}
	for upgrade in available:
		if int(upgrade["cost"]) <= int(game.get("upgrade_points")):
			affordable = upgrade
			break
	_check(not affordable.is_empty(), "Victory offered no affordable upgrade")
	if not affordable.is_empty():
		var upgrade_id := String(affordable["id"])
		game.call("_purchase_upgrade", upgrade_id)
		await process_frame
		var owned_before: Array = (game.get("owned_upgrade_ids") as Array).duplicate()
		_check(upgrade_id in owned_before, "Affordable upgrade %s was not purchased" % upgrade_id)
		var previous_encounter := int(game.get("encounter_number"))
		game.call("_start_next_encounter")
		await process_frame
		_check(int(game.get("encounter_number")) == previous_encounter + 1, "Starting the next fight did not increment the encounter")
		_check(upgrade_id in (game.get("owned_upgrade_ids") as Array), "Purchased upgrade %s did not persist into the next encounter" % upgrade_id)
		_check(not bool(game.get("game_over")), "Next encounter did not enter a playable state")

	# The next encounter must not erase kills that have not yet been banked.
	game.set("encounter_enemy_fighters_killed", 4)
	game.call("_start_new_game")
	_check(int(game.get("encounter_enemy_fighters_killed")) == 4, "Starting the next encounter erased the run's unbanked fighter kills")
	game.call("_begin_selected_faction_run")
	_check(int(game.get("encounter_enemy_fighters_killed")) == 0 and int(game.get("upgrade_points")) == 0, "Starting a new faction run did not reset fighter-kill progression")

	game.queue_free()
	await process_frame
	finished = true
	if failures.is_empty():
		print("Expansion smoke passed: six faction runs, 10 cards each, rival factions, victory upgrade, encounter persistence.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
