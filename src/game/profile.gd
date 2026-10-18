class_name Profile
extends RefCounted
## Det som varar mellan körningarna (basen, Siralims slott): silver, samlingen av troféer,
## hjältarnas artefakter och senaste uppställning. Ren logik; sparas i en ConfigFile.
##
## Silver är den enda resursen än så länge (Siralim har fem). Det ges för vunna strider i kryptan –
## inte i Övningsgården – och behålls även om sällskapet faller, som i Siralim där man bara
## förlorar Fortune.
##
## Balans: en artefakt höjer chansen att klara hela kryptan med startmakrona från ~60 % till 75–85 %,
## alla fyra till ~96 %. Startsilvret räcker till en, sedan ungefär en per klarad körning (110 silver).

const START_SILVER := 100
## Smida en ny artefakt (eller byta typ, som smälter ned den gamla).
const FORGE_COST := 100
## Byta förmågan i en artefakt man redan har.
const RESOCKET_COST := 40
## Silver per vunnen strid, per våning.
const FLOOR_REWARD := [25, 35, 50]
## Ederna vid Edsaltaret (data/oaths.json). Äldre sparfiler kan ha en Ed som inte finns längre.
const OATHS := ["oath_vengeance", "oath_dawn", "oath_ward"]

var silver := START_SILVER
var collection: Array[String] = []
## hero_id -> {type, ability}
var artifacts := {}
## Senaste uppställningen från Kryptporten (används också i Övningsgården).
var oath := "oath_vengeance"
## Edsaltaret (Siralims Enchanted Wardrobe): köpta perks per Ed, oath_id -> [perk_id]. Alla köpta
## perks i den valda Eden verkar; kärnan verkar alltid. Att återställa är gratis (silvret kommer tillbaka).
var perks := {}
var party: Array[String] = ["paladin", "brokk", "alva", "eira"]
## Troféer ur samlingen som hjältarna bär i Övningsgården: hero_id -> trophy_id.
var practice_equipped := {}


static func reward(floor: int) -> int:
	return FLOOR_REWARD[clampi(floor, 0, FLOOR_REWARD.size() - 1)]


## Ger silver för en vunnen strid på våningen. Returnerar hur mycket.
func win_battle(floor: int) -> int:
	var amount := reward(floor)
	silver += amount
	return amount


func add_trophy(trophy_id: String) -> void:
	if not collection.has(trophy_id):
		collection.append(trophy_id)


## Vad det kostar att ge hjälten en artefakt av typen med förmågan (0 = redan så).
func forge_cost(hero_id: String, type: String, ability_id: String) -> int:
	var cur: Dictionary = artifacts.get(hero_id, {})
	if cur.is_empty() or cur.type != type:
		return FORGE_COST
	if cur.get("ability", "") != ability_id:
		return RESOCKET_COST
	return 0


## Smider eller byter. Falskt om det inte ändrar något eller silvret inte räcker.
func forge(hero_id: String, type: String, ability_id: String) -> bool:
	var cost := forge_cost(hero_id, type, ability_id)
	if cost == 0 or silver < cost:
		return false
	silver -= cost
	artifacts[hero_id] = {"type": type, "ability": ability_id}
	return true


## Väljer Ed vid Edsaltaret.
func choose_oath(oath_id: String) -> void:
	if OATHS.has(oath_id):
		oath = oath_id


func owned_perks(oath_id: String) -> Array:
	return perks.get(oath_id, [])


## Vad perken kostar (−1 om den inte hör till Eden).
static func perk_cost(data: Dictionary, oath_id: String, perk_id: String) -> int:
	for p in data.oaths.get(oath_id, {}).get("perks", []):
		if p.id == perk_id:
			return int(p.cost)
	return -1


## Köper perken. Falskt om den redan är köpt, inte hör till Eden eller silvret inte räcker.
func buy_perk(data: Dictionary, oath_id: String, perk_id: String) -> bool:
	var cost := perk_cost(data, oath_id, perk_id)
	if cost < 0 or owned_perks(oath_id).has(perk_id) or silver < cost:
		return false
	silver -= cost
	var list: Array = owned_perks(oath_id).duplicate()
	list.append(perk_id)
	perks[oath_id] = list
	return true


## Återställer Edens perks gratis, som i Siralim: allt silver kommer tillbaka. Returnerar beloppet.
func reset_perks(data: Dictionary, oath_id: String) -> int:
	var refund := 0
	for perk_id in owned_perks(oath_id):
		refund += maxi(perk_cost(data, oath_id, perk_id), 0)
	silver += refund
	perks.erase(oath_id)
	return refund


## Sätter en trofé på hjälten i Övningsgården (tar bort den från den som bar den). Tom sträng tar av.
func equip_practice(hero_id: String, trophy_id: String) -> void:
	for other in practice_equipped.keys():
		if practice_equipped[other] == trophy_id:
			practice_equipped.erase(other)
	if trophy_id == "":
		practice_equipped.erase(hero_id)
	else:
		practice_equipped[hero_id] = trophy_id


func save(path: String) -> Error:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "collection", collection)
	cfg.set_value("progress", "silver", silver)
	cfg.set_value("progress", "artifacts", artifacts)
	cfg.set_value("progress", "oath", oath)
	cfg.set_value("progress", "perks", perks)
	cfg.set_value("progress", "party", party)
	cfg.set_value("progress", "practice_equipped", practice_equipped)
	return cfg.save(path)


## Läser profilen; saknas filen blir det en ny (med startsilver).
static func load_from(path: String) -> Profile:
	var p := Profile.new()
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return p
	for t in cfg.get_value("progress", "collection", []):
		p.collection.append(t)
	p.silver = int(cfg.get_value("progress", "silver", START_SILVER))
	p.artifacts = cfg.get_value("progress", "artifacts", {})
	var saved_oath: String = cfg.get_value("progress", "oath", p.oath)
	if OATHS.has(saved_oath):
		p.oath = saved_oath
	p.perks = cfg.get_value("progress", "perks", {})
	var saved: Array = cfg.get_value("progress", "party", [])
	if saved.size() == p.party.size():
		p.party.assign(saved)
	p.practice_equipped = cfg.get_value("progress", "practice_equipped", {})
	return p
