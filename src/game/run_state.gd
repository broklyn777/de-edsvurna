class_name RunState
extends RefCounted
## En körning genom kryptan: valt kall, sällskap, våning och troféer. Ren logik utan noder.
##
## Varje vunnen strid ger ett val av en trofé bland monstren man just slog. Troféer kan flyttas
## fritt mellan hjältarna mellan striderna (en per hjälte).

## Kryptans våningar (standard). Varje Realm har sina i data/realms.json.
const FLOORS := ["crypt_1", "crypt_2", "crypt_3"]
## Största sällskapet (Paladinen + 3). 0.23: det minsta är Paladinen + 1.
const PARTY_SIZE := 4
const MIN_PARTY := 2


## 0.25.1: den som väntar på rumskartan ansluter nu (nivå efter sällskapet, Charges, profilens sällskap).
## Returnerar hjälten, eller "" om ingen väntade.
func join_waiting(data: Dictionary, profile: Profile) -> String:
	var hero_id := joins_next
	joins_next = ""
	if hero_id == "" or party.has(hero_id):
		return ""
	profile.recruit(data, hero_id, float(profile.hero(data, "paladin").level))
	party.append(hero_id)
	add_charges_for(data, hero_id)
	profile.set_party(party.slice(1))
	return hero_id


## 0.25: sällskapet kan gå ned: Paladinen och minst en följeslagare, eller Paladinen ensam när ingen har anslutit än
## (introts nedstigning; Imma smiter efter).
static func can_start(profile: Profile) -> bool:
	return profile.party.size() >= MIN_PARTY or profile.recruited.is_empty()
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
## Köpta perks i Kallet (Kallets altare). De bärs av Paladinen och verkar som Kallet.
var perks: Array = []
## Paladinen först, sedan följeslagarna.
var party: Array[String] = ["paladin", "brokk", "alva", "eira"]
var floor := 0
## Realm (Siralim): "crypt" eller "chapel" (data/realms.json) och dess våningar.
var realm := "crypt"
var floor_ids: Array = FLOORS
## 0.27: två våningar per körning (den första slutar vid en trappa, den andra vid bossen). Realmens tre möten i
## "floors" finns kvar: det sista är bossen och de andra vaktar de bevakade skatterna.
const FLOORS_PER_RUN := 2
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

# --- Grottan och Realm Quest (0.27) -------------------------------------------------
## Fröet som våningarnas grottor och questen slumpas ur.
var run_seed := 1
## Våningens grotta (Grotto), rutan man står på, besökta rutor, rutor med en sedd grupp och rutan man kom ifrån
## (dit man kan backa från en grupp).
var map: Grotto
var pos := 0
var visited: Array = []
var seen: Array = []
var came_from := -1
## Kvar från rumskartan (0.18), används inte längre; −1.
var side_index := -1
## Sällskapet har gått in i ett stridsrum men inte vunnit än (körningen sparas före striden). Vid
## återupptagning går man rakt in i striden igen.
var battle_pending := false
## Våningens quest (0.27: en per våning, låser trappan eller bossen): {type, goal, progress, done, rewarded}.
var quest := {}
## Helgedomens gåvor och förbannelser som gäller nästa strid: auror för sällskapet och regler.
var next_auras: Array = []
var next_rules: Array = []
## Klar med körningen (slutet på sista våningen vunnet).
var finished := false
## Egenskapernas statistik för hela körningen: trait_id -> {procs, damage, heal, unit} (hjältebladet).
var trait_totals := {}
## Fynden i körningen (0.20), visas på rumskartan: bärnsten, trick och Nether Stones.
var found := {"amber": 0, "trick": 0, "nether": 0}
## 0.24: replikerna som redan har sagts den här körningen (Dialog.bark upprepar dem inte).
var barks_used: Array = []
## 0.24: profilens första nedstigning (FIRST_DESCENT_RAMP).
var first_descent := false
## 0.25.1: den som ansluter när sällskapet är tillbaka på rumskartan (Imma som smiter efter den första striden), eller "".
## Segerskärmen visar bara dem som var med i striden; anslutningen görs först på kartan (join_waiting).
var joins_next := ""
## 0.23: fångar på våningarna, floor (som text) -> {hero, first}. Den första är tidig och obevakad.
var prisoners := {}


