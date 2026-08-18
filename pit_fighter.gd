extends Control

const FactionData = preload("res://data/faction_data.gd")
const UpgradeData = preload("res://data/upgrade_data.gd")
const ArtifactData = preload("res://data/artifact_data.gd")
const CombatAnimatorScript = preload("res://systems/combat_animator.gd")
const RoundedTextureShader = preload("res://systems/rounded_texture.gdshader")

const STARTING_HEALTH := 20
const STARTING_HAND := 7
const MAX_HAND := 12
const MAX_FIGHTERS_TRAINED_PER_TURN := 1
const MAX_STAT_TRAINING_PER_TURN := 1
const MAX_CARDS_DRAWN_PER_TURN := 4
const MAX_TRAINING_CARDS_PER_TURN := 2
const OPENING_SEQUENCE_TIME_MULTIPLIER := 2.0
const DICE_RANDOM_NUMBER_INTERVAL := 0.025
const DICE_RANDOM_NUMBER_TICKS := 20
const PIT_TARGET_LINE_DURATION := 0.25
const PIT_CARD_ATTACK_DURATION := 0.5
const CARD_TYPE_SORT_ORDER := {
	"stat": 0, "weapon": 1, "shield": 2, "training": 3,
	"blessing": 4, "heal": 5, "curse": 6, "summon": 7,
}

const PHASE_DRAW := "DRAW"
const PHASE_TRAIN := "TRAIN"
const PHASE_ATTACK := "ATTACK"
const PHASE_HEAL := "HEAL"
const PHASE_DEFEND := "DEFEND"
const PHASE_COMBAT := "CLASH"
const PHASE_GAME_OVER := "GAME OVER"
const LOG_NEUTRAL := -1
const LOG_HUMAN := 0
const LOG_COMPUTER := 1
const LOG_AUTO := -2
const SFX_BASE_VOLUME_DB := -4.0
const MUSIC_BASE_VOLUME_DB := -12.0
const GAME_OVER_BASE_VOLUME_DB := -6.0
const PIT_START_VOLUME := 0.8
const SUPPORTED_FACTION_EFFECTS := [
	"add_attack", "add_attack_and_pierce", "add_attack_and_random_damage", "add_attack_and_self_damage",
	"add_attack_and_thorns", "add_attack_bonus_if_shielded", "add_attack_defense", "add_defense",
	"add_defense_and_evasive_once", "add_defense_counterattack_training", "add_defense_with_break_draw",
	"add_defense_with_break_heal", "add_to_lower_stat", "adjacent_allies_defense_aura",
	"attack_and_temporary_evasive", "attack_from_existing_damage", "boost_next_card", "boost_next_cards",
	"damage_all_fighters", "damage_and_chain", "damage_and_lifesteal", "damage_and_remove_weapon",
	"damage_if_wounded", "damage_players_and_draw", "discover_faction_card", "enemy_area_damage_from_chain",
	"fortify_most_damaged_ally", "heal", "heal_all_allied_fighters", "heal_all_allies_and_player",
	"heal_and_cleanse", "heal_with_chain_bonus", "other_ally_trained_gain_defense", "prevent_next_damage",
	"reduce_combat_damage_timed", "reflect_next_player_damage", "sacrifice_for_player_damage",
	"summon_and_prime_stat", "summon_copy_enemy_stat", "summon_double_chain_count", "summon_fighter",
	"summon_fighter_lifesteal", "summon_fighter_splash", "survive_combat_gain_attack",
	"survive_lethal_once", "team_attack_per_enemy", "team_temporary_attack_and_draw",
	"temporary_attack_with_recoil", "temporary_reduce_attack",
]


static func supported_faction_effects() -> Array[String]:
	return SUPPORTED_FACTION_EFFECTS.duplicate()

const SUPPORTED_UPGRADE_EFFECTS := [
	"chain_milestone_draw", "copy_enemy_third_card", "fighters_start_defense",
	"first_card_double_chain_count", "first_summon_death_player_damage",
	"first_summon_death_reborn", "heal_chains_to_ally", "kind_value_bonus",
	"lifesteal_grants_attack", "opening_hand_selection_bonus", "overheal_to_defense",
	"passive_random_fighter_damage", "passive_stack_limit",
	"passive_trigger_boost_next_card", "passive_value_bonus",
	"recycle_first_faction_card", "round_end_team_defense", "starting_faction_summon",
	"starting_heal_card", "summons_gain_attack", "summons_gain_defense",
	"trade_starting_health_for_cards", "transfer_attack_on_death",
	"unlock_full_heal_double_defense", "unlock_lightning_combo",
	"unlock_player_rebirth", "unlock_replay_last_cards", "unlock_worldforge",
]


static func supported_upgrade_effects() -> Array[String]:
	return SUPPORTED_UPGRADE_EFFECTS.duplicate()


const SUPPORTED_ARTIFACT_EFFECTS := [
	"team_attack", "team_defense", "player_damage_reduction", "enemy_death_heal",
	"weapon_bonus", "heal_bonus", "card_milestone_damage", "first_fighter_boost",
	"first_ally_death_draw", "first_curse_prevent", "player_rebirth", "blocker_thorns",
	"first_attack_bonus", "low_health_turn_heal", "opening_hand_bonus",
	"enemy_fighter_attack_penalty", "first_turn_fighter_attack", "blocker_defense",
	"starting_health_bonus", "third_fighter_boost",
]


static func supported_artifact_effects() -> Array[String]:
	return SUPPORTED_ARTIFACT_EFFECTS.duplicate()

const FIGHTER_PREFIXES := [
	"Underhanded", "Sneaky", "Despicable", "Vicious", "Scummy", "Lowdown",
	"Treacherous", "Deceitful", "Ruthless", "Unscrupulous", "Ignoble",
	"Cowardly", "Dishonorable", "Foul", "Contemptible", "Vile", "Cunning",
	"Wicked", "Malicious", "Dastardly", "Backstabbing", "Cheating", "Devious",
	"Corrupt", "Repugnant", "Detestable", "Pitiless", "Savage", "Brutal",
	"Merciless", "Sordid", "Sleazy", "Scurrilous", "Untrustworthy", "Faithless",
	"Double-crossing", "Two-faced", "Sneering", "Sneaking", "Coarse", "Vulgar",
	"Ignorant", "Slithery", "Crafty", "Dirty", "Crooked", "Lawless", "Unfair",
	"Corrupted", "Shady", "Mind-game", "Sadistic", "Cruel", "Cold-blooded",
	"Heartless", "Deceptive", "Scheming", "Conniving", "Calculating", "Insidious",
	"Sinister", "Diabolical", "Unorthodox", "Raw", "Feral", "Primal", "Wild",
	"Untamed", "Uncontrolled", "Unrefined", "Gutter", "Barbaric", "Bloodthirsty",
]

const FIGHTER_NAMES := [
	"Rex", "Gunnar", "Hunter", "Jax", "Blade", "Colt", "Brock", "Diesel",
	"Ryker", "Titus", "Maverick", "Axel", "Dane", "Knox", "Zane", "Brody",
	"Cane", "Gage", "Stone", "Ridge", "Slate", "Flint", "Rock", "Steel", "Iron",
	"Titan", "Atlas", "Thor", "Odin", "Bruce", "Butch", "Duke", "Cliff", "Mack",
	"Boone", "Briggs", "Cash", "Chance", "Clint", "Cody", "Colton", "Dallas",
	"Dash", "Drake", "Dustin", "Garrett", "Hank", "Heath", "Jack", "Jed",
	"Jesse", "Kane", "Luke", "Nash", "Pierce", "Ranger", "Reid", "Rhett",
	"Rocco", "Roy", "Shane", "Slater", "Talon", "Tate", "Tex", "Travis",
	"Trent", "Troy", "Ty", "Tyson", "Vance", "Wade", "Walker", "Wyatt", "Zeke",
	"Beau", "Bronson", "Cade", "Carter", "Clay", "Cole", "Cooper", "Dalton",
	"Dean", "Gavin", "Grant", "Hudson", "Jace", "Jake", "Lane", "Logan", "Mason",
	"Owen", "Parker", "Sawyer", "Tucker", "Weston", "Wilder", "Xander",
]

const INK := Color("#f3faff")
const MUTED := Color("#9ec3d6")
const COAL := Color("#071521")
const PANEL := Color("#102b3d")
const PANEL_LIGHT := Color("#1e5368")
const RED := Color("#ff5d73")
const RED_DARK := Color("#8f3d77")
const GOLD := Color("#ffd166")
const GREEN := Color("#4fd1a1")
const BLUE := Color("#57c7ff")
const PURPLE := Color("#a78bfa")

const GAME_TERM_TOOLTIPS := {
	"attack": "Attack sets the number of sides on a fighter's damage die during a pit scuffle.",
	"fighter": "A fighter is a trained combatant with attack, defense, equipment, curses, and persistent abilities.",
	"defense": "Defense is a fighter's total durability. Damage remains until healed and destroys the fighter at zero.",
	"block": "Every defending fighter automatically joins the pit scuffle; no blocker assignment is required.",
	"blocker": "Defending fighters automatically enter the pit when the other side attacks.",
	"trample": "When one side wins a scuffle, each survivor makes one final attack-die roll against the opposing player.",
	"poison": "Each Poison stack deals 2 damage to the cursed fighter at the start of its owner's turn.",
	"madness": "Each Madness stack adds a 25% chance that a fighter's combat damage hits itself.",
	"evasive": "Evasive fighters cannot be targeted by curses while the effect remains active.",
	"berserker": "Each Berserker stack adds a 25% chance to double combat damage.",
	"rage": "Rage is the fighter-card shorthand for the Berserker double-damage effect.",
	"zen": "Zen prevents the next damage that fighter would take.",
	"curse": "A curse is a hostile card that weakens, damages, or destroys an enemy fighter.",
	"blessing": "A blessing grants a persistent beneficial effect to a fighter.",
	"training": "Training cards grant persistent specialties. At most two may be applied per player turn.",
	"summon": "A summon creates one or more fighters without using two stat cards.",
	"pierce": "Pierce adds damage to this fighter's scuffle rolls against enemy fighters.",
	"thorns": "Thorns returns damage when this defending fighter is struck during a scuffle.",
	"lifesteal": "Lifesteal heals the fighter's player by damage that fighter deals.",
	"recoil": "Recoil damages its own fighter after that fighter attacks.",
	"artifact": "Artifacts are always-active run rewards. They persist through every later encounter.",
	"ascension": "Ascension upgrades are persistent choices purchased after victories.",
	"assault": "Assault doctrine deals 25% more damage to Engine and 20% less to Bulwark.",
	"engine": "Engine doctrine deals 25% more damage to Bulwark and 20% less to Assault.",
	"bulwark": "Bulwark doctrine deals 25% more damage to Assault and 20% less to Engine.",
	"fatigue": "Fatigue deals 5 player damage when a deck is empty and tries to draw.",
}

class ArenaBackdrop:
	extends Control

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		queue_redraw()

	func _draw() -> void:
		var size := get_rect().size
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.015, 0.055, 0.095, 0.54))
		var center := Vector2(size.x * 0.42, size.y * 0.44)
		for radius in range(620, 60, -54):
			var alpha := 0.012 + float(620 - radius) / 620.0 * 0.012
			draw_circle(center, float(radius), Color(0.18, 0.56, 0.82, alpha))
		for x in range(-200, int(size.x) + 300, 96):
			draw_line(Vector2(x, 0), Vector2(x - 480, size.y), Color(0.36, 0.78, 0.92, 0.030), 1.0)
		for y in range(50, int(size.y), 110):
			draw_line(Vector2(0, y), Vector2(size.x, y + 160), Color(0.56, 0.44, 0.88, 0.024), 1.0)
		draw_circle(center, min(size.x, size.y) * 0.28, Color(0.01, 0.01, 0.01, 0.26))
		draw_arc(center, min(size.x, size.y) * 0.28, 0, TAU, 96, Color(0.28, 0.68, 0.94, 0.18), 5.0)


class PitBackdrop:
	extends Control

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		queue_redraw()

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			queue_redraw()

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		# A translucent vignette keeps text and fighter cards legible over the
		# illustrated arena in both its banner and expanded combat crops.
		draw_rect(rect, Color(0.025, 0.018, 0.025, 0.20))
		draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, minf(52.0, size.y))), Color(0.015, 0.012, 0.018, 0.34))
		for edge in range(5):
			var inset := float(edge * 5)
			draw_rect(Rect2(Vector2(inset, inset), size - Vector2(inset * 2.0, inset * 2.0)), Color(0.0, 0.0, 0.0, 0.045), false, 5.0)


class BlockLineOverlay:
	extends Control

	var game

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if not is_instance_valid(game):
			return
		for attacker_id in game.block_assignments.keys():
			var attacker_button: Control = game.fighter_button_nodes.get(int(attacker_id))
			if not is_instance_valid(attacker_button):
				continue
			for blocker_id in game.block_assignments[attacker_id]:
				var blocker_button: Control = game.fighter_button_nodes.get(int(blocker_id))
				if not is_instance_valid(blocker_button):
					continue
				var canvas_inverse := get_global_transform_with_canvas().affine_inverse()
				var start: Vector2 = canvas_inverse * attacker_button.get_global_rect().get_center()
				var finish: Vector2 = canvas_inverse * blocker_button.get_global_rect().get_center()
				var chord: Vector2 = finish - start
				var perpendicular: Vector2 = Vector2(-chord.y, chord.x).normalized()
				var bend: float = minf(chord.length() * 0.28, 86.0) * tan(deg_to_rad(35.0))
				var control: Vector2 = (start + finish) * 0.5 + perpendicular * bend
				var curve := PackedVector2Array()
				for step in 25:
					var t := float(step) / 24.0
					var point: Vector2 = (1.0 - t) * (1.0 - t) * start + 2.0 * (1.0 - t) * t * control + t * t * finish
					curve.append(point)
				for step in range(curve.size() - 1):
					if step % 2 == 0:
						draw_line(curve[step], curve[step + 1], Color("#71e6ff"), 2.5, true)
				draw_circle(start, 5.0, Color("#71e6ff"))
				draw_circle(finish, 5.0, Color("#71e6ff"))


class PitStrikeLineOverlay:
	extends Control

	var game
	var strikes: Array[Dictionary] = []
	var progress := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if not is_instance_valid(game) or strikes.is_empty() or progress <= 0.0:
			return
		var canvas_inverse := get_global_transform_with_canvas().affine_inverse()
		for strike in strikes:
			var source: Dictionary = strike.get("source", {})
			var target: Dictionary = strike.get("target", {})
			var source_visual: Control = game.fighter_button_nodes.get(int(source.get("id", -1)))
			var target_visual: Control = game.fighter_button_nodes.get(int(target.get("id", -1)))
			if not is_instance_valid(source_visual) or not is_instance_valid(target_visual):
				continue
			var start: Vector2 = canvas_inverse * source_visual.get_global_rect().get_center()
			var finish: Vector2 = canvas_inverse * target_visual.get_global_rect().get_center()
			var line_color := Color("#54df91") if int(source.get("owner", 0)) == 0 else Color("#ff5d73")
			if start.distance_squared_to(finish) < 4.0:
				draw_arc(start, 28.0 * progress, 0.0, TAU, 24, line_color, 4.0, true)
				continue
			var drawn_finish := start.lerp(finish, progress)
			draw_line(start, drawn_finish, Color(line_color, 0.92), 4.0, true)
			draw_circle(start, 5.0, line_color)
			draw_circle(drawn_finish, 6.0, line_color)


class TurnGlowOverlay:
	extends Control

	var active := false
	var progress := 0.0
	var glow_color := Color("#ffd166")

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_process(true)

	func _process(delta: float) -> void:
		if active:
			progress = fmod(progress + delta * 0.038, 1.0)
			queue_redraw()

	func _draw() -> void:
		if not active:
			return
		var rect := Rect2(Vector2(2, 2), size - Vector2(4, 4))
		draw_rect(rect, Color(glow_color, 0.22), false, 2.0)
		var perimeter: float = maxf(1.0, 2.0 * (rect.size.x + rect.size.y))
		var start_distance: float = progress * perimeter
		var segment_length: float = minf(perimeter * 0.16, 240.0)
		var points := PackedVector2Array()
		for step in 25:
			points.append(_perimeter_point(rect, fmod(start_distance + segment_length * float(step) / 24.0, perimeter)))
		for step in range(points.size() - 1):
			if points[step].distance_to(points[step + 1]) < segment_length:
				draw_line(points[step], points[step + 1], Color(glow_color, 0.98), 5.0, true)
				draw_line(points[step], points[step + 1], Color(1.0, 0.86, 0.46, 0.28), 11.0, true)

	func _perimeter_point(rect: Rect2, distance: float) -> Vector2:
		var d := distance
		if d <= rect.size.x:
			return rect.position + Vector2(d, 0)
		d -= rect.size.x
		if d <= rect.size.y:
			return rect.position + Vector2(rect.size.x, d)
		d -= rect.size.y
		if d <= rect.size.x:
			return rect.position + Vector2(rect.size.x - d, rect.size.y)
		d -= rect.size.x
		return rect.position + Vector2(0, rect.size.y - d)


class StatusHealthBar:
	extends Control

	var health_ratio := 1.0
	var turn_active := false
	var pulse_elapsed := 0.0
	var corner_radius := 9

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_process(false)
		queue_redraw()

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			pivot_offset = size * 0.5
			queue_redraw()

	func _process(delta: float) -> void:
		if not turn_active:
			return
		pulse_elapsed += delta
		var wave := (sin(pulse_elapsed * TAU / 6.0) + 1.0) * 0.5
		scale = Vector2.ONE * (1.18 + wave * 0.02)
		queue_redraw()

	func set_health(current: int, maximum: int) -> void:
		health_ratio = clampf(float(current) / float(maxi(1, maximum)), 0.0, 1.0)
		queue_redraw()

	func set_turn_active(enabled: bool) -> void:
		if turn_active == enabled:
			return
		turn_active = enabled
		pulse_elapsed = 0.0
		set_process(enabled)
		scale = Vector2.ONE * 1.19 if enabled else Vector2.ONE
		set_meta("turn_highlight_active", enabled)
		queue_redraw()

	func _bar_style(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
		var style := StyleBoxFlat.new()
		style.bg_color = fill
		style.border_color = border
		style.set_border_width_all(width)
		style.set_corner_radius_all(radius)
		style.anti_aliasing = true
		style.corner_detail = 12
		return style

	func _draw() -> void:
		var bar_rect := Rect2(Vector2.ZERO, size)
		var background_alpha := 0.42 if turn_active else 0.28
		draw_style_box(_bar_style(Color(0.12, 0.015, 0.025, background_alpha), Color(0.58, 0.68, 0.72, 0.34), 1, corner_radius), bar_rect)
		if health_ratio <= 0.0:
			return
		var health_color := Color("#ff4057").lerp(Color("#37d67a"), health_ratio)
		if turn_active:
			health_color = health_color.lightened(0.20)
		var fill_alpha := 0.55 if turn_active else 0.34
		var fill_rect := Rect2(Vector2.ZERO, Vector2(size.x * health_ratio, size.y))
		draw_style_box(_bar_style(Color(health_color, fill_alpha), Color(health_color, 0.82 if turn_active else 0.58), 2 if turn_active else 1, corner_radius), fill_rect)
		if turn_active:
			draw_style_box(_bar_style(Color.TRANSPARENT, Color(health_color, 0.42), 2, corner_radius), bar_rect.grow(-1.0))


class FirstPlayerSpinner:
	extends Control

	var human_label: Label
	var computer_label: Label
	var wheel_angle := 0.0:
		set(value):
			wheel_angle = value
			_update_side_labels()
			queue_redraw()

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		human_label = _side_label("HUMAN")
		computer_label = _side_label("COMPUTER")
		add_child(human_label)
		add_child(computer_label)
		_update_side_labels()
		queue_redraw()

	func _side_label(caption: String) -> Label:
		var label := Label.new()
		label.text = caption
		label.size = Vector2(124, 34)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_font_size_override("font_size", 18)
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.95))
		label.add_theme_constant_override("shadow_offset_x", 2)
		label.add_theme_constant_override("shadow_offset_y", 2)
		return label

	func _update_side_labels() -> void:
		if not is_instance_valid(human_label) or not is_instance_valid(computer_label):
			return
		var radius := minf(size.x, size.y) * 0.46
		var center := size * 0.5
		human_label.position = center + Vector2.from_angle(wheel_angle + PI * 0.5) * radius * 0.50 - human_label.size * 0.5
		computer_label.position = center + Vector2.from_angle(wheel_angle + PI * 1.5) * radius * 0.50 - computer_label.size * 0.5

	func _sector(start_angle: float, span: float, radius: float) -> PackedVector2Array:
		var points := PackedVector2Array([size * 0.5])
		for step in 49:
			var angle := start_angle + span * float(step) / 48.0
			points.append(size * 0.5 + Vector2(cos(angle), sin(angle)) * radius)
		return points

	func _draw() -> void:
		var center := size * 0.5
		var radius := minf(size.x, size.y) * 0.46
		draw_circle(center, radius + 10.0, Color(0.01, 0.025, 0.045, 0.96))
		draw_colored_polygon(_sector(wheel_angle, PI, radius), Color("#28b97d"))
		draw_colored_polygon(_sector(wheel_angle + PI, PI, radius), Color("#d9415b"))
		var divider := Vector2(cos(wheel_angle), sin(wheel_angle)) * radius
		draw_line(center - divider, center + divider, Color("#fff2bd"), 5.0, true)
		draw_arc(center, radius, 0.0, TAU, 96, Color("#ffd166"), 8.0, true)
		draw_circle(center, 20.0, Color("#ffd166"))
		# The pointer is fixed; the equal player/computer halves rotate beneath it.
		var pointer := PackedVector2Array([
			center + Vector2(-18.0, -radius - 24.0),
			center + Vector2(18.0, -radius - 24.0),
			center + Vector2(0.0, -radius + 14.0),
		])
		draw_colored_polygon(pointer, Color.WHITE)


class FighterTriggerLabel:
	extends Label

	var game
	var fighter_id := -1

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_process(true)

	func _process(_delta: float) -> void:
		if not is_instance_valid(game) or not is_instance_valid(game.design_surface):
			return
		var visual: Control = game.fighter_button_nodes.get(fighter_id)
		if not is_instance_valid(visual):
			return
		var surface_inverse: Transform2D = game.design_surface.get_global_transform_with_canvas().affine_inverse()
		var fighter_center: Vector2 = surface_inverse * visual.get_global_rect().get_center()
		position = fighter_center - size * 0.5


class ParticleCloud:
	extends Control

	var origin := Vector2.ZERO
	var particle_color := Color.WHITE
	var elapsed := 0.0
	var duration := 0.24
	var particles: Array[Dictionary] = []

	func configure(center: Vector2, color: Color, cloud_duration: float = 0.24) -> void:
		origin = center
		particle_color = color
		duration = cloud_duration
		var local_rng := RandomNumberGenerator.new()
		local_rng.randomize()
		for index in 42:
			var angle := local_rng.randf_range(0.0, TAU)
			var speed := local_rng.randf_range(90.0, 310.0)
			particles.append({
				"velocity": Vector2(cos(angle), sin(angle)) * speed,
				"radius": local_rng.randf_range(3.0, 10.0),
			})

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_process(true)
		queue_redraw()

	func _process(delta: float) -> void:
		elapsed += delta
		queue_redraw()
		if elapsed >= duration:
			queue_free()

	func _draw() -> void:
		var life := clampf(1.0 - elapsed / duration, 0.0, 1.0)
		for particle in particles:
			var velocity: Vector2 = particle["velocity"]
			var position := origin + velocity * elapsed + Vector2(0, 180) * elapsed * elapsed
			var color := Color(particle_color, life)
			draw_circle(position, float(particle["radius"]) * (0.45 + life * 0.55), color)

var rng := RandomNumberGenerator.new()
var next_card_id := 1
var next_fighter_id := 1
var available_portrait_indices: Array[int] = []
var available_prefix_indices: Array[int] = []
var available_name_indices: Array[int] = []

var decks: Array = [[], []]
var hands: Array = [[], []]
var fighters: Array = [[], []]
var player_health: Array[int] = [STARTING_HEALTH, STARTING_HEALTH]

var active_player := 0
var round_number := 1
var phase := PHASE_DRAW
var has_drawn := false
var trained_this_turn := false
var squad_summoned_this_turn := false
var stat_cards_played_this_turn := 0
var fighters_trained_this_turn: Array[int] = [0, 0]
var training_cards_played_this_turn: Array[int] = [0, 0]
var cards_drawn_this_turn: Array[int] = [0, 0]
var input_locked := false
var game_over := false
var match_serial := 0

var selected_hand_indices: Array[int] = []
var selected_attacker_ids: Array[int] = []
var pending_attack_ids: Array[int] = []
var block_assignments: Dictionary = {}
var selected_defend_attacker_id := -1
var new_fighter_attack := 0
var new_fighter_defense := 0
var pending_new_fighter_cards: Dictionary = {}
var pending_new_fighter_order: Array[String] = []
var selected_healer_id := -1
var new_fighter_attack_button: Button
var new_fighter_defense_button: Button

var log_lines: Array[Dictionary] = []
var toast_tween: Tween
var design_surface: Control
var block_overlay: BlockLineOverlay
var pit_strike_overlay: PitStrikeLineOverlay
var fighter_button_nodes: Dictionary = {}
var pit_health_bar_nodes: Dictionary = {}
var pit_damage_label_nodes: Dictionary = {}
var hand_card_nodes: Dictionary = {}
var game_font: SystemFont
var fighter_atlas: Texture2D
var arena_background: Texture2D
var panel_metal_texture: Texture2D
var fighter_pit_texture: Texture2D
var sound_paths: Dictionary = {}
var sfx_players: Array[AudioStreamPlayer] = []
var next_sfx_player := 0
var music_player: AudioStreamPlayer
var pit_background_player: AudioStreamPlayer
var pit_start_player: AudioStreamPlayer
var game_over_player: AudioStreamPlayer
var music_mode := "menu"
var music_muted := false
var pit_fight_volume := 0.5
var other_audio_volume := 1.0
var pit_audio_active := false
var pit_audio_serial := 0
var pit_background_started := false
var pit_audio_fade_tween: Tween
var game_over_audio_active := false
var pit_hit_sound_count := 0
var last_one_shot := ""
var last_pit_background_path := ""
var last_pit_background_start := 0.0

var opponent_health_label: Label
var opponent_deck_label: Label
var opponent_hand_label: Label
var player_health_label: Label
var player_deck_label: Label
var player_hand_label: Label
var opponent_fighters_box: HBoxContainer
var player_fighters_box: HBoxContainer
var pit_fighters_box: HBoxContainer
var pit_panel: PanelContainer
var pit_backdrop: PitBackdrop
var fighter_lane_panels: Dictionary = {}
var hand_panel: PanelContainer
var hand_box: HBoxContainer
var phase_label: Label
var turn_label: Label
var encounter_number_label: Label
var round_number_label: Label
var prompt_label: Label
var selection_label: Label
var log_label: RichTextLabel
var log_card_lookup: Dictionary = {}
var log_card_tooltip: Control
var computer_card_reveal_slots: Dictionary = {}
var fighter_status_trigger_queue: Array[Dictionary] = []
var fighter_status_trigger_running := false
var action_button: Button
var advance_button: Button
var restart_button: Button
var settings_button: Button
var settings_layer: ColorRect
var settings_speed_buttons: Dictionary = {}
var pit_fight_volume_slider: HSlider
var pit_fight_volume_label: Label
var other_audio_volume_slider: HSlider
var other_audio_volume_label: Label
var new_match_confirmation_layer: ColorRect
var modal_paused_tree := false
var game_speed_mode := "fast"
var player_portrait_button: Button
var toast_panel: PanelContainer
var toast_label: Label
var player_status_panel: PanelContainer
var opponent_status_panel: PanelContainer
var player_health_bar: StatusHealthBar
var opponent_health_bar: StatusHealthBar
var player_turn_glow: TurnGlowOverlay
var opponent_turn_glow: TurnGlowOverlay
var turn_order_title_label: Label
var turn_order_labels: Dictionary = {}
var training_stage_panel: PanelContainer
var training_stage_name: Label
var training_stage_attack: Button
var training_stage_defense: Button
var training_animation_active := false
var training_animation_requests := 0
var training_animation_epoch := 0
var splash_layer: Control
var splash_start_button: Button
var splash_mute_button: Button
var action_flash_panel: PanelContainer
var action_flash_label: RichTextLabel
var computer_log_flash_queue: Array[String] = []
var computer_log_flash_running := false
var return_menu_button: Button
var combat_animator: CombatAnimator
var faction_layer: Control
var faction_detail_label: RichTextLabel
var faction_begin_button: Button
var selected_faction_id := ""
var faction_ids: Array[String] = ["", ""]
var faction_round_flags: Array[Dictionary] = [{}, {}]
var faction_card_plays: Array[int] = [0, 0]
var encounter_number := 1
var upgrade_points := 0
var owned_upgrade_ids: Array[String] = []
var upgrade_layer: Control
var upgrade_points_label: RichTextLabel
var upgrade_nodes_box: VBoxContainer
var encounter_enemy_fighters_killed := 0
var next_fight_button: Button
var defeat_layer: Control
var game_rules_layer: Control
var capstone_action_bar: HBoxContainer
var upgrade_battle_flags: Dictionary = {}
var upgrade_card_history: Array[Dictionary] = []
var replaying_upgrade_cards := false
var opening_discard_layer: Control
var opening_discard_box: HBoxContainer
var opening_discard_pending := false
var replayed_creation_pairs: Dictionary = {}
var card_play_history: Array = [[], []]
var pit_focus_active := false
var pit_focus_tween: Tween
var owned_artifact_ids: Array[String] = []
var artifact_bar_panel: PanelContainer
var artifact_bar: HBoxContainer
var artifact_popup: Control
var artifact_popup_art: TextureRect
var artifact_popup_name: Label
var artifact_popup_description: Label
var artifact_popup_epoch := 0
var artifact_choice_layer: ColorRect
var artifact_choice_box: HBoxContainer
var pending_artifact_choices: Array[Dictionary] = []
var artifact_battle_flags: Dictionary = {}
var artifact_run_fighters_trained := 0
var pending_fighter_entrance_ids: Dictionary = {}
var final_roll_animation_active := false
var final_roll_animation_skipped := false
var encounter_first_player := 0
var opening_attack_skip_owner := -1
var opening_attack_skip_pending := false
var first_player_roll_active := false
var round_banner_active := false
var round_banner_skipped := false


func _ready() -> void:
	Engine.time_scale = 1.0
	rng.randomize()
	fighter_atlas = load("res://assets/fighter_atlas.png")
	arena_background = load("res://assets/arena_background.png")
	panel_metal_texture = load("res://assets/ui/battered_metal_panels.png")
	fighter_pit_texture = load("res://assets/ui/fighter_pit_background.png")
	_build_interface()
	_build_artifact_ui()
	combat_animator = CombatAnimatorScript.new()
	design_surface.add_child(combat_animator)
	_build_audio_system()
	_build_splash_screen()
	_build_game_rules_overlay()
	_build_faction_selection()
	_build_upgrade_overlay()
	_build_defeat_overlay()
	_build_settings_overlay()
	_build_new_match_confirmation()
	_build_artifact_choice_overlay()
	_play_intro_music()


func _input(event: InputEvent) -> void:
	if final_roll_animation_active and event is InputEventMouseButton and event.pressed:
		final_roll_animation_skipped = true
		final_roll_animation_active = false
		get_viewport().set_input_as_handled()
	elif round_banner_active and event is InputEventMouseButton and event.pressed:
		round_banner_skipped = true
		get_viewport().set_input_as_handled()


func _build_audio_system() -> void:
	_refresh_sound_paths()
	for index in 6:
		var player := AudioStreamPlayer.new()
		player.name = "SoundEffect%02d" % (index + 1)
		player.volume_db = SFX_BASE_VOLUME_DB
		add_child(player)
		sfx_players.append(player)
	music_player = AudioStreamPlayer.new()
	music_player.name = "BackgroundMusic"
	music_player.volume_db = MUSIC_BASE_VOLUME_DB
	music_player.finished.connect(_on_music_finished)
	add_child(music_player)
	pit_background_player = AudioStreamPlayer.new()
	pit_background_player.name = "PitBackgroundLoop"
	pit_background_player.bus = &"Master"
	pit_background_player.volume_db = linear_to_db(pit_fight_volume)
	add_child(pit_background_player)
	pit_start_player = AudioStreamPlayer.new()
	pit_start_player.name = "PitStartCue"
	pit_start_player.volume_db = linear_to_db(PIT_START_VOLUME)
	add_child(pit_start_player)
	game_over_player = AudioStreamPlayer.new()
	game_over_player.name = "GameOverMusic"
	game_over_player.volume_db = GAME_OVER_BASE_VOLUME_DB
	game_over_player.finished.connect(_on_game_over_music_finished)
	add_child(game_over_player)
	_apply_audio_levels()


func _refresh_sound_paths() -> void:
	# Query the filesystem at startup instead of relying on imported-resource
	# metadata. This immediately includes newly added WAV/MP3 files and drops
	# paths for files that have been removed from sounds/.
	var categories := ["attacking", "blocking", "draw_a_card", "curse", "blessing", "background_music", "FIGHTBG", "game over", "intro_music", "oneshot", "PITSTART"]
	for category in categories:
		var folder := "res://sounds/%s" % category
		sound_paths[category] = _audio_files_in_folder(folder)
	var pit_hits: Array[String] = []
	pit_hits.append_array(sound_paths.get("attacking", []))
	pit_hits.append_array(sound_paths.get("blocking", []))
	pit_hits.append_array(_audio_files_in_folder("res://sounds"))
	sound_paths["pit_hit"] = pit_hits


func _audio_files_in_folder(folder: String) -> Array[String]:
	var files: Array[String] = []
	if not DirAccess.dir_exists_absolute(folder):
		return files
	for filename in DirAccess.get_files_at(folder):
		var extension := String(filename).get_extension().to_lower()
		if extension == "wav" or extension == "mp3":
			files.append(folder.path_join(filename))
	return files


func _play_random_sound(category: String, pitch_scale: float = 1.0) -> AudioStreamPlayer:
	var candidates: Array = sound_paths.get(category, [])
	if candidates.is_empty() or sfx_players.is_empty():
		return null
	var path: String = candidates[rng.randi_range(0, candidates.size() - 1)]
	var stream := _load_audio_file(path)
	if stream == null:
		return null
	var player := sfx_players[next_sfx_player]
	next_sfx_player = (next_sfx_player + 1) % sfx_players.size()
	player.stream = stream
	# These players are pooled, so always restore ordinary sounds to their normal
	# sample rate after a deliberately slowed, pitch-shifted lethal strike.
	player.pitch_scale = clampf(pitch_scale, 0.01, 4.0)
	player.set_meta("sound_category", category)
	player.set_meta("source_path", path)
	if category == "pit_hit":
		pit_hit_sound_count += 1
	player.play()
	return player


func _play_one_shot(filename: String) -> void:
	var path := "res://sounds/oneshot/%s" % filename
	if not FileAccess.file_exists(path) or sfx_players.is_empty():
		return
	var stream := _load_audio_file(path)
	if stream == null:
		return
	last_one_shot = filename
	var player := sfx_players[next_sfx_player]
	next_sfx_player = (next_sfx_player + 1) % sfx_players.size()
	player.stream = stream
	player.pitch_scale = 1.0
	player.play()


func _start_pit_audio() -> void:
	if pit_audio_fade_tween and pit_audio_fade_tween.is_valid():
		pit_audio_fade_tween.kill()
	_refresh_sound_paths()
	if pit_audio_active:
		print("[PIT AUDIO] Start ignored because pit audio is already active. Background=%s playing=%s position=%.3f" % [last_pit_background_path, pit_background_player.playing if is_instance_valid(pit_background_player) else false, pit_background_player.get_playback_position() if is_instance_valid(pit_background_player) else 0.0])
		return
	pit_audio_active = true
	pit_audio_serial += 1
	pit_background_started = false
	# Start the fight bed immediately with the pit-start cue. These are separate
	# players so the cue can finish while the background track keeps looping.
	_start_pit_background_loop()
	var candidates: Array = sound_paths.get("PITSTART", [])
	if candidates.is_empty() or not is_instance_valid(pit_start_player):
		push_error("[PIT AUDIO] PITSTART failed: candidates=%d player_valid=%s" % [candidates.size(), is_instance_valid(pit_start_player)])
		return
	var path: String = candidates[rng.randi_range(0, candidates.size() - 1)]
	var stream := _load_audio_file(path)
	if stream == null:
		push_error("[PIT AUDIO] Could not load PITSTART resource: %s" % path)
		return
	last_one_shot = path.get_file()
	pit_start_player.stream = stream
	# Pit audio is a combat effect, so the menu's music-mute state must not
	# silently pause it while the rest of the combat effects remain audible.
	pit_start_player.stream_paused = false
	pit_start_player.play()
	print("[PIT AUDIO] PITSTART playing: %s playing=%s paused=%s" % [path, pit_start_player.playing, pit_start_player.stream_paused])


func _start_pit_background_loop() -> void:
	if not pit_audio_active or pit_background_started:
		return
	var candidates: Array = sound_paths.get("FIGHTBG", [])
	if candidates.is_empty() or not is_instance_valid(pit_background_player):
		push_error("[PIT AUDIO] FIGHTBG failed: candidates=%d player_valid=%s scanned=%s" % [candidates.size(), is_instance_valid(pit_background_player), str(sound_paths.get("FIGHTBG", []))])
		return
	var path: String = String(candidates[rng.randi_range(0, candidates.size() - 1)])
	var stream := _load_audio_file(path)
	if stream == null:
		push_error("[PIT AUDIO] Could not load FIGHTBG resource: %s (ResourceLoader.exists=%s file_exists=%s)" % [path, ResourceLoader.exists(path), FileAccess.file_exists(path)])
		return
	if stream is AudioStreamWAV:
		var wav := stream as AudioStreamWAV
		wav.loop_begin = 0
		wav.loop_end = maxi(1, int(round(wav.get_length() * float(wav.mix_rate))))
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	elif stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	pit_background_player.stream = stream
	pit_background_player.volume_db = linear_to_db(pit_fight_volume)
	pit_background_player.pitch_scale = 1.0
	pit_background_player.stream_paused = false
	last_pit_background_start = rng.randf_range(0.0, maxf(0.0, stream.get_length() - 0.05))
	pit_background_player.play(last_pit_background_start)
	pit_background_started = true
	last_pit_background_path = path
	print("[PIT AUDIO] FIGHTBG playing: %s type=%s length=%.3f start=%.3f volume=%d%% playing=%s paused=%s loop=%s" % [path, stream.get_class(), stream.get_length(), last_pit_background_start, roundi(pit_fight_volume * 100.0), pit_background_player.playing, pit_background_player.stream_paused, (stream as AudioStreamWAV).loop_mode if stream is AudioStreamWAV else (stream as AudioStreamMP3).loop if stream is AudioStreamMP3 else false])
	_verify_pit_background_output(path, pit_audio_serial)


func _verify_pit_background_output(path: String, audio_serial: int) -> void:
	await get_tree().create_timer(0.25).timeout
	if audio_serial != pit_audio_serial or not pit_audio_active:
		return
	if not is_instance_valid(pit_background_player) or not pit_background_player.playing or pit_background_player.stream_paused or pit_background_player.get_playback_position() <= 0.0:
		push_error("[PIT AUDIO] FIGHTBG output verification FAILED: %s valid=%s playing=%s paused=%s position=%.3f" % [path, is_instance_valid(pit_background_player), pit_background_player.playing if is_instance_valid(pit_background_player) else false, pit_background_player.stream_paused if is_instance_valid(pit_background_player) else true, pit_background_player.get_playback_position() if is_instance_valid(pit_background_player) else 0.0])
	else:
		print("[PIT AUDIO] FIGHTBG output verified: %s position=%.3f" % [path, pit_background_player.get_playback_position()])


func _stop_pit_audio(fade_out: bool = false) -> void:
	if pit_audio_active:
		print("[PIT AUDIO] Stopping pit audio: background=%s position=%.3f" % [last_pit_background_path, pit_background_player.get_playback_position() if is_instance_valid(pit_background_player) else 0.0])
	pit_audio_active = false
	pit_audio_serial += 1
	var stop_serial := pit_audio_serial
	pit_background_started = false
	if pit_audio_fade_tween and pit_audio_fade_tween.is_valid():
		pit_audio_fade_tween.kill()
	if is_instance_valid(pit_start_player):
		pit_start_player.stop()
	if is_instance_valid(pit_background_player):
		if fade_out and pit_background_player.playing:
			pit_audio_fade_tween = create_tween()
			pit_audio_fade_tween.tween_property(pit_background_player, "volume_db", -80.0, 1.0)
			pit_audio_fade_tween.tween_callback(func() -> void:
				if stop_serial == pit_audio_serial and is_instance_valid(pit_background_player):
					pit_background_player.stop()
					_apply_audio_levels()
			)
		else:
			pit_background_player.stop()
			_apply_audio_levels()


func _start_game_over_audio() -> void:
	_refresh_sound_paths()
	game_over_audio_active = true
	if is_instance_valid(music_player):
		music_player.stop()
	var candidates: Array = sound_paths.get("game over", [])
	if candidates.is_empty() or not is_instance_valid(game_over_player):
		return
	var stream := _load_audio_file(String(candidates[rng.randi_range(0, candidates.size() - 1)]))
	if stream == null:
		return
	game_over_player.stream = stream
	game_over_player.stream_paused = music_muted
	game_over_player.play()


func _stop_game_over_audio() -> void:
	game_over_audio_active = false
	if is_instance_valid(game_over_player):
		game_over_player.stop()


func _on_game_over_music_finished() -> void:
	if game_over_audio_active:
		_start_game_over_audio()


func _play_background_music() -> void:
	if not is_instance_valid(music_player):
		return
	music_mode = "match"
	var candidates: Array = sound_paths.get("background_music", [])
	if candidates.is_empty():
		return
	var path: String = candidates[rng.randi_range(0, candidates.size() - 1)]
	var stream := _load_audio_file(path)
	if stream == null:
		return
	music_player.stream = stream
	music_player.play()
	music_player.stream_paused = music_muted


func _play_intro_music() -> void:
	_refresh_sound_paths()
	if not is_instance_valid(music_player):
		return
	music_mode = "menu"
	var candidates: Array = sound_paths.get("intro_music", [])
	if candidates.is_empty():
		return
	var stream := _load_audio_file(String(candidates[rng.randi_range(0, candidates.size() - 1)]))
	if stream == null:
		return
	music_player.stop()
	music_player.stream = stream
	music_player.play()
	music_player.stream_paused = music_muted


func _on_music_finished() -> void:
	if music_mode == "menu":
		_play_intro_music()
	else:
		_play_background_music()


func _load_audio_file(path: String) -> AudioStream:
	var disk_path := ProjectSettings.globalize_path(path)
	match path.get_extension().to_lower():
		"wav":
			# Use the original PCM WAV when running from the project directory.
			# Godot's compressed imported copies of the FIGHTBG files report a
			# 30-second duration but terminate in under two seconds on Windows.
			if FileAccess.file_exists(disk_path):
				var wav := AudioStreamWAV.load_from_file(disk_path)
				if wav != null:
					return wav
		"mp3":
			if FileAccess.file_exists(disk_path):
				var mp3 := AudioStreamMP3.load_from_file(disk_path)
				if mp3 != null:
					return mp3
	# Packaged builds load the Godot-imported resource from the PCK.
	if ResourceLoader.exists(path):
		return load(path) as AudioStream
	return null


func _build_interface() -> void:
	game_font = SystemFont.new()
	game_font.font_names = PackedStringArray(["Trebuchet MS", "Segoe UI", "Arial"])
	game_font.font_weight = 500
	game_font.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	game_font.generate_mipmaps = true
	game_font.multichannel_signed_distance_field = true
	game_font.oversampling = 4.0
	var interface_theme := Theme.new()
	interface_theme.default_font = game_font
	interface_theme.default_font_size = 14
	interface_theme.set_font("font", "TooltipLabel", game_font)
	interface_theme.set_font_size("font_size", "TooltipLabel", 45)
	interface_theme.set_color("font_color", "TooltipLabel", INK)
	var tooltip_style := _style(COAL.lightened(0.06), BLUE, 3, 10)
	tooltip_style.content_margin_left = 42
	tooltip_style.content_margin_right = 42
	tooltip_style.content_margin_top = 30
	tooltip_style.content_margin_bottom = 30
	interface_theme.set_stylebox("panel", "TooltipPanel", tooltip_style)

	# The widened 1620x900 design is rendered at 5760x3200, then shown at
	# 2880x1600. This preserves the 4x-to-2x supersampling for illustrated cards.
	design_surface = Control.new()
	design_surface.name = "SupersampledDesignSurface"
	design_surface.position = Vector2.ZERO
	design_surface.size = Vector2(1620, 900)
	design_surface.scale = Vector2(32.0 / 9.0, 32.0 / 9.0)
	design_surface.theme = interface_theme
	add_child(design_surface)

	var background_image := TextureRect.new()
	background_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background_image.texture = arena_background
	background_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background_image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	background_image.modulate = Color(0.66, 0.78, 0.92, 0.62)
	background_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	design_surface.add_child(background_image)

	var backdrop := ArenaBackdrop.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	design_surface.add_child(backdrop)

	var safe := MarginContainer.new()
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe.add_theme_constant_override("margin_left", 24)
	safe.add_theme_constant_override("margin_right", 24)
	safe.add_theme_constant_override("margin_top", 18)
	safe.add_theme_constant_override("margin_bottom", 18)
	design_surface.add_child(safe)

	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 12)
	safe.add_child(page)
	page.add_child(_build_header())

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	page.add_child(body)

	var arena := VBoxContainer.new()
	arena.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arena.add_theme_constant_override("separation", 10)
	body.add_child(arena)
	arena.add_child(_build_opponent_strip())
	arena.add_child(_build_fighter_lane(true))
	arena.add_child(_build_pit_banner())
	arena.add_child(_build_fighter_lane(false))
	arena.add_child(_build_hand())
	body.add_child(_build_command_panel())

	toast_panel = PanelContainer.new()
	toast_panel.set_anchors_preset(Control.PRESET_CENTER)
	toast_panel.offset_left = -240
	toast_panel.offset_right = 240
	toast_panel.offset_top = -42
	toast_panel.offset_bottom = 42
	toast_panel.add_theme_stylebox_override("panel", _style(COAL.lightened(0.05), GOLD, 2, 10))
	toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_panel.z_index = 900
	toast_panel.modulate.a = 0.0
	design_surface.add_child(toast_panel)
	_center_control(toast_panel, Vector2(480, 84))
	toast_label = Label.new()
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toast_label.add_theme_font_size_override("font_size", 16)
	toast_label.add_theme_color_override("font_color", INK)
	toast_panel.add_child(toast_label)

	_build_training_stage()

	block_overlay = BlockLineOverlay.new()
	block_overlay.game = self
	block_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	block_overlay.visible = false
	design_surface.add_child(block_overlay)
	pit_strike_overlay = PitStrikeLineOverlay.new()
	pit_strike_overlay.name = "PitStrikeLines"
	pit_strike_overlay.game = self
	pit_strike_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pit_strike_overlay.z_index = 180
	pit_strike_overlay.visible = false
	design_surface.add_child(pit_strike_overlay)
	_build_action_flash()

	return_menu_button = _command_button("RETURN TO MENU", BLUE.darkened(0.48))
	return_menu_button.set_anchors_preset(Control.PRESET_CENTER)
	return_menu_button.offset_left = -130
	return_menu_button.offset_right = 130
	return_menu_button.offset_top = 82
	return_menu_button.offset_bottom = 136
	return_menu_button.add_theme_font_size_override("font_size", 18)
	return_menu_button.visible = false
	return_menu_button.pressed.connect(_return_to_menu)
	design_surface.add_child(return_menu_button)
	_center_control(return_menu_button, Vector2(260, 54))
	return_menu_button.offset_top += 109
	return_menu_button.offset_bottom += 109


func _build_action_flash() -> void:
	action_flash_panel = PanelContainer.new()
	action_flash_panel.set_anchors_preset(Control.PRESET_CENTER)
	action_flash_panel.offset_left = -390
	action_flash_panel.offset_right = 390
	action_flash_panel.offset_top = -74
	action_flash_panel.offset_bottom = 74
	action_flash_panel.add_theme_stylebox_override("panel", _style(Color(0.025, 0.10, 0.16, 0.96), PURPLE, 3, 12))
	action_flash_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	action_flash_panel.z_index = 900
	action_flash_panel.modulate.a = 0.0
	design_surface.add_child(action_flash_panel)
	_center_control(action_flash_panel, Vector2(780, 148))
	action_flash_label = RichTextLabel.new()
	action_flash_label.bbcode_enabled = true
	action_flash_label.fit_content = false
	action_flash_label.scroll_active = false
	action_flash_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	action_flash_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	action_flash_label.add_theme_font_size_override("normal_font_size", 32)
	action_flash_label.add_theme_color_override("default_color", INK)
	action_flash_panel.add_child(action_flash_label)


func _build_artifact_ui() -> void:
	artifact_bar_panel = PanelContainer.new()
	artifact_bar_panel.name = "ArtifactBar"
	artifact_bar_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	artifact_bar_panel.position = Vector2(10, 8)
	artifact_bar_panel.custom_minimum_size = Vector2(520, 54)
	artifact_bar_panel.add_theme_stylebox_override("panel", _style(Color(0.025, 0.055, 0.08, 0.94), GOLD.darkened(0.25), 2, 9))
	design_surface.add_child(artifact_bar_panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	artifact_bar_panel.add_child(row)
	var title := Label.new()
	title.text = "ARTIFACTS"
	title.add_theme_font_size_override("font_size", 10)
	title.add_theme_color_override("font_color", GOLD)
	row.add_child(title)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(420, 44)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	row.add_child(scroll)
	artifact_bar = HBoxContainer.new()
	artifact_bar.add_theme_constant_override("separation", 5)
	scroll.add_child(artifact_bar)

	var popup_button := Button.new()
	artifact_popup = popup_button
	popup_button.name = "ArtifactDropPopup"
	popup_button.set_anchors_preset(Control.PRESET_CENTER)
	popup_button.offset_left = -330
	popup_button.offset_right = 330
	popup_button.offset_top = -145
	popup_button.offset_bottom = 145
	popup_button.text = ""
	popup_button.add_theme_stylebox_override("normal", _style(Color(0.025, 0.045, 0.075, 0.99), GOLD, 4, 16))
	popup_button.add_theme_stylebox_override("hover", _style(Color(0.04, 0.075, 0.11, 0.99), Color("#fff0a6"), 4, 16))
	popup_button.pressed.connect(_dismiss_artifact_popup)
	popup_button.visible = false
	design_surface.add_child(popup_button)
	_center_control(popup_button, Vector2(660, 290))
	var popup_margin := MarginContainer.new()
	popup_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	popup_margin.add_theme_constant_override("margin_left", 26)
	popup_margin.add_theme_constant_override("margin_right", 26)
	popup_margin.add_theme_constant_override("margin_top", 22)
	popup_margin.add_theme_constant_override("margin_bottom", 22)
	popup_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup_button.add_child(popup_margin)
	var popup_row := HBoxContainer.new()
	popup_row.add_theme_constant_override("separation", 24)
	popup_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup_margin.add_child(popup_row)
	artifact_popup_art = TextureRect.new()
	artifact_popup_art.custom_minimum_size = Vector2(210, 210)
	artifact_popup_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artifact_popup_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	artifact_popup_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup_row.add_child(artifact_popup_art)
	var text_column := VBoxContainer.new()
	text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_column.alignment = BoxContainer.ALIGNMENT_CENTER
	text_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup_row.add_child(text_column)
	var drop_heading := Label.new()
	drop_heading.text = "ARTIFACT ACQUIRED"
	drop_heading.add_theme_font_size_override("font_size", 17)
	drop_heading.add_theme_color_override("font_color", GOLD)
	text_column.add_child(drop_heading)
	artifact_popup_name = Label.new()
	artifact_popup_name.add_theme_font_size_override("font_size", 28)
	artifact_popup_name.add_theme_color_override("font_color", INK)
	artifact_popup_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_column.add_child(artifact_popup_name)
	artifact_popup_description = Label.new()
	artifact_popup_description.add_theme_font_size_override("font_size", 16)
	artifact_popup_description.add_theme_color_override("font_color", MUTED)
	artifact_popup_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	artifact_popup_description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_column.add_child(artifact_popup_description)
	var dismiss := Label.new()
	dismiss.text = "CLICK TO CONTINUE  //  AUTO-CLOSES IN 3 SECONDS"
	dismiss.add_theme_font_size_override("font_size", 10)
	dismiss.add_theme_color_override("font_color", Color(MUTED, 0.8))
	text_column.add_child(dismiss)
	_refresh_artifact_bar()


func _build_artifact_choice_overlay() -> void:
	artifact_choice_layer = ColorRect.new()
	artifact_choice_layer.name = "ArtifactChoiceOverlay"
	artifact_choice_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	artifact_choice_layer.color = Color(0.012, 0.025, 0.045, 0.96)
	artifact_choice_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	artifact_choice_layer.visible = false
	design_surface.add_child(artifact_choice_layer)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 100)
	margin.add_theme_constant_override("margin_right", 100)
	margin.add_theme_constant_override("margin_top", 70)
	margin.add_theme_constant_override("margin_bottom", 70)
	artifact_choice_layer.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 22)
	margin.add_child(column)
	var title := Label.new()
	title.text = "VICTORY  //  CHOOSE ONE ARTIFACT"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", GOLD)
	column.add_child(title)
	var hint := Label.new()
	hint.text = "The chosen artifact remains active for every later encounter in this run."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", MUTED)
	column.add_child(hint)
	artifact_choice_box = HBoxContainer.new()
	artifact_choice_box.alignment = BoxContainer.ALIGNMENT_CENTER
	artifact_choice_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	artifact_choice_box.add_theme_constant_override("separation", 22)
	column.add_child(artifact_choice_box)


func _offer_artifact_choices() -> void:
	if not is_instance_valid(artifact_choice_layer):
		return
	_play_one_shot("LEVELUP.mp3")
	pending_artifact_choices.clear()
	var unowned: Array = ArtifactData.all_artifacts().filter(func(item: Dictionary) -> bool: return not (String(item["id"]) in owned_artifact_ids))
	var pool: Array = unowned.duplicate(true)
	if pool.size() < 3:
		for artifact in ArtifactData.all_artifacts():
			if not pool.any(func(item: Dictionary) -> bool: return String(item["id"]) == String(artifact["id"])):
				pool.append(artifact)
	while not pool.is_empty() and pending_artifact_choices.size() < 3:
		pending_artifact_choices.append(pool.pop_at(rng.randi_range(0, pool.size() - 1)))
	_clear_container(artifact_choice_box)
	for artifact in pending_artifact_choices:
		var button := Button.new()
		button.name = "ArtifactChoice_%s" % artifact["id"]
		button.custom_minimum_size = Vector2(390, 530)
		button.text = ""
		button.add_theme_stylebox_override("normal", _style(Color(0.025, 0.055, 0.085, 0.99), GOLD.darkened(0.25), 2, 14))
		button.add_theme_stylebox_override("hover", _style(Color(0.05, 0.10, 0.14, 0.99), GOLD, 4, 14))
		button.pressed.connect(_select_artifact_reward.bind(String(artifact["id"])))
		artifact_choice_box.add_child(button)
		var card_margin := MarginContainer.new()
		card_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		card_margin.add_theme_constant_override("margin_left", 20)
		card_margin.add_theme_constant_override("margin_right", 20)
		card_margin.add_theme_constant_override("margin_top", 20)
		card_margin.add_theme_constant_override("margin_bottom", 20)
		card_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(card_margin)
		var content := VBoxContainer.new()
		content.add_theme_constant_override("separation", 14)
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_margin.add_child(content)
		var art := TextureRect.new()
		art.custom_minimum_size = Vector2(330, 300)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var path := _artifact_art_path(String(artifact["id"]))
		art.texture = load(path) if ResourceLoader.exists(path) else null
		content.add_child(art)
		var name_label := Label.new()
		name_label.text = String(artifact["name"]).to_upper()
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_label.add_theme_font_size_override("font_size", 24)
		name_label.add_theme_color_override("font_color", GOLD)
		content.add_child(name_label)
		var description := Label.new()
		description.text = String(artifact["description"])
		description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.add_theme_font_size_override("font_size", 15)
		description.add_theme_color_override("font_color", INK)
		content.add_child(description)
		var icon_center := CenterContainer.new()
		icon_center.name = "ArtifactChoiceIconArea"
		icon_center.custom_minimum_size.y = 176
		icon_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
		icon_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(icon_center)
		var artifact_icon := TextureRect.new()
		artifact_icon.name = "ArtifactChoiceIcon"
		artifact_icon.custom_minimum_size = Vector2(168, 168)
		artifact_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		artifact_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		artifact_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		artifact_icon.texture = art.texture
		icon_center.add_child(artifact_icon)
	artifact_choice_layer.visible = true
	artifact_choice_layer.move_to_front()


func _artifact_art_path(artifact_id: String) -> String:
	return "res://assets/artifacts/%s.png" % artifact_id


func _refresh_artifact_bar() -> void:
	if not is_instance_valid(artifact_bar):
		return
	_clear_container(artifact_bar)
	for artifact_id in owned_artifact_ids:
		var artifact := ArtifactData.artifact_by_id(artifact_id)
		if artifact.is_empty():
			continue
		var button := Button.new()
		button.custom_minimum_size = Vector2(42, 42)
		button.text = ""
		button.tooltip_text = "%s\n%s" % [artifact["name"], artifact["description"]]
		var path := _artifact_art_path(artifact_id)
		if ResourceLoader.exists(path):
			button.icon = load(path)
			button.expand_icon = true
		button.add_theme_stylebox_override("normal", _style(Color("#17253a"), GOLD.darkened(0.35), 1, 7))
		button.add_theme_stylebox_override("hover", _style(Color("#263e59"), GOLD, 2, 7))
		artifact_bar.add_child(button)
	artifact_bar_panel.visible = not owned_artifact_ids.is_empty()


func _artifact_total(effect: String) -> int:
	var total := 0
	for artifact_id in owned_artifact_ids:
		var artifact := ArtifactData.artifact_by_id(artifact_id)
		if String(artifact.get("effect", "")) == effect:
			total += int(artifact.get("value", 0))
	return total


func _has_artifact(effect: String) -> bool:
	return _artifact_total(effect) > 0


func _award_artifact(artifact_id: String = "") -> Dictionary:
	var artifact := ArtifactData.artifact_by_id(artifact_id)
	if artifact.is_empty():
		var candidates: Array = ArtifactData.all_artifacts().filter(func(item: Dictionary) -> bool: return not (String(item["id"]) in owned_artifact_ids))
		if candidates.is_empty():
			candidates = ArtifactData.all_artifacts()
		artifact = candidates[rng.randi_range(0, candidates.size() - 1)]
	owned_artifact_ids.append(String(artifact["id"]))
	_refresh_artifact_bar()
	_show_artifact_popup(artifact)
	_log_event("[color=#ffd166]Artifact dropped:[/color] %s — %s" % [artifact["name"], artifact["description"]])
	return artifact


func _select_artifact_reward(artifact_id: String) -> void:
	if not pending_artifact_choices.any(func(item: Dictionary) -> bool: return String(item["id"]) == artifact_id):
		return
	artifact_choice_layer.visible = false
	pending_artifact_choices.clear()
	var awarded := _award_artifact(artifact_id)
	call_deferred("_finish_victory_rewards", int(artifact_popup_epoch), String(awarded.get("id", "")), match_serial)


func _show_artifact_popup(artifact: Dictionary) -> void:
	artifact_popup_epoch += 1
	var epoch := artifact_popup_epoch
	artifact_popup_name.text = String(artifact["name"]).to_upper()
	artifact_popup_description.text = String(artifact["description"])
	var path := _artifact_art_path(String(artifact["id"]))
	artifact_popup_art.texture = load(path) if ResourceLoader.exists(path) else null
	artifact_popup.visible = true
	artifact_popup.move_to_front()
	await get_tree().create_timer(3.0).timeout
	if epoch == artifact_popup_epoch:
		_dismiss_artifact_popup()


func _dismiss_artifact_popup() -> void:
	artifact_popup_epoch += 1
	if is_instance_valid(artifact_popup):
		artifact_popup.visible = false


func _build_header() -> Control:
	var header := Control.new()
	header.custom_minimum_size.y = 54
	var canvas := header
	canvas.custom_minimum_size.y = 52
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(center)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	center.add_child(row)

	var encounter_text := Label.new()
	encounter_text.text = "ENCOUNTER"
	encounter_text.add_theme_font_size_override("font_size", 16)
	encounter_text.add_theme_color_override("font_color", INK)
	encounter_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(encounter_text)
	encounter_number_label = Label.new()
	encounter_number_label.add_theme_font_size_override("font_size", 27)
	encounter_number_label.add_theme_color_override("font_color", GOLD)
	encounter_number_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(encounter_number_label)
	var encounter_divider := Label.new()
	encounter_divider.text = "//"
	encounter_divider.add_theme_font_size_override("font_size", 16)
	encounter_divider.add_theme_color_override("font_color", MUTED)
	row.add_child(encounter_divider)
	var round_text := Label.new()
	round_text.text = "ROUND"
	round_text.add_theme_font_size_override("font_size", 16)
	round_text.add_theme_color_override("font_color", INK)
	round_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(round_text)
	round_number_label = Label.new()
	round_number_label.add_theme_font_size_override("font_size", 27)
	round_number_label.add_theme_color_override("font_color", BLUE)
	round_number_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(round_number_label)
	# These references are retained for presentation helpers, but the compact
	# header now ends at the round counter.
	turn_label = Label.new()
	turn_label.visible = false
	turn_label.add_theme_font_size_override("font_size", 16)
	turn_label.add_theme_color_override("font_color", INK)
	turn_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(turn_label)
	phase_label = Label.new()
	phase_label.visible = false
	phase_label.custom_minimum_size = Vector2(145, 42)
	phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	phase_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	phase_label.add_theme_font_size_override("font_size", 18)
	phase_label.add_theme_color_override("font_color", RED)
	row.add_child(phase_label)
	restart_button = _command_button("NEW MATCH", PANEL_LIGHT)
	restart_button.custom_minimum_size = Vector2(0, 0)
	restart_button.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	restart_button.offset_left = -116
	restart_button.offset_right = -10
	restart_button.offset_top = -14
	restart_button.offset_bottom = 14
	restart_button.add_theme_font_size_override("font_size", 10)
	restart_button.pressed.connect(_request_new_match_confirmation)
	canvas.add_child(restart_button)
	settings_button = _command_button("SETTINGS", PANEL_LIGHT.darkened(0.08))
	settings_button.custom_minimum_size = Vector2(0, 0)
	settings_button.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	settings_button.offset_left = -222
	settings_button.offset_right = -124
	settings_button.offset_top = -14
	settings_button.offset_bottom = 14
	settings_button.add_theme_font_size_override("font_size", 10)
	settings_button.pressed.connect(_show_settings)
	canvas.add_child(settings_button)
	return header


func _center_control(control: Control, dimensions: Vector2) -> void:
	control.set_anchors_preset(Control.PRESET_CENTER)
	control.offset_left = -dimensions.x * 0.5
	control.offset_right = dimensions.x * 0.5
	control.offset_top = -dimensions.y * 0.5
	control.offset_bottom = dimensions.y * 0.5


func _build_settings_overlay() -> void:
	settings_layer = ColorRect.new()
	settings_layer.name = "SettingsOverlay"
	settings_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	settings_layer.color = Color(0.008, 0.018, 0.03, 0.88)
	settings_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	settings_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	settings_layer.visible = false
	design_surface.add_child(settings_layer)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	settings_layer.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(700, 610)
	panel.add_theme_stylebox_override("panel", _style(Color(0.025, 0.055, 0.085, 0.99), BLUE, 3, 16))
	center.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 34)
	margin.add_theme_constant_override("margin_bottom", 34)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	margin.add_child(column)
	var title := Label.new()
	title.text = "SETTINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", GOLD)
	column.add_child(title)
	var speed_title := Label.new()
	speed_title.text = "GAME SPEED"
	speed_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	speed_title.add_theme_font_size_override("font_size", 19)
	speed_title.add_theme_color_override("font_color", INK)
	column.add_child(speed_title)
	var hint := Label.new()
	hint.text = "FAST is the default. MEDIUM lasts 75% longer and SLOW lasts 2.5× as long."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", MUTED)
	column.add_child(hint)
	var speed_row := HBoxContainer.new()
	speed_row.alignment = BoxContainer.ALIGNMENT_CENTER
	speed_row.add_theme_constant_override("separation", 14)
	column.add_child(speed_row)
	for mode in ["slow", "medium", "fast"]:
		var speed_button := _command_button(String(mode).to_upper(), PANEL_LIGHT)
		speed_button.custom_minimum_size = Vector2(160, 58)
		speed_button.pressed.connect(_set_game_speed.bind(String(mode)))
		speed_row.add_child(speed_button)
		settings_speed_buttons[String(mode)] = speed_button
	var pit_volume_row := HBoxContainer.new()
	pit_volume_row.add_theme_constant_override("separation", 16)
	column.add_child(pit_volume_row)
	pit_fight_volume_label = Label.new()
	pit_fight_volume_label.custom_minimum_size.x = 240
	pit_fight_volume_label.add_theme_font_size_override("font_size", 17)
	pit_fight_volume_label.add_theme_color_override("font_color", INK)
	pit_volume_row.add_child(pit_fight_volume_label)
	pit_fight_volume_slider = HSlider.new()
	pit_fight_volume_slider.name = "PitFightVolume"
	pit_fight_volume_slider.min_value = 0.0
	pit_fight_volume_slider.max_value = 100.0
	pit_fight_volume_slider.step = 1.0
	pit_fight_volume_slider.value = pit_fight_volume * 100.0
	pit_fight_volume_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pit_fight_volume_slider.custom_minimum_size.y = 40
	pit_fight_volume_slider.value_changed.connect(_set_pit_fight_volume)
	pit_volume_row.add_child(pit_fight_volume_slider)
	var other_volume_row := HBoxContainer.new()
	other_volume_row.add_theme_constant_override("separation", 16)
	column.add_child(other_volume_row)
	other_audio_volume_label = Label.new()
	other_audio_volume_label.custom_minimum_size.x = 240
	other_audio_volume_label.add_theme_font_size_override("font_size", 17)
	other_audio_volume_label.add_theme_color_override("font_color", INK)
	other_volume_row.add_child(other_audio_volume_label)
	other_audio_volume_slider = HSlider.new()
	other_audio_volume_slider.name = "OtherAudioVolume"
	other_audio_volume_slider.min_value = 0.0
	other_audio_volume_slider.max_value = 100.0
	other_audio_volume_slider.step = 1.0
	other_audio_volume_slider.value = other_audio_volume * 100.0
	other_audio_volume_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	other_audio_volume_slider.custom_minimum_size.y = 40
	other_audio_volume_slider.value_changed.connect(_set_other_audio_volume)
	other_volume_row.add_child(other_audio_volume_slider)
	var close := _command_button("CLOSE", RED_DARK)
	close.custom_minimum_size = Vector2(240, 54)
	close.pressed.connect(_hide_settings)
	column.add_child(close)
	_refresh_speed_buttons()
	_refresh_volume_labels()


func _build_new_match_confirmation() -> void:
	new_match_confirmation_layer = ColorRect.new()
	new_match_confirmation_layer.name = "NewMatchConfirmation"
	new_match_confirmation_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	new_match_confirmation_layer.color = Color(0.008, 0.012, 0.022, 0.90)
	new_match_confirmation_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	new_match_confirmation_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	new_match_confirmation_layer.visible = false
	design_surface.add_child(new_match_confirmation_layer)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	new_match_confirmation_layer.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(650, 330)
	panel.add_theme_stylebox_override("panel", _style(Color(0.055, 0.025, 0.045, 0.99), RED, 3, 16))
	center.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 44)
	margin.add_theme_constant_override("margin_right", 44)
	margin.add_theme_constant_override("margin_top", 38)
	margin.add_theme_constant_override("margin_bottom", 38)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 28)
	margin.add_child(column)
	var title := Label.new()
	title.text = "START A NEW MATCH?"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", GOLD)
	column.add_child(title)
	var warning := Label.new()
	warning.text = "Your current encounter and run progress will be abandoned."
	warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning.add_theme_font_size_override("font_size", 17)
	warning.add_theme_color_override("font_color", MUTED)
	column.add_child(warning)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 18)
	column.add_child(actions)
	var cancel := _command_button("CANCEL", PANEL_LIGHT)
	cancel.custom_minimum_size = Vector2(230, 58)
	cancel.pressed.connect(_cancel_new_match_confirmation)
	actions.add_child(cancel)
	var confirm := _command_button("NEW MATCH", RED_DARK)
	confirm.custom_minimum_size = Vector2(230, 58)
	confirm.pressed.connect(_confirm_new_match)
	actions.add_child(confirm)


func _pause_for_modal() -> void:
	if not get_tree().paused:
		modal_paused_tree = true
		get_tree().paused = true


func _resume_from_modal() -> void:
	if modal_paused_tree:
		get_tree().paused = false
		modal_paused_tree = false


func _show_settings() -> void:
	if not is_instance_valid(settings_layer):
		return
	settings_layer.visible = true
	settings_layer.move_to_front()
	_pause_for_modal()


func _hide_settings() -> void:
	if is_instance_valid(settings_layer):
		settings_layer.visible = false
	_resume_from_modal()


func _set_game_speed(mode: String) -> void:
	if mode not in ["fast", "medium", "slow"]:
		return
	game_speed_mode = mode
	Engine.time_scale = {"fast": 1.0, "medium": 1.0 / 1.75, "slow": 1.0 / 2.5}[mode]
	_refresh_speed_buttons()


func _refresh_speed_buttons() -> void:
	for mode in settings_speed_buttons:
		var button: Button = settings_speed_buttons[mode]
		button.text = "%s%s" % ["●  " if String(mode) == game_speed_mode else "", String(mode).to_upper()]
		var selected := String(mode) == game_speed_mode
		button.add_theme_stylebox_override("normal", _style(GREEN.darkened(0.56) if selected else PANEL_LIGHT, GOLD if selected else PANEL_LIGHT.lightened(0.18), 3 if selected else 1, 7))


func _set_pit_fight_volume(value: float) -> void:
	pit_fight_volume = clampf(value / 100.0, 0.0, 1.0)
	_apply_audio_levels()
	_refresh_volume_labels()


func _set_other_audio_volume(value: float) -> void:
	other_audio_volume = clampf(value / 100.0, 0.0, 1.0)
	_apply_audio_levels()
	_refresh_volume_labels()


func _scaled_audio_db(base_db: float, level: float) -> float:
	return -80.0 if level <= 0.0 else base_db + linear_to_db(level)


func _apply_audio_levels() -> void:
	if is_instance_valid(pit_background_player):
		pit_background_player.volume_db = -80.0 if pit_fight_volume <= 0.0 else linear_to_db(pit_fight_volume)
	for player in sfx_players:
		if is_instance_valid(player):
			player.volume_db = _scaled_audio_db(SFX_BASE_VOLUME_DB, other_audio_volume)
	if is_instance_valid(pit_start_player):
		pit_start_player.volume_db = _scaled_audio_db(0.0, PIT_START_VOLUME * other_audio_volume)
	if is_instance_valid(music_player):
		music_player.volume_db = _scaled_audio_db(MUSIC_BASE_VOLUME_DB, other_audio_volume)
	if is_instance_valid(game_over_player):
		game_over_player.volume_db = _scaled_audio_db(GAME_OVER_BASE_VOLUME_DB, other_audio_volume)


func _refresh_volume_labels() -> void:
	if is_instance_valid(pit_fight_volume_label):
		pit_fight_volume_label.text = "PIT FIGHT VOLUME  %d%%" % roundi(pit_fight_volume * 100.0)
	if is_instance_valid(other_audio_volume_label):
		other_audio_volume_label.text = "OTHER AUDIO  %d%%" % roundi(other_audio_volume * 100.0)


func _request_new_match_confirmation() -> void:
	if not is_instance_valid(new_match_confirmation_layer):
		return
	new_match_confirmation_layer.visible = true
	new_match_confirmation_layer.move_to_front()
	_pause_for_modal()


func _cancel_new_match_confirmation() -> void:
	if is_instance_valid(new_match_confirmation_layer):
		new_match_confirmation_layer.visible = false
	_resume_from_modal()


func _confirm_new_match() -> void:
	if is_instance_valid(new_match_confirmation_layer):
		new_match_confirmation_layer.visible = false
	_resume_from_modal()
	_show_faction_selection()


func _build_splash_screen() -> void:
	splash_layer = Control.new()
	splash_layer.name = "SplashScreen"
	splash_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	splash_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	design_surface.add_child(splash_layer)

	var image := TextureRect.new()
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image.texture = arena_background
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	splash_layer.add_child(image)

	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.035, 0.02, 0.015, 0.34)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	splash_layer.add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	splash_layer.add_child(center)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 28)
	center.add_child(column)

	var title_font := SystemFont.new()
	title_font.font_names = PackedStringArray(["Orbitron", "Audiowide", "Bank Gothic", "Eurostile", "Bahnschrift", "Segoe UI"])
	title_font.font_weight = 800
	title_font.multichannel_signed_distance_field = true
	title_font.oversampling = 4.0
	var title := Label.new()
	title.text = "PITFIGHTER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", title_font)
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", Color("#f4d070"))
	title.add_theme_color_override("font_shadow_color", Color(0.05, 0.01, 0.0, 0.92))
	title.add_theme_constant_override("shadow_offset_x", 5)
	title.add_theme_constant_override("shadow_offset_y", 5)
	column.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "ENTER THE SCRAP BOWL"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_override("font", title_font)
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", INK)
	column.add_child(subtitle)

	var button_center := CenterContainer.new()
	column.add_child(button_center)
	splash_start_button = _command_button("START", RED)
	splash_start_button.custom_minimum_size = Vector2(240, 62)
	splash_start_button.add_theme_font_override("font", title_font)
	splash_start_button.add_theme_font_size_override("font_size", 24)
	splash_start_button.pressed.connect(_on_splash_start_pressed)
	button_center.add_child(splash_start_button)

	var rules_button := _command_button("GAME RULES", BLUE.darkened(0.38))
	rules_button.custom_minimum_size = Vector2(240, 54)
	rules_button.add_theme_font_override("font", title_font)
	rules_button.add_theme_font_size_override("font_size", 18)
	rules_button.pressed.connect(_show_game_rules)
	column.add_child(rules_button)

	splash_mute_button = _command_button("MUTE MUSIC", BLUE.darkened(0.45))
	splash_mute_button.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	splash_mute_button.offset_left = 28
	splash_mute_button.offset_right = 178
	splash_mute_button.offset_top = -76
	splash_mute_button.offset_bottom = -28
	splash_mute_button.add_theme_font_size_override("font_size", 13)
	splash_mute_button.pressed.connect(_toggle_music_mute)
	splash_layer.add_child(splash_mute_button)


func _build_game_rules_overlay() -> void:
	game_rules_layer = ColorRect.new()
	game_rules_layer.name = "GameRulesOverlay"
	game_rules_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_rules_layer.color = Color(0.008, 0.018, 0.03, 0.98)
	game_rules_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	game_rules_layer.visible = false
	design_surface.add_child(game_rules_layer)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 62)
	margin.add_theme_constant_override("margin_right", 62)
	margin.add_theme_constant_override("margin_top", 34)
	margin.add_theme_constant_override("margin_bottom", 34)
	game_rules_layer.add_child(margin)
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 14)
	margin.add_child(page)
	var title := Label.new()
	title.text = "GAME RULES"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", GOLD)
	page.add_child(title)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	scroll.add_child(grid)
	var rules := [
		["GAME START", "A 50/50 spinner determines first player, who will skip the first attack phase."],
		["DRAW", "Draw up to 4 cards for a maximum of 8."],
		["TRAIN", "Build up to 1 fighter and train any existing fighters one time. All other playable cards in hand have no limit."],
		["PIT FIGHT", "Chosen fighters enter the pit and circle each other. Fighters each choose the closest fighter and roll a die with sides equal to fighter attack, dealing that much damage to the defender. The current round number indicates the number of times fighters roll and assign damage each pit fight. A pit fight ends when all rounds are over, when no fighters remain, or when only one side has fighters remaining. In the last case, each surviving fighter does one more damage roll and that damage is done to the opposing player."],
		["HEAL", "Cast any heal cards in hand on the specified target, then end your turn."],
	]
	for rule in rules:
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(720, 112 if String(rule[0]) != "PIT FIGHT" else 245)
		card.add_theme_stylebox_override("panel", _style(Color(0.035, 0.09, 0.13, 0.98), BLUE.darkened(0.15), 2, 12))
		grid.add_child(card)
		var card_margin := MarginContainer.new()
		card_margin.add_theme_constant_override("margin_left", 20)
		card_margin.add_theme_constant_override("margin_right", 20)
		card_margin.add_theme_constant_override("margin_top", 14)
		card_margin.add_theme_constant_override("margin_bottom", 14)
		card.add_child(card_margin)
		var text := Label.new()
		text.text = "%s\n%s" % [rule[0], rule[1]]
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.add_theme_font_size_override("font_size", 16)
		text.add_theme_color_override("font_color", INK)
		card_margin.add_child(text)
	var close := _command_button("BACK", RED_DARK)
	close.custom_minimum_size = Vector2(240, 52)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(_hide_game_rules)
	page.add_child(close)


func _show_game_rules() -> void:
	if is_instance_valid(game_rules_layer):
		game_rules_layer.visible = true
		game_rules_layer.move_to_front()


func _hide_game_rules() -> void:
	if is_instance_valid(game_rules_layer):
		game_rules_layer.visible = false


func _build_faction_selection() -> void:
	faction_layer = ColorRect.new()
	faction_layer.name = "FactionSelection"
	faction_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	faction_layer.color = Color(0.015, 0.035, 0.055, 0.97)
	faction_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	faction_layer.visible = false
	design_surface.add_child(faction_layer)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 90)
	margin.add_theme_constant_override("margin_right", 90)
	margin.add_theme_constant_override("margin_top", 62)
	margin.add_theme_constant_override("margin_bottom", 54)
	faction_layer.add_child(margin)
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 18)
	margin.add_child(page)
	var title := Label.new()
	title.text = "CHOOSE YOUR FACTION"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", GOLD)
	page.add_child(title)
	var rule := Label.new()
	rule.text = "ASSAULT  >  ENGINE  >  BULWARK  >  ASSAULT"
	rule.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rule.add_theme_font_size_override("font_size", 17)
	rule.add_theme_color_override("font_color", BLUE)
	page.add_child(rule)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 14)
	page.add_child(grid)
	for faction in FactionData.all_factions():
		var button := Button.new()
		button.custom_minimum_size = Vector2(450, 176)
		button.text = "%s\n%s\n\n%s" % [String(faction["name"]).to_upper(), faction["title"], String(faction["lean"]).to_upper()]
		button.add_theme_font_size_override("font_size", 17)
		var faction_color := Color(String(faction["color"]))
		button.add_theme_stylebox_override("normal", _style(faction_color.darkened(0.72), faction_color, 2, 10))
		button.add_theme_stylebox_override("hover", _style(faction_color.darkened(0.52), GOLD, 3, 10))
		button.pressed.connect(_select_faction.bind(String(faction["id"])))
		button.mouse_entered.connect(_preview_faction.bind(String(faction["id"])))
		grid.add_child(button)
		_add_faction_bitmap(button, String(faction["id"]), 0.24)
	faction_detail_label = RichTextLabel.new()
	faction_detail_label.custom_minimum_size.y = 82
	faction_detail_label.bbcode_enabled = true
	faction_detail_label.fit_content = false
	faction_detail_label.scroll_active = false
	faction_detail_label.add_theme_font_size_override("normal_font_size", 16)
	faction_detail_label.add_theme_color_override("default_color", INK)
	page.add_child(faction_detail_label)
	var begin_center := CenterContainer.new()
	page.add_child(begin_center)
	faction_begin_button = _command_button("SELECT A FACTION", RED)
	faction_begin_button.custom_minimum_size = Vector2(330, 58)
	faction_begin_button.disabled = true
	faction_begin_button.pressed.connect(_begin_selected_faction_run)
	begin_center.add_child(faction_begin_button)


func _build_upgrade_overlay() -> void:
	upgrade_layer = ColorRect.new()
	upgrade_layer.name = "VictoryUpgradeTree"
	upgrade_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	upgrade_layer.color = Color(0.02, 0.025, 0.055, 0.985)
	upgrade_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	upgrade_layer.visible = false
	design_surface.add_child(upgrade_layer)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 72)
	margin.add_theme_constant_override("margin_right", 72)
	margin.add_theme_constant_override("margin_top", 70)
	margin.add_theme_constant_override("margin_bottom", 64)
	upgrade_layer.add_child(margin)
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 24)
	margin.add_child(page)
	var title := Label.new()
	title.text = "ASCENSION  //  VICTORY FORGES POWER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", GOLD)
	page.add_child(title)
	upgrade_points_label = RichTextLabel.new()
	upgrade_points_label.bbcode_enabled = true
	upgrade_points_label.fit_content = true
	upgrade_points_label.scroll_active = false
	upgrade_points_label.custom_minimum_size.y = 34
	upgrade_points_label.add_theme_font_size_override("normal_font_size", 19)
	upgrade_points_label.add_theme_color_override("default_color", GREEN)
	page.add_child(upgrade_points_label)
	var tree_scroll := ScrollContainer.new()
	tree_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tree_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page.add_child(tree_scroll)
	upgrade_nodes_box = VBoxContainer.new()
	upgrade_nodes_box.alignment = BoxContainer.ALIGNMENT_CENTER
	upgrade_nodes_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upgrade_nodes_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	upgrade_nodes_box.add_theme_constant_override("separation", 4)
	tree_scroll.add_child(upgrade_nodes_box)
	var hint := Label.new()
	hint.text = "Computer fighter kills persist through the run and purchase upgrades. Every encounter strengthens enemy health, fighters, and card pressure."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", MUTED)
	page.add_child(hint)
	var next_center := CenterContainer.new()
	page.add_child(next_center)
	next_fight_button = _command_button("NEXT FIGHT", RED)
	next_fight_button.custom_minimum_size = Vector2(310, 58)
	next_fight_button.pressed.connect(_start_next_encounter)
	next_center.add_child(next_fight_button)
	var capstone_panel := PanelContainer.new()
	capstone_panel.name = "CapstoneActions"
	capstone_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	capstone_panel.offset_left = -900
	capstone_panel.offset_right = 900
	capstone_panel.offset_top = 14
	capstone_panel.offset_bottom = 76
	capstone_panel.custom_minimum_size = Vector2(1800, 62)
	capstone_panel.add_theme_stylebox_override("panel", _style(Color(0.025, 0.06, 0.10, 0.96), GOLD, 2, 10))
	design_surface.add_child(capstone_panel)
	capstone_action_bar = HBoxContainer.new()
	capstone_action_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	capstone_action_bar.add_theme_constant_override("separation", 10)
	capstone_panel.add_child(capstone_action_bar)
	capstone_panel.visible = false
	_build_opening_discard_overlay()


func _build_opening_discard_overlay() -> void:
	opening_discard_layer = ColorRect.new()
	opening_discard_layer.name = "DeeperScanDiscard"
	opening_discard_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	opening_discard_layer.color = Color(0.01, 0.035, 0.06, 0.985)
	opening_discard_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	opening_discard_layer.visible = false
	design_surface.add_child(opening_discard_layer)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 90)
	margin.add_theme_constant_override("margin_right", 90)
	margin.add_theme_constant_override("margin_top", 190)
	margin.add_theme_constant_override("margin_bottom", 190)
	opening_discard_layer.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 30)
	margin.add_child(column)
	var title := Label.new()
	title.text = "DEEPER SCAN  //  DISCARD EXACTLY ONE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", GOLD)
	column.add_child(title)
	var hint := Label.new()
	hint.text = "Your expanded opening hand has been scanned. Choose the one card that does not belong in this encounter."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 17)
	hint.add_theme_color_override("font_color", MUTED)
	column.add_child(hint)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	opening_discard_box = HBoxContainer.new()
	opening_discard_box.alignment = BoxContainer.ALIGNMENT_CENTER
	opening_discard_box.add_theme_constant_override("separation", 12)
	scroll.add_child(opening_discard_box)


func _show_opening_discard_overlay() -> void:
	opening_discard_pending = true
	input_locked = true
	_sort_hand_by_type_and_value(0)
	_clear_container(opening_discard_box)
	for index in hands[0].size():
		var card: Dictionary = hands[0][index]
		var button := _command_button("%s\n\n%s\n\nVALUE %d\n\nDISCARD" % [String(card["name"]).to_upper(), card.get("description", ""), int(card.get("value", 0))], _card_color(String(card.get("kind", "faction"))).darkened(0.45))
		button.custom_minimum_size = Vector2(270, 390)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(_resolve_opening_discard.bind(0, index))
		opening_discard_box.add_child(button)
	opening_discard_layer.visible = true
	opening_discard_layer.move_to_front()


func _resolve_opening_discard(owner: int, requested_index: int = -1) -> bool:
	if owner < 0 or owner >= hands.size() or hands[owner].is_empty():
		return false
	var discard_index := requested_index
	if owner == 1 or discard_index < 0 or discard_index >= hands[owner].size():
		discard_index = 0
		for index in hands[owner].size():
			if int(hands[owner][index].get("value", 0)) < int(hands[owner][discard_index].get("value", 0)):
				discard_index = index
	var discarded: Dictionary = hands[owner].pop_at(discard_index)
	_log_event("%s discards [color=#a78bfa]%s[/color] after a Deeper Scan." % [_owner_name(owner), discarded["name"]], owner)
	if owner == 0 and opening_discard_pending:
		opening_discard_pending = false
		opening_discard_layer.visible = false
		_start_first_player_roll()
	return true


func _refresh_capstone_actions() -> void:
	if not is_instance_valid(capstone_action_bar):
		return
	_clear_container(capstone_action_bar)
	var panel := capstone_action_bar.get_parent()
	var actions := [
		{"effect":"unlock_worldforge", "label":"UNLEASH WORLDFORGE"},
		{"effect":"unlock_replay_last_cards", "label":"REPLAY LAST THREE"},
		{"effect":"unlock_full_heal_double_defense", "label":"BECOME THE OCEAN"},
		{"effect":"unlock_lightning_combo", "label":"LIGHTNING COMBO ×4"},
	]
	for action in actions:
		var effect := String(action["effect"])
		if not _has_upgrade_effect(effect):
			continue
		var button := _command_button(String(action["label"]), GOLD.darkened(0.35))
		button.disabled = bool(upgrade_battle_flags.get(effect + "_used", false)) or game_over
		button.text += "  //  SPENT" if button.disabled else "  //  ONCE"
		button.pressed.connect(_activate_upgrade_capstone.bind(effect))
		capstone_action_bar.add_child(button)
	if _has_upgrade_effect("unlock_player_rebirth"):
		var rebirth := _command_button("ETERNAL NIGHT  //  %s" % ("SPENT" if upgrade_battle_flags.get("unlock_player_rebirth_used", false) else "LETHAL REBIRTH READY"), RED_DARK)
		rebirth.disabled = true
		capstone_action_bar.add_child(rebirth)
	if _has_upgrade_effect("round_end_team_defense"):
		var engine := _command_button("ETERNAL ENGINE  //  +1 DEFENSE EACH ROUND", PANEL_LIGHT)
		engine.disabled = true
		capstone_action_bar.add_child(engine)
	panel.visible = capstone_action_bar.get_child_count() > 0 and not upgrade_layer.visible
	if panel.visible:
		panel.move_to_front()


func _activate_upgrade_capstone(effect: String) -> void:
	if not _has_upgrade_effect(effect) or bool(upgrade_battle_flags.get(effect + "_used", false)) or game_over:
		return
	upgrade_battle_flags[effect + "_used"] = true
	match effect:
		"unlock_worldforge":
			fighters[0].clear()
			var summons := FactionData.cards_for_faction(faction_ids[0]).filter(func(card: Dictionary) -> bool: return card["kind"] == "summon")
			for index in mini(3, summons.size()):
				var definition: Dictionary = summons[index]
				var forged := _create_fighter(0, int(definition.get("attack", definition["value"])) + _upgrade_total("summons_gain_attack") + 2, int(definition.get("defense", definition["value"])) + _upgrade_total("summons_gain_defense") + 2)
				forged["name"] = definition["name"]
				forged["faction_summon"] = true
				fighters[0].append(forged)
				_queue_fighter_entrance(forged)
		"unlock_replay_last_cards":
			var replay_entries: Array = upgrade_card_history.slice(maxi(0, upgrade_card_history.size() - 3)).duplicate(true)
			upgrade_battle_flags["singularity_replay_order"] = []
			replayed_creation_pairs.clear()
			replaying_upgrade_cards = true
			for entry in replay_entries:
				if _replay_history_entry(entry):
					(upgrade_battle_flags["singularity_replay_order"] as Array).append(String(entry.get("name", "Card")))
			replaying_upgrade_cards = false
		"unlock_full_heal_double_defense":
			for fighter in fighters[0]:
				fighter["damage"] = 0
				var bonus := _fighter_max_defense(fighter)
				fighter["defense_bonus"] += bonus
				fighter["ocean_defense_bonus"] = int(fighter.get("ocean_defense_bonus", 0)) + bonus
			upgrade_battle_flags["ocean_round"] = round_number
		"unlock_lightning_combo":
			for strike in 4:
				var targets: Array = fighters[1].filter(func(f: Dictionary) -> bool: return not _is_dead(f))
				if targets.is_empty(): _damage_player(1, 1, 0)
				else: _apply_damage_to_fighter(targets[strike % targets.size()], 1, "Ascension Lightning")
				_record_faction_card_play(0, {"effect":"ascension_lightning", "kind":"faction", "name":"Ascension Lightning", "value":1})
	_show_toast("CAPSTONE UNLEASHED  //  %s" % effect.trim_prefix("unlock_").replace("_", " ").to_upper(), 0.8)
	_refresh_all()
	_refresh_capstone_actions()


func _replay_target(owner: int, fighter_id: int) -> Dictionary:
	if fighter_id >= 0:
		var original := _get_fighter(owner, fighter_id)
		if not original.is_empty() and not _is_dead(original):
			return original
	for fighter in fighters[owner]:
		if not _is_dead(fighter):
			return fighter
	return {}


func _replay_history_entry(entry: Dictionary) -> bool:
	var target_info: Dictionary = entry.get("target_info", {})
	var target_class := String(target_info.get("target_class", "none"))
	if target_class == "creation_slot":
		var pair_id := int(target_info.get("creation_pair_id", -1))
		if replayed_creation_pairs.has(pair_id):
			return true
		var pair_attack := int(target_info.get("pair_attack", 0))
		var pair_defense := int(target_info.get("pair_defense", 0))
		if pair_attack <= 0 or pair_defense <= 0:
			return false
		var created := _create_fighter(0, pair_attack, pair_defense)
		fighters[0].append(created)
		_queue_fighter_entrance(created)
		_notify_ally_trained(0, created)
		replayed_creation_pairs[pair_id] = true
		return true
	var card: Dictionary = entry.duplicate(true)
	card.erase("target_info")
	card.erase("play_number")
	card.erase("chain_count")
	card["_replay_resolved_value"] = int(entry.get("resolved_value", entry.get("value", 0)))
	card["id"] = next_card_id
	next_card_id += 1
	var fighter_id := int(target_info.get("fighter_id", -1))
	var target_mode := String(card.get("target", ""))
	var target_owner := int(target_info.get("original_owner", target_info.get("fallback_owner", 1 if target_mode == "enemy_fighter" or String(card.get("kind", "")) == "curse" else 0)))
	var target := _replay_target(target_owner, fighter_id)
	var original_hand_size: int = hands[0].size()
	hands[0].append(card)
	var index: int = hands[0].size() - 1
	var resolved := false
	if card.has("faction_id"):
		if target_class == "fighter" or target_mode in ["ally_fighter", "enemy_fighter", "any_fighter"]:
			if not target.is_empty(): resolved = _play_faction_card(0, index, target)
		else:
			resolved = _play_faction_card(0, index)
	else:
		match String(card.get("kind", "")):
			"weapon", "shield", "blessing", "training":
				if not target.is_empty():
					_play_support_card(0, index, target, false)
					resolved = true
			"stat":
				if not target.is_empty(): resolved = _apply_stat_upgrade(0, index, target, String(target_info.get("axis", "attack")), false)
			"curse":
				if card.get("name", "") == "Armageddon": resolved = _play_armageddon(0, index, false)
				elif not target.is_empty(): resolved = _play_curse_card(0, index, target, false, false)
			"summon":
				if card.get("name", "") == "Call in the Squad": resolved = _play_squad_card(0, index, false)
			"heal":
				if target_class == "player": resolved = _resolve_heal_on_player(0, index, false)
				elif not target.is_empty() and int(target.get("damage", 0)) > 0: resolved = _play_heal_on_fighter(0, index, target, false)
	if hands[0].size() > original_hand_size and hands[0].has(card):
		hands[0].erase(card)
	return resolved


func _build_defeat_overlay() -> void:
	defeat_layer = ColorRect.new()
	defeat_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	defeat_layer.color = Color(0.08, 0.008, 0.018, 1.0)
	defeat_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	defeat_layer.visible = false
	design_surface.add_child(defeat_layer)
	var loss_image := TextureRect.new()
	loss_image.name = "YouLoseBackground"
	loss_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	loss_image.texture = load("res://assets/YouLose.png")
	loss_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	loss_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	loss_image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	loss_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	defeat_layer.add_child(loss_image)
	var loss_shade := ColorRect.new()
	loss_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	loss_shade.color = Color(0.04, 0.0, 0.01, 0.24)
	loss_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	defeat_layer.add_child(loss_shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	defeat_layer.add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 22)
	center.add_child(column)
	var title := Label.new()
	title.text = "THE RUN ENDS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", RED)
	column.add_child(title)
	var retry := _command_button("RETRY ENCOUNTER", RED_DARK)
	retry.custom_minimum_size = Vector2(340, 58)
	retry.pressed.connect(_retry_encounter)
	column.add_child(retry)
	var new_run := _command_button("NEW FACTION RUN", BLUE.darkened(0.35))
	new_run.custom_minimum_size = Vector2(340, 58)
	new_run.pressed.connect(_show_faction_selection)
	column.add_child(new_run)
	var menu := _command_button("RETURN TO MENU", PANEL_LIGHT)
	menu.custom_minimum_size = Vector2(340, 54)
	menu.pressed.connect(_return_to_menu)
	column.add_child(menu)


func _show_faction_selection() -> void:
	_resume_from_modal()
	_stop_game_over_audio()
	_stop_pit_audio(true)
	match_serial += 1
	game_over = true
	input_locked = true
	selected_faction_id = ""
	faction_begin_button.disabled = true
	faction_begin_button.text = "SELECT A FACTION"
	faction_detail_label.text = "[center]Hover over a faction to inspect its doctrine and passive.[/center]"
	if is_instance_valid(defeat_layer):
		defeat_layer.visible = false
	if is_instance_valid(upgrade_layer):
		upgrade_layer.visible = false
	if is_instance_valid(settings_layer):
		settings_layer.visible = false
	if is_instance_valid(new_match_confirmation_layer):
		new_match_confirmation_layer.visible = false
	if is_instance_valid(artifact_choice_layer):
		artifact_choice_layer.visible = false
	pending_artifact_choices.clear()
	_dismiss_artifact_popup()
	faction_layer.visible = true
	faction_layer.move_to_front()


func _preview_faction(faction_id: String) -> void:
	var faction := FactionData.faction_by_id(faction_id)
	if faction.is_empty():
		return
	var passive: Dictionary = faction["passive"]
	faction_detail_label.text = "[center][color=%s][b]%s[/b][/color] — %s\n[b]%s:[/b] %s[/center]" % [faction["color"], faction["theme"], String(faction["lean"]).to_upper(), passive["name"], passive["description"]]


func _select_faction(faction_id: String) -> void:
	selected_faction_id = faction_id
	_preview_faction(faction_id)
	var faction := FactionData.faction_by_id(faction_id)
	faction_begin_button.disabled = false
	faction_begin_button.text = "COMMAND %s" % String(faction["name"]).to_upper()


func _begin_selected_faction_run() -> void:
	if selected_faction_id.is_empty():
		return
	encounter_number = 1
	upgrade_points = 0
	encounter_enemy_fighters_killed = 0
	owned_upgrade_ids.clear()
	owned_artifact_ids.clear()
	artifact_run_fighters_trained = 0
	_refresh_artifact_bar()
	faction_ids[0] = selected_faction_id
	var choices: Array = FactionData.all_factions().filter(func(item: Dictionary) -> bool: return item["id"] != selected_faction_id)
	faction_ids[1] = String(choices[rng.randi_range(0, choices.size() - 1)]["id"])
	faction_layer.visible = false
	if is_instance_valid(splash_layer):
		splash_layer.visible = false
	music_player.stop()
	_play_background_music()
	_start_new_game()


func _open_upgrade_tree() -> void:
	upgrade_points += encounter_enemy_fighters_killed
	encounter_enemy_fighters_killed = 0
	_play_one_shot("LEVELUP.mp3")
	upgrade_layer.visible = true
	upgrade_layer.move_to_front()
	_refresh_upgrade_tree()
	_refresh_capstone_actions()
	combat_animator.victory_flourish(upgrade_layer, "VICTORY  //  ASCEND")


func _refresh_upgrade_tree() -> void:
	if not is_instance_valid(upgrade_nodes_box):
		return
	_clear_container(upgrade_nodes_box)
	upgrade_points_label.text = "[center]ENCOUNTER %d CLEARED  //  [color=#ff9f43][font_size=23]%d COMPUTER FIGHTER KILL%s[/font_size][/color] BANKED[/center]" % [encounter_number, upgrade_points, "" if upgrade_points == 1 else "S"]
	var available_ids: Array[String] = []
	for item in UpgradeData.available_upgrades(faction_ids[0], owned_upgrade_ids):
		available_ids.append(String(item["id"]))
	var upgrades := UpgradeData.upgrades_for_faction(faction_ids[0])
	var tiers := [1, 2, 3, 5]
	for tier_index in tiers.size():
		var tier := int(tiers[tier_index])
		if tier_index > 0:
			var connector := Label.new()
			connector.text = "└──────── ◆ ────────┘"
			connector.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			connector.add_theme_font_size_override("font_size", 12)
			connector.add_theme_color_override("font_color", GOLD.darkened(0.2))
			upgrade_nodes_box.add_child(connector)
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 18)
		upgrade_nodes_box.add_child(row)
		for upgrade in upgrades:
			if int(upgrade["tier"]) != tier:
				continue
			var button := Button.new()
			button.custom_minimum_size = Vector2(330 if tier == 2 else 380, 108)
			var owned := String(upgrade["id"]) in owned_upgrade_ids
			button.text = "TIER %d  •  %s%s\n%s\n%s" % [upgrade["tier"], "✓  " if owned else "", String(upgrade["name"]).to_upper(), upgrade["description"], "OWNED" if owned else ""]
			button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			button.tooltip_text = "Requires: %s" % ("none" if upgrade["requires"].is_empty() else ", ".join(upgrade["requires"]))
			button.add_theme_font_size_override("font_size", 13)
			var purchasable := not owned and String(upgrade["id"]) in available_ids and upgrade_points >= int(upgrade["cost"])
			button.add_theme_color_override("font_color", Color.WHITE if owned else (INK if String(upgrade["id"]) in available_ids else MUTED))
			button.add_theme_color_override("font_disabled_color", Color.WHITE if owned else MUTED)
			var owned_style := _style(GREEN.darkened(0.42), GREEN.lightened(0.20), 3, 10)
			button.add_theme_stylebox_override("normal", owned_style if owned else _style(Color(0.08, 0.14, 0.22), GOLD if String(upgrade["id"]) in available_ids else PANEL_LIGHT, 2, 10))
			button.add_theme_stylebox_override("disabled", owned_style if owned else _style(Color(0.055, 0.075, 0.10), PANEL_LIGHT.darkened(0.25), 1, 10))
			button.disabled = owned or not purchasable
			if not owned:
				var kill_cost := Label.new()
				kill_cost.name = "UpgradeFighterKillCost"
				kill_cost.text = "%d FIGHTER KILLS" % int(upgrade["cost"])
				kill_cost.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
				kill_cost.offset_top = -31.0
				kill_cost.offset_bottom = -7.0
				kill_cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				kill_cost.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				kill_cost.mouse_filter = Control.MOUSE_FILTER_IGNORE
				kill_cost.add_theme_font_size_override("font_size", 17)
				kill_cost.add_theme_color_override("font_color", Color("#ff9f43"))
				button.add_child(kill_cost)
			if purchasable:
				_animate_purchasable_upgrade(button)
			elif not owned:
				_add_locked_upgrade_overlay(button)
			button.pressed.connect(_purchase_upgrade.bind(String(upgrade["id"])))
			row.add_child(button)
	next_fight_button.text = "NEXT FIGHT  //  ENCOUNTER %d" % (encounter_number + 1)


func _animate_purchasable_upgrade(button: Button) -> void:
	var pulse := create_tween().bind_node(button).set_loops()
	var pulse_update := _update_purchasable_upgrade_pulse.bind(button.get_instance_id())
	pulse.tween_method(pulse_update, 0.0, 1.0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse.tween_method(pulse_update, 1.0, 0.0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _update_purchasable_upgrade_pulse(weight: float, button_instance_id: int) -> void:
	var instance := instance_from_id(button_instance_id)
	if not instance is Button or not is_instance_valid(instance):
		return
	var button := instance as Button
	var fill := Color("#173f3a").lerp(Color("#287a55"), weight)
	var border := Color("#73e6a4").lerp(Color("#f6d76c"), weight)
	button.add_theme_stylebox_override("normal", _style(fill, border, 3, 10))
	button.add_theme_stylebox_override("hover", _style(fill.lightened(0.10), Color.WHITE, 3, 10))


func _add_locked_upgrade_overlay(button: Button) -> void:
	var lock := Label.new()
	lock.name = "UnavailableUpgradeLock"
	lock.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lock.text = "🔒"
	lock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lock.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lock.add_theme_font_size_override("font_size", 42)
	lock.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.20))
	lock.z_index = 20
	lock.set_meta("opacity", 0.20)
	button.add_child(lock)


func _purchase_upgrade(upgrade_id: String) -> void:
	var upgrade := UpgradeData.upgrade_by_id(upgrade_id)
	if upgrade.is_empty() or upgrade_id in owned_upgrade_ids or int(upgrade["cost"]) > upgrade_points:
		return
	if String(upgrade.get("effect", "")) not in SUPPORTED_UPGRADE_EFFECTS:
		push_error("Refusing inert upgrade purchase: %s" % upgrade.get("effect", ""))
		return
	var available := UpgradeData.available_upgrades(faction_ids[0], owned_upgrade_ids)
	if not available.any(func(item: Dictionary) -> bool: return item["id"] == upgrade_id):
		return
	upgrade_points -= int(upgrade["cost"])
	owned_upgrade_ids.append(upgrade_id)
	_show_toast("UPGRADE ACQUIRED  //  %s" % String(upgrade["name"]).to_upper(), 0.8)
	combat_animator.victory_flourish(upgrade_layer, String(upgrade["name"]).to_upper())
	_refresh_upgrade_tree()
	_refresh_capstone_actions()


func _start_next_encounter() -> void:
	encounter_number += 1
	var rivals := FactionData.all_factions().filter(func(item: Dictionary) -> bool: return item["id"] != faction_ids[0])
	faction_ids[1] = String(rivals[rng.randi_range(0, rivals.size() - 1)]["id"])
	upgrade_layer.visible = false
	_start_new_game()


func _retry_encounter() -> void:
	defeat_layer.visible = false
	encounter_enemy_fighters_killed = 0
	_play_background_music()
	_start_new_game()


func _has_upgrade_effect(effect: String) -> bool:
	return _upgrade_total(effect) > 0


func _upgrade_total(effect: String) -> int:
	var total := 0
	for upgrade_id in owned_upgrade_ids:
		var upgrade := UpgradeData.upgrade_by_id(upgrade_id)
		if String(upgrade.get("effect", "")) == effect:
			total += int(upgrade.get("value", 1))
	return total


func _upgrade_kind_bonus(kind: String) -> int:
	var total := 0
	for upgrade_id in owned_upgrade_ids:
		var upgrade := UpgradeData.upgrade_by_id(upgrade_id)
		if String(upgrade.get("effect", "")) == "kind_value_bonus" and String(upgrade.get("target", "")) == kind:
			total += int(upgrade.get("value", 0))
	return total


func _apply_starting_upgrades() -> void:
	if _has_upgrade_effect("trade_starting_health_for_cards"):
		for upgrade_id in owned_upgrade_ids:
			var upgrade := UpgradeData.upgrade_by_id(upgrade_id)
			if String(upgrade.get("effect", "")) == "trade_starting_health_for_cards":
				player_health[0] = maxi(1, player_health[0] - int(upgrade.get("health_cost", 0)))
				for count in int(upgrade.get("value", 0)):
					_draw_card(0, false, false)
	if _has_upgrade_effect("starting_faction_summon"):
		for index in range(decks[0].size() - 1, -1, -1):
			if decks[0][index].has("faction_id") and decks[0][index]["kind"] == "summon" and hands[0].size() < MAX_HAND:
				hands[0].append(decks[0].pop_at(index))
				break
	if _has_upgrade_effect("starting_heal_card") and hands[0].size() < MAX_HAND:
		hands[0].append(_new_card("heal", "Small Heal", 5, "Restore 5 health to a fighter or player."))


func _toggle_music_mute() -> void:
	music_muted = not music_muted
	if is_instance_valid(music_player):
		music_player.stream_paused = music_muted
	if is_instance_valid(game_over_player):
		game_over_player.stream_paused = music_muted
	if is_instance_valid(splash_mute_button):
		splash_mute_button.text = "UNMUTE MUSIC" if music_muted else "MUTE MUSIC"


func _on_splash_start_pressed() -> void:
	if not is_instance_valid(splash_layer) or not splash_layer.visible:
		return
	splash_start_button.disabled = true
	_hide_game_rules()
	var fade := create_tween()
	fade.tween_property(splash_layer, "modulate:a", 0.0, 0.32)
	await fade.finished
	splash_layer.visible = false
	if is_instance_valid(return_menu_button):
		return_menu_button.visible = false
	_show_faction_selection()


func _return_to_menu() -> void:
	_resume_from_modal()
	_stop_pit_audio(true)
	_stop_game_over_audio()
	match_serial += 1
	input_locked = true
	game_over = true
	_reset_training_stage()
	if is_instance_valid(return_menu_button):
		return_menu_button.visible = false
	if is_instance_valid(action_flash_panel):
		action_flash_panel.modulate.a = 0.0
	if is_instance_valid(faction_layer):
		faction_layer.visible = false
	if is_instance_valid(upgrade_layer):
		upgrade_layer.visible = false
	if is_instance_valid(defeat_layer):
		defeat_layer.visible = false
	if is_instance_valid(settings_layer):
		settings_layer.visible = false
	if is_instance_valid(game_rules_layer):
		game_rules_layer.visible = false
	if is_instance_valid(new_match_confirmation_layer):
		new_match_confirmation_layer.visible = false
	if is_instance_valid(artifact_choice_layer):
		artifact_choice_layer.visible = false
	pending_artifact_choices.clear()
	_dismiss_artifact_popup()
	computer_log_flash_queue.clear()
	computer_log_flash_running = false
	splash_layer.modulate = Color.WHITE
	splash_layer.visible = true
	splash_start_button.disabled = false
	music_player.stop()
	_play_intro_music()


func _build_opponent_strip() -> Control:
	var outer := PanelContainer.new()
	outer.name = "CombinedPlayerStatus"
	outer.custom_minimum_size.y = 74
	outer.add_theme_stylebox_override("panel", _style(Color(0.02, 0.08, 0.12, 0.08), PANEL_LIGHT, 2, 9))
	_add_panel_metal(outer, 0.78)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_bottom", 7)
	outer.add_child(margin)
	var split := HBoxContainer.new()
	split.add_theme_constant_override("separation", 12)
	margin.add_child(split)

	opponent_status_panel = PanelContainer.new()
	opponent_status_panel.name = "ComputerStatusHalf"
	opponent_status_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	opponent_status_panel.add_theme_stylebox_override("panel", _style(Color(0.20, 0.04, 0.12, 0.06), Color.TRANSPARENT, 0, 7))
	split.add_child(opponent_status_panel)
	opponent_health_bar = StatusHealthBar.new()
	opponent_health_bar.name = "ComputerHealthBar"
	opponent_health_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	opponent_status_panel.add_child(opponent_health_bar)
	var opponent_row := HBoxContainer.new()
	opponent_row.add_theme_constant_override("separation", 12)
	opponent_status_panel.add_child(opponent_row)
	var opponent_identity := HBoxContainer.new()
	opponent_identity.add_theme_constant_override("separation", 12)
	opponent_row.add_child(opponent_identity)
	var opponent_badge := Label.new()
	opponent_badge.text = "THIS COMPUTER"
	opponent_badge.add_theme_font_size_override("font_size", 16)
	opponent_badge.add_theme_color_override("font_color", RED)
	opponent_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	opponent_identity.add_child(opponent_badge)
	opponent_health_label = _stat_label("20 HP", RED)
	opponent_health_label.add_theme_font_size_override("font_size", 32)
	opponent_identity.add_child(opponent_health_label)
	var opponent_spacer := Control.new()
	opponent_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	opponent_row.add_child(opponent_spacer)
	var opponent_counts := HBoxContainer.new()
	opponent_counts.alignment = BoxContainer.ALIGNMENT_END
	opponent_counts.add_theme_constant_override("separation", 9)
	opponent_row.add_child(opponent_counts)
	opponent_hand_label = _stat_label("HAND 7", INK)
	opponent_counts.add_child(opponent_hand_label)
	opponent_deck_label = _stat_label("DECK 81", MUTED)
	opponent_counts.add_child(opponent_deck_label)

	var divider := VSeparator.new()
	divider.custom_minimum_size.x = 3
	divider.add_theme_color_override("separator", Color(0.46, 0.68, 0.76, 0.70))
	split.add_child(divider)

	player_status_panel = PanelContainer.new()
	player_status_panel.name = "HumanStatusHalf"
	player_status_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	player_status_panel.add_theme_stylebox_override("panel", _style(Color(0.04, 0.18, 0.20, 0.06), Color.TRANSPARENT, 0, 7))
	split.add_child(player_status_panel)
	player_health_bar = StatusHealthBar.new()
	player_health_bar.name = "HumanHealthBar"
	player_health_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	player_status_panel.add_child(player_health_bar)
	var player_row := HBoxContainer.new()
	player_row.add_theme_constant_override("separation", 12)
	player_status_panel.add_child(player_row)
	var player_identity := HBoxContainer.new()
	player_identity.add_theme_constant_override("separation", 12)
	player_row.add_child(player_identity)
	player_portrait_button = Button.new()
	player_portrait_button.text = "YOU"
	player_portrait_button.tooltip_text = "Select your life total as a healing target."
	player_portrait_button.add_theme_font_size_override("font_size", 16)
	player_portrait_button.add_theme_color_override("font_color", GOLD)
	player_portrait_button.add_theme_stylebox_override("normal", _style(Color(0.02, 0.12, 0.16, 0.26), GOLD, 1, 7))
	player_portrait_button.pressed.connect(_on_player_portrait_pressed)
	player_identity.add_child(player_portrait_button)
	player_health_label = _stat_label("20 HP", GREEN)
	player_health_label.add_theme_font_size_override("font_size", 32)
	player_identity.add_child(player_health_label)
	var player_spacer := Control.new()
	player_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	player_row.add_child(player_spacer)
	var player_counts := HBoxContainer.new()
	player_counts.alignment = BoxContainer.ALIGNMENT_END
	player_counts.add_theme_constant_override("separation", 9)
	player_row.add_child(player_counts)
	player_hand_label = _stat_label("HAND 7", INK)
	player_counts.add_child(player_hand_label)
	player_deck_label = _stat_label("DECK 81", MUTED)
	player_counts.add_child(player_deck_label)
	# Human information occupies the left half; computer information occupies the
	# right. Semantic references remain attached to their original controls so
	# damage/heal/card-flight animations automatically follow the swapped sides.
	split.move_child(player_status_panel, 0)
	split.move_child(divider, 1)
	split.move_child(opponent_status_panel, 2)
	return outer


func _build_player_strip() -> Control:
	var panel := PanelContainer.new()
	player_status_panel = panel
	panel.custom_minimum_size.y = 68
	panel.add_theme_stylebox_override("panel", _style(PANEL, PANEL_LIGHT, 1, 9))
	_add_panel_metal(panel, 0.30)
	var canvas := Control.new()
	canvas.custom_minimum_size.y = 54
	panel.add_child(canvas)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(center)
	var identity := HBoxContainer.new()
	identity.add_theme_constant_override("separation", 18)
	center.add_child(identity)
	player_portrait_button = Button.new()
	player_portrait_button.text = " YOU "
	player_portrait_button.tooltip_text = "Select your life total as a healing target."
	player_portrait_button.add_theme_font_size_override("font_size", 17)
	player_portrait_button.add_theme_color_override("font_color", GOLD)
	player_portrait_button.add_theme_stylebox_override("normal", _style(PANEL_LIGHT, GOLD, 1, 7))
	player_portrait_button.pressed.connect(_on_player_portrait_pressed)
	identity.add_child(player_portrait_button)
	player_health_label = _stat_label("50 HP", GREEN)
	player_health_label.add_theme_font_size_override("font_size", 38)
	player_health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	identity.add_child(player_health_label)
	var counts := HBoxContainer.new()
	counts.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	counts.offset_left = -330
	counts.offset_right = -12
	counts.offset_top = -24
	counts.offset_bottom = 24
	counts.alignment = BoxContainer.ALIGNMENT_END
	counts.add_theme_constant_override("separation", 12)
	canvas.add_child(counts)
	player_hand_label = _stat_label("HAND 7", INK)
	player_hand_label.custom_minimum_size.x = 88
	player_hand_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	counts.add_child(player_hand_label)
	player_deck_label = _stat_label("DECK 81", MUTED)
	player_deck_label.custom_minimum_size.x = 88
	player_deck_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	counts.add_child(player_deck_label)
	return panel


func _build_fighter_lane(opponent: bool) -> Control:
	var panel := PanelContainer.new()
	# Stable cards need the same 18px health-bar headroom used by pit cards.
	panel.custom_minimum_size.y = 170
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _style(Color(0.035, 0.12, 0.18, 0.07), BLUE.darkened(0.48), 1, 9))
	_add_panel_metal(panel, 0.82)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	margin.add_child(column)
	var lane_label := Label.new()
	lane_label.text = "ENEMY FIGHTERS" if opponent else "YOUR FIGHTERS"
	lane_label.add_theme_font_size_override("font_size", 11)
	lane_label.add_theme_color_override("font_color", MUTED)
	column.add_child(lane_label)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)
	if opponent:
		opponent_fighters_box = box
		fighter_lane_panels[1] = panel
	else:
		player_fighters_box = box
		fighter_lane_panels[0] = panel
	return panel


func _build_pit_banner() -> Control:
	pit_panel = PanelContainer.new()
	pit_panel.custom_minimum_size.y = 96
	pit_panel.clip_contents = true
	pit_panel.add_theme_stylebox_override("panel", _style(Color(0.12, 0.055, 0.035, 0.97), Color("#d3652f"), 3, 13))
	var pit_image := TextureRect.new()
	pit_image.name = "FighterPitTexture"
	pit_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pit_image.texture = fighter_pit_texture
	pit_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pit_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	pit_image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	pit_image.modulate = Color(0.82, 0.86, 0.90, 0.88)
	pit_image.material = _rounded_texture_material(13.0)
	pit_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pit_panel.add_child(pit_image)
	pit_backdrop = PitBackdrop.new()
	pit_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pit_panel.add_child(pit_backdrop)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	pit_panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 5)
	margin.add_child(column)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	column.add_child(row)
	var pit := Label.new()
	pit.text = "⚔  THE FIGHTER PIT  ⚔"
	pit.add_theme_font_size_override("font_size", 24)
	pit.add_theme_color_override("font_color", Color("#ff8a45"))
	row.add_child(pit)
	var rule := VSeparator.new()
	rule.add_theme_color_override("separator", RED_DARK)
	row.add_child(rule)
	prompt_label = Label.new()
	prompt_label.text = "Draw steel. Draw blood."
	prompt_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt_label.add_theme_font_size_override("font_size", 15)
	prompt_label.add_theme_color_override("font_color", INK)
	row.add_child(prompt_label)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	pit_fighters_box = HBoxContainer.new()
	pit_fighters_box.add_theme_constant_override("separation", 12)
	pit_fighters_box.alignment = BoxContainer.ALIGNMENT_CENTER
	pit_fighters_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pit_fighters_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(pit_fighters_box)
	return pit_panel


func _build_hand() -> Control:
	hand_panel = PanelContainer.new()
	hand_panel.custom_minimum_size.y = 255
	hand_panel.add_theme_stylebox_override("panel", _style(Color(0.04, 0.13, 0.20, 0.07), PANEL_LIGHT, 1, 9))
	_add_panel_metal(hand_panel, 0.82)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	hand_panel.add_child(margin)
	var column := VBoxContainer.new()
	margin.add_child(column)
	var heading := HBoxContainer.new()
	column.add_child(heading)
	var label := Label.new()
	label.text = "YOUR HAND"
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", MUTED)
	heading.add_child(label)
	selection_label = Label.new()
	selection_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	selection_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	selection_label.add_theme_font_size_override("font_size", 11)
	selection_label.add_theme_color_override("font_color", GOLD)
	heading.add_child(selection_label)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	var hand_center := CenterContainer.new()
	hand_center.name = "CenteredHandViewport"
	hand_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hand_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(hand_center)
	hand_box = HBoxContainer.new()
	hand_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hand_box.alignment = BoxContainer.ALIGNMENT_CENTER
	hand_box.add_theme_constant_override("separation", 8)
	hand_center.add_child(hand_box)
	return hand_panel


func _build_command_panel() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 286
	panel.add_theme_stylebox_override("panel", _style(Color(0.04, 0.13, 0.20, 0.08), PANEL_LIGHT, 1, 10))
	_add_panel_metal(panel, 0.76, 10.0)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 9)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	margin.add_child(column)
	turn_order_title_label = Label.new()
	turn_order_title_label.visible = false
	var phase_entries := {
		PHASE_DRAW: "DRAW",
		PHASE_TRAIN: "TRAIN",
		PHASE_ATTACK: "PIT",
		PHASE_HEAL: "HEAL/END",
	}
	for phase_key in phase_entries:
		var item := Label.new()
		item.text = phase_entries[phase_key]
		item.custom_minimum_size.y = 18
		item.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		item.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		item.add_theme_font_size_override("font_size", 13)
		item.add_theme_color_override("font_color", MUTED)
		column.add_child(item)
		turn_order_labels[phase_key] = item
	var separator := HSeparator.new()
	column.add_child(separator)
	var log_title := Label.new()
	log_title.text = "FIGHT LOG"
	log_title.add_theme_font_size_override("font_size", 13)
	log_title.add_theme_color_override("font_color", GOLD)
	column.add_child(log_title)
	log_label = RichTextLabel.new()
	log_label.bbcode_enabled = true
	log_label.fit_content = false
	log_label.scroll_active = true
	log_label.selection_enabled = true
	log_label.context_menu_enabled = true
	log_label.shortcut_keys_enabled = true
	log_label.deselect_on_focus_loss_enabled = false
	log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_label.custom_minimum_size.y = 255
	log_label.add_theme_font_size_override("normal_font_size", 12)
	log_label.add_theme_color_override("default_color", MUTED)
	log_label.meta_hover_started.connect(_on_log_meta_hover_started)
	log_label.meta_hover_ended.connect(_on_log_meta_hover_ended)
	column.add_child(log_label)
	var orders_separator := HSeparator.new()
	column.add_child(orders_separator)
	var action_title := Label.new()
	action_title.text = "ORDERS"
	action_title.add_theme_font_size_override("font_size", 13)
	action_title.add_theme_color_override("font_color", GOLD)
	column.add_child(action_title)
	var order_buttons := VBoxContainer.new()
	order_buttons.alignment = BoxContainer.ALIGNMENT_BEGIN
	order_buttons.add_theme_constant_override("separation", 8)
	column.add_child(order_buttons)
	action_button = _command_button("DRAW CARD", RED)
	action_button.custom_minimum_size.x = 228
	action_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	action_button.pressed.connect(_on_action_pressed)
	order_buttons.add_child(action_button)
	advance_button = _command_button("ADVANCE", BLUE.darkened(0.25))
	advance_button.custom_minimum_size.x = 228
	advance_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	advance_button.pressed.connect(_on_advance_pressed)
	order_buttons.add_child(advance_button)
	return panel


func _build_training_stage() -> void:
	training_stage_panel = PanelContainer.new()
	training_stage_panel.set_anchors_preset(Control.PRESET_CENTER)
	training_stage_panel.offset_left = -126
	training_stage_panel.offset_right = 126
	training_stage_panel.offset_top = -88
	training_stage_panel.offset_bottom = 88
	training_stage_panel.add_theme_stylebox_override("panel", _style(Color(0.08, 0.11, 0.25, 0.97), GOLD, 3, 12))
	training_stage_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	training_stage_panel.visible = false
	design_surface.add_child(training_stage_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	training_stage_panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 7)
	margin.add_child(column)
	var heading := Label.new()
	heading.text = "NEW FIGHTER"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 18)
	heading.add_theme_color_override("font_color", GOLD)
	column.add_child(heading)
	training_stage_name = Label.new()
	training_stage_name.text = "AWAITING STATS"
	training_stage_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	training_stage_name.add_theme_font_size_override("font_size", 12)
	training_stage_name.add_theme_color_override("font_color", MUTED)
	column.add_child(training_stage_name)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)
	var stats := HBoxContainer.new()
	column.add_child(stats)
	var attack_column := VBoxContainer.new()
	attack_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats.add_child(attack_column)
	training_stage_attack = Button.new()
	training_stage_attack.text = "—"
	training_stage_attack.tooltip_text = "Add the selected stat card to the new fighter's attack."
	training_stage_attack.add_theme_font_size_override("font_size", 32)
	training_stage_attack.add_theme_color_override("font_color", RED)
	training_stage_attack.add_theme_stylebox_override("normal", _style(Color(0.18, 0.08, 0.15, 0.94), RED, 2, 8))
	training_stage_attack.add_theme_stylebox_override("hover", _style(Color(0.30, 0.10, 0.20, 0.98), GOLD, 3, 8))
	training_stage_attack.pressed.connect(_on_new_fighter_slot_pressed.bind("attack"))
	attack_column.add_child(training_stage_attack)
	new_fighter_attack_button = training_stage_attack
	var attack_caption := Label.new()
	attack_caption.text = "ATTACK SLOT"
	attack_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	attack_caption.add_theme_font_size_override("font_size", 10)
	attack_caption.add_theme_color_override("font_color", MUTED)
	attack_column.add_child(attack_caption)
	var defense_column := VBoxContainer.new()
	defense_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats.add_child(defense_column)
	training_stage_defense = Button.new()
	training_stage_defense.text = "—"
	training_stage_defense.tooltip_text = "Add the selected stat card to the new fighter's defense."
	training_stage_defense.add_theme_font_size_override("font_size", 32)
	training_stage_defense.add_theme_color_override("font_color", BLUE)
	training_stage_defense.add_theme_stylebox_override("normal", _style(Color(0.05, 0.17, 0.25, 0.94), BLUE, 2, 8))
	training_stage_defense.add_theme_stylebox_override("hover", _style(Color(0.08, 0.27, 0.38, 0.98), GOLD, 3, 8))
	training_stage_defense.pressed.connect(_on_new_fighter_slot_pressed.bind("defense"))
	defense_column.add_child(training_stage_defense)
	new_fighter_defense_button = training_stage_defense
	var defense_caption := Label.new()
	defense_caption.text = "DEFENSE SLOT"
	defense_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	defense_caption.add_theme_font_size_override("font_size", 10)
	defense_caption.add_theme_color_override("font_color", MUTED)
	defense_column.add_child(defense_caption)


func _rounded_texture_material(radius_pixels: float, round_bottom := true, logical_size := Vector2.ZERO, round_top := true) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = RoundedTextureShader
	material.set_shader_parameter("radius_pixels", radius_pixels)
	material.set_shader_parameter("round_top", round_top)
	material.set_shader_parameter("round_bottom", round_bottom)
	if logical_size.x > 0.0 and logical_size.y > 0.0:
		material.set_shader_parameter("radius_uv", Vector2(radius_pixels / logical_size.x, radius_pixels / logical_size.y))
		material.set_shader_parameter("logical_size_pixels", logical_size)
	return material


func _add_panel_metal(parent: PanelContainer, opacity := 0.34, radius := 9.0) -> TextureRect:
	var texture_rect := TextureRect.new()
	texture_rect.name = "BatteredMetalTexture"
	texture_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	texture_rect.texture = panel_metal_texture
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	texture_rect.modulate = Color(0.82, 0.90, 0.96, opacity)
	texture_rect.material = _rounded_texture_material(radius)
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(texture_rect)
	return texture_rect


func _add_type_badge(parent: Container, badge_text: String, badge_color: Color) -> Label:
	var center := CenterContainer.new()
	center.custom_minimum_size.y = 10
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(center)
	var badge_panel := PanelContainer.new()
	badge_panel.name = "CardTypeBadge"
	var badge_style := _style(Color(0.012, 0.018, 0.025, 0.82), badge_color.darkened(0.38), 1, 5)
	badge_style.content_margin_left = 5
	badge_style.content_margin_right = 5
	badge_style.content_margin_top = 0.5
	badge_style.content_margin_bottom = 0.5
	badge_panel.add_theme_stylebox_override("panel", badge_style)
	badge_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(badge_panel)
	var badge := Label.new()
	badge.text = badge_text
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 9)
	badge.add_theme_color_override("font_color", badge_color)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge_panel.add_child(badge)
	return badge


func _fit_card_name_font(name_text: String, initial_size: int, available_width: float) -> int:
	var longest_word := ""
	for word in name_text.split(" ", false):
		if longest_word.is_empty() or game_font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, initial_size).x > game_font.get_string_size(longest_word, HORIZONTAL_ALIGNMENT_LEFT, -1, initial_size).x:
			longest_word = word
	if longest_word.is_empty():
		longest_word = name_text
	var font_size := initial_size
	while font_size > 9 and game_font.get_string_size(longest_word, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > available_width:
		font_size -= 1
	return font_size


func _fit_single_line_font(text_value: String, initial_size: int, available_width: float, minimum_size: int = 7) -> int:
	var font_size := initial_size
	while font_size > minimum_size and game_font.get_string_size(text_value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > available_width:
		font_size -= 1
	return font_size


func _style(fill: Color, border: Color, width: int = 1, radius: int = 4) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(radius)
	box.border_blend = true
	box.anti_aliasing = true
	box.corner_detail = 10
	box.shadow_color = Color(0.01, 0.04, 0.08, 0.42)
	box.shadow_size = 4
	box.shadow_offset = Vector2(0, 2)
	box.content_margin_left = 12
	box.content_margin_right = 12
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	return box


func _stat_label(text_value: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", color)
	return label


func _command_button(text_value: String, color: Color) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size.y = 46
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", INK)
	button.add_theme_stylebox_override("normal", _style(color, color.lightened(0.18), 1, 5))
	button.add_theme_stylebox_override("hover", _style(color.lightened(0.10), GOLD, 1, 5))
	button.add_theme_stylebox_override("pressed", _style(color.darkened(0.12), INK, 1, 5))
	button.add_theme_stylebox_override("disabled", _style(COAL.lightened(0.08), PANEL_LIGHT.darkened(0.25), 1, 7))
	return button


func _start_new_game() -> void:
	_resume_from_modal()
	_stop_pit_audio()
	_stop_game_over_audio()
	match_serial += 1
	upgrade_battle_flags = {"player_cards_played": 0, "enemy_cards_played": 0}
	upgrade_card_history.clear()
	replaying_upgrade_cards = false
	opening_discard_pending = false
	if is_instance_valid(opening_discard_layer):
		opening_discard_layer.visible = false
	card_play_history = [[], []]
	artifact_battle_flags = {"player_cards_played": 0, "first_ally_death_draw_used": false, "player_rebirth_used": false, "fighters_trained": 0}
	_reset_training_stage()
	if is_instance_valid(return_menu_button):
		return_menu_button.visible = false
	next_card_id = 1
	next_fighter_id = 1
	_reset_fighter_identity_bags()
	if faction_ids[0].is_empty():
		faction_ids[0] = String(FactionData.all_factions()[0]["id"])
	if faction_ids[1].is_empty() or faction_ids[1] == faction_ids[0]:
		var rivals := FactionData.all_factions().filter(func(item: Dictionary) -> bool: return item["id"] != faction_ids[0])
		faction_ids[1] = String(rivals[rng.randi_range(0, rivals.size() - 1)]["id"])
	decks = [_make_deck(0), _make_deck(1)]
	hands = [[], []]
	fighters = [[], []]
	var player_max_health := _maximum_player_health(0)
	var enemy_health := _maximum_player_health(1)
	player_health = [player_max_health, enemy_health]
	faction_round_flags = [{}, {}]
	faction_card_plays = [0, 0]
	active_player = 0
	round_number = 1
	phase = PHASE_DRAW
	has_drawn = false
	trained_this_turn = false
	squad_summoned_this_turn = false
	stat_cards_played_this_turn = 0
	fighters_trained_this_turn[0] = 0
	training_cards_played_this_turn[0] = 0
	cards_drawn_this_turn = [0, 0]
	artifact_battle_flags["first_attack_round"] = -1
	artifact_battle_flags["first_curse_prevent_used"] = false
	fighters_trained_this_turn = [0, 0]
	training_cards_played_this_turn = [0, 0]
	input_locked = true
	game_over = false
	if is_instance_valid(defeat_layer):
		defeat_layer.visible = false
	if is_instance_valid(upgrade_layer):
		upgrade_layer.visible = false
	if is_instance_valid(artifact_choice_layer):
		artifact_choice_layer.visible = false
	pending_artifact_choices.clear()
	_dismiss_artifact_popup()
	selected_hand_indices.clear()
	selected_attacker_ids.clear()
	pending_attack_ids.clear()
	block_assignments.clear()
	selected_defend_attacker_id = -1
	new_fighter_attack = 0
	new_fighter_defense = 0
	selected_healer_id = -1
	pending_fighter_entrance_ids.clear()
	final_roll_animation_active = false
	final_roll_animation_skipped = false
	encounter_first_player = 0
	opening_attack_skip_owner = -1
	opening_attack_skip_pending = false
	first_player_roll_active = false
	round_banner_active = false
	round_banner_skipped = false
	log_lines.clear()
	for owner in 2:
		var opening_size := STARTING_HAND + (1 if owner == 0 and _has_upgrade_effect("opening_hand_selection_bonus") else 0) + (_artifact_total("opening_hand_bonus") if owner == 0 else 0)
		for count in opening_size:
			_draw_card(owner, false, false)
	_apply_starting_upgrades()
	_sort_hand_by_type_and_value(0)
	_sort_hand_by_type_and_value(1)
	var player_faction := FactionData.faction_by_id(faction_ids[0])
	var enemy_faction := FactionData.faction_by_id(faction_ids[1])
	_log_event("[color=#d8a94b]Encounter %d.[/color] %s faces %s — %s versus %s." % [encounter_number, player_faction["name"], enemy_faction["name"], String(player_faction["lean"]).to_upper(), String(enemy_faction["lean"]).to_upper()])
	_refresh_capstone_actions()
	if _has_upgrade_effect("opening_hand_selection_bonus"):
		_show_opening_discard_overlay()
	else:
		_start_first_player_roll()


func _start_first_player_roll() -> void:
	var serial := match_serial
	input_locked = true
	first_player_roll_active = true
	phase = PHASE_DRAW
	_refresh_all()
	var spinner := FirstPlayerSpinner.new()
	spinner.name = "FirstPlayerSpinner"
	spinner.z_index = 400
	spinner.set_meta("fast_spin_duration", 0.75)
	design_surface.add_child(spinner)
	_center_control(spinner, Vector2(390.0, 390.0))
	var status := Label.new()
	status.name = "FirstPlayerSpinnerStatus"
	status.text = "WHO TAKES THE FIRST TURN?"
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status.add_theme_font_size_override("font_size", 32)
	status.add_theme_color_override("font_color", GOLD)
	status.z_index = 450
	design_surface.add_child(status)
	_center_control(status, Vector2(760.0, 76.0))
	status.position.y = spinner.position.y - 90.0
	var final_angle := rng.randf_range(0.0, TAU)
	spinner.set_meta("final_angle", final_angle)
	var fast_spin := create_tween().set_ignore_time_scale(true)
	fast_spin.tween_property(spinner, "wheel_angle", TAU * 5.0, 0.75).set_trans(Tween.TRANS_LINEAR)
	await fast_spin.finished
	if serial != match_serial:
		for control in [spinner, status]:
			if is_instance_valid(control): control.queue_free()
		first_player_roll_active = false
		return
	var slow_spin := create_tween().set_ignore_time_scale(true)
	slow_spin.tween_property(spinner, "wheel_angle", TAU * 7.0 + final_angle, 1.25).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	await slow_spin.finished
	if serial != match_serial:
		for control in [spinner, status]:
			if is_instance_valid(control): control.queue_free()
		first_player_roll_active = false
		return
	var pointer_sector := fposmod(-PI * 0.5 - final_angle, TAU)
	encounter_first_player = 0 if pointer_sector < PI else 1
	spinner.set_meta("winner_owner", encounter_first_player)
	opening_attack_skip_owner = encounter_first_player
	opening_attack_skip_pending = true
	active_player = encounter_first_player
	var winner_text := "YOU GO FIRST" if encounter_first_player == 0 else "THIS COMPUTER GOES FIRST"
	status.text = "%s  //  FIRST ATTACK PHASE WILL BE SKIPPED" % winner_text
	status.add_theme_color_override("font_color", GREEN if encounter_first_player == 0 else RED)
	_log_event("%s wins the opening spinner and goes first. The first attack phase is skipped." % ("You" if encounter_first_player == 0 else "This Computer"), encounter_first_player)
	await get_tree().create_timer(0.75, true, false, true).timeout
	for control in [spinner, status]:
		if is_instance_valid(control): control.queue_free()
	first_player_roll_active = false
	if serial != match_serial or game_over:
		return
	await _show_round_banner(serial)
	if serial != match_serial or game_over:
		return
	if encounter_first_player == 0:
		_begin_player_turn()
	else:
		_begin_ai_turn()


func _opening_sequence_duration(base_seconds: float) -> float:
	return base_seconds * OPENING_SEQUENCE_TIME_MULTIPLIER


func _show_round_banner(serial: int = -1) -> void:
	if serial == -1:
		serial = match_serial
	round_banner_active = true
	round_banner_skipped = false
	var banner := _create_final_roll_label()
	banner.name = "RoundBanner"
	banner.text = "ROUND %d" % round_number
	banner.add_theme_font_size_override("font_size", 76)
	design_surface.add_child(banner)
	_center_control(banner, Vector2(760.0, 200.0))
	var remaining := 1.0
	while remaining > 0.0 and not round_banner_skipped and serial == match_serial:
		var step := minf(0.05, remaining)
		await get_tree().create_timer(step, true, false, false).timeout
		remaining -= step
	if is_instance_valid(banner):
		banner.queue_free()
	round_banner_active = false
	round_banner_skipped = false


func _make_deck(owner: int) -> Array:
	var deck: Array = []
	for value in range(1, 11):
		for count in range(11 - value):
			deck.append(_new_card("stat", str(value), value, "Train: use as %s." % ("attack or defense")))
	for count in 3:
		deck.append(_new_card("weapon", "Sword", 2, "+2 attack"))
	deck.append(_new_card("weapon", "Hammer", 4, "+4 attack"))
	for count in 3:
		deck.append(_new_card("shield", "Small Shield", 4, "+4 defense"))
	deck.append(_new_card("shield", "Large Shield", 8, "+8 defense"))
	for count in 3:
		deck.append(_new_card("curse", "Poison", 2, "Takes 2 damage at the start of its turn."))
	for count in 2:
		deck.append(_new_card("curse", "Madness", 25, "25% chance its combat damage hits itself."))
	deck.append(_new_card("curse", "Deathmark", 0, "Destroy target fighter."))
	deck.append(_new_card("curse", "Armageddon", 0, "Destroy every fighter on the battlefield."))
	for count in 3:
		deck.append(_new_card("blessing", "Evasive", 0, "Cannot be targeted by curses."))
	deck.append(_new_card("blessing", "Berserker", 25, "25% chance to deal double combat damage."))
	for count in 6:
		deck.append(_new_card("heal", "Small Heal", 5, "Restore 5 health to a fighter or player."))
	deck.append(_new_card("heal", "Large Heal", 15, "Restore 15 health to a fighter or player."))
	for count in 2:
		deck.append(_new_card("training", "Shield Master", 1, "+1 max defense and heal 1 each turn."))
	for count in 2:
		deck.append(_new_card("training", "Zen Master", 1, "Prevent the next damage this fighter takes."))
	for count in 2:
		deck.append(_new_card("training", "Explosive Master", 2, "Deals 2 splash damage in combat."))
	deck.append(_new_card("summon", "Call in the Squad", 3, "Summon Dirty Dan, Wild Wayne, and Chaste Chase as 3/3 fighters for five turns."))
	for faction_card in FactionData.cards_for_faction(faction_ids[owner]):
		var runtime_card: Dictionary = faction_card.duplicate(true)
		runtime_card["id"] = next_card_id
		runtime_card["definition_id"] = faction_card["id"]
		next_card_id += 1
		deck.append(runtime_card)
	deck.shuffle()
	return deck


func _new_card(kind: String, card_name: String, value: int, description: String) -> Dictionary:
	var card := {
		"id": next_card_id,
		"kind": kind,
		"name": card_name,
		"value": value,
		"description": description,
		"definition_id": "%s_%s" % [kind, card_name.to_snake_case()],
	}
	next_card_id += 1
	return card


func _play_faction_card(owner: int, hand_index: int, target: Dictionary = {}) -> bool:
	if hand_index < 0 or hand_index >= hands[owner].size():
		return false
	var card: Dictionary = hands[owner][hand_index]
	if not card.has("faction_id"):
		return false
	if String(card.get("kind", "")) == "training" and not replaying_upgrade_cards and training_cards_played_this_turn[owner] >= MAX_TRAINING_CARDS_PER_TURN:
		if owner == 0:
			_show_toast("TRAINING CARD LIMIT  //  2 OF 2")
		return false
	var effect := String(card.get("effect", ""))
	if effect not in SUPPORTED_FACTION_EFFECTS:
		push_error("Unsupported faction effect: %s" % effect)
		return false
	var value := _consume_effective_card_value(owner, card)
	var target_owner := 1 - owner
	var created: Dictionary = {}
	if owner == 1 and String(card.get("kind", "")) == "curse" and not target.is_empty() and int(target.get("owner", -1)) == 0 and _has_artifact("first_curse_prevent") and not artifact_battle_flags.get("first_curse_prevent_used", false):
		artifact_battle_flags["first_curse_prevent_used"] = true
		_log_event("Mirror Shard shatters %s before it lands." % card["name"], 0)
		hands[owner].remove_at(hand_index)
		_record_card_play(owner, card, value, {"fighter_id": int(target.get("id", -1)), "negated": true})
		return true
	if not target.is_empty() and String(card.get("target", "")) == "enemy_fighter" and effect != "summon_copy_enemy_stat" and bool(target.get("evasive_once", false)):
		target["evasive_once"] = false
		target["evasive"] = false
		_queue_fighter_status_trigger(target, "QUANTUM SCREEN!", BLUE)
		_log_event("%s's Quantum Screen prevents %s." % [_fighter_name(target), card["name"]], owner)
		hands[owner].remove_at(hand_index)
		_record_card_play(owner, card, value, {"fighter_id": int(target.get("id", -1)), "negated": true})
		if owner == 0: selected_hand_indices.clear()
		return true
	match effect:
		"summon_fighter", "summon_fighter_splash", "summon_fighter_lifesteal", "summon_and_prime_stat", "summon_copy_enemy_stat", "summon_double_chain_count":
			var attack := int(card.get("attack", maxi(1, value))) + (_upgrade_total("summons_gain_attack") if owner == 0 else 0)
			var defense := int(card.get("defense", maxi(1, value))) + (_upgrade_total("summons_gain_defense") if owner == 0 else 0)
			if effect == "summon_copy_enemy_stat" and not target.is_empty():
				if _fighter_attack(target) >= _fighter_max_defense(target): attack = maxi(attack, _fighter_attack(target))
				else: defense = maxi(defense, _fighter_max_defense(target))
			created = _create_fighter(owner, attack, defense)
			created["name"] = card["name"]
			created["faction_summon"] = true
			created["lifesteal"] = effect == "summon_fighter_lifesteal"
			created["explosive"] = effect == "summon_fighter_splash"
			fighters[owner].append(created)
			_queue_fighter_entrance(created)
			if effect == "summon_and_prime_stat": faction_round_flags[owner]["stat_bonus"] = 1
			_notify_ally_trained(owner, created)
		"add_attack", "add_attack_bonus_if_shielded":
			target["attack_bonus"] += value + (1 if effect == "add_attack_bonus_if_shielded" and not target["shields"].is_empty() else 0)
			target["weapons"].append(card["name"])
		"add_attack_and_pierce":
			target["attack_bonus"] += value; target["pierce"] += 2; target["weapons"].append(card["name"])
		"add_attack_and_random_damage":
			target["attack_bonus"] += value; target["weapons"].append(card["name"])
			var victims: Array = fighters[target_owner].filter(func(f: Dictionary) -> bool: return not _is_dead(f))
			if not victims.is_empty(): _apply_damage_to_fighter(victims[rng.randi_range(0, victims.size() - 1)], 1, card["name"])
		"add_attack_and_self_damage":
			target["attack_bonus"] += value; target["weapons"].append(card["name"]); _apply_damage_to_fighter(target, 1, card["name"])
		"add_attack_and_thorns":
			target["attack_bonus"] += value; target["thorns"] += 1; target["weapons"].append(card["name"])
		"temporary_attack_with_recoil":
			target["attack_bonus"] += value; target["temporary_attack"] += value; target["recoil_damage"] = maxi(int(target["recoil_damage"]), 1)
		"attack_and_temporary_evasive":
			target["attack_bonus"] += value; target["temporary_attack"] += value; target["evasive"] = true; target["temporary_evasive"] = true
		"add_defense":
			target["defense_bonus"] += value; target["shields"].append(card["name"])
		"add_defense_and_evasive_once":
			target["defense_bonus"] += value; target["evasive"] = true; target["evasive_once"] = true; target["shields"].append(card["name"])
		"add_defense_with_break_heal":
			target["defense_bonus"] += value; target["shield_break_heal"] += 2; target["shields"].append(card["name"])
		"add_defense_with_break_draw":
			target["defense_bonus"] += value; target["shield_break_draw"] += 1; target["shields"].append(card["name"])
		"add_defense_counterattack_training":
			target["defense_bonus"] += value; target["counterattack_bonus"] += 2
		"adjacent_allies_defense_aura":
			target["aura_defense"] += value
		"add_attack_defense":
			target["attack_bonus"] += int(card.get("attack", value)); target["defense_bonus"] += int(card.get("defense", value))
		"add_to_lower_stat":
			if _fighter_attack(target) <= _fighter_max_defense(target): target["attack_bonus"] += value
			else: target["defense_bonus"] += value
		"attack_from_existing_damage":
			target["attack_bonus"] += mini(6, floori(float(target["damage"]) / 3.0) * value)
		"other_ally_trained_gain_defense":
			target["ally_trained_defense"] += value
		"survive_combat_gain_attack":
			target["survive_combat_attack"] += value
		"survive_lethal_once":
			target["deathless_once"] = true
		"prevent_next_damage":
			target["damage_prevention"] += value
		"reduce_combat_damage_timed":
			target["combat_damage_reduction"] = maxi(int(target["combat_damage_reduction"]), value); target["reduction_combats"] = 2
		"temporary_reduce_attack":
			target["attack_bonus"] -= value; target["temporary_attack"] -= value
		"heal", "heal_with_chain_bonus":
			var heal_amount := value + (3 if effect == "heal_with_chain_bonus" and (faction_card_plays[owner] + 1) % 3 == 0 else 0)
			if String(card["target"]) == "ally_player": player_health[owner] += _apply_heal_bonus(owner, heal_amount)
			else: _heal_fighter_with_upgrades(owner, target, _apply_heal_bonus(owner, heal_amount))
		"heal_and_cleanse":
			_heal_fighter_with_upgrades(owner, target, _apply_heal_bonus(owner, value)); _remove_one_curse_stack(target)
		"heal_all_allied_fighters", "heal_all_allies_and_player":
			for ally in fighters[owner]: _heal_fighter_with_upgrades(owner, ally, _apply_heal_bonus(owner, value), false)
			if effect == "heal_all_allies_and_player": player_health[owner] += _apply_heal_bonus(owner, value)
		"damage_and_lifesteal", "damage_if_wounded", "damage_and_remove_weapon", "damage_and_chain":
			var dealt := 0
			if effect != "damage_if_wounded" or int(target["damage"]) > 0: dealt = _apply_damage_to_fighter(target, value, card["name"])
			if effect == "damage_and_lifesteal": player_health[owner] += dealt
			if effect == "damage_and_remove_weapon" and not target["weapons"].is_empty():
				var removed_weapon := String(target["weapons"].pop_back())
				target["attack_bonus"] -= _weapon_attack_value(removed_weapon)
				if removed_weapon == "Phase Blade": target["pierce"] = maxi(0, int(target["pierce"]) - 2)
			if effect == "damage_and_chain":
				for other in fighters[target_owner]:
					if other != target and not _is_dead(other): _apply_damage_to_fighter(other, 1, card["name"]); break
		"damage_all_fighters":
			for side in 2:
				for fighter in fighters[side]: _apply_damage_to_fighter(fighter, value, card["name"])
		"damage_players_and_draw":
			_damage_player(0, value, owner); _damage_player(1, value, owner); _draw_card(owner, false)
		"enemy_area_damage_from_chain":
			for enemy in fighters[target_owner]: _apply_damage_to_fighter(enemy, mini(4, maxi(1, faction_card_plays[owner])), card["name"])
		"sacrifice_for_player_damage":
			target["damage"] = _fighter_max_defense(target); _damage_player(target_owner, value, owner)
		"fortify_most_damaged_ally":
			var ally := _most_damaged_fighter(owner)
			if not ally.is_empty(): ally["defense_bonus"] += value; ally["damage"] = maxi(0, int(ally["damage"]) - 4)
		"team_attack_per_enemy", "team_temporary_attack_and_draw":
			var boost: int = value if effect == "team_temporary_attack_and_draw" else value * fighters[target_owner].size()
			for ally in fighters[owner]: ally["attack_bonus"] += boost; ally["temporary_attack"] += boost
			if effect == "team_temporary_attack_and_draw": _draw_card(owner, false)
		"boost_next_card":
			faction_round_flags[owner]["next_card_bonus"] = int(faction_round_flags[owner].get("next_card_bonus", 0)) + value
		"boost_next_cards":
			faction_round_flags[owner]["boost_cards_remaining"] = 3; faction_round_flags[owner]["boost_cards_value"] = value
		"discover_faction_card":
			pass # Resolve after the played card leaves hand, guaranteeing one open slot.
		"reflect_next_player_damage":
			faction_round_flags[owner]["reflect_player_damage"] = value
	_log_event("%s invokes [color=#ffd166]%s[/color] — %s" % [_owner_name(owner), card["name"], card["description"]], owner, owner == 0)
	hands[owner].remove_at(hand_index)
	if String(card.get("kind", "")) == "training" and not replaying_upgrade_cards:
		training_cards_played_this_turn[owner] += 1
	if effect == "discover_faction_card":
		_discover_best_faction_card(owner, String(card["definition_id"]))
	_record_card_play(owner, card, value, {"fighter_id": int(target.get("id", -1)) if not target.is_empty() else -1})
	if owner == 0:
		selected_hand_indices.clear()
	_remove_dead_fighters()
	_check_game_over()
	return true


func _faction_card_requires_fighter_target(card: Dictionary) -> bool:
	# Player, team, battlefield, and self modes resolve directly. Only these
	# three modes may ever ask the player to choose a highlighted fighter.
	return String(card.get("target", "none")) in ["ally_fighter", "enemy_fighter", "any_fighter"]


func _consume_effective_card_value(owner: int, card: Dictionary) -> int:
	if card.has("_replay_resolved_value"):
		return int(card["_replay_resolved_value"])
	var result := int(card.get("value", 0))
	if owner == 0:
		result += _upgrade_kind_bonus(String(card.get("kind", "")))
		if String(card.get("kind", "")) == "weapon":
			result += _artifact_total("weapon_bonus")
	result += int(faction_round_flags[owner].get("next_card_bonus", 0))
	faction_round_flags[owner]["next_card_bonus"] = 0
	var remaining := int(faction_round_flags[owner].get("boost_cards_remaining", 0))
	if remaining > 0:
		result += int(faction_round_flags[owner].get("boost_cards_value", 0))
		faction_round_flags[owner]["boost_cards_remaining"] = remaining - 1
	if String(card.get("kind", "")) == "stat":
		result += int(faction_round_flags[owner].get("stat_bonus", 0))
		faction_round_flags[owner]["stat_bonus"] = 0
	return result


func _preview_effective_card_value(owner: int, card: Dictionary) -> int:
	if card.has("_replay_resolved_value"):
		return int(card["_replay_resolved_value"])
	var result := int(card.get("value", 0))
	if owner == 0:
		result += _upgrade_kind_bonus(String(card.get("kind", "")))
		if String(card.get("kind", "")) == "weapon":
			result += _artifact_total("weapon_bonus")
	result += int(faction_round_flags[owner].get("next_card_bonus", 0))
	if int(faction_round_flags[owner].get("boost_cards_remaining", 0)) > 0:
		result += int(faction_round_flags[owner].get("boost_cards_value", 0))
	if String(card.get("kind", "")) == "stat":
		result += int(faction_round_flags[owner].get("stat_bonus", 0))
	return result


func _record_card_play(owner: int, card: Dictionary, resolved_value: int = -1, target_info: Dictionary = {}) -> void:
	if owner < 0 or owner >= 2:
		return
	if replaying_upgrade_cards:
		return
	if resolved_value < 0:
		resolved_value = int(card.get("value", 0))
	var battle_count_key := "player_cards_played" if owner == 0 else "enemy_cards_played"
	upgrade_battle_flags[battle_count_key] = int(upgrade_battle_flags.get(battle_count_key, 0)) + 1
	var actual_battle_count := int(upgrade_battle_flags[battle_count_key])
	if owner == 0 and _has_artifact("card_milestone_damage"):
		var interval := 5
		for artifact_id in owned_artifact_ids:
			var milestone_artifact := ArtifactData.artifact_by_id(artifact_id)
			if String(milestone_artifact.get("effect", "")) == "card_milestone_damage":
				interval = maxi(1, int(milestone_artifact.get("interval", 5)))
				break
		if actual_battle_count % interval == 0:
			_damage_player(1, _artifact_total("card_milestone_damage"), 0)
			_log_event("Static Battery spits lightning after card %d." % actual_battle_count, 0)
	var previous_chain := faction_card_plays[owner]
	var chain_increment := 1
	if owner == 0 and actual_battle_count == 1 and _has_upgrade_effect("first_card_double_chain_count"):
		chain_increment += 1
	if String(card.get("effect", "")) == "summon_double_chain_count":
		chain_increment += 1
	faction_card_plays[owner] += chain_increment
	var history_entry: Dictionary = card.duplicate(true)
	history_entry["resolved_value"] = resolved_value
	var resolved_target_info := target_info.duplicate(true)
	if not resolved_target_info.has("target_class"):
		if resolved_target_info.has("player"):
			resolved_target_info["target_class"] = "player"
		elif String(card.get("target", "")) in ["ally_player", "enemy_player", "any_player"]:
			resolved_target_info["target_class"] = "player"
			resolved_target_info["player"] = owner if String(card.get("target", "")) == "ally_player" else 1 - owner
		elif resolved_target_info.get("battlefield", false) or String(card.get("target", "")) in ["battlefield", "all_allies", "all_enemies"]:
			resolved_target_info["target_class"] = "battlefield"
		elif resolved_target_info.has("creation_pair_id") or resolved_target_info.has("new_fighter_slot") or resolved_target_info.has("new_fighter_axis"):
			resolved_target_info["target_class"] = "creation_slot"
		elif int(resolved_target_info.get("fighter_id", -1)) >= 0:
			resolved_target_info["target_class"] = "fighter"
		elif resolved_target_info.has("summoned"):
			resolved_target_info["target_class"] = "creation_pair"
		else:
			resolved_target_info["target_class"] = "battlefield" if String(card.get("target", "")) == "battlefield" else "none"
	var recorded_fighter_id := int(resolved_target_info.get("fighter_id", -1))
	if recorded_fighter_id >= 0:
		for side in 2:
			var recorded_target := _get_fighter(side, recorded_fighter_id)
			if not recorded_target.is_empty():
				resolved_target_info["original_owner"] = side
				resolved_target_info["original_name"] = _fighter_name(recorded_target)
				break
	resolved_target_info["fallback_owner"] = 1 if String(card.get("target", "")) == "enemy_fighter" or String(card.get("kind", "")) == "curse" else 0
	history_entry["target_info"] = resolved_target_info
	history_entry["play_number"] = actual_battle_count
	history_entry["chain_count"] = faction_card_plays[owner]
	(card_play_history[owner] as Array).append(history_entry)
	_attach_card_to_recent_log(owner, card, actual_battle_count)
	if owner == 0:
		upgrade_card_history.append(history_entry.duplicate(true))
		if upgrade_card_history.size() > 12:
			upgrade_card_history.pop_front()
		if _has_upgrade_effect("chain_milestone_draw") and actual_battle_count % maxi(1, _upgrade_total("chain_milestone_draw")) == 0:
			_draw_card(0, false)
		if _has_upgrade_effect("recycle_first_faction_card") and not upgrade_battle_flags.get("recycled_first_faction", false) and card.has("faction_id"):
			upgrade_battle_flags["recycled_first_faction"] = true
			var recycled := card.duplicate(true)
			recycled["id"] = next_card_id
			next_card_id += 1
			decks[0].push_front(recycled)
	elif actual_battle_count == 3 and _has_upgrade_effect("copy_enemy_third_card") and hands[0].size() < MAX_HAND:
		var copied := card.duplicate(true)
		copied["id"] = next_card_id
		next_card_id += 1
		copied["temporary_copy"] = true
		hands[0].append(copied)
	var faction := FactionData.faction_by_id(faction_ids[owner])
	var passive: Dictionary = faction.get("passive", {})
	match String(passive.get("effect", "")):
		"prime_next_stat_after_non_stat":
			if card.get("kind", "") != "stat":
				var stack_limit := _upgrade_total("passive_stack_limit") if owner == 0 else 1
				faction_round_flags[owner]["stat_bonus"] = mini(maxi(1, stack_limit), int(faction_round_flags[owner].get("stat_bonus", 0)) + int(passive.get("value", 1)))
		"third_card_damage_enemy_player":
			var triggers := faction_card_plays[owner] / 3 - previous_chain / 3
			for trigger in triggers:
				_damage_player(1 - owner, int(passive.get("value", 1)), owner)
				if owner == 0 and _has_upgrade_effect("passive_random_fighter_damage"):
					var enemies: Array = fighters[1].filter(func(f: Dictionary) -> bool: return not _is_dead(f))
					if not enemies.is_empty(): _apply_damage_to_fighter(enemies[rng.randi_range(0, enemies.size() - 1)], _upgrade_total("passive_random_fighter_damage"), "Forked Bolt")
				if owner == 0 and _has_upgrade_effect("passive_trigger_boost_next_card"):
					faction_round_flags[0]["next_card_bonus"] = int(faction_round_flags[0].get("next_card_bonus", 0)) + _upgrade_total("passive_trigger_boost_next_card")


func _finalize_creation_pair(pair_id: int, attack: int, defense: int) -> void:
	for history in [card_play_history[0], upgrade_card_history]:
		for entry in history:
			var info: Dictionary = entry.get("target_info", {})
			if int(info.get("creation_pair_id", -1)) == pair_id:
				info["pair_attack"] = attack
				info["pair_defense"] = defense


func _record_faction_card_play(owner: int, card: Dictionary, resolved_value: int = -1, target_info: Dictionary = {}) -> void:
	_record_card_play(owner, card, resolved_value, target_info)


func _attach_card_to_recent_log(owner: int, card: Dictionary, play_number: int) -> void:
	var card_name := String(card.get("name", ""))
	if card_name.is_empty():
		return
	for reverse_index in log_lines.size():
		var event_index := log_lines.size() - 1 - reverse_index
		var event: Dictionary = log_lines[event_index]
		if int(event.get("speaker", LOG_NEUTRAL)) != owner or card_name not in String(event.get("text", "")):
			continue
		var references: Array = event.get("card_refs", [])
		references.append({
			"key": "%d:%d:%s" % [owner, play_number, String(card.get("definition_id", card.get("id", card_name)))],
			"name": card_name,
			"card": card.duplicate(true),
		})
		event["card_refs"] = references
		log_lines[event_index] = event
		return


func _discover_best_faction_card(owner: int, excluded_definition_id: String) -> void:
	if hands[owner].size() >= MAX_HAND:
		return
	var options := FactionData.cards_for_faction(faction_ids[owner]).filter(func(item: Dictionary) -> bool: return String(item["id"]) != excluded_definition_id)
	if options.is_empty():
		return
	options.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_score := int(a.get("attack", 0)) + int(a.get("defense", 0)) + int(a.get("value", 0))
		var b_score := int(b.get("attack", 0)) + int(b.get("defense", 0)) + int(b.get("value", 0))
		return a_score > b_score
	)
	var discovered: Dictionary = options[0].duplicate(true)
	discovered["definition_id"] = discovered["id"]
	discovered["id"] = next_card_id
	next_card_id += 1
	hands[owner].append(discovered)


func _notify_ally_trained(owner: int, new_fighter: Dictionary) -> void:
	for ally in fighters[owner]:
		if ally != new_fighter and int(ally.get("ally_trained_defense", 0)) > 0:
			var gained := int(ally["ally_trained_defense"])
			ally["defense_bonus"] += gained
			_queue_fighter_status_trigger(ally, "SHARED PROCESSOR: +%d DEF" % gained, GREEN)


func _apply_artifacts_to_trained_fighter(owner: int, fighter: Dictionary) -> void:
	if owner != 0 or fighter.is_empty():
		return
	var battle_count := int(artifact_battle_flags.get("fighters_trained", 0)) + 1
	artifact_battle_flags["fighters_trained"] = battle_count
	if battle_count == 1 and _has_artifact("first_fighter_boost"):
		fighter["attack_bonus"] += _artifact_total("first_fighter_boost")
		fighter["defense_bonus"] += _artifact_total("first_fighter_boost")
	if fighters_trained_this_turn[0] == 1 and _has_artifact("first_turn_fighter_attack"):
		fighter["attack_bonus"] += _artifact_total("first_turn_fighter_attack")
	if artifact_run_fighters_trained > 0 and artifact_run_fighters_trained % 3 == 0 and _has_artifact("third_fighter_boost"):
		fighter["attack_bonus"] += _artifact_total("third_fighter_boost")
		fighter["defense_bonus"] += _artifact_total("third_fighter_boost")


func _weapon_attack_value(weapon_name: String) -> int:
	if weapon_name == "Sword": return 2
	if weapon_name == "Hammer": return 4
	for definition in FactionData.all_cards():
		if String(definition.get("name", "")) == weapon_name and String(definition.get("kind", "")) == "weapon":
			return int(definition.get("value", 0))
	return 0


func _apply_heal_bonus(owner: int, amount: int) -> int:
	var artifact_bonus := _artifact_total("heal_bonus") if owner == 0 else 0
	var faction := FactionData.faction_by_id(faction_ids[owner])
	if String(faction.get("passive", {}).get("effect", "")) == "first_heal_bonus" and not faction_round_flags[owner].get("healed", false):
		faction_round_flags[owner]["healed"] = true
		return amount + artifact_bonus + int(faction["passive"].get("value", 2)) + _upgrade_total("passive_value_bonus")
	return amount + artifact_bonus


func _heal_fighter_with_upgrades(owner: int, fighter: Dictionary, amount: int, allow_chain: bool = true) -> int:
	if fighter.is_empty() or amount <= 0:
		return 0
	var missing := int(fighter.get("damage", 0))
	var healed := mini(missing, amount)
	fighter["damage"] = maxi(0, missing - healed)
	var excess := maxi(0, amount - missing)
	if owner == 0 and excess > 0 and _has_upgrade_effect("overheal_to_defense"):
		fighter["defense_bonus"] += excess
	if owner == 0 and allow_chain and healed > 0 and _has_upgrade_effect("heal_chains_to_ally"):
		var chain_target: Dictionary = {}
		for ally in fighters[0]:
			if ally != fighter and int(ally.get("damage", 0)) > int(chain_target.get("damage", 0)):
				chain_target = ally
		if not chain_target.is_empty():
			_heal_fighter_with_upgrades(0, chain_target, maxi(1, floori(float(healed) * float(_upgrade_total("heal_chains_to_ally")) / 100.0)), false)
	return healed


func _most_damaged_fighter(owner: int) -> Dictionary:
	var result: Dictionary = {}
	for fighter in fighters[owner]:
		if result.is_empty() or int(fighter["damage"]) > int(result["damage"]):
			result = fighter
	return result


func _maximum_player_health(owner: int) -> int:
	if owner == 0:
		return STARTING_HEALTH + _upgrade_total("max_health") + _artifact_total("starting_health_bonus")
	return STARTING_HEALTH + (encounter_number - 1) * 5


func _player_animation_target(owner: int) -> Control:
	return player_portrait_button if owner == 0 else opponent_status_panel


func _player_hit_will_be_lethal(owner: int, amount: int, source_owner: int) -> bool:
	var effective_amount := amount
	if owner == 0 and source_owner != owner:
		effective_amount -= mini(effective_amount, _artifact_total("player_damage_reduction"))
	if effective_amount <= 0 or player_health[owner] - effective_amount > 0:
		return false
	if owner == 0 and _has_artifact("player_rebirth") and not artifact_battle_flags.get("player_rebirth_used", false):
		return false
	if owner == 0 and _has_upgrade_effect("unlock_player_rebirth") and not upgrade_battle_flags.get("unlock_player_rebirth_used", false):
		return false
	return true


func _damage_player(owner: int, amount: int, source_owner: int) -> void:
	if amount <= 0:
		return
	if owner == 0 and source_owner != owner:
		var prevented := mini(amount, _artifact_total("player_damage_reduction"))
		if prevented > 0:
			amount -= prevented
			_log_event("Guardian Coin prevents %d player damage." % prevented, 0)
			if amount <= 0:
				return
	var previous := player_health[owner]
	player_health[owner] = maxi(0, previous - amount)
	if owner == 0 and player_health[0] <= 0 and _has_artifact("player_rebirth") and not artifact_battle_flags.get("player_rebirth_used", false):
		artifact_battle_flags["player_rebirth_used"] = true
		player_health[0] = _artifact_total("player_rebirth")
		_log_event("Phoenix Feather flares: you return at %d health." % player_health[0], 0)
	if owner == 0 and player_health[0] <= 0 and _has_upgrade_effect("unlock_player_rebirth") and not upgrade_battle_flags.get("unlock_player_rebirth_used", false):
		upgrade_battle_flags["unlock_player_rebirth_used"] = true
		player_health[0] = _upgrade_total("unlock_player_rebirth")
		for ally in fighters[0]:
			ally["attack_bonus"] += 3
			ally["defense_bonus"] += 3
		_refresh_capstone_actions()
	var health_bar: StatusHealthBar = player_health_bar if owner == 0 else opponent_health_bar
	if is_instance_valid(health_bar):
		health_bar.set_health(player_health[owner], _maximum_player_health(owner))
	var portrait := _player_animation_target(owner)
	var health_label: Label = player_health_label if owner == 0 else opponent_health_label
	combat_animator.player_damage(portrait, health_label, amount, player_health[owner], design_surface)
	_log_event("%s takes [color=#ff5d73]%d damage[/color]." % [_owner_name(owner), amount], source_owner, source_owner == 0)
	var reflected := int(faction_round_flags[owner].get("reflect_player_damage", 0))
	if reflected > 0 and source_owner != owner:
		faction_round_flags[owner]["reflect_player_damage"] = 0
		_damage_player(source_owner, mini(reflected, amount), owner)


func _apply_round_end_passive(owner: int) -> void:
	var faction := FactionData.faction_by_id(faction_ids[owner])
	if String(faction.get("passive", {}).get("effect", "")) == "round_end_repair_most_damaged":
		var target := _most_damaged_fighter(owner)
		if not target.is_empty() and int(target["damage"]) > 0:
			var amount := int(faction["passive"].get("value", 1)) + (_upgrade_total("passive_value_bonus") if owner == 0 else 0)
			target["damage"] = maxi(0, int(target["damage"]) - amount)
			_log_event("%s's Field Repairs restores %d defense to %s." % [_owner_name(owner), amount, _fighter_name(target)], owner)
	if owner == 0 and _has_upgrade_effect("round_end_team_defense"):
		for ally in fighters[0]:
			ally["defense_bonus"] += _upgrade_total("round_end_team_defense")
		_log_event("The Eternal Engine grants every ally +1 defense.", 0)


func _draw_card(owner: int, announce: bool = true, count_toward_turn_limit: bool = true) -> bool:
	if count_toward_turn_limit and cards_drawn_this_turn[owner] >= MAX_CARDS_DRAWN_PER_TURN:
		if announce:
			_log_event("You reached the four-card draw limit this turn." if owner == 0 else "This Computer reached the four-card draw limit this turn.")
		return false
	if hands[owner].size() >= MAX_HAND:
		if announce:
			_log_event("Your hand is full." if owner == 0 else "This Computer's hand is full.")
		return false
	if decks[owner].is_empty():
		_damage_player(owner, 5, 1 - owner)
		if announce:
			_log_event(("You have" if owner == 0 else "This Computer has") + " no cards left and take%s [color=#c33b35]5 fatigue damage[/color]." % ("" if owner == 0 else "s"))
		_check_game_over()
		return false
	hands[owner].append(decks[owner].pop_back())
	if count_toward_turn_limit:
		cards_drawn_this_turn[owner] += 1
	if announce:
		_log_event("You draw a card." if owner == 0 else "This Computer draws a card.")
		_play_random_sound("draw_a_card")
	return true


func _draw_to_eight(owner: int) -> int:
	var drawn := 0
	while hands[owner].size() < 8 and hands[owner].size() < MAX_HAND and not game_over and cards_drawn_this_turn[owner] < MAX_CARDS_DRAWN_PER_TURN:
		if decks[owner].is_empty():
			_draw_card(owner, true)
			break
		if not _draw_card(owner, false):
			break
		drawn += 1
	if drawn > 0:
		var actor := "You draw" if owner == 0 else "This Computer draws"
		var message := "%s %d card%s." % [actor, drawn, "" if drawn == 1 else "s"]
		_log_event(message, owner, false if owner == 1 else true)
		_play_random_sound("draw_a_card")
	return drawn


func _sort_hand_by_type_and_value(owner: int) -> void:
	if owner < 0 or owner >= hands.size():
		return
	var selected_card_ids: Array[int] = []
	if owner == 0:
		for selected_index in selected_hand_indices:
			if selected_index >= 0 and selected_index < hands[0].size():
				selected_card_ids.append(int(hands[0][selected_index].get("id", -1)))
	hands[owner].sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_kind := String(a.get("kind", ""))
		var b_kind := String(b.get("kind", ""))
		var a_type := int(CARD_TYPE_SORT_ORDER.get(a_kind, 99))
		var b_type := int(CARD_TYPE_SORT_ORDER.get(b_kind, 99))
		if a_type != b_type:
			return a_type > b_type
		var a_value := int(a.get("value", 0))
		var b_value := int(b.get("value", 0))
		if a_value != b_value:
			return a_value > b_value
		return String(a.get("name", "")) > String(b.get("name", ""))
	)
	if owner == 0:
		selected_hand_indices.clear()
		for index in hands[0].size():
			if int(hands[0][index].get("id", -1)) in selected_card_ids:
				selected_hand_indices.append(index)


func _begin_player_turn() -> void:
	if game_over:
		return
	if int(upgrade_battle_flags.get("ocean_round", -1)) >= 0 and int(upgrade_battle_flags.get("ocean_round", -1)) < round_number:
		for ally in fighters[0]:
			var ocean_bonus := int(ally.get("ocean_defense_bonus", 0))
			ally["defense_bonus"] -= ocean_bonus
			ally["ocean_defense_bonus"] = 0
		upgrade_battle_flags.erase("ocean_round")
	var serial := match_serial
	active_player = 0
	phase = PHASE_DRAW
	has_drawn = false
	trained_this_turn = false
	squad_summoned_this_turn = false
	stat_cards_played_this_turn = 0
	fighters_trained_this_turn[0] = 0
	training_cards_played_this_turn[0] = 0
	cards_drawn_this_turn[0] = 0
	artifact_battle_flags["first_attack_round"] = -1
	artifact_battle_flags["first_curse_prevent_used"] = false
	faction_round_flags[0] = {}
	faction_card_plays[0] = 0
	input_locked = true
	selected_hand_indices.clear()
	selected_attacker_ids.clear()
	new_fighter_attack = 0
	new_fighter_defense = 0
	selected_healer_id = -1
	_reset_training_stage()
	_apply_upkeep(0)
	if game_over:
		return
	_log_event("[color=#d8a94b]Round %d — your turn.[/color]" % round_number)
	_refresh_all()
	await _phase_beat(0, PHASE_DRAW, false)
	if game_over or serial != match_serial:
		return
	var cards_drawn := _draw_to_eight(0)
	_sort_hand_by_type_and_value(0)
	_show_toast("YOU DRAW %d CARD%s  //  HAND %d" % [cards_drawn, "" if cards_drawn == 1 else "S", hands[0].size()], 0.3)
	await get_tree().create_timer(0.3).timeout
	if game_over or serial != match_serial:
		return
	has_drawn = true
	phase = PHASE_TRAIN
	_refresh_all()
	await _phase_beat(0, PHASE_TRAIN, true)


func _begin_ai_turn() -> void:
	if game_over:
		return
	var serial := match_serial
	active_player = 1
	phase = PHASE_DRAW
	has_drawn = false
	trained_this_turn = false
	squad_summoned_this_turn = false
	stat_cards_played_this_turn = 0
	fighters_trained_this_turn[1] = 0
	training_cards_played_this_turn[1] = 0
	cards_drawn_this_turn[1] = 0
	faction_round_flags[1] = {}
	faction_card_plays[1] = 0
	input_locked = true
	selected_hand_indices.clear()
	selected_attacker_ids.clear()
	new_fighter_attack = 0
	new_fighter_defense = 0
	selected_healer_id = -1
	_reset_training_stage()
	_apply_upkeep(1)
	var turn_message := "[color=#c33b35]This Computer takes its turn.[/color]"
	_log_event(turn_message, LOG_COMPUTER, false)
	_refresh_all()
	await _show_action_flash(turn_message, 0.5)
	await get_tree().create_timer(0.5).timeout
	await _phase_beat(1, PHASE_DRAW, false)
	if game_over or serial != match_serial:
		return
	_run_ai_turn(serial)


func _apply_upkeep(owner: int) -> void:
	var expired_ids: Array[int] = []
	for fighter in fighters[owner]:
		fighter["squad_heal_used"] = false
		if int(fighter.get("temporary_attack", 0)) != 0:
			fighter["attack_bonus"] -= int(fighter["temporary_attack"])
			fighter["temporary_attack"] = 0
		if bool(fighter.get("temporary_evasive", false)):
			fighter["temporary_evasive"] = false
			if not bool(fighter.get("evasive_once", false)):
				fighter["evasive"] = false
		if int(fighter.get("squad_turns_remaining", 0)) > 0:
			fighter["squad_turns_remaining"] = int(fighter["squad_turns_remaining"]) - 1
			if int(fighter["squad_turns_remaining"]) <= 0:
				expired_ids.append(int(fighter["id"]))
		var poison_stacks := _status_stacks(fighter, "poison")
		if poison_stacks > 0:
			var poison_amount := 2 * poison_stacks
			var poison_dealt := _apply_damage_to_fighter(fighter, poison_amount, "Poison x%d" % poison_stacks, false)
			if poison_dealt > 0:
				_show_poison_damage(fighter, poison_dealt)
		if fighter["shield_master"]:
			fighter["defense_bonus"] += 1
			fighter["damage"] = max(0, fighter["damage"] - 1)
			_log_event("%s's Shield Master training grants +1 defense and repairs 1." % _fighter_name(fighter), owner)
	for fighter_id in expired_ids:
		var expired := _get_fighter(owner, fighter_id)
		if not expired.is_empty():
			_log_event("[color=#a78bfa]%s disappears as the squad's five turns expire.[/color]" % _fighter_name(expired), owner)
			fighters[owner].erase(expired)
	_remove_dead_fighters()
	_check_game_over()


func _on_action_pressed() -> void:
	if input_locked or game_over:
		return
	if training_animation_requests > 0:
		_show_toast("FIGHTER ASSEMBLY IN PROGRESS")
		return
	if active_player != 0 and phase != PHASE_DEFEND:
		return
	match phase:
		PHASE_DRAW:
			if not has_drawn:
				_draw_to_eight(0)
				_sort_hand_by_type_and_value(0)
				has_drawn = true
				phase = PHASE_TRAIN
				_show_toast("CARD DRAWN  //  TRAINING OPEN")
		PHASE_TRAIN:
			if selected_hand_indices.size() == 1:
				var selected_card: Dictionary = hands[0][selected_hand_indices[0]]
				if selected_card.has("faction_id"):
					var faction_targets := _selected_card_targets()
					if not _faction_card_requires_fighter_target(selected_card):
						_play_faction_card(0, selected_hand_indices[0])
					elif faction_targets.size() == 1:
						_play_faction_card(0, selected_hand_indices[0], faction_targets[0]["fighter"])
					else:
						_show_toast("CHOOSE A HIGHLIGHTED TARGET")
					input_locked = false
					_refresh_all()
					return
				if selected_card["kind"] == "stat":
					_show_toast("CLICK AN ATTACK OR DEFENSE SLOT")
					_refresh_all()
					return
				if selected_card["kind"] == "summon":
					input_locked = true
					_show_toast("CALLING IN THE SQUAD", 0.3)
					_refresh_all()
					var squad_serial := match_serial
					await get_tree().create_timer(0.3).timeout
					if squad_serial != match_serial or game_over:
						return
					_play_squad_card(0, selected_hand_indices[0])
					input_locked = false
					_refresh_all()
					return
				if selected_card["kind"] == "curse" and selected_card["name"] == "Armageddon":
					input_locked = true
					_show_toast("UNLEASHING ARMAGEDDON", 0.3)
					_refresh_all()
					var armageddon_serial := match_serial
					await get_tree().create_timer(0.3).timeout
					if armageddon_serial != match_serial or game_over:
						return
					_play_armageddon(0, selected_hand_indices[0])
					input_locked = false
					_refresh_all()
					return
				if selected_card["kind"] != "stat":
					var targets := _selected_card_targets()
					if targets.size() != 1:
						_show_toast("CLICK A HIGHLIGHTED FIGHTER TO PLAY %s" % String(selected_card["name"]).to_upper(), 0.7)
						_refresh_all()
						return
					input_locked = true
					_show_toast("PLAYING %s" % String(selected_card["name"]).to_upper(), 0.3)
					_refresh_all()
					var card_serial := match_serial
					await get_tree().create_timer(0.3).timeout
					if card_serial != match_serial or game_over:
						return
					var target: Dictionary = targets[0]
					if selected_card["kind"] == "curse":
						_play_curse_card(0, selected_hand_indices[0], target["fighter"])
					elif selected_card["kind"] in ["weapon", "shield", "blessing", "training"]:
						_play_support_card(0, selected_hand_indices[0], target["fighter"])
					input_locked = false
					_refresh_all()
					return
			_show_toast("SELECT A STAT CARD OR PLAY ANOTHER TRAINING CARD")
		PHASE_ATTACK:
			if selected_attacker_ids.is_empty():
				_log_event("You hold your fighters back.")
				_enter_player_heal_or_end()
			else:
				_begin_player_attack()
		PHASE_DEFEND:
			_resolve_player_defense()
	_refresh_all()


func _on_advance_pressed() -> void:
	if input_locked or game_over or active_player != 0:
		return
	if training_animation_requests > 0:
		_show_toast("FIGHTER ASSEMBLY IN PROGRESS")
		return
	if phase == PHASE_TRAIN and ((new_fighter_attack > 0) != (new_fighter_defense > 0)):
		_show_toast("FINISH THE NEW FIGHTER BY FILLING ITS EMPTY SLOT")
		return
	selected_hand_indices.clear()
	_reset_training_stage()
	match phase:
		PHASE_TRAIN:
			_enter_player_attack_phase()
		PHASE_ATTACK:
			selected_attacker_ids.clear()
			_log_event("You decline to attack.")
			_enter_player_heal_or_end()
		PHASE_HEAL:
			_end_player_turn()
	_refresh_all()


func _consume_opening_attack_skip(owner: int) -> bool:
	if opening_attack_skip_pending and opening_attack_skip_owner == owner:
		opening_attack_skip_pending = false
		return true
	return false


func _enter_player_attack_phase() -> void:
	if _consume_opening_attack_skip(0):
		selected_attacker_ids.clear()
		_log_event("You went first, so your opening attack phase is skipped.", 0)
		_show_toast("OPENING ATTACK SKIPPED  //  FIRST PLAYER", _opening_sequence_duration(0.6))
		_enter_player_heal_or_end()
		return
	phase = PHASE_ATTACK
	_start_pit_audio()
	selected_attacker_ids.clear()
	for fighter in fighters[0]:
		if not _is_dead(fighter):
			selected_attacker_ids.append(int(fighter["id"]))
	_log_event("Training closes. All ready fighters enter the pit; click any fighter to hold it back.")
	_phase_beat(0, PHASE_ATTACK, true)


func _advance_turn_after(completed_owner: int) -> void:
	var next_owner := 1 - completed_owner
	if next_owner == encounter_first_player:
		round_number += 1
		var serial := match_serial
		await _show_round_banner(serial)
		if serial != match_serial or game_over:
			return
	if next_owner == 0:
		_begin_player_turn()
	else:
		_begin_ai_turn()


func _end_player_turn() -> void:
	if game_over:
		return
	input_locked = true
	_apply_round_end_passive(0)
	if _has_artifact("low_health_turn_heal") and player_health[0] <= int(_maximum_player_health(0) / 2):
		var flask_heal := _artifact_total("low_health_turn_heal")
		player_health[0] += flask_heal
		_log_event("Bottomless Flask restores [color=#4fd1a1]%d player health[/color]." % flask_heal)
	_log_event("You end your turn.")
	_show_toast("YOU  //  END TURN", 0.3)
	_refresh_all()
	await get_tree().create_timer(0.3).timeout
	_play_phase_cue()
	await _advance_turn_after(0)


func _heal_card_can_target_player(card: Dictionary) -> bool:
	if not card.has("faction_id"):
		return true
	var target := String(card.get("target", ""))
	return target in ["ally_player", "any_player"] or String(card.get("effect", "")) == "heal_all_allies_and_player"


func _heal_card_can_target_fighter(card: Dictionary) -> bool:
	if not card.has("faction_id"):
		return true
	return String(card.get("target", "")) in ["ally_fighter", "any_fighter", "all_allies"]


func _heal_card_has_valid_target(owner: int, card: Dictionary) -> bool:
	if String(card.get("kind", "")) != "heal":
		return false
	if _heal_card_can_target_player(card) and player_health[owner] < _maximum_player_health(owner):
		return true
	if _heal_card_can_target_fighter(card):
		return fighters[owner].any(func(fighter: Dictionary) -> bool: return not _is_dead(fighter) and int(fighter.get("damage", 0)) > 0)
	return false


func _has_playable_heal_card(owner: int) -> bool:
	for card in hands[owner]:
		if _heal_card_has_valid_target(owner, card):
			return true
	return false


func _has_squad_heal(owner: int) -> bool:
	for fighter in fighters[owner]:
		if fighter.get("squad_role", "") == "ally_healer" and not bool(fighter.get("squad_heal_used", false)):
			for ally in fighters[owner]:
				if ally != fighter and int(ally["damage"]) > 0:
					return true
	return false


func _enter_player_heal_or_end() -> void:
	if game_over:
		return
	_stop_pit_audio(true)
	if _has_playable_heal_card(0) or _has_squad_heal(0):
		phase = PHASE_HEAL
		input_locked = true
		_log_event("Healing phase opens.")
		_refresh_all()
		_phase_beat(0, PHASE_HEAL, true)
	else:
		_log_event("No heal card or healer has a valid target. The healing phase is skipped.")
		_show_toast("NO VALID HEALS  //  HEAL SKIPPED", 0.3)
		_end_player_turn()


func _on_hand_card_pressed(index: int) -> void:
	if input_locked or game_over or active_player != 0 or index < 0 or index >= hands[0].size():
		return
	var card: Dictionary = hands[0][index]
	if phase == PHASE_TRAIN:
		if card["kind"] == "stat":
			if stat_cards_played_this_turn >= MAX_STAT_TRAINING_PER_TURN and not _can_use_stat_for_new_fighter(0):
				_show_toast("STAT TRAINING LIMIT REACHED  //  1 OF 1")
				return
			var deselect_stat := selected_hand_indices.size() == 1 and selected_hand_indices[0] == index
			selected_hand_indices.clear()
			if deselect_stat:
				training_stage_panel.visible = new_fighter_attack > 0 or new_fighter_defense > 0
			else:
				selected_hand_indices.append(index)
				_show_training_choices()
				_show_toast("CHOOSE ANY ATTACK OR DEFENSE SLOT", 0.5)
		else:
			if training_animation_requests > 0:
				_show_toast("FINISH SELECTING THE FIGHTER'S STATS")
				return
			var deselect := selected_hand_indices.size() == 1 and selected_hand_indices[0] == index
			selected_hand_indices.clear()
			if not deselect:
				selected_hand_indices.append(index)
			training_stage_panel.visible = false
			if not selected_hand_indices.is_empty():
				if card.has("faction_id"):
					_show_toast("FACTION CARD  //  %s" % String(card["description"]).to_upper(), 0.7)
				elif card["kind"] == "heal":
					_show_toast("HEAL CARDS ARE USED IN THE HEAL PHASE")
				elif card["kind"] in ["weapon", "shield", "blessing", "training"]:
					_show_toast("SELECT ONE OF YOUR FIGHTERS")
				elif card["kind"] == "curse":
					if card["name"] == "Armageddon":
						_show_toast("PRESS ARMAGEDDON TO DESTROY ALL FIGHTERS")
					else:
						_show_toast("SELECT AN ENEMY FIGHTER")
				elif card["kind"] == "summon":
					_show_toast("PRESS CALL IN THE SQUAD")
	elif phase == PHASE_HEAL and card["kind"] == "heal":
		var deselect := selected_hand_indices.size() == 1 and selected_hand_indices[0] == index
		selected_hand_indices.clear()
		if not deselect:
			selected_hand_indices.append(index)
		if not selected_hand_indices.is_empty():
			_show_toast("SELECT A DAMAGED FIGHTER OR YOUR LIFE TOTAL")
	else:
		_show_toast(_phase_card_hint(card))
	_refresh_all()


func _show_training_choices() -> void:
	training_stage_panel.visible = false
	training_stage_name.text = "SELECT A SLOT"
	training_stage_attack.text = str(new_fighter_attack) if new_fighter_attack > 0 else "+ ATK"
	training_stage_defense.text = str(new_fighter_defense) if new_fighter_defense > 0 else "+ DEF"
	var fighter_limit_reached := fighters_trained_this_turn[0] >= MAX_FIGHTERS_TRAINED_PER_TURN
	training_stage_attack.disabled = fighter_limit_reached or new_fighter_attack > 0
	training_stage_defense.disabled = fighter_limit_reached or new_fighter_defense > 0


func _can_use_stat_for_new_fighter(owner: int) -> bool:
	return (
		owner >= 0
		and owner < fighters_trained_this_turn.size()
		and fighters_trained_this_turn[owner] < MAX_FIGHTERS_TRAINED_PER_TURN
		and not squad_summoned_this_turn
	)


func _on_new_fighter_slot_pressed(axis: String) -> void:
	if input_locked or game_over or active_player != 0 or phase != PHASE_TRAIN:
		return
	if fighters_trained_this_turn[0] >= MAX_FIGHTERS_TRAINED_PER_TURN:
		_show_toast("FIGHTER LIMIT REACHED  //  1 OF 1 THIS TURN")
		return
	if squad_summoned_this_turn:
		_show_toast("YOU CANNOT CREATE A FIGHTER AFTER CALLING IN THE SQUAD")
		return
	if selected_hand_indices.size() != 1:
		_show_toast("SELECT A STAT CARD FIRST")
		return
	var hand_index := selected_hand_indices[0]
	if hand_index < 0 or hand_index >= hands[0].size() or hands[0][hand_index]["kind"] != "stat":
		return
	var spent_card: Dictionary = hands[0][hand_index].duplicate(true)
	var preview_value := int(spent_card.get("value", 0))
	if axis == "attack":
		if new_fighter_attack > 0:
			_show_toast("THE NEW FIGHTER'S ATTACK SLOT IS FILLED")
			return
		new_fighter_attack = preview_value
	else:
		if new_fighter_defense > 0:
			_show_toast("THE NEW FIGHTER'S DEFENSE SLOT IS FILLED")
			return
		new_fighter_defense = preview_value
	hands[0].remove_at(hand_index)
	pending_new_fighter_cards[axis] = spent_card
	pending_new_fighter_order.append(axis)
	selected_hand_indices.clear()
	if new_fighter_attack > 0 and new_fighter_defense > 0:
		var resolved_values := {}
		for staged_axis in pending_new_fighter_order:
			resolved_values[staged_axis] = _consume_effective_card_value(0, pending_new_fighter_cards[staged_axis])
		new_fighter_attack = int(resolved_values.get("attack", new_fighter_attack))
		new_fighter_defense = int(resolved_values.get("defense", new_fighter_defense))
		var creation_pair_id := next_fighter_id
		var fighter := _create_fighter(0, new_fighter_attack, new_fighter_defense)
		fighters[0].append(fighter)
		_queue_fighter_entrance(fighter)
		for staged_axis in pending_new_fighter_order:
			var staged_card: Dictionary = pending_new_fighter_cards[staged_axis]
			_record_card_play(0, staged_card, int(resolved_values[staged_axis]), {
				"target_class":"creation_slot",
				"creation_pair_id":creation_pair_id,
				"creation_axis":staged_axis,
				"new_fighter_slot":staged_axis,
				"pair_attack":new_fighter_attack,
				"pair_defense":new_fighter_defense,
			})
		_finalize_creation_pair(creation_pair_id, new_fighter_attack, new_fighter_defense)
		_notify_ally_trained(0, fighter)
		fighters_trained_this_turn[0] += 1
		artifact_run_fighters_trained += 1
		_apply_artifacts_to_trained_fighter(0, fighter)
		trained_this_turn = true
		_log_event("You train [color=#ffd166]%s (%d/%d)[/color]." % [_fighter_name(fighter), new_fighter_attack, new_fighter_defense])
		_show_toast("%s ENTERS THE STABLE" % _fighter_name(fighter).to_upper(), 0.5)
		new_fighter_attack = 0
		new_fighter_defense = 0
		pending_new_fighter_cards.clear()
		pending_new_fighter_order.clear()
		training_stage_panel.visible = false
	else:
		_show_training_choices()
		_show_toast("%s SLOT FILLED  //  SELECT ANOTHER STAT CARD" % axis.to_upper(), 0.5)
	_refresh_all()


func _cancel_pending_new_fighter() -> void:
	if pending_new_fighter_cards.is_empty():
		_show_toast("NO STAGED STAT CARD TO RETURN")
		return
	for staged_axis in pending_new_fighter_order:
		if pending_new_fighter_cards.has(staged_axis):
			hands[0].append((pending_new_fighter_cards[staged_axis] as Dictionary).duplicate(true))
	pending_new_fighter_cards.clear()
	pending_new_fighter_order.clear()
	new_fighter_attack = 0
	new_fighter_defense = 0
	selected_hand_indices.clear()
	training_stage_panel.visible = false
	_show_toast("NEW FIGHTER CANCELLED  //  STAT CARD RETURNED", 0.6)
	_log_event("You cancel the unfinished fighter and return its stat card to your hand.", 0)
	_refresh_all()


func _animate_stat_into_training(card: Dictionary, attack_slot: bool, source_global: Vector2) -> void:
	var animation_serial := match_serial
	var animation_epoch := training_animation_epoch
	training_animation_requests += 1
	while training_animation_active:
		await get_tree().process_frame
		if animation_serial != match_serial or animation_epoch != training_animation_epoch:
			training_animation_requests = maxi(0, training_animation_requests - 1)
			return
	training_animation_active = true
	if attack_slot:
		training_stage_attack.text = "—"
		training_stage_defense.text = "—"
		training_stage_name.text = "AWAITING DEFENSE"
		training_stage_panel.visible = true
		training_stage_panel.modulate.a = 0.0
		training_stage_panel.scale = Vector2(0.72, 0.72)
		training_stage_panel.pivot_offset = training_stage_panel.size * 0.5
		var reveal := create_tween().set_parallel(true)
		reveal.tween_property(training_stage_panel, "modulate:a", 1.0, 0.18)
		reveal.tween_property(training_stage_panel, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await reveal.finished
		if animation_serial != match_serial or animation_epoch != training_animation_epoch:
			_finish_training_animation_request()
			return
	await get_tree().process_frame
	var target_label: Button = training_stage_attack if attack_slot else training_stage_defense
	var target_global := target_label.get_global_rect().get_center()
	var canvas_inverse := design_surface.get_global_transform_with_canvas().affine_inverse()
	var source := canvas_inverse * source_global
	var target := canvas_inverse * target_global
	if source_global == Vector2.ZERO:
		source = target + Vector2(0, 180)
	var beam := Line2D.new()
	beam.width = 6.0
	beam.default_color = Color("#f6d475")
	beam.points = PackedVector2Array([source, target])
	design_surface.add_child(beam)
	var stat_orb := Label.new()
	stat_orb.text = str(card["value"])
	stat_orb.position = source - Vector2(27, 27)
	stat_orb.size = Vector2(54, 54)
	stat_orb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stat_orb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stat_orb.add_theme_font_size_override("font_size", 34)
	stat_orb.add_theme_color_override("font_color", INK)
	stat_orb.add_theme_stylebox_override("normal", _style(BLUE.darkened(0.55), GOLD, 2, 27))
	stat_orb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	design_surface.add_child(stat_orb)
	var flight := create_tween().set_parallel(true)
	flight.tween_property(stat_orb, "position", target - Vector2(27, 27), 0.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	flight.tween_property(stat_orb, "scale", Vector2(0.45, 0.45), 0.30)
	flight.tween_property(beam, "modulate:a", 0.0, 0.30)
	await flight.finished
	if animation_serial != match_serial or animation_epoch != training_animation_epoch:
		stat_orb.queue_free()
		beam.queue_free()
		_finish_training_animation_request()
		return
	target_label.text = str(card["value"])
	stat_orb.queue_free()
	beam.queue_free()
	if attack_slot:
		training_stage_name.text = "CHOOSE DEFENSE"
		_finish_training_animation_request()
		_refresh_all()
		return
	training_stage_name.text = "FIGHTER TRAINED"
	await get_tree().create_timer(0.12).timeout
	if animation_serial != match_serial or animation_epoch != training_animation_epoch:
		_finish_training_animation_request()
		return
	var fighter := _try_train_selected()
	_refresh_all()
	await get_tree().process_frame
	if not fighter.is_empty():
		training_stage_name.text = _fighter_name(fighter).to_upper()
		await _animate_training_stage_to_stable(int(fighter["id"]))
	training_stage_panel.visible = false
	training_stage_panel.modulate = Color.WHITE
	training_stage_panel.scale = Vector2.ONE
	training_stage_panel.offset_left = -126
	training_stage_panel.offset_right = 126
	training_stage_panel.offset_top = -88
	training_stage_panel.offset_bottom = 88
	_finish_training_animation_request()
	_refresh_all()


func _finish_training_animation_request() -> void:
	training_animation_active = false
	training_animation_requests = maxi(0, training_animation_requests - 1)


func _reset_training_stage() -> void:
	training_animation_epoch += 1
	training_animation_active = false
	training_animation_requests = 0
	new_fighter_attack = 0
	new_fighter_defense = 0
	pending_new_fighter_cards.clear()
	pending_new_fighter_order.clear()
	if not is_instance_valid(training_stage_panel):
		return
	training_stage_panel.visible = false
	training_stage_panel.modulate = Color.WHITE
	training_stage_panel.scale = Vector2.ONE
	training_stage_panel.offset_left = -126
	training_stage_panel.offset_right = 126
	training_stage_panel.offset_top = -88
	training_stage_panel.offset_bottom = 88
	if is_instance_valid(training_stage_attack):
		training_stage_attack.text = "—"
	if is_instance_valid(training_stage_defense):
		training_stage_defense.text = "—"
	if is_instance_valid(training_stage_name):
		training_stage_name.text = "AWAITING STATS"


func _animate_training_stage_to_stable(fighter_id: int) -> void:
	var target_button: Control = fighter_button_nodes.get(fighter_id)
	if not is_instance_valid(target_button):
		await get_tree().create_timer(0.18).timeout
		return
	var destination := target_button.get_global_rect().get_center()
	var origin := training_stage_panel.get_global_rect().get_center()
	var canvas_inverse := design_surface.get_global_transform_with_canvas().affine_inverse()
	var delta: Vector2 = canvas_inverse * destination - canvas_inverse * origin
	var travel := create_tween().set_parallel(true)
	travel.tween_property(training_stage_panel, "position", training_stage_panel.position + delta, 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	travel.tween_property(training_stage_panel, "scale", Vector2(0.58, 0.58), 0.34)
	travel.tween_property(training_stage_panel, "modulate:a", 0.15, 0.34)
	await travel.finished


func _selected_cards_are_stats() -> bool:
	for index in selected_hand_indices:
		if index < 0 or index >= hands[0].size() or hands[0][index]["kind"] != "stat":
			return false
	return true


func _try_train_selected() -> Dictionary:
	if fighters_trained_this_turn[0] >= MAX_FIGHTERS_TRAINED_PER_TURN:
		_show_toast("FIGHTER LIMIT REACHED  //  1 OF 1 THIS TURN")
		return {}
	if selected_hand_indices.size() != 2 or not _selected_cards_are_stats():
		_show_toast("SELECT TWO STAT CARDS: ATTACK, THEN DEFENSE")
		return {}
	var attack_card: Dictionary = hands[0][selected_hand_indices[0]]
	var defense_card: Dictionary = hands[0][selected_hand_indices[1]]
	var attack_value := _consume_effective_card_value(0, attack_card)
	var defense_value := _consume_effective_card_value(0, defense_card)
	var fighter := _create_fighter(0, attack_value, defense_value)
	var remove_indices: Array[int] = selected_hand_indices.duplicate()
	remove_indices.sort()
	remove_indices.reverse()
	for index in remove_indices:
		hands[0].remove_at(index)
	var pair_info := {"target_class":"creation_slot", "creation_pair_id":int(fighter["id"]), "pair_attack":attack_value, "pair_defense":defense_value}
	var attack_pair_info := pair_info.duplicate(true); attack_pair_info["creation_axis"] = "attack"; attack_pair_info["new_fighter_axis"] = "attack"
	var defense_pair_info := pair_info.duplicate(true); defense_pair_info["creation_axis"] = "defense"; defense_pair_info["new_fighter_axis"] = "defense"
	_record_card_play(0, attack_card, attack_value, attack_pair_info)
	_record_card_play(0, defense_card, defense_value, defense_pair_info)
	fighters[0].append(fighter)
	_queue_fighter_entrance(fighter)
	_notify_ally_trained(0, fighter)
	fighters_trained_this_turn[0] += 1
	artifact_run_fighters_trained += 1
	_apply_artifacts_to_trained_fighter(0, fighter)
	trained_this_turn = true
	selected_hand_indices.clear()
	_log_event("You train [color=#d8a94b]%s (%d/%d)[/color]." % [_fighter_name(fighter), fighter["attack_base"], fighter["defense_base"]])
	_show_toast("%s  //  %d ATTACK  //  %d DEFENSE" % [_fighter_name(fighter).to_upper(), fighter["attack_base"], fighter["defense_base"]], 0.3)
	return fighter


func _create_fighter(owner: int, attack: int, defense: int) -> Dictionary:
	if owner == 1:
		if encounter_number > 1:
			attack += floori(float(encounter_number - 1) / 2.0)
			defense += encounter_number - 1
		attack = maxi(1, attack - _artifact_total("enemy_fighter_attack_penalty"))
	elif owner == 0:
		defense += _upgrade_total("fighters_start_defense")
	var prefix_index := _take_identity_index(available_prefix_indices, FIGHTER_PREFIXES.size(), FIGHTER_PREFIXES)
	var name_index := _take_identity_index(available_name_indices, FIGHTER_NAMES.size(), FIGHTER_NAMES)
	var fighter := {
		"id": next_fighter_id,
		"owner": owner,
		"name": "%s %s" % [
			FIGHTER_PREFIXES[prefix_index],
			FIGHTER_NAMES[name_index],
		],
		"attack_base": attack,
		"defense_base": defense,
		"attack_bonus": 0,
		"defense_bonus": 0,
		"damage": 0,
		"weapons": [],
		"shields": [],
		"poison": false,
		"poison_stacks": 0,
		"madness": false,
		"madness_stacks": 0,
		"evasive": false,
		"berserker": false,
		"berserker_stacks": 0,
		"shield_master": false,
		"zen": false,
		"explosive": false,
		"faction_summon": false,
		"lifesteal": false,
		"pierce": 0,
		"thorns": 0,
		"recoil_damage": 0,
		"shield_break_heal": 0,
		"shield_break_draw": 0,
		"counterattack_bonus": 0,
		"combat_damage_reduction": 0,
		"reduction_combats": 0,
		"survive_combat_attack": 0,
		"deathless_once": false,
		"damage_prevention": 0,
		"ally_trained_defense": 0,
		"aura_defense": 0,
		"temporary_attack": 0,
		"temporary_evasive": false,
		"evasive_once": false,
		"squad_role": "",
		"squad_turns_remaining": 0,
		"squad_heal_used": false,
		"portrait_index": _take_identity_index(available_portrait_indices, 25),
	}
	next_fighter_id += 1
	return fighter


func _create_squad_fighter(owner: int, fighter_name: String, role: String) -> Dictionary:
	var fighter := _create_fighter(owner, 3, 3)
	fighter["name"] = fighter_name
	fighter["squad_role"] = role
	fighter["squad_turns_remaining"] = 5
	return fighter


func _queue_fighter_entrance(fighter: Dictionary) -> void:
	if not fighter.is_empty():
		pending_fighter_entrance_ids[int(fighter["id"])] = match_serial


func _animate_new_fighter_drop(fighter_id: int, button: Button) -> void:
	if not pending_fighter_entrance_ids.has(fighter_id) or not is_instance_valid(button):
		return
	if int(pending_fighter_entrance_ids[fighter_id]) != match_serial:
		pending_fighter_entrance_ids.erase(fighter_id)
		return
	pending_fighter_entrance_ids.erase(fighter_id)
	var resting_position := button.position
	button.pivot_offset = button.size * 0.5
	button.position.y = resting_position.y - 46.0
	button.scale = Vector2(0.96, 1.04)
	button.rotation = -0.025
	button.z_index = 20
	button.set_meta("fighter_drop_active", true)
	var drop := button.create_tween()
	drop.tween_property(button, "position:y", resting_position.y + 8.0, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	drop.parallel().tween_property(button, "scale", Vector2(1.04, 0.94), 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	drop.parallel().tween_property(button, "rotation", 0.018, 0.42)
	drop.tween_property(button, "position:y", resting_position.y - 6.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	drop.parallel().tween_property(button, "scale", Vector2(0.985, 1.015), 0.18)
	drop.parallel().tween_property(button, "rotation", -0.012, 0.18)
	drop.tween_property(button, "position:y", resting_position.y + 2.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	drop.parallel().tween_property(button, "scale", Vector2(1.01, 0.99), 0.16)
	drop.parallel().tween_property(button, "rotation", 0.006, 0.16)
	drop.tween_property(button, "position:y", resting_position.y, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	drop.parallel().tween_property(button, "scale", Vector2.ONE, 0.20)
	drop.parallel().tween_property(button, "rotation", 0.0, 0.20)
	drop.finished.connect(func() -> void:
		if is_instance_valid(button):
			button.position = resting_position
			button.scale = Vector2.ONE
			button.rotation = 0.0
			button.z_index = 0
			button.set_meta("fighter_drop_active", false)
	)


func _reset_fighter_identity_bags() -> void:
	available_portrait_indices.clear()
	available_prefix_indices.clear()
	available_name_indices.clear()


func _take_identity_index(bag: Array[int], total: int, identities: Array = []) -> int:
	if bag.is_empty():
		var seen: Dictionary = {}
		for index in total:
			if not identities.is_empty():
				var identity_key := String(identities[index])
				if seen.has(identity_key):
					continue
				seen[identity_key] = true
			bag.append(index)
		bag.shuffle()
	return bag.pop_back()


func _on_fighter_pressed(owner: int, fighter_id: int) -> void:
	if input_locked or game_over:
		return
	var fighter := _get_fighter(owner, fighter_id)
	if fighter.is_empty():
		return
	if phase == PHASE_DEFEND and active_player == 1:
		if owner == 1:
			if fighter_id in pending_attack_ids:
				selected_defend_attacker_id = fighter_id
				_show_toast("ATTACKER SELECTED  //  CHOOSE YOUR BLOCKERS")
		elif owner == 0:
			_toggle_blocker(fighter_id)
	elif active_player == 0 and phase == PHASE_ATTACK and owner == 0:
		if fighter_id in selected_attacker_ids:
			selected_attacker_ids.erase(fighter_id)
		else:
			selected_attacker_ids.append(fighter_id)
	elif active_player == 0 and phase == PHASE_TRAIN and selected_hand_indices.size() == 1:
		var card: Dictionary = hands[0][selected_hand_indices[0]]
		if card.has("faction_id") and _is_valid_selected_card_target(owner, fighter):
			_play_faction_card(0, selected_hand_indices[0], fighter)
		elif owner == 0 and _is_stat_upgrade_card(card):
			_show_toast("CHOOSE %s'S ATTACK OR DEFENSE SLOT" % _fighter_name(fighter).to_upper())
		elif owner == 0 and card["kind"] in ["weapon", "shield", "blessing", "training"]:
			input_locked = true
			_show_toast("PLAYING %s" % String(card["name"]).to_upper(), 0.3)
			_refresh_all()
			var support_serial := match_serial
			await get_tree().create_timer(0.3).timeout
			if support_serial != match_serial or game_over:
				return
			_play_support_card(0, selected_hand_indices[0], fighter)
			input_locked = false
		elif owner == 1 and card["kind"] == "curse":
			if card["name"] == "Armageddon":
				_show_toast("USE THE UNLEASH ARMAGEDDON ORDER")
				_refresh_all()
				return
			input_locked = true
			_show_toast("CASTING %s" % String(card["name"]).to_upper(), 0.3)
			_refresh_all()
			var curse_serial := match_serial
			await get_tree().create_timer(0.3).timeout
			if curse_serial != match_serial or game_over:
				return
			_play_curse_card(0, selected_hand_indices[0], fighter)
			input_locked = false
	elif active_player == 0 and phase == PHASE_HEAL and owner == 0 and selected_hand_indices.is_empty():
		if selected_healer_id == -1:
			if fighter.get("squad_role", "") == "ally_healer" and not bool(fighter.get("squad_heal_used", false)):
				selected_healer_id = fighter_id
				_show_toast("CHASTE CHASE SELECTED  //  CHOOSE A WOUNDED ALLY")
		else:
			var healer := _get_fighter(0, selected_healer_id)
			if fighter_id == selected_healer_id:
				selected_healer_id = -1
			elif not healer.is_empty() and int(fighter["damage"]) > 0:
				var healed: int = mini(_fighter_attack(healer), int(fighter["damage"]))
				fighter["damage"] -= healed
				healer["squad_heal_used"] = true
				_log_event("Chaste Chase heals %s for [color=#4fd1a1]%d[/color]." % [_fighter_name(fighter), healed])
				_show_toast("CHASTE CHASE HEALS %s FOR %d" % [_fighter_name(fighter).to_upper(), healed], 0.5)
				selected_healer_id = -1
	elif active_player == 0 and phase == PHASE_HEAL and owner == 0 and selected_hand_indices.size() == 1:
		var card: Dictionary = hands[0][selected_hand_indices[0]]
		if card["kind"] == "heal":
			input_locked = true
			_show_toast("APPLYING %s" % String(card["name"]).to_upper(), 0.3)
			_refresh_all()
			var heal_serial := match_serial
			await get_tree().create_timer(0.3).timeout
			if heal_serial != match_serial or game_over:
				return
			_play_heal_on_fighter(0, selected_hand_indices[0], fighter)
			input_locked = false
	_refresh_all()


func _on_player_portrait_pressed() -> void:
	if input_locked or game_over or active_player != 0 or phase != PHASE_HEAL or selected_hand_indices.size() != 1:
		return
	var card: Dictionary = hands[0][selected_hand_indices[0]]
	if card["kind"] != "heal":
		return
	if not _heal_card_can_target_player(card):
		_show_toast("THIS HEAL CAN ONLY TARGET FIGHTERS")
		return
	if player_health[0] >= _maximum_player_health(0):
		_show_toast("YOUR LIFE TOTAL IS ALREADY FULL")
		return
	input_locked = true
	_show_toast("APPLYING %s" % String(card["name"]).to_upper(), 0.3)
	_refresh_all()
	var serial := match_serial
	await get_tree().create_timer(0.3).timeout
	if serial != match_serial or game_over:
		return
	_resolve_heal_on_player(0, selected_hand_indices[0], true)
	selected_hand_indices.clear()
	input_locked = false
	_refresh_all()


func _resolve_heal_on_player(owner: int, hand_index: int, show_feedback: bool = true) -> bool:
	if hand_index < 0 or hand_index >= hands[owner].size():
		return false
	var card: Dictionary = hands[owner][hand_index]
	if String(card.get("kind", "")) != "heal":
		return false
	if not _heal_card_can_target_player(card) or player_health[owner] >= _maximum_player_health(owner):
		return false
	var amount := _apply_heal_bonus(owner, _consume_effective_card_value(owner, card))
	var maximum_health := _maximum_player_health(owner)
	var healed := mini(amount, maxi(0, maximum_health - player_health[owner]))
	player_health[owner] += healed
	if show_feedback:
		_log_event("%s restore%s [color=#58a66b]%d life[/color]." % [_owner_name(owner), "s" if owner == 1 else "", healed], owner)
		_show_toast("%s  //  RESTORE %d HP" % [_owner_name(owner).to_upper(), healed], 0.3)
	hands[owner].remove_at(hand_index)
	_record_card_play(owner, card, amount, {"target_class":"player", "player":owner, "healed":healed})
	return true


func _toggle_blocker(fighter_id: int) -> void:
	if selected_defend_attacker_id == -1:
		_show_toast("SELECT AN ENEMY ATTACKER FIRST")
		return
	var selected_attacker := _get_fighter(1, selected_defend_attacker_id)
	if not selected_attacker.is_empty() and selected_attacker.get("squad_role", "") == "unblockable":
		_show_toast("DIRTY DAN CANNOT BE BLOCKED")
		return
	for attacker_id in block_assignments.keys():
		var assigned: Array = block_assignments[attacker_id]
		if fighter_id in assigned:
			assigned.erase(fighter_id)
			if int(attacker_id) != selected_defend_attacker_id:
				_show_toast("BLOCKER REASSIGNED")
			if int(attacker_id) == selected_defend_attacker_id:
				_refresh_all()
				return
	if not block_assignments.has(selected_defend_attacker_id):
		block_assignments[selected_defend_attacker_id] = []
	block_assignments[selected_defend_attacker_id].append(fighter_id)
	_play_random_sound("blocking")


func _make_card_animation_visual(card: Dictionary) -> Button:
	var visual := Button.new()
	visual.size = Vector2(132, 194)
	visual.custom_minimum_size = visual.size
	visual.text = ""
	visual.add_theme_color_override("font_color", INK)
	var color := _card_color(card["kind"])
	visual.add_theme_stylebox_override("normal", _style(color.darkened(0.50), color.lightened(0.15), 3, 7))
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_add_card_art_layout(visual, card)
	return visual


func _spawn_particle_cloud(center: Vector2, color: Color, duration: float = 0.24) -> void:
	var cloud := ParticleCloud.new()
	cloud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cloud.configure(center, color, duration)
	design_surface.add_child(cloud)


func _show_opponent_card_reveal(card: Dictionary) -> void:
	if String(card.get("kind", "")) == "stat":
		return
	var slot := 0
	while computer_card_reveal_slots.has(slot):
		slot += 1
	var preview := _make_card_animation_visual(card)
	preview.name = "OpponentCardReveal"
	preview.size = Vector2(220, 310)
	preview.custom_minimum_size = preview.size
	preview.z_index = 500
	design_surface.add_child(preview)
	preview.position = _opponent_card_reveal_slot_position(slot, preview.size)
	preview.set_meta("reveal_duration", 1.5)
	preview.set_meta("gameplay_pause_duration", 0.3)
	preview.set_meta("reveal_slot", slot)
	preview.set_meta("card_name", String(card.get("name", "")))
	computer_card_reveal_slots[slot] = preview
	_expire_opponent_card_reveal(slot, preview)
	# Only the opening beat blocks play; this fixed slot remains for the full 1.5s.
	await get_tree().create_timer(0.3, true, false, true).timeout


func _opponent_card_reveal_slot_position(slot: int, card_size: Vector2) -> Vector2:
	var surface_inverse: Transform2D = design_surface.get_global_transform_with_canvas().affine_inverse()
	var lane_control: Control = fighter_lane_panels.get(1, opponent_fighters_box)
	var lane_rect: Rect2 = lane_control.get_global_rect()
	var lane_top_left: Vector2 = surface_inverse * lane_rect.position
	var lane_bottom_right: Vector2 = surface_inverse * lane_rect.end
	var gap := 18.0
	var right_edge := lane_bottom_right.x - 18.0
	var columns := maxi(1, floori((right_edge - 12.0) / (card_size.x + gap)))
	var column := slot % columns
	var row := slot / columns
	return Vector2(right_edge - card_size.x - float(column) * (card_size.x + gap), maxf(8.0, lane_top_left.y - 125.0) + float(row) * (card_size.y + 12.0))


func _expire_opponent_card_reveal(slot: int, preview: Control) -> void:
	await get_tree().create_timer(1.5, true, false, true).timeout
	if computer_card_reveal_slots.get(slot) == preview:
		computer_card_reveal_slots.erase(slot)
	if is_instance_valid(preview):
		preview.visible = false
		preview.queue_free()


func _animate_computer_card_play(card: Dictionary, target_control: Control, log_message: String) -> void:
	await _show_opponent_card_reveal(card)
	await get_tree().process_frame
	var canvas_inverse := design_surface.get_global_transform_with_canvas().affine_inverse()
	var source_global := opponent_status_panel.get_global_rect().get_center()
	var target_global := opponent_fighters_box.get_global_rect().get_center()
	if is_instance_valid(target_control):
		target_global = target_control.get_global_rect().get_center()
	var source: Vector2 = canvas_inverse * source_global
	var target: Vector2 = canvas_inverse * target_global
	var visual := _make_card_animation_visual(card)
	visual.position = source - visual.size * 0.5
	visual.pivot_offset = visual.size * 0.5
	design_surface.add_child(visual)
	_show_action_flash(log_message, 0.5)
	var flight := create_tween().set_parallel(true)
	flight.tween_property(visual, "position", target - visual.size * 0.5, 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	flight.tween_property(visual, "rotation", deg_to_rad(8.0), 0.34)
	flight.tween_property(visual, "scale", Vector2(0.82, 0.82), 0.34)
	await flight.finished
	visual.visible = false
	_spawn_particle_cloud(target, _card_color(card["kind"]), 0.20)
	await get_tree().create_timer(0.16).timeout
	visual.queue_free()


func _animate_fighter_destruction(fighter: Dictionary, log_message: String) -> void:
	_refresh_all()
	await get_tree().process_frame
	var button: Control = fighter_button_nodes.get(int(fighter["id"]))
	_show_action_flash(log_message, 0.5)
	if not is_instance_valid(button):
		await get_tree().create_timer(0.5).timeout
		return
	button.pivot_offset = button.size * 0.5
	var shake := create_tween()
	shake.tween_property(button, "rotation", deg_to_rad(7.0), 0.10)
	shake.tween_property(button, "rotation", deg_to_rad(-7.0), 0.10)
	shake.tween_property(button, "rotation", 0.0, 0.10)
	await shake.finished
	var canvas_inverse := design_surface.get_global_transform_with_canvas().affine_inverse()
	var center: Vector2 = canvas_inverse * button.get_global_rect().get_center()
	_spawn_particle_cloud(center, RED, 0.24)
	var vanish := create_tween().set_parallel(true)
	vanish.tween_property(button, "scale", Vector2(1.35, 0.10), 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	vanish.tween_property(button, "modulate:a", 0.0, 0.20)
	await vanish.finished


func _play_support_card(owner: int, hand_index: int, fighter: Dictionary, show_computer_flash: bool = true) -> void:
	if hand_index < 0 or hand_index >= hands[owner].size():
		return
	var card: Dictionary = hands[owner][hand_index]
	if String(card.get("kind", "")) == "training" and not replaying_upgrade_cards and training_cards_played_this_turn[owner] >= MAX_TRAINING_CARDS_PER_TURN:
		if owner == 0:
			_show_toast("TRAINING CARD LIMIT  //  2 OF 2")
		return
	var value := _consume_effective_card_value(owner, card)
	match card["kind"]:
		"weapon":
			fighter["attack_bonus"] += value
			fighter["weapons"].append(card["name"])
		"shield":
			fighter["defense_bonus"] += value
			fighter["shields"].append(card["name"])
		"blessing":
			if card["name"] == "Evasive":
				fighter["evasive"] = true
			elif card["name"] == "Berserker":
				var existing_berserker_stacks := _status_stacks(fighter, "berserker")
				fighter["berserker"] = true
				fighter["berserker_stacks"] = existing_berserker_stacks + 1
			_play_random_sound("blessing")
		"training":
			if card["name"] == "Shield Master":
				fighter["shield_master"] = true
			elif card["name"] == "Zen Master":
				fighter["zen"] = true
			elif card["name"] == "Explosive Master":
				fighter["explosive"] = true
			if not replaying_upgrade_cards:
				training_cards_played_this_turn[owner] += 1
	_log_event("%s gives %s [color=#d8a94b]%s[/color]." % [_owner_name(owner), _fighter_name(fighter), card["name"]], owner, show_computer_flash)
	_show_toast("%s RECEIVES %s" % [_fighter_name(fighter).to_upper(), String(card["name"]).to_upper()], 0.3)
	hands[owner].remove_at(hand_index)
	_record_card_play(owner, card, value, {"fighter_id": int(fighter["id"])})
	if owner == 0:
		selected_hand_indices.clear()


func _is_stat_upgrade_card(card: Dictionary) -> bool:
	if card.get("kind", "") != "stat":
		return false
	var value := int(card.get("value", 0))
	return value >= 1 and value <= 10


func _apply_stat_upgrade(owner: int, hand_index: int, fighter: Dictionary, axis: String, show_computer_flash: bool = true) -> bool:
	if hand_index < 0 or hand_index >= hands[owner].size():
		return false
	var card: Dictionary = hands[owner][hand_index]
	if not _is_stat_upgrade_card(card):
		return false
	if stat_cards_played_this_turn >= MAX_STAT_TRAINING_PER_TURN and not replaying_upgrade_cards:
		if owner == 0:
			_show_toast("STAT TRAINING LIMIT REACHED  //  1 OF 1")
		return false
	var value := _consume_effective_card_value(owner, card)
	if axis != "attack" and axis != "defense":
		return false
	var color := "#ff5d73" if axis == "attack" else "#57c7ff"
	if axis == "attack":
		fighter["attack_bonus"] += value
	else:
		fighter["defense_bonus"] += value
	var message := "%s adds [color=%s]+%d %s[/color] to %s." % [
		_owner_name(owner),
		color,
		value,
		axis,
		_fighter_name(fighter),
	]
	_log_event(message, owner, show_computer_flash)
	_show_toast("%s  //  +%d %s" % [_fighter_name(fighter).to_upper(), value, axis.to_upper()], 0.3)
	hands[owner].remove_at(hand_index)
	_record_card_play(owner, card, value, {"fighter_id": int(fighter["id"]), "axis": axis})
	if not replaying_upgrade_cards:
		stat_cards_played_this_turn += 1
	if owner == 0:
		selected_hand_indices.clear()
	return true


func _on_fighter_stat_slot_pressed(owner: int, fighter_id: int, axis: String) -> void:
	if input_locked or game_over or active_player != 0 or phase != PHASE_TRAIN or owner != 0:
		return
	if selected_hand_indices.size() != 1:
		_show_toast("SELECT A STAT CARD FIRST")
		return
	if stat_cards_played_this_turn >= MAX_STAT_TRAINING_PER_TURN:
		_show_toast("STAT TRAINING LIMIT REACHED  //  1 OF 1")
		return
	var hand_index := selected_hand_indices[0]
	if hand_index < 0 or hand_index >= hands[0].size() or not _is_stat_upgrade_card(hands[0][hand_index]):
		return
	var fighter := _get_fighter(owner, fighter_id)
	if fighter.is_empty():
		return
	var value := int(hands[0][hand_index]["value"])
	input_locked = true
	_show_toast("ADDING +%d %s TO %s" % [value, axis.to_upper(), _fighter_name(fighter).to_upper()], 0.3)
	_refresh_all()
	var serial := match_serial
	await get_tree().create_timer(0.3).timeout
	if serial != match_serial or game_over:
		return
	_apply_stat_upgrade(0, hand_index, fighter, axis)
	input_locked = false
	training_stage_panel.visible = new_fighter_attack > 0 or new_fighter_defense > 0
	_refresh_all()


func _play_curse_card(owner: int, hand_index: int, target: Dictionary, defer_destruction: bool = false, show_computer_flash: bool = true) -> bool:
	if hand_index < 0 or hand_index >= hands[owner].size():
		return false
	var card: Dictionary = hands[owner][hand_index]
	if owner == 1 and int(target.get("owner", -1)) == 0 and _has_artifact("first_curse_prevent") and not artifact_battle_flags.get("first_curse_prevent_used", false):
		artifact_battle_flags["first_curse_prevent_used"] = true
		_log_event("Mirror Shard shatters %s before it lands." % card["name"], 0)
		_show_toast("MIRROR SHARD  //  CURSE PREVENTED")
		hands[owner].remove_at(hand_index)
		_record_card_play(owner, card, int(card.get("value", 0)), {"fighter_id": int(target["id"])})
		return true
	if target["evasive"]:
		_queue_fighter_status_trigger(target, "EVASIVE! CURSE REJECTED", BLUE)
		_log_event("%s is Evasive and rejects [color=#8865a8]%s[/color]." % [_fighter_name(target), card["name"]], owner, show_computer_flash)
		_show_toast("EVASIVE FIGHTERS CANNOT BE CURSED")
		return false
	var value := _consume_effective_card_value(owner, card)
	match card["name"]:
		"Poison":
			var existing_poison_stacks := _status_stacks(target, "poison")
			target["poison"] = true
			target["poison_stacks"] = existing_poison_stacks + 1
		"Madness":
			var existing_madness_stacks := _status_stacks(target, "madness")
			target["madness"] = true
			target["madness_stacks"] = existing_madness_stacks + 1
		"Deathmark":
			target["damage"] = _fighter_max_defense(target)
	_log_event("%s curses %s with [color=#8865a8]%s[/color]." % [_owner_name(owner), _fighter_name(target), card["name"]], owner, show_computer_flash)
	_show_toast("%s  //  CURSED WITH %s" % [_fighter_name(target).to_upper(), String(card["name"]).to_upper()], 0.3)
	_play_random_sound("curse")
	hands[owner].remove_at(hand_index)
	_record_card_play(owner, card, value, {"fighter_id": int(target["id"])})
	if owner == 0:
		selected_hand_indices.clear()
	if not defer_destruction:
		_remove_dead_fighters()
		_check_game_over()
	return true


func _play_armageddon(owner: int, hand_index: int, show_computer_flash: bool = true) -> bool:
	if hand_index < 0 or hand_index >= hands[owner].size():
		return false
	var card: Dictionary = hands[owner][hand_index]
	if card["kind"] != "curse" or card["name"] != "Armageddon":
		return false
	var value := _consume_effective_card_value(owner, card)
	var destroyed: int = fighters[0].size() + fighters[1].size()
	_log_event("%s unleashes [color=#a78bfa]Curse Armageddon[/color]. All %d fighters are destroyed." % [_owner_name(owner), destroyed], owner, show_computer_flash)
	_show_toast("ARMAGEDDON  //  ALL FIGHTERS DESTROYED", 0.7)
	_play_random_sound("curse")
	hands[owner].remove_at(hand_index)
	_record_card_play(owner, card, value, {"battlefield": true})
	if owner == 0:
		selected_hand_indices.clear()
	for fighter_owner in 2:
		for fighter in fighters[fighter_owner]:
			fighter["damage"] = _fighter_max_defense(fighter)
	_remove_dead_fighters(show_computer_flash)
	return true


func _play_squad_card(owner: int, hand_index: int, show_computer_flash: bool = true) -> bool:
	if hand_index < 0 or hand_index >= hands[owner].size():
		return false
	var card: Dictionary = hands[owner][hand_index]
	if card["kind"] != "summon" or card["name"] != "Call in the Squad":
		return false
	if not replaying_upgrade_cards and (trained_this_turn or new_fighter_attack > 0 or new_fighter_defense > 0):
		if owner == 0:
			_show_toast("THE SQUAD CANNOT BE CALLED AFTER STARTING A NEW FIGHTER")
		return false
	var value := _consume_effective_card_value(owner, card)
	var squad := [
		_create_squad_fighter(owner, "Dirty Dan", "unblockable"),
		_create_squad_fighter(owner, "Wild Wayne", "wild_splash"),
		_create_squad_fighter(owner, "Chaste Chase", "ally_healer"),
	]
	for fighter in squad:
		fighters[owner].append(fighter)
		_queue_fighter_entrance(fighter)
		_notify_ally_trained(owner, fighter)
	if not replaying_upgrade_cards:
		squad_summoned_this_turn = true
	_log_event("%s calls in the squad: [color=#ffd166]Dirty Dan, Wild Wayne, and Chaste Chase[/color]." % _owner_name(owner), owner, show_computer_flash)
	_show_toast("THE SQUAD ARRIVES  //  THREE 3/3 FIGHTERS", 0.7)
	hands[owner].remove_at(hand_index)
	_record_card_play(owner, card, value, {"summoned": 3})
	if owner == 0:
		selected_hand_indices.clear()
	return true


func _play_heal_on_fighter(owner: int, hand_index: int, fighter: Dictionary, show_computer_flash: bool = true) -> bool:
	if hand_index < 0 or hand_index >= hands[owner].size():
		return false
	var card: Dictionary = hands[owner][hand_index]
	if not _heal_card_can_target_fighter(card):
		return false
	if int(fighter["damage"]) <= 0:
		if owner == 0:
			_show_toast("THAT FIGHTER IS UNDAMAGED")
		return false
	var value := _apply_heal_bonus(owner, _consume_effective_card_value(owner, card))
	var healed: int = min(value, int(fighter["damage"]))
	_heal_fighter_with_upgrades(owner, fighter, value)
	_log_event("%s repairs [color=#58a66b]%d damage[/color] on %s." % [_owner_name(owner), healed, _fighter_name(fighter)], owner, show_computer_flash)
	_show_toast("%s  //  HEALED %d" % [_fighter_name(fighter).to_upper(), healed], 0.3)
	hands[owner].remove_at(hand_index)
	_record_card_play(owner, card, value, {"fighter_id": int(fighter["id"]), "healed": healed})
	if owner == 0:
		selected_hand_indices.clear()
	return true


func _begin_player_attack() -> void:
	pending_attack_ids = selected_attacker_ids.duplicate()
	selected_attacker_ids.clear()
	block_assignments.clear()
	input_locked = true
	phase = PHASE_COMBAT
	_log_event("You send [color=#c33b35]%d fighter%s[/color] into the pit." % [pending_attack_ids.size(), "" if pending_attack_ids.size() == 1 else "s"])
	_play_random_sound("attacking")
	_refresh_all()
	var serial := match_serial
	await _phase_beat(0, PHASE_COMBAT, false)
	await get_tree().create_timer(0.3).timeout
	if serial != match_serial or game_over:
		return
	await _resolve_combat(0, pending_attack_ids, {})
	pending_attack_ids.clear()
	block_assignments.clear()
	input_locked = false
	_check_game_over()
	if not game_over:
		_enter_player_heal_or_end()
	else:
		_refresh_all()


func _choose_ai_blocks(attacker_ids: Array[int]) -> Dictionary:
	var assignments: Dictionary = {}
	var available: Array[int] = []
	for defender in fighters[1]:
		available.append(defender["id"])
	var sorted_attackers := attacker_ids.duplicate()
	sorted_attackers.sort_custom(func(a: int, b: int) -> bool:
		return _fighter_attack(_get_fighter(0, a)) > _fighter_attack(_get_fighter(0, b))
	)
	for attacker_id in sorted_attackers:
		var attacker := _get_fighter(0, attacker_id)
		if attacker.get("squad_role", "") == "unblockable":
			continue
		if available.is_empty():
			break
		var needed := _fighter_attack(attacker)
		var assigned: Array[int] = []
		available.sort_custom(func(a: int, b: int) -> bool:
			return _fighter_remaining(_get_fighter(1, a)) < _fighter_remaining(_get_fighter(1, b))
		)
		var absorbed := 0
		while not available.is_empty() and absorbed < needed:
			var best_id: int = available.pop_front()
			assigned.append(best_id)
			absorbed += _fighter_remaining(_get_fighter(1, best_id))
		assignments[attacker_id] = assigned
	return assignments


func _prepare_player_defense(ai_attackers: Array[int]) -> void:
	input_locked = true
	pending_attack_ids = ai_attackers.duplicate()
	block_assignments.clear()
	selected_defend_attacker_id = -1
	var attack_message := "This Computer attacks with [color=#c33b35]%d fighter%s[/color]. All ready defenders enter the pit automatically." % [
		pending_attack_ids.size(),
		"" if pending_attack_ids.size() == 1 else "s",
	]
	_log_event(attack_message, LOG_COMPUTER, false)
	_play_random_sound("attacking")
	phase = PHASE_COMBAT
	_refresh_all()
	await _show_action_flash(attack_message, 0.5)
	await get_tree().create_timer(0.5).timeout
	if game_over:
		return
	await _resolve_combat(1, pending_attack_ids, {})
	pending_attack_ids.clear()
	block_assignments.clear()
	selected_defend_attacker_id = -1
	_check_game_over()
	_refresh_all()
	if not game_over:
		_resume_ai_after_combat()


func _resolve_player_defense() -> void:
	if phase != PHASE_DEFEND or active_player != 1:
		return
	input_locked = true
	phase = PHASE_COMBAT
	_show_toast("COMBAT RESOLVING", 0.3)
	_refresh_all()
	var serial := match_serial
	await get_tree().create_timer(0.3).timeout
	if serial != match_serial or game_over:
		return
	await _resolve_combat(1, pending_attack_ids, block_assignments)
	pending_attack_ids.clear()
	block_assignments.clear()
	selected_defend_attacker_id = -1
	_check_game_over()
	_refresh_all()
	if not game_over:
		_resume_ai_after_combat()


func _resolve_combat(attacker_owner: int, attacker_ids: Array[int], assignments: Dictionary) -> void:
	var defender_owner := 1 - attacker_owner
	var participant_ids: Dictionary = {0: [], 1: []}
	for attacker_id in attacker_ids:
		var parsed_attacker_id := int(attacker_id)
		if parsed_attacker_id not in participant_ids[attacker_owner]:
			participant_ids[attacker_owner].append(parsed_attacker_id)
	for defender in fighters[defender_owner]:
		if not _is_dead(defender):
			participant_ids[defender_owner].append(int(defender["id"]))

	var initial_participants := _living_pit_participants(participant_ids)
	var contested: bool = not initial_participants[0].is_empty() and not initial_participants[1].is_empty()
	if contested:
		await _animate_pit_charge_to_center()
		_log_event("The fighters rush the middle and begin to [color=#ffd166]scuffle[/color].", attacker_owner)
	elif is_instance_valid(pit_panel):
		pit_panel.set_meta("uncontested_pit_skipped_clash", true)
	_clear_pit_damage_labels()
	var scuffle_beat := 0
	var maximum_scuffle_beats := maxi(1, round_number)
	while scuffle_beat < maximum_scuffle_beats:
		var living := _living_pit_participants(participant_ids)
		if living[0].is_empty() or living[1].is_empty():
			break
		scuffle_beat += 1
		_clear_pit_damage_labels()
		await _animate_pit_scuffle_beat(living, scuffle_beat)
		var strikes: Array[Dictionary] = []
		# Every target and roll is captured before damage is applied. Fighters killed
		# during this beat therefore still land the strike they rolled simultaneously.
		for side in 2:
			for fighter in living[side]:
				var roll := _pit_damage_roll(fighter, "scuffles", true)
				var target: Dictionary = fighter if bool(roll["self_hit"]) else _closest_pit_enemy(fighter, living[1 - side])
				if not target.is_empty():
					strikes.append({"source": fighter, "target": target, "roll": roll, "self_hit": bool(roll["self_hit"])})

		await _animate_pit_strike_lines(strikes)
		var pile_positions := await _animate_pit_fighters_to_grid(living)
		var thorn_strikes: Array[Dictionary] = []
		for strike in strikes:
			var source: Dictionary = strike["source"]
			var target: Dictionary = strike["target"]
			var roll: Dictionary = strike["roll"]
			var amount := int(roll["damage"])
			if bool(strike["self_hit"]):
				await _animate_madness_self_attack(strike)
			else:
				await _animate_pit_card_strike(strike)
			var source_name := "Madness" if bool(strike["self_hit"]) else _fighter_name(source)
			var dealt := _apply_damage_to_fighter(target, amount, source_name, false, not bool(strike["self_hit"]))
			_show_pit_damage_total(target, dealt)
			_refresh_pit_health_bars()
			if bool(strike["self_hit"]):
				continue
			var roll_description := "d%d = %d" % [int(roll["sides"]), int(roll["rolled"])]
			if amount != int(roll["rolled"]):
				roll_description += ", %d after modifiers" % amount
			_log_event("%s rolls %s and hits the closest enemy, %s." % [_fighter_name(source), roll_description, _fighter_name(target)], int(source["owner"]), false)
			if bool(source.get("lifesteal", false)) and dealt > 0:
				player_health[int(source["owner"])] += dealt
				if int(source["owner"]) == 0 and _has_upgrade_effect("lifesteal_grants_attack"):
					source["attack_bonus"] += _upgrade_total("lifesteal_grants_attack")
			var thorn_damage := int(target.get("thorns", 0))
			if int(target.get("owner", -1)) == 0 and _fighter_is_assigned_blocker(int(target["id"])):
				thorn_damage += _artifact_total("blocker_thorns")
			if thorn_damage > 0:
				thorn_strikes.append({"source": target, "target": source, "damage": thorn_damage})
		for thorn_strike in thorn_strikes:
			var thorn_dealt := _apply_damage_to_fighter(thorn_strike["target"], int(thorn_strike["damage"]), _fighter_name(thorn_strike["source"]), false)
			_show_pit_damage_total(thorn_strike["target"], thorn_dealt)
		for strike in strikes:
			if not bool(strike["self_hit"]):
				var source: Dictionary = strike["source"]
				_trigger_explosive(source, 1 - int(source["owner"]))
				_trigger_wild_splash(source, 1 - int(source["owner"]))
		_refresh_pit_health_bars()
		# Hold the complete grid and its accumulated damage totals long enough for
		# the player to read the whole simultaneous exchange.
		if is_instance_valid(pit_panel):
			pit_panel.set_meta("damage_observation_delay", 1.0)
		await get_tree().create_timer(1.0, true, false, false).timeout
		await _restore_pit_fighters_from_grid(pile_positions)
		if is_instance_valid(pit_strike_overlay):
			pit_strike_overlay.visible = false
			pit_strike_overlay.queue_redraw()
		_remove_dead_fighters()

	_clear_pit_damage_labels()
	if is_instance_valid(pit_strike_overlay):
		pit_strike_overlay.visible = false
	var survivors := _living_pit_participants(participant_ids)
	var winning_side := -1
	if not survivors[0].is_empty() and survivors[1].is_empty():
		winning_side = 0
	elif not survivors[1].is_empty() and survivors[0].is_empty():
		winning_side = 1
	elif not survivors[0].is_empty() and not survivors[1].is_empty():
		_log_event("Round %d reaches its %d-damage-round scuffle limit; both sides disengage." % [round_number, maximum_scuffle_beats], attacker_owner)
	if winning_side != -1:
		var finishing_rolls: Array[Dictionary] = []
		for survivor in survivors[winning_side]:
			finishing_rolls.append({"fighter": survivor, "roll": _pit_damage_roll(survivor, "finishes the scuffle")})
		await _animate_final_pit_rolls(finishing_rolls, 1 - winning_side)

	_finish_pit_combat_effects(participant_ids)
	_remove_dead_fighters()
	# Terminal impacts and defeat launches are fire-and-forget so they do not slow
	# the half-second scuffle cadence. Let the last set finish before heal refreshes
	# and rebuilds the pit controls.
	if is_instance_valid(combat_animator):
		var settle_time := maxf(0.55 / combat_animator.animation_speed, 0.01)
		await get_tree().create_timer(settle_time, true, false, false).timeout
		await get_tree().process_frame
	_check_game_over()


func _living_pit_participants(participant_ids: Dictionary) -> Array:
	var result: Array = [[], []]
	for side in 2:
		for fighter_id in participant_ids.get(side, []):
			var fighter := _get_fighter(side, int(fighter_id))
			if not fighter.is_empty() and not _is_dead(fighter):
				result[side].append(fighter)
	return result


func _animate_pit_scuffle_beat(living: Array, beat: int) -> void:
	if not is_instance_valid(combat_animator) or not is_instance_valid(pit_panel):
		return
	var visuals: Array[Control] = []
	for side in 2:
		for fighter in living[side]:
			var visual: Control = fighter_button_nodes.get(int(fighter["id"]))
			if is_instance_valid(visual):
				visuals.append(visual)
	await combat_animator.pit_scuffle_step(visuals, pit_panel, beat)


func _animate_pit_strike_lines(strikes: Array) -> void:
	if not is_instance_valid(pit_strike_overlay) or strikes.is_empty():
		return
	pit_strike_overlay.strikes.clear()
	for strike in strikes:
		pit_strike_overlay.strikes.append(strike)
	pit_strike_overlay.progress = 0.0
	pit_strike_overlay.visible = true
	pit_strike_overlay.set_meta("last_strike_count", strikes.size())
	pit_strike_overlay.set_meta("line_duration", PIT_TARGET_LINE_DURATION)
	var line_tween := create_tween()
	line_tween.tween_method(func(value: float) -> void:
		if is_instance_valid(pit_strike_overlay):
			pit_strike_overlay.progress = value
			pit_strike_overlay.queue_redraw()
	, 0.0, 1.0, PIT_TARGET_LINE_DURATION)
	await line_tween.finished


func _animate_pit_fighters_to_grid(living: Array) -> Dictionary:
	var pile_positions := {}
	if not is_instance_valid(pit_panel):
		return pile_positions
	var movement := create_tween().set_parallel(true)
	for side in 2:
		var side_fighters: Array = living[side]
		var grid_scale := _pit_grid_scale_for_side(side_fighters)
		var column_jitters: Dictionary = {}
		for index in side_fighters.size():
			var fighter: Dictionary = side_fighters[index]
			var visual: Control = fighter_button_nodes.get(int(fighter["id"]))
			if not is_instance_valid(visual):
				continue
			pile_positions[int(fighter["id"])] = {
				"position": visual.position,
				"scale": visual.scale,
				"pivot_offset": visual.pivot_offset,
			}
			visual.pivot_offset = visual.size * 0.5
			var column := _pit_grid_column(index, side_fighters.size())
			if not column_jitters.has(column):
				var jitter_magnitude := rng.randf_range(1.0, 15.0)
				column_jitters[column] = jitter_magnitude * (-1.0 if rng.randi() % 2 == 0 else 1.0)
			var displayed_size := visual.size * grid_scale
			var target_in_pit := _pit_grid_center(side, index, displayed_size, side_fighters.size(), float(column_jitters[column]))
			visual.set_meta("pit_grid_center", target_in_pit)
			visual.set_meta("pit_grid_scale", grid_scale)
			var target_global: Vector2 = pit_panel.get_global_transform_with_canvas() * target_in_pit
			var target_local: Vector2 = visual.get_parent().get_global_transform_with_canvas().affine_inverse() * target_global - visual.size * 0.5
			movement.tween_property(visual, "position", target_local, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
			movement.tween_property(visual, "scale", Vector2.ONE * grid_scale, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
			movement.tween_property(visual, "rotation", 0.0, 0.22)
	await movement.finished
	if is_instance_valid(pit_strike_overlay):
		pit_strike_overlay.queue_redraw()
	return pile_positions


func _pit_grid_scale_for_side(side_fighters: Array) -> float:
	if side_fighters.is_empty() or not is_instance_valid(pit_panel):
		return 1.0
	var card_size := Vector2(230.0, 170.0)
	for fighter in side_fighters:
		var visual: Control = fighter_button_nodes.get(int(fighter.get("id", -1)))
		if is_instance_valid(visual) and visual.size.x > 0.0 and visual.size.y > 0.0:
			card_size = visual.size
			break
	var count := side_fighters.size()
	var columns := count if count <= 3 else 3 + ceili(float(count - 3) / 2.0)
	var rows := 1 if count <= 3 else 2
	var horizontal_gap := 18.0
	var column_gap := 12.0
	var row_gap := 32.0
	var margin := 24.0
	var half_width := maxf(1.0, pit_panel.size.x * 0.5 - margin)
	var usable_card_width := maxf(1.0, half_width - horizontal_gap - float(maxi(0, columns - 1)) * column_gap)
	var width_scale := usable_card_width / (float(maxi(1, columns)) * card_size.x)
	var usable_card_height := maxf(1.0, pit_panel.size.y - margin * 2.0 - (row_gap if rows == 2 else 0.0))
	var height_scale := usable_card_height / (float(rows) * card_size.y)
	var scale := clampf(minf(1.0, minf(width_scale, height_scale)), 0.05, 1.0)
	pit_panel.set_meta("last_grid_scale_side_%d" % int(side_fighters[0].get("owner", 0)), scale)
	return scale


func _pit_grid_column(index: int, side_count: int) -> int:
	if side_count <= 3 or index < 3:
		return index
	return 3 + floori(float(index - 3) / 2.0)


func _pit_grid_center(side: int, index: int, card_size: Vector2, side_count: int = 1, vertical_jitter: float = 0.0) -> Vector2:
	# Up to three fighters form a single centered row with one card per column.
	# Larger teams use half-size cards: the first three retain their own columns,
	# then fighters four through twelve fill two-high overflow columns.
	if card_size.x <= 0.0 or card_size.y <= 0.0:
		card_size = Vector2(230.0, 170.0)
	var column := _pit_grid_column(index, side_count)
	var overflow_index := index - 3
	var paired_overflow := side_count > 3 and index >= 3
	var row := overflow_index % 2 if paired_overflow else -1
	var center_x := pit_panel.size.x * 0.5
	var direction := -1.0 if side == 0 else 1.0
	var horizontal_gap := 18.0
	var column_gap := 12.0
	var row_gap := 32.0
	var x := center_x + direction * (horizontal_gap + card_size.x * 0.5 + float(column) * (card_size.x + column_gap))
	var y := pit_panel.size.y * 0.5 + vertical_jitter
	if paired_overflow:
		y += (-0.5 if row == 0 else 0.5) * (card_size.y + row_gap)
	return Vector2(x, y)


func _restore_pit_fighters_from_grid(pile_positions: Dictionary) -> void:
	if pile_positions.is_empty():
		return
	var movement := create_tween().set_parallel(true)
	for fighter_id in pile_positions:
		var visual: Control = fighter_button_nodes.get(int(fighter_id))
		if not is_instance_valid(visual):
			continue
		var original: Dictionary = pile_positions[fighter_id]
		movement.tween_property(visual, "position", original["position"], 0.20).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		movement.tween_property(visual, "scale", original["scale"], 0.20).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		movement.tween_property(visual, "rotation", 0.0, 0.20)
	await movement.finished
	for fighter_id in pile_positions:
		var visual: Control = fighter_button_nodes.get(int(fighter_id))
		if is_instance_valid(visual):
			visual.pivot_offset = pile_positions[fighter_id]["pivot_offset"]


func _animate_pit_card_strike(strike: Dictionary) -> void:
	if not is_instance_valid(combat_animator):
		return
	var source: Dictionary = strike.get("source", {})
	var target: Dictionary = strike.get("target", {})
	var source_visual: Control = fighter_button_nodes.get(int(source.get("id", -1)))
	var target_visual: Control = fighter_button_nodes.get(int(target.get("id", -1)))
	if is_instance_valid(source_visual):
		source_visual.set_meta("pit_attack_duration", PIT_CARD_ATTACK_DURATION)
	await combat_animator.pit_card_attack(source_visual, target_visual)


func _animate_madness_self_attack(strike: Dictionary) -> void:
	var source: Dictionary = strike.get("source", {})
	var fighter_visual: Control = fighter_button_nodes.get(int(source.get("id", -1)))
	var banner := Label.new()
	banner.name = "MadnessSelfAttackBanner"
	banner.text = "MADNESS! SELF ATTACK!"
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.z_index = 450
	banner.add_theme_font_size_override("font_size", 58)
	banner.add_theme_color_override("font_color", Color("#ff66e8"))
	banner.add_theme_color_override("font_shadow_color", Color(0.08, 0.0, 0.10, 0.98))
	banner.add_theme_constant_override("shadow_offset_x", 4)
	banner.add_theme_constant_override("shadow_offset_y", 5)
	banner.add_theme_stylebox_override("normal", _style(Color(0.10, 0.015, 0.12, 0.88), Color("#ff66e8"), 3, 12))
	design_surface.add_child(banner)
	_center_control(banner, Vector2(1050.0, 150.0))
	design_surface.set_meta("last_madness_banner_text", banner.text)
	var previous_animation_speed := combat_animator.animation_speed if is_instance_valid(combat_animator) else 1.0
	var previous_background_speed := pit_background_player.pitch_scale if is_instance_valid(pit_background_player) else 1.0
	if is_instance_valid(combat_animator):
		combat_animator.set_animation_speed(0.5)
	if is_instance_valid(pit_background_player):
		pit_background_player.pitch_scale = 0.5
	var madness_sound := _play_random_sound("pit_hit", 0.5)
	if is_instance_valid(fighter_visual):
		fighter_visual.set_meta("madness_animation_speed", 0.5)
		fighter_visual.set_meta("madness_sound_pitch", madness_sound.pitch_scale if is_instance_valid(madness_sound) else 0.0)
	await _animate_pit_card_strike(strike)
	if is_instance_valid(combat_animator):
		combat_animator.set_animation_speed(previous_animation_speed)
	if is_instance_valid(pit_background_player):
		pit_background_player.pitch_scale = previous_background_speed
	if is_instance_valid(banner):
		banner.queue_free()


func _show_pit_damage_total(fighter: Dictionary, amount: int) -> void:
	var fighter_id := int(fighter.get("id", -1))
	var label: Label = pit_damage_label_nodes.get(fighter_id)
	if not is_instance_valid(label):
		var visual: Control = fighter_button_nodes.get(fighter_id)
		if not is_instance_valid(visual):
			return
		label = Label.new()
		label.name = "PitDamageAmount"
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.z_index = 220
		label.add_theme_font_size_override("font_size", 54)
		label.add_theme_color_override("font_color", Color("#ff394f"))
		label.add_theme_color_override("font_shadow_color", Color(0.08, 0.0, 0.0, 0.98))
		label.add_theme_constant_override("shadow_offset_x", 3)
		label.add_theme_constant_override("shadow_offset_y", 4)
		label.set_meta("damage_total", 0)
		visual.add_child(label)
		pit_damage_label_nodes[fighter_id] = label
	var total := int(label.get_meta("damage_total", 0)) + maxi(0, amount)
	label.set_meta("damage_total", total)
	label.text = "-%d" % total if total > 0 else "0"


func _show_poison_damage(fighter: Dictionary, amount: int) -> void:
	if amount <= 0:
		return
	design_surface.set_meta("last_poison_popup_amount", amount)
	_queue_fighter_status_trigger(fighter, "POISON: -%d" % amount, Color("#63f28b"), "PoisonDamagePopup", 16, {"poison_damage":amount})


func _queue_fighter_status_trigger(fighter: Dictionary, message: String, color: Color, node_name := "FighterStatusTrigger", font_size := 22, metadata: Dictionary = {}) -> void:
	if fighter.is_empty() or message.is_empty():
		return
	fighter_status_trigger_queue.append({
		"fighter": fighter,
		"message": message,
		"color": color,
		"node_name": node_name,
		"font_size": font_size,
		"metadata": metadata.duplicate(true),
	})
	if not fighter_status_trigger_running:
		_run_fighter_status_trigger_queue()


func _run_fighter_status_trigger_queue() -> void:
	if fighter_status_trigger_running:
		return
	fighter_status_trigger_running = true
	while not fighter_status_trigger_queue.is_empty():
		var entry: Dictionary = fighter_status_trigger_queue.pop_front()
		var fighter: Dictionary = entry["fighter"]
		var visual: Control = fighter_button_nodes.get(int(fighter.get("id", -1)))
		if not is_instance_valid(visual):
			continue
		var label := FighterTriggerLabel.new()
		label.game = self
		label.fighter_id = int(fighter.get("id", -1))
		label.name = String(entry["node_name"])
		label.text = String(entry["message"])
		label.size = Vector2(160, 44) if int(entry["font_size"]) <= 16 else Vector2(380, 82)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.z_index = 430
		label.add_theme_font_size_override("font_size", int(entry["font_size"]))
		var color: Color = entry["color"]
		label.add_theme_color_override("font_color", color)
		label.add_theme_color_override("font_shadow_color", Color(0.0, 0.015, 0.025, 0.98))
		label.add_theme_constant_override("shadow_offset_x", 2)
		label.add_theme_constant_override("shadow_offset_y", 3)
		label.add_theme_stylebox_override("normal", _style(Color(0.01, 0.035, 0.055, 0.86), color, 1, 7))
		label.set_meta("display_duration", 1.5)
		for key in (entry["metadata"] as Dictionary):
			label.set_meta(StringName(key), entry["metadata"][key])
		design_surface.add_child(label)
		label._process(0.0)
		await get_tree().create_timer(1.5, true, false, true).timeout
		if is_instance_valid(label):
			label.visible = false
			label.queue_free()
	fighter_status_trigger_running = false


func _queue_free_instance(instance_id: int) -> void:
	var instance := instance_from_id(instance_id)
	if instance is Node and is_instance_valid(instance):
		(instance as Node).queue_free()


func _clear_pit_damage_labels() -> void:
	for label in pit_damage_label_nodes.values():
		if is_instance_valid(label):
			label.queue_free()
	pit_damage_label_nodes.clear()


func _closest_pit_enemy(source: Dictionary, enemies: Array) -> Dictionary:
	if enemies.is_empty():
		return {}
	var closest: Dictionary = enemies[0]
	var source_visual: Control = fighter_button_nodes.get(int(source["id"]))
	if not is_instance_valid(source_visual):
		return closest
	var source_center := source_visual.get_global_rect().get_center()
	var closest_distance := INF
	for enemy in enemies:
		var enemy_visual: Control = fighter_button_nodes.get(int(enemy["id"]))
		if not is_instance_valid(enemy_visual):
			continue
		var distance := source_center.distance_squared_to(enemy_visual.get_global_rect().get_center())
		if distance < closest_distance or (is_equal_approx(distance, closest_distance) and int(enemy["id"]) < int(closest["id"])):
			closest = enemy
			closest_distance = distance
	return closest


func _wait_final_roll_duration(duration: float) -> bool:
	var remaining := duration
	while remaining > 0.0:
		if final_roll_animation_skipped:
			return false
		var step := minf(0.05, remaining)
		await get_tree().create_timer(step, true, false, false).timeout
		remaining -= step
	return not final_roll_animation_skipped


func _create_final_roll_label() -> Label:
	var label := Label.new()
	label.name = "FinalRollNumber"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 220
	label.add_theme_font_size_override("font_size", 42)
	label.add_theme_color_override("font_color", GOLD)
	label.add_theme_color_override("font_shadow_color", Color(0.08, 0.0, 0.0, 0.95))
	label.add_theme_constant_override("shadow_offset_x", 3)
	label.add_theme_constant_override("shadow_offset_y", 4)
	label.add_theme_stylebox_override("normal", _style(Color(0.055, 0.025, 0.08, 0.90), GOLD, 3, 12))
	return label


func _animate_final_pit_rolls(finishing_rolls: Array[Dictionary], target_owner: int) -> void:
	if finishing_rolls.is_empty() or not is_instance_valid(design_surface):
		return
	final_roll_animation_active = true
	final_roll_animation_skipped = false
	var display_rng := RandomNumberGenerator.new()
	display_rng.randomize()
	var total_damage := 0
	await _arrange_final_pit_attackers(finishing_rolls)
	var lifted_attackers := _lift_final_attackers(finishing_rolls)

	for finish in finishing_rolls:
		if final_roll_animation_skipped:
			break
		var fighter: Dictionary = finish["fighter"]
		var roll: Dictionary = finish["roll"]
		var label := _create_final_roll_label()
		var fighter_visual: Control = fighter_button_nodes.get(int(fighter["id"]))
		if is_instance_valid(fighter_visual):
			fighter_visual.add_child(label)
			label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			label.offset_left = 10.0
			label.offset_top = 18.0
			label.offset_right = -10.0
			label.offset_bottom = -18.0
		else:
			design_surface.add_child(label)
			_center_control(label, Vector2(260.0, 140.0))
		label.set_meta("player_damage_roll_duration_scale", 0.5)
		for tick in maxi(1, floori(float(DICE_RANDOM_NUMBER_TICKS) * 0.5)):
			if final_roll_animation_skipped or not is_instance_valid(label):
				break
			label.text = str(display_rng.randi_range(1, maxi(1, int(roll["sides"]))))
			if not await _wait_final_roll_duration(DICE_RANDOM_NUMBER_INTERVAL):
				break
		if final_roll_animation_skipped or not is_instance_valid(label):
			if is_instance_valid(label):
				label.queue_free()
			if final_roll_animation_skipped:
				break
			continue
		label.text = "DAMAGE %d" % int(roll["damage"])
		label.add_theme_font_size_override("font_size", 28)
		if not await _wait_final_roll_duration(0.125):
			if is_instance_valid(label):
				label.queue_free()
			break
		if is_instance_valid(label):
			label.queue_free()
		var amount := int(roll["damage"])
		if bool(roll["self_hit"]):
			_apply_damage_to_fighter(fighter, amount, "Madness")
			continue
		var target_visual: Control = player_health_bar if target_owner == 0 else opponent_health_bar
		if not is_instance_valid(target_visual):
			target_visual = _player_animation_target(target_owner)
		var lethal_hit := _player_hit_will_be_lethal(target_owner, amount, 1 - target_owner)
		var previous_background_speed := pit_background_player.pitch_scale if is_instance_valid(pit_background_player) else 1.0
		var lethal_sound: AudioStreamPlayer = null
		if is_instance_valid(fighter_visual) and is_instance_valid(combat_animator):
			fighter_visual.set_meta("final_player_attack", true)
			fighter_visual.set_meta("lethal_player_attack", lethal_hit)
			var previous_animation_speed := combat_animator.animation_speed
			if lethal_hit:
				# Slow the fight bed with the killing lunge, then restore it as soon as
				# the impact animation has landed.
				if is_instance_valid(pit_background_player):
					pit_background_player.pitch_scale = 0.5
				lethal_sound = _play_random_sound("attacking", 0.5)
				fighter_visual.set_meta("lethal_attack_pitch", lethal_sound.pitch_scale if is_instance_valid(lethal_sound) else 0.0)
				fighter_visual.set_meta("lethal_animation_speed", 0.5)
				combat_animator.set_animation_speed(0.5)
			var apex_audio: Array = [pit_background_player, lethal_sound] if lethal_hit else []
			await combat_animator.pit_player_finisher(fighter_visual, target_visual, amount, design_surface, 0.75 if lethal_hit else 1.0, apex_audio)
			if lethal_hit:
				combat_animator.set_animation_speed(previous_animation_speed)
				if is_instance_valid(pit_background_player):
					pit_background_player.pitch_scale = previous_background_speed
		if not lethal_hit:
			_play_random_sound("pit_hit")
		_damage_player(target_owner, amount, 1 - target_owner)
		total_damage += amount
		_log_event("%s survives the scuffle, rolls d%d = %d, and deals [color=#c33b35]%d damage[/color] to %s." % [_fighter_name(fighter), int(roll["sides"]), int(roll["rolled"]), amount, _owner_name(target_owner)], 1 - target_owner, false)
		if bool(fighter.get("lifesteal", false)):
			player_health[1 - target_owner] += amount
		_trigger_explosive(fighter, target_owner)
		_trigger_wild_splash(fighter, target_owner)
		if lethal_hit:
			# A player death ends the finishing sequence immediately. Any remaining
			# survivor rolls were only pending resolution, so neither their damage nor
			# their secondary effects should be applied after the fatal impact.
			break

	if not final_roll_animation_skipped:
		var total_label := _create_final_roll_label()
		total_label.name = "FinalRollTotal"
		total_label.text = "TOTAL DAMAGE  %d\nTO %s" % [total_damage, "YOU" if target_owner == 0 else "THIS COMPUTER"]
		total_label.add_theme_font_size_override("font_size", 48)
		total_label.z_index = 700
		design_surface.add_child(total_label)
		_center_control(total_label, Vector2(700.0, 180.0))
		await _wait_final_roll_duration(0.75)
		if is_instance_valid(total_label):
			total_label.queue_free()
	_restore_lifted_final_attackers(lifted_attackers)
	final_roll_animation_active = false


func _lift_final_attackers(finishing_rolls: Array[Dictionary]) -> Dictionary:
	var lifted := {}
	if not is_instance_valid(design_surface):
		return lifted
	for finish in finishing_rolls:
		var fighter: Dictionary = finish.get("fighter", {})
		var fighter_id := int(fighter.get("id", -1))
		var visual: Control = fighter_button_nodes.get(fighter_id)
		if not is_instance_valid(visual) or visual.get_parent() == design_surface:
			continue
		var old_parent := visual.get_parent()
		lifted[fighter_id] = {
			"parent": old_parent,
			"index": visual.get_index(),
			"z_index": visual.z_index,
		}
		visual.reparent(design_surface, true)
		visual.z_index = 400
		visual.set_meta("finisher_lifted_above_pit", true)
	return lifted


func _restore_lifted_final_attackers(lifted: Dictionary) -> void:
	for fighter_id in lifted:
		var visual: Control = fighter_button_nodes.get(int(fighter_id))
		var state: Dictionary = lifted[fighter_id]
		var old_parent := state.get("parent") as Node
		if not is_instance_valid(visual) or not is_instance_valid(old_parent):
			continue
		visual.reparent(old_parent, true)
		old_parent.move_child(visual, mini(int(state.get("index", 0)), old_parent.get_child_count() - 1))
		visual.z_index = int(state.get("z_index", 0))


func _arrange_final_pit_attackers(finishing_rolls: Array[Dictionary]) -> void:
	if finishing_rolls.is_empty() or not is_instance_valid(pit_panel):
		return
	var valid_visuals: Array[Control] = []
	for finish in finishing_rolls:
		var fighter: Dictionary = finish["fighter"]
		var visual: Control = fighter_button_nodes.get(int(fighter["id"]))
		if is_instance_valid(visual):
			valid_visuals.append(visual)
	if valid_visuals.is_empty():
		return
	var widest_card := 230.0
	for visual in valid_visuals:
		widest_card = maxf(widest_card, visual.size.x)
	var edge_margin := 24.0
	var card_gap := 12.0
	var available_width := maxf(1.0, pit_panel.size.x - edge_margin * 2.0 - card_gap * float(maxi(0, valid_visuals.size() - 1)))
	var finisher_scale := clampf(available_width / (widest_card * float(valid_visuals.size())), 0.05, 1.0)
	var spacing := widest_card * finisher_scale + card_gap
	var line_width := spacing * float(maxi(0, valid_visuals.size() - 1))
	var movement := create_tween().set_parallel(true)
	for index in valid_visuals.size():
		var visual := valid_visuals[index]
		var target_in_pit := Vector2(pit_panel.size.x * 0.5 - line_width * 0.5 + float(index) * spacing, pit_panel.size.y * 0.58)
		var target_global: Vector2 = pit_panel.get_global_transform_with_canvas() * target_in_pit
		var target_local: Vector2 = visual.get_parent().get_global_transform_with_canvas().affine_inverse() * target_global - visual.size * 0.5
		movement.tween_property(visual, "position", target_local, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		movement.tween_property(visual, "scale", Vector2.ONE * finisher_scale, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		movement.tween_property(visual, "rotation", 0.0, 0.28)
		visual.set_meta("final_attacker_fit_scale", finisher_scale)
	await movement.finished


func _pit_damage_roll(fighter: Dictionary, verb: String, against_fighter: bool = false) -> Dictionary:
	var sides := maxi(1, _fighter_attack(fighter))
	var rolled := rng.randi_range(1, sides)
	var amount := rolled
	var self_hit := false
	var relation := FactionData.triangle_relation(faction_ids[int(fighter["owner"])], faction_ids[1 - int(fighter["owner"])])
	if relation > 0:
		amount = ceili(float(amount) * 1.25)
	elif relation < 0:
		amount = maxi(1, floori(float(amount) * 0.80))
	if int(fighter.get("owner", -1)) == 0 and _has_artifact("first_attack_bonus") and int(artifact_battle_flags.get("first_attack_round", -1)) != round_number:
		artifact_battle_flags["first_attack_round"] = round_number
		amount += _artifact_total("first_attack_bonus")
		_log_event("War Drum gives %s +%d damage for the opening roll." % [_fighter_name(fighter), _artifact_total("first_attack_bonus")], 0)
	if int(fighter.get("reduction_combats", 0)) > 0:
		var reduction := int(fighter.get("combat_damage_reduction", 0))
		amount = maxi(0, amount - reduction)
		_queue_fighter_status_trigger(fighter, "LOGIC VIRUS: -%d DAMAGE" % reduction, PURPLE)
	var madness_stacks := _status_stacks(fighter, "madness")
	if madness_stacks > 0 and rng.randf() < minf(1.0, 0.25 * madness_stacks):
		self_hit = true
		_queue_fighter_status_trigger(fighter, "MADNESS TRIGGERED!", PURPLE)
		_log_event("[color=#8865a8]Madness![/color] %s turns its %d damage on itself." % [_fighter_name(fighter), amount], int(fighter["owner"]))
	var berserker_stacks := _status_stacks(fighter, "berserker")
	if berserker_stacks > 0 and rng.randf() < minf(1.0, 0.25 * berserker_stacks):
		amount *= 2
		_queue_fighter_status_trigger(fighter, "BERSERKER: DOUBLE DAMAGE!", GOLD)
		_log_event("[color=#d8a94b]Berserker![/color] %s deals double damage as it %s." % [_fighter_name(fighter), verb], int(fighter["owner"]))
	if against_fighter and not self_hit:
		amount += int(fighter.get("pierce", 0))
	return {"damage": amount, "self_hit": self_hit, "critical": relation > 0, "sides": sides, "rolled": rolled}


func _finish_pit_combat_effects(participant_ids: Dictionary) -> void:
	for side in 2:
		for fighter_id in participant_ids.get(side, []):
			var fighter := _get_fighter(side, int(fighter_id))
			if fighter.is_empty():
				continue
			if int(fighter.get("reduction_combats", 0)) > 0:
				fighter["reduction_combats"] = int(fighter["reduction_combats"]) - 1
				if int(fighter["reduction_combats"]) <= 0:
					fighter["combat_damage_reduction"] = 0
			if int(fighter.get("recoil_damage", 0)) > 0:
				_apply_damage_to_fighter(fighter, int(fighter["recoil_damage"]), "Overwind recoil")
				fighter["recoil_damage"] = 0
			if _is_dead(fighter):
				continue
			if int(fighter.get("survive_combat_attack", 0)) > 0:
				var attack_gain := int(fighter["survive_combat_attack"])
				fighter["attack_bonus"] += attack_gain
				_queue_fighter_status_trigger(fighter, "EMBERHEART: +%d ATTACK" % attack_gain, GOLD)
			if _fighter_is_assigned_blocker(int(fighter["id"])) and int(fighter.get("counterattack_bonus", 0)) > 0:
				fighter["attack_bonus"] += int(fighter["counterattack_bonus"])


func _animate_pit_charge_to_center() -> void:
	if not is_instance_valid(combat_animator) or not is_instance_valid(pit_panel):
		return
	await get_tree().process_frame
	var computer_cards: Array[Control] = []
	var human_cards: Array[Control] = []
	for owner in 2:
		for fighter in fighters[owner]:
			var fighter_id := int(fighter["id"])
			if not _fighter_in_pit(owner, fighter_id):
				continue
			var visual: Control = fighter_button_nodes.get(fighter_id)
			if not is_instance_valid(visual):
				continue
			if owner == 0:
				human_cards.append(visual)
			else:
				computer_cards.append(visual)
	await combat_animator.pit_charge(computer_cards, human_cards, pit_panel)


func _trigger_explosive(source: Dictionary, target_owner: int) -> void:
	if not source["explosive"]:
		return
	var targets: Array[Dictionary] = []
	for fighter in fighters[target_owner]:
		if not _is_dead(fighter):
			targets.append(fighter)
	if targets.is_empty():
		return
	_log_event("[color=#d8a94b]Explosive Master[/color] splashes the opposing stable for 2.", int(source["owner"]))
	for fighter in targets:
		_apply_damage_to_fighter(fighter, 2, "Explosive Master")


func _trigger_wild_splash(source: Dictionary, target_owner: int) -> void:
	if source.get("squad_role", "") != "wild_splash" or rng.randf() >= 0.15:
		return
	var splash := maxi(1, roundi(float(_fighter_attack(source)) * 0.8))
	var targets: Array[Dictionary] = []
	for fighter in fighters[target_owner]:
		if not _is_dead(fighter):
			targets.append(fighter)
	if targets.is_empty():
		return
	_log_event("[color=#ffd166]Wild Wayne erupts![/color] He deals %d splash damage to the opposing stable." % splash, int(source["owner"]))
	for fighter in targets:
		_apply_damage_to_fighter(fighter, splash, "Wild Wayne")


func _apply_damage_to_fighter(fighter: Dictionary, amount: int, source: String, animate_impact: bool = true, play_impact_sound: bool = true) -> int:
	if amount <= 0 or fighter.is_empty():
		return 0
	if phase == PHASE_COMBAT and play_impact_sound:
		_play_random_sound("pit_hit")
	if fighter["zen"]:
		fighter["zen"] = false
		_log_event("%s's [color=#5089a6]Zen Master[/color] prevents %d damage from %s." % [_fighter_name(fighter), amount, source], int(fighter["owner"]))
		return 0
	var prevention := int(fighter.get("damage_prevention", 0))
	if prevention > 0:
		var prevented := mini(prevention, amount)
		amount -= prevented
		fighter["damage_prevention"] = prevention - prevented
		_queue_fighter_status_trigger(fighter, "PEARL AEGIS: -%d DAMAGE" % prevented, BLUE)
		_log_event("%s's Pearl Aegis prevents %d damage." % [_fighter_name(fighter), prevented], int(fighter["owner"]))
		if amount <= 0:
			return 0
	var was_alive := not _is_dead(fighter)
	fighter["damage"] += amount
	if _is_dead(fighter) and bool(fighter.get("deathless_once", false)):
		fighter["deathless_once"] = false
		fighter["damage"] = maxi(0, _fighter_max_defense(fighter) - 1)
		_queue_fighter_status_trigger(fighter, "DEATHLESS OATH: SURVIVED!", GREEN)
		_log_event("%s's Deathless Oath leaves it at 1 defense." % _fighter_name(fighter), int(fighter["owner"]))
	elif was_alive and _is_dead(fighter) and int(fighter.get("shield_break_heal", 0)) > 0:
		var break_heal := int(fighter["shield_break_heal"])
		fighter["shield_break_heal"] = 0
		fighter["damage"] = maxi(0, int(fighter["damage"]) - break_heal)
	elif was_alive and _is_dead(fighter) and int(fighter.get("shield_break_draw", 0)) > 0:
		var draw_owner := int(fighter["owner"])
		fighter["shield_break_draw"] = 0
		_draw_card(draw_owner, false)
	var visual: Control = fighter_button_nodes.get(int(fighter["id"]))
	if animate_impact and is_instance_valid(combat_animator):
		combat_animator.impact(visual, amount, false)
	var owner := int(fighter["owner"])
	var faction := FactionData.faction_by_id(faction_ids[owner])
	if String(faction.get("passive", {}).get("effect", "")) == "first_ally_damaged_gain_attack" and not faction_round_flags[owner].get("damage_boosted", false):
		fighter["attack_bonus"] += int(faction["passive"].get("value", 1)) + (_upgrade_total("passive_value_bonus") if owner == 0 else 0)
		faction_round_flags[owner]["damage_boosted"] = true
	return amount


func _remove_dead_fighters(show_computer_flash: bool = true) -> void:
	for owner in 2:
		for index in range(fighters[owner].size() - 1, -1, -1):
			var fighter: Dictionary = fighters[owner][index]
			if _is_dead(fighter):
				if owner == 1:
					encounter_enemy_fighters_killed += 1
				var defeated_button: Control = fighter_button_nodes.get(int(fighter["id"]))
				if is_instance_valid(defeated_button) and defeated_button.visible:
					combat_animator.fighter_defeat(defeated_button)
				_log_event("[color=#c33b35]%s is destroyed.[/color]" % _fighter_name(fighter), active_player, show_computer_flash)
				var rival := 1 - owner
				var rival_faction := FactionData.faction_by_id(faction_ids[rival])
				if String(rival_faction.get("passive", {}).get("effect", "")) == "enemy_destroyed_heal_player":
					player_health[rival] += int(rival_faction["passive"].get("value", 2)) + (_upgrade_total("passive_value_bonus") if rival == 0 else 0)
				if owner == 1 and _has_artifact("enemy_death_heal"):
					player_health[0] += _artifact_total("enemy_death_heal")
					_log_event("Blood Cup drinks the knockout and heals you for %d." % _artifact_total("enemy_death_heal"), 0)
				if owner == 0 and _has_artifact("first_ally_death_draw") and not artifact_battle_flags.get("first_ally_death_draw_used", false):
					artifact_battle_flags["first_ally_death_draw_used"] = true
					for draw_index in _artifact_total("first_ally_death_draw"):
						_draw_card(0, false)
					_log_event("Grave Lantern draws a card from your first fallen fighter.", 0)
				if owner == 0 and bool(fighter.get("faction_summon", false)) and _has_upgrade_effect("first_summon_death_player_damage") and not upgrade_battle_flags.get("first_summon_death_damage_used", false):
					upgrade_battle_flags["first_summon_death_damage_used"] = true
					_damage_player(1, _upgrade_total("first_summon_death_player_damage"), 0)
				if owner == 0 and _has_upgrade_effect("transfer_attack_on_death"):
					var weakest: Dictionary = {}
					for ally in fighters[0]:
						if ally != fighter and not _is_dead(ally) and (weakest.is_empty() or _fighter_attack(ally) < _fighter_attack(weakest)):
							weakest = ally
					if not weakest.is_empty():
						weakest["attack_bonus"] += floori(float(_fighter_attack(fighter)) * float(_upgrade_total("transfer_attack_on_death")) / 100.0)
				fighters[owner].remove_at(index)
				if owner == 0 and bool(fighter.get("faction_summon", false)) and _has_upgrade_effect("first_summon_death_reborn") and not upgrade_battle_flags.get("first_summon_reborn_used", false):
					upgrade_battle_flags["first_summon_reborn_used"] = true
					var reborn_upgrade: Dictionary = UpgradeData.all_upgrades().filter(func(item: Dictionary) -> bool: return item["effect"] == "first_summon_death_reborn")[0]
					var scrapling := _create_fighter(0, int(reborn_upgrade.get("attack", 2)), int(reborn_upgrade.get("defense", 4)))
					scrapling["name"] = "Scrapling"
					fighters[0].append(scrapling)
					_queue_fighter_entrance(scrapling)


func _run_ai_turn(serial: int) -> void:
	if game_over or serial != match_serial:
		return
	var cards_drawn := _draw_to_eight(1)
	_sort_hand_by_type_and_value(1)
	if cards_drawn > 0:
		var draw_message := "This Computer draws %d card%s." % [cards_drawn, "" if cards_drawn == 1 else "s"]
		_show_toast("THIS COMPUTER DRAWS %d CARD%s" % [cards_drawn, "" if cards_drawn == 1 else "S"], 0.5)
		await _show_action_flash(draw_message, 0.5)
		await get_tree().create_timer(0.5).timeout
	has_drawn = true
	phase = PHASE_TRAIN
	_refresh_all()
	await _phase_beat(1, PHASE_TRAIN, false)
	if game_over or serial != match_serial:
		return
	await _ai_cast_armageddon_before_creatures()
	if game_over or serial != match_serial:
		return
	await _ai_train_fighter()
	if game_over or serial != match_serial:
		return
	await get_tree().create_timer(0.5).timeout
	await _ai_play_support_cards()
	if game_over or serial != match_serial:
		return
	await get_tree().create_timer(0.5).timeout
	if _consume_opening_attack_skip(1):
		var skip_message := "This Computer went first, so its opening attack phase is skipped."
		_log_event(skip_message, LOG_COMPUTER, false)
		await _show_action_flash(skip_message, _opening_sequence_duration(0.6))
		_resume_ai_after_combat(serial)
		return
	var attackers: Array[int] = []
	for fighter in fighters[1]:
		if not _is_dead(fighter):
			attackers.append(int(fighter["id"]))
	if attackers.is_empty():
		if is_instance_valid(pit_panel):
			pit_panel.set_meta("computer_empty_pit_skipped", true)
		var no_attack_message := "This Computer has no fighter ready to attack and skips the pit."
		_log_event(no_attack_message, LOG_COMPUTER, false)
		await _show_action_flash(no_attack_message, 0.5)
		await get_tree().create_timer(0.5).timeout
		_resume_ai_after_combat(serial)
		return
	if is_instance_valid(pit_panel):
		pit_panel.set_meta("computer_empty_pit_skipped", false)
	phase = PHASE_ATTACK
	_start_pit_audio()
	_refresh_all()
	await _phase_beat(1, PHASE_ATTACK, false)
	if game_over or serial != match_serial:
		return
	await get_tree().create_timer(0.5).timeout
	_prepare_player_defense(attackers)


func _resume_ai_after_combat(serial: int = -1) -> void:
	if serial == -1:
		serial = match_serial
	await get_tree().create_timer(0.5).timeout
	input_locked = true
	_stop_pit_audio(true)
	if _has_playable_heal_card(1) or _has_squad_heal(1):
		phase = PHASE_HEAL
		_refresh_all()
		await _phase_beat(1, PHASE_HEAL, false)
		if game_over or serial != match_serial:
			return
		await _ai_play_heal()
	else:
		_log_event("This Computer has no valid heals and skips its heal phase.", LOG_COMPUTER, false)
	_apply_round_end_passive(1)
	await get_tree().create_timer(0.5).timeout
	var end_message := "This Computer ends its turn."
	_log_event(end_message, LOG_COMPUTER, false)
	_show_toast("THIS COMPUTER  //  END TURN", 0.3)
	_refresh_all()
	await _show_action_flash(end_message, 0.5)
	await get_tree().create_timer(0.5).timeout
	_play_phase_cue()
	if serial != match_serial:
		return
	await _advance_turn_after(1)


func _ai_train_fighter() -> void:
	if fighters_trained_this_turn[1] >= MAX_FIGHTERS_TRAINED_PER_TURN:
		return
	var stat_indices: Array[int] = []
	for index in hands[1].size():
		if hands[1][index]["kind"] == "stat":
			stat_indices.append(index)
	if stat_indices.size() < 2:
		var no_train_message := "This Computer cannot train a new fighter."
		_log_event(no_train_message, LOG_COMPUTER, false)
		await _show_action_flash(no_train_message, 0.5)
		return
	stat_indices.sort_custom(func(a: int, b: int) -> bool:
		return int(hands[1][a]["value"]) > int(hands[1][b]["value"])
	)
	var attack_index := stat_indices[0]
	var defense_index := stat_indices[1]
	var attack_card: Dictionary = hands[1][attack_index]
	var defense_card: Dictionary = hands[1][defense_index]
	var train_message := "This Computer assembles a new fighter from two stat cards."
	await _animate_computer_card_play(attack_card, opponent_fighters_box, train_message)
	if game_over or active_player != 1:
		return
	var attack := _consume_effective_card_value(1, attack_card)
	var defense := _consume_effective_card_value(1, defense_card)
	var fighter := _create_fighter(1, attack, defense)
	train_message = "This Computer trains [color=#c33b35]%s (%d/%d)[/color]." % [_fighter_name(fighter), attack, defense]
	await get_tree().create_timer(0.5).timeout
	await _animate_computer_card_play(defense_card, opponent_fighters_box, train_message)
	if game_over or active_player != 1:
		return
	var remove_indices := [attack_index, defense_index]
	remove_indices.sort()
	remove_indices.reverse()
	for index in remove_indices:
		hands[1].remove_at(index)
	var ai_pair_info := {"target_class":"creation_slot", "creation_pair_id":int(fighter["id"]), "pair_attack":attack, "pair_defense":defense}
	var ai_attack_info := ai_pair_info.duplicate(true); ai_attack_info["creation_axis"] = "attack"; ai_attack_info["new_fighter_axis"] = "attack"
	var ai_defense_info := ai_pair_info.duplicate(true); ai_defense_info["creation_axis"] = "defense"; ai_defense_info["new_fighter_axis"] = "defense"
	_record_card_play(1, attack_card, attack, ai_attack_info)
	_record_card_play(1, defense_card, defense, ai_defense_info)
	fighters[1].append(fighter)
	_queue_fighter_entrance(fighter)
	_notify_ally_trained(1, fighter)
	fighters_trained_this_turn[1] += 1
	trained_this_turn = true
	_log_event(train_message, LOG_COMPUTER, false)
	_refresh_all()


func _ai_cast_armageddon_before_creatures() -> bool:
	if _ai_armageddon_score() <= 0.0:
		return false
	var armageddon_index := -1
	for index in hands[1].size():
		var card: Dictionary = hands[1][index]
		if String(card.get("kind", "")) == "curse" and String(card.get("name", "")) == "Armageddon":
			armageddon_index = index
			break
	if armageddon_index < 0:
		return false
	var armageddon: Dictionary = hands[1][armageddon_index]
	var message := "This Computer unleashes [color=#a78bfa]Curse Armageddon[/color]."
	await _animate_computer_card_play(armageddon, pit_panel, message)
	if game_over or active_player != 1:
		return false
	_play_armageddon(1, armageddon_index, false)
	if is_instance_valid(pit_panel):
		pit_panel.set_meta("armageddon_played_before_creatures", true)
	_refresh_all()
	return true


func _ai_play_support_cards() -> void:
	while true:
		if game_over or active_player != 1:
			return
		var played := false
		var faction_play := _ai_best_faction_play()
		if not faction_play.is_empty():
			var faction_index := int(faction_play["index"])
			var faction_card: Dictionary = hands[1][faction_index]
			var faction_target: Dictionary = faction_play.get("target", {})
			var faction_message := "This Computer deploys [color=#ffd166]%s[/color]." % faction_card["name"]
			await _show_opponent_card_reveal(faction_card)
			await _show_action_flash(faction_message, 0.35)
			if game_over or active_player != 1:
				return
			_play_faction_card(1, faction_index, faction_target)
			_refresh_all()
			played = true
			await get_tree().create_timer(0.5).timeout
			continue
		for index in hands[1].size():
			var card: Dictionary = hands[1][index]
			if String(card.get("kind", "")) == "training" and training_cards_played_this_turn[1] >= MAX_TRAINING_CARDS_PER_TURN:
				continue
			if card.has("faction_id"):
				continue # Faction cards are considered together above, including holding them.
			elif _is_stat_upgrade_card(card) and stat_cards_played_this_turn < MAX_STAT_TRAINING_PER_TURN and not fighters[1].is_empty():
				var target := _best_ai_fighter()
				_refresh_all()
				await get_tree().process_frame
				var target_button: Control = fighter_button_nodes.get(int(target["id"]))
				var axis := "attack" if _fighter_attack(target) <= _fighter_max_defense(target) else "defense"
				var color := "#ff5d73" if axis == "attack" else "#57c7ff"
				var stat_message := "This Computer adds [color=%s]+%d %s[/color] to %s." % [
					color,
					int(card["value"]),
					axis,
					_fighter_name(target),
				]
				await _animate_computer_card_play(card, target_button, stat_message)
				if game_over or active_player != 1:
					return
				_apply_stat_upgrade(1, index, target, axis, false)
				_refresh_all()
				played = true
				break
			elif card["kind"] in ["weapon", "shield", "blessing", "training"] and not fighters[1].is_empty():
				var target := _best_ai_fighter()
				_refresh_all()
				await get_tree().process_frame
				var target_button: Control = fighter_button_nodes.get(int(target["id"]))
				var support_message := "This Computer gives %s [color=#d8a94b]%s[/color]." % [_fighter_name(target), card["name"]]
				await _animate_computer_card_play(card, target_button, support_message)
				if game_over or active_player != 1:
					return
				_play_support_card(1, index, target, false)
				_refresh_all()
				played = true
				break
			elif card["kind"] == "summon" and not trained_this_turn:
				var summon_message := "This Computer plays [color=#ffd166]Call in the Squad[/color]."
				await _animate_computer_card_play(card, opponent_fighters_box, summon_message)
				if game_over or active_player != 1:
					return
				_play_squad_card(1, index, false)
				_refresh_all()
				played = true
				break
			elif card["kind"] == "curse" and card["name"] == "Armageddon":
				if _ai_armageddon_score() <= 0.0:
					continue
				var armageddon_message := "This Computer unleashes [color=#a78bfa]Curse Armageddon[/color]."
				await _animate_computer_card_play(card, pit_panel, armageddon_message)
				if game_over or active_player != 1:
					return
				_play_armageddon(1, index, false)
				_refresh_all()
				played = true
				break
			elif card["kind"] == "curse":
				var target := _best_ai_generic_curse_target(card)
				if not target.is_empty():
					_refresh_all()
					await get_tree().process_frame
					var target_button: Control = fighter_button_nodes.get(int(target["id"]))
					var curse_message := "This Computer curses %s with [color=#8865a8]%s[/color]." % [_fighter_name(target), card["name"]]
					await _animate_computer_card_play(card, target_button, curse_message)
					if game_over or active_player != 1:
						return
					if not _play_curse_card(1, index, target, true, false):
						continue
					if card["name"] == "Deathmark":
						var destroyed_message := "[color=#c33b35]%s is destroyed.[/color]" % _fighter_name(target)
						await _animate_fighter_destruction(target, destroyed_message)
						if game_over or active_player != 1:
							return
						_remove_dead_fighters(false)
						_check_game_over()
					_refresh_all()
					played = true
					break
		if played:
			await get_tree().create_timer(0.5).timeout
		else:
			break


func _ai_play_heal() -> void:
	if game_over or active_player != 1:
		return
	for healer in fighters[1]:
		if healer.get("squad_role", "") != "ally_healer" or bool(healer.get("squad_heal_used", false)):
			continue
		var heal_target: Dictionary = {}
		for ally in fighters[1]:
			if ally != healer and int(ally["damage"]) > 0 and (heal_target.is_empty() or int(ally["damage"]) > int(heal_target["damage"])):
				heal_target = ally
		if not heal_target.is_empty():
			var squad_healed: int = mini(_fighter_attack(healer), int(heal_target["damage"]))
			heal_target["damage"] -= squad_healed
			healer["squad_heal_used"] = true
			var squad_heal_message := "Chaste Chase heals %s for [color=#4fd1a1]%d[/color]." % [_fighter_name(heal_target), squad_healed]
			_log_event(squad_heal_message, LOG_COMPUTER, false)
			_refresh_all()
			await _show_action_flash(squad_heal_message, 0.5)
			await get_tree().create_timer(0.5).timeout
			break
	for index in hands[1].size():
		var card: Dictionary = hands[1][index]
		if card["kind"] != "heal":
			continue
		var most_damaged: Dictionary = {}
		if _heal_card_can_target_fighter(card):
			for fighter in fighters[1]:
				if fighter["damage"] > 0 and (most_damaged.is_empty() or fighter["damage"] > most_damaged["damage"]):
					most_damaged = fighter
		if not most_damaged.is_empty():
			_refresh_all()
			await get_tree().process_frame
			var target_button: Control = fighter_button_nodes.get(int(most_damaged["id"]))
			var heal_message := "This Computer repairs [color=#58a66b]%d damage[/color] on %s." % [min(int(card["value"]), int(most_damaged["damage"])), _fighter_name(most_damaged)]
			await _animate_computer_card_play(card, target_button, heal_message)
			if game_over or active_player != 1:
				return
			_play_heal_on_fighter(1, index, most_damaged, false)
			_refresh_all()
			return
		var computer_max_health := _maximum_player_health(1)
		if _heal_card_can_target_player(card) and player_health[1] < computer_max_health:
			var life_message := "This Computer restores life."
			await _animate_computer_card_play(card, opponent_status_panel, life_message)
			if game_over or active_player != 1:
				return
			var effective_value := _consume_effective_card_value(1, card)
			var amount: int = min(effective_value, computer_max_health - player_health[1])
			life_message = "This Computer restores [color=#58a66b]%d life[/color]." % amount
			player_health[1] += amount
			_log_event(life_message, LOG_COMPUTER, false)
			hands[1].remove_at(index)
			_record_card_play(1, card, effective_value, {"player": 1, "healed": amount})
			_refresh_all()
			return


func _ai_fighter_value(fighter: Dictionary) -> float:
	if fighter.is_empty():
		return 0.0
	var value := float(_fighter_attack(fighter)) + float(_fighter_remaining(fighter)) * 0.8
	value += float(fighter.get("weapons", []).size() + fighter.get("shields", []).size()) * 1.5
	if bool(fighter.get("evasive", false)) or bool(fighter.get("zen", false)):
		value += 1.5
	if bool(fighter.get("berserker", false)) or bool(fighter.get("explosive", false)):
		value += 1.0
	return value


func _ai_damage_target_score(target: Dictionary, amount: int) -> float:
	if target.is_empty() or amount <= 0:
		return -1000.0
	var remaining := _fighter_remaining(target)
	var dealt := mini(amount, remaining)
	var score := float(dealt) * 1.5
	if dealt >= remaining:
		score += _ai_fighter_value(target) + 4.0
	return score


func _ai_weakest_expendable_ally() -> Dictionary:
	var weakest: Dictionary = {}
	for ally in fighters[1]:
		if _is_dead(ally):
			continue
		if weakest.is_empty() or _ai_fighter_value(ally) < _ai_fighter_value(weakest):
			weakest = ally
	return weakest


func _ai_best_target_for_faction_card(card: Dictionary) -> Dictionary:
	var mode := String(card.get("target", "none"))
	var effect := String(card.get("effect", ""))
	var candidates: Array = []
	if mode == "ally_fighter":
		candidates = fighters[1]
	elif mode in ["enemy_fighter", "any_fighter"]:
		# Faction cards with these modes are hostile/copy effects. Never feed them an ally.
		candidates = fighters[0]
	else:
		return {}
	var best: Dictionary = {}
	var best_score := -100000.0
	for candidate in candidates:
		if mode in ["enemy_fighter", "any_fighter"] and bool(candidate.get("evasive", false)):
			continue
		if effect == "damage_if_wounded" and int(candidate.get("damage", 0)) <= 0:
			continue
		var score := _ai_score_faction_card(card, candidate)
		if score > best_score:
			best_score = score
			best = candidate
	return best


func _ai_score_faction_card(card: Dictionary, target: Dictionary = {}) -> float:
	var effect := String(card.get("effect", ""))
	var value := int(card.get("value", 0)) + int(faction_round_flags[1].get("next_card_bonus", 0))
	var enemy_health := int(player_health[0])
	match effect:
		"summon_fighter", "summon_fighter_splash", "summon_fighter_lifesteal", "summon_and_prime_stat":
			return float(int(card.get("attack", value))) + float(int(card.get("defense", value))) * 0.7 + (1.5 if effect != "summon_fighter" else 0.0)
		"summon_copy_enemy_stat":
			if target.is_empty():
				return -1000.0
			return float(maxi(int(card.get("attack", value)), _fighter_attack(target))) + float(maxi(int(card.get("defense", value)), _fighter_max_defense(target))) * 0.7
		"damage_and_lifesteal", "damage_and_remove_weapon", "damage_and_chain":
			var damage_score := _ai_damage_target_score(target, value)
			if effect == "damage_and_lifesteal":
				damage_score += float(mini(value, maxi(0, _maximum_player_health(1) - int(player_health[1])))) * 0.7
			elif effect == "damage_and_remove_weapon" and not target.is_empty():
				damage_score += 2.0 if not target.get("weapons", []).is_empty() else 0.0
			elif effect == "damage_and_chain":
				damage_score += float(maxi(0, fighters[0].size() - 1))
			return damage_score
		"damage_if_wounded":
			return _ai_damage_target_score(target, value) if not target.is_empty() and int(target.get("damage", 0)) > 0 else -1000.0
		"heal", "heal_and_cleanse", "heal_with_chain_bonus":
			if String(card.get("target", "")) == "ally_player":
				var missing_player := maxi(0, _maximum_player_health(1) - int(player_health[1]))
				return float(mini(value, missing_player)) * 1.2 if missing_player > 0 else -4.0
			if target.is_empty() or int(target.get("damage", 0)) <= 0:
				return -4.0
			var effective_heal := mini(value, int(target["damage"]))
			return float(effective_heal) * 1.15 + (1.5 if effect == "heal_and_cleanse" and (bool(target.get("poison", false)) or bool(target.get("madness", false))) else 0.0)
		"heal_all_allied_fighters", "heal_all_allies_and_player":
			var total_heal := 0
			for ally in fighters[1]:
				total_heal += mini(value, int(ally.get("damage", 0)))
			if effect == "heal_all_allies_and_player":
				total_heal += mini(value, maxi(0, _maximum_player_health(1) - int(player_health[1])))
			return float(total_heal) * 1.1 if total_heal > 0 else -5.0
		"damage_all_fighters":
			var exchange := 0.0
			for enemy in fighters[0]:
				exchange += _ai_damage_target_score(enemy, value)
			for ally in fighters[1]:
				exchange -= _ai_damage_target_score(ally, value) * 1.15
			return exchange
		"sacrifice_for_player_damage":
			if target.is_empty():
				return -1000.0
			var player_damage_value := float(mini(value, enemy_health)) * 2.0
			if value >= enemy_health:
				player_damage_value += 100.0
			return player_damage_value - _ai_fighter_value(target) * 1.15
		"damage_players_and_draw":
			if value >= enemy_health and value < int(player_health[1]):
				return 100.0
			if value >= int(player_health[1]):
				return -1000.0
			return float(value) * 0.4 + 2.0
		"team_attack_per_enemy":
			return float(value * fighters[0].size() * fighters[1].size()) if not fighters[0].is_empty() and not fighters[1].is_empty() else -4.0
		"team_temporary_attack_and_draw":
			return float(value * fighters[1].size()) + 2.0 if not fighters[1].is_empty() else 1.0
		"enemy_area_damage_from_chain":
			var area := mini(4, maxi(1, faction_card_plays[1]))
			var area_score := 0.0
			for enemy in fighters[0]:
				area_score += _ai_damage_target_score(enemy, area)
			return area_score if not fighters[0].is_empty() else -4.0
		"fortify_most_damaged_ally":
			var wounded := _most_damaged_fighter(1)
			return float(mini(4, int(wounded.get("damage", 0)))) + float(value) * 0.35 if not wounded.is_empty() else -4.0
		"add_attack_and_self_damage":
			if target.is_empty() or _fighter_remaining(target) <= 1:
				return -1000.0
			return float(value) * 1.4 - 1.5
		"add_attack", "add_attack_bonus_if_shielded", "add_attack_and_pierce", "temporary_attack_with_recoil", "attack_and_temporary_evasive":
			return float(value) * 1.3 + (1.0 if effect == "add_attack_bonus_if_shielded" and not target.is_empty() and not target.get("shields", []).is_empty() else 0.0)
		"add_defense", "add_defense_and_evasive_once", "add_defense_with_break_heal", "add_defense_with_break_draw", "add_defense_counterattack_training":
			return float(value) * 0.9
		"add_attack_defense":
			return float(int(card.get("attack", value))) * 1.2 + float(int(card.get("defense", value))) * 0.8
		"add_to_lower_stat", "survive_combat_gain_attack", "adjacent_allies_defense_aura", "other_ally_trained_gain_defense", "attack_from_existing_damage", "survive_lethal_once", "prevent_next_damage":
			return 2.0 + float(value)
		"temporary_reduce_attack", "reduce_combat_damage_timed":
			return float(_fighter_attack(target)) * 0.5 if not target.is_empty() else -1000.0
		"discover_faction_card", "boost_next_cards", "boost_next_card", "reflect_next_player_damage":
			return 2.0 if hands[1].size() > 1 else -1.0
	return 1.0


func _ai_best_faction_play() -> Dictionary:
	var best: Dictionary = {}
	var best_score := 0.75 # A marginal card is worth holding for a better board.
	for index in hands[1].size():
		var card: Dictionary = hands[1][index]
		if not card.has("faction_id"):
			continue
		if String(card.get("kind", "")) == "training" and training_cards_played_this_turn[1] >= MAX_TRAINING_CARDS_PER_TURN:
			continue
		var mode := String(card.get("target", "none"))
		var target := _ai_best_target_for_faction_card(card)
		if mode in ["ally_fighter", "enemy_fighter", "any_fighter"] and target.is_empty():
			continue
		if String(card.get("effect", "")) == "sacrifice_for_player_damage":
			target = _ai_weakest_expendable_ally()
			if target.is_empty():
				continue
		var score := _ai_score_faction_card(card, target)
		if score > best_score:
			best_score = score
			best = {"index": index, "target": target, "score": score}
	return best


func _ai_armageddon_score() -> float:
	var enemy_value := 0.0
	var ally_value := 0.0
	for enemy in fighters[0]:
		enemy_value += _ai_fighter_value(enemy)
	for ally in fighters[1]:
		ally_value += _ai_fighter_value(ally)
	if enemy_value <= 0.0:
		return -1000.0
	return enemy_value - ally_value * 1.2 - 2.0


func _ai_best_ai_generic_curse_score(card: Dictionary, target: Dictionary) -> float:
	match String(card.get("name", "")):
		"Deathmark":
			return _ai_fighter_value(target) + 5.0
		"Poison":
			return float(_fighter_remaining(target)) * 0.35 + 2.0 - float(_status_stacks(target, "poison"))
		"Madness":
			return float(_fighter_attack(target)) * 0.35 + 2.0 - float(_status_stacks(target, "madness"))
	return _ai_fighter_value(target)


func _best_ai_generic_curse_target(card: Dictionary) -> Dictionary:
	var best: Dictionary = {}
	var best_score := 0.5
	for enemy in fighters[0]:
		if bool(enemy.get("evasive", false)):
			continue
		var score := _ai_best_ai_generic_curse_score(card, enemy)
		if score > best_score:
			best_score = score
			best = enemy
	return best


func _best_ai_fighter() -> Dictionary:
	var best: Dictionary = {}
	for fighter in fighters[1]:
		if best.is_empty() or _fighter_attack(fighter) + _fighter_max_defense(fighter) > _fighter_attack(best) + _fighter_max_defense(best):
			best = fighter
	return best


func _best_curse_target() -> Dictionary:
	var best: Dictionary = {}
	for fighter in fighters[0]:
		if fighter["evasive"]:
			continue
		if best.is_empty() or _fighter_attack(fighter) + _fighter_max_defense(fighter) > _fighter_attack(best) + _fighter_max_defense(best):
			best = fighter
	return best


func _refresh_all() -> void:
	if not is_instance_valid(hand_box):
		return
	opponent_health_label.text = "%d HP" % player_health[1]
	opponent_health_label.add_theme_color_override("font_color", RED if player_health[1] > 15 else Color("#ff6b5f"))
	if is_instance_valid(opponent_health_bar):
		opponent_health_bar.set_health(player_health[1], _maximum_player_health(1))
	opponent_hand_label.text = "HAND %d" % hands[1].size()
	opponent_deck_label.text = "DECK %d" % decks[1].size()
	player_health_label.text = "%d HP" % player_health[0]
	player_health_label.add_theme_color_override("font_color", GREEN if player_health[0] > 15 else Color("#ff6b5f"))
	if is_instance_valid(player_health_bar):
		player_health_bar.set_health(player_health[0], _maximum_player_health(0))
	player_hand_label.text = "HAND %d" % hands[0].size()
	player_deck_label.text = "DECK %d" % decks[0].size()
	encounter_number_label.text = "%02d" % encounter_number
	round_number_label.text = "%02d" % round_number
	turn_label.text = "YOUR TURN" if active_player == 0 else "THIS COMPUTER"
	phase_label.text = phase
	_refresh_turn_display()
	_refresh_hand()
	fighter_button_nodes.clear()
	pit_health_bar_nodes.clear()
	_refresh_fighter_lane(0, player_fighters_box)
	_refresh_fighter_lane(1, opponent_fighters_box)
	_refresh_pit_fighters()
	_refresh_prompt()
	_refresh_commands()
	_render_fight_log()
	await get_tree().process_frame
	if is_instance_valid(log_label):
		log_label.scroll_to_line(max(0, log_label.get_line_count() - 1))
	if is_instance_valid(block_overlay):
		block_overlay.queue_redraw()


func _refresh_turn_display() -> void:
	if is_instance_valid(turn_order_title_label):
		turn_order_title_label.text = "HUMAN'S TURN:" if active_player == 0 else "COMPUTER'S TURN:"
	var highlighted_phase := phase
	if phase == PHASE_DEFEND or phase == PHASE_COMBAT:
		highlighted_phase = PHASE_ATTACK
	for phase_key in turn_order_labels:
		var item: Label = turn_order_labels[phase_key]
		var base_text: String = {
			PHASE_DRAW: "DRAW",
			PHASE_TRAIN: "TRAIN",
			PHASE_ATTACK: "PIT",
			PHASE_HEAL: "HEAL/END",
		}.get(phase_key, String(phase_key))
		var current: bool = phase_key == highlighted_phase
		item.text = ("▶  " if current else "    ") + base_text
		item.add_theme_color_override("font_color", INK if current else MUTED)
		item.add_theme_stylebox_override("normal", _style(PURPLE.darkened(0.45) if current else Color(0, 0, 0, 0), BLUE if current else Color(0, 0, 0, 0), 1 if current else 0, 6))
	var human_active := active_player == 0 and not game_over
	if is_instance_valid(player_health_bar):
		player_health_bar.set_turn_active(human_active)
	if is_instance_valid(opponent_health_bar):
		opponent_health_bar.set_turn_active(not human_active and not game_over)
	if is_instance_valid(player_status_panel):
		player_status_panel.add_theme_stylebox_override("panel", _style(Color(0.02, 0.08, 0.10, 0.04), Color.TRANSPARENT, 0, 7))
	if is_instance_valid(opponent_status_panel):
		opponent_status_panel.add_theme_stylebox_override("panel", _style(Color(0.10, 0.02, 0.06, 0.04), Color.TRANSPARENT, 0, 7))


func _refresh_hand() -> void:
	_sort_hand_by_type_and_value(0)
	_clear_container(hand_box)
	hand_card_nodes.clear()
	var hand_count := maxi(1, hands[0].size())
	var available_width := maxf(1080.0, hand_panel.size.x - 24.0)
	var card_width := clampf(floorf((available_width - float(hand_count - 1) * 8.0) / float(hand_count)), 92.0, 132.0)
	if hands[0].is_empty():
		var empty := Label.new()
		empty.text = "NO CARDS IN HAND"
		empty.custom_minimum_size = Vector2(220, 120)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty.add_theme_color_override("font_color", MUTED)
		hand_box.add_child(empty)
	for index in hands[0].size():
		var card: Dictionary = hands[0][index]
		var unavailable_reason := _card_unavailable_reason(card)
		var phase_playable := unavailable_reason.is_empty()
		var button := Button.new()
		button.custom_minimum_size = Vector2(card_width, 194)
		button.text = ""
		button.tooltip_text = "%s\n%s" % [card["name"], card["description"]]
		if not phase_playable:
			button.tooltip_text += "\n\nUNAVAILABLE: %s" % unavailable_reason
			button.set_meta("unavailable_reason", unavailable_reason)
		button.clip_contents = true
		button.add_theme_color_override("font_color", INK)
		var color := Color(String(FactionData.faction_by_id(String(card["faction_id"])).get("color", "#9ec3d6"))) if card.has("faction_id") else _card_color(card["kind"])
		var selected: bool = index in selected_hand_indices
		button.add_theme_stylebox_override("normal", _style(color.darkened(0.58), GOLD if selected else color, 3 if selected else 1, 18))
		button.add_theme_stylebox_override("hover", _style(color.darkened(0.45), GOLD, 2, 18))
		button.add_theme_stylebox_override("pressed", _style(color.darkened(0.68), INK, 2, 18))
		button.add_theme_stylebox_override("disabled", _style(color.darkened(0.68), color.darkened(0.25), 1, 18))
		button.disabled = input_locked or game_over
		button.pressed.connect(_on_hand_card_pressed.bind(index))
		hand_box.add_child(button)
		hand_card_nodes[index] = button
		_add_card_art_layout(button, card)
		_add_card_hover_outline(button, selected)
		if not phase_playable:
			button.modulate = Color(0.75, 0.75, 0.75, 1.0)
			button.set_meta("phase_unplayable", true)
			_add_unplayable_card_fade(button)
			_lower_unplayable_card(button)
		if selected and phase_playable and phase == PHASE_TRAIN and _is_stat_upgrade_card(card):
			button.pivot_offset = Vector2(card_width * 0.5, 97.0)
			button.z_index = 30
			button.set_meta("stat_selection_pulse", true)
			_start_selected_stat_card_pulse(button)
	if phase == PHASE_TRAIN and selected_hand_indices.size() == 1 and _selected_cards_are_stats():
		if selected_hand_indices.size() == 1:
			var card: Dictionary = hands[0][selected_hand_indices[0]]
			selection_label.text = "STAT %d  //  CHOOSE ATK OR DEF  //  TRAINING %d OF 1" % [card["value"], stat_cards_played_this_turn]
	elif selected_hand_indices.size() == 1:
		selection_label.text = "SELECTED: %s" % hands[0][selected_hand_indices[0]]["name"]
	else:
		selection_label.text = ""


func _add_card_hover_outline(button: Button, selected: bool) -> void:
	var outline := Panel.new()
	outline.name = "CardHoverOutline"
	outline.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outline.z_index = 100
	var outline_style := _style(Color.TRANSPARENT, GOLD, 3, 18)
	outline_style.shadow_size = 0
	outline_style.shadow_color = Color.TRANSPARENT
	outline.add_theme_stylebox_override("panel", outline_style)
	outline.visible = selected
	button.add_child(outline)
	button.mouse_entered.connect(_refresh_card_hover_outline.bind(button, outline, selected, true))
	button.mouse_exited.connect(_refresh_card_hover_outline.bind(button, outline, selected, false))
	button.focus_entered.connect(_refresh_card_hover_outline.bind(button, outline, selected, true))
	button.focus_exited.connect(_refresh_card_hover_outline.bind(button, outline, selected, false))


func _refresh_card_hover_outline(button: Button, outline: Panel, selected: bool, highlighted: bool) -> void:
	if is_instance_valid(button) and is_instance_valid(outline):
		outline.visible = selected or highlighted or button.is_hovered() or button.has_focus()


func _card_can_be_played_in_current_phase(card: Dictionary) -> bool:
	return _card_unavailable_reason(card).is_empty()


func _card_unavailable_reason(card: Dictionary) -> String:
	if game_over or active_player != 0:
		return "The match is over" if game_over else "It is not your turn"
	var kind := String(card.get("kind", ""))
	if phase == PHASE_HEAL:
		if kind != "heal":
			return "This card cannot be played during the heal phase"
		return "" if _heal_card_has_valid_target(0, card) else "This heal has no valid target"
	if phase != PHASE_TRAIN:
		return "Cards cannot be played during the %s phase" % phase.to_lower()
	if card.has("faction_id"):
		if kind == "training" and training_cards_played_this_turn[0] >= MAX_TRAINING_CARDS_PER_TURN:
			return "All training cards have been played this turn"
		if kind == "summon" and (trained_this_turn or new_fighter_attack > 0 or new_fighter_defense > 0):
			return "A fighter has already been created or staged this turn"
		var target_mode := String(card.get("target", "none"))
		if target_mode == "ally_fighter":
			return "" if not fighters[0].is_empty() else "There are no allied fighters to target"
		if target_mode == "enemy_fighter":
			if String(card.get("effect", "")) == "summon_copy_enemy_stat":
				return "" if fighters[1].any(func(fighter: Dictionary) -> bool: return not _is_dead(fighter)) else "There are no enemy fighters whose stats can be copied"
			return "" if fighters[1].any(func(fighter: Dictionary) -> bool: return not bool(fighter.get("evasive", false)) or bool(fighter.get("evasive_once", false))) else "There are no eligible enemy fighters to target"
		if target_mode == "any_fighter":
			return "" if not fighters[0].is_empty() or not fighters[1].is_empty() else "There are no fighters to target"
		return ""
	match kind:
		"heal":
			return "Heal cards can only be played during the heal phase"
		"stat":
			var can_train_existing: bool = stat_cards_played_this_turn < MAX_STAT_TRAINING_PER_TURN and not fighters[0].is_empty()
			if can_train_existing or _can_use_stat_for_new_fighter(0):
				return ""
			if stat_cards_played_this_turn >= MAX_STAT_TRAINING_PER_TURN:
				return "All stat cards played this turn"
			return "A fighter has already been created this turn"
		"weapon", "shield", "blessing":
			return "" if not fighters[0].is_empty() else "There are no allied fighters to receive this card"
		"training":
			if fighters[0].is_empty():
				return "There are no allied fighters to train"
			return "" if training_cards_played_this_turn[0] < MAX_TRAINING_CARDS_PER_TURN else "All training cards have been played this turn"
		"curse":
			if String(card.get("name", "")) == "Armageddon":
				return ""
			return "" if fighters[1].any(func(fighter: Dictionary) -> bool: return not bool(fighter.get("evasive", false))) else "There are no eligible enemy fighters to curse"
		"summon":
			return "" if not trained_this_turn and new_fighter_attack == 0 and new_fighter_defense == 0 else "A fighter has already been created or staged this turn"
	return "This card has no valid play during the current phase"


func _lower_unplayable_card(button: Button) -> void:
	await get_tree().process_frame
	if not is_instance_valid(button) or not bool(button.get_meta("phase_unplayable", false)):
		return
	button.position.y += 25.0


func _add_unplayable_card_fade(button: Button) -> void:
	# Lowered cards extend 25px past the hand viewport. Fade the final visible
	# 30px into the hand's dark surface so the clipping edge is gradual.
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 1.0])
	gradient.colors = PackedColorArray([
		Color(0.025, 0.045, 0.055, 0.0),
		Color(0.025, 0.045, 0.055, 1.0),
	])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = maxi(1, roundi(button.custom_minimum_size.x))
	texture.height = 30
	texture.fill_from = Vector2(0.5, 0.0)
	texture.fill_to = Vector2(0.5, 1.0)
	var fade := TextureRect.new()
	fade.name = "UnavailableBottomFade"
	fade.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	fade.offset_top = -55.0
	fade.offset_bottom = -25.0
	fade.texture = texture
	fade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fade.stretch_mode = TextureRect.STRETCH_SCALE
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.z_index = 90
	fade.set_meta("fade_height", 30.0)
	button.add_child(fade)


func _start_selected_stat_card_pulse(button: Button) -> void:
	await get_tree().process_frame
	if not is_instance_valid(button) or not bool(button.get_meta("stat_selection_pulse", false)):
		return
	# Containers finish laying out children at the end of the frame, so apply the
	# visual transform afterward to keep the initial ten-percent enlargement.
	button.scale = Vector2.ONE * 1.10
	var pulse := button.create_tween().set_loops()
	pulse.tween_property(button, "scale", Vector2.ONE * 1.13, 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse.parallel().tween_property(button, "rotation", 0.012, 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse.tween_property(button, "scale", Vector2.ONE * 1.10, 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse.parallel().tween_property(button, "rotation", -0.012, 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _add_stat_card_layout(button: Button, card: Dictionary) -> void:
	var face := VBoxContainer.new()
	face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	face.offset_left = 6
	face.offset_top = 5
	face.offset_right = -6
	face.offset_bottom = -6
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face.add_theme_constant_override("separation", 0)
	button.add_child(face)

	var heading := _add_type_badge(face, "STAT", GOLD)
	heading.add_theme_font_size_override("font_size", 14)

	var number := Label.new()
	number.text = str(card["value"])
	number.size_flags_vertical = Control.SIZE_EXPAND_FILL
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	number.add_theme_font_size_override("font_size", 82 if int(card["value"]) < 10 else 70)
	number.add_theme_color_override("font_color", INK)
	number.add_theme_color_override("font_shadow_color", Color(0.02, 0.02, 0.03, 0.95))
	number.add_theme_constant_override("shadow_offset_x", 3)
	number.add_theme_constant_override("shadow_offset_y", 3)
	face.add_child(number)

	var footer := Label.new()
	footer.text = "TRAIN: ATTACK OR DEFENSE"
	footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 9)
	footer.add_theme_color_override("font_color", INK)
	face.add_child(footer)


func _add_faction_bitmap(parent: Control, faction_id: String, opacity := 0.42) -> void:
	var path := "res://assets/factions/%s.png" % faction_id
	if not ResourceLoader.exists(path):
		return
	var art := TextureRect.new()
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.texture = load(path)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	art.modulate = Color(1, 1, 1, opacity)
	art.material = _rounded_texture_material(6.0)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(art)


func _add_faction_card_layout(button: Button, card: Dictionary) -> void:
	_add_card_art_layout(button, card)


func _card_art_path(card: Dictionary) -> String:
	return "res://assets/cards/%s.png" % String(card.get("definition_id", "%s_%s" % [card.get("kind", "card"), String(card.get("name", "card")).to_snake_case()]))


func _add_card_art_layout(button: Button, card: Dictionary) -> void:
	var art_path := _card_art_path(card)
	if ResourceLoader.exists(art_path):
		var art := TextureRect.new()
		art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		art.offset_bottom = 0 if String(card.get("kind", "")) == "stat" else -78
		art.texture = load(art_path)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		var is_stat := String(card.get("kind", "")) == "stat"
		var face_width := maxf(button.custom_minimum_size.x, 92.0)
		var face_height := maxf(button.custom_minimum_size.y - (0.0 if is_stat else 78.0), 92.0)
		art.material = _rounded_texture_material(18.0, is_stat, Vector2(face_width, face_height))
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(art)
	elif card.has("faction_id"):
		_add_faction_bitmap(button, String(card["faction_id"]), 0.56)
	var shade := PanelContainer.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.add_theme_stylebox_override("panel", _style(Color(0.015, 0.02, 0.04, 0.26), Color.TRANSPARENT, 0, 18))
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(shade)
	if String(card.get("kind", "")) == "stat":
		shade.add_theme_stylebox_override("panel", _style(Color(0.015, 0.02, 0.04, 0.38), Color.TRANSPARENT, 0, 18))
		_add_stat_card_layout(button, card)
		return
	var face := VBoxContainer.new()
	face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	face.offset_left = 8
	face.offset_right = -8
	face.offset_top = 5
	face.offset_bottom = -7
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face.add_theme_constant_override("separation", 1)
	button.add_child(face)
	var faction := FactionData.faction_by_id(String(card.get("faction_id", "")))
	_add_type_badge(face, String(faction.get("lean", card.get("kind", "card"))).to_upper(), Color(String(faction.get("color", "#ffffff"))))
	var art_space := Control.new()
	art_space.custom_minimum_size.y = 28
	art_space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face.add_child(art_space)
	var name_label := Label.new()
	var name_text := String(card["name"]).to_upper()
	name_label.text = name_text
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if " " in name_text else TextServer.AUTOWRAP_OFF
	name_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.custom_minimum_size.y = 42
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var card_width := button.custom_minimum_size.x
	var name_length := String(card["name"]).length()
	var name_size := 30
	if card_width < 112.0:
		name_size = 18 if name_length <= 10 else 13
	elif name_length > 19:
		name_size = 15
	elif name_length > 13:
		name_size = 18
	elif name_length > 8:
		name_size = 24
	name_size = _fit_card_name_font(name_text, name_size, card_width - 16.0)
	name_label.add_theme_font_size_override("font_size", name_size)
	name_label.add_theme_color_override("font_color", INK)
	face.add_child(name_label)
	var description := Label.new()
	description.text = String(card.get("description", ""))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	description.custom_minimum_size.y = 62
	description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	description.add_theme_font_size_override("font_size", 7 if card_width < 112.0 else 9)
	description.add_theme_color_override("font_color", Color("#f5f0df"))
	face.add_child(description)
	var footer := Label.new()
	footer.text = "%s  //  %d" % [String(card["kind"]).to_upper(), int(card["value"])]
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 9)
	footer.add_theme_color_override("font_color", GOLD)
	face.add_child(footer)


func _refresh_fighter_lane(owner: int, box: HBoxContainer) -> void:
	_clear_container(box)
	var stable_fighters: Array[Dictionary] = []
	for fighter in fighters[owner]:
		if not _fighter_in_pit(owner, fighter["id"]):
			stable_fighters.append(fighter)
	if fighter_lane_panels.has(owner):
		fighter_lane_panels[owner].custom_minimum_size.y = 86 if stable_fighters.is_empty() and not fighters[owner].is_empty() else 170
	var selected_stat_for_creation := false
	if owner == 0 and selected_hand_indices.size() == 1:
		var selected_index := selected_hand_indices[0]
		selected_stat_for_creation = selected_index >= 0 and selected_index < hands[0].size() and _is_stat_upgrade_card(hands[0][selected_index]) and _can_use_stat_for_new_fighter(0)
	var show_new_fighter_choice := owner == 0 and active_player == 0 and phase == PHASE_TRAIN and (selected_stat_for_creation or new_fighter_attack > 0 or new_fighter_defense > 0)
	if stable_fighters.is_empty() and not show_new_fighter_choice:
		var empty := Label.new()
		empty.text = "FIGHTERS COMMITTED TO THE PIT" if not fighters[owner].is_empty() else "NO FIGHTERS TRAINED"
		empty.custom_minimum_size = Vector2(260, 105)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty.add_theme_color_override("font_color", Color(0.50, 0.72, 0.82, 0.72))
		box.add_child(empty)
		return
	if show_new_fighter_choice:
		box.add_child(_create_new_fighter_choice_card())
	for fighter in stable_fighters:
		var fighter_button := _create_fighter_button(fighter, owner)
		box.add_child(_stable_fighter_slot(fighter_button))
		if pending_fighter_entrance_ids.has(int(fighter["id"])):
			call_deferred("_animate_new_fighter_drop", int(fighter["id"]), fighter_button)


func _stable_fighter_slot(fighter_button: Button) -> VBoxContainer:
	var slot := VBoxContainer.new()
	slot.name = "StableFighterSlot"
	slot.custom_minimum_size = Vector2(fighter_button.custom_minimum_size.x, fighter_button.custom_minimum_size.y + 20.0)
	slot.clip_contents = false
	slot.add_theme_constant_override("separation", 2)
	var headroom := Control.new()
	headroom.name = "HealthBarHeadroom"
	headroom.custom_minimum_size.y = 18.0
	headroom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(headroom)
	fighter_button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	slot.add_child(fighter_button)
	return slot


func _create_new_fighter_choice_card() -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(204, 112)
	card.add_theme_stylebox_override("panel", _style(Color(0.10, 0.13, 0.30, 0.98), GOLD, 3, 9))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	card.add_child(column)
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 3)
	column.add_child(title_row)
	var title_spacer := Control.new()
	title_spacer.custom_minimum_size.x = 25
	title_row.add_child(title_spacer)
	var heading := Label.new()
	heading.text = "NEW FIGHTER"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_theme_font_size_override("font_size", 15)
	heading.add_theme_color_override("font_color", GOLD)
	title_row.add_child(heading)
	var cancel_button := _command_button("×", RED.darkened(0.25))
	cancel_button.custom_minimum_size = Vector2(25, 23)
	cancel_button.add_theme_font_size_override("font_size", 16)
	cancel_button.tooltip_text = "Cancel this unfinished fighter and return its staged stat card to your hand."
	cancel_button.disabled = pending_new_fighter_cards.is_empty()
	cancel_button.pressed.connect(_cancel_pending_new_fighter)
	title_row.add_child(cancel_button)
	var hint := Label.new()
	if squad_summoned_this_turn:
		hint.text = "LOCKED AFTER SQUAD"
	elif fighters_trained_this_turn[0] >= MAX_FIGHTERS_TRAINED_PER_TURN:
		hint.text = "FIGHTER LIMIT  //  1 OF 1"
	else:
		hint.text = "FILL BOTH SLOTS"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 9)
	hint.add_theme_color_override("font_color", MUTED)
	column.add_child(hint)
	var slots := HBoxContainer.new()
	slots.add_theme_constant_override("separation", 7)
	column.add_child(slots)
	var stat_selected: bool = selected_hand_indices.size() == 1 and selected_hand_indices[0] >= 0 and selected_hand_indices[0] < hands[0].size() and hands[0][selected_hand_indices[0]]["kind"] == "stat"
	var attack_slot := _command_button(str(new_fighter_attack) if new_fighter_attack > 0 else "+ ATTACK", RED.darkened(0.35))
	attack_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	attack_slot.disabled = fighters_trained_this_turn[0] >= MAX_FIGHTERS_TRAINED_PER_TURN or squad_summoned_this_turn or new_fighter_attack > 0 or not stat_selected
	attack_slot.tooltip_text = "Use the selected stat as the new fighter's attack."
	attack_slot.pressed.connect(_on_new_fighter_slot_pressed.bind("attack"))
	slots.add_child(attack_slot)
	var defense_slot := _command_button(str(new_fighter_defense) if new_fighter_defense > 0 else "+ DEFENSE", BLUE.darkened(0.40))
	defense_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	defense_slot.disabled = fighters_trained_this_turn[0] >= MAX_FIGHTERS_TRAINED_PER_TURN or squad_summoned_this_turn or new_fighter_defense > 0 or not stat_selected
	defense_slot.tooltip_text = "Use the selected stat as the new fighter's defense."
	defense_slot.pressed.connect(_on_new_fighter_slot_pressed.bind("defense"))
	slots.add_child(defense_slot)
	return card


func _create_fighter_button(fighter: Dictionary, owner: int, pit_role: String = "") -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(230, 170) if not pit_role.is_empty() else Vector2(204, 112)
	button.text = ""
	# Pit lanes provide surrounding vertical space; stable lanes wrap this card
	# in a dedicated headroom slot. In both cases the bar may render above it.
	button.clip_contents = false
	button.tooltip_text = _fighter_tooltip(fighter)
	var selected: bool = _is_fighter_selected(owner, fighter["id"])
	var healer_target: bool = phase == PHASE_HEAL and owner == 0 and selected_healer_id != -1 and int(fighter["id"]) != selected_healer_id and int(fighter["damage"]) > 0
	var card_target: bool = _is_valid_selected_card_target(owner, fighter) or healer_target
	var base_color := Color("#412552") if owner == 1 else Color("#104452")
	var edge := RED if owner == 1 else GREEN
	var border_width := 1
	var pit_combat := phase == PHASE_COMBAT and not pit_role.is_empty()
	if pit_combat:
		edge = GREEN if owner == 0 else RED
		border_width = 2
	elif selected or card_target or not pit_role.is_empty():
		edge = GOLD
		border_width = 3
	if card_target:
		base_color = base_color.lightened(0.10)
	if phase == PHASE_ATTACK and owner == 0:
		if selected:
			base_color = Color("#51346e")
		else:
			button.modulate = Color(0.56, 0.56, 0.56, 0.72)
	var normal_style := _style(base_color, edge, border_width, 10)
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("disabled", normal_style)
	button.add_theme_stylebox_override("hover", _style(base_color.lightened(0.07), edge if pit_combat else GOLD, 2, 10))
	button.add_theme_stylebox_override("pressed", _style(base_color.darkened(0.10), edge if pit_combat else INK, 2, 10))
	button.disabled = input_locked or game_over
	button.pressed.connect(_on_fighter_pressed.bind(owner, fighter["id"]))
	_add_fighter_card_layout(button, fighter, owner, pit_role)
	fighter_button_nodes[fighter["id"]] = button
	return button


func _fighter_in_pit(owner: int, fighter_id: int) -> bool:
	if phase not in [PHASE_ATTACK, PHASE_COMBAT]:
		return false
	var attacking_ids: Array[int] = selected_attacker_ids if phase == PHASE_ATTACK else pending_attack_ids
	if owner == active_player and fighter_id in attacking_ids:
		return true
	if phase == PHASE_COMBAT and owner == 1 - active_player:
		var defender := _get_fighter(owner, fighter_id)
		return not defender.is_empty() and not _is_dead(defender)
	return false


func _refresh_pit_fighters() -> void:
	_clear_container(pit_fighters_box)
	var pit_phase := phase in [PHASE_ATTACK, PHASE_COMBAT]
	var attacking_ids: Array[int] = selected_attacker_ids if phase == PHASE_ATTACK else pending_attack_ids
	pit_panel.custom_minimum_size.y = 354 if pit_phase else 96
	hand_panel.custom_minimum_size.y = 230
	_set_pit_focus(pit_phase)
	pit_fighters_box.get_parent().visible = pit_phase
	if not pit_phase:
		return
	if attacking_ids.is_empty():
		var invitation := Label.new()
		invitation.text = "CHOOSE YOUR GLADIATORS  •  THE CROWD DEMANDS A FIGHT"
		invitation.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		invitation.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		invitation.custom_minimum_size = Vector2(680, 150)
		invitation.add_theme_font_size_override("font_size", 18)
		invitation.add_theme_color_override("font_color", GOLD)
		pit_fighters_box.add_child(invitation)
		return
	var entries_by_owner: Dictionary = {0: [], 1: []}
	for attacker_id in attacking_ids:
		var attacker := _get_fighter(active_player, attacker_id)
		if not attacker.is_empty():
			entries_by_owner[active_player].append({"fighter": attacker, "role": "CHOSEN FOR THE PIT" if phase == PHASE_ATTACK else "ATTACKING"})
	var defender_owner := 1 - active_player
	if phase == PHASE_COMBAT:
		for defender in fighters[defender_owner]:
			if not _is_dead(defender):
				entries_by_owner[defender_owner].append({"fighter": defender, "role": "DEFENDING"})
	if phase == PHASE_ATTACK:
		var defenders_available: bool = fighters[1 - active_player].any(func(fighter: Dictionary) -> bool: return not _is_dead(fighter))
		var staging_alignment := (BoxContainer.ALIGNMENT_BEGIN if active_player == 0 else BoxContainer.ALIGNMENT_END) if defenders_available else BoxContainer.ALIGNMENT_CENTER
		pit_fighters_box.add_child(_create_pit_team_group(entries_by_owner[active_player], staging_alignment))
		return
	if entries_by_owner[0].is_empty() or entries_by_owner[1].is_empty():
		var lone_side := 1 if entries_by_owner[0].is_empty() else 0
		pit_fighters_box.add_child(_create_pit_team_group(entries_by_owner[lone_side], BoxContainer.ALIGNMENT_CENTER))
		return
	# Humans stage at the left rail and opponents at the right rail. The charge
	# animation pulls both groups into the center once combat is locked.
	pit_fighters_box.add_child(_create_pit_team_group(entries_by_owner[0], BoxContainer.ALIGNMENT_BEGIN))
	pit_fighters_box.add_child(_create_pit_team_group(entries_by_owner[1], BoxContainer.ALIGNMENT_END))


func _create_pit_team_group(entries: Array, alignment: int) -> HBoxContainer:
	var group := HBoxContainer.new()
	var owner := int(entries[0]["fighter"]["owner"]) if not entries.is_empty() else -1
	group.name = "HumanPitTeam" if owner == 0 else "ComputerPitTeam" if owner == 1 else "EmptyPitTeam"
	group.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	group.size_flags_vertical = Control.SIZE_EXPAND_FILL
	group.alignment = alignment
	group.add_theme_constant_override("separation", 12)
	for entry in entries:
		var fighter: Dictionary = entry["fighter"]
		var card := _create_fighter_button(fighter, int(fighter["owner"]), String(entry["role"]))
		# The pit lane is taller than the card so its persistent health bar has room
		# above it. Center the card vertically instead of letting HBox top-align it.
		card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		group.add_child(card)
	return group


func _set_pit_focus(active: bool) -> void:
	if pit_focus_active == active or not is_instance_valid(hand_panel):
		return
	pit_focus_active = active
	if pit_focus_tween and pit_focus_tween.is_valid():
		pit_focus_tween.kill()
	pit_focus_tween = create_tween().set_parallel(true)
	if active:
		hand_panel.visible = true
		pit_focus_tween.tween_property(hand_panel, "position:x", -maxf(900.0, hand_panel.size.x + 40.0), 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		pit_focus_tween.tween_property(hand_panel, "modulate:a", 0.0, 0.20)
		pit_focus_tween.chain().tween_callback(func() -> void:
			if pit_focus_active:
				hand_panel.visible = false
		)
	else:
		hand_panel.visible = true
		hand_panel.position.x = -maxf(900.0, hand_panel.size.x + 40.0)
		hand_panel.modulate.a = 0.0
		pit_focus_tween.tween_property(hand_panel, "position:x", 0.0, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pit_focus_tween.tween_property(hand_panel, "modulate:a", 1.0, 0.18)


func _add_pit_fighter_health_bar(button: Button, fighter: Dictionary) -> void:
	var bar := ProgressBar.new()
	bar.name = "PitHealthBar"
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_left = 9.0
	bar.offset_top = -20.0
	bar.offset_right = -9.0
	bar.offset_bottom = -2.0
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Keep the bar in the card's own canvas order. A positive independent z-index
	# allowed it to draw through settings and other modal overlays.
	bar.z_as_relative = true
	bar.z_index = 0
	var background_style := _style(Color(0.025, 0.035, 0.04, 0.94), Color(0.88, 0.94, 0.98, 0.72), 1, 5)
	background_style.shadow_size = 0
	bar.add_theme_stylebox_override("background", background_style)
	var text := Label.new()
	text.name = "PitHealthText"
	text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.add_theme_font_size_override("font_size", 11)
	text.add_theme_color_override("font_color", Color.WHITE)
	text.add_theme_color_override("font_shadow_color", Color(0.02, 0.02, 0.02, 0.95))
	text.add_theme_constant_override("shadow_offset_x", 1)
	text.add_theme_constant_override("shadow_offset_y", 1)
	bar.add_child(text)
	button.add_child(bar)
	pit_health_bar_nodes[int(fighter["id"])] = bar
	_update_pit_fighter_health_bar(fighter)


func _update_pit_fighter_health_bar(fighter: Dictionary) -> void:
	var bar: ProgressBar = pit_health_bar_nodes.get(int(fighter.get("id", -1)))
	if not is_instance_valid(bar):
		return
	var maximum := maxi(1, _fighter_max_defense(fighter))
	var current := clampi(_fighter_remaining(fighter), 0, maximum)
	var ratio := float(current) / float(maximum)
	bar.max_value = maximum
	bar.value = current
	var fill_color := RED.lerp(GREEN, ratio)
	var fill_style := _style(Color(fill_color, 0.96), fill_color.lightened(0.18), 1, 5)
	fill_style.shadow_size = 0
	bar.add_theme_stylebox_override("fill", fill_style)
	var text := bar.get_node_or_null("PitHealthText") as Label
	if is_instance_valid(text):
		text.text = "%d / %d" % [current, maximum]
	bar.set_meta("health_ratio", ratio)
	bar.set_meta("health_color", fill_color)


func _refresh_pit_health_bars() -> void:
	for owner in 2:
		for fighter in fighters[owner]:
			_update_pit_fighter_health_bar(fighter)


func _add_fighter_card_layout(button: Button, fighter: Dictionary, owner: int, pit_role: String = "") -> void:
	if fighter_atlas:
		var portrait_texture := AtlasTexture.new()
		portrait_texture.atlas = fighter_atlas
		var portrait_index := int(fighter.get("portrait_index", int(fighter["id"]) % 25))
		var cell_size := Vector2(fighter_atlas.get_width() / 5.0, fighter_atlas.get_height() / 5.0)
		portrait_texture.region = Rect2(Vector2(portrait_index % 5, portrait_index / 5) * cell_size, cell_size)
		portrait_texture.filter_clip = true
		var portrait := TextureRect.new()
		portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		portrait.texture = portrait_texture
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		portrait.modulate = Color(1.0, 1.0, 1.0, 0.52)
		portrait.material = _rounded_texture_material(10.0, true, button.custom_minimum_size)
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(portrait)
		var shade := ColorRect.new()
		shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		shade.color = Color(0.015, 0.07, 0.11, 0.10)
		shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(shade)
	_add_pit_fighter_health_bar(button, fighter)
	var content := VBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 10
	content.offset_top = 27
	content.offset_right = -10
	content.offset_bottom = -7
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 2)
	button.add_child(content)

	var name_label := Label.new()
	name_label.text = _fighter_name(fighter).to_upper()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.custom_minimum_size.y = 34
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", GOLD if owner == 0 else Color("#ff9daf"))
	content.add_child(name_label)

	var effects := Label.new()
	var tags := _fighter_tags(fighter)
	var trait_text := "BARE-KNUCKLE" if tags.is_empty() else "  /  ".join(tags)
	if not pit_role.is_empty():
		effects.text = "%s  //  %s" % [pit_role, trait_text]
	elif _is_valid_selected_card_target(owner, fighter):
		var selected_card: Dictionary = hands[0][selected_hand_indices[0]]
		effects.text = ("CHOOSE ATK OR DEF  //  %s" % trait_text) if selected_card["kind"] == "stat" else "PLAY %s HERE  //  %s" % [String(selected_card["name"]).to_upper(), trait_text]
	elif phase == PHASE_HEAL and owner == 0 and selected_healer_id != -1:
		effects.text = ("HEALER SELECTED" if int(fighter["id"]) == selected_healer_id else "HEAL THIS ALLY") + "  //  " + trait_text
	elif phase == PHASE_ATTACK and owner == 0:
		effects.text = ("IN PIT" if fighter["id"] in selected_attacker_ids else "HELD BACK") + "  //  " + trait_text
	else:
		effects.text = trait_text
	effects.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	effects.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	effects.add_theme_font_size_override("font_size", 9)
	effects.add_theme_color_override("font_color", MUTED)
	content.add_child(effects)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(spacer)

	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 8)
	content.add_child(stats)
	var attack_box := VBoxContainer.new()
	attack_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats.add_child(attack_box)
	var attack_value := Label.new()
	attack_value.text = str(_fighter_attack(fighter))
	attack_value.add_theme_font_size_override("font_size", 24)
	attack_value.add_theme_color_override("font_color", RED)
	attack_box.add_child(attack_value)
	var attack_caption := Label.new()
	attack_caption.text = "ATTACK"
	attack_caption.add_theme_font_size_override("font_size", 9)
	attack_caption.add_theme_color_override("font_color", MUTED)
	attack_box.add_child(attack_caption)

	var defense_box := VBoxContainer.new()
	defense_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats.add_child(defense_box)
	var defense_value_row := HBoxContainer.new()
	defense_value_row.alignment = BoxContainer.ALIGNMENT_END
	defense_value_row.add_theme_constant_override("separation", 1)
	defense_box.add_child(defense_value_row)
	var defense_current := Label.new()
	defense_current.text = str(_fighter_remaining(fighter))
	defense_current.add_theme_font_size_override("font_size", 24)
	defense_current.add_theme_color_override("font_color", BLUE)
	defense_value_row.add_child(defense_current)
	var defense_slash := Label.new()
	defense_slash.text = "/"
	defense_slash.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	defense_slash.add_theme_font_size_override("font_size", 12)
	defense_slash.add_theme_color_override("font_color", Color(BLUE, 0.75))
	defense_value_row.add_child(defense_slash)
	var defense_maximum := Label.new()
	defense_maximum.text = str(_fighter_max_defense(fighter))
	defense_maximum.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	defense_maximum.add_theme_font_size_override("font_size", 12)
	defense_maximum.add_theme_color_override("font_color", Color(BLUE, 0.75))
	defense_value_row.add_child(defense_maximum)
	var defense_caption := Label.new()
	defense_caption.text = "DEFENSE"
	defense_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	defense_caption.add_theme_font_size_override("font_size", 9)
	defense_caption.add_theme_color_override("font_color", MUTED)
	defense_box.add_child(defense_caption)

	var stat_slots_active := owner == 0 and phase == PHASE_TRAIN and stat_cards_played_this_turn < MAX_STAT_TRAINING_PER_TURN and selected_hand_indices.size() == 1 and _is_stat_upgrade_card(hands[0][selected_hand_indices[0]])
	if stat_slots_active:
		var selected_stat: Dictionary = hands[0][selected_hand_indices[0]]
		var preview_value := _preview_effective_card_value(0, selected_stat)
		var current_attack := _fighter_attack(fighter)
		var current_defense := _fighter_remaining(fighter)
		var maximum_defense := _fighter_max_defense(fighter)
		var attack_slot := Button.new()
		attack_slot.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
		attack_slot.offset_left = 3
		attack_slot.offset_right = 99
		attack_slot.offset_top = -52
		attack_slot.offset_bottom = -2
		attack_slot.text = "%d -> %d" % [current_attack, current_attack + preview_value]
		attack_slot.autowrap_mode = TextServer.AUTOWRAP_OFF
		attack_slot.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		attack_slot.tooltip_text = "Add the selected stat card to %s's attack." % _fighter_name(fighter)
		attack_slot.add_theme_font_size_override("font_size", _fit_single_line_font(attack_slot.text, 16, 88.0))
		attack_slot.add_theme_color_override("font_color", INK)
		var attack_normal := _style(Color(0.35, 0.08, 0.18, 0.80), RED, 2, 7)
		var attack_hover := _style(Color(0.50, 0.10, 0.24, 0.96), GOLD, 3, 7)
		for attack_style in [attack_normal, attack_hover]:
			attack_style.content_margin_left = 3.0
			attack_style.content_margin_right = 3.0
		attack_slot.add_theme_stylebox_override("normal", attack_normal)
		attack_slot.add_theme_stylebox_override("hover", attack_hover)
		attack_slot.pressed.connect(_on_fighter_stat_slot_pressed.bind(owner, int(fighter["id"]), "attack"))
		button.add_child(attack_slot)
		var defense_slot := Button.new()
		defense_slot.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		defense_slot.offset_left = -99
		defense_slot.offset_right = -3
		defense_slot.offset_top = -52
		defense_slot.offset_bottom = -2
		defense_slot.text = "%d/%d -> %d/%d" % [current_defense, maximum_defense, current_defense + preview_value, maximum_defense + preview_value]
		defense_slot.autowrap_mode = TextServer.AUTOWRAP_OFF
		defense_slot.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		defense_slot.tooltip_text = "Add the selected stat card to %s's defense." % _fighter_name(fighter)
		defense_slot.add_theme_font_size_override("font_size", _fit_single_line_font(defense_slot.text, 16, 88.0))
		defense_slot.add_theme_color_override("font_color", INK)
		var defense_normal := _style(Color(0.04, 0.24, 0.38, 0.82), BLUE, 2, 7)
		var defense_hover := _style(Color(0.05, 0.36, 0.52, 0.96), GOLD, 3, 7)
		for defense_style in [defense_normal, defense_hover]:
			defense_style.content_margin_left = 3.0
			defense_style.content_margin_right = 3.0
		defense_slot.add_theme_stylebox_override("normal", defense_normal)
		defense_slot.add_theme_stylebox_override("hover", defense_hover)
		defense_slot.pressed.connect(_on_fighter_stat_slot_pressed.bind(owner, int(fighter["id"]), "defense"))
		button.add_child(defense_slot)


func _is_valid_selected_card_target(owner: int, fighter: Dictionary) -> bool:
	if active_player != 0 or selected_hand_indices.size() != 1:
		return false
	var hand_index: int = selected_hand_indices[0]
	if hand_index < 0 or hand_index >= hands[0].size():
		return false
	var card: Dictionary = hands[0][hand_index]
	if phase == PHASE_TRAIN:
		if card.has("faction_id"):
			if String(card.get("kind", "")) == "training" and training_cards_played_this_turn[0] >= MAX_TRAINING_CARDS_PER_TURN:
				return false
			match String(card.get("target", "none")):
				"ally_fighter":
					return owner == 0
				"enemy_fighter":
					if String(card.get("effect", "")) == "summon_copy_enemy_stat":
						return owner == 1 and not _is_dead(fighter)
					return owner == 1 and (not fighter["evasive"] or bool(fighter.get("evasive_once", false)))
				"any_fighter":
					return true
				_:
					return false
		if _is_stat_upgrade_card(card):
			return owner == 0 and stat_cards_played_this_turn < MAX_STAT_TRAINING_PER_TURN
		if card["kind"] in ["weapon", "shield", "blessing", "training"]:
			return owner == 0 and (card["kind"] != "training" or training_cards_played_this_turn[0] < MAX_TRAINING_CARDS_PER_TURN)
		if card["kind"] == "curse":
			return card["name"] != "Armageddon" and owner == 1 and not fighter["evasive"]
	if phase == PHASE_HEAL and card["kind"] == "heal":
		return owner == 0 and fighter["damage"] > 0 and _heal_card_can_target_fighter(card)
	return false


func _selected_card_targets() -> Array[Dictionary]:
	var targets: Array[Dictionary] = []
	for owner in 2:
		for fighter in fighters[owner]:
			if _is_valid_selected_card_target(owner, fighter):
				targets.append({"owner": owner, "fighter": fighter})
	return targets


func _is_fighter_selected(owner: int, fighter_id: int) -> bool:
	if phase == PHASE_HEAL and owner == 0 and selected_healer_id != -1:
		return fighter_id == selected_healer_id
	if phase == PHASE_ATTACK and owner == 0:
		return fighter_id in selected_attacker_ids
	if phase == PHASE_COMBAT:
		if owner == active_player:
			return fighter_id in pending_attack_ids
		if owner == 1 - active_player:
			var defender := _get_fighter(owner, fighter_id)
			return not defender.is_empty() and not _is_dead(defender)
	if phase == PHASE_DEFEND:
		if owner == 1:
			return fighter_id == selected_defend_attacker_id
		for attacker_id in block_assignments.keys():
			if fighter_id in block_assignments[attacker_id]:
				return true
	return false


func _refresh_prompt() -> void:
	if game_over:
		prompt_label.text = "THE CROWD HAS ITS VERDICT."
		return
	if active_player == 1 and phase != PHASE_DEFEND:
		prompt_label.text = "This Computer is making its move..."
		return
	match phase:
		PHASE_DRAW:
			prompt_label.text = "Draw one card to open your turn."
		PHASE_TRAIN:
			if selected_hand_indices.size() == 1:
				var selected_card: Dictionary = hands[0][selected_hand_indices[0]]
				if selected_card.has("faction_id"):
					prompt_label.text = "%s — %s" % [selected_card["name"], selected_card["description"]]
				elif selected_card["kind"] in ["weapon", "shield", "blessing", "training"]:
					prompt_label.text = "Click a highlighted fighter to play %s.%s" % [selected_card["name"], " Training cards: %d of %d used." % [training_cards_played_this_turn[0], MAX_TRAINING_CARDS_PER_TURN] if selected_card["kind"] == "training" else ""]
				elif selected_card["kind"] == "curse":
					prompt_label.text = "Press the Orders button to destroy all fighters." if selected_card["name"] == "Armageddon" else "Click a highlighted enemy fighter to cast %s. Curse plays are unlimited during TRAIN." % selected_card["name"]
				elif selected_card["kind"] == "heal":
					prompt_label.text = "Heal cards are used during the HEAL phase."
				elif _is_stat_upgrade_card(selected_card):
					prompt_label.text = "STAT %d: create one fighter or add +%d to an existing stat. Existing-fighter training: %d/1." % [selected_card["value"], selected_card["value"], stat_cards_played_this_turn]
				elif selected_card["kind"] == "summon":
					prompt_label.text = "A new fighter was started this turn, so the squad is unavailable." if trained_this_turn or new_fighter_attack > 0 or new_fighter_defense > 0 else "Press Call in the Squad to summon three temporary 3/3 fighters."
				else:
					prompt_label.text = "Choose a valid target."
			else:
				prompt_label.text = "Select stat cards to create one fighter, plus train one existing stat per turn. Existing-fighter training: %d/1." % stat_cards_played_this_turn
		PHASE_ATTACK:
			prompt_label.text = "All ready fighters start in the pit. Click any fighter to hold it back, then send the rest."
		PHASE_HEAL:
			prompt_label.text = "Use heal cards, or select Chaste Chase then a wounded allied fighter."
		PHASE_COMBAT:
			prompt_label.text = "Both sides enter automatically. The fighters rush the center and scuffle."
		PHASE_DEFEND:
			prompt_label.text = "All surviving defenders enter the pit automatically."


func _refresh_commands() -> void:
	action_button.visible = true
	advance_button.visible = true
	action_button.disabled = input_locked or game_over
	advance_button.disabled = input_locked or game_over
	if game_over:
		action_button.text = "MATCH OVER"
		advance_button.visible = false
		return
	if active_player == 1 and phase != PHASE_DEFEND:
		action_button.text = "THIS COMPUTER ACTING"
		action_button.disabled = true
		advance_button.visible = false
		return
	match phase:
		PHASE_DRAW:
			action_button.text = "DRAW CARD"
			advance_button.visible = false
		PHASE_TRAIN:
			if selected_hand_indices.size() == 1:
				var selected_card: Dictionary = hands[0][selected_hand_indices[0]]
				if selected_card.has("faction_id"):
					action_button.text = "DEPLOY %s" % String(selected_card["name"]).to_upper()
					if _faction_card_requires_fighter_target(selected_card):
						action_button.disabled = _selected_card_targets().size() != 1
				elif selected_card["kind"] == "stat":
					action_button.text = "CHOOSE A STAT SLOT"
					action_button.disabled = true
				elif selected_card["kind"] == "summon":
					action_button.text = "CALL IN THE SQUAD"
					action_button.disabled = input_locked or trained_this_turn or new_fighter_attack > 0 or new_fighter_defense > 0
				elif selected_card["kind"] == "curse" and selected_card["name"] == "Armageddon":
					action_button.text = "UNLEASH ARMAGEDDON"
				elif selected_card["kind"] == "heal":
					action_button.text = "USE DURING HEAL"
					action_button.disabled = true
				else:
					var targets := _selected_card_targets()
					if targets.size() == 1:
						action_button.text = "PLAY ON %s" % _fighter_name(targets[0]["fighter"]).to_upper()
						action_button.disabled = input_locked
					elif targets.is_empty():
						action_button.text = "NO VALID TARGET"
						action_button.disabled = true
					else:
						action_button.text = "CHOOSE HIGHLIGHTED FIGHTER"
						action_button.disabled = true
			else:
				action_button.text = "SELECT A CARD  //  STAT TRAINING %d/1" % stat_cards_played_this_turn
				action_button.disabled = true
			advance_button.text = "ADVANCE TO ATTACK"
		PHASE_ATTACK:
			action_button.text = "SEND TO PIT" if not selected_attacker_ids.is_empty() else "HOLD FIGHTERS"
			advance_button.text = "SKIP ATTACK"
		PHASE_HEAL:
			action_button.visible = false
			advance_button.text = "END TURN"
		PHASE_DEFEND:
			action_button.text = "RESOLVE COMBAT"
			advance_button.visible = false
		PHASE_COMBAT:
			action_button.text = "BLOCKERS ASSIGNED"
			action_button.disabled = true
			advance_button.visible = false


func _card_display_text(card: Dictionary) -> String:
	var type_name: String = card["kind"].to_upper()
	if card["kind"] == "stat":
		return "STAT\n\n      %d\n\nATK or DEF" % card["value"]
	if card["kind"] == "curse" and card["name"] == "Deathmark":
		return "CURSE\n\nDEATHMARK"
	var value_line := ""
	if card["kind"] == "weapon":
		value_line = "+%d ATK" % card["value"]
	elif card["kind"] == "shield":
		value_line = "+%d DEF" % card["value"]
	elif card["kind"] == "heal":
		value_line = "RESTORE %d" % card["value"]
	elif card["name"] in ["Poison", "Madness", "Berserker"]:
		value_line = "%d%% EFFECT" % card["value"] if card["name"] != "Poison" else "2 / TURN"
	else:
		value_line = "SPECIAL"
	return "%s\n\n%s\n\n%s" % [type_name, card["name"].to_upper(), value_line]


func _card_color(kind: String) -> Color:
	match kind:
		"stat":
			return Color("#4f8cff")
		"weapon":
			return RED
		"shield":
			return BLUE
		"curse":
			return PURPLE
		"blessing":
			return Color("#f472b6")
		"heal":
			return GREEN
		"training":
			return Color("#20c7b7")
		"summon":
			return Color("#ff7ab8")
	return MUTED


func _fighter_display_text(fighter: Dictionary) -> String:
	var attack := _fighter_attack(fighter)
	var maximum := _fighter_max_defense(fighter)
	var remaining := _fighter_remaining(fighter)
	var tags := _fighter_tags(fighter)
	var tag_line := "BARE-KNUCKLE" if tags.is_empty() else "  ".join(tags)
	return "%s\n\n  %d ATK     %d/%d DEF\n\n%s" % [_fighter_name(fighter), attack, remaining, maximum, tag_line]


func _fighter_tooltip(fighter: Dictionary) -> String:
	var owner := int(fighter.get("owner", -1))
	var lines: Array[String] = [
		_fighter_name(fighter),
		"%s fighter" % ("Your" if owner == 0 else "Enemy"),
		"Attack: %d  Defense: %d/%d  Damage: %d" % [_fighter_attack(fighter), _fighter_remaining(fighter), _fighter_max_defense(fighter), int(fighter.get("damage", 0))],
		"Base: %d/%d  Permanent bonuses: %+d/%+d" % [int(fighter.get("attack_base", 0)), int(fighter.get("defense_base", 0)), int(fighter.get("attack_bonus", 0)), int(fighter.get("defense_bonus", 0))],
	]
	if not fighter["weapons"].is_empty():
		lines.append("Weapons: %s" % ", ".join(fighter["weapons"]))
	if not fighter["shields"].is_empty():
		lines.append("Shields: %s" % ", ".join(fighter["shields"]))
	var tags := _fighter_tags(fighter)
	if not tags.is_empty():
		lines.append("Effects: %s" % ", ".join(tags))
	var details: Array[String] = []
	var poison_stacks := _status_stacks(fighter, "poison")
	if poison_stacks > 0:
		details.append("Poison — %d stack%s; takes %d damage at the start of its owner's turn." % [poison_stacks, "" if poison_stacks == 1 else "s", poison_stacks * 2])
	var madness_stacks := _status_stacks(fighter, "madness")
	if madness_stacks > 0:
		details.append("Madness — %d stack%s; %d%% chance each combat swing hits itself." % [madness_stacks, "" if madness_stacks == 1 else "s", mini(100, madness_stacks * 25)])
	if bool(fighter.get("evasive", false)):
		details.append("Evasive — cannot be targeted by enemy curses.")
	if bool(fighter.get("evasive_once", false)):
		details.append("Phase-shift — ignores the next hostile fighter effect.")
	if bool(fighter.get("temporary_evasive", false)):
		details.append("Temporary evasive — curse immunity lasts through the next combat.")
	var berserker_stacks := _status_stacks(fighter, "berserker")
	if berserker_stacks > 0:
		details.append("Berserker — %d stack%s; %d%% chance to deal double combat damage." % [berserker_stacks, "" if berserker_stacks == 1 else "s", mini(100, berserker_stacks * 25)])
	if bool(fighter.get("shield_master", false)):
		details.append("Shield Master — shield effects are enhanced.")
	if bool(fighter.get("zen", false)):
		details.append("Zen Master — turns healing into lasting attack.")
	if bool(fighter.get("explosive", false)):
		details.append("Explosive Master — splashes 2 damage after combat.")
	if bool(fighter.get("lifesteal", false)):
		details.append("Lifesteal — combat damage restores player health.")
	if int(fighter.get("pierce", 0)) > 0:
		details.append("Pierce %d — adds that much damage to scuffle rolls against fighters." % int(fighter["pierce"]))
	if int(fighter.get("thorns", 0)) > 0:
		details.append("Thorns %d — damages an attacker that strikes this fighter." % int(fighter["thorns"]))
	if int(fighter.get("recoil_damage", 0)) > 0:
		details.append("Recoil %d — takes this damage after its next attack." % int(fighter["recoil_damage"]))
	if int(fighter.get("combat_damage_reduction", 0)) > 0:
		details.append("Suppression — loses %d attack for %d more combat(s)." % [int(fighter["combat_damage_reduction"]), int(fighter.get("reduction_combats", 0))])
	if int(fighter.get("damage_prevention", 0)) > 0:
		details.append("Ward %d — prevents that much incoming fighter damage." % int(fighter["damage_prevention"]))
	if int(fighter.get("shield_break_heal", 0)) > 0:
		details.append("Break heal — restores %d defense when its shield would break." % int(fighter["shield_break_heal"]))
	if int(fighter.get("shield_break_draw", 0)) > 0:
		details.append("Break draw — draws %d card when its shield is depleted." % int(fighter["shield_break_draw"]))
	if bool(fighter.get("deathless_once", false)):
		details.append("Deathless — survives the next lethal hit at 1 defense.")
	if int(fighter.get("aura_defense", 0)) > 0:
		details.append("Defense aura — every other ally gains +%d defense." % int(fighter["aura_defense"]))
	if int(fighter.get("ally_trained_defense", 0)) > 0:
		details.append("Trainer — gains +%d defense whenever an ally is trained." % int(fighter["ally_trained_defense"]))
	if int(fighter.get("counterattack_bonus", 0)) > 0:
		details.append("Counter-growth — gains +%d attack after surviving a block." % int(fighter["counterattack_bonus"]))
	if int(fighter.get("survive_combat_attack", 0)) > 0:
		details.append("Battle growth — gains +%d attack after surviving combat." % int(fighter["survive_combat_attack"]))
	if int(fighter.get("temporary_attack", 0)) != 0:
		details.append("Temporary attack: %+d until the current effect expires." % int(fighter["temporary_attack"]))
	if int(fighter.get("ocean_defense_bonus", 0)) > 0:
		details.append("Ocean blessing — +%d defense from the active ascension." % int(fighter["ocean_defense_bonus"]))
	if int(fighter.get("squad_turns_remaining", 0)) > 0:
		details.append("Squad fighter — leaves after %d turn(s)." % int(fighter["squad_turns_remaining"]))
	if not details.is_empty():
		lines.append("")
		lines.append_array(details)
	return "\n".join(lines)


func _fighter_tags(fighter: Dictionary) -> Array[String]:
	var tags: Array[String] = []
	var poison_stacks := _status_stacks(fighter, "poison")
	if poison_stacks > 0:
		tags.append("POISON" if poison_stacks == 1 else "POISON x%d" % poison_stacks)
	var madness_stacks := _status_stacks(fighter, "madness")
	if madness_stacks > 0:
		tags.append("MAD" if madness_stacks == 1 else "MAD x%d" % madness_stacks)
	if fighter["evasive"]:
		tags.append("EVASIVE")
	var berserker_stacks := _status_stacks(fighter, "berserker")
	if berserker_stacks > 0:
		tags.append("RAGE" if berserker_stacks == 1 else "RAGE x%d" % berserker_stacks)
	if fighter["shield_master"]:
		tags.append("SHIELD+")
	if fighter["zen"]:
		tags.append("ZEN")
	if fighter["explosive"]:
		tags.append("BLAST")
	match fighter.get("squad_role", ""):
		"unblockable":
			tags.append("UNBLOCKABLE")
		"wild_splash":
			tags.append("15% WILD SPLASH")
		"ally_healer":
			tags.append("ALLY HEAL")
	if int(fighter.get("squad_turns_remaining", 0)) > 0:
		tags.append("%d TURNS" % int(fighter["squad_turns_remaining"]))
	return tags


func _fighter_attack(fighter: Dictionary) -> int:
	if fighter.is_empty():
		return 0
	var amount := int(fighter["attack_base"]) + int(fighter["attack_bonus"])
	if int(fighter.get("owner", -1)) == 0:
		amount += _artifact_total("team_attack")
	return amount


func _fighter_max_defense(fighter: Dictionary) -> int:
	if fighter.is_empty():
		return 0
	var aura_bonus := 0
	var owner := int(fighter.get("owner", -1))
	if owner >= 0 and owner < fighters.size():
		for ally in fighters[owner]:
			if ally != fighter and not _is_dead_without_aura(ally):
				aura_bonus += int(ally.get("aura_defense", 0))
	var artifact_bonus := _artifact_total("team_defense") if owner == 0 else 0
	if owner == 0 and _fighter_is_assigned_blocker(int(fighter.get("id", -1))):
		artifact_bonus += _artifact_total("blocker_defense")
	return int(fighter["defense_base"]) + int(fighter["defense_bonus"]) + aura_bonus + artifact_bonus


func _fighter_is_assigned_blocker(fighter_id: int) -> bool:
	if phase != PHASE_COMBAT:
		return false
	for owner in 2:
		for fighter in fighters[owner]:
			if int(fighter["id"]) == fighter_id:
				return owner != active_player
	return false


func _is_dead_without_aura(fighter: Dictionary) -> bool:
	return int(fighter.get("defense_base", 0)) + int(fighter.get("defense_bonus", 0)) - int(fighter.get("damage", 0)) <= 0


func _fighter_remaining(fighter: Dictionary) -> int:
	return max(0, _fighter_max_defense(fighter) - int(fighter["damage"]))


func _status_stacks(fighter: Dictionary, status: String) -> int:
	var explicit_stacks := int(fighter.get("%s_stacks" % status, 0))
	if explicit_stacks > 0:
		return explicit_stacks
	return 1 if bool(fighter.get(status, false)) else 0


func _remove_one_curse_stack(fighter: Dictionary) -> void:
	for status in ["poison", "madness"]:
		var stacks := _status_stacks(fighter, status)
		if stacks <= 0:
			continue
		stacks -= 1
		fighter["%s_stacks" % status] = stacks
		fighter[status] = stacks > 0
		return


func _is_dead(fighter: Dictionary) -> bool:
	return _fighter_remaining(fighter) <= 0


func _get_fighter(owner: int, fighter_id: int) -> Dictionary:
	for fighter in fighters[owner]:
		if int(fighter["id"]) == fighter_id:
			return fighter
	return {}


func _phase_card_hint(card: Dictionary) -> String:
	if card["kind"] == "heal":
		return "HEAL CARDS ARE USED IN THE HEAL PHASE"
	return "PLAY THAT CARD DURING TRAINING"


func _owner_name(owner: int) -> String:
	return "You" if owner == 0 else "This Computer"


func _fighter_name(fighter: Dictionary) -> String:
	return fighter.get("name", "Fighter #%02d" % fighter["id"])


func _log_event(message: String, speaker: int = LOG_AUTO, show_computer_flash: bool = true) -> void:
	var resolved_speaker := _infer_log_speaker(message) if speaker == LOG_AUTO else speaker
	log_lines.append({"text": message, "speaker": resolved_speaker})
	while log_lines.size() > 60:
		log_lines.pop_front()
	if resolved_speaker == LOG_COMPUTER and show_computer_flash:
		computer_log_flash_queue.append(message)
		if not computer_log_flash_running:
			call_deferred("_run_computer_log_flash_queue")


func _run_computer_log_flash_queue() -> void:
	if computer_log_flash_running:
		return
	computer_log_flash_running = true
	while not computer_log_flash_queue.is_empty() and is_instance_valid(action_flash_panel):
		var message: String = computer_log_flash_queue.pop_front()
		await _show_action_flash(message, 0.5)
	computer_log_flash_running = false


func _show_action_flash(message: String, duration: float = 0.5) -> void:
	if not is_instance_valid(action_flash_panel):
		return
	action_flash_label.text = "[center]%s[/center]" % message
	action_flash_panel.modulate.a = 0.0
	var flash := create_tween()
	flash.tween_property(action_flash_panel, "modulate:a", 1.0, 0.06)
	flash.tween_interval(maxf(0.02, duration - 0.12))
	flash.tween_property(action_flash_panel, "modulate:a", 0.0, 0.06)
	await flash.finished


func _infer_log_speaker(message: String) -> int:
	var lowered := message.to_lower()
	if "the gates open" in lowered or "round " in lowered or "healing phase" in lowered or "heal cards" in lowered:
		return LOG_NEUTRAL
	if "training closes" in lowered or "victory" in lowered or "defeat" in lowered or "both stables fall" in lowered:
		return LOG_NEUTRAL
	if "this computer" in lowered:
		return LOG_COMPUTER
	if "you " in lowered or "your " in lowered:
		return LOG_HUMAN
	return LOG_NEUTRAL


func _format_fight_log() -> String:
	var messages: Array[String] = []
	log_card_lookup.clear()
	for event in log_lines:
		var message := _prepare_log_event_message(event)
		var speaker: int = int(event.get("speaker", LOG_NEUTRAL))
		match speaker:
			LOG_HUMAN:
				messages.append("YOU  •  %s" % message)
			LOG_COMPUTER:
				messages.append("COMPUTER  •  %s" % message)
			_:
				messages.append("•  %s" % message)
	return "\n".join(messages)


func _prepare_log_event_message(event: Dictionary) -> String:
	var message := _strip_log_visual_bbcode(String(event.get("text", "")))
	for reference in event.get("card_refs", []):
		var key := String(reference.get("key", ""))
		var card_name := String(reference.get("name", ""))
		var card: Dictionary = reference.get("card", {})
		if key.is_empty() or card_name.is_empty() or card.is_empty():
			continue
		log_card_lookup[key] = card
		message = message.replace(card_name, "[url=card:%s][u]%s[/u][/url]" % [key, card_name])
	return _glossary_wrap(message)


func _render_fight_log() -> void:
	if not is_instance_valid(log_label):
		return
	log_label.clear()
	log_card_lookup.clear()
	var human_count := 0
	var computer_count := 0
	var neutral_count := 0
	for event_index in log_lines.size():
		var event: Dictionary = log_lines[event_index]
		var speaker: int = int(event.get("speaker", LOG_NEUTRAL))
		var alignment := HORIZONTAL_ALIGNMENT_CENTER
		var foreground := Color("#dcecff")
		var background := Color("#18344f")
		var prefix := "  •  "
		match speaker:
			LOG_HUMAN:
				alignment = HORIZONTAL_ALIGNMENT_LEFT
				foreground = Color("#d7fbff")
				background = Color("#14505b")
				prefix = "  YOU  •  "
				human_count += 1
			LOG_COMPUTER:
				alignment = HORIZONTAL_ALIGNMENT_RIGHT
				foreground = Color("#f8e8ff")
				background = Color("#55306d")
				prefix = "  COMPUTER  •  "
				computer_count += 1
			_:
				neutral_count += 1
		log_label.push_paragraph(alignment)
		log_label.push_bgcolor(background)
		log_label.push_color(foreground)
		log_label.add_text(prefix)
		# Only the prepared message is parsed, so URL metadata remains interactive
		# without allowing old color/alignment wrappers to leak into the log.
		log_label.append_text(_prepare_log_event_message(event))
		log_label.add_text("  ")
		log_label.pop()
		log_label.pop()
		log_label.pop()
		if event_index < log_lines.size() - 1:
			log_label.newline()
	log_label.set_meta("chat_style_human_count", human_count)
	log_label.set_meta("chat_style_computer_count", computer_count)
	log_label.set_meta("chat_style_neutral_count", neutral_count)
	log_label.set_meta("chat_style_human_color", Color("#14505b"))
	log_label.set_meta("chat_style_computer_color", Color("#55306d"))


func _strip_log_visual_bbcode(message: String) -> String:
	# Log colors/alignment are presentation-only and can become visible fragments
	# when nested with selectable URL metadata. Keep card/glossary links, but make
	# each log line itself plain and copy-safe.
	var visual_tags := RegEx.new()
	visual_tags.compile("\\[/?(?:color|bgcolor|left|right|center)(?:=[^\\]]+)?\\]")
	return visual_tags.sub(message, "", true)


func _glossary_wrap(message: String) -> String:
	var result := ""
	var token := ""
	var inside_tag := false
	var tag_buffer := ""
	var url_depth := 0
	for index in message.length():
		var character := message.substr(index, 1)
		if character == "[":
			result += token if url_depth > 0 else _glossary_token(token)
			token = ""
			inside_tag = true
			tag_buffer = "["
		elif inside_tag:
			tag_buffer += character
			if character == "]":
				result += tag_buffer
				var lowered_tag := tag_buffer.to_lower()
				if lowered_tag.begins_with("[url="):
					url_depth += 1
				elif lowered_tag == "[/url]":
					url_depth = maxi(0, url_depth - 1)
				inside_tag = false
				tag_buffer = ""
		elif character.to_lower() in "abcdefghijklmnopqrstuvwxyz0123456789_'":
			token += character
		else:
			result += (token if url_depth > 0 else _glossary_token(token)) + character
			token = ""
	if inside_tag:
		result += tag_buffer
	result += token if url_depth > 0 else _glossary_token(token)
	return result


func _glossary_token(token: String) -> String:
	if token.is_empty():
		return token
	var key := token.to_lower()
	var aliases := {"attacks":"attack", "attacking":"attack", "blocks":"block", "blocking":"block", "blockers":"blocker", "curses":"curse", "cursed":"curse", "artifacts":"artifact", "fighters":"fighter"}
	key = String(aliases.get(key, key))
	if not GAME_TERM_TOOLTIPS.has(key):
		return token
	return "[url=term:%s][u]%s[/u][/url]" % [key, token]


func _on_log_meta_hover_started(meta: Variant) -> void:
	var meta_key := String(meta)
	if meta_key.begins_with("card:"):
		var card_key := meta_key.trim_prefix("card:")
		var card: Dictionary = log_card_lookup.get(card_key, {})
		if not card.is_empty():
			_show_log_card_tooltip(card)
		return
	var term_key := meta_key.trim_prefix("term:")
	if GAME_TERM_TOOLTIPS.has(term_key):
		log_label.tooltip_text = "%s\n%s" % [term_key.capitalize(), GAME_TERM_TOOLTIPS[term_key]]


func _on_log_meta_hover_ended(meta: Variant) -> void:
	log_label.tooltip_text = ""
	if String(meta).begins_with("card:"):
		_hide_log_card_tooltip()


func _show_log_card_tooltip(card: Dictionary) -> void:
	_hide_log_card_tooltip()
	var preview := _make_card_animation_visual(card)
	preview.name = "FightLogCardTooltip"
	preview.size = Vector2(280, 412)
	preview.custom_minimum_size = preview.size
	preview.z_index = 1000
	design_surface.add_child(preview)
	var desired := design_surface.get_local_mouse_position() + Vector2(22, 18)
	desired.x = clampf(desired.x, 8.0, maxf(8.0, design_surface.size.x - preview.size.x - 8.0))
	desired.y = clampf(desired.y, 8.0, maxf(8.0, design_surface.size.y - preview.size.y - 8.0))
	preview.position = desired
	preview.set_meta("source", "fight_log_card")
	log_card_tooltip = preview


func _hide_log_card_tooltip() -> void:
	if is_instance_valid(log_card_tooltip):
		log_card_tooltip.queue_free()
	log_card_tooltip = null


func _show_toast(message: String, duration: float = 0.7) -> void:
	if not is_instance_valid(toast_panel):
		return
	toast_label.text = message
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if toast_tween and toast_tween.is_valid():
		toast_tween.kill()
	toast_panel.modulate.a = 0.0
	toast_tween = create_tween()
	toast_tween.tween_property(toast_panel, "modulate:a", 1.0, 0.05)
	toast_tween.tween_interval(max(0.05, duration - 0.10))
	toast_tween.tween_property(toast_panel, "modulate:a", 0.0, 0.05)


func _play_phase_cue() -> void:
	var cue_path := "res://sounds/draw_a_card/HTG 37.wav"
	if not FileAccess.file_exists(cue_path) or sfx_players.is_empty():
		return
	var stream := _load_audio_file(cue_path)
	if stream == null:
		return
	var player := sfx_players[next_sfx_player]
	next_sfx_player = (next_sfx_player + 1) % sfx_players.size()
	player.stream = stream
	player.play()


func _phase_beat(owner: int, phase_name: String, unlock_after: bool) -> void:
	var serial := match_serial
	input_locked = true
	var actor := "YOU" if owner == 0 else "THIS COMPUTER"
	_show_toast("%s  //  %s" % [actor, phase_name], 0.3)
	_refresh_all()
	await get_tree().create_timer(0.3).timeout
	if serial != match_serial or game_over:
		return
	_play_phase_cue()
	if unlock_after:
		input_locked = false
		_refresh_all()


func _clear_container(container: Container) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _check_game_over() -> void:
	if game_over:
		return
	if player_health[0] > 0 and player_health[1] > 0:
		return
	game_over = true
	_stop_pit_audio(true)
	input_locked = true
	phase = PHASE_GAME_OVER
	selected_hand_indices.clear()
	selected_attacker_ids.clear()
	if player_health[0] <= 0 and player_health[1] <= 0:
		_log_event("[color=#d8a94b]Both stables fall. The match is a draw.[/color]")
		_show_toast("DRAW  //  NO ONE LEAVES THE PIT")
	elif player_health[1] <= 0:
		_log_event("[color=#58a66b]VICTORY. This Computer has fallen.[/color]")
		_show_toast("VICTORY  //  THE PIT IS YOURS")
		_offer_artifact_choices()
	else:
		_log_event("[color=#c33b35]DEFEAT. Your stable has fallen.[/color]")
		_show_toast("DEFEAT  //  THE CROWD TURNS AWAY")
		defeat_layer.visible = true
		defeat_layer.move_to_front()
		_start_game_over_audio()
	if is_instance_valid(return_menu_button):
		return_menu_button.visible = player_health[0] <= 0 and player_health[1] <= 0
		return_menu_button.move_to_front()
	_refresh_all()


func _finish_victory_rewards(popup_epoch: int, _artifact_id: String, reward_match_serial: int) -> void:
	var waited := 0.0
	while is_instance_valid(artifact_popup) and artifact_popup.visible and artifact_popup_epoch == popup_epoch and waited < 3.2:
		await get_tree().create_timer(0.1).timeout
		waited += 0.1
	if reward_match_serial != match_serial or not game_over:
		return
	_open_upgrade_tree()
