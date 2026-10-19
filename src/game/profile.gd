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
## varje klarad Realm Quest på en ny kombination av Realm och djup (0.18, som i Siralim där questen är
## enda källan till Perk Points). Äldre profiler behåller poängen de hade (bonus_points).

const START_SILVER := 60
## Smida en ny artefakt (eller byta typ, som smälter ned den gamla).
const FORGE_COST := 160
## Byta förmågan i en artefakt man redan har.
const RESOCKET_COST := 60
## Silver per vunnen strid, per våning (djup 1).
const FLOOR_REWARD := [15, 20, 30]
## Perk-poäng per kall: startvärdet räcker till en eller två perks (perks kostar 1–2 poäng).
const PERK_POINTS_START := 2
## Före 0.18: en perk-poäng för varannat klarat djup (räknas om till bonus_points för äldre profiler).
const DEPTHS_PER_PERK_POINT := 2
## Silver för en klarad Realm Quest (gånger djupets tillägg).
const QUEST_SILVER := 30
## Realm Depth: +25 % silver per djup över 1.
const SILVER_PER_DEPTH := 0.25
const OATHS := ["oath_vengeance", "oath_dawn", "oath_ward"]

var silver := START_SILVER
var collection: Array[String] = []
## hero_id -> {type, ability, level, stat_slots, trick_slots, nether} (Forge.normalize)
var artifacts := {}
## Material (0.20): material_id -> antal (bärnsten och trick). Nether Stones i en egen lista.
var materials := {}
var stones: Array = []
var next_stone_id := 1
## Senaste uppställningen från Kryptporten (används också i Övningsgården).
var oath := "oath_vengeance"
## Kallets altare (Siralims Enchanted Wardrobe): köpta perks per kall, oath_id -> [perk_id]. Alla köpta
## perks i den valda kallet verkar (inom perk-poängen); kärnan verkar alltid. Att återställa är gratis
## (poängen kommer tillbaka).
var perks := {}
var party: Array[String] = ["paladin"]
## 0.23: följeslagarna man har (de som inte följer med bor i Värdshuset och behåller sina nivåer). En ny profil
## börjar med Paladinen och Imma (VD:n: barndomsvännen från borgen); de andra befrias som lärjungar (fånge-rummet,
## Brokk först). Äldre profiler behåller sina fyra och får Imma i Värdshuset.
var recruited: Array[String] = []
const STARTER := "imma"
## Introduktionen (0.23, Intro): aktuellt steg i data/intro.json. En ny profil börjar ensam med Paladinen;
## Imma ansluter i steg 6. Befintliga profiler hoppar över introt.
var intro_step := 0
var intro_done := false
## Hur många följeslagare man hade senast man var i Värdshuset (det lyser när någon ny har kommit).
var inn_seen := 0
const LEGACY_COMPANIONS := ["brokk", "alva", "eira", "solveig"]
## Paladinen och högst så här många följeslagare i sällskapet.
const MAX_COMPANIONS := 3
## Ikapphämtning (vårt val): en hjälte under sällskapets snitt får mer erfarenhet, +50 % per nivå under, högst ×3.
const CATCH_UP_PER_LEVEL := 0.5
const CATCH_UP_MAX := 3.0
## Troféer ur samlingen som hjältarna bär i Övningsgården: hero_id -> trophy_id.
var practice_equipped := {}
## Realm Depth (Siralim): valt djup vid Kryptporten och det djupaste som klarats (0 = inget än).
## Nästa djup öppnas när det föregående är klarat.
var depth := 1
var best_depth := 0
## Vald Realm vid Kryptporten (data/realms.json). Djupet gäller alla Realms.
var realm := "crypt"
## Vald instabilitet 0–3 (RunState.MAX_INSTABILITY).
var instability := 0
## Segrar per boss (Siralims Masters): bosstrofén kräver RunState.BOSS_WINS_FOR_TROPHY.
var boss_wins := {}
## Klarade Realm Quests, en per kombination av Realm och djup ("crypt:1").
var quests_done: Array = []
## Djupaste klarade djup per Realm (kampanjkartans front, 0.18).
var realm_depth := {}
## Hjältarnas utveckling (0.19, Siralim): hero_id -> {level, xp, personality, battles, wins, deaths,
## revives, log: [{level, battle}]}. Nivåerna behålls mellan körningarna.
var heroes := {}
## Att byta personlighet i Biblioteket (Siralims Personality Tome).
const PERSONALITY_COST := 80
## Inställning: 3D-ögonblicken när sällskapet går in i ett rum på rumskartan.
var room_moments := true
## Perk-poäng från tiden före Realm Quests (0.14.1–0.17), så att äldre profiler behåller sina.
var bonus_points := 0
## Anointments (Siralim): varje besegrad boss (räknas en gång per bosstyp) låser upp en plats där
## ett kall får låna en perk från ett annat kall. Lånet kostar perk-poäng ur den lånande Kallets pott.
var bosses_defeated: Array[String] = []
## oath_id -> lånad perk_id.
var anointed := {}


