class_name FactionData
extends RefCounted

## Canonical faction and card content. Returned dictionaries are deep copies so a
## match may safely add runtime fields (owner, damage, instance id, and so on).

const VALID_KINDS := ["stat", "weapon", "shield", "curse", "blessing", "heal", "training", "summon", "faction"]
const VALID_TARGETS := ["self", "ally_fighter", "enemy_fighter", "any_fighter", "ally_player", "enemy_player", "any_player", "all_allies", "all_enemies", "battlefield", "none"]
const TRIANGLE := {
	"assault": {"beats": "engine", "loses_to": "bulwark"},
	"engine": {"beats": "bulwark", "loses_to": "assault"},
	"bulwark": {"beats": "assault", "loses_to": "engine"},
}

const FACTIONS := [
	{
		"id": "cinder_coven", "name": "Cinder Coven", "title": "Golem-Smith Wizards",
		"theme": "Blood, rock, and fire golems animated by dangerous spellcraft.",
		"lean": "assault", "beats": "engine", "weak_to": "bulwark", "color": "#ef5b3f",
		"passive": {"id": "runaway_reaction", "name": "Runaway Reaction", "description": "The first allied fighter damaged each round gains +1 attack for the round.", "effect": "first_ally_damaged_gain_attack", "value": 1},
	},
	{
		"id": "ironroot_compact", "name": "Ironroot Compact", "title": "Dwarven Automata Guild",
		"theme": "Clockwork soldiers, pressure engines, and interlocking shieldworks.",
		"lean": "bulwark", "beats": "assault", "weak_to": "engine", "color": "#d59a45",
		"passive": {"id": "field_repairs", "name": "Field Repairs", "description": "At round end, repair 1 damage on the most damaged allied fighter.", "effect": "round_end_repair_most_damaged", "value": 1},
	},
	{
		"id": "velari_collective", "name": "Velari Collective", "title": "Alien Machine Intellect",
		"theme": "Adaptive robots coordinated by an intelligence beyond the arena.",
		"lean": "engine", "beats": "bulwark", "weak_to": "assault", "color": "#55d6c2",
		"passive": {"id": "predictive_lattice", "name": "Predictive Lattice", "description": "After playing a non-stat card, the next stat card this round has +1 value.", "effect": "prime_next_stat_after_non_stat", "value": 1},
	},
	{
		"id": "sanguine_court", "name": "Sanguine Court", "title": "Vampire Flesh-Shapers",
		"theme": "Blood knights and stitched thralls that grow stronger through pain.",
		"lean": "assault", "beats": "engine", "weak_to": "bulwark", "color": "#b62d58",
		"passive": {"id": "taste_of_victory", "name": "Taste of Victory", "description": "When an enemy fighter is destroyed, heal your player for 2.", "effect": "enemy_destroyed_heal_player", "value": 2},
	},
	{
		"id": "tidebound_conclave", "name": "Tidebound Conclave", "title": "Coral Wardens",
		"theme": "Amphibian mystics protected by living reefs and patient leviathans.",
		"lean": "bulwark", "beats": "assault", "weak_to": "engine", "color": "#3e91c7",
		"passive": {"id": "rising_tide", "name": "Rising Tide", "description": "The first heal each round restores 2 additional health.", "effect": "first_heal_bonus", "value": 2},
	},
	{
		"id": "tempest_clans", "name": "Tempest Clans", "title": "Skyship Beast Riders",
		"theme": "Storm raiders, lightning beasts, and momentum-driven aerial tactics.",
		"lean": "engine", "beats": "bulwark", "weak_to": "assault", "color": "#9b7bea",
		"passive": {"id": "gathering_storm", "name": "Gathering Storm", "description": "Every third card played in a round deals 1 damage to the enemy player.", "effect": "third_card_damage_enemy_player", "value": 1},
	},
]

