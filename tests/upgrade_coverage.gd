extends SceneTree

const Upgrades = preload("res://data/upgrade_data.gd")
const Main = preload("res://main.tscn")

var failures: Array[String] = []


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := Main.instantiate()
	root.add_child(game)
	await process_frame

	var declared := {}
	for upgrade in Upgrades.all_upgrades():
		declared[String(upgrade["effect"])] = true
	var registered := {}
	for effect in game.supported_upgrade_effects():
		registered[String(effect)] = true
	var unsupported: Array[String] = []
	var undeclared: Array[String] = []
	for effect in declared:
		if not registered.has(effect): unsupported.append(effect)
	for effect in registered:
		if not declared.has(effect): undeclared.append(effect)
	unsupported.sort()
	undeclared.sort()
	_check(unsupported.is_empty(), "Unregistered upgrade effects: %s" % ", ".join(unsupported))
	_check(undeclared.is_empty(), "Registered effects absent from data: %s" % ", ".join(undeclared))
	_check(declared.size() == 28, "Expected 28 unique upgrade effects, found %d" % declared.size())

	# Every one of the 30 nodes must activate the runtime lookup contract.
	for upgrade in Upgrades.all_upgrades():
		var one_owned: Array = game.get("owned_upgrade_ids")
		one_owned.clear()
		one_owned.append(String(upgrade["id"]))
		_check(bool(game.call("_has_upgrade_effect", String(upgrade["effect"]))), "Upgrade node %s did not activate its effect" % upgrade["id"])
		_check(int(game.call("_upgrade_total", String(upgrade["effect"]))) == int(upgrade.get("value", 1)), "Upgrade node %s returned the wrong magnitude" % upgrade["id"])

	var faction_ids: Array = game.get("faction_ids")
	faction_ids[0] = "tidebound_conclave"
	faction_ids[1] = "cinder_coven"
	var owned: Array = game.get("owned_upgrade_ids")
	owned.clear()
	owned.append_array(["tidebound_regrowth", "tidebound_shared_current"])
	game.set("upgrade_battle_flags", {})
	var first: Dictionary = game.call("_create_fighter", 0, 2, 10)
	var second: Dictionary = game.call("_create_fighter", 0, 2, 10)
	first["damage"] = 4
	second["damage"] = 6
	var all_fighters: Array = game.get("fighters")
	all_fighters[0] = [first, second]
	all_fighters[1] = []
	game.call("_heal_fighter_with_upgrades", 0, first, 10)
	_check(int(first["defense_bonus"]) == 6, "Overheal was not converted to defense")
	_check(int(second["damage"]) == 4, "Shared Current did not chain half the effective healing")

	faction_ids[0] = "ironroot_compact"
	faction_ids[1] = "cinder_coven"
	owned.clear()
	owned.append_array(["ironroot_redundant_core", "ironroot_eternal_engine"])
	game.set("upgrade_battle_flags", {})
	var doomed: Dictionary = game.call("_create_fighter", 0, 3, 2)
	doomed["faction_summon"] = true
	doomed["damage"] = 2
	all_fighters[0] = [doomed]
	all_fighters[1] = []
	game.call("_remove_dead_fighters", false)
	var player_fighters: Array = (game.get("fighters") as Array)[0]
	_check(player_fighters.size() == 1 and String(player_fighters[0]["name"]) == "Scrapling", "Redundant Core did not rebirth the first summon")
	if not player_fighters.is_empty():
		var defense_before := int(player_fighters[0]["defense_bonus"])
		game.call("_apply_round_end_passive", 0)
		_check(int(player_fighters[0]["defense_bonus"]) == defense_before + 1, "Eternal Engine did not grant round-end defense")

	faction_ids[0] = "sanguine_court"
	faction_ids[1] = "cinder_coven"
	owned.clear()
	owned.append("sanguine_eternal_night")
	game.set("upgrade_battle_flags", {})
	var health: Array = game.get("player_health")
	health[0] = 4
	health[1] = 50
	all_fighters[0] = [game.call("_create_fighter", 0, 3, 3)]
	all_fighters[1] = []
	game.call("_damage_player", 0, 10, 1)
	_check(int((game.get("player_health") as Array)[0]) == 15, "Eternal Night did not replace lethal damage with 15 health")
	_check(bool((game.get("upgrade_battle_flags") as Dictionary).get("unlock_player_rebirth_used", false)), "Eternal Night use was not battle-scoped")

	faction_ids[0] = "cinder_coven"
	faction_ids[1] = "ironroot_compact"
	owned.clear()
	owned.append("cinder_worldforge")
	game.set("upgrade_battle_flags", {})
	game.set("game_over", false)
	all_fighters[0] = []
	all_fighters[1] = []
	game.call("_activate_upgrade_capstone", "unlock_worldforge")
	_check((game.get("fighters") as Array)[0].size() == 3, "Worldforge did not create three upgraded golems")
	_check(bool((game.get("upgrade_battle_flags") as Dictionary).get("unlock_worldforge_used", false)), "Worldforge was not marked spent")

	print("Upgrade coverage: %d nodes, %d declared effects, %d unsupported." % [Upgrades.all_upgrades().size(), declared.size(), unsupported.size()])
	game.queue_free()
	await process_frame
	if failures.is_empty():
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