static func reward(floor: int, at_depth := 1) -> int:
	var base: int = FLOOR_REWARD[clampi(floor, 0, FLOOR_REWARD.size() - 1)]
	return roundi(base * (1.0 + SILVER_PER_DEPTH * (maxi(at_depth, 1) - 1)))


## Ger silver för en vunnen strid på våningen och djupet, gånger våningsreglernas tillägg. Returnerar hur mycket.
func win_battle(floor: int, at_depth := 1, mult := 1.0) -> int:
	var amount := roundi(reward(floor, at_depth) * mult)
	silver += amount
	return amount


## Det djupaste man får välja: ett mer än det djupaste som klarats.
func max_depth() -> int:
	return best_depth + 1


func choose_depth(d: int) -> void:
	depth = clampi(d, 1, max_depth())


## Hela kryptan klarad på djupet: öppnar nästa.
func clear_depth(d: int, realm_id := "") -> void:
	best_depth = maxi(best_depth, d)
	if realm_id != "":
		realm_depth[realm_id] = maxi(int(realm_depth.get(realm_id, 0)), d)


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
	# Nivån och materialen följer med när typen byts (vårt val: det är samma artefakt, omsmidd).
	var art := artifact(hero_id)
	if art.is_empty():
		art = Forge.normalize({"type": type, "ability": ability_id})
	art.type = type
	art.ability = ability_id
	artifacts[hero_id] = art
	return true


## Hjältens artefakt med alla fält ifyllda ({} om ingen är smidd).
func artifact(hero_id: String) -> Dictionary:
	var art := Forge.normalize(artifacts.get(hero_id, {}))
	if not art.is_empty():
		artifacts[hero_id] = art
	return art


## Silver till nästa artefaktnivå (0 = högsta nivån eller ingen artefakt).
func artifact_level_cost(hero_id: String) -> int:
	var art := artifact(hero_id)
	return 0 if art.is_empty() else Forge.level_cost(int(art.level))


## Höjer artefaktens nivå. Returnerar vad nivån öppnade ("" om den bara stärker), eller null om det inte gick.
func level_artifact(hero_id: String) -> Variant:
	var cost := artifact_level_cost(hero_id)
	if cost == 0 or silver < cost:
		return null
	silver -= cost
	var art := artifact(hero_id)
	art.level = int(art.level) + 1
	return Forge.unlock_text(int(art.level))


## Sätter bärnsten i en Stat-plats (kostar Forge.AMBER_PER_SLOT) eller ett trick i en Trick-plats (kostar 1).
## Det som satt där förstörs (originalet). Tom material_id tömmer platsen. Falskt om det inte går.
func socket(hero_id: String, slot_kind: String, index: int, material_id: String) -> bool:
	var art := artifact(hero_id)
	if art.is_empty():
		return false
	var key := "stat_slots" if slot_kind == "stat" else "trick_slots"
	var open := Forge.stat_slot_open(int(art.level), index) if slot_kind == "stat" \
			else Forge.trick_slot_open(int(art.level), index)
	if not open or art[key][index] == material_id:
		return false
	var need := Forge.AMBER_PER_SLOT if slot_kind == "stat" else 1
	if material_id != "":
		if int(materials.get(material_id, 0)) < need:
			return false
		materials[material_id] = int(materials[material_id]) - need
		if materials[material_id] <= 0:
			materials.erase(material_id)
	art[key][index] = material_id
	return true