## En ny körning från basen: Kallet och sällskapet från Kryptporten, artefakterna från Smeden.
static func new_run(profile: Profile, data: Dictionary) -> RunState:
	var s := RunState.new()
	s.oath = profile.oath
	s.perks = profile.active_perks(data, profile.oath)
	s.party = profile.party.duplicate()
	s.artifacts = profile.artifacts.duplicate(true)
	s.depth = profile.depth
	s.set_realm(data, profile.realm)
	s.fill_charges(data)
	s.place_prisoners(data, profile.recruited, int(profile.descents.get(profile.realm, 0)))
	# 0.26.3 (Siralim): hjältarna bär sina troféer ur samlingen in i varje körning.
	for hero_id in profile.worn:
		var trophy_id: String = profile.worn[hero_id]
		if s.party.has(hero_id) and profile.collection.has(trophy_id):
			s.take_trophy(trophy_id)
			s.equip(hero_id, trophy_id)
	return s


## Lärjungar som sitter fångna i den här Realmen på det här djupet (0.23, Siralims varelser per Realm): de man inte
## redan har och vars djup är nått. 0.24: en i taget (den första i listan som passar), och "after_descents" kräver så
## många tidigare nedstigningar i Realmen (Syster Alva på den andra i kryptan). descents < 0 = räkna inte (botarna).
func place_prisoners(data: Dictionary, recruited: Array, descents := -1) -> void:
	prisoners.clear()
	for d in data.realms[realm].get("disciples", []):
		if recruited.has(d.hero) or depth < int(d.depth):
			continue
		if descents >= 0 and descents < int(d.get("after_descents", 0)):
			continue
		var f := clampi(int(d.floor), 0, FLOORS_PER_RUN - 1)  # 0.27: dagens våning 2–3 blir grottans andra
		prisoners[str(f)] = {"hero": d.hero, "first": d.get("first", false),
				"guarded": d.get("guarded", not d.get("first", false))}
		return


## En strid i Övningsgården: samma sällskap, makron, artefakter och troféer, och fulla Charges. Inget förloras
## och inget vinns.
static func new_practice(profile: Profile, data: Dictionary, encounter_id: String) -> RunState:
	var s := new_run(profile, data)
	s.practice = true
	s.practice_encounter = encounter_id
	return s


## Fulla Charges för en hjälte som ansluter mitt i körningen (0.23).
func add_charges_for(data: Dictionary, hero_id: String) -> void:
	var c := {}
	for ability_id in data.heroes[hero_id].get("abilities", []):
		c[ability_id] = int(data.abilities[ability_id].get("charges", 0))
	charges[hero_id] = c


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
	if practice:
		return practice_encounter
	var r := current_room()
	if r.has("encounter"):
		return r.encounter
	return floor_ids[floor]


func is_last_floor() -> bool:
	return practice or floor >= FLOORS_PER_RUN - 1


## Egenskaper per hjälte för striden: Paladinens kall och perks ersätter hens förvalda, och troféer
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
	# 0.23.3: bara de fiender som faktiskt mötte sällskapet (ett litet sällskap möter färre).
	for kind in CombatSim.enemy_lineup(data, data.encounters[encounter()].enemies, party.size()):
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



# --- Rumskartan (0.18) --------------------------------------------------------
# Flöde (0.27): start_expedition() → start_floor() lägger grottan och questen. Spelaren går med can_step(i) och
# step(i). En ruta med en grupp visar ett kort: fight() (striden) eller back(). Efter en vunnen strid battle_won();
# sedan rutans innehåll (skatt, föremål, fånge). Lägereld: campfire(); skatt: treasure(); helgedom: shrine_options() +
# apply_shrine(). Trappan (descend) eller bossen avslutar våningen när questen är klar.

