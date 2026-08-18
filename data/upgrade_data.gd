class_name UpgradeData
extends RefCounted

const UPGRADE_KILL_COST := 5

## Persistent victory upgrades. Each faction has one five-node tree: tier 1 is
## always available, tiers 2-4 branch, and tier 5 is the dramatic capstone.

const UPGRADES := [
	{"id":"cinder_living_crucible","faction_id":"cinder_coven","name":"Living Crucible","tier":1,"cost":1,"requires":[],"description":"Start each run with a random Cinder summon in hand.","effect":"starting_faction_summon","target":"deck","value":1},
	{"id":"cinder_hotter_blood","faction_id":"cinder_coven","name":"Hotter Blood","tier":2,"cost":2,"requires":["cinder_living_crucible"],"description":"All summoned golems enter with +1 attack.","effect":"summons_gain_attack","target":"cards","value":1},
	{"id":"cinder_granite_memory","faction_id":"cinder_coven","name":"Granite Memory","tier":2,"cost":2,"requires":["cinder_living_crucible"],"description":"All summoned golems enter with +2 defense.","effect":"summons_gain_defense","target":"cards","value":2},
	{"id":"cinder_chain_reaction","faction_id":"cinder_coven","name":"Chain Reaction","tier":3,"cost":3,"requires":["cinder_hotter_blood"],"description":"Your first golem destroyed each round deals 3 damage to the enemy player.","effect":"first_summon_death_player_damage","target":"player","value":3},
	{"id":"cinder_worldforge","faction_id":"cinder_coven","name":"Worldforge Unbound","tier":5,"cost":5,"requires":["cinder_chain_reaction","cinder_granite_memory"],"description":"Once per battle, replace your stable with three random upgraded golems.","effect":"unlock_worldforge","target":"battle","value":3},

	{"id":"ironroot_spare_parts","faction_id":"ironroot_compact","name":"Bottomless Spare Parts","tier":1,"cost":1,"requires":[],"description":"Field Repairs heals 1 additional damage.","effect":"passive_value_bonus","target":"faction_passive","value":1},
	{"id":"ironroot_tungsten_teeth","faction_id":"ironroot_compact","name":"Tungsten Teeth","tier":2,"cost":2,"requires":["ironroot_spare_parts"],"description":"Weapon cards grant +1 additional attack.","effect":"kind_value_bonus","target":"weapon","value":1},
	{"id":"ironroot_mobile_fortress","faction_id":"ironroot_compact","name":"Mobile Fortress","tier":2,"cost":2,"requires":["ironroot_spare_parts"],"description":"Shield cards grant +2 additional defense.","effect":"kind_value_bonus","target":"shield","value":2},
	{"id":"ironroot_redundant_core","faction_id":"ironroot_compact","name":"Redundant Core","tier":3,"cost":3,"requires":["ironroot_mobile_fortress"],"description":"The first allied automaton destroyed each battle returns as a 2/4 Scrapling.","effect":"first_summon_death_reborn","target":"battle","attack":2,"defense":4},
	{"id":"ironroot_eternal_engine","faction_id":"ironroot_compact","name":"The Eternal Engine","tier":5,"cost":5,"requires":["ironroot_tungsten_teeth","ironroot_redundant_core"],"description":"At round end, permanently grant every allied fighter +1 defense.","effect":"round_end_team_defense","target":"all_allies","value":1},

	{"id":"velari_deeper_scan","faction_id":"velari_collective","name":"Deeper Scan","tier":1,"cost":1,"requires":[],"description":"Your opening hand offers one extra card, then discard one.","effect":"opening_hand_selection_bonus","target":"deck","value":1},
	{"id":"velari_parallel_minds","faction_id":"velari_collective","name":"Parallel Minds","tier":2,"cost":2,"requires":["velari_deeper_scan"],"description":"Predictive Lattice may hold two primed stat bonuses.","effect":"passive_stack_limit","target":"faction_passive","value":2},
	{"id":"velari_stolen_pattern","faction_id":"velari_collective","name":"Stolen Pattern","tier":2,"cost":2,"requires":["velari_deeper_scan"],"description":"After the enemy plays its third card, create a temporary copy in your hand.","effect":"copy_enemy_third_card","target":"hand","value":1},
	{"id":"velari_recursive_code","faction_id":"velari_collective","name":"Recursive Code","tier":3,"cost":3,"requires":["velari_parallel_minds"],"description":"The first faction card played each battle returns to your deck.","effect":"recycle_first_faction_card","target":"deck","value":1},
	{"id":"velari_singularity","faction_id":"velari_collective","name":"Arena Singularity","tier":5,"cost":5,"requires":["velari_recursive_code","velari_stolen_pattern"],"description":"Once per battle, replay the effects of your last three cards in order.","effect":"unlock_replay_last_cards","target":"battle","value":3},

	{"id":"sanguine_rich_vintage","faction_id":"sanguine_court","name":"A Rich Vintage","tier":1,"cost":1,"requires":[],"description":"Taste of Victory heals 1 additional health.","effect":"passive_value_bonus","target":"faction_passive","value":1},
	{"id":"sanguine_sharpened_fangs","faction_id":"sanguine_court","name":"Sharpened Fangs","tier":2,"cost":2,"requires":["sanguine_rich_vintage"],"description":"Fighters gain +1 attack after they heal your player.","effect":"lifesteal_grants_attack","target":"fighters","value":1},
	{"id":"sanguine_open_veins","faction_id":"sanguine_court","name":"Open the Veins","tier":2,"cost":2,"requires":["sanguine_rich_vintage"],"description":"Begin battles at 5 less health and draw two extra cards.","effect":"trade_starting_health_for_cards","target":"player","value":2,"health_cost":5},
	{"id":"sanguine_inheritance","faction_id":"sanguine_court","name":"Crimson Inheritance","tier":3,"cost":3,"requires":["sanguine_sharpened_fangs"],"description":"When an ally dies, transfer half its attack to your weakest fighter.","effect":"transfer_attack_on_death","target":"fighters","value":50},
	{"id":"sanguine_eternal_night","faction_id":"sanguine_court","name":"Eternal Night","tier":5,"cost":5,"requires":["sanguine_inheritance","sanguine_open_veins"],"description":"Once per battle at lethal damage, set player health to 15 and empower all allies +3/+3.","effect":"unlock_player_rebirth","target":"battle","value":15,"attack":3,"defense":3},

	{"id":"tidebound_sweetwater","faction_id":"tidebound_conclave","name":"Sweetwater Springs","tier":1,"cost":1,"requires":[],"description":"Begin each battle with a Small Heal in hand.","effect":"starting_heal_card","target":"deck","value":1},
	{"id":"tidebound_regrowth","faction_id":"tidebound_conclave","name":"Rapid Regrowth","tier":2,"cost":2,"requires":["tidebound_sweetwater"],"description":"Excess fighter healing becomes temporary defense.","effect":"overheal_to_defense","target":"fighters","value":100},
	{"id":"tidebound_salt_armor","faction_id":"tidebound_conclave","name":"Salt-Hardened Armor","tier":2,"cost":2,"requires":["tidebound_sweetwater"],"description":"All fighters enter with +1 defense.","effect":"fighters_start_defense","target":"fighters","value":1},
	{"id":"tidebound_shared_current","faction_id":"tidebound_conclave","name":"Shared Current","tier":3,"cost":3,"requires":["tidebound_regrowth"],"description":"Healing one fighter also heals the most damaged other ally for half.","effect":"heal_chains_to_ally","target":"fighters","value":50},
	{"id":"tidebound_ocean_incarnate","faction_id":"tidebound_conclave","name":"Ocean Incarnate","tier":5,"cost":5,"requires":["tidebound_shared_current","tidebound_salt_armor"],"description":"Once per battle, fully heal your stable and double its defense for the round.","effect":"unlock_full_heal_double_defense","target":"battle","value":100},

	{"id":"tempest_static_charge","faction_id":"tempest_clans","name":"Static Charge","tier":1,"cost":1,"requires":[],"description":"Your first card each round counts twice for Gathering Storm.","effect":"first_card_double_chain_count","target":"faction_passive","value":1},
	{"id":"tempest_forked_bolt","faction_id":"tempest_clans","name":"Forked Bolt","tier":2,"cost":2,"requires":["tempest_static_charge"],"description":"Gathering Storm also deals 1 damage to a random enemy fighter.","effect":"passive_random_fighter_damage","target":"all_enemies","value":1},
	{"id":"tempest_jetstream","faction_id":"tempest_clans","name":"Ride the Jetstream","tier":2,"cost":2,"requires":["tempest_static_charge"],"description":"Every sixth card played in a battle draws a card.","effect":"chain_milestone_draw","target":"deck","value":6},
	{"id":"tempest_supercell","faction_id":"tempest_clans","name":"Supercell","tier":3,"cost":3,"requires":["tempest_forked_bolt"],"description":"After Gathering Storm triggers, your next card has +2 value.","effect":"passive_trigger_boost_next_card","target":"cards","value":2},
	{"id":"tempest_storm_crowned","faction_id":"tempest_clans","name":"Storm-Crowned Ascension","tier":5,"cost":5,"requires":["tempest_supercell","tempest_jetstream"],"description":"Once per battle, play four generated lightning cards without spending cards from hand.","effect":"unlock_lightning_combo","target":"battle","value":4},
]


