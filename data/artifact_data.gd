class_name ArtifactData
extends RefCounted

## Run-persistent relics dropped after victories. Effects intentionally use a
## compact vocabulary so gameplay can validate that every artifact is active.

const ARTIFACTS := [
	{"id":"warlords_tooth","name":"Warlord's Tooth","description":"All allied fighters have +1 attack.","effect":"team_attack","value":1},
	{"id":"iron_idol","name":"Iron Idol","description":"All allied fighters have +2 defense.","effect":"team_defense","value":2},
	{"id":"guardian_coin","name":"Guardian Coin","description":"Reduce every hit to your player by 1, to a minimum of 0.","effect":"player_damage_reduction","value":1},
	{"id":"blood_cup","name":"Blood Cup","description":"Whenever an enemy fighter is destroyed, heal your player for 1.","effect":"enemy_death_heal","value":1},
	{"id":"forge_bell","name":"Forge Bell","description":"Weapon cards grant +1 additional attack.","effect":"weapon_bonus","value":1},
	{"id":"coral_charm","name":"Coral Charm","description":"Heal cards and faction healing restore 1 additional health.","effect":"heal_bonus","value":1},
	{"id":"static_battery","name":"Static Battery","description":"Every fifth card you play deals 2 damage to the enemy player.","effect":"card_milestone_damage","value":2,"interval":5},
	{"id":"lucky_knuckle","name":"Lucky Knuckle","description":"The first fighter you train each battle gains +2 attack and +2 defense.","effect":"first_fighter_boost","value":2},
	{"id":"grave_lantern","name":"Grave Lantern","description":"The first allied fighter destroyed each battle draws a card.","effect":"first_ally_death_draw","value":1},
	{"id":"mirror_shard","name":"Mirror Shard","description":"The first curse aimed at your stable each round is prevented.","effect":"first_curse_prevent","value":1},
	{"id":"phoenix_feather","name":"Phoenix Feather","description":"Once per battle, lethal player damage leaves you at 5 health.","effect":"player_rebirth","value":5},
	{"id":"thorn_ring","name":"Thorn Ring","description":"All allied defenders return 1 damage when struck in a scuffle.","effect":"blocker_thorns","value":1},
	{"id":"war_drum","name":"War Drum","description":"Your first attacking fighter each round deals +2 combat damage.","effect":"first_attack_bonus","value":2},
	{"id":"bottomless_flask","name":"Bottomless Flask","description":"At the end of your turn, heal 2 if your player is at half health or less.","effect":"low_health_turn_heal","value":2},
	{"id":"scholars_lens","name":"Scholar's Lens","description":"Draw 1 additional card in your opening hand.","effect":"opening_hand_bonus","value":1},
	{"id":"rusty_crown","name":"Rusty Crown","description":"Enemy fighters enter with 1 less attack, to a minimum of 1.","effect":"enemy_fighter_attack_penalty","value":1},
	{"id":"ogre_belt","name":"Ogre Belt","description":"The first fighter you train each turn gains +2 attack.","effect":"first_turn_fighter_attack","value":2},
	{"id":"stone_anklet","name":"Stone Anklet","description":"Your defending fighters have +2 defense during a scuffle.","effect":"blocker_defense","value":2},
	{"id":"soul_magnet","name":"Soul Magnet","description":"Start every encounter with 5 bonus player health.","effect":"starting_health_bonus","value":5},
	{"id":"chaos_die","name":"Chaos Die","description":"Every third fighter you train gains +1 attack and +1 defense.","effect":"third_fighter_boost","value":1,"interval":3},
]


static func all_artifacts() -> Array:
	return ARTIFACTS.duplicate(true)


static func artifact_by_id(artifact_id: String) -> Dictionary:
	for artifact in ARTIFACTS:
		if artifact["id"] == artifact_id:
			return artifact.duplicate(true)
	return {}


static func validate_content() -> Array[String]:
	var errors: Array[String] = []
	var ids := {}
	var effects := {}
	for artifact in ARTIFACTS:
		for key in ["id", "name", "description", "effect", "value"]:
			if not artifact.has(key):
				errors.append("Artifact is missing %s: %s" % [key, str(artifact)])
		var artifact_id := String(artifact.get("id", ""))
		if artifact_id.is_empty() or ids.has(artifact_id):
			errors.append("Invalid or duplicate artifact id: %s" % artifact_id)
		ids[artifact_id] = true
		effects[String(artifact.get("effect", ""))] = true
	if ARTIFACTS.size() != 20:
		errors.append("Expected exactly 20 artifacts, found %d" % ARTIFACTS.size())
	if effects.size() != ARTIFACTS.size():
		errors.append("Every artifact must have a unique effect; found %d effects" % effects.size())
	return errors
