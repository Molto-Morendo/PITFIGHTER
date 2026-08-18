extends SceneTree

const Factions = preload("res://data/faction_data.gd")
const Upgrades = preload("res://data/upgrade_data.gd")
const Artifacts = preload("res://data/artifact_data.gd")


func _init() -> void:
	var faction_errors := Factions.validate_content()
	var faction_ids: Array = []
	for faction in Factions.all_factions():
		faction_ids.append(faction["id"])
	var upgrade_errors := Upgrades.validate_content(faction_ids)
	var artifact_errors := Artifacts.validate_content()
	var errors: Array = faction_errors + upgrade_errors + artifact_errors
	if errors.is_empty():
		print("Content validation passed: 6 factions, 60 unique faction cards, 30 upgrades, 20 artifacts.")
		quit(0)
		return
	for error in errors:
		push_error(error)
	quit(1)