## Sätter en Nether Stone ur förrådet i Nether-platsen; den som satt där går tillbaka till förrådet.
## Tomt stone_id tar ut stenen. Falskt om det inte går.
func socket_stone(hero_id: String, stone_id: String) -> bool:
	var art := artifact(hero_id)
	if art.is_empty() or not Forge.nether_open(int(art.level)):
		return false
	var stone := {}
	if stone_id != "":
		for s in stones:
			if s.id == stone_id:
				stone = s
		if stone.is_empty():
			return false
		stones.erase(stone)
	if not art.nether.is_empty():
		stones.append(art.nether)
	art.nether = stone
	return true


## Lägger fynd i förrådet (Forge.roll_finds). Stenarna får sina id här.
func add_finds(finds: Array) -> void:
	for f in finds:
		match f.kind:
			"amber", "trick":
				materials[f.id] = int(materials.get(f.id, 0)) + int(f.count)
			"nether":
				stones.append(f.stone)


## Väljer kall vid Kallets altare.
func choose_oath(oath_id: String) -> void:
	if OATHS.has(oath_id):
		oath = oath_id


func owned_perks(oath_id: String) -> Array:
	return perks.get(oath_id, [])


## Perk-poäng att lägga i varje kall: PERK_POINTS_START, en per klarad quest (ny Realm och djup) och de
## gamla poängen från före 0.18.
func perk_points() -> int:
	return PERK_POINTS_START + quests_done.size() + bonus_points


## En Realm Quest är klarad. Ger silver, och en perk-poäng om kombinationen av Realm och djup är ny.
## Returnerar {silver, point}.
func complete_quest(realm_id: String, at_depth: int) -> Dictionary:
	var key := "%s:%d" % [realm_id, at_depth]
	var point := not quests_done.has(key)
	if point:
		quests_done.append(key)
	var amount := roundi(QUEST_SILVER * (1.0 + SILVER_PER_DEPTH * (maxi(at_depth, 1) - 1)))
	silver += amount
	return {"silver": amount, "point": point}


## Hjältens utveckling; skapas på nivå 1 med den förvalda personligheten (även för gamla profiler).
func hero(data: Dictionary, hero_id: String) -> Dictionary:
	if not heroes.has(hero_id):
		heroes[hero_id] = {"level": 1, "xp": 0, "personality": data.heroes[hero_id].get("personality", ""),
				"battles": 0, "wins": 0, "deaths": 0, "revives": 0, "log": []}
	return heroes[hero_id]


## Nivå och personlighet per hjälte, till CombatSim (opts.levels).
func levels_for(data: Dictionary, party: Array) -> Dictionary:
	var out := {}
	for hero_id in party:
		var h := hero(data, hero_id)
		out[hero_id] = {"level": int(h.level), "personality": h.personality}
	return out


## Erfarenhet till hela sällskapet efter en vunnen strid. Returnerar hero_id -> [nya nivåer].
## 0.23: den som ligger under sällskapets snitt hämtar ikapp (catch_up).
func grant_xp(data: Dictionary, party: Array, xp: int) -> Dictionary:
	var out := {}
	var avg := 0.0
	for hero_id in party:
		avg += float(hero(data, hero_id).level)
	avg /= maxi(party.size(), 1)
	for hero_id in party:
		var h := hero(data, hero_id)
		var ups := HeroStats.add_xp(h, roundi(xp * catch_up(float(h.level), avg)))
		for lv in ups:
			h.log.append({"level": lv, "battle": int(h.battles)})
		if not ups.is_empty():
			out[hero_id] = ups
	return out


static func catch_up(level: float, party_avg: float) -> float:
	return minf(1.0 + CATCH_UP_PER_LEVEL * maxf(party_avg - level, 0.0), CATCH_UP_MAX)


