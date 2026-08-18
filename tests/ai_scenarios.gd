extends SceneTree

const Factions = preload("res://data/faction_data.gd")
const MAIN_SCENE = preload("res://main.tscn")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _fighter(id: int, owner: int, attack: int, defense: int, damage: int = 0) -> Dictionary:
	return {
		"id": id, "owner": owner, "name": "Test %d" % id,
		"attack_base": attack, "defense_base": defense,
		"attack_bonus": 0, "defense_bonus": 0, "damage": damage,
		"weapons": [], "shields": [], "poison": false, "madness": false,
		"evasive": false, "berserker": false, "zen": false, "explosive": false,
	}


func _card(card_id: String) -> Dictionary:
	for card in Factions.all_cards():
		if String(card["id"]) == card_id:
			return card
	return {}


func _run() -> void:
	var game := MAIN_SCENE.instantiate()
	root.add_child(game)
	await process_frame
	game.set("faction_round_flags", [{}, {}])
	game.set("faction_card_plays", [0, 0])
	game.set("player_health", [30, 30])

	# 1. Hostile cards select enemies only, and wounded-only damage waits for a legal target.
	var ally := _fighter(1, 1, 9, 9)
	var healthy_enemy := _fighter(2, 0, 4, 8)
	game.set("fighters", [[healthy_enemy], [ally]])
	var exsanguinate := _card("sanguine_exsanguinate")
	_check((game.call("_ai_best_target_for_faction_card", exsanguinate) as Dictionary).is_empty(), "Exsanguinate targeted a healthy fighter")
	healthy_enemy["damage"] = 2
	var hostile_target: Dictionary = game.call("_ai_best_target_for_faction_card", exsanguinate)
	_check(hostile_target == healthy_enemy and hostile_target != ally, "Enemy-target card selected an ally")

	# 2. Sacrifice selects the weakest expendable ally, but is held when the exchange is bad.
	var cheap := _fighter(3, 1, 1, 1)
	var champion := _fighter(4, 1, 10, 10)
	game.set("fighters", [[], [champion, cheap]])
	var spark := _card("cinder_sacrifice_spark")
	_check(game.call("_ai_weakest_expendable_ally") == cheap, "Sacrifice did not select the weakest ally")
	game.set("fighters", [[], [champion]])
	game.set("hands", [[], [spark]])
	game.set("player_health", [30, 30])
	_check((game.call("_ai_best_faction_play") as Dictionary).is_empty(), "AI sacrificed a fighter for a poor nonlethal exchange")
	game.set("fighters", [[], [champion, cheap]])
	game.set("player_health", [4, 30])
	var lethal_sacrifice: Dictionary = game.call("_ai_best_faction_play")
	_check(not lethal_sacrifice.is_empty() and lethal_sacrifice["target"] == cheap, "AI missed lethal with its expendable sacrifice")

	# 3. Armageddon is held on a losing board and used on a strongly favorable exchange.
	game.set("fighters", [[_fighter(5, 0, 2, 2)], [_fighter(6, 1, 9, 9)]])
	_check(float(game.call("_ai_armageddon_score")) <= 0.0, "Armageddon approved a losing exchange")
	game.set("fighters", [[_fighter(7, 0, 10, 10), _fighter(8, 0, 8, 8)], [_fighter(9, 1, 1, 1)]])
	_check(float(game.call("_ai_armageddon_score")) > 0.0, "Armageddon rejected a favorable exchange")
	var armageddon := {"id":9300, "definition_id":"curse_armageddon", "kind":"curse", "name":"Armageddon", "value":0, "description":"Destroy every fighter."}
	var later_summon := {"id":9301, "definition_id":"summon_call_in_the_squad", "kind":"summon", "name":"Call in the Squad", "value":3, "description":"Summon fighters."}
	game.set("hands", [[], [armageddon, later_summon]])
	game.set("active_player", 1)
	game.set("phase", "TRAIN")
	_check(bool(await game.call("_ai_cast_armageddon_before_creatures")), "AI did not cast a favorable Armageddon before creature creation")
	_check(bool((game.get("pit_panel") as Control).get_meta("armageddon_played_before_creatures", false)), "Armageddon ordering was not recorded before creature play")
	_check((game.get("hands") as Array)[1].size() == 1 and String((game.get("hands") as Array)[1][0]["name"]) == "Call in the Squad", "AI played or discarded a creature before Armageddon")

	# 4. Healing is valued by effective healing, never by printed value alone.
	var repair := _card("ironroot_emergency_repairs")
	var pristine := _fighter(10, 1, 5, 7)
	game.set("fighters", [[], [pristine]])
	_check(float(game.call("_ai_score_faction_card", repair, pristine)) < 0.0, "AI wanted to heal an undamaged fighter")
	pristine["damage"] = 6
	_check(float(game.call("_ai_score_faction_card", repair, pristine)) > 5.0, "AI failed to value effective healing")

	# 5. Global damage and self-damage account for friendly losses and suicide.
	var lava := _card("cinder_lava_surge")
	game.set("fighters", [[_fighter(11, 0, 2, 2)], [_fighter(12, 1, 9, 2), _fighter(13, 1, 8, 2)]])
	_check(float(game.call("_ai_score_faction_card", lava)) < 0.0, "AI approved an unfavorable global-damage exchange")
	var veinripper := _card("sanguine_veinripper")
	var dying_ally := _fighter(14, 1, 6, 3, 2)
	_check(float(game.call("_ai_score_faction_card", veinripper, dying_ally)) < -100.0, "AI approved a self-damage card that kills its target")

	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("AI scenarios passed: targeting, sacrifice/lethal, Armageddon, healing, and dangerous exchanges.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
