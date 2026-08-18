extends SceneTree

const MAIN_SCENE := preload("res://main.tscn")

var failures: Array[String] = []


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _labels_below(node: Node) -> Array[Label]:
	var labels: Array[Label] = []
	for child in node.get_children():
		if child is Label:
			labels.append(child)
		labels.append_array(_labels_below(child))
	return labels


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := MAIN_SCENE.instantiate()
	root.add_child(game)
	await process_frame
	game.call("_set_game_speed", "fast")
	game.call("_select_faction", "cinder_coven")
	game.call("_begin_selected_faction_run")
	game.set("match_serial", int(game.get("match_serial")) + 1)
	game.set("phase", "TRAIN")
	game.set("active_player", 0)
	game.set("input_locked", false)
	_check((game.get("design_surface") as Control).theme.get_font_size("font_size", "TooltipLabel") == 45, "Tooltips are not three times larger")
	_check((game.get("encounter_number_label") as Label).get_theme_font_size("font_size") > (game.get("turn_label") as Label).get_theme_font_size("font_size"), "Encounter number is not larger than header text")
	_check((game.get("round_number_label") as Label).get_theme_color("font_color") != (game.get("encounter_number_label") as Label).get_theme_color("font_color"), "Encounter and round counters do not use distinct colors")
	var computer_half: PanelContainer = game.get("opponent_status_panel")
	var human_half: PanelContainer = game.get("player_status_panel")
	_check(computer_half.get_parent() == human_half.get_parent(), "Computer and human summaries are not in one split panel")
	_check(not computer_half.get_parent().find_children("*", "VSeparator", true, false).is_empty(), "Combined player summary has no center divider")
	_check(human_half.get_index() < computer_half.get_index(), "Human status was not moved to the left of the computer status")
	_check((game.get("player_health") as Array)[0] == 20, "Default player health is not 20")
	_check((game.get("player_health") as Array)[1] == 20, "Default enemy health is not 20")
	_check(is_equal_approx(float(game.get("player_health_bar").get("health_ratio")), 1.0) and is_equal_approx(float(game.get("opponent_health_bar").get("health_ratio")), 1.0), "Health bars did not begin full")
	_check(int(game.get("player_health_bar").get("corner_radius")) >= 9 and int(game.get("opponent_health_bar").get("corner_radius")) >= 9, "Top player health bars do not have rounded corners")
	_check(bool(game.get("player_health_bar").get_meta("turn_highlight_active", false)) and (game.get("player_health_bar") as Control).scale.x >= 1.18, "Current player's health bar did not receive the brighter enlarged turn highlight")
	_check(not is_instance_valid(game.get("player_turn_glow")) and not is_instance_valid(game.get("opponent_turn_glow")), "Legacy moving turn-highlight bars are still attached")
	game.set("active_player", 1)
	game.call("_refresh_turn_display")
	_check(bool(game.get("opponent_health_bar").get_meta("turn_highlight_active", false)) and (game.get("opponent_health_bar") as Control).scale.x >= 1.18 and (game.get("player_health_bar") as Control).scale == Vector2.ONE, "Health-bar turn highlight did not transfer to the computer")
	game.set("active_player", 0)
	game.call("_refresh_turn_display")
	var human_animation_target: Control = game.call("_player_animation_target", 0)
	var computer_animation_target: Control = game.call("_player_animation_target", 1)
	_check(human_animation_target.get_global_rect().get_center().x < computer_animation_target.get_global_rect().get_center().x, "Player-target animations were not retargeted to the swapped header sides")
	(game.get("player_health") as Array)[0] = 5
	game.call("_refresh_all")
	await process_frame
	_check(is_equal_approx(float(game.get("player_health_bar").get("health_ratio")), 0.25), "Human health bar did not shrink to 25 percent")
	(game.get("player_health") as Array)[0] = 20

	# Cards unavailable in the current phase are dimmed and lowered, while the
	# remaining hand stays centered as cards leave it.
	var hands: Array = game.get("hands")
	hands[0] = [
		{"id":9490, "definition_id":"stat_3", "kind":"stat", "name":"3", "value":3, "description":"Train."},
		{"id":9491, "definition_id":"heal_small_heal", "kind":"heal", "name":"Small Heal", "value":5, "description":"Heal."},
	]
	game.call("_refresh_all")
	await process_frame
	await process_frame
	var phase_hand_nodes: Dictionary = game.get("hand_card_nodes")
	var lowered_heal: Button = phase_hand_nodes[0]
	var playable_stat: Button = phase_hand_nodes[1]
	_check(bool(lowered_heal.get_meta("phase_unplayable", false)) and is_equal_approx(lowered_heal.modulate.r, 0.75) and lowered_heal.position.y >= 24.0, "Unplayable heal card was not dimmed 25 percent and lowered 25 pixels during training")
	var unavailable_fade := lowered_heal.get_node_or_null("UnavailableBottomFade") as TextureRect
	_check(is_instance_valid(unavailable_fade) and is_equal_approx(float(unavailable_fade.get_meta("fade_height", 0.0)), 30.0), "Lowered card does not fade across its final visible 30 pixels")
	_check("UNAVAILABLE:" in lowered_heal.tooltip_text and "heal phase" in lowered_heal.tooltip_text, "Dimmed card tooltip did not explain why the card is unavailable")
	_check(not bool(playable_stat.get_meta("phase_unplayable", false)), "Playable stat card was incorrectly dimmed")
	_check((game.get("hand_box") as HBoxContainer).alignment == BoxContainer.ALIGNMENT_CENTER, "Remaining hand cards are not center justified")

	# Stage one stat, then cancel it from the new-fighter card without consuming a play.
	hands[0] = [{"id":9500, "definition_id":"stat_7", "kind":"stat", "name":"7", "value":7, "description":"Train: use as attack or defense."}]
	var history_before: int = (game.get("card_play_history") as Array)[0].size()
	var selected: Array = game.get("selected_hand_indices")
	selected.append(0)
	game.call("_on_new_fighter_slot_pressed", "attack")
	_check(hands[0].is_empty(), "Staged stat card did not leave the hand")
	_check(int(game.get("new_fighter_attack")) == 7, "Staged stat did not fill the attack slot")
	_check(not (game.get("pending_new_fighter_cards") as Dictionary).is_empty(), "Pending fighter did not preserve its staged card")
	game.call("_refresh_all")
	await process_frame
	var cancel_found := false
	for button in game.get("player_fighters_box").find_children("*", "Button", true, false):
		if String(button.text) == "×":
			cancel_found = true
			_check(not button.disabled, "New-fighter cancel button was disabled with a staged card")
	_check(cancel_found, "New-fighter card has no upper-right cancel button")
	game.call("_cancel_pending_new_fighter")
	_check(hands[0].size() == 1 and int(hands[0][0]["value"]) == 7, "Cancel did not return the staged stat card")
	_check(int(game.get("stat_cards_played_this_turn")) == 0, "Cancel did not refund the staged stat play")
	_check((game.get("card_play_history") as Array)[0].size() == history_before, "Cancelled stat polluted card history")
	hands[0] = [
		{"id":9510, "definition_id":"stat_4", "kind":"stat", "name":"4", "value":4, "description":"Train: use as attack or defense."},
		{"id":9511, "definition_id":"stat_6", "kind":"stat", "name":"6", "value":6, "description":"Train: use as attack or defense."},
	]
	selected.clear(); selected.append(0)
	game.call("_on_new_fighter_slot_pressed", "attack")
	selected.append(0)
	game.call("_on_new_fighter_slot_pressed", "defense")
	_check((game.get("fighters") as Array)[0].size() == 1, "Completing both staged slots did not train a fighter")
	_check((game.get("card_play_history") as Array)[0].size() == history_before + 2, "Completed fighter did not record both stat cards")
	_check((game.get("pending_new_fighter_cards") as Dictionary).is_empty(), "Completed fighter left staged-card state behind")

	# Once this turn's fighter exists, another playable stat offers only existing-
	# fighter upgrade buttons and never renders a second New Fighter panel.
	hands[0] = [{"id":9520, "definition_id":"stat_2", "kind":"stat", "name":"2", "value":2, "description":"Train: use as attack or defense."}]
	selected.clear(); selected.append(0)
	game.call("_refresh_all")
	await process_frame
	var new_fighter_titles: Array[Node] = game.get("player_fighters_box").find_children("*", "Label", true, false).filter(func(label: Node) -> bool: return String((label as Label).text) == "NEW FIGHTER")
	_check(new_fighter_titles.is_empty(), "New Fighter popup remained visible after the turn's fighter was already created")
	var created_fighter: Dictionary = (game.get("fighters") as Array)[0][0]
	var created_button: Button = (game.get("fighter_button_nodes") as Dictionary)[int(created_fighter["id"])]
	var upgrade_buttons := created_button.find_children("*", "Button", true, false).filter(func(candidate: Node) -> bool: return "->" in String((candidate as Button).text))
	_check(upgrade_buttons.size() == 2, "Existing-fighter stat upgrade buttons disappeared when new-fighter creation was unavailable")

	# After that independent stat-training play is also spent, remaining stat cards
	# become unavailable with the same dim/shift treatment and a reason tooltip.
	game.set("stat_cards_played_this_turn", 1)
	selected.clear()
	game.call("_refresh_all")
	await process_frame
	await process_frame
	var unavailable_stat: Button = (game.get("hand_card_nodes") as Dictionary)[0]
	_check(bool(unavailable_stat.get_meta("phase_unplayable", false)) and unavailable_stat.position.y >= 24.0 and is_equal_approx(unavailable_stat.modulate.r, 0.75), "Spent-turn stat card was not dimmed and shifted down")
	_check("UNAVAILABLE: All stat cards played this turn" in unavailable_stat.tooltip_text, "Unavailable stat tooltip did not explain the exhausted stat limit")
	(game.get("fighters") as Array)[0].clear()
	game.set("stat_cards_played_this_turn", 0)

	# A selected stat shows the exact resulting totals on every existing fighter's
	# attack and defense buttons.
	var preview_fighter: Dictionary = game.call("_create_fighter", 0, 8, 7)
	(game.get("fighters") as Array)[0].append(preview_fighter)
	hands[0] = [{"id":9550, "definition_id":"stat_2", "kind":"stat", "name":"2", "value":2, "description":"Train: use as attack or defense."}]
	selected.clear(); selected.append(0)
	game.call("_refresh_all")
	await process_frame
	var selected_stat_button: Button = (game.get("hand_card_nodes") as Dictionary)[0]
	_check(selected_stat_button.scale.x >= 1.09 and selected_stat_button.scale.y >= 1.09, "Selected unassigned stat card did not grow by about 10 percent")
	_check(bool(selected_stat_button.get_meta("stat_selection_pulse", false)), "Selected unassigned stat card did not start its subtle pulse")
	var preview_button: Button = (game.get("fighter_button_nodes") as Dictionary)[int(preview_fighter["id"])]
	_check(not preview_button.find_children("PitHealthBar", "ProgressBar", true, false).is_empty(), "Stable fighter card did not keep its health bar outside combat")
	var stable_bar := preview_button.get_node_or_null("PitHealthBar") as ProgressBar
	_check(is_instance_valid(stable_bar) and stable_bar.get_global_rect().end.y <= preview_button.get_global_rect().position.y, "Stable fighter health bar is not positioned completely above its card")
	_check(preview_button.get_parent().name == "StableFighterSlot" and preview_button.size.y <= 113.0, "Stable fighter card stretched into its reserved health-bar headroom")
	preview_fighter["poison"] = true
	preview_fighter["poison_stacks"] = 2
	game.call("_apply_upkeep", 0)
	var poison_popups := (game.get("design_surface") as Control).find_children("PoisonDamagePopup", "Label", true, false)
	_check(int(preview_fighter["damage"]) == 4 and not poison_popups.is_empty() and String((poison_popups[0] as Label).text) == "POISON: -4", "Poison upkeep did not display its green damage popup")
	if not poison_popups.is_empty():
		_check(is_equal_approx(float((poison_popups[0] as Label).get_meta("display_duration", 0.0)), 1.5), "Poison damage popup is not configured for 1.5 seconds")
		_check((poison_popups[0] as Label).get_theme_font_size("font_size") == 16, "Poison damage popup was not reduced to one-third size")
	preview_fighter["poison"] = false
	preview_fighter["poison_stacks"] = 0
	preview_fighter["damage"] = 0
	var preview_button_texts: Array[String] = []
	for child_button in preview_button.find_children("*", "Button", true, false):
		preview_button_texts.append(String(child_button.text))
		if String(child_button.text) in ["8 -> 10", "7/7 -> 9/9"]:
			var expected_size := int(game.call("_fit_single_line_font", String(child_button.text), 16, 88.0))
			_check(child_button.get_theme_font_size("font_size") == expected_size, "Stat preview button did not use the largest fitting font")
			_check(child_button.autowrap_mode == TextServer.AUTOWRAP_OFF, "Stat preview button can still wrap onto multiple lines")
	_check("8 -> 10" in preview_button_texts, "Attack stat button did not preview 8 -> 10")
	_check("7/7 -> 9/9" in preview_button_texts, "Defense stat button did not preview 7/7 -> 9/9")

	# Newly shown fighter cards drop and bounce for about one second without
	# disabling their input.
	game.call("_queue_fighter_entrance", preview_fighter)
	game.call("_refresh_all")
	await process_frame
	await process_frame
	preview_button = (game.get("fighter_button_nodes") as Dictionary)[int(preview_fighter["id"])]
	_check(bool(preview_button.get_meta("fighter_drop_active", false)), "New fighter drop animation did not start")
	_check(not preview_button.disabled and not bool(game.get("input_locked")), "New fighter drop animation blocked input")
	await create_timer(1.05).timeout
	_check(not bool(preview_button.get_meta("fighter_drop_active", true)), "New fighter drop animation did not settle after about one second")

	# Final-roll numbers appear over the fighter, advance to the total display,
	# and any mouse click skips the remainder immediately.
	var final_rolls: Array[Dictionary] = [{"fighter":preview_fighter, "roll":{"sides":8, "rolled":3, "damage":3, "self_hit":false}}]
	game.call("_animate_final_pit_rolls", final_rolls, 1)
	await create_timer(0.35).timeout
	_check(bool(game.get("final_roll_animation_active")), "Final-roll animation did not become active")
	var rolling_labels := preview_button.find_children("FinalRollNumber", "Label", true, false)
	_check(not rolling_labels.is_empty(), "Fighter did not show a rolling-number display")
	if not rolling_labels.is_empty():
		_check(is_equal_approx(float((rolling_labels[0] as Label).get_meta("player_damage_roll_duration_scale", 0.0)), 0.5), "Player-damage rolling animation was not halved")
	await create_timer(1.20).timeout
	var total_labels: Array[Node] = (game.get("design_surface") as Control).find_children("FinalRollTotal", "Label", true, false)
	_check(not total_labels.is_empty() and "TOTAL DAMAGE  3" in String((total_labels[0] as Label).text), "Final-roll animation did not show the combined damage total")
	_check(bool(preview_button.get_meta("finisher_lifted_above_pit", false)) and bool(preview_button.get_meta("finisher_reached_target", false)), "Surviving fighter was not lifted out of pit clipping and animated to the player health bar")
	if not total_labels.is_empty():
		_check((total_labels[0] as Label).position.distance_to(Vector2(460, 360)) < 2.0, "Final damage popup was not centered on screen")
		_check((total_labels[0] as Label).z_index > preview_button.z_index, "Final damage popup rendered behind attacking fighters")
	var skip_click := InputEventMouseButton.new()
	skip_click.button_index = MOUSE_BUTTON_LEFT
	skip_click.pressed = true
	game.call("_input", skip_click)
	await create_timer(0.10).timeout
	_check(not bool(game.get("final_roll_animation_active")), "Mouse click did not skip the final-roll animation")
	(game.get("fighters") as Array)[0].clear()
	selected.clear()

	# Eight compact cards must fit without a horizontal scrollbar.
	hands[0].clear()
	for value in range(1, 9):
		hands[0].append({"id":9600 + value, "definition_id":"stat_%d" % value, "kind":"stat", "name":str(value), "value":value, "description":"Train: use as attack or defense."})
	game.call("_refresh_all")
	await process_frame
	await process_frame
	var hand_nodes: Dictionary = game.get("hand_card_nodes")
	_check(hand_nodes.size() == 8, "Eight-card hand did not render eight cards")
	var total_width := 0.0
	for index in hand_nodes:
		total_width += (hand_nodes[index] as Button).custom_minimum_size.x
	total_width += 8.0 * 7.0
	_check(total_width <= game.get("hand_panel").size.x - 10.0, "Eight compact cards still require horizontal scrolling")
	var scrolls: Array[Node] = game.get("hand_panel").find_children("*", "ScrollContainer", true, false)
	if not scrolls.is_empty():
		_check(not (scrolls[0] as ScrollContainer).get_h_scroll_bar().visible, "Horizontal hand scrollbar is visible for eight cards")

	# Stat faces use a very large centered number; short regular names use 2.5x size.
	var stat_button: Button = hand_nodes[0]
	var stat_style := stat_button.get_theme_stylebox("normal") as StyleBoxFlat
	_check(stat_style != null and stat_style.corner_radius_bottom_left >= 18 and stat_style.corner_radius_bottom_right >= 18, "Stat card bottom corners remain square")
	var stat_art_nodes: Array[Node] = stat_button.find_children("*", "TextureRect", true, false)
	_check(not stat_art_nodes.is_empty() and stat_art_nodes[0].material is ShaderMaterial and bool((stat_art_nodes[0].material as ShaderMaterial).get_shader_parameter("round_bottom")), "Stat artwork does not mask its bottom corners")
	var number_found := false
	for label in _labels_below(stat_button):
		if label.text == "8":
			number_found = true
			_check(label.get_theme_font_size("font_size") >= 70, "Stat number is not dramatically enlarged")
			_check(label.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER and label.vertical_alignment == VERTICAL_ALIGNMENT_CENTER, "Stat number is not centered")
	_check(number_found, "Stat face did not render its number")
	hands[0] = [{"id":9700, "definition_id":"weapon_sword", "kind":"weapon", "name":"Sword", "value":2, "description":"+2 attack"}]
	game.call("_refresh_all")
	await process_frame
	var sword_button: Button = (game.get("hand_card_nodes") as Dictionary)[0]
	var sword_found := false
	for label in _labels_below(sword_button):
		if label.text == "SWORD":
			sword_found = true
			_check(label.get_theme_font_size("font_size") == 30, "Short card name did not receive the requested 2.5x size")
	_check(sword_found, "Regular card name label was not rendered")

	# Card faces retain four rounded outer corners, unbroken single-word names,
	# and a compact rounded badge behind their type text.
	hands[0] = [{"id":9800, "definition_id":"curse_deathmark", "kind":"curse", "name":"Deathmark", "value":0, "description":"Destroy target fighter."}]
	game.call("_refresh_all")
	await process_frame
	var deathmark_button: Button = (game.get("hand_card_nodes") as Dictionary)[0]
	var card_style := deathmark_button.get_theme_stylebox("normal") as StyleBoxFlat
	_check(card_style != null, "Card normal style is missing")
	if card_style:
		_check(card_style.corner_radius_top_left >= 18 and card_style.corner_radius_top_right >= 18 and card_style.corner_radius_bottom_left >= 18 and card_style.corner_radius_bottom_right >= 18, "Card frame does not visibly round all four corners")
	var deathmark_found := false
	for label in _labels_below(deathmark_button):
		if label.text == "DEATHMARK":
			deathmark_found = true
			_check(label.autowrap_mode == TextServer.AUTOWRAP_OFF, "Single-word card name can still wrap mid-word")
			var rendered_width: float = (game.get("game_font") as Font).get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")).x
			_check(rendered_width <= deathmark_button.custom_minimum_size.x - 16.0, "Deathmark font was not reduced enough to remain on one line")
	_check(deathmark_found, "Deathmark name label was not rendered")
	var art_nodes: Array[Node] = deathmark_button.find_children("*", "TextureRect", true, false)
	_check(not art_nodes.is_empty() and art_nodes[0].material is ShaderMaterial, "Card artwork has no rounded-corner mask")
	if not art_nodes.is_empty() and art_nodes[0].material is ShaderMaterial:
		var art_material := art_nodes[0].material as ShaderMaterial
		_check(bool(art_material.get_shader_parameter("round_top")), "Card artwork does not mask its top corners")
		_check(Vector2(art_material.get_shader_parameter("logical_size_pixels")).x > 0.0, "Card artwork corner mask still uses cropped texture coordinates")
	var hover_outlines: Array[Node] = deathmark_button.find_children("CardHoverOutline", "Panel", true, false)
	_check(not hover_outlines.is_empty(), "Card does not have a foreground hover outline")
	if not hover_outlines.is_empty():
		var hover_outline := hover_outlines[0] as Panel
		deathmark_button.emit_signal("mouse_entered")
		_check(hover_outline.visible and hover_outline.z_index > 0, "Card hover outline is not visible above its artwork")
		deathmark_button.emit_signal("mouse_exited")
	var badge_nodes: Array[Node] = deathmark_button.find_children("CardTypeBadge", "PanelContainer", true, false)
	_check(not badge_nodes.is_empty(), "Card type has no rounded background badge")
	if not badge_nodes.is_empty():
		var badge_style := (badge_nodes[0] as PanelContainer).get_theme_stylebox("panel") as StyleBoxFlat
		_check(badge_style != null and badge_style.corner_radius_top_left > 0, "Card type badge background is not rounded")
		_check(is_equal_approx(badge_style.content_margin_top + badge_style.content_margin_bottom, 1.0), "Card type badge is not exactly one pixel taller than its text")
	_check(not game.get("fighter_lane_panels").is_empty() and not (game.get("fighter_lane_panels") as Dictionary)[1].find_children("BatteredMetalTexture", "TextureRect", true, false).is_empty(), "Fighter lane panel is missing the generated metal texture")
	var lane_style := ((game.get("fighter_lane_panels") as Dictionary)[1] as PanelContainer).get_theme_stylebox("panel") as StyleBoxFlat
	_check(lane_style != null and lane_style.bg_color.a <= 0.10, "Original blue fighter panel still obscures the metal texture")
	_check(not game.get("pit_panel").find_children("FighterPitTexture", "TextureRect", true, false).is_empty(), "Pit is missing the generated illustrated backdrop")

	# Owned upgrade buttons are disabled for input but retain their acquired state.
	(game.get("owned_upgrade_ids") as Array).append("cinder_living_crucible")
	game.call("_refresh_upgrade_tree")
	await process_frame
	var owned_upgrade_button: Button
	for candidate in game.get("upgrade_nodes_box").find_children("*", "Button", true, false):
		if "LIVING CRUCIBLE" in String((candidate as Button).text):
			owned_upgrade_button = candidate as Button
			break
	_check(is_instance_valid(owned_upgrade_button), "Owned upgrade node was not rendered")
	if is_instance_valid(owned_upgrade_button):
		var owned_disabled_style := owned_upgrade_button.get_theme_stylebox("disabled") as StyleBoxFlat
		_check(owned_disabled_style != null and owned_disabled_style.bg_color.g > owned_disabled_style.bg_color.r and owned_disabled_style.bg_color.g > owned_disabled_style.bg_color.b, "Owned upgrade disabled state does not retain a green background")
		_check(owned_upgrade_button.get_theme_color("font_disabled_color") == Color.WHITE, "Owned upgrade disabled state does not retain white text")
	var locked_icons: Array[Node] = game.get("upgrade_nodes_box").find_children("UnavailableUpgradeLock", "Label", true, false)
	_check(not locked_icons.is_empty() and is_equal_approx(float((locked_icons[0] as Label).get_meta("opacity", 0.0)), 0.20), "Unavailable unowned upgrade does not show an 80%-transparent lock")

	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("UI adjustments passed: stat previews, selected-card pulse, fighter drop, final rolls, compact hand, rounded cards, and arena panels.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
