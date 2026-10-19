class_name Profile
extends RefCounted
## Det som varar mellan körningarna (basen, Siralims slott): silver, samlingen av troféer,
## hjältarnas artefakter och senaste uppställning. Ren logik; sparas i en ConfigFile.
##
## Silver är den enda resursen än så länge (Siralim har fem). Det ges för vunna strider i kryptan –
## inte i Övningsgården – och behålls även om sällskapet faller, som i Siralim där man bara
## förlorar Fortune.
##
## Balans (0.14): silvret ska inte räcka till allt efter några körningar. En klarad krypta på djup 1
## ger 65 silver och en artefakt kostar 160. Djupare ger mer (SILVER_PER_DEPTH). Perks kostar inte silver
## utan perk-poäng (0.14.1, Siralims Perk Points): man börjar med PERK_POINTS_START och får en till för
## varannat klarat djup (Siralim ger Perk Points från Realm Quests).

const START_SILVER := 60
## Smida en ny artefakt (eller byta typ, som smälter ned den gamla).
const FORGE_COST := 160
## Byta förmågan i en artefakt man redan har.
const RESOCKET_COST := 60
## Silver per vunnen strid, per våning (djup 1).
const FLOOR_REWARD := [15, 20, 30]
## Perk-poäng per Ed: startvärdet räcker till en eller två perks (perks kostar 1–2 poäng).
const PERK_POINTS_START := 2
## Klarade djup per extra perk-poäng.
const DEPTHS_PER_PERK_POINT := 2
## Realm Depth: +25 % silver per djup över 1.
const SILVER_PER_DEPTH := 0.25
const OATHS := ["oath_vengeance", "oath_dawn", "oath_ward"]

var silver := START_SILVER
var collection: Array[String] = []
## hero_id -> {type, ability}
var artifacts := {}
## Senaste uppställningen från Kryptporten (används också i Övningsgården).
var oath := "oath_vengeance"
## Edsaltaret (Siralims Enchanted Wardrobe): köpta perks per Ed, oath_id -> [perk_id]. Alla köpta
## perks i den valda Eden verkar (inom perk-poängen); kärnan verkar alltid. Att återställa är gratis
## (poängen kommer tillbaka).
var perks := {}
var party: Array[String] = ["paladin", "brokk", "alva", "eira"]
## Troféer ur samlingen som hjältarna bär i Övningsgården: hero_id -> trophy_id.
var practice_equipped := {}
## Realm Depth (Siralim): valt djup vid Kryptporten och det djupaste som klarats (0 = inget än).
## Nästa djup öppnas när det föregående är klarat.
var depth := 1
var best_depth := 0


static func reward(floor: int, at_depth := 1) -> int:
	var base: int = FLOOR_REWARD[clampi(floor, 0, FLOOR_REWARD.size() - 1)]
	return roundi(base * (1.0 + SILVER_PER_DEPTH * (maxi(at_depth, 1) - 1)))


## Ger silver för en vunnen strid på våningen och djupet. Returnerar hur mycket.
func win_battle(floor: int, at_depth := 1) -> int:
	var amount := reward(floor, at_depth)
	silver += amount
	return amount


## Det djupaste man får välja: ett mer än det djupaste som klarats.
func max_depth() -> int:
	return best_depth + 1


func choose_depth(d: int) -> void:
	depth = clampi(d, 1, max_depth())


## Hela kryptan klarad på djupet: öppnar nästa.
func clear_depth(d: int) -> void:
	best_depth = maxi(best_depth, d)


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


## Perk-poäng att lägga i varje Ed: PERK_POINTS_START och en till för varannat klarat djup.
func perk_points() -> int:
	return PERK_POINTS_START + best_depth / DEPTHS_PER_PERK_POINT


## Hur många perk-poäng Edens köpta perks använder.
func points_used(data: Dictionary, oath_id: String) -> int:
	var used := 0
	for perk_id in owned_perks(oath_id):
		used += maxi(perk_cost(data, oath_id, perk_id), 0)
	return used


## Perkarna som verkar: de köpta i köpordning så långt poängen räcker (äldre sparfiler kan ha fler).
func active_perks(data: Dictionary, oath_id: String) -> Array:
	var out := []
	var left := perk_points()
	for perk_id in owned_perks(oath_id):
		var cost := perk_cost(data, oath_id, perk_id)
		if cost >= 0 and cost <= left:
			out.append(perk_id)
			left -= cost
	return out


## Vad perken kostar i perk-poäng (−1 om den inte hör till Eden).
static func perk_cost(data: Dictionary, oath_id: String, perk_id: String) -> int:
	for p in data.oaths.get(oath_id, {}).get("perks", []):
		if p.id == perk_id:
			return int(p.cost)
	return -1


## Köper perken för perk-poäng. Falskt om den redan är köpt, inte hör till Eden eller poängen inte räcker.
func buy_perk(data: Dictionary, oath_id: String, perk_id: String) -> bool:
	var cost := perk_cost(data, oath_id, perk_id)
	if cost < 0 or owned_perks(oath_id).has(perk_id) or points_used(data, oath_id) + cost > perk_points():
		return false
	var list: Array = owned_perks(oath_id).duplicate()
	list.append(perk_id)
	perks[oath_id] = list
	return true


## Återställer Edens perks gratis, som i Siralim: poängen kommer tillbaka. Returnerar antalet poäng.
func reset_perks(data: Dictionary, oath_id: String) -> int:
	var refund := points_used(data, oath_id)
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
	cfg.set_value("progress", "depth", depth)
	cfg.set_value("progress", "best_depth", best_depth)
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
	p.best_depth = int(cfg.get_value("progress", "best_depth", 0))
	p.choose_depth(int(cfg.get_value("progress", "depth", 1)))
	return p
