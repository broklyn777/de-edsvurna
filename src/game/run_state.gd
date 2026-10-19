class_name RunState
extends RefCounted
## En körning genom kryptan: vald Ed, sällskap, våning och troféer. Ren logik utan noder.
##
## Varje vunnen strid ger ett val av en trofé bland monstren man just slog. Troféer kan flyttas
## fritt mellan hjältarna mellan striderna (en per hjälte).

## Kryptans våningar (standard). Varje Realm har sina i data/realms.json.
const FLOORS := ["crypt_1", "crypt_2", "crypt_3"]
const PARTY_SIZE := 4
const OFFER_SIZE := 3
## Troféchans (Realm Depth ger bättre byte): första trofén efter en seger är säker, varje ytterligare
## plats i erbjudandet kommer med den här chansen, +15 procentenheter per djup över 1.
const TROPHY_CHANCE := 0.4
const TROPHY_CHANCE_PER_DEPTH := 0.15
## Instabilitet (Siralims Realm Instability) 0–3: nivå n ger n synliga och n dolda våningsregler,
## mer silver (reglernas "silver") och bättre troféchans.
const MAX_INSTABILITY := 3
const TROPHY_CHANCE_PER_INSTABILITY := 0.1
## Bosstroféer kräver så många segrar mot samma boss (Siralims Masters).
const BOSS_WINS_FOR_TROPHY := 3

var oath := "oath_vengeance"
## Köpta perks i Eden (Edsaltaret). De bärs av Paladinen och verkar som Eden.
var perks: Array = []
## Paladinen först, sedan följeslagarna.
var party: Array[String] = ["paladin", "brokk", "alva", "eira"]
var floor := 0
## Realm (Siralim): "crypt" eller "chapel" (data/realms.json) och dess våningar.
var realm := "crypt"
var floor_ids: Array = FLOORS
## Instabilitet och våningsreglerna för körningen (data/floor_rules.json). Dolda regler syns först
## när de slår till; då hamnar de i rules_revealed.
var instability := 0
var rules_visible: Array = []
var rules_hidden: Array = []
var rules_revealed: Array = []
## Fiendetyper som var elitvarianter i senaste vunna striden (ger sin elittrofé).
var last_elites: Array = []
## Realm Depth som fienderna skalar med (Profile.depth).
var depth := 1
## Troféer som hittats under körningen.
var trophies: Array[String] = []
## hero_id -> trophy_id
var equipped := {}
## hero_id -> {ability_id: Charges kvar}. Fylls vid ny körning och räcker hela körningen
## (som Siralims Charges, som fylls först vid nästa Realm).
var charges := {}
## hero_id -> {type, ability}: artefakterna från Smeden (Profile.artifacts).
var artifacts := {}
## Övningsgården (Siralims Arena): en enda strid utan risk mot valfritt möte.
var practice := false
var practice_encounter := ""


## En ny körning från basen: Eden och sällskapet från Kryptporten, artefakterna från Smeden.
static func new_run(profile: Profile, data: Dictionary) -> RunState:
	var s := RunState.new()
	s.oath = profile.oath
	s.perks = profile.active_perks(data, profile.oath)
	s.party = profile.party.duplicate()
	s.artifacts = profile.artifacts.duplicate(true)
	s.depth = profile.depth
	s.set_realm(data, profile.realm)
	s.fill_charges(data)
	return s


## En strid i Övningsgården: samma sällskap, makron och artefakter, troféer ur samlingen och fulla
## Charges. Inget förloras och inget vinns.
static func new_practice(profile: Profile, data: Dictionary, encounter_id: String) -> RunState:
	var s := new_run(profile, data)
	s.practice = true
	s.practice_encounter = encounter_id
	for hero_id in profile.practice_equipped:
		var trophy_id: String = profile.practice_equipped[hero_id]
		if s.party.has(hero_id) and profile.collection.has(trophy_id):
			s.take_trophy(trophy_id)
			s.equip(hero_id, trophy_id)
	return s


func fill_charges(data: Dictionary) -> void:
	charges.clear()
	for hero_id in party:
		var c := {}
		for ability_id in data.heroes[hero_id].get("abilities", []):
			c[ability_id] = int(data.abilities[ability_id].get("charges", 0))
		charges[hero_id] = c


## Sparar hur många Charges hjältarna har kvar efter en strid.
func store_charges(sim: CombatSim) -> void:
	for h in sim.heroes:
		charges[h.id] = h.charges.duplicate()


func set_realm(data: Dictionary, realm_id: String) -> void:
	if data.get("realms", {}).has(realm_id):
		realm = realm_id
		floor_ids = data.realms[realm_id].floors


func encounter() -> String:
	return practice_encounter if practice else floor_ids[floor]


func is_last_floor() -> bool:
	return practice or floor >= floor_ids.size() - 1


