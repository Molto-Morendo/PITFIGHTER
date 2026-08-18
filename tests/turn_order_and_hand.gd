extends SceneTree

const MAIN_SCENE := preload("res://main.tscn")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _card(kind: String, value: int, name: String) -> Dictionary:
	return {"id":name.hash(), "definition_id":name, "kind":kind, "name":name, "value":value, "description":"test"}


func _run() -> void:
	var game := MAIN_SCENE.instantiate()
	root.add_child(game)
	await process_frame
	_check(String(game.get("game_speed_mode")) == "fast" and is_equal_approx(Engine.time_scale, 1.0), "Fast was not the default game speed")
	game.call("_set_game_speed", "medium")
	_check(is_equal_approx(Engine.time_scale, 1.0 / 1.75), "Medium speed did not make timing 1.75 times as long")
	game.call("_set_game_speed", "slow")
	_check(is_equal_approx(Engine.time_scale, 0.4), "Slow speed did not make timing 2.5 times as long")
	game.call("_set_game_speed", "fast")
	_check((game.get("settings_button") as Button).position.x < (game.get("restart_button") as Button).position.x, "Settings button was not placed left of New Match")
	game.call("_show_settings")
	_check((game.get("settings_layer") as Control).visible and paused, "Settings did not open as a pausing overlay")
	_check(is_instance_valid(game.get("pit_fight_volume_slider")) and is_equal_approx(float((game.get("pit_fight_volume_slider") as HSlider).value), 50.0), "Settings are missing the default 50% pit-fight volume control")
	_check(is_instance_valid(game.get("other_audio_volume_slider")) and is_equal_approx(float((game.get("other_audio_volume_slider") as HSlider).value), 100.0), "Settings are missing the other-audio volume control")
	game.call("_set_pit_fight_volume", 40.0)
	game.call("_set_other_audio_volume", 50.0)
	_check(is_equal_approx((game.get("pit_background_player") as AudioStreamPlayer).volume_db, linear_to_db(0.4)), "Pit-fight volume setting did not update its player")
	_check(is_equal_approx((game.get("sfx_players") as Array)[0].volume_db, -4.0 + linear_to_db(0.5)), "Other-audio volume setting did not update sound effects")
	game.call("_set_pit_fight_volume", 75.0)
	game.call("_set_other_audio_volume", 100.0)
	game.call("_hide_settings")
	_check(not paused, "Closing Settings did not resume the game")
	game.call("_request_new_match_confirmation")
	_check((game.get("new_match_confirmation_layer") as Control).visible and paused, "New Match did not open a pausing confirmation screen")
	game.call("_cancel_new_match_confirmation")
	_check(not (game.get("new_match_confirmation_layer") as Control).visible and not paused, "Cancel did not return from New Match confirmation to the current game")
	(game.get("rng") as RandomNumberGenerator).seed = 24680
	game.call("_select_faction", "cinder_coven")
	game.call("_begin_selected_faction_run")
	await process_frame
	_check(bool(game.get("first_player_roll_active")), "Encounter did not begin with the first-player spinner")
	var spinner := (game.get("design_surface") as Control).find_child("FirstPlayerSpinner", true, false) as Control
	_check(is_instance_valid(spinner), "First-player spinner was not visible")
	if is_instance_valid(spinner):
		_check(is_equal_approx(float(spinner.get_meta("fast_spin_duration", 0.0)), 0.75), "First-player spinner did not use the requested 0.75-second fast phase")
		_check(spinner.position.distance_to(Vector2(615, 255)) < 2.0, "First-player spinner was not centered on screen")
		var side_labels: Array[String] = []
		for side_label in spinner.find_children("*", "Label", true, false):
			side_labels.append(String((side_label as Label).text))
		_check("HUMAN" in side_labels and "COMPUTER" in side_labels, "Spinner halves were not labeled Human and Computer")
		var spinner_status := (game.get("design_surface") as Control).find_child("FirstPlayerSpinnerStatus", true, false) as Control
		_check(is_instance_valid(spinner_status) and spinner_status.z_index > spinner.z_index, "Spinner result text was not layered in front of the wheel")
		_check((game.get("toast_panel") as Control).z_index > spinner.z_index and (game.get("action_flash_panel") as Control).z_index > spinner.z_index, "Text popups were not layered in front of the wheel")
	var waited := 0.0
	while bool(game.get("first_player_roll_active")) and waited < 10.0:
		await create_timer(0.05).timeout
		waited += 0.05
	_check(not bool(game.get("first_player_roll_active")), "First-player spinner did not finish")
	_check(bool(game.get("round_banner_active")), "Round 1 banner did not appear after the opening roll")
	var round_labels := (game.get("design_surface") as Control).find_children("RoundBanner", "Label", true, false)
	_check(not round_labels.is_empty() and String((round_labels[0] as Label).text) == "ROUND 1", "Round banner did not show the current round number")
	var banner_skip := InputEventMouseButton.new()
	banner_skip.button_index = MOUSE_BUTTON_LEFT
	banner_skip.pressed = true
	game.call("_input", banner_skip)
	await create_timer(0.10).timeout
	_check(not bool(game.get("round_banner_active")), "Clicking did not skip the round banner delay")
	var opener := int(game.get("encounter_first_player"))
	_check(opener in [0, 1] and int(game.get("active_player")) == opener, "Spinner winner did not receive the first turn")
	_check(bool(game.get("opening_attack_skip_pending")) and int(game.get("opening_attack_skip_owner")) == opener, "Spinner winner was not marked to skip its first attack phase")
	_check(bool(game.call("_consume_opening_attack_skip", opener)), "Opening attack skip was not consumed for the spinner winner")
	_check(not bool(game.call("_consume_opening_attack_skip", opener)), "Opening attack skip could be consumed more than once")

	# Normal draws and draw effects share a four-card cap for the turn.
	var decks: Array = game.get("decks")
	var hands: Array = game.get("hands")
	hands[0].clear()
	decks[0] = []
	for value in range(1, 7):
		decks[0].append(_card("stat", value, "draw%d" % value))
	(game.get("cards_drawn_this_turn") as Array)[0] = 0
	for draw_attempt in 6:
		game.call("_draw_card", 0, false)
	_check(hands[0].size() == 4 and int((game.get("cards_drawn_this_turn") as Array)[0]) == 4, "Turn draw limit did not stop the fifth card")

	# End-of-draw sorting reverses type order, then uses descending value.
	hands[0] = [_card("curse", 5, "curse5"), _card("stat", 8, "stat8"), _card("weapon", 4, "weapon4"), _card("stat", 2, "stat2"), _card("curse", 1, "curse1")]
	game.call("_sort_hand_by_type_and_value", 0)
	var sorted_names: Array[String] = []
	for card in hands[0]:
		sorted_names.append(String(card["name"]))
	_check(sorted_names == ["curse5", "curse1", "weapon4", "stat8", "stat2"], "Hand was not reverse-sorted by type and descending value")
	hands[0] = [_card("stat", 2, "stat2"), _card("curse", 5, "curse5"), _card("stat", 8, "stat8")]
	game.call("_refresh_hand")
	_check(String(hands[0][0]["name"]) == "curse5" and String(hands[0][1]["name"]) == "stat8", "Hand was briefly rendered before being sorted")

	# Phase three defaults every ready player fighter into the pit, allows holding
	# individual fighters back, and automatically includes every defender.
	game.set("match_serial", int(game.get("match_serial")) + 1)
	game.set("active_player", 0)
	game.set("phase", "TRAIN")
	game.set("input_locked", false)
	game.set("opening_attack_skip_pending", false)
	var sides: Array = game.get("fighters")
	var player_a: Dictionary = game.call("_create_fighter", 0, 3, 4)
	var player_b: Dictionary = game.call("_create_fighter", 0, 4, 5)
	var enemy_a: Dictionary = game.call("_create_fighter", 1, 2, 4)
	var enemy_b: Dictionary = game.call("_create_fighter", 1, 5, 5)
	sides[0] = [player_a, player_b]
	sides[1] = [enemy_a, enemy_b]
	game.call("_enter_player_attack_phase")
	var selected: Array = game.get("selected_attacker_ids")
	_check(selected.has(int(player_a["id"])) and selected.has(int(player_b["id"])), "Phase three did not place every player fighter in the pit by default")
	game.set("input_locked", false)
	game.call("_on_fighter_pressed", 0, int(player_a["id"]))
	_check(not selected.has(int(player_a["id"])) and selected.has(int(player_b["id"])), "Clicking a pit fighter did not hold it back")
	var pending: Array = game.get("pending_attack_ids")
	pending.clear(); pending.append(int(player_b["id"]))
	game.set("phase", "CLASH")
	game.set("block_assignments", {})
	_check(bool(game.call("_fighter_in_pit", 1, int(enemy_a["id"]))) and bool(game.call("_fighter_in_pit", 1, int(enemy_b["id"]))), "Defenders did not enter combat automatically")
	_check(not (game.get("block_overlay") as Control).visible, "Legacy blocker assignment lines are still visible")

	# A pit with attackers but no possible defenders stages in the middle rather
	# than moving to a rail before its survivor rolls hit the player.
	sides[1] = []
	game.set("phase", "ATTACK")
	game.set("active_player", 0)
	selected.clear(); selected.append(int(player_a["id"])); selected.append(int(player_b["id"]))
	game.call("_refresh_all")
	await process_frame
	var centered_groups := (game.get("pit_fighters_box") as Control).find_children("HumanPitTeam", "HBoxContainer", true, false)
	_check(not centered_groups.is_empty() and (centered_groups[0] as HBoxContainer).alignment == BoxContainer.ALIGNMENT_CENTER, "Unopposed attackers were staged at the pit edge instead of the middle")

	# Heal-phase eligibility respects each card's legal target class.
	var player_only_heal := {"kind":"heal", "faction_id":"test", "target":"ally_player", "effect":"heal", "value":5}
	var fighter_only_heal := {"kind":"heal", "faction_id":"test", "target":"ally_fighter", "effect":"heal", "value":5}
	player_a["damage"] = 2
	(game.get("player_health") as Array)[0] = int(game.call("_maximum_player_health", 0))
	hands[0] = [player_only_heal]
	_check(not bool(game.call("_has_playable_heal_card", 0)), "Player-only heal incorrectly opened for a wounded fighter")
	hands[0] = [fighter_only_heal]
	_check(bool(game.call("_has_playable_heal_card", 0)), "Fighter heal did not recognize a wounded fighter")
	player_a["damage"] = 0
	(game.get("player_health") as Array)[0] -= 1
	_check(not bool(game.call("_has_playable_heal_card", 0)), "Fighter-only heal incorrectly opened for player damage")
	hands[0] = [player_only_heal]
	_check(bool(game.call("_has_playable_heal_card", 0)), "Player heal did not recognize a wounded player")

	game.queue_free()
	await process_frame
	Engine.time_scale = 1.0
	if failures.is_empty():
		print("Turn order/hand passed: faster opener, skippable round banner, four-card draw cap, sorting, and pit defaults.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