const QUEST_TYPES := ["hunt", "clear", "collect"]
## Lägereld: Charges som fylls per förmåga (högst till max). Charges är Siralims (4–8 per förmåga), så
## lägerelden före våningens slut är det som gör att de räcker en hel körning.
const CAMPFIRE_CHARGES := 3
## Silver i vanliga strider och skattkammare, som andel av våningens belöning (bossen ger hela).
const BATTLE_SILVER := 0.4
const TREASURE_SILVER := 0.6
const TREASURE_TROPHY_CHANCE := 0.2
## Portalens strid: starkare fiender, mer silver och bättre troféchans.
const PORTAL_STATS := 1.15
## 0.24.1: den allra första nedstigningen gör Paladinen och Imma ensamma, med en mjuk trappa i fiendernas stats per
## våning (vårt val; följer aldrig hjältarnas nivå): första våningen nästan alltid vunnen, den andra lite svårare och
## Benfursten en riktig utmaning. Mätt med botarna (BALANS=forsta), docs/formler.md §9.
const FIRST_DESCENT_RAMP := [0.70, 0.88, 0.81]
## 0.28 (vårt val): elitgruppen på våning 1 (Kolossens vakt) är mildare på profilens första nedstigning, eftersom en
## Jakt på Nemesis kan tvinga en ny spelare att möta den.
const FIRST_DESCENT_ELITE := 0.8
## 0.25: den första striden gör paladinen ensam (Imma smiter efter först efteråt). Den ska vara lika lätt som övningen:
## fienderna ×0,80 till (vårt val, mätt med botarna: tests/test_story.gd och BALANS=forsta).
const FIRST_FIGHT_ALONE := 0.80


## Fiendernas skalning på profilens första nedstigning för en våning (1 = ingen).
static func first_descent_mult(floor_i: int) -> float:
	return float(FIRST_DESCENT_RAMP[clampi(floor_i, 0, FIRST_DESCENT_RAMP.size() - 1)])
const PORTAL_SILVER := 1.0
const PORTAL_TROPHY_BONUS := 0.25


## Startar grottan och den första våningens quest för en ny körning.
func start_expedition(data: Dictionary, seed_value: int) -> void:
	run_seed = seed_value
	floor = 0
	finished = false
	start_floor(data)


## Slumpar våningens quest (Siralim, plan "Questen"): Jakt (besegra Nemesis), Rensa (2 elitgrupper) eller Samla (2–3
## föremål, alltid bevakade av en grupp). Varje quest leder till strider.
static func roll_quest(rng: RandomNumberGenerator) -> Dictionary:
	var type: String = QUEST_TYPES[rng.randi() % QUEST_TYPES.size()]
	var q := {"type": type, "progress": 0, "done": false}
	match type:
		"hunt":
			q.goal = 1
		"clear":
			q.goal = 2
		"collect":
			q.goal = rng.randi_range(2, 3)
	return q


static func quest_text(q: Dictionary) -> String:
	match q.get("type", ""):
		"hunt":
			return "Jakt: besegra Nemesis (%d/%d)" % [q.progress, q.goal]
		"clear":
			return "Rensa: besegra %d elitgrupper (%d/%d)" % [q.goal, q.progress, q.goal]
		"collect":
			return "Samla: ta %d bevakade föremål (%d/%d)" % [q.goal, q.progress, q.goal]
	return ""


## Lägger våningens grotta och quest ur fröet. Grupperna kommer ur Realmens pooler (tier 0–2 efter våning och avstånd).
func start_floor(data: Dictionary) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = run_seed * 977 + floor * 31 + 13
	quest = roll_quest(rng)
	var pools: Array = data.realms[realm].get("pools", [])
	if pools.is_empty():
		pools = [floor_ids]
	var boss: String = floor_ids[floor_ids.size() - 1]
	var guard: String = floor_ids[mini(floor, floor_ids.size() - 2)] if floor_ids.size() > 1 else ""
	map = Grotto.generate(run_seed * 101 + floor * 7 + 1, floor, is_last_floor(), pools, boss, guard, quest,
			prisoners.get(str(floor), {}), data.realms[realm].get("elite_pools", []))
	pos = map.start
	visited = [map.start]
	seen = []
	came_from = -1
	battle_pending = false