## En befriad lärjunge ansluter (0.23). Nivå 1, eller 2 om sällskapet redan är på nivå 4 eller mer (svag men
## användbar; egenskapen verkar från nivå 1). Returnerar falskt om hen redan fanns.
func recruit(data: Dictionary, hero_id: String, party_avg := 1.0) -> bool:
	if recruited.has(hero_id) or not data.heroes.has(hero_id) or hero_id == "paladin":
		return false
	recruited.append(hero_id)
	var h := hero(data, hero_id)
	if int(h.level) <= 1:
		h.level = 2 if party_avg >= 4.0 else 1
		h.xp = 0
	return true


## Följeslagarna man kan välja (Värdshuset): de man har, i den ordning de kom.
func roster() -> Array[String]:
	return recruited.duplicate()


## Väljer sällskapet: Paladinen plus 1–MAX_COMPANIONS följeslagare man har.
func set_party(companions: Array) -> void:
	var p: Array[String] = ["paladin"]
	for id in companions:
		if recruited.has(id) and not p.has(id) and p.size() <= MAX_COMPANIONS:
			p.append(id)
	if p.size() == 1 and not recruited.is_empty():
		p.append(recruited[0])  # minst en följeslagare när man har någon (introt: Paladinen ensam tills Imma)
	party = p


## Byter personlighet mot silver; nivåerna räknas om bakåt (statsen räknas alltid ur nivå och personlighet).
func set_personality(data: Dictionary, hero_id: String, personality: String) -> bool:
	var h := hero(data, hero_id)
	if not data.personalities.has(personality) or h.personality == personality or silver < PERSONALITY_COST:
		return false
	silver -= PERSONALITY_COST
	h.personality = personality
	return true


## Hur många perk-poäng Kallets köpta perks och lånade perk använder.
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


## Perkens post i oaths.json med Kallet den hör till: {id, cost, ranks, oath}, eller tom.
static func perk_entry(data: Dictionary, perk_id: String) -> Dictionary:
	for oath_id in data.oaths:
		for p in data.oaths[oath_id].perks:
			if p.id == perk_id:
				var out: Dictionary = p.duplicate()
				out.oath = oath_id
				return out
	return {}


## Vad en nivå av perken kostar i perk-poäng (−1 om den inte hör till Kallet).
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
## Kallet eller poängen inte räcker.
func buy_perk(data: Dictionary, oath_id: String, perk_id: String) -> bool:
	var cost := perk_cost(data, oath_id, perk_id)
	if cost < 0 or perk_rank(oath_id, perk_id) >= perk_ranks(data, perk_id) \
			or points_used(data, oath_id) + cost > perk_points():
		return false
	var list: Array = owned_perks(oath_id).duplicate()
	list.append(perk_id)
	perks[oath_id] = list
	return true


## Antal anointment-platser: en per besegrad bosstyp. Vi har en plats per kall, så fler bossar ger
## inte fler lån än (VAL; Siralim har fler platser).
func anointment_slots() -> int:
	return mini(bosses_defeated.size(), 1)


func defeat_boss(kind: String) -> void:
	if not bosses_defeated.has(kind):
		bosses_defeated.append(kind)
	boss_wins[kind] = int(boss_wins.get(kind, 0)) + 1


## Bossar som har besegrats tillräckligt många gånger för att lämna sin trofé.
func unlocked_boss_trophies() -> Array:
	return boss_wins.keys().filter(func(k: String) -> bool:
		return int(boss_wins[k]) >= RunState.BOSS_WINS_FOR_TROPHY)


## Lånar perken (nivå 1) från ett annat kall till oath_id, i stället för ett tidigare lån. Falskt om
## platsen inte är upplåst, perken hör till samma kall eller poängen inte räcker.
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