## Egenskaper per hjälte för striden: Paladinens Ed och perks ersätter hens förvalda, och troféer
## läggs till.
func hero_traits(data: Dictionary) -> Dictionary:
	var out := {}
	for hero_id in party:
		var list: Array = ([oath] + perks) if hero_id == "paladin" else data.heroes[hero_id].get("traits", []).duplicate()
		if equipped.has(hero_id):
			list.append(equipped[hero_id])
		out[hero_id] = list
	return out


## Chansen för varje trofé utöver den första i erbjudandet (högst 100 %).
static func trophy_chance(at_depth: int, at_instability := 0) -> float:
	return minf(1.0, TROPHY_CHANCE + TROPHY_CHANCE_PER_DEPTH * (maxi(at_depth, 1) - 1)
			+ TROPHY_CHANCE_PER_INSTABILITY * at_instability)


## Slumpar våningsregler för instabiliteten: n synliga och n dolda, utan upprepning. Regler med
## "min_instability" kräver minst den nivån, och "hidden_only" kan bara bli dolda.
static func roll_rules(data: Dictionary, level: int, rng: RandomNumberGenerator) -> Dictionary:
	var pool: Array = data.floor_rules.keys().filter(func(id: String) -> bool:
		return int(data.floor_rules[id].get("min_instability", 0)) <= level)
	var visible := []
	var hidden := []
	for i in level:
		var open := pool.filter(func(id: String) -> bool: return not data.floor_rules[id].get("hidden_only", false))
		if not open.is_empty():
			var id: String = open[rng.randi() % open.size()]
			visible.append(id)
			pool.erase(id)
		if not pool.is_empty():
			var id: String = pool[rng.randi() % pool.size()]
			hidden.append(id)
			pool.erase(id)
	return {"visible": visible, "hidden": hidden}


## Alla regler som gäller i körningen (synliga och dolda).
func active_rules() -> Array:
	return rules_visible + rules_hidden


## Regler spelaren känner till: de synliga och de dolda som har avslöjats.
func known_rules() -> Array:
	return rules_visible + rules_hidden.filter(func(id: String) -> bool: return rules_revealed.has(id))


## Silver gånger 1 + reglernas tillägg.
func silver_mult(data: Dictionary) -> float:
	var m := 1.0
	for id in active_rules():
		m += float(data.floor_rules[id].get("silver", 0.0))
	return m


## Troféerna som erbjuds efter att våningen är vunnen: elittroféer från besegrade elitvarianter
## (alltid), sedan från monstren i striden och påfyllnad ur samma Realm. Bosstroféer bara om bossen
## är besegrad BOSS_WINS_FOR_TROPHY gånger (unlocked_bosses). Elittroféerna och den första vanliga är
## säkra, resten kommer med trophy_chance(depth, instabilitet).
func trophy_offer(data: Dictionary, rng: RandomNumberGenerator, elites: Array = [],
		unlocked_bosses: Array = []) -> Array[String]:
	var sure: Array[String] = []
	for kind in elites:
		var t: String = data.enemies[kind].get("elite", {}).get("trophy", "")
		if t != "" and not sure.has(t) and not trophies.has(t):
			sure.append(t)
	var offer: Array[String] = []
	for kind in data.encounters[encounter()].enemies:
		if data.enemies[kind].get("boss", false) and not unlocked_bosses.has(kind):
			continue
		var t: String = data.enemies[kind].get("trophy", "")
		if t != "" and not offer.has(t) and not trophies.has(t):
			offer.append(t)
	var rest: Array[String] = []
	var realm_kinds := []
	for enc_id in floor_ids:
		realm_kinds.append_array(data.encounters[enc_id].enemies)
	for kind in data.enemies:
		if not realm_kinds.has(kind):
			continue  # påfyllnaden kommer från samma Realm
		var t: String = data.enemies[kind].get("trophy", "")
		if t != "" and not offer.has(t) and not trophies.has(t) and not data.enemies[kind].get("boss", false):
			rest.append(t)
	while offer.size() < OFFER_SIZE and not rest.is_empty():
		offer.append(rest.pop_at(rng.randi() % rest.size()))
	var out: Array[String] = sure.duplicate()
	var chance := trophy_chance(depth, instability)
	var first := true
	for t in offer.slice(0, OFFER_SIZE):
		if first or rng.randf() < chance:
			out.append(t)
		first = false
	return out


func take_trophy(trophy_id: String) -> void:
	if not trophies.has(trophy_id):
		trophies.append(trophy_id)


## Sätter trofén på hjälten (tar bort den från den som bar den förut). Tom sträng tar av.
func equip(hero_id: String, trophy_id: String) -> void:
	for other in equipped.keys():
		if equipped[other] == trophy_id:
			equipped.erase(other)
	if trophy_id == "":
		equipped.erase(hero_id)
	else:
		equipped[hero_id] = trophy_id


func wearer(trophy_id: String) -> String:
	for hero_id in equipped:
		if equipped[hero_id] == trophy_id:
			return hero_id
	return ""
