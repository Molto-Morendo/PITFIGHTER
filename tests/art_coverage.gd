extends SceneTree

const FactionData := preload("res://data/faction_data.gd")
const ArtifactData := preload("res://data/artifact_data.gd")

const GENERIC_IDS := [
	"stat_1", "stat_2", "stat_3", "stat_4", "stat_5", "stat_6", "stat_7", "stat_8", "stat_9", "stat_10",
	"weapon_sword", "weapon_hammer", "shield_small_shield", "shield_large_shield", "curse_poison", "curse_madness",
	"curse_deathmark", "curse_armageddon", "blessing_evasive", "blessing_berserker", "heal_small_heal", "heal_large_heal",
	"training_shield_master", "training_zen_master", "training_explosive_master", "summon_call_in_the_squad",
]


func _init() -> void:
	var failures: Array[String] = []
	var card_ids: Array = GENERIC_IDS.duplicate()
	for card in FactionData.all_cards():
		card_ids.append(String(card["id"]))
	for card_id in card_ids:
		var path := "res://assets/cards/%s.png" % card_id
		if not FileAccess.file_exists(path):
			failures.append("Missing card art: %s" % path)
	for artifact in ArtifactData.all_artifacts():
		var path := "res://assets/artifacts/%s.png" % artifact["id"]
		if not FileAccess.file_exists(path):
			failures.append("Missing artifact art: %s" % path)
	if failures.is_empty():
		print("Art coverage passed: %d unique card illustrations and %d artifact illustrations." % [card_ids.size(), ArtifactData.all_artifacts().size()])
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
