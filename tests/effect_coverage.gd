extends SceneTree

const Factions = preload("res://data/faction_data.gd")
const MAIN_SCENE = preload("res://main.tscn")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _card(effect: String) -> Dictionary:
	for card in Factions.all_cards():
		if String(card["effect"]) == effect:
			var runtime: Dictionary = card.duplicate(true)
			runtime["definition_id"] = runtime["id"]
			runtime["id"] = 9000 + effect.hash()
			return runtime
	return {}


func _play(game: Node, owner: int, card: Dictionary, target: Dictionary = {}) -> bool:
	var hands: Array = game.get("hands")
	hands[owner] = [card]
	return bool(game.call("_play_faction_card", owner, 0, target))


func _fighter(game: Node, owner: int, attack := 3, defense := 6) -> Dictionary:
	return game.call("_create_fighter", owner, attack, defense)


func _run() -> void:
	var game := MAIN_SCENE.instantiate()
	root.add_child(game)
	await process_frame
	var faction_ids: Array = game.get("faction_ids")
	faction_ids[0] = "cinder_coven"
	faction_ids[1] = "ironroot_compact"
	game.set("hands", [[], []])
	game.set("decks", [[], []])
	game.set("fighters", [[], []])
	game.set("player_health", [40, 40])
	game.set("faction_round_flags", [{}, {}])
	game.set("faction_card_plays", [0, 0])
	game.set("game_over", false)

	var supported: Array = game.call("supported_faction_effects")
	var declared := {}
	for card in Factions.all_cards():
		declared[String(card["effect"])] = true
	var unsupported: Array[String] = []
	for effect in declared:
		if effect not in supported:
			unsupported.append(effect)
	_check(unsupported.is_empty(), "Unsupported declared faction effects: %s" % ", ".join(unsupported))
	_check(supported.size() == declared.size(), "Registry has %d effects but content declares %d" % [supported.size(), declared.size()])

	# Cinder Coven: lifesteal damages an enemy and heals its owner by damage dealt.
	var cinder_target := _fighter(game, 1)
	(game.get("fighters") as Array)[1] = [cinder_target]
	var cinder_hp := int((game.get("player_health") as Array)[0])
	_check(_play(game, 0, _card("damage_and_lifesteal"), cinder_target), "Cinder lifesteal card did not resolve")
	_check(int(cinder_target["damage"]) == 3 and int((game.get("player_health") as Array)[0]) == cinder_hp + 3, "Cinder lifesteal did not deal and heal 3")

	# Ironroot: Jammed Gears is a round-scoped attack penalty and Overwind stores recoil.
	var iron_target := _fighter(game, 1, 5, 6)
	_check(_play(game, 0, _card("temporary_reduce_attack"), iron_target), "Jammed Gears did not resolve")
	_check(int(iron_target["attack_bonus"]) == -2 and int(iron_target["temporary_attack"]) == -2, "Jammed Gears did not register a temporary -2")
	var iron_ally := _fighter(game, 0)
	_check(_play(game, 0, _card("temporary_attack_with_recoil"), iron_ally), "Overwind did not resolve")
	_check(int(iron_ally["recoil_damage"]) == 1 and int(iron_ally["temporary_attack"]) == 2, "Overwind did not store its recoil/temporary power")

	# Velari: Probability Collapse creates a deterministic best legal faction card.
	faction_ids[0] = "velari_collective"
	faction_ids[1] = "ironroot_compact"
	_check(_play(game, 0, _card("discover_faction_card")), "Probability Collapse did not resolve")
	var discovered_hand: Array = (game.get("hands") as Array)[0]
	_check(discovered_hand.size() == 1 and String(discovered_hand[0].get("faction_id", "")) == "velari_collective", "Probability Collapse did not create a usable Velari card: %s" % str(discovered_hand))

	# Mimetic Titan copies a visible stat; Evasive prevents curses, not observation.
	var evasive_enemy := _fighter(game, 1, 8, 7)
	evasive_enemy["evasive"] = true
	(game.get("fighters") as Array)[1] = [evasive_enemy]
	var mimetic := _card("summon_copy_enemy_stat")
	(game.get("hands") as Array)[0] = [mimetic]
	game.set("active_player", 0)
	game.set("phase", "TRAIN")
	_check(String(game.call("_card_unavailable_reason", mimetic)).is_empty(), "Mimetic Titan rejected an Evasive enemy stat source")
	(game.get("selected_hand_indices") as Array).clear()
	(game.get("selected_hand_indices") as Array).append(0)
	_check(bool(game.call("_is_valid_selected_card_target", 1, evasive_enemy)), "Mimetic Titan could not select an Evasive enemy stat source")
	_check(_play(game, 0, mimetic, evasive_enemy), "Mimetic Titan did not resolve against an Evasive enemy stat source")
	var mimetic_result: Dictionary = (game.get("fighters") as Array)[0].back()
	_check(int(mimetic_result["attack_base"]) == 8, "Mimetic Titan did not copy the stronger attack stat")

	# Sanguine: Deathless Oath consumes itself and leaves exactly one defense.
	var vampire := _fighter(game, 0, 4, 5)
	_check(_play(game, 0, _card("survive_lethal_once"), vampire), "Deathless Oath did not resolve")
	game.call("_apply_damage_to_fighter", vampire, 99, "test")
	_check(not bool(vampire["deathless_once"]) and int(vampire["damage"]) == 4, "Deathless Oath did not stop lethal at one defense")

	# Tidebound: Pearl Aegis prevents exactly three points, retaining unused prevention.
	var guardian := _fighter(game, 0, 2, 6)
	_check(_play(game, 0, _card("prevent_next_damage"), guardian), "Pearl Aegis did not resolve")
	game.call("_apply_damage_to_fighter", guardian, 2, "test")
	_check(int(guardian["damage"]) == 0 and int(guardian["damage_prevention"]) == 1, "Pearl Aegis prevention was not consumed correctly")

	# Tempest: Zero Hour boosts exactly three card values and Cloudstrider counts twice.
	faction_ids[0] = "tempest_clans"
	faction_ids[1] = "ironroot_compact"
	_check(_play(game, 0, _card("boost_next_cards")), "Zero Hour did not resolve")
	var flags: Array = game.get("faction_round_flags")
	_check(int(flags[0].get("boost_cards_remaining", 0)) == 3, "Zero Hour did not arm three boosted cards")
	var before_chain := int((game.get("faction_card_plays") as Array)[0])
	_check(_play(game, 0, _card("summon_double_chain_count")), "Cloudstrider did not resolve")
	_check(int((game.get("faction_card_plays") as Array)[0]) == before_chain + 2, "Cloudstrider did not count as two card plays")

	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("Faction effect coverage passed: %d declared, 0 unsupported; six faction behavior suites passed." % declared.size())
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
