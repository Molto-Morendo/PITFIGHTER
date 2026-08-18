extends SceneTree

const ArtifactData := preload("res://data/artifact_data.gd")
const MAIN_SCENE := preload("res://main.tscn")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _training_card(id: int) -> Dictionary:
	return {"id":id, "definition_id":"training_shield_master", "kind":"training", "name":"Shield Master", "value":1, "description":"Training test."}


func _run() -> void:
	_check(ArtifactData.validate_content().is_empty(), "Artifact content validation failed: %s" % [ArtifactData.validate_content()])
	_check(ArtifactData.all_artifacts().size() == 20, "Expected exactly 20 artifacts")
	var game := MAIN_SCENE.instantiate()
	root.add_child(game)
	await process_frame
	var declared_effects: Array[String] = []
	for artifact in ArtifactData.all_artifacts():
		declared_effects.append(String(artifact["effect"]))
	declared_effects.sort()
	var supported_effects: Array = game.call("supported_artifact_effects")
	supported_effects.sort()
	_check(declared_effects == supported_effects, "Artifact effect registry does not exactly cover all 20 effects")
	game.call("_select_faction", "cinder_coven")
	game.call("_begin_selected_faction_run")
	await process_frame
	game.set("match_serial", int(game.get("match_serial")) + 1)

	# One fighter creation is legal; later attempts are rejected before consuming cards.
	game.set("phase", "TRAIN")
	game.set("active_player", 0)
	game.set("input_locked", false)
	var next_test_id := 9000
	for attempt in 3:
		var hands: Array = game.get("hands")
		hands[0].append({"id":next_test_id, "definition_id":"stat_2", "kind":"stat", "name":"2", "value":2, "description":"test"})
		hands[0].append({"id":next_test_id + 1, "definition_id":"stat_3", "kind":"stat", "name":"3", "value":3, "description":"test"})
		next_test_id += 2
		var last: int = hands[0].size() - 1
		var selected: Array = game.get("selected_hand_indices")
		selected.clear()
		selected.append(last - 1)
		selected.append(last)
		game.call("_try_train_selected")
	_check(int((game.get("fighters_trained_this_turn") as Array)[0]) == 1, "Player fighter training was not capped at one")
	_check((game.get("fighters") as Array)[0].size() == 1, "A second fighter was incorrectly trained")

	# Stat training on an existing fighter has its own one-card cap; creation-pair
	# stat cards do not consume this allowance.
	var target: Dictionary = (game.get("fighters") as Array)[0][0]
	var hands: Array = game.get("hands")
	hands[0] = [
		{"id":9050, "definition_id":"stat_2", "kind":"stat", "name":"2", "value":2, "description":"test"},
		{"id":9051, "definition_id":"stat_3", "kind":"stat", "name":"3", "value":3, "description":"test"},
	]
	var first_stat_play: bool = game.call("_apply_stat_upgrade", 0, 0, target, "attack", false)
	var second_stat_play: bool = game.call("_apply_stat_upgrade", 0, 0, target, "attack", false)
	_check(first_stat_play and not second_stat_play and int(game.get("stat_cards_played_this_turn")) == 1, "Existing-fighter stat training was not capped at one card")
	_check(hands[0].size() == 1, "The rejected second stat-training card was consumed")

	# Training attachments use an independent two-card cap.
	hands[0] = [_training_card(9100), _training_card(9101), _training_card(9102)]
	game.call("_play_support_card", 0, 0, target, false)
	game.call("_play_support_card", 0, 0, target, false)
	game.call("_play_support_card", 0, 0, target, false)
	_check(int((game.get("training_cards_played_this_turn") as Array)[0]) == 2, "Training-card applications were not capped at two")
	_check((game.get("hands") as Array)[0].size() == 1, "Third training card was consumed despite the cap")
	target["poison"] = true
	target["madness"] = true
	var detailed_tooltip: String = game.call("_fighter_tooltip", target)
	_check("Poison —" in detailed_tooltip and "Madness —" in detailed_tooltip and "Base:" in detailed_tooltip, "Fighter tooltip did not enumerate curses and stat sources")
	game.call("_log_event", "A fighter attacks a blocker with poison and trample.", 0, false)
	var formatted_log: String = game.call("_format_fight_log")
	_check("url=term:attack" in formatted_log and "url=term:blocker" in formatted_log and "url=term:poison" in formatted_log, "Fight log did not attach game-term hover metadata")

	# Repeatable status cards accumulate independent stacks on the same fighter.
	var stack_target: Dictionary = game.call("_create_fighter", 1, 3, 20)
	(game.get("fighters") as Array)[1].append(stack_target)
	hands[0] = [
		{"id":9200, "definition_id":"curse_poison", "kind":"curse", "name":"Poison", "value":2, "description":"test"},
		{"id":9201, "definition_id":"curse_poison", "kind":"curse", "name":"Poison", "value":2, "description":"test"},
		{"id":9202, "definition_id":"curse_madness", "kind":"curse", "name":"Madness", "value":25, "description":"test"},
		{"id":9203, "definition_id":"curse_madness", "kind":"curse", "name":"Madness", "value":25, "description":"test"},
	]
	game.call("_play_curse_card", 0, 0, stack_target, false, false)
	game.call("_play_curse_card", 0, 0, stack_target, false, false)
	game.call("_play_curse_card", 0, 0, stack_target, false, false)
	game.call("_play_curse_card", 0, 0, stack_target, false, false)
	_check(int(stack_target.get("poison_stacks", 0)) == 2 and int(stack_target.get("madness_stacks", 0)) == 2, "Repeated Poison and Madness cards did not stack")
	game.call("_apply_upkeep", 1)
	_check(int(stack_target["damage"]) == 4, "Two Poison stacks did not deal four upkeep damage")

	# Representative always-active artifact effects run through authoritative stats/damage.
	var owned_artifacts: Array = game.get("owned_artifact_ids")
	owned_artifacts.clear()
	owned_artifacts.append_array(["warlords_tooth", "iron_idol", "guardian_coin"])
	var plain: Dictionary = game.call("_create_fighter", 0, 3, 4)
	_check(int(game.call("_fighter_attack", plain)) == 4, "Warlord's Tooth did not add team attack")
	_check(int(game.call("_fighter_max_defense", plain)) == 6, "Iron Idol did not add team defense")
	var health: Array = game.get("player_health")
	health[0] = 20
	game.call("_damage_player", 0, 3, 1)
	_check(health[0] == 18, "Guardian Coin did not prevent exactly one damage")

	# Closest targeting uses current screen positions, not assignment order.
	owned_artifacts.clear()
	var faction_ids: Array = game.get("faction_ids")
	faction_ids[0] = "ironroot_compact"
	faction_ids[1] = "ironroot_compact"
	var position_source: Dictionary = game.call("_create_fighter", 0, 1, 2)
	var position_far: Dictionary = game.call("_create_fighter", 1, 1, 2)
	var position_near: Dictionary = game.call("_create_fighter", 1, 1, 2)
	var source_visual := Control.new()
	var far_visual := Control.new()
	var near_visual := Control.new()
	for visual in [source_visual, far_visual, near_visual]:
		visual.size = Vector2(20, 20)
		game.add_child(visual)
	source_visual.position = Vector2(0, 0)
	far_visual.position = Vector2(200, 0)
	near_visual.position = Vector2(40, 0)
	var fighter_nodes: Dictionary = game.get("fighter_button_nodes")
	fighter_nodes[int(position_source["id"])] = source_visual
	fighter_nodes[int(position_far["id"])] = far_visual
	fighter_nodes[int(position_near["id"])] = near_visual
	var closest: Dictionary = game.call("_closest_pit_enemy", position_source, [position_far, position_near])
	_check(int(closest["id"]) == int(position_near["id"]), "Pit scuffle did not target the physically closest enemy")
	for fighter in [position_source, position_far, position_near]:
		fighter_nodes.erase(int(fighter["id"]))
	for visual in [source_visual, far_visual, near_visual]:
		visual.queue_free()

	# All d1 strikes land simultaneously, and every surviving fighter gets one d1
	# finishing roll against the opposing player.
	var attacker_a: Dictionary = game.call("_create_fighter", 0, 1, 2)
	var attacker_b: Dictionary = game.call("_create_fighter", 0, 1, 2)
	var blocker: Dictionary = game.call("_create_fighter", 1, 1, 1)
	var fighter_sides: Array = game.get("fighters")
	fighter_sides[0] = [attacker_a, attacker_b]
	fighter_sides[1] = [blocker]
	health[0] = 50
	health[1] = 50
	game.set("phase", "CLASH")
	game.set("active_player", 0)
	var attack_ids: Array[int] = [int(attacker_a["id"]), int(attacker_b["id"])]
	var assignments := {int(attacker_a["id"]): [int(blocker["id"])], int(attacker_b["id"]): []}
	game.set("pending_attack_ids", attack_ids.duplicate())
	game.set("block_assignments", assignments.duplicate(true))
	game.call("_refresh_all")
	await process_frame
	await game.call("_resolve_combat", 0, attack_ids, assignments)
	_check(is_equal_approx(float((game.get("pit_panel") as Control).get_meta("damage_observation_delay", 0.0)), 1.0), "Pit damage grid did not retain the completed round for one second")
	_check(int(attacker_a.get("damage", 0)) == 1, "A defeated blocker did not land its simultaneous scuffle strike")
	_check((game.get("fighters") as Array)[1].is_empty(), "Scuffle damage did not remove the defeated blocker")
	_check(health[1] == 48, "Both surviving fighters did not deal one final rolled damage to the opposing player")

	# If the simultaneous beat destroys both sides, neither player takes a final hit.
	var doomed_attacker: Dictionary = game.call("_create_fighter", 0, 1, 1)
	var doomed_blocker: Dictionary = game.call("_create_fighter", 1, 1, 1)
	fighter_sides[0] = [doomed_attacker]
	fighter_sides[1] = [doomed_blocker]
	health[0] = 50
	health[1] = 50
	attack_ids = [int(doomed_attacker["id"])]
	assignments = {int(doomed_attacker["id"]): [int(doomed_blocker["id"])]}
	game.set("pending_attack_ids", attack_ids.duplicate())
	game.set("block_assignments", assignments.duplicate(true))
	game.call("_refresh_all")
	await process_frame
	await game.call("_resolve_combat", 0, attack_ids, assignments)
	_check(fighter_sides[0].is_empty() and fighter_sides[1].is_empty(), "Mutual lethal scuffle did not remove both fighters")
	_check(health[0] == 50 and health[1] == 50, "An all-dead scuffle incorrectly dealt final player damage")

	# With no defenders, the attacker begins centered and immediately rolls its
	# damage against the opposing player.
	var unopposed_attacker: Dictionary = game.call("_create_fighter", 0, 1, 4)
	fighter_sides[0] = [unopposed_attacker]
	fighter_sides[1] = []
	health[0] = 50
	health[1] = 50
	attack_ids = [int(unopposed_attacker["id"])]
	assignments = {}
	game.set("pending_attack_ids", attack_ids.duplicate())
	game.set("block_assignments", {})
	game.call("_refresh_all")
	await process_frame
	var unopposed_groups := (game.get("pit_fighters_box") as Control).find_children("HumanPitTeam", "HBoxContainer", true, false)
	_check(not unopposed_groups.is_empty() and (unopposed_groups[0] as HBoxContainer).alignment == BoxContainer.ALIGNMENT_CENTER, "Unopposed combatants did not remain centered during resolution")
	await game.call("_resolve_combat", 0, attack_ids, assignments)
	_check(health[1] == 49, "Unopposed pit fighter did not assign its damage directly to the opposing player")

	# A scuffle stops after one damage beat per current game round. If both sides
	# remain, nobody makes a finishing roll against a player.
	var durable_attacker: Dictionary = game.call("_create_fighter", 0, 1, 10)
	var durable_blocker: Dictionary = game.call("_create_fighter", 1, 1, 10)
	fighter_sides[0] = [durable_attacker]
	fighter_sides[1] = [durable_blocker]
	health[0] = 50
	health[1] = 50
	game.set("round_number", 2)
	attack_ids = [int(durable_attacker["id"])]
	assignments = {int(durable_attacker["id"]): [int(durable_blocker["id"])]}
	game.set("pending_attack_ids", attack_ids.duplicate())
	game.set("block_assignments", assignments.duplicate(true))
	game.call("_refresh_all")
	await process_frame
	await game.call("_resolve_combat", 0, attack_ids, assignments)
	_check(int(durable_attacker["damage"]) == 2 and int(durable_blocker["damage"]) == 2, "Round 2 scuffle did not stop after exactly two damage rounds")
	_check(health[0] == 50 and health[1] == 50, "A capped unresolved scuffle incorrectly dealt finishing damage")

	# A finishing strike that truly kills a player uses a half-speed lunge,
	# slows FIGHTBG to half speed, and uses a half-speed attack effect.
	var lethal_attacker: Dictionary = game.call("_create_fighter", 1, 1, 4)
	fighter_sides[0] = []
	fighter_sides[1] = [lethal_attacker]
	health[0] = 1
	health[1] = 50
	attack_ids = [int(lethal_attacker["id"])]
	assignments = {}
	game.set("round_number", 1)
	game.set("active_player", 1)
	game.set("pending_attack_ids", attack_ids.duplicate())
	game.set("block_assignments", {})
	game.call("_refresh_all")
	await process_frame
	var lethal_visual: Control = (game.get("fighter_button_nodes") as Dictionary)[int(lethal_attacker["id"])]
	await game.call("_resolve_combat", 1, attack_ids, assignments)
	_check(health[0] == 0, "Lethal finishing strike did not kill the human player")
	_check(bool(lethal_visual.get_meta("lethal_player_attack", false)), "Killing player strike was not identified as lethal")
	_check(is_equal_approx(float(lethal_visual.get_meta("lethal_animation_speed", 0.0)), 0.5), "Lethal player strike did not use 50% animation speed")
	_check(is_equal_approx(float(lethal_visual.get_meta("lethal_attack_pitch", 0.0)), 0.5), "Lethal player strike sound did not use half playback rate/pitch")
	_check(is_equal_approx(float((game.get("combat_animator") as Node).get("animation_speed")), 1.0), "Combat animation speed was not restored after the lethal strike")
	var normal_sound: AudioStreamPlayer = game.call("_play_random_sound", "attacking")
	_check(is_instance_valid(normal_sound) and is_equal_approx(normal_sound.pitch_scale, 1.0), "A pooled audio player retained the lethal half-speed pitch")

	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("Artifact/limits/combat passed: one fighter, one stat training, four draws, and round-capped simultaneous scuffles.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