## Rutan man står på (med "kind"; tom utanför en körning).
func current_room() -> Dictionary:
	if map == null or practice:
		return {}
	return map.cell(pos)


## Sant om rutan har en grupp som inte är besegrad (striden väntar).
static func is_battle(r: Dictionary) -> bool:
	return r.has("encounter") and not r.get("beaten", false)


## Står man på en obesegrad grupp kan man bara slåss eller backa.
func at_group() -> bool:
	return map != null and map.has_group(pos)


func goal_locked() -> bool:
	return not quest.get("done", false)


## Kan man gå till rutan? "" om det går, annars en orsak: here, group (backa eller slåss först), locked (målet),
## blocked (spärrad av en grupp), far (inte en granne och inte besökt), path (ingen väg genom besökta rutor).
func can_step(i: int) -> String:
	if map == null or i < 0 or i >= map.cells.size():
		return "far"
	if i == pos:
		return "here"
	if at_group():
		return "" if i == came_from else "group"
	if i == map.goal and goal_locked():
		return "locked"
	if visited.has(i):
		return "" if not map.path(pos, i, visited).is_empty() else "path"
	if map.blocked(i, visited, seen):
		return "blocked"
	if Grotto.neighbors(pos).has(i):
		return ""
	# En obesökt ruta intill en besökt: pjäsen går dit själv och tar sista steget (bara besökta rutor på vägen).
	return "" if not map.path(pos, i, visited).is_empty() else "far"


## Går till rutan. Returnerar rutorna pjäsen passerar (den sista är målet), eller [] om det inte går.
func step(i: int) -> Array[int]:
	if can_step(i) != "":
		return []
	var walk: Array[int] = []
	if at_group() or (Grotto.neighbors(pos).has(i) and not visited.has(i)):
		walk.append(i)
	else:
		walk = map.path(pos, i, visited)
	if walk.is_empty():
		walk.append(i)
	came_from = walk[walk.size() - 2] if walk.size() > 1 else pos
	pos = i
	if not visited.has(i):
		visited.append(i)
	if map.has_group(i) and not seen.has(i):
		seen.append(i)
	return walk


## Backar från en grupp till rutan man kom ifrån (gruppen står kvar och spärrar sina grannar).
func back() -> bool:
	if not at_group() or came_from < 0:
		return false
	pos = came_from
	came_from = -1
	return true


## Striden mot gruppen på rutan börjar (körningen sparas före striden).
func fight() -> void:
	battle_pending = at_group()


## Inställningar till CombatSim för rutans strid (regler, elit, Nemesis, helgedomens gåva). "floor" är gruppens tier, som
## ger fiendernas nivå (HeroStats.enemy_level).
func battle_opts() -> Dictionary:
	var r := current_room()
	var tier := int(r.get("tier", floor))
	var opts := {"rules": active_rules() + next_rules, "instability": instability, "start_auras": next_auras.duplicate(),
			"floor": tier}
	if r.get("elite", false) or r.get("nemesis", false):
		opts.force_elites = 1
	# 0.27: motdrag bara i elitgrupper och bossmöten (CombatSim.counter_for).
	if r.get("elite", false) or r.get("nemesis", false) or r.get("boss", false):
		opts.counter = true
	if r.get("nemesis", false):
		opts.nemesis = true
	if first_descent:
		opts.stat_bonus = first_descent_mult(tier)
		if party.size() == 1:
			opts.stat_bonus *= FIRST_FIGHT_ALONE
		if floor == 0 and (r.get("elite", false) or r.get("nemesis", false)):
			opts.stat_bonus *= FIRST_DESCENT_ELITE
	return opts


## Stridens sort för erfarenhet och fynd: boss, elite, end eller battle.
static func fight_kind(r: Dictionary) -> String:
	if r.get("boss", false):
		return "end"
	return "elite" if r.get("elite", false) else "battle"


## Silver för rutans strid (gånger våningsreglernas tillägg sätts av den som betalar ut).
func battle_silver(at_depth: int) -> int:
	var r := current_room()
	var share := 1.0 if r.get("boss", false) else BATTLE_SILVER
	return roundi(Profile.reward(int(r.get("tier", floor)), at_depth) * share)


