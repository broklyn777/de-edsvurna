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
## Anointments (Siralim): varje besegrad boss (räknas en gång per bosstyp) låser upp en plats där
## en Ed får låna en perk från en annan Ed. Lånet kostar perk-poäng ur den lånande Edens pott.
var bosses_defeated: Array[String] = []
## oath_id -> lånad perk_id.
var anointed := {}


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


## Hur många perk-poäng Edens köpta perks och lånade perk använder.
func points_used(data: Dictionary, oath_id: String) -> int:
	var used := 0
	for perk_id in owned_perks(oath_id):
		used += maxi(perk_cost(data, oath_id, perk_id), 0)
	if anointed.has(oath_id):
		used += maxi(int(perk_entry(data, anointed[oath_id]).get("cost", 0)), 0)
	return used


## Perkarna som verkar: de köpta i köpordning (en post per nivå) och sist den lånade, så långt
## poängen räcker (äldre sparfiler kan ha fler).
func active_perks(data: Dictionary, oath_id: String) -> Array:
	var out := []
	var left := perk_points()
	var list: Array = owned_perks(oath_id).duplicate()
	if anointed.has(oath_id) and anointment_slots() > 0:
		list.append(anointed[oath_id])
	for perk_id in list:
		var cost := int(perk_entry(data, perk_id).get("cost", -1))
		if cost >= 0 and cost <= left:
			out.append(perk_id)
			left -= cost
	return out


## Perkens post i oaths.json med Eden den hör till: {id, cost, ranks, oath}, eller tom.
static func perk_entry(data: Dictionary, perk_id: String) -> Dictionary:
	for oath_id in data.oaths:
		for p in data.oaths[oath_id].perks:
			if p.id == perk_id:
				var out: Dictionary = p.duplicate()
				out.oath = oath_id
				return out
	return {}


## Vad en nivå av perken kostar i perk-poäng (−1 om den inte hör till Eden).
static func perk_cost(data: Dictionary, oath_id: String, perk_id: String) -> int:
	var entry := perk_entry(data, perk_id)
	return int(entry.cost) if entry.get("oath", "") == oath_id else -1


## Hur många nivåer perken har (rena siffror 2–3, regelbrytare 1, som i Siralim).
static func perk_ranks(data: Dictionary, perk_id: String) -> int:
	return int(perk_entry(data, perk_id).get("ranks", 1))


## Köpt nivå i perken (0 = inte köpt).
func perk_rank(oath_id: String, perk_id: String) -> int:
	return owned_perks(oath_id).count(perk_id)


## Köper perken, eller nästa nivå i den, för perk-poäng. Falskt om den har alla nivåer, inte hör till
## Eden eller poängen inte räcker.
func buy_perk(data: Dictionary, oath_id: String, perk_id: String) -> bool:
	var cost := perk_cost(data, oath_id, perk_id)
	if cost < 0 or perk_rank(oath_id, perk_id) >= perk_ranks(data, perk_id) \
			or points_used(data, oath_id) + cost > perk_points():
		return false
	var list: Array = owned_perks(oath_id).duplicate()
	list.append(perk_id)
	perks[oath_id] = list
	return true


## Antal anointment-platser: en per besegrad bosstyp. Vi har en plats per Ed, så fler bossar ger
## inte fler lån än (VAL; Siralim har fler platser).
func anointment_slots() -> int:
	return mini(bosses_defeated.size(), 1)


func defeat_boss(kind: String) -> void:
	if not bosses_defeated.has(kind):
		bosses_defeated.append(kind)


## Lånar perken (nivå 1) från en annan Ed till oath_id, i stället för ett tidigare lån. Falskt om
## platsen inte är upplåst, perken hör till samma Ed eller poängen inte räcker.
func anoint(data: Dictionary, oath_id: String, perk_id: String) -> bool:
	var entry := perk_entry(data, perk_id)
	if anointment_slots() <= 0 or entry.is_empty() or entry.oath == oath_id:
		return false
	var before: Variant = anointed.get(oath_id)
	anointed.erase(oath_id)
	if points_used(data, oath_id) + int(entry.cost) > perk_points():
		if before != null:
			anointed[oath_id] = before
		return false
	anointed[oath_id] = perk_id
	return true


## Återställer Edens perks och lån gratis, som i Siralim: poängen kommer tillbaka. Returnerar antalet poäng.
func reset_perks(data: Dictionary, oath_id: String) -> int:
	var refund := points_used(data, oath_id)
	perks.erase(oath_id)
	anointed.erase(oath_id)
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
	cfg.set_value("progress", "bosses_defeated", bosses_defeated)
	cfg.set_value("progress", "anointed", anointed)
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
	for kind in cfg.get_value("progress", "bosses_defeated", []):
		p.bosses_defeated.append(kind)
	p.anointed = cfg.get_value("progress", "anointed", {})
	p.choose_depth(int(cfg.get_value("progress", "depth", 1)))
	return p
