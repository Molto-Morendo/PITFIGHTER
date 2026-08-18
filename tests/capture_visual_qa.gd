extends SceneTree

const MAIN_SCENE := preload("res://main.tscn")
const FactionData := preload("res://data/faction_data.gd")
const ArtifactData := preload("res://data/artifact_data.gd")


func _init() -> void:
	call_deferred("_run")


func _save_viewport(game: Node, file_name: String) -> void:
	var image := game.get_viewport().get_texture().get_image()
	image.resize(1440, 800, Image.INTERPOLATE_LANCZOS)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://qa"))
	var error := image.save_png("res://qa/%s" % file_name)
	if error != OK:
		push_error("Could not save QA screenshot %s: %s" % [file_name, error_string(error)])


func _run() -> void:
	var game := MAIN_SCENE.instantiate()
	root.add_child(game)
	await process_frame
	game.call("_show_game_rules")
	await process_frame
	_save_viewport(game, "game_rules.png")
	game.call("_hide_game_rules")
	game.call("_select_faction", "cinder_coven")
	game.call("_begin_selected_faction_run")
	game.set("match_serial", int(game.get("match_serial")) + 1)
	game.get("splash_layer").visible = false
	game.get("faction_layer").visible = false
	game.set("input_locked", false)
	game.set("phase", "TRAIN")
	game.get("toast_panel").modulate.a = 0.0
	var hand: Array = (game.get("hands") as Array)[0]
	hand.clear()
	for definition in FactionData.cards_for_faction("cinder_coven").slice(0, 4):
		var card: Dictionary = definition.duplicate(true)
		card["definition_id"] = card["id"]
		card["id"] = 8000 + hand.size()
		hand.append(card)
	for definition in FactionData.cards_for_faction("tidebound_conclave"):
		if String(definition["id"]) == "tidebound_riptide":
			var card: Dictionary = definition.duplicate(true)
			card["definition_id"] = card["id"]
			card["id"] = 8050
			hand.append(card)
			break
	hand.append({"id":8090, "definition_id":"curse_deathmark", "kind":"curse", "name":"Deathmark", "value":0, "description":"Destroy target fighter."})
	hand.append({"id":8100, "definition_id":"stat_7", "kind":"stat", "name":"7", "value":7, "description":"Train: use as attack or defense."})
	hand.append({"id":8101, "definition_id":"weapon_sword", "kind":"weapon", "name":"Sword", "value":2, "description":"+2 attack"})
	game.call("_refresh_all")
	await create_timer(0.4).timeout
	_save_viewport(game, "cards_and_log.png")
	var display_hand: Array = hand.duplicate(true)
	(game.get("hands") as Array)[0] = [{"id":8200, "definition_id":"stat_7", "kind":"stat", "name":"7", "value":7, "description":"Train: use as attack or defense."}]
	var selected_stat: Array = game.get("selected_hand_indices")
	selected_stat.clear()
	selected_stat.append(0)
	game.call("_on_new_fighter_slot_pressed", "attack")
	await create_timer(0.7).timeout
	_save_viewport(game, "cancel_pending_fighter.png")
	game.call("_cancel_pending_new_fighter")
	(game.get("hands") as Array)[0] = display_hand

	var fighter_sides: Array = game.get("fighters")
	fighter_sides[0].clear()
	for stats in [[5, 7], [3, 9], [8, 4]]:
		fighter_sides[0].append(game.call("_create_fighter", 0, stats[0], stats[1]))
	game.set("phase", "ATTACK")
	var selected: Array = game.get("selected_attacker_ids")
	selected.clear()
	selected.append(int(fighter_sides[0][0]["id"]))
	selected.append(int(fighter_sides[0][1]["id"]))
	game.call("_refresh_all")
	await create_timer(0.5).timeout
	_save_viewport(game, "expanded_pit.png")
	game.get("toast_panel").modulate.a = 0.0
	for stats in [[6, 6], [4, 8]]:
		fighter_sides[1].append(game.call("_create_fighter", 1, stats[0], stats[1]))
	game.set("phase", "CLASH")
	game.set("pending_attack_ids", selected.duplicate())
	game.set("block_assignments", {int(selected[0]): [int(fighter_sides[1][0]["id"])], int(selected[1]): [int(fighter_sides[1][1]["id"])]})
	game.call("_refresh_all")
	await create_timer(0.35).timeout
	_save_viewport(game, "pit_edge_staging.png")
	await game.call("_animate_pit_charge_to_center")
	_save_viewport(game, "pit_center_clash.png")
	var owned_artifacts: Array = game.get("owned_artifact_ids")
	owned_artifacts.append("warlords_tooth")
	game.call("_refresh_artifact_bar")
	game.call("_show_artifact_popup", ArtifactData.artifact_by_id("warlords_tooth"))
	await create_timer(0.2).timeout
	_save_viewport(game, "artifact_reward.png")
	game.call("_dismiss_artifact_popup")
	game.set("encounter_enemy_fighters_killed", 5)
	game.call("_open_upgrade_tree")
	await create_timer(0.2).timeout
	_save_viewport(game, "skill_tree.png")
	game.get("upgrade_layer").visible = false
	game.get("defeat_layer").visible = true
	game.get("defeat_layer").move_to_front()
	await process_frame
	_save_viewport(game, "you_lose.png")
	game.queue_free()
	await process_frame
	print("Visual QA captures saved, including game rules, skill tree, and You Lose screens.")
	quit(0)