## Återställer Kallets perks och lån gratis, som i Siralim: poängen kommer tillbaka. Returnerar antalet poäng.
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
	cfg.set_value("progress", "materials", materials)
	cfg.set_value("progress", "stones", stones)
	cfg.set_value("progress", "next_stone_id", next_stone_id)
	cfg.set_value("progress", "oath", oath)
	cfg.set_value("progress", "perks", perks)
	cfg.set_value("progress", "party", party)
	cfg.set_value("progress", "recruited", recruited)
	cfg.set_value("progress", "intro_step", intro_step)
	cfg.set_value("progress", "intro_done", intro_done)
	cfg.set_value("progress", "inn_seen", inn_seen)
	cfg.set_value("progress", "practice_equipped", practice_equipped)
	cfg.set_value("progress", "depth", depth)
	cfg.set_value("progress", "best_depth", best_depth)
	cfg.set_value("progress", "realm", realm)
	cfg.set_value("progress", "instability", instability)
	cfg.set_value("progress", "boss_wins", boss_wins)
	cfg.set_value("progress", "quests_done", quests_done)
	cfg.set_value("progress", "realm_depth", realm_depth)
	cfg.set_value("progress", "room_moments", room_moments)
	cfg.set_value("progress", "heroes", heroes)
	cfg.set_value("progress", "bonus_points", bonus_points)
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
	for hero_id in p.artifacts:
		p.artifacts[hero_id] = Forge.normalize(p.artifacts[hero_id])
	p.materials = cfg.get_value("progress", "materials", {})
	p.stones = cfg.get_value("progress", "stones", [])
	p.next_stone_id = int(cfg.get_value("progress", "next_stone_id", 1))
	var saved_oath: String = cfg.get_value("progress", "oath", p.oath)
	if OATHS.has(saved_oath):
		p.oath = saved_oath
	p.perks = cfg.get_value("progress", "perks", {})
	# 0.23: äldre profiler (utan "recruited") behåller sina fyra följeslagare och sitt sällskap.
	if cfg.has_section_key("progress", "recruited"):
		p.recruited.assign(cfg.get_value("progress", "recruited", [STARTER]))
	else:
		p.recruited.assign(LEGACY_COMPANIONS)
	# Introt: profiler från före 0.23 (utan "intro_done") har redan allt och hoppar över det.
	p.intro_done = bool(cfg.get_value("progress", "intro_done", not cfg.has_section_key("progress", "recruited")))
	p.intro_step = int(cfg.get_value("progress", "intro_step", 0))
	p.inn_seen = int(cfg.get_value("progress", "inn_seen", p.recruited.size()))
	if p.intro_done and not p.recruited.has(STARTER):
		p.recruited.append(STARTER)  # Imma bor i borgen; äldre profiler hittar henne i Värdshuset
	var saved: Array = cfg.get_value("progress", "party", [])
	if saved.size() >= 2 and saved[0] == "paladin":
		p.party.assign(saved.filter(func(id: String) -> bool: return id == "paladin" or p.recruited.has(id)))
	elif not cfg.has_section_key("progress", "recruited"):
		p.party.assign(["paladin", "brokk", "alva", "eira"])
	p.practice_equipped = cfg.get_value("progress", "practice_equipped", {})
	p.best_depth = int(cfg.get_value("progress", "best_depth", 0))
	p.realm = cfg.get_value("progress", "realm", "crypt")
	p.instability = clampi(int(cfg.get_value("progress", "instability", 0)), 0, RunState.MAX_INSTABILITY)
	p.boss_wins = cfg.get_value("progress", "boss_wins", {})
	p.realm_depth = cfg.get_value("progress", "realm_depth", {})
	p.room_moments = cfg.get_value("progress", "room_moments", true)
	p.heroes = cfg.get_value("progress", "heroes", {})
	if cfg.has_section_key("progress", "quests_done"):
		p.quests_done = cfg.get_value("progress", "quests_done", [])
		p.bonus_points = int(cfg.get_value("progress", "bonus_points", 0))
	else:
		# Profil från före 0.18: behåll poängen för varannat klarat djup.
		p.bonus_points = p.best_depth / DEPTHS_PER_PERK_POINT
	for kind in cfg.get_value("progress", "bosses_defeated", []):
		p.bosses_defeated.append(kind)
	p.anointed = cfg.get_value("progress", "anointed", {})
	p.choose_depth(int(cfg.get_value("progress", "depth", 1)))
	return p