## Efter en vunnen strid: gruppen är besegrad, questen räknas, och nästa strid är utan helgedomens gåva. Returnerar sant
## om questen blev klar nu.
func battle_won() -> bool:
	var r := current_room()
	battle_pending = false
	next_auras.clear()
	next_rules.clear()
	r.beaten = true
	var before: bool = quest.get("done", false)
	if r.get("nemesis", false) and quest.get("type", "") == "hunt":
		_quest_step()
	if r.get("elite", false) and quest.get("type", "") == "clear":
		_quest_step()
	return quest.get("done", false) and not before


## Ett quest-föremål tas (efter att vakten är besegrad). Sant om questen blev klar nu.
func collect_item() -> bool:
	var r := current_room()
	if r.get("kind", "") != "item" or r.get("done", false) or is_battle(r):
		return false
	r.done = true
	var before: bool = quest.get("done", false)
	if quest.get("type", "") == "collect":
		_quest_step()
	return quest.get("done", false) and not before


func _quest_step() -> void:
	quest.progress = mini(int(quest.progress) + 1, int(quest.goal))
	if quest.progress >= quest.goal:
		quest.done = true


## Sant när våningen är klar: bossen besegrad, eller trappan nådd med questen klar.
func floor_cleared() -> bool:
	if map == null or pos != map.goal or battle_pending:
		return false
	var g := map.cell(map.goal)
	return g.get("beaten", false) if g.kind == "end" else not goal_locked()


## Nästa våning, eller körningen klar efter den sista.
func next_floor(data: Dictionary) -> void:
	if is_last_floor():
		finished = true
		return
	floor += 1
	start_floor(data)


## Lägereld: +CAMPFIRE_CHARGES på varje förmåga (högst till max), en gång per lägereld. Troféerna byts där (Run).
func campfire(data: Dictionary) -> int:
	var r := current_room()
	if r.get("done", false):
		return 0
	r.done = true
	var gained := 0
	for hero_id in charges:
		for ability_id in charges[hero_id]:
			var full := int(data.abilities[ability_id].get("charges", 0))
			var add := mini(CAMPFIRE_CHARGES, full - int(charges[hero_id][ability_id]))
			if add > 0:
				charges[hero_id][ability_id] += add
				gained += add
	return gained