const CARDS := [
	# Cinder Coven — explosive attack, disposable constructs, and risky magic.
	{"id":"cinder_blood_golem","faction_id":"cinder_coven","name":"Blood Golem","kind":"summon","value":4,"description":"Summon a volatile 4/3 blood construct.","effect":"summon_fighter","target":"self","attack":4,"defense":3},
	{"id":"cinder_rock_golem","faction_id":"cinder_coven","name":"Rock Golem","kind":"summon","value":5,"description":"Summon a steadfast 2/7 stone construct.","effect":"summon_fighter","target":"self","attack":2,"defense":7},
	{"id":"cinder_fire_golem","faction_id":"cinder_coven","name":"Fire Golem","kind":"summon","value":5,"description":"Summon a 5/2 construct that splashes 1 combat damage.","effect":"summon_fighter_splash","target":"self","attack":5,"defense":2},
	{"id":"cinder_molten_fist","faction_id":"cinder_coven","name":"Molten Fist","kind":"weapon","value":3,"description":"Grant a fighter +3 attack.","effect":"add_attack","target":"ally_fighter"},
	{"id":"cinder_obsidian_skin","faction_id":"cinder_coven","name":"Obsidian Skin","kind":"shield","value":5,"description":"Grant a fighter +5 defense.","effect":"add_defense","target":"ally_fighter"},
	{"id":"cinder_hemomancy","faction_id":"cinder_coven","name":"Hemomancy","kind":"curse","value":3,"description":"Deal 3 damage to a fighter; heal your player for damage dealt.","effect":"damage_and_lifesteal","target":"enemy_fighter"},
	{"id":"cinder_emberheart","faction_id":"cinder_coven","name":"Emberheart","kind":"blessing","value":2,"description":"The fighter gains +2 attack after it survives combat.","effect":"survive_combat_gain_attack","target":"ally_fighter"},
	{"id":"cinder_lava_surge","faction_id":"cinder_coven","name":"Lava Surge","kind":"faction","value":2,"description":"Deal 2 damage to every fighter.","effect":"damage_all_fighters","target":"battlefield"},
	{"id":"cinder_rune_forging","faction_id":"cinder_coven","name":"Rune Forging","kind":"training","value":2,"description":"Grant a fighter +2 attack and +2 defense.","effect":"add_attack_defense","target":"ally_fighter","attack":2,"defense":2},
	{"id":"cinder_sacrifice_spark","faction_id":"cinder_coven","name":"Sacrificial Spark","kind":"faction","value":4,"description":"Destroy an allied fighter to deal 4 damage to the enemy player.","effect":"sacrifice_for_player_damage","target":"ally_fighter"},

	# Ironroot Compact — armor, repairs, and clockwork formation play.
	{"id":"ironroot_brass_sentry","faction_id":"ironroot_compact","name":"Brass Sentry","kind":"summon","value":4,"description":"Summon a reliable 3/5 automaton.","effect":"summon_fighter","target":"self","attack":3,"defense":5},
	{"id":"ironroot_gear_colossus","faction_id":"ironroot_compact","name":"Gear Colossus","kind":"summon","value":6,"description":"Summon a massive 4/8 automaton.","effect":"summon_fighter","target":"self","attack":4,"defense":8},
	{"id":"ironroot_ratchet_axe","faction_id":"ironroot_compact","name":"Ratchet Axe","kind":"weapon","value":2,"description":"Grant +2 attack; grant +1 more if the fighter has a shield.","effect":"add_attack_bonus_if_shielded","target":"ally_fighter"},
	{"id":"ironroot_bulwark_plates","faction_id":"ironroot_compact","name":"Bulwark Plates","kind":"shield","value":6,"description":"Grant a fighter +6 defense.","effect":"add_defense","target":"ally_fighter"},
	{"id":"ironroot_emergency_repairs","faction_id":"ironroot_compact","name":"Emergency Repairs","kind":"heal","value":7,"description":"Restore 7 health to a fighter.","effect":"heal","target":"ally_fighter"},
	{"id":"ironroot_overwind","faction_id":"ironroot_compact","name":"Overwind the Spring","kind":"training","value":2,"description":"Grant +2 attack now; take 1 damage after the next combat.","effect":"temporary_attack_with_recoil","target":"ally_fighter"},
	{"id":"ironroot_lockstep","faction_id":"ironroot_compact","name":"Lockstep Protocol","kind":"blessing","value":1,"description":"Adjacent allies gain +1 defense while this fighter lives.","effect":"adjacent_allies_defense_aura","target":"ally_fighter"},
	{"id":"ironroot_jammed_gears","faction_id":"ironroot_compact","name":"Jammed Gears","kind":"curse","value":2,"description":"Target fighter loses 2 attack this round.","effect":"temporary_reduce_attack","target":"enemy_fighter"},
	{"id":"ironroot_foundry_shift","faction_id":"ironroot_compact","name":"Foundry Night Shift","kind":"faction","value":3,"description":"Repair 3 damage on all allied fighters.","effect":"heal_all_allied_fighters","target":"all_allies"},
	{"id":"ironroot_last_redoubt","faction_id":"ironroot_compact","name":"The Last Redoubt","kind":"faction","value":8,"description":"Grant your most damaged fighter +8 defense and heal it for 4.","effect":"fortify_most_damaged_ally","target":"all_allies"},

	# Velari Collective — sequencing, adaptation, and enemy disruption.
	{"id":"velari_probe_unit","faction_id":"velari_collective","name":"Probe Unit K-7","kind":"summon","value":3,"description":"Summon a 2/3 robot and prime your next stat card.","effect":"summon_and_prime_stat","target":"self","attack":2,"defense":3},
	{"id":"velari_mimetic_titan","faction_id":"velari_collective","name":"Mimetic Titan","kind":"summon","value":5,"description":"Summon a 3/3 robot that copies the strongest enemy stat.","effect":"summon_copy_enemy_stat","target":"enemy_fighter","attack":3,"defense":3},
	{"id":"velari_phase_blade","faction_id":"velari_collective","name":"Phase Blade","kind":"weapon","value":3,"description":"Grant +3 attack and +2 scuffle damage against fighters.","effect":"add_attack_and_pierce","target":"ally_fighter"},
	{"id":"velari_quantum_screen","faction_id":"velari_collective","name":"Quantum Screen","kind":"shield","value":4,"description":"Grant +4 defense and prevent the next curse.","effect":"add_defense_and_evasive_once","target":"ally_fighter"},
	{"id":"velari_logic_virus","faction_id":"velari_collective","name":"Logic Virus","kind":"curse","value":2,"description":"Target fighter deals 2 less combat damage for two combats.","effect":"reduce_combat_damage_timed","target":"enemy_fighter"},
	{"id":"velari_recompile","faction_id":"velari_collective","name":"Recompile","kind":"heal","value":6,"description":"Restore 6 health to a fighter and clear one curse.","effect":"heal_and_cleanse","target":"ally_fighter"},
	{"id":"velari_adaptive_matrix","faction_id":"velari_collective","name":"Adaptive Matrix","kind":"training","value":2,"description":"Add +2 to this fighter's lower base stat.","effect":"add_to_lower_stat","target":"ally_fighter"},
	{"id":"velari_shared_processor","faction_id":"velari_collective","name":"Shared Processor","kind":"blessing","value":1,"description":"Whenever you train another fighter, this fighter gains +1 defense.","effect":"other_ally_trained_gain_defense","target":"ally_fighter"},
	{"id":"velari_probability_collapse","faction_id":"velari_collective","name":"Probability Collapse","kind":"faction","value":2,"description":"Discover the strongest available Velari faction pattern and add it to your hand.","effect":"discover_faction_card","target":"self"},
	{"id":"velari_zero_hour","faction_id":"velari_collective","name":"Zero Hour Protocol","kind":"faction","value":1,"description":"Your next three cards this round have +1 value.","effect":"boost_next_cards","target":"self"},

	# Sanguine Court — lifesteal, sacrifice, and relentless pressure.
	{"id":"sanguine_stitched_thrall","faction_id":"sanguine_court","name":"Stitched Thrall","kind":"summon","value":3,"description":"Summon a reckless 4/2 thrall.","effect":"summon_fighter","target":"self","attack":4,"defense":2},
	{"id":"sanguine_crimson_duke","faction_id":"sanguine_court","name":"Crimson Duke","kind":"summon","value":6,"description":"Summon a 5/5 vampire that heals your player when it deals damage.","effect":"summon_fighter_lifesteal","target":"self","attack":5,"defense":5},
	{"id":"sanguine_veinripper","faction_id":"sanguine_court","name":"Veinripper","kind":"weapon","value":4,"description":"Grant +4 attack; the fighter takes 1 damage.","effect":"add_attack_and_self_damage","target":"ally_fighter"},
	{"id":"sanguine_bone_cuirass","faction_id":"sanguine_court","name":"Bone Cuirass","kind":"shield","value":4,"description":"Grant +4 defense and heal 2 when it breaks.","effect":"add_defense_with_break_heal","target":"ally_fighter"},
	{"id":"sanguine_exsanguinate","faction_id":"sanguine_court","name":"Exsanguinate","kind":"curse","value":4,"description":"Deal 4 damage to a wounded fighter.","effect":"damage_if_wounded","target":"enemy_fighter"},
	{"id":"sanguine_red_feast","faction_id":"sanguine_court","name":"Red Feast","kind":"heal","value":5,"description":"Restore 5 health to your player.","effect":"heal","target":"ally_player"},
	{"id":"sanguine_pain_tutor","faction_id":"sanguine_court","name":"Pain Is the Tutor","kind":"training","value":2,"description":"Grant +2 attack for each 3 damage already suffered, up to +6.","effect":"attack_from_existing_damage","target":"ally_fighter"},
	{"id":"sanguine_deathless","faction_id":"sanguine_court","name":"Deathless Oath","kind":"blessing","value":1,"description":"The next lethal hit leaves this fighter at 1 health.","effect":"survive_lethal_once","target":"ally_fighter"},
	{"id":"sanguine_blood_tithe","faction_id":"sanguine_court","name":"Blood Tithe","kind":"faction","value":3,"description":"Deal 3 damage to both players, then draw a card.","effect":"damage_players_and_draw","target":"any_player"},
	{"id":"sanguine_night_of_knives","faction_id":"sanguine_court","name":"Night of a Thousand Knives","kind":"faction","value":1,"description":"All allied fighters gain +1 attack for each enemy fighter this round.","effect":"team_attack_per_enemy","target":"all_allies"},

	# Tidebound Conclave — healing, protection, and retaliation.
	{"id":"tidebound_coral_guardian","faction_id":"tidebound_conclave","name":"Coral Guardian","kind":"summon","value":4,"description":"Summon a protective 2/6 guardian.","effect":"summon_fighter","target":"self","attack":2,"defense":6},
	{"id":"tidebound_abyssal_leviathan","faction_id":"tidebound_conclave","name":"Abyssal Leviathan","kind":"summon","value":7,"description":"Summon a colossal 5/9 leviathan.","effect":"summon_fighter","target":"self","attack":5,"defense":9},
	{"id":"tidebound_barbed_trident","faction_id":"tidebound_conclave","name":"Barbed Trident","kind":"weapon","value":3,"description":"Grant +3 attack and return 1 damage when struck.","effect":"add_attack_and_thorns","target":"ally_fighter"},
	{"id":"tidebound_reef_carapace","faction_id":"tidebound_conclave","name":"Reef Carapace","kind":"shield","value":7,"description":"Grant a fighter +7 defense.","effect":"add_defense","target":"ally_fighter"},
	{"id":"tidebound_riptide","faction_id":"tidebound_conclave","name":"Riptide","kind":"curse","value":2,"description":"Deal 2 damage and remove one weapon from a fighter.","effect":"damage_and_remove_weapon","target":"enemy_fighter"},
	{"id":"tidebound_restorative_rain","faction_id":"tidebound_conclave","name":"Restorative Rain","kind":"heal","value":4,"description":"Restore 4 health to all allied fighters.","effect":"heal_all_allied_fighters","target":"all_allies"},
	{"id":"tidebound_deep_patience","faction_id":"tidebound_conclave","name":"Patience of the Deep","kind":"training","value":3,"description":"Grant +3 defense; gain +2 attack after surviving a defensive scuffle.","effect":"add_defense_counterattack_training","target":"ally_fighter"},
	{"id":"tidebound_pearl_aegis","faction_id":"tidebound_conclave","name":"Pearl Aegis","kind":"blessing","value":3,"description":"Prevent the next 3 damage to this fighter.","effect":"prevent_next_damage","target":"ally_fighter"},
	{"id":"tidebound_high_tide","faction_id":"tidebound_conclave","name":"Call the High Tide","kind":"faction","value":5,"description":"Heal your player and every allied fighter for 5.","effect":"heal_all_allies_and_player","target":"all_allies"},
	{"id":"tidebound_undertow","faction_id":"tidebound_conclave","name":"Undertow Reversal","kind":"faction","value":4,"description":"The next time your player takes damage, return up to 4 to the source.","effect":"reflect_next_player_damage","target":"self"},

	# Tempest Clans — chained card plays, speed, and lightning pressure.
	{"id":"tempest_thunder_roc","faction_id":"tempest_clans","name":"Thunder Roc","kind":"summon","value":5,"description":"Summon a swift 5/3 lightning beast.","effect":"summon_fighter","target":"self","attack":5,"defense":3},
	{"id":"tempest_cloudstrider","faction_id":"tempest_clans","name":"Cloudstrider Raider","kind":"summon","value":4,"description":"Summon a 3/4 raider and count this as two cards for Gathering Storm.","effect":"summon_double_chain_count","target":"self","attack":3,"defense":4},
	{"id":"tempest_fulgar_blade","faction_id":"tempest_clans","name":"Fulgur Blade","kind":"weapon","value":3,"description":"Grant +3 attack; deal 1 damage to a random enemy fighter.","effect":"add_attack_and_random_damage","target":"ally_fighter"},
	{"id":"tempest_kite_shield","faction_id":"tempest_clans","name":"Skyglass Kite Shield","kind":"shield","value":4,"description":"Grant +4 defense; draw a card when the shield is depleted.","effect":"add_defense_with_break_draw","target":"ally_fighter"},
	{"id":"tempest_chain_lightning","faction_id":"tempest_clans","name":"Chain Lightning","kind":"curse","value":2,"description":"Deal 2 damage to a fighter and 1 to another enemy.","effect":"damage_and_chain","target":"enemy_fighter"},
	{"id":"tempest_second_wind","faction_id":"tempest_clans","name":"Second Wind","kind":"heal","value":5,"description":"Restore 5 health; if this is your third card, restore 8 instead.","effect":"heal_with_chain_bonus","target":"ally_fighter"},
	{"id":"tempest_eye_training","faction_id":"tempest_clans","name":"Eye of the Storm Training","kind":"training","value":2,"description":"Grant +2 attack and curse immunity until the next combat.","effect":"attack_and_temporary_evasive","target":"ally_fighter"},
	{"id":"tempest_tailwind","faction_id":"tempest_clans","name":"Tailwind","kind":"blessing","value":1,"description":"The next card you play has +1 value.","effect":"boost_next_card","target":"self"},
	{"id":"tempest_stormfront","faction_id":"tempest_clans","name":"Rolling Stormfront","kind":"faction","value":1,"description":"Deal 1 damage to all enemies for each card played before this one this round, up to 4.","effect":"enemy_area_damage_from_chain","target":"all_enemies"},
	{"id":"tempest_ride_lightning","faction_id":"tempest_clans","name":"Ride the Lightning","kind":"faction","value":2,"description":"Your fighters gain +2 attack this round; draw a card.","effect":"team_temporary_attack_and_draw","target":"all_allies"},
]


