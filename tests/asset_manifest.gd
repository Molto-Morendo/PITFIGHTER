extends SceneTree

const FactionData := preload("res://data/faction_data.gd")
const ArtifactData := preload("res://data/artifact_data.gd")

const GENERIC_CARDS := [
	{"id":"stat_1", "name":"Stat One", "description":"A raw training spark for attack or defense."},
	{"id":"stat_2", "name":"Stat Two", "description":"Two knuckle-shaped points of fighter training."},
	{"id":"stat_3", "name":"Stat Three", "description":"Three loud points of attack or defense training."},
	{"id":"stat_4", "name":"Stat Four", "description":"Four chunky points of gladiator training."},
	{"id":"stat_5", "name":"Stat Five", "description":"Five points of dramatic fighter training."},
	{"id":"stat_6", "name":"Stat Six", "description":"Six points of overconfident pit training."},
	{"id":"stat_7", "name":"Stat Seven", "description":"Seven points of absurdly intense training."},
	{"id":"stat_8", "name":"Stat Eight", "description":"Eight points of arena-shaking training."},
	{"id":"stat_9", "name":"Stat Nine", "description":"Nine points of ridiculous gladiator power."},
	{"id":"stat_10", "name":"Stat Ten", "description":"Ten points of maximum cartoon muscle."},
	{"id":"weapon_sword", "name":"Sword", "description":"A comically broad sword adds attack."},
	{"id":"weapon_hammer", "name":"Hammer", "description":"A huge squeaky war hammer adds attack."},
	{"id":"shield_small_shield", "name":"Small Shield", "description":"A stubborn buckler adds defense."},
	{"id":"shield_large_shield", "name":"Large Shield", "description":"A door-sized shield adds defense."},
	{"id":"curse_poison", "name":"Poison", "description":"A bubbling venom flask curses a fighter."},
	{"id":"curse_madness", "name":"Madness", "description":"A spiral-eyed curse makes a fighter punch itself."},
	{"id":"curse_deathmark", "name":"Deathmark", "description":"A theatrical doom stamp destroys a fighter."},
	{"id":"curse_armageddon", "name":"Armageddon", "description":"A ridiculous arena apocalypse destroys every fighter."},
	{"id":"blessing_evasive", "name":"Evasive", "description":"A fighter slips around curses with slapstick speed."},
	{"id":"blessing_berserker", "name":"Berserker", "description":"A frothing cartoon rage blessing doubles damage."},
	{"id":"heal_small_heal", "name":"Small Heal", "description":"A tiny glowing bandage restores health."},
	{"id":"heal_large_heal", "name":"Large Heal", "description":"An enormous miracle bandage restores health."},
	{"id":"training_shield_master", "name":"Shield Master", "description":"A fighter trains by headbutting a stack of shields."},
	{"id":"training_zen_master", "name":"Zen Master", "description":"A serene but terrifying fighter ignores damage."},
	{"id":"training_explosive_master", "name":"Explosive Master", "description":"A cackling fighter trains with cartoon bombs."},
	{"id":"summon_call_in_the_squad", "name":"Call in the Squad", "description":"Three ridiculous temporary brawlers burst into the pit."},
]


func _init() -> void:
	var cards: Array = GENERIC_CARDS.duplicate(true)
	for card in FactionData.all_cards():
		cards.append({"id":card["id"], "name":card["name"], "description":card["description"], "faction_id":card["faction_id"]})
	print(JSON.stringify({"cards":cards, "artifacts":ArtifactData.all_artifacts()}))
	quit()
