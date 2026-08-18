extends SceneTree

const MAIN_SCENE := preload("res://main.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var capture := AudioEffectCapture.new()
	capture.buffer_length = 3.0
	AudioServer.add_bus_effect(0, capture, 0)
	var game := MAIN_SCENE.instantiate()
	root.add_child(game)
	await process_frame
	(game.get("music_player") as AudioStreamPlayer).stop()
	(game.get("game_over_player") as AudioStreamPlayer).stop()
	for sfx in game.get("sfx_players"):
		(sfx as AudioStreamPlayer).stop()
	game.set("music_muted", true)
	game.set("pit_audio_active", true)
	game.set("pit_background_started", false)
	game.call("_start_pit_background_loop")
	await create_timer(2.0).timeout
	var player := game.get("pit_background_player") as AudioStreamPlayer
	var available := capture.get_frames_available()
	var frames := capture.get_buffer(available)
	var peak := 0.0
	for frame in frames:
		peak = maxf(peak, maxf(absf(frame.x), absf(frame.y)))
	var path := String(game.get("last_pit_background_path"))
	print("[PIT AUDIO TEST] path=%s length=%.3f playing=%s paused=%s position=%.3f frames=%d peak=%.6f volume_db=%.3f" % [path, player.stream.get_length(), player.playing, player.stream_paused, player.get_playback_position(), available, peak, player.volume_db])
	var start := float(game.get("last_pit_background_start"))
	var passed := not path.is_empty() and player.playing and not player.stream_paused and player.get_playback_position() > 0.0 and available > 0 and peak > 0.0001 and is_equal_approx(player.volume_db, linear_to_db(0.5)) and start >= 0.0 and start < player.stream.get_length()
	game.call("_stop_pit_audio")
	game.queue_free()
	AudioServer.remove_bus_effect(0, 0)
	await process_frame
	if passed:
		print("Pit audio output passed: decoded FIGHTBG produced non-zero samples from a random start point at 50% volume.")
		quit(0)
		return
	push_error("Pit audio output FAILED: FIGHTBG did not produce audible samples on the Master bus.")
	quit(1)