static func all_factions() -> Array:
	return FACTIONS.duplicate(true)


static func faction_by_id(faction_id: String) -> Dictionary:
	for faction in FACTIONS:
		if faction["id"] == faction_id:
			return faction.duplicate(true)
	return {}


static func cards_for_faction(faction_id: String) -> Array:
	var result: Array = []
	for card in CARDS:
		if card["faction_id"] == faction_id:
			result.append(card.duplicate(true))
	return result


static func all_cards() -> Array:
	return CARDS.duplicate(true)


static func triangle_relation(attacker_faction_id: String, defender_faction_id: String) -> int:
	## Returns 1 for advantage, -1 for disadvantage, or 0 for an even matchup.
	var attacker := faction_by_id(attacker_faction_id)
	var defender := faction_by_id(defender_faction_id)
	if attacker.is_empty() or defender.is_empty() or attacker["lean"] == defender["lean"]:
		return 0
	if TRIANGLE[attacker["lean"]]["beats"] == defender["lean"]:
		return 1
	return -1


static func validate_content() -> Array[String]:
	var errors: Array[String] = []
	var faction_ids := {}
	for faction in FACTIONS:
		var faction_id := String(faction.get("id", ""))
		if faction_id.is_empty() or faction_ids.has(faction_id):
			errors.append("Invalid or duplicate faction id: %s" % faction_id)
		faction_ids[faction_id] = true
		var lean := String(faction.get("lean", ""))
		if not TRIANGLE.has(lean):
			errors.append("Faction %s has invalid triangle lean: %s" % [faction_id, lean])
		if not faction.has("passive") or not faction["passive"].has("effect"):
			errors.append("Faction %s is missing a passive effect" % faction_id)
	if FACTIONS.size() != 6:
		errors.append("Expected exactly 6 factions, found %d" % FACTIONS.size())

	var card_ids := {}
	var card_names := {}
	var counts := {}
	for faction_id in faction_ids:
		counts[faction_id] = 0
	for card in CARDS:
		var card_id := String(card.get("id", ""))
		var card_name := String(card.get("name", ""))
		var faction_id := String(card.get("faction_id", ""))
		if card_id.is_empty() or card_ids.has(card_id):
			errors.append("Invalid or duplicate card id: %s" % card_id)
		if card_name.is_empty() or card_names.has(card_name):
			errors.append("Invalid or duplicate card name: %s" % card_name)
		card_ids[card_id] = true
		card_names[card_name] = true
		if not faction_ids.has(faction_id):
			errors.append("Card %s has unknown faction: %s" % [card_id, faction_id])
		else:
			counts[faction_id] += 1
		if not VALID_KINDS.has(card.get("kind", "")):
			errors.append("Card %s has invalid kind" % card_id)
		if not VALID_TARGETS.has(card.get("target", "")):
			errors.append("Card %s has invalid target" % card_id)
		for required_key in ["value", "description", "effect"]:
			if not card.has(required_key):
				errors.append("Card %s is missing %s" % [card_id, required_key])
	for faction_id in counts:
		if counts[faction_id] != 10:
			errors.append("Faction %s must have exactly 10 cards, found %d" % [faction_id, counts[faction_id]])
	if CARDS.size() != 60:
		errors.append("Expected exactly 60 faction cards, found %d" % CARDS.size())
	return errors
