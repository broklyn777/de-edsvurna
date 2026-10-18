class_name RunState
extends RefCounted
## En körning genom kryptan: vald Ed, sällskap, våning och troféer. Ren logik utan noder.
##
## Varje vunnen strid ger ett val av en trofé bland monstren man just slog. Troféer kan flyttas
## fritt mellan hjältarna mellan striderna (en per hjälte).

const FLOORS := ["crypt_1", "crypt_2", "crypt_3"]
const PARTY_SIZE := 4
const OFFER_SIZE := 3

var oath := "oath_vengeance"
## Köpta perks i Eden (Edsaltaret). De bärs av Paladinen och verkar som Eden.
var perks: Array = []
## Paladinen först, sedan följeslagarna.
var party: Array[String] = ["paladin", "brokk", "alva", "eira"]
var floor := 0
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
	s.perks = profile.owned_perks(profile.oath).duplicate()
	s.party = profile.party.duplicate()
	s.artifacts = profile.artifacts.duplicate(true)
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


func encounter() -> String:
	return practice_encounter if practice else FLOORS[floor]


func is_last_floor() -> bool:
	return practice or floor >= FLOORS.size() - 1


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


## Troféerna som erbjuds efter att våningen är vunnen: först från monstren i striden, sedan
## fylls det på med andra som inte redan är tagna.
func trophy_offer(data: Dictionary, rng: RandomNumberGenerator) -> Array[String]:
	var offer: Array[String] = []
	for kind in data.encounters[encounter()].enemies:
		var t: String = data.enemies[kind].get("trophy", "")
		if t != "" and not offer.has(t) and not trophies.has(t):
			offer.append(t)
	var rest: Array[String] = []
	for kind in data.enemies:
		var t: String = data.enemies[kind].get("trophy", "")
		if t != "" and not offer.has(t) and not trophies.has(t) and not data.enemies[kind].get("boss", false):
			rest.append(t)
	while offer.size() < OFFER_SIZE and not rest.is_empty():
		offer.append(rest.pop_at(rng.randi() % rest.size()))
	return offer.slice(0, OFFER_SIZE)


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
