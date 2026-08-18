extends SceneTree

const Main = preload("res://main.tscn")

var failures: Array[String] = []


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _reset(game: Node) -> void:
	(game.get("upgrade_card_history") as Array).clear()
	game.set("card_play_history", [[], []])
	game.set("upgrade_battle_flags", {"player_cards_played":0, "enemy_cards_played":0})
	var chains: Array = game.get("faction_card_plays")
	chains[0] = 0
	chains[1] = 0
	var hands: Array = game.get("hands")
	hands[0] = []
	hands[1] = []
	var fighters: Array = game.get("fighters")
	fighters[0] = []
	fighters[1] = []
	game.set("game_over", false)
	game.set("trained_this_turn", false)
	game.set("squad_summoned_this_turn", false)
	game.set("stat_cards_played_this_turn", 0)
	game.set("new_fighter_attack", 0)
	game.set("new_fighter_defense", 0)
	var ids: Array = game.get("faction_ids")
	ids[0] = "velari_collective"
	ids[1] = "ironroot_compact"
	var owned: Array = game.get("owned_upgrade_ids")
	owned.clear()
	owned.append("velari_singularity")


func _snapshot_limits(game: Node) -> Array:
	return [
		int((game.get("upgrade_battle_flags") as Dictionary).get("player_cards_played", 0)),
		int((game.get("faction_card_plays") as Array)[0]),
		int(game.get("stat_cards_played_this_turn")),
		bool(game.get("trained_this_turn")),
		bool(game.get("squad_summoned_this_turn")),
		int(game.get("new_fighter_attack")),
		int(game.get("new_fighter_defense")),
	]


func _activate_and_check_invariants(game: Node, label: String) -> void:
	var history_size := (game.get("upgrade_card_history") as Array).size()
	var hand_before: Array = (game.get("hands") as Array)[0].duplicate(true)
	var limits_before := _snapshot_limits(game)
	game.call("_activate_upgrade_capstone", "unlock_replay_last_cards")
	_check((game.get("upgrade_card_history") as Array).size() == history_size, "%s changed replay history size" % label)
	_check((game.get("hands") as Array)[0] == hand_before, "%s consumed or added normal hand cards" % label)
	_check(_snapshot_limits(game) == limits_before, "%s changed play counters or normal action limits" % label)


func _run() -> void:
	var game := Main.instantiate()
	root.add_child(game)
	await process_frame

	# Player-targeted healing must never fall back to a wounded fighter.
	_reset(game)
	var health: Array = game.get("player_health")
	health[0] = 15
	health[1] = 50
	var wounded: Dictionary = game.call("_create_fighter", 0, 2, 10)
	wounded["damage"] = 5
	(game.get("fighters") as Array)[0] = [wounded]
	var heal := {"id":91001, "kind":"heal", "name":"Small Heal", "value":5, "description":"Restore 5 health."}
	game.call("_record_card_play", 0, heal, 5, {"player":0, "healed":5})
	_check(String((game.get("upgrade_card_history") as Array)[0]["target_info"]["target_class"]) == "player", "Player heal history lost its target class")
	_activate_and_check_invariants(game, "Player heal replay")
	_check(health[0] == 20, "Player-targeted Small Heal did not replay onto the player")
	_check(int(wounded["damage"]) == 5, "Player-targeted Small Heal incorrectly healed a fighter")

	# Paired creation slots are one fighter construction, not two arbitrary buffs.
	_reset(game)
	var attack_stat := {"id":91002, "kind":"stat", "name":"4", "value":4, "description":"Attack slot"}
	var defense_stat := {"id":91003, "kind":"stat", "name":"6", "value":6, "description":"Defense slot"}
	var pair_base := {"target_class":"creation_slot", "creation_pair_id":77, "pair_attack":4, "pair_defense":6}
	var attack_info := pair_base.duplicate(true); attack_info["creation_axis"] = "attack"
	var defense_info := pair_base.duplicate(true); defense_info["creation_axis"] = "defense"
	game.call("_record_card_play", 0, attack_stat, 4, attack_info)
	game.call("_record_card_play", 0, defense_stat, 6, defense_info)
	game.set("stat_cards_played_this_turn", 1)
	game.set("trained_this_turn", true)
	_activate_and_check_invariants(game, "Creation-pair replay")
	var created: Array = (game.get("fighters") as Array)[0]
	_check(created.size() == 1 and int(created[0]["attack_base"]) == 4 and int(created[0]["defense_base"]) == 6, "Paired stat replay did not create one equivalent 4/6 fighter")

	# A fighter-targeted stat replay bypasses the normal one-stat cap without changing it.
	_reset(game)
	var target: Dictionary = game.call("_create_fighter", 0, 2, 10)
	(game.get("fighters") as Array)[0] = [target]
	game.call("_record_card_play", 0, {"id":91004, "kind":"stat", "name":"3", "value":3, "description":"Upgrade"}, 3, {"fighter_id":int(target["id"]), "axis":"attack"})
	game.set("stat_cards_played_this_turn", 1)
	_activate_and_check_invariants(game, "Capped stat replay")
	_check(int(target["attack_bonus"]) == 3, "Singularity did not bypass the one-stat cap")

	# A previously valid Squad remains replayable despite all current mutual exclusions.
	_reset(game)
	var squad := {"id":91005, "kind":"summon", "name":"Call in the Squad", "value":3, "description":"Summon the squad."}
	game.call("_record_card_play", 0, squad, 3, {"target_class":"creation_pair", "summoned":3})
	game.set("trained_this_turn", true)
	game.set("squad_summoned_this_turn", true)
	game.set("stat_cards_played_this_turn", 1)
	game.set("new_fighter_attack", 2)
	game.set("new_fighter_defense", 3)
	_activate_and_check_invariants(game, "Squad replay")
	_check((game.get("fighters") as Array)[0].size() == 3, "Squad replay was blocked by current training/squad eligibility flags")

	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("Singularity edge cases passed: authoritative player, fighter, creation-pair, stat-cap, and Squad replay semantics.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _init() -> void:
	call_deferred("_run")
