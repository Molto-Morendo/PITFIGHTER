extends SceneTree

const Main = preload("res://main.tscn")
const Factions = preload("res://data/faction_data.gd")

var failures: Array[String] = []


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _set_ids(game: Node, player_id: String, enemy_id: String) -> void:
	var ids: Array = game.get("faction_ids")
	ids[0] = player_id
	ids[1] = enemy_id


func _faction_card(effect: String, runtime_id: int) -> Dictionary:
	for definition in Factions.cards_for_faction("cinder_coven"):
		if String(definition["effect"]) == effect and (effect != "summon_fighter" or String(definition["name"]) == "Rock Golem"):
			var card: Dictionary = definition.duplicate(true)
			card["definition_id"] = card["id"]
			card["id"] = runtime_id
			return card
	return {}


func _run() -> void:
	# Deeper Scan must gate the first turn behind exactly one explicit discard.
	var scan_game := Main.instantiate()
	root.add_child(scan_game)
	await process_frame
	_set_ids(scan_game, "velari_collective", "ironroot_compact")
	(scan_game.get("owned_upgrade_ids") as Array).append("velari_deeper_scan")
	scan_game.call("_start_new_game")
	await process_frame
	var opening_hand: Array = (scan_game.get("hands") as Array)[0]
	_check(bool(scan_game.get("opening_discard_pending")), "Deeper Scan did not gate the opening turn")
	_check((scan_game.get("opening_discard_layer") as Control).visible, "Deeper Scan discard overlay was not visible")
	_check(opening_hand.size() == 8, "Deeper Scan did not offer exactly one extra opening card")
	_check(not bool(scan_game.get("has_drawn")), "Turn play advanced before the mandatory discard")
	var discarded_id := int(opening_hand[0]["id"])
	_check(bool(scan_game.call("_resolve_opening_discard", 0, 0)), "Deeper Scan rejected a valid discard selection")
	_check(not bool(scan_game.get("opening_discard_pending")), "Deeper Scan remained gated after one discard")
	_check(opening_hand.size() == 7, "Deeper Scan did not discard exactly one card")
	_check(not opening_hand.any(func(card: Dictionary) -> bool: return int(card["id"]) == discarded_id), "Selected opening card was not discarded")
	scan_game.queue_free()
	await process_frame

	# Singularity replays the exact mixed last-three sequence using real handlers.
	var game := Main.instantiate()
	root.add_child(game)
	await process_frame
	_set_ids(game, "cinder_coven", "ironroot_compact")
	(game.get("owned_upgrade_ids") as Array).append("velari_singularity")
	game.set("upgrade_battle_flags", {"player_cards_played": 0, "enemy_cards_played": 0})
	(game.get("upgrade_card_history") as Array).clear()
	game.set("card_play_history", [[], []])
	game.set("game_over", false)
	var ally: Dictionary = game.call("_create_fighter", 0, 2, 20)
	var enemy_a: Dictionary = game.call("_create_fighter", 1, 2, 20)
	var enemy_b: Dictionary = game.call("_create_fighter", 1, 2, 20)
	var all_fighters: Array = game.get("fighters")
	all_fighters[0] = [ally]
	all_fighters[1] = [enemy_a, enemy_b]
	var sword := {"id":81001, "kind":"weapon", "name":"Sword", "value":2, "description":"+2 attack"}
	var summon := _faction_card("summon_fighter", 81002)
	var area := _faction_card("damage_all_fighters", 81003)
	var player_hand: Array = (game.get("hands") as Array)[0]
	player_hand.clear()
	player_hand.append(sword)
	game.call("_play_support_card", 0, 0, ally, false)
	player_hand.append(summon)
	_check(bool(game.call("_play_faction_card", 0, 0)), "Original summon did not resolve")
	player_hand.append(area)
	_check(bool(game.call("_play_faction_card", 0, 0)), "Original area damage did not resolve")
	var history: Array = game.get("upgrade_card_history")
	_check(history.size() == 3, "Mixed shared/faction history did not contain exactly three resolved cards")
	_check(not history[0].has("faction_id") and history[1].has("faction_id") and history[2].has("faction_id"), "Singularity history excluded or reordered mixed card origins")
	_check(int(history[0]["resolved_value"]) == 2 and int(history[0]["target_info"]["fighter_id"]) == int(ally["id"]), "Targeted buff history lost resolved value or target identity")
	var history_size_before := history.size()
	var play_count_before := int((game.get("upgrade_battle_flags") as Dictionary)["player_cards_played"])
	var ally_attack_before := int(ally["attack_bonus"])
	game.call("_activate_upgrade_capstone", "unlock_replay_last_cards")
	_check(int(ally["attack_bonus"]) == ally_attack_before + 2, "Singularity targeted buff was not equivalent to the original +2 (actual delta %d)" % (int(ally["attack_bonus"]) - ally_attack_before))
	_check((game.get("fighters") as Array)[0].size() == 3, "Singularity did not replay the summon exactly once (actual %d)" % (game.get("fighters") as Array)[0].size())
	_check(int(enemy_a["damage"]) == 4 and int(enemy_b["damage"]) == 4, "Singularity area damage was not equivalent on all enemies")
	_check((game.get("upgrade_battle_flags") as Dictionary).get("singularity_replay_order", []) == ["Sword", "Rock Golem", "Lava Surge"], "Singularity did not replay in original order")
	_check(history.size() == history_size_before and int((game.get("upgrade_battle_flags") as Dictionary)["player_cards_played"]) == play_count_before, "Singularity recursively recorded or retriggered replayed cards")
	var fallback: Dictionary = game.call("_create_fighter", 0, 1, 20)
	all_fighters[0] = [fallback]
	game.set("replaying_upgrade_cards", true)
	_check(bool(game.call("_replay_history_entry", history[0])), "Singularity could not resolve a missing-target fallback")
	game.set("replaying_upgrade_cards", false)
	_check(int(fallback["attack_bonus"]) == 2, "Singularity did not retarget a missing original ally safely")

	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("Exact upgrade semantics passed: Deeper Scan discard gate and ordered mixed Arena Singularity replay.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _init() -> void:
	call_deferred("_run")