static func all_upgrades() -> Array:
	var result := UPGRADES.duplicate(true)
	for upgrade in result:
		upgrade["cost"] = UPGRADE_KILL_COST
	return result


static func upgrades_for_faction(faction_id: String) -> Array:
	var result: Array = []
	for upgrade in UPGRADES:
		if upgrade["faction_id"] == faction_id:
			var normalized: Dictionary = upgrade.duplicate(true)
			normalized["cost"] = UPGRADE_KILL_COST
			result.append(normalized)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["tier"]) < int(b["tier"]))
	return result


static func upgrade_by_id(upgrade_id: String) -> Dictionary:
	for upgrade in UPGRADES:
		if upgrade["id"] == upgrade_id:
			var normalized: Dictionary = upgrade.duplicate(true)
			normalized["cost"] = UPGRADE_KILL_COST
			return normalized
	return {}


static func available_upgrades(faction_id: String, owned_upgrade_ids: Array) -> Array:
	var owned := {}
	for upgrade_id in owned_upgrade_ids:
		owned[String(upgrade_id)] = true
	var result: Array = []
	for upgrade in UPGRADES:
		if upgrade["faction_id"] != faction_id or owned.has(upgrade["id"]):
			continue
		var unlocked := true
		for requirement in upgrade["requires"]:
			if not owned.has(requirement):
				unlocked = false
				break
		if unlocked:
			var normalized: Dictionary = upgrade.duplicate(true)
			normalized["cost"] = UPGRADE_KILL_COST
			result.append(normalized)
	return result