## Skatt: silver (andel av våningens belöning) och ibland en trofé ur samma Realm; en bevakad skatt har bättre chans
## (plan: "trofé eller sällsynt material"). Returnerar {silver, trophy}.
func treasure(data: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var r := current_room()
	r.done = true
	var guarded: bool = r.get("guarded", false)
	var out := {"silver": roundi(Profile.reward(int(r.get("tier", floor)), depth) * TREASURE_SILVER), "trophy": ""}
	var chance := TREASURE_TROPHY_CHANCE + (PORTAL_TROPHY_BONUS if guarded else 0.0)
	if rng.randf() < chance:
		var pool := []
		for enc_id in floor_ids:
			for kind in data.encounters[enc_id].enemies:
				var t: String = data.enemies[kind].get("trophy", "")
				if t != "" and not data.enemies[kind].get("boss", false) and not trophies.has(t) and not pool.has(t):
					pool.append(t)
		if not pool.is_empty():
			out.trophy = pool[rng.randi() % pool.size()]
	return out


## Helgedom (Siralims Pandemonium Shrine): två gåvor och en slumpad effekt att välja mellan.
## [{kind: "charge", hero, ability} | {kind: "blessing", aura} | {kind: "chaos"}]
func shrine_options(data: Dictionary, rng: RandomNumberGenerator) -> Array:
	var abilities := []
	for hero_id in charges:
		for ability_id in charges[hero_id]:
			if int(charges[hero_id][ability_id]) < int(data.abilities[ability_id].get("charges", 0)) + 1:
				abilities.append([hero_id, ability_id])
	var out := []
	if not abilities.is_empty():
		var pick: Array = abilities[rng.randi() % abilities.size()]
		out.append({"kind": "charge", "hero": pick[0], "ability": pick[1], "amount": 2})
	out.append({"kind": "blessing", "aura": ["inspired", "warded"][rng.randi() % 2]})
	out.append({"kind": "chaos"})
	return out


static func shrine_text(data: Dictionary, o: Dictionary) -> String:
	match o.kind:
		"charge":
			return "+%d Charges: %s (%s)" % [o.amount, data.abilities[o.ability].name, data.heroes[o.hero].name]
		"blessing":
			return "Sällskapet börjar nästa strid med %s" % data.auras[o.aura].name
	return "Pandemonium: en slumpad effekt, bra eller dålig"


## Tar emot gåvan. Pandemonium slår om: +1 Charge på alla förmågor, Barriär till nästa strid, en
## förlorad Charge eller en våningsregel i nästa strid. Returnerar en text om vad som hände.
func apply_shrine(data: Dictionary, rng: RandomNumberGenerator, o: Dictionary) -> String:
	var text := shrine_text(data, o)
	match o.kind:
		"charge":
			charges[o.hero][o.ability] = int(charges[o.hero][o.ability]) + int(o.amount)
		"blessing":
			next_auras.append(o.aura)
		"chaos":
			match rng.randi() % 4:
				0:
					for hero_id in charges:
						for ability_id in charges[hero_id]:
							charges[hero_id][ability_id] = int(charges[hero_id][ability_id]) + 1
					text = "Pandemonium: +1 Charge på alla förmågor!"
				1:
					next_auras.append("holy_shield")
					text = "Pandemonium: sällskapet börjar nästa strid under Helig sköld!"
				2:
					var hero_id: String = charges.keys()[rng.randi() % charges.size()]
					var list: Array = charges[hero_id].keys()
					if not list.is_empty():
						var ab: String = list[rng.randi() % list.size()]
						charges[hero_id][ab] = maxi(0, int(charges[hero_id][ab]) - 1)
						text = "Pandemonium: %s förlorar en Charge på %s." % [data.heroes[hero_id].name, data.abilities[ab].name]
				3:
					var open: Array = data.floor_rules.keys().filter(func(id: String) -> bool:
						return int(data.floor_rules[id].get("min_instability", 0)) <= 1 and not active_rules().has(id))
					var rule: String = open[rng.randi() % open.size()]
					next_rules.append(rule)
					text = "Pandemonium: nästa strid gäller %s." % data.floor_rules[rule].name
	current_room().done = true
	return text


# --- Sparning (user://run.cfg) -------------------------------------------------

const SAVED_FIELDS := ["oath", "perks", "floor", "realm", "floor_ids", "instability", "rules_visible", "rules_hidden",
		"rules_revealed", "depth", "equipped", "charges", "artifacts", "run_seed", "pos", "visited", "seen", "came_from",
		"side_index", "quest", "next_auras", "next_rules", "finished", "trait_totals", "found", "battle_pending", "prisoners",
		"barks_used", "first_descent", "joins_next"]


func to_dict() -> Dictionary:
	var d := {}
	for f in SAVED_FIELDS:
		d[f] = get(f)
	d.party = Array(party)
	d.trophies = Array(trophies)
	d.map = map.to_dict() if map else {}
	return d


static func from_dict(d: Dictionary) -> RunState:
	var s := RunState.new()
	for f in SAVED_FIELDS:
		if d.has(f):
			s.set(f, d[f])
	s.party.assign(d.get("party", s.party))
	s.trophies.assign(d.get("trophies", []))
	# 0.27: en körning sparad med rumskartan (före grottan) går inte att fortsätta; den börjar om hemma.
	if not d.get("map", {}).is_empty() and d.map.has("cells"):
		s.map = Grotto.from_dict(d.map)
	return s


func save(path: String) -> Error:
	var cfg := ConfigFile.new()
	cfg.set_value("run", "state", to_dict())
	return cfg.save(path)


## Tar bort den sparade körningen (förlust eller ge upp): nästa körning börjar om från våning 1.
static func delete_saved(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


## Läser en sparad körning, eller null.
static func load_from(path: String) -> RunState:
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK or not cfg.has_section_key("run", "state"):
		return null
	return from_dict(cfg.get_value("run", "state"))
