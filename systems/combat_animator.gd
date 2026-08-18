class_name CombatAnimator
extends Node
## Reusable, code-only combat presentation for Control based battle screens.
##
## Add one instance below the screen's root Control. Every public animation method
## may be awaited and also emits [signal animation_finished] when it completes.

signal animation_finished(kind: StringName, target: Control)

@export var reduced_motion := false
@export_range(0.1, 4.0, 0.05) var animation_speed := 1.0

const HIT_RED := Color("ff5b61")
const DAMAGE_GOLD := Color("ffd166")
const VICTORY_GOLD := Color("f4c95d")
const PIT_CARD_ATTACK_DURATION := 0.5


class ImpactBurst:
	extends Control

	var burst_color := Color("ffb347")

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		queue_redraw()

	func _draw() -> void:
		var center := size * 0.5
		draw_circle(center, 34.0, Color(burst_color, 0.20))
		draw_arc(center, 39.0, 0.0, TAU, 32, Color(burst_color, 0.92), 5.0)
		draw_arc(center, 25.0, 0.0, TAU, 24, Color.WHITE, 0.82, 3.0)
		for index in 12:
			var angle := TAU * float(index) / 12.0
			var inner := center + Vector2.from_angle(angle) * 32.0
			var outer := center + Vector2.from_angle(angle) * (66.0 if index % 2 == 0 else 52.0)
			draw_line(inner, outer, Color(burst_color, 0.88), 5.0, true)


func set_reduced_motion(enabled: bool) -> void:
	reduced_motion = enabled


func set_animation_speed(multiplier: float) -> void:
	animation_speed = clampf(multiplier, 0.1, 4.0)