static func validate_content(valid_faction_ids: Array = []) -> Array[String]:
	var errors: Array[String] = []
	var ids := {}
	var faction_counts := {}
	for upgrade in UPGRADES:
		var upgrade_id := String(upgrade.get("id", ""))
		var faction_id := String(upgrade.get("faction_id", ""))
		if upgrade_id.is_empty() or ids.has(upgrade_id):
			errors.append("Invalid or duplicate upgrade id: %s" % upgrade_id)
		ids[upgrade_id] = true
		faction_counts[faction_id] = int(faction_counts.get(faction_id, 0)) + 1
		if not valid_faction_ids.is_empty() and not valid_faction_ids.has(faction_id):
			errors.append("Upgrade %s has unknown faction: %s" % [upgrade_id, faction_id])
		for key in ["name", "tier", "cost", "requires", "description", "effect", "target"]:
			if not upgrade.has(key):
				errors.append("Upgrade %s is missing %s" % [upgrade_id, key])
	for upgrade in UPGRADES:
		for requirement in upgrade.get("requires", []):
			if not ids.has(requirement):
				errors.append("Upgrade %s requires unknown upgrade %s" % [upgrade["id"], requirement])
			elif upgrade_by_id(requirement)["faction_id"] != upgrade["faction_id"]:
				errors.append("Upgrade %s has a cross-faction requirement" % upgrade["id"])
	for faction_id in faction_counts:
		if faction_counts[faction_id] != 5:
			errors.append("Faction %s must have exactly 5 upgrades, found %d" % [faction_id, faction_counts[faction_id]])
	return errors
