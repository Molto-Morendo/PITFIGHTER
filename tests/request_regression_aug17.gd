extends SceneTree

const MAIN_SCENE := preload("res://main.tscn")
const FactionData := preload("res://data/faction_data.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _faction_card(card_id: String) -> Dictionary:
	for card in FactionData.all_cards():
		if String(card["id"]) == card_id:
			var runtime: Dictionary = card.duplicate(true)
			runtime["definition_id"] = card_id
			runtime["id"] = 9001
			return runtime
	return {}


func _run() -> void:
	var game := MAIN_SCENE.instantiate()
	root.add_child(game)
	await process_frame

	var blood_tithe := _faction_card("sanguine_blood_tithe")
	_check(not bool(game.call("_faction_card_requires_fighter_target", blood_tithe)), "Blood Tithe still requires a fighter target")
	for card in FactionData.all_cards():
		var should_require := String(card.get("target", "none")) in ["ally_fighter", "enemy_fighter", "any_fighter"]
		_check(bool(game.call("_faction_card_requires_fighter_target", card)) == should_require, "%s has inconsistent faction targeting" % card["name"])
	var hands: Array = game.get("hands")
	var decks: Array = game.get("decks")
	hands[0] = [blood_tithe]
	decks[0] = [{"id":9002, "definition_id":"test_draw", "kind":"stat", "name":"Test Draw", "value":1, "description":"test"}]
	game.set("player_health", [20, 20])
	game.set("active_player", 0)
	game.set("phase", "TRAIN")
	(game.get("selected_hand_indices") as Array).append(0)
	game.call("_on_action_pressed")
	_check((game.get("hands") as Array)[0].size() == 1, "Blood Tithe did not play and draw without selecting a target")
	_check((game.get("player_health") as Array)[0] == 17 and (game.get("player_health") as Array)[1] == 17, "Blood Tithe did not damage both players")

	var surface := game.get("design_surface") as Control
	var forbidden_status_labels := surface.find_children("*", "Label", true, false).filter(func(node: Label) -> bool: return node.text in ["YOUR STABLE", "OPPONENT"])
	_check(forbidden_status_labels.is_empty(), "Removed stable/opponent health-panel text is still present")

	var factions: Array = game.get("faction_ids")
	factions[0] = "cinder_coven"
	game.set("upgrade_points", 8)
	game.call("_refresh_upgrade_tree")
	var upgrade_header := game.get("upgrade_points_label") as RichTextLabel
	_check("[color=#ff9f43][font_size=23]" in upgrade_header.text, "Skill-tree header fighter kills are not orange and four points larger")
	var cost_labels := (game.get("upgrade_nodes_box") as Control).find_children("UpgradeFighterKillCost", "Label", true, false)
	_check(not cost_labels.is_empty(), "Skill-tree cards do not have dedicated fighter-kill values")
	for label in cost_labels:
		_check((label as Label).get_theme_font_size("font_size") == 17, "A card fighter-kill value is not four points larger")
		_check((label as Label).get_theme_color("font_color").is_equal_approx(Color("#ff9f43")), "A card fighter-kill value is not orange")

	var revealed_weapon := {"id":9010, "definition_id":"test_weapon", "kind":"weapon", "name":"Test Weapon", "value":1, "description":"test"}
	game.call("_show_opponent_card_reveal", revealed_weapon)
	var queued_heal := {"id":9011, "definition_id":"test_heal", "kind":"heal", "name":"Queued Heal", "value":2, "description":"test"}
	game.call("_show_opponent_card_reveal", queued_heal)
	await process_frame
	var active_reveals := surface.find_children("*", "Button", true, false).filter(func(item: Control) -> bool: return item.has_meta("reveal_slot"))
	_check(active_reveals.size() == 2, "Simultaneous computer cards did not receive separate reveal slots")
	active_reveals.sort_custom(func(a: Control, b: Control) -> bool: return int(a.get_meta("reveal_slot", -1)) < int(b.get_meta("reveal_slot", -1)))
	var reveal := active_reveals[0] as Control if not active_reveals.is_empty() else null
	var second_reveal := active_reveals[1] as Control if active_reveals.size() > 1 else null
	_check(is_instance_valid(reveal), "Opponent non-stat card was not revealed")
	if is_instance_valid(reveal):
		_check(is_equal_approx(float(reveal.get_meta("reveal_duration", 0.0)), 1.5), "Opponent non-stat reveal did not hold for 1.5 seconds")
		_check(is_equal_approx(float(reveal.get_meta("gameplay_pause_duration", 0.0)), 0.3), "Opponent non-stat reveal blocked gameplay for longer than 0.3 seconds")
		_check(int(reveal.get_meta("reveal_slot", -1)) == 0 and is_instance_valid(second_reveal) and int(second_reveal.get_meta("reveal_slot", -1)) == 1, "Computer reveal slots were not allocated in order")
		_check(is_instance_valid(second_reveal) and reveal.position.x > second_reveal.position.x and is_equal_approx(reveal.position.y, second_reveal.position.y), "Computer reveal slots were not placed right-to-left without shifting")
	await create_timer(1.52).timeout
	_check(not is_instance_valid(reveal), "Opponent non-stat reveal remained after its hold")

	var log_label := game.get("log_label") as RichTextLabel
	_check(log_label.selection_enabled and log_label.context_menu_enabled and log_label.shortcut_keys_enabled, "Fight log does not allow native selection and clipboard copying")
	game.call("_log_event", "This Computer equips Test Weapon.", 1, false)
	game.call("_record_card_play", 1, revealed_weapon, 1, {"test":true})
	var formatted_log: String = game.call("_format_fight_log")
	_check("[url=card:" in formatted_log and "Test Weapon" in formatted_log, "Logged card name was not converted to a card-preview link")
	game.call("_log_event", "You add [color=#57c7ff]+7 defense[/color] to a fighter.", 0, false)
	formatted_log = game.call("_format_fight_log")
	_check("[color" not in formatted_log and "[/color]" not in formatted_log and "/color]" not in formatted_log, "Fight log exposed visual BBCode fragments")
	game.call("_render_fight_log")
	_check(int(log_label.get_meta("chat_style_human_count", 0)) > 0, "Human fight-log messages lost their chat-bubble styling")
	_check(int(log_label.get_meta("chat_style_computer_count", 0)) > 0, "Computer fight-log messages lost their chat-bubble styling")
	_check(Color(log_label.get_meta("chat_style_human_color", Color.WHITE)) != Color(log_label.get_meta("chat_style_computer_color", Color.WHITE)), "Human and computer fight-log messages use the same color")
	var linked_training: String = game.call("_glossary_wrap", "[url=card:test][u]Eye of the Storm Training[/u][/url]")
	_check("term:training" not in linked_training, "Glossary metadata was nested inside a card tooltip link")
	var card_lookup: Dictionary = game.get("log_card_lookup")
	_check(not card_lookup.is_empty(), "Fight log did not retain card data for its preview")
	if not card_lookup.is_empty():
		var tooltip_key := String(card_lookup.keys()[0])
		game.call("_on_log_meta_hover_started", "card:%s" % tooltip_key)
		var card_tooltip := surface.find_child("FightLogCardTooltip", true, false) as Control
		_check(is_instance_valid(card_tooltip) and card_tooltip.size == Vector2(280, 412), "Logged card hover did not show the full-size card")
		game.call("_on_log_meta_hover_ended", "card:%s" % tooltip_key)

	var trigger_fighter: Dictionary = game.call("_create_fighter", 0, 4, 8)
	(game.get("fighters") as Array)[0].append(trigger_fighter)
	game.call("_refresh_all")
	await process_frame
	game.call("_queue_fighter_status_trigger", trigger_fighter, "FIRST TRIGGER", Color.ORANGE)
	game.call("_queue_fighter_status_trigger", trigger_fighter, "SECOND TRIGGER", Color.PURPLE)
	_check(surface.find_children("FighterStatusTrigger", "Label", true, false).size() == 1, "Simultaneous curse/blessing trigger indicators overlapped")
	_check((game.get("fighter_status_trigger_queue") as Array).size() == 1, "Second fighter trigger indicator was not queued")
	await create_timer(1.52).timeout

	game.call("_offer_artifact_choices")
	var artifact_icons := (game.get("artifact_choice_box") as Control).find_children("ArtifactChoiceIcon", "TextureRect", true, false)
	_check(artifact_icons.size() == 3, "Artifact choices did not show an icon in each lower panel")
	for icon in artifact_icons:
		_check((icon as TextureRect).custom_minimum_size == Vector2(168, 168) and (icon as TextureRect).texture != null, "Artifact choice icon was not a loaded four-times-size icon")

	var animator = game.get("combat_animator")
	var attacker := Control.new()
	attacker.size = Vector2(120, 160)
	attacker.position = Vector2(300, 500)
	surface.add_child(attacker)
	var target := Control.new()
	target.size = Vector2(300, 60)
	target.position = Vector2(650, 100)
	surface.add_child(target)
	var audio := AudioStreamPlayer.new()
	audio.pitch_scale = 0.5
	game.add_child(audio)
	animator.set_animation_speed(0.5)
	await animator.call("pit_player_finisher", attacker, target, 20, surface, 0.75, [audio])
	_check(is_equal_approx(float(attacker.get_meta("fatal_apex_animation_speed", 0.0)), 0.375), "Fatal contact did not slow animation by a further 25%")
	_check(is_equal_approx(float(attacker.get_meta("fatal_apex_audio_pitch", 0.0)), 0.375), "Fatal contact did not slow audio by a further 25%")
	_check(is_equal_approx(audio.pitch_scale, 0.5), "Fatal contact did not restore audio speed after the animation")

	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("August 17 request regression passed: targeting, skill kills, status copy, artifacts, and lethal slowdown.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