## Runs a complete attack beat. Direction is inferred from the two Controls.
func fighter_attack(
	attacker: Control,
	target: Control,
	damage: int = 0,
	critical: bool = false
) -> void:
	if not _valid(attacker):
		await _finish(&"fighter_attack", attacker)
		return
	var start_position := attacker.position
	var direction := Vector2.RIGHT
	if _valid(target):
		direction = attacker.global_position.direction_to(target.global_position)
		if direction.is_zero_approx():
			direction = Vector2.RIGHT
	var start_scale := attacker.scale
	var start_rotation := attacker.rotation
	attacker.pivot_offset = attacker.size * 0.5
	var distance := 84.0 if not reduced_motion else 12.0
	var windup := create_tween().set_parallel(true)
	windup.tween_property(attacker, "position", start_position - direction * (22.0 if not reduced_motion else 3.0), _duration(0.13)) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	windup.tween_property(attacker, "scale", Vector2(start_scale.x * 0.90, start_scale.y * 1.08), _duration(0.13))
	windup.tween_property(attacker, "rotation", start_rotation - direction.x * 0.055, _duration(0.13))
	await windup.finished
	var lunge := create_tween().set_parallel(true)
	lunge.tween_property(attacker, "position", start_position + direction * distance, _duration(0.10)) \
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	lunge.tween_property(attacker, "scale", Vector2(start_scale.x * 1.14, start_scale.y * 0.92), _duration(0.10))
	lunge.tween_property(attacker, "rotation", start_rotation + direction.x * 0.075, _duration(0.10))
	await lunge.finished
	if _valid(target):
		impact(target, damage, critical)
	await get_tree().create_timer(_duration(0.08), true, false, false).timeout
	var recoil := create_tween()
	recoil.set_parallel(true)
	recoil.tween_property(attacker, "position", start_position - direction * (13.0 if not reduced_motion else 2.0), _duration(0.10)) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	recoil.tween_property(attacker, "scale", start_scale, _duration(0.20)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	recoil.tween_property(attacker, "rotation", start_rotation, _duration(0.18))
	await recoil.finished
	var settle := create_tween()
	settle.tween_property(attacker, "position", start_position, _duration(0.15)) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await settle.finished
	if _valid(attacker):
		attacker.position = start_position
		attacker.scale = start_scale
		attacker.rotation = start_rotation
	await _finish(&"fighter_attack", attacker)


## A compact pit-only lunge. The complete windup, contact, and recovery lasts
## half a second before the next fighter begins its attack.
func pit_card_attack(attacker: Control, target: Control) -> void:
	if not _valid(attacker):
		await _finish(&"pit_card_attack", attacker)
		return
	var start_position := attacker.position
	var start_scale := attacker.scale
	var start_rotation := attacker.rotation
	var target_modulate := target.modulate if _valid(target) else Color.WHITE
	var direction := Vector2.RIGHT
	if _valid(target):
		direction = attacker.get_global_rect().get_center().direction_to(target.get_global_rect().get_center())
		if direction.is_zero_approx():
			direction = Vector2.RIGHT
	attacker.pivot_offset = attacker.size * 0.5
	var contact := create_tween().set_parallel(true)
	contact.tween_property(attacker, "position", start_position + direction * (14.0 if reduced_motion else 72.0), _duration(PIT_CARD_ATTACK_DURATION * 0.40)) \
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	contact.tween_property(attacker, "scale", start_scale * Vector2(1.10, 0.94), _duration(PIT_CARD_ATTACK_DURATION * 0.40))
	contact.tween_property(attacker, "rotation", start_rotation + direction.x * (0.02 if reduced_motion else 0.07), _duration(PIT_CARD_ATTACK_DURATION * 0.40))
	if _valid(target):
		contact.tween_property(target, "modulate", HIT_RED, _duration(PIT_CARD_ATTACK_DURATION * 0.40))
	await contact.finished
	var recovery := create_tween().set_parallel(true)
	recovery.tween_property(attacker, "position", start_position, _duration(PIT_CARD_ATTACK_DURATION * 0.60)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	recovery.tween_property(attacker, "scale", start_scale, _duration(PIT_CARD_ATTACK_DURATION * 0.60))
	recovery.tween_property(attacker, "rotation", start_rotation, _duration(PIT_CARD_ATTACK_DURATION * 0.60))
	if _valid(target):
		recovery.tween_property(target, "modulate", target_modulate, _duration(PIT_CARD_ATTACK_DURATION * 0.60))
	await recovery.finished
	if _valid(attacker):
		attacker.position = start_position
		attacker.scale = start_scale
		attacker.rotation = start_rotation
	if _valid(target):
		target.modulate = target_modulate
	await _finish(&"pit_card_attack", attacker)


## A deliberately oversized survivor-to-player strike. Its travel, squash,
## rotation, and impact are roughly triple the normal pit-card lunge. Damage of
## seven or more also shakes the full game surface, reaching maximum force at 15.
func pit_player_finisher(attacker: Control, target: Control, damage: int, screen_root: Control, apex_slow_factor: float = 1.0, apex_audio_players: Array = []) -> void:
	if not _valid(attacker):
		await _finish(&"pit_player_finisher", attacker)
		return
	var start_position := attacker.position
	var start_scale := attacker.scale
	var start_rotation := attacker.rotation
	var target_modulate := target.modulate if _valid(target) else Color.WHITE
	var direction := Vector2.UP
	if _valid(target):
		direction = attacker.get_global_rect().get_center().direction_to(target.get_global_rect().get_center())
		if direction.is_zero_approx():
			direction = Vector2.UP
	attacker.pivot_offset = attacker.size * 0.5
	attacker.set_meta("finisher_damage", damage)
	var windup := create_tween().set_parallel(true)
	windup.tween_property(attacker, "position", start_position - direction * (10.0 if reduced_motion else 54.0), _duration(0.16)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	windup.tween_property(attacker, "scale", start_scale * Vector2(0.78, 1.24), _duration(0.16))
	windup.tween_property(attacker, "rotation", start_rotation - direction.x * (0.05 if reduced_motion else 0.16), _duration(0.16))
	await windup.finished
	var contact := create_tween().set_parallel(true)
	var contact_position := start_position + direction * (32.0 if reduced_motion else 216.0)
	if _valid(target) and attacker.get_parent() is CanvasItem:
		var target_center := target.get_global_rect().get_center()
		var parent_inverse := (attacker.get_parent() as CanvasItem).get_global_transform_with_canvas().affine_inverse()
		contact_position = parent_inverse * target_center - attacker.size * 0.5
		attacker.set_meta("finisher_reached_target", true)
	contact.tween_property(attacker, "position", contact_position, _duration(0.20)).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	contact.tween_property(attacker, "scale", start_scale * Vector2(1.32, 0.76), _duration(0.20))
	contact.tween_property(attacker, "rotation", start_rotation + direction.x * (0.07 if reduced_motion else 0.21), _duration(0.20))
	if _valid(target):
		contact.tween_property(target, "modulate", Color.WHITE * 1.8, _duration(0.20))
	await contact.finished
	var pre_apex_animation_speed := animation_speed
	var pre_apex_pitches: Array[Dictionary] = []
	if apex_slow_factor < 1.0:
		animation_speed *= apex_slow_factor
		attacker.set_meta("fatal_apex_animation_speed", animation_speed)
		for audio in apex_audio_players:
			if is_instance_valid(audio) and audio is AudioStreamPlayer:
				pre_apex_pitches.append({"player": audio, "pitch": audio.pitch_scale})
				audio.pitch_scale *= apex_slow_factor
				attacker.set_meta("fatal_apex_audio_pitch", audio.pitch_scale)
	if _valid(target):
		_spawn_impact_burst(target, true)
	if damage >= 7 and _valid(screen_root):
		_screen_shake_for_damage(screen_root, damage)
	await get_tree().create_timer(_duration(0.14), true, false, false).timeout
	var recovery := create_tween().set_parallel(true)
	recovery.tween_property(attacker, "position", start_position, _duration(0.32)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	recovery.tween_property(attacker, "scale", start_scale, _duration(0.32))
	recovery.tween_property(attacker, "rotation", start_rotation, _duration(0.32))
	if _valid(target):
		recovery.tween_property(target, "modulate", target_modulate, _duration(0.28))
	await recovery.finished
	if _valid(attacker):
		attacker.position = start_position
		attacker.scale = start_scale
		attacker.rotation = start_rotation
	if _valid(target):
		target.modulate = target_modulate
	if apex_slow_factor < 1.0:
		animation_speed = pre_apex_animation_speed
		for saved in pre_apex_pitches:
			var audio: AudioStreamPlayer = saved["player"]
			if is_instance_valid(audio):
				audio.pitch_scale = float(saved["pitch"])
	await _finish(&"pit_player_finisher", attacker)


func _screen_shake_for_damage(screen_root: Control, damage: int) -> void:
	if not _valid(screen_root) or damage < 7:
		return
	var intensity := clampf(float(damage - 7) / 8.0, 0.0, 1.0)
	var strength := lerpf(8.0, 30.0, intensity)
	var duration := lerpf(0.28, 0.65, intensity)
	var origin := screen_root.position
	screen_root.set_meta("last_screen_shake_damage", damage)
	screen_root.set_meta("last_screen_shake_strength", strength)
	var steps := maxi(4, ceili(duration / 0.045))
	var shake := create_tween()
	for index in steps:
		var falloff := 1.0 - float(index) / float(steps)
		var angle := float(index) * 2.39996
		var offset := Vector2(cos(angle), sin(angle * 1.31)) * strength * falloff
		shake.tween_property(screen_root, "position", origin + offset, _duration(duration / float(steps)))
	shake.tween_property(screen_root, "position", origin, _duration(0.06))
	await shake.finished
	if _valid(screen_root):
		screen_root.position = origin


## Hit flash, shake, and optional damage number. Safe to fire without awaiting.
func impact(target: Control, damage: int = 0, critical: bool = false) -> void:
	if not _valid(target):
		await _finish(&"impact", target)
		return
	var original_modulate := target.modulate
	var original_position := target.position
	var original_scale := target.scale
	var original_rotation := target.rotation
	target.pivot_offset = target.size * 0.5
	_spawn_impact_burst(target, critical)
	var tween := create_tween()
	if reduced_motion:
		tween.tween_property(target, "modulate", HIT_RED, _duration(0.06))
		tween.tween_property(target, "modulate", original_modulate, _duration(0.12))
	else:
		tween.tween_property(target, "modulate", Color.WHITE * 1.7, _duration(0.045))
		tween.tween_callback(func() -> void:
			if _valid(target):
				target.position = original_position + Vector2(-7.0, 2.0)
		)
		tween.tween_property(target, "position", original_position + Vector2(15.0, -5.0), _duration(0.045))
		tween.parallel().tween_property(target, "rotation", original_rotation + 0.09, _duration(0.045))
		tween.parallel().tween_property(target, "scale", original_scale * 1.12, _duration(0.045))
		tween.tween_property(target, "position", original_position - Vector2(10.0, -3.0), _duration(0.055))
		tween.parallel().tween_property(target, "rotation", original_rotation - 0.065, _duration(0.055))
		tween.tween_property(target, "position", original_position, _duration(0.10))
		tween.parallel().tween_property(target, "rotation", original_rotation, _duration(0.10))
		tween.parallel().tween_property(target, "scale", original_scale, _duration(0.10))
		tween.parallel().tween_property(target, "modulate", HIT_RED, _duration(0.06))
		tween.tween_property(target, "modulate", original_modulate, _duration(0.16))
	if damage > 0:
		floating_damage(target, damage, critical)
	await tween.finished
	if _valid(target):
		target.position = original_position
		target.modulate = original_modulate
		target.scale = original_scale
		target.rotation = original_rotation
	await _finish(&"impact", target)


func floating_damage(
	target: Control,
	amount: int,
	critical: bool = false,
	prefix: String = "-"
) -> void:
	if not _valid(target):
		await _finish(&"floating_damage", target)
		return
	var label := Label.new()
	label.text = ("CRIT! " if critical else "") + prefix + str(absi(amount))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 100
	label.add_theme_font_size_override("font_size", 46 if critical else 36)
	label.add_theme_color_override("font_color", DAMAGE_GOLD if critical else Color.WHITE)
	label.add_theme_color_override("font_shadow_color", Color(0.1, 0.0, 0.0, 0.95))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 3)
	target.add_child(label)
	label.position = Vector2(target.size.x * 0.5 - 28.0, -8.0)
	label.pivot_offset = label.size * 0.5
	if reduced_motion:
		label.modulate.a = 0.9
		await get_tree().create_timer(_duration(0.35), true, false, false).timeout
	else:
		label.scale = Vector2(0.45, 0.45)
		var tween := create_tween().set_parallel(true)
		tween.tween_property(label, "position:y", label.position.y - 62.0, _duration(0.62)) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(label, "scale", Vector2.ONE * (1.25 if critical else 1.0), _duration(0.18)) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(label, "modulate:a", 0.0, _duration(0.62)).set_delay(_duration(0.14))
		await tween.finished
	if is_instance_valid(label):
		label.queue_free()
	await _finish(&"floating_damage", target)


func pit_charge(computer_fighters: Array[Control], human_fighters: Array[Control], arena: Control) -> void:
	if not _valid(arena):
		await _finish(&"pit_charge", arena)
		return
	var computer_valid: Array[Control] = []
	var human_valid: Array[Control] = []
	for fighter in computer_fighters:
		if _valid(fighter):
			computer_valid.append(fighter)
	for fighter in human_fighters:
		if _valid(fighter):
			human_valid.append(fighter)
	if computer_valid.is_empty() or human_valid.is_empty():
		arena.set_meta("uncontested_charge_skipped", true)
		await _finish(&"pit_charge", arena)
		return
	var clash := Label.new()
	clash.text = "CLASH!"
	clash.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	clash.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	clash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clash.z_index = 130
	clash.add_theme_font_size_override("font_size", 54)
	clash.add_theme_color_override("font_color", DAMAGE_GOLD)
	clash.add_theme_color_override("font_shadow_color", Color(0.18, 0.0, 0.0, 0.95))
	clash.add_theme_constant_override("shadow_offset_x", 4)
	clash.add_theme_constant_override("shadow_offset_y", 6)
	arena.add_child(clash)
	clash.set_anchors_preset(Control.PRESET_CENTER)
	clash.offset_left = -150.0
	clash.offset_right = 150.0
	clash.offset_top = -52.0
	clash.offset_bottom = 52.0
	clash.pivot_offset = clash.size * 0.5
	clash.scale = Vector2(0.1, 0.1)
	clash.modulate.a = 0.0
	var windup := create_tween().set_parallel(true)
	for fighter in computer_valid:
		fighter.pivot_offset = fighter.size * 0.5
		windup.tween_property(fighter, "position:x", fighter.position.x + (28.0 if not reduced_motion else 4.0), _duration(0.15)) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		windup.tween_property(fighter, "rotation", 0.045, _duration(0.15))
	for fighter in human_valid:
		fighter.pivot_offset = fighter.size * 0.5
		windup.tween_property(fighter, "position:x", fighter.position.x - (28.0 if not reduced_motion else 4.0), _duration(0.15)) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		windup.tween_property(fighter, "rotation", -0.045, _duration(0.15))
	await windup.finished
	var center_x := arena.size.x * 0.5
	var computer_step := minf(190.0, arena.size.x * 0.36 / maxf(1.0, float(computer_valid.size())))
	var human_step := minf(190.0, arena.size.x * 0.36 / maxf(1.0, float(human_valid.size())))
	var charge := create_tween().set_parallel(true)
	for index in computer_valid.size():
		var fighter := computer_valid[index]
		var target_center_x := center_x + 22.0 + float(index) * computer_step
		var target_global: Vector2 = arena.get_global_transform_with_canvas() * Vector2(target_center_x, arena.size.y * 0.58)
		var target_local: Vector2 = fighter.get_parent().get_global_transform_with_canvas().affine_inverse() * target_global
		charge.tween_property(fighter, "position:x", target_local.x - fighter.size.x * 0.5, _duration(0.38)) \
			.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
		charge.tween_property(fighter, "rotation", -0.035, _duration(0.38))
	for index in human_valid.size():
		var fighter := human_valid[index]
		var target_center_x := center_x - 22.0 - float(human_valid.size() - 1 - index) * human_step
		var target_global: Vector2 = arena.get_global_transform_with_canvas() * Vector2(target_center_x, arena.size.y * 0.58)
		var target_local: Vector2 = fighter.get_parent().get_global_transform_with_canvas().affine_inverse() * target_global
		charge.tween_property(fighter, "position:x", target_local.x - fighter.size.x * 0.5, _duration(0.38)) \
			.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
		charge.tween_property(fighter, "rotation", 0.035, _duration(0.38))
	charge.tween_property(clash, "scale", Vector2.ONE, _duration(0.22)).set_delay(_duration(0.24)).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	charge.tween_property(clash, "modulate:a", 1.0, _duration(0.08)).set_delay(_duration(0.24))
	await charge.finished
	var fade := create_tween()
	fade.tween_interval(_duration(0.18))
	fade.tween_property(clash, "modulate:a", 0.0, _duration(0.16))
	await fade.finished
	if is_instance_valid(clash):
		clash.queue_free()
	await _finish(&"pit_charge", arena)


## Moves every living pit fighter at once for one half-second scuffle beat. The
## combat resolver samples their resulting screen positions for closest targeting.
func pit_scuffle_step(fighters: Array[Control], arena: Control, beat: int) -> void:
	if not _valid(arena):
		await _finish(&"pit_scuffle", arena)
		return
	var valid_fighters: Array[Control] = []
	for fighter in fighters:
		if _valid(fighter):
			valid_fighters.append(fighter)
	if valid_fighters.is_empty():
		await _finish(&"pit_scuffle", arena)
		return
	var center := Vector2(arena.size.x * 0.5, arena.size.y * 0.58)
	var scuffle := create_tween().set_parallel(true)
	for index in valid_fighters.size():
		var fighter := valid_fighters[index]
		fighter.pivot_offset = fighter.size * 0.5
		var angle := float(beat) * 1.71 + float(index) * TAU / float(valid_fighters.size())
		var radius_x := (34.0 if reduced_motion else 104.0) + float(index % 3) * (4.0 if reduced_motion else 16.0)
		var radius_y := 8.0 if reduced_motion else 42.0
		var target_in_arena := center + Vector2(cos(angle) * radius_x, sin(angle * 1.37) * radius_y)
		var target_global: Vector2 = arena.get_global_transform_with_canvas() * target_in_arena
		var target_local: Vector2 = fighter.get_parent().get_global_transform_with_canvas().affine_inverse() * target_global
		target_local -= fighter.size * 0.5
		scuffle.tween_property(fighter, "position", target_local, _duration(0.5)) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		scuffle.tween_property(fighter, "rotation", sin(angle) * (0.025 if reduced_motion else 0.11), _duration(0.5))
	await scuffle.finished
	await _finish(&"pit_scuffle", arena)


func _spawn_impact_burst(target: Control, critical: bool) -> void:
	if not _valid(target) or reduced_motion:
		return
	var burst := ImpactBurst.new()
	burst.burst_color = DAMAGE_GOLD if critical else HIT_RED.lightened(0.18)
	burst.custom_minimum_size = Vector2(140.0, 140.0)
	burst.size = Vector2(140.0, 140.0)
	burst.position = target.size * 0.5 - burst.size * 0.5
	burst.pivot_offset = burst.size * 0.5
	burst.scale = Vector2(0.15, 0.15)
	burst.z_index = 110
	target.add_child(burst)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(burst, "scale", Vector2.ONE * (1.38 if critical else 1.12), _duration(0.22)) \
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(burst, "rotation", 0.42, _duration(0.24))
	tween.tween_property(burst, "modulate:a", 0.0, _duration(0.22)).set_delay(_duration(0.08))
	tween.finished.connect(func() -> void:
		if is_instance_valid(burst):
			burst.queue_free()
	)


func fighter_flash(target: Control, color: Color = Color.WHITE, duration := 0.22) -> void:
	if not _valid(target):
		await _finish(&"fighter_flash", target)
		return
	var original := target.modulate
	var tween := create_tween()
	tween.tween_property(target, "modulate", color, _duration(duration * 0.35))
	tween.tween_property(target, "modulate", original, _duration(duration * 0.65))
	await tween.finished
	if _valid(target):
		target.modulate = original
	await _finish(&"fighter_flash", target)


func fighter_shake(target: Control, strength := 8.0, duration := 0.24) -> void:
	if not _valid(target):
		await _finish(&"fighter_shake", target)
		return
	var original := target.position
	var original_modulate := target.modulate
	if reduced_motion:
		var pulse := create_tween()
		pulse.tween_property(target, "modulate", HIT_RED, _duration(duration * 0.35))
		pulse.tween_property(target, "modulate", original_modulate, _duration(duration * 0.65))
		await pulse.finished
	else:
		var tween := create_tween()
		var steps := maxi(2, ceili(duration / 0.045))
		for index in range(steps):
			var falloff := 1.0 - float(index) / float(steps)
			var offset := Vector2(strength * falloff * (-1.0 if index % 2 == 0 else 1.0), 0.0)
			tween.tween_property(target, "position", original + offset, _duration(duration / steps))
		tween.tween_property(target, "position", original, _duration(0.04))
		await tween.finished
	if _valid(target):
		target.position = original
		target.modulate = original_modulate
	await _finish(&"fighter_shake", target)


func fighter_defeat(target: Control) -> void:
	if not _valid(target):
		await _finish(&"fighter_defeat", target)
		return
	var original_scale := target.scale
	var original_rotation := target.rotation
	var original_modulate := target.modulate
	var original_position := target.position
	target.pivot_offset = target.size * 0.5
	var tween := create_tween().set_parallel(true)
	if reduced_motion:
		tween.tween_property(target, "modulate:a", 0.0, _duration(0.24))
	else:
		_spawn_impact_burst(target, true)
		tween.tween_property(target, "position", original_position + Vector2(42.0, 96.0), _duration(0.48)) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tween.tween_property(target, "scale", Vector2(original_scale.x * 1.30, original_scale.y * 0.05), _duration(0.48)) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tween.tween_property(target, "rotation", original_rotation + 0.48, _duration(0.44))
		tween.tween_property(target, "modulate", Color(0.25, 0.05, 0.04, 0.0), _duration(0.50))
	await tween.finished
	# The caller owns removal. Hide first, then restore transforms so pooled Controls
	# can simply be made visible again without inheriting a collapsed layout.
	if _valid(target):
		target.visible = false
		target.scale = original_scale
		target.rotation = original_rotation
		target.modulate = original_modulate
		target.position = original_position
	await _finish(&"fighter_defeat", target)


## Shakes the portrait, flashes a temporary red vignette, and counts the HP label down.
func player_damage(
	portrait: Control,
	hp_label: Label,
	damage: int,
	new_hp: int,
	vignette_parent: Control = null
) -> void:
	if not _valid(portrait) and not _valid(hp_label):
		await _finish(&"player_damage", portrait)
		return
	var old_hp := new_hp + damage
	if _valid(hp_label):
		var parsed := hp_label.text.to_int()
		if parsed != 0 or hp_label.text.strip_edges() == "0":
			old_hp = parsed
	var vignette := _make_vignette(vignette_parent if _valid(vignette_parent) else portrait)
	if _valid(portrait):
		fighter_shake(portrait, 13.0, 0.34)
	if _valid(hp_label):
		var hp_tween := create_tween()
		hp_tween.tween_method(func(value: float) -> void:
			if _valid(hp_label):
				hp_label.text = str(roundi(value))
		, float(old_hp), float(new_hp), _duration(0.42))
	if _valid(vignette):
		var red_tween := create_tween()
		red_tween.tween_property(vignette, "modulate:a", 0.72, _duration(0.08))
		red_tween.tween_property(vignette, "modulate:a", 0.0, _duration(0.40))
		await red_tween.finished
		if is_instance_valid(vignette):
			vignette.queue_free()
	else:
		await get_tree().create_timer(_duration(0.42), true, false, false).timeout
	if _valid(hp_label):
		hp_label.text = str(new_hp)
	await _finish(&"player_damage", portrait)


func victory_flourish(anchor: Control, title := "VICTORY") -> void:
	if not _valid(anchor):
		await _finish(&"victory", anchor)
		return
	var banner := Label.new()
	banner.text = title
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.z_index = 120
	banner.add_theme_font_size_override("font_size", 54)
	banner.add_theme_color_override("font_color", VICTORY_GOLD)
	banner.add_theme_color_override("font_shadow_color", Color(0.15, 0.04, 0.01, 1.0))
	banner.add_theme_constant_override("shadow_offset_x", 3)
	banner.add_theme_constant_override("shadow_offset_y", 5)
	anchor.add_child(banner)
	banner.set_anchors_preset(Control.PRESET_CENTER)
	banner.offset_left = -180.0
	banner.offset_right = 180.0
	banner.offset_top = -40.0
	banner.offset_bottom = 40.0
	banner.pivot_offset = banner.size * 0.5
	if reduced_motion:
		banner.modulate.a = 0.0
		var fade := create_tween()
		fade.tween_property(banner, "modulate:a", 1.0, _duration(0.18))
		fade.tween_interval(_duration(0.55))
		fade.tween_property(banner, "modulate:a", 0.0, _duration(0.24))
		await fade.finished
	else:
		banner.scale = Vector2(0.15, 0.15)
		banner.rotation = -0.08
		var flourish := create_tween().set_parallel(true)
		flourish.tween_property(banner, "scale", Vector2.ONE, _duration(0.42)) \
			.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		flourish.tween_property(banner, "rotation", 0.0, _duration(0.30)) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		flourish.tween_property(banner, "modulate:a", 0.0, _duration(0.40)).set_delay(_duration(0.85))
		await flourish.finished
	if is_instance_valid(banner):
		banner.queue_free()
	await _finish(&"victory", anchor)


func _make_vignette(parent: Control) -> ColorRect:
	if not _valid(parent):
		return null
	var vignette := ColorRect.new()
	vignette.name = "CombatDamageVignette"
	vignette.color = Color(0.65, 0.0, 0.02, 0.42)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette.z_index = 110
	vignette.modulate.a = 0.0
	parent.add_child(vignette)
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return vignette


func _duration(seconds: float) -> float:
	return maxf(seconds / animation_speed, 0.001)


func _valid(control: Variant) -> bool:
	return control != null and is_instance_valid(control) and not control.is_queued_for_deletion()


func _finish(kind: StringName, target: Variant) -> void:
	# One frame makes even reduced/no-target branches consistently awaitable.
	if is_inside_tree():
		await get_tree().process_frame
	animation_finished.emit(kind, target if _valid(target) else null)
