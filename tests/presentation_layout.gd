extends SceneTree

const MAIN_SCENE := preload("res://main.tscn")

var failures: Array[String] = []


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _center_x(control: Control) -> float:
	return (control.get_global_transform_with_canvas() * (control.size * 0.5)).x


func _center_y(control: Control) -> float:
	return (control.get_global_transform_with_canvas() * (control.size * 0.5)).y


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
	game.get("splash_layer").visible = false
	game.get("faction_layer").visible = false
	game.set("active_player", 0)
	game.set("input_locked", false)
	var paths: Dictionary = game.get("sound_paths")
	_check(not (paths.get("PITSTART", []) as Array).is_empty(), "Pit-start sound folder was not scanned")
	_check((paths.get("FIGHTBG", []) as Array).size() == 4, "Pit background sound folder was not scanned")
	_check(not (paths.get("game over", []) as Array).is_empty(), "Game-over sound folder was not scanned")
	_check(not (paths.get("intro_music", []) as Array).is_empty(), "Intro-music sound folder was not scanned")
	_check(not (paths.get("oneshot", []) as Array).is_empty(), "One-shot sound folder is missing the victory cue")
	_check(not (paths.get("pit_hit", []) as Array).is_empty(), "No random pit-hit sound pool was built")
	# Pit audio is a combat effect and must remain audible even if menu music was muted.
	game.set("music_muted", true)
	game.call("_start_pit_audio")
	_check(bool(game.get("pit_audio_active")) and not String(game.get("last_one_shot")).is_empty(), "Pit audio did not start with a random pit-start cue")
	_check((game.get("pit_start_player") as AudioStreamPlayer).playing, "Pit-start cue did not begin playback")
	_check((game.get("pit_background_player") as AudioStreamPlayer).playing, "Pit background loop did not begin at the same time as the pit-start cue")
	_check(not (game.get("pit_start_player") as AudioStreamPlayer).stream_paused and not (game.get("pit_background_player") as AudioStreamPlayer).stream_paused, "Pit audio was silently paused by the menu music-mute state")
	_check(is_equal_approx((game.get("pit_background_player") as AudioStreamPlayer).volume_db, linear_to_db(0.5)), "Pit background loop is not at 50% volume")
	_check(is_equal_approx((game.get("pit_start_player") as AudioStreamPlayer).volume_db, linear_to_db(0.8)), "Pit-start cue is not at 80% volume")
	_check(float(game.get("last_pit_background_start")) >= 0.0 and float(game.get("last_pit_background_start")) < (game.get("pit_background_player") as AudioStreamPlayer).stream.get_length(), "Pit background did not choose a valid random start point")
	var pit_stream := (game.get("pit_background_player") as AudioStreamPlayer).stream
	_check(pit_stream is AudioStreamWAV and (pit_stream as AudioStreamWAV).loop_mode == AudioStreamWAV.LOOP_FORWARD, "Pit background track was not configured to loop")
	_check(pit_stream is AudioStreamWAV and (pit_stream as AudioStreamWAV).loop_end > 0, "Pit background WAV has an invalid zero-length loop range")
	await create_timer(0.20).timeout
	_check((game.get("pit_background_player") as AudioStreamPlayer).get_playback_position() > 0.0, "Pit background playback clock did not advance")
	game.call("_stop_pit_audio")
	_check(not (game.get("pit_start_player") as AudioStreamPlayer).playing and not (game.get("pit_background_player") as AudioStreamPlayer).playing, "Pit audio continued after the pit phase stopped")
	game.set("music_muted", false)
	game.call("_start_game_over_audio")
	_check(bool(game.get("game_over_audio_active")) and (game.get("game_over_player") as AudioStreamPlayer).playing, "Random game-over music did not begin")
	game.call("_stop_game_over_audio")
	game.call("_play_background_music")
	var sides: Array = game.get("fighters")
	sides[0] = [game.call("_create_fighter", 0, 6, 7), game.call("_create_fighter", 0, 4, 8)]
	sides[1] = [game.call("_create_fighter", 1, 5, 6), game.call("_create_fighter", 1, 3, 9)]
	var selected: Array = game.get("selected_attacker_ids")
	selected.append(int(sides[0][0]["id"]))
	selected.append(int(sides[0][1]["id"]))
	game.set("phase", "ATTACK")
	game.call("_refresh_all")
	await process_frame
	await process_frame
	var pit: Control = game.get("pit_panel")
	var pit_center := _center_x(pit)
	var nodes: Dictionary = game.get("fighter_button_nodes")
	var attack_center := (_center_x(nodes[int(sides[0][0]["id"])]) + _center_x(nodes[int(sides[0][1]["id"])])) * 0.5
	_check(attack_center < pit_center - pit.size.x * 0.10, "Human stage-three fighters do not begin at the left pit rail")

	var pending: Array = game.get("pending_attack_ids")
	pending.append_array(selected)
	selected.clear()
	game.set("block_assignments", {
		int(sides[0][0]["id"]): [int(sides[1][0]["id"])],
		int(sides[0][1]["id"]): [int(sides[1][1]["id"])],
	})
	game.set("phase", "CLASH")
	sides[0][0]["damage"] = 3
	var hit_count_before := int(game.get("pit_hit_sound_count"))
	game.call("_apply_damage_to_fighter", sides[1][1], 1, "audio test", false)
	_check(int(game.get("pit_hit_sound_count")) == hit_count_before + 1, "A landed pit hit did not select a random hit sound")
	game.call("_refresh_all")
	await process_frame
	await process_frame
	nodes = game.get("fighter_button_nodes")
	var computer_before := (_center_x(nodes[int(sides[1][0]["id"])]) + _center_x(nodes[int(sides[1][1]["id"])])) * 0.5
	var human_before := (_center_x(nodes[int(sides[0][0]["id"])]) + _center_x(nodes[int(sides[0][1]["id"])])) * 0.5
	_check(human_before < pit_center and computer_before > pit_center, "Pit teams do not stage human-left and computer-right")
	var health_bars: Dictionary = game.get("pit_health_bar_nodes")
	_check(health_bars.size() == 4, "Pit combat did not add a health bar above every fighter")
	var damaged_bar: ProgressBar = health_bars[int(sides[0][0]["id"])]
	var damaged_card: Control = nodes[int(sides[0][0]["id"])]
	var pit_scroll: Control = (game.get("pit_fighters_box") as Control).get_parent()
	_check(absf(_center_y(damaged_card) - _center_y(pit_scroll)) <= 2.0, "Pit fighter card was not vertically centered in the fighter viewport")
	_check(damaged_bar.get_global_rect().position.y >= pit_scroll.get_global_rect().position.y, "Pit fighter health bar was clipped above the fighter viewport")
	_check(damaged_bar.get_parent() == damaged_card and damaged_bar.z_as_relative and damaged_bar.z_index == 0, "Pit health bar does not share its fighter card's canvas layer")
	var damaged_text := damaged_bar.get_node_or_null("PitHealthText") as Label
	_check(is_instance_valid(damaged_text) and damaged_text.text == "4 / 7", "Pit health bar did not show current health out of total health")
	_check(is_equal_approx(float(damaged_bar.get_meta("health_ratio")), 4.0 / 7.0), "Pit health bar did not track fighter damage")
	var human_style := (nodes[int(sides[0][0]["id"])] as Button).get_theme_stylebox("normal") as StyleBoxFlat
	var computer_style := (nodes[int(sides[1][0]["id"])] as Button).get_theme_stylebox("normal") as StyleBoxFlat
	_check(human_style.border_width_left == 2 and human_style.border_color == Color("#4fd1a1"), "Human pit fighter did not receive a two-pixel green border")
	_check(computer_style.border_width_left == 2 and computer_style.border_color == Color("#ff5d73"), "Computer pit fighter did not receive a two-pixel red border")
	game.call("_show_settings")
	_check((game.get("settings_layer") as Control).visible and damaged_bar.z_index == 0, "Pit health bar retained an elevated layer over the settings overlay")
	game.call("_hide_settings")

	# Strike lines draw first, damage totals remain on the struck card, and each
	# individual card attack advertises the quarter-second pit timing.
	var visual_strike: Dictionary = {"source":sides[0][0], "target":sides[1][0], "roll":{"damage":3}, "self_hit":false}
	game.call("_animate_pit_strike_lines", [visual_strike])
	await process_frame
	var strike_overlay: Control = game.get("pit_strike_overlay")
	_check(strike_overlay.visible and int(strike_overlay.get_meta("last_strike_count", 0)) == 1, "Pit target line did not begin before the card attack")
	_check(is_equal_approx(float(strike_overlay.get_meta("line_duration", 0.0)), 0.25), "Pit target-line assignment was not reduced to one quarter second")
	await create_timer(0.30).timeout
	_check(strike_overlay.visible, "Pit target line did not remain visible for the damage grid")
	strike_overlay.visible = false
	await game.call("_animate_pit_card_strike", visual_strike)
	_check(is_equal_approx(float((nodes[int(sides[0][0]["id"])] as Control).get_meta("pit_attack_duration", 0.0)), 0.5), "Pit card attack was not doubled to half a second")
	var madness_strike: Dictionary = {"source":sides[0][0], "target":sides[0][0], "roll":{"damage":2}, "self_hit":true}
	await game.call("_animate_madness_self_attack", madness_strike)
	var madness_visual := nodes[int(sides[0][0]["id"])] as Control
	_check(is_equal_approx(float(madness_visual.get_meta("madness_animation_speed", 0.0)), 0.5) and is_equal_approx(float(madness_visual.get_meta("madness_sound_pitch", 0.0)), 0.5), "Madness self-attack did not slow its animation and sound to 50%")
	_check(String((game.get("design_surface") as Control).get_meta("last_madness_banner_text", "")) == "MADNESS! SELF ATTACK!", "Madness self-attack banner was not shown")
	_check(is_equal_approx(float((game.get("combat_animator") as Node).get("animation_speed")), 1.0) and is_equal_approx((game.get("pit_background_player") as AudioStreamPlayer).pitch_scale, 1.0), "Madness playback speeds were not restored")
	game.call("_show_pit_damage_total", sides[1][0], 3)
	var damage_labels := (nodes[int(sides[1][0]["id"])] as Control).find_children("PitDamageAmount", "Label", true, false)
	_check(not damage_labels.is_empty() and String((damage_labels[0] as Label).text) == "-3", "Large red pit damage amount did not remain over the struck card")
	game.call("_clear_pit_damage_labels")
	await game.call("_animate_pit_charge_to_center")
	var computer_after := (_center_x(nodes[int(sides[1][0]["id"])]) + _center_x(nodes[int(sides[1][1]["id"])])) * 0.5
	var human_after := (_center_x(nodes[int(sides[0][0]["id"])]) + _center_x(nodes[int(sides[0][1]["id"])])) * 0.5
	_check(absf(computer_after - pit_center) < absf(computer_before - pit_center), "Computer fighters did not charge toward center")
	_check(absf(human_after - pit_center) < absf(human_before - pit_center), "Human fighters did not charge toward center")
	# Damage resolution uses one full-size fighter per centerline column for small
	# teams. Teams above three use half-size cards, with two-high columns beginning
	# at fighter four, and retain clearance under the full random vertical jitter.
	var grid_size := Vector2(230, 170)
	var grid_center_x := (game.get("pit_panel") as Control).size.x * 0.5
	var grid_rects: Array[Rect2] = []
	for side in 2:
		var previous_column_distance := -1.0
		for index in 3:
			var jitter := 1.0 + float(index) * 7.0
			var grid_center: Vector2 = game.call("_pit_grid_center", side, index, grid_size, 3, jitter)
			_check(grid_center.x < grid_center_x if side == 0 else grid_center.x > grid_center_x, "Pit grid placed a fighter on the wrong side of center")
			_check(is_equal_approx(grid_center.y, (game.get("pit_panel") as Control).size.y * 0.5 + jitter), "Single-row pit fighter was not vertically centered with its jitter")
			var distance := absf(grid_center.x - grid_center_x)
			_check(distance > previous_column_distance, "Single-fighter pit columns did not expand outward from center")
			previous_column_distance = distance
			var rect := Rect2(grid_center - grid_size * 0.5, grid_size)
			for existing in grid_rects:
				_check(not rect.intersects(existing), "Pit grid fighter cards overlap")
			grid_rects.append(rect)
	var compact_size := grid_size * 0.5
	grid_rects.clear()
	for side in 2:
		var column_centers: Dictionary = {}
		for index in 12:
			var column := int(game.call("_pit_grid_column", index, 12))
			var jitter := (-15.0 if column % 2 == 0 else 15.0)
			var grid_center: Vector2 = game.call("_pit_grid_center", side, index, compact_size, 12, jitter)
			_check(grid_center.x < grid_center_x if side == 0 else grid_center.x > grid_center_x, "Compact pit grid placed a fighter on the wrong side")
			if column_centers.has(column):
				_check(is_equal_approx(grid_center.x, float(column_centers[column])), "Overflow pit column was not vertically paired")
			else:
				column_centers[column] = grid_center.x
			var rect := Rect2(grid_center - compact_size * 0.5, compact_size)
			for existing in grid_rects:
				_check(not rect.intersects(existing), "Compact pit grid fighter cards overlap at maximum jitter")
			grid_rects.append(rect)
	_check(int(game.call("_pit_grid_column", 2, 12)) == 2 and int(game.call("_pit_grid_column", 3, 12)) == 3, "The fourth fighter did not begin the overflow columns")
	_check(int(game.call("_pit_grid_column", 3, 12)) == int(game.call("_pit_grid_column", 4, 12)), "Fighters four and five did not share the first two-high column")
	var original_positions: Dictionary = await game.call("_animate_pit_fighters_to_grid", [sides[0], sides[1]])
	for side in 2:
		for fighter in sides[side]:
			var visual: Control = nodes[int(fighter["id"])]
			_check(is_equal_approx(visual.scale.x, 1.0), "A team of three or fewer was incorrectly shrunk")
			var vertical_shift := absf(float(visual.get_meta("pit_grid_center").y) - (game.get("pit_panel") as Control).size.y * 0.5)
			_check(vertical_shift >= 1.0 and vertical_shift <= 15.0, "Pit fighter jitter fell outside the requested 1–15 pixel range")
	await game.call("_restore_pit_fighters_from_grid", original_positions)
	for side in 2:
		for extra in 3:
			sides[side].append(game.call("_create_fighter", side, 2 + extra, 6))
	pending.clear()
	for fighter in sides[0]:
		pending.append(int(fighter["id"]))
	game.call("_refresh_all")
	await process_frame
	await process_frame
	nodes = game.get("fighter_button_nodes")
	var compact_originals: Dictionary = await game.call("_animate_pit_fighters_to_grid", [sides[0], sides[1]])
	var pit_bounds := Rect2(Vector2.ZERO, (game.get("pit_panel") as Control).size)
	for side in 2:
		for fighter in sides[side]:
			var compact_visual: Control = nodes[int(fighter["id"])]
			_check(compact_visual.scale.x < 1.0 and compact_visual.scale.x >= 0.25 and is_equal_approx(compact_visual.scale.x, compact_visual.scale.y), "Crowded pit cards did not receive a uniform fit-to-screen scale")
			var displayed_size := compact_visual.size * compact_visual.scale
			var displayed_center: Vector2 = compact_visual.get_meta("pit_grid_center")
			_check(pit_bounds.encloses(Rect2(displayed_center - displayed_size * 0.5, displayed_size)), "A damage-resolution fighter was positioned outside the visible pit")
		var fourth_center: Vector2 = (nodes[int(sides[side][3]["id"])] as Control).get_meta("pit_grid_center")
		var fifth_center: Vector2 = (nodes[int(sides[side][4]["id"])] as Control).get_meta("pit_grid_center")
		_check(is_equal_approx(fourth_center.x, fifth_center.x), "Runtime fighters four and five did not share an overflow column")
	await game.call("_restore_pit_fighters_from_grid", compact_originals)
	var animator: Node = game.get("combat_animator")
	(game.get("pit_panel") as Control).remove_meta("uncontested_charge_skipped")
	var uncontested_human: Array[Control] = [nodes[int(sides[0][0]["id"])] as Control]
	var uncontested_computer: Array[Control] = []
	await animator.call("pit_charge", uncontested_human, uncontested_computer, game.get("pit_panel"))
	_check(bool((game.get("pit_panel") as Control).get_meta("uncontested_charge_skipped", false)), "An uncontested pit did not skip the left/right charge animation")
	_check((game.get("pit_panel") as Control).find_children("*", "Label", true, false).all(func(item: Label) -> bool: return item.text != "CLASH!"), "An uncontested pit displayed CLASH text")
	animator.call("_screen_shake_for_damage", game.get("design_surface"), 7)
	await process_frame
	_check(is_equal_approx(float(game.get("design_surface").get_meta("last_screen_shake_strength", 0.0)), 8.0), "Screen shake did not begin at seven damage")
	await create_timer(0.45).timeout
	await animator.call("pit_player_finisher", nodes[int(sides[0][0]["id"])], game.get("opponent_status_panel"), 15, game.get("design_surface"))
	_check(is_equal_approx(float(game.get("design_surface").get_meta("last_screen_shake_strength", 0.0)), 30.0), "Screen shake did not cap at fifteen damage")
	_check(int((nodes[int(sides[0][0]["id"])] as Control).get_meta("finisher_damage", 0)) == 15, "Dramatic player finisher did not receive its damage value")

	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("Presentation layout passed: pit health bars, owner borders, target lines, damage labels, and card attacks.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
