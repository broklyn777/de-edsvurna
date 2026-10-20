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

# --- Rumskartan och Realm Quest (0.18) ---------------------------------------------
## Fröet som våningarnas kartor och questen slumpas ur.
var run_seed := 1
## Våningens karta, rummet man står i ("" = vid våningens början) och besökta rum.
var map: RoomMap
var room_id := ""
var visited: Array = []
## Portalens sidodel: index för nästa sidorum (−1 = inte i en portal).
var side_index := -1
## Sällskapet har gått in i ett stridsrum men inte vunnit än (körningen sparas före striden). Vid
## återupptagning går man rakt in i striden igen.
var battle_pending := false
## Realm Quest: {type, goal, progress, done, floor (Jakt), room (Jakt), reward_silver}.
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
## 0.24: profilens första nedstigning (FIRST_DESCENT_STATS).
var first_descent := false
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
		var f := clampi(int(d.floor), 0, floor_ids.size() - 1)
		prisoners[str(f)] = {"hero": d.hero, "first": d.get("first", false),
				"guarded": d.get("guarded", not d.get("first", false))}
		return


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
	return practice or floor >= floor_ids.size() - 1


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
# Flöde: start_expedition() → choices() → enter(id) → beroende på rummets typ:
#   strid (battle, elite, portal_battle, end): battle_opts() till CombatSim, sedan battle_won()
#   lägereld: campfire(); skattkammare: treasure(); helgedom: shrine_options() + apply_shrine()
#   portal: enter() går vidare in i sidodelen (side_choice())
# När slutet är vunnet: next_floor() eller finished.

const QUEST_TYPES := ["hunt", "clear", "purify"]
## Lägereld: Charges som fylls per förmåga (högst till max). Charges är Siralims (4–8 per förmåga), så
## lägerelden före våningens slut är det som gör att de räcker en hel körning.
const CAMPFIRE_CHARGES := 3
## Silver i vanliga strider och skattkammare, som andel av våningens belöning (slutet ger hela).
const BATTLE_SILVER := 0.4
const TREASURE_SILVER := 0.6
const TREASURE_TROPHY_CHANCE := 0.2
## Portalens strid: starkare fiender, mer silver och bättre troféchans.
const PORTAL_STATS := 1.15
## 0.24: den allra första nedstigningen gör Paladinen och Imma ensamma, med svagare fiender (vårt val, mätt med
## botarna: 64 % med en ny profils makron, BALANS=forsta).
const FIRST_DESCENT_STATS := 0.85
const PORTAL_SILVER := 1.0
const PORTAL_TROPHY_BONUS := 0.25


## Startar kartan och questen för en ny körning.
func start_expedition(data: Dictionary, seed_value: int) -> void:
	run_seed = seed_value
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 977 + 13
	quest = roll_quest(data, rng, floor_ids.size())
	floor = 0
	finished = false
	start_floor(data)


## Slumpar en Realm Quest (Siralim): Jakt (besegra Nemesis), Rensa (2 elitstrider), Rening (3 helgedomar).
static func roll_quest(data: Dictionary, rng: RandomNumberGenerator, floors: int) -> Dictionary:
	var type: String = QUEST_TYPES[rng.randi() % QUEST_TYPES.size()]
	var q := {"type": type, "progress": 0, "done": false}
	match type:
		"hunt":
			q.goal = 1
			q.floor = rng.randi() % floors
		"clear":
			q.goal = 2
		"purify":
			q.goal = 3
	return q


static func quest_text(q: Dictionary) -> String:
	match q.get("type", ""):
		"hunt":
			return "Jakt: besegra Nemesis på våning %d (%d/%d)" % [int(q.floor) + 1, q.progress, q.goal]
		"clear":
			return "Rensa: vinn %d elitstrider (%d/%d)" % [q.goal, q.progress, q.goal]
		"purify":
			return "Rening: besök %d helgedomar (%d/%d)" % [q.goal, q.progress, q.goal]
	return ""


func start_floor(data: Dictionary) -> void:
	var pools: Array = data.realms[realm].get("pools", [])
	var pool: Array = pools[floor] if floor < pools.size() else [floor_ids[floor]]
	var want_shrines := 1 if quest.get("type", "") == "purify" else 0
	map = RoomMap.generate(run_seed * 101 + floor * 7 + 1, floor, is_last_floor(), pool, floor_ids[floor], want_shrines)
	room_id = ""
	side_index = -1
	_place_prisoner_room()
	if quest.get("type", "") == "hunt" and int(quest.floor) == floor:
		# Nemesis i ett av stridsrummen (det i mitten av kartan om det går).
		var fights := map.all_rooms().filter(func(r: Dictionary) -> bool: return r.kind == "battle")
		if not fights.is_empty():
			fights[fights.size() / 2].nemesis = true
		else:
			map.end.nemesis = true


## Fånge-rummet på våningen: den första tidigt och obevakad (steg 0), de andra i ett senare rum, bevakade av en strid.
func _place_prisoner_room() -> void:
	var p: Dictionary = prisoners.get(str(floor), {})
	if p.is_empty() or map == null or map.steps.is_empty():
		return
	var first: bool = p.get("first", false)
	var step: Array = map.steps[0 if first else mini(1, map.steps.size() - 2)]
	var r: Dictionary = step[0]
	for x in step:
		if x.kind == "battle":
			r = x
			break
	var pool: Array = [r.get("encounter", floor_ids[floor])]
	r.kind = "prisoner"
	r.hero = p.hero
	r.guarded = p.get("guarded", not first)
	r.erase("side")
	if r.guarded and not r.has("encounter"):
		r.encounter = pool[0]


func current_room() -> Dictionary:
	if map == null or room_id == "":
		return {}
	if side_index >= 0:
		var portal := map.room(room_id)
		return portal.side[mini(side_index, portal.side.size() - 1)]
	return map.room(room_id)


## Rummen man kan välja nu. Inne i en portal finns bara nästa sidorum.
func choices() -> Array:
	if map == null:
		return []
	if side_index >= 0:
		return [current_room().id]
	return map.choices(room_id)


## Går in i rummet. Returnerar rummet (med "kind").
func enter(id: String) -> Dictionary:
	if side_index >= 0:
		return current_room()
	room_id = id
	visited.append(id)
	var r := map.room(id)
	if r.kind == "portal":
		side_index = 0
		r = current_room()
	battle_pending = is_battle(r)
	return r


## Sant om rummet är en strid.
static func is_battle(r: Dictionary) -> bool:
	if r.get("kind", "") == "prisoner":
		return r.get("guarded", false) and not r.get("rescued", false)
	return r.get("kind", "") in ["battle", "elite", "portal_battle", "end"]


## Inställningar till CombatSim för rummets strid (regler, elit, portal, helgedomens gåva).
func battle_opts() -> Dictionary:
	var r := current_room()
	var opts := {"rules": active_rules() + next_rules, "instability": instability, "start_auras": next_auras.duplicate(),
			"floor": floor}
	if r.get("kind", "") == "elite" or r.get("nemesis", false):
		opts.force_elites = 1
	if r.get("nemesis", false):
		opts.nemesis = true
	if r.get("kind", "") == "portal_battle":
		opts.stat_bonus = PORTAL_STATS
	if first_descent:
		opts.stat_bonus = float(opts.get("stat_bonus", 1.0)) * FIRST_DESCENT_STATS
	return opts


## Silver för rummets strid (gånger våningsreglernas tillägg sätts av den som betalar ut).
func battle_silver(at_depth: int) -> int:
	var r := current_room()
	var kind: String = r.get("kind", "end")
	var share := 1.0 if kind == "end" else (PORTAL_SILVER if kind == "portal_battle" else BATTLE_SILVER)
	return roundi(Profile.reward(floor, at_depth) * share)


## Efter en vunnen strid: questen räknas, och nästa strid är utan helgedomens gåva. Returnerar sant
## om questen blev klar nu.
func battle_won() -> bool:
	var r := current_room()
	battle_pending = false
	next_auras.clear()
	next_rules.clear()
	var before: bool = quest.get("done", false)
	if r.get("nemesis", false) and quest.get("type", "") == "hunt":
		_quest_step()
	if r.get("kind", "") in ["elite", "portal_battle"] and quest.get("type", "") == "clear":
		_quest_step()
	_after_room()
	return quest.get("done", false) and not before


func _quest_step() -> void:
	quest.progress = mini(int(quest.progress) + 1, int(quest.goal))
	if quest.progress >= quest.goal:
		quest.done = true


## Efter ett rum: i en portal går man vidare till nästa sidorum, sedan tillbaka till kartan.
func _after_room() -> void:
	if side_index >= 0:
		side_index += 1
		if side_index >= map.room(room_id).side.size():
			side_index = -1


## Sant när våningens slut är vunnet.
func floor_cleared() -> bool:
	return map != null and room_id == map.end.id and side_index < 0 and not battle_pending


## Nästa våning, eller körningen klar efter den sista.
func next_floor(data: Dictionary) -> void:
	if is_last_floor():
		finished = true
		return
	floor += 1
	start_floor(data)


## Lägereld: +CAMPFIRE_CHARGES på varje förmåga (högst till max).
func campfire(data: Dictionary) -> int:
	var gained := 0
	for hero_id in charges:
		for ability_id in charges[hero_id]:
			var full := int(data.abilities[ability_id].get("charges", 0))
			var add := mini(CAMPFIRE_CHARGES, full - int(charges[hero_id][ability_id]))
			if add > 0:
				charges[hero_id][ability_id] += add
				gained += add
	_after_room()
	return gained


## Skattkammare: silver (andel av våningens belöning) och ibland en trofé ur samma Realm.
## Returnerar {silver, trophy}.
func treasure(data: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var out := {"silver": roundi(Profile.reward(floor, depth) * TREASURE_SILVER), "trophy": ""}
	var chance := TREASURE_TROPHY_CHANCE + (PORTAL_TROPHY_BONUS if side_index >= 0 else 0.0)
	if rng.randf() < chance:
		var pool := []
		for enc_id in floor_ids:
			for kind in data.encounters[enc_id].enemies:
				var t: String = data.enemies[kind].get("trophy", "")
				if t != "" and not data.enemies[kind].get("boss", false) and not trophies.has(t) and not pool.has(t):
					pool.append(t)
		if not pool.is_empty():
			out.trophy = pool[rng.randi() % pool.size()]
	_after_room()
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
	if quest.get("type", "") == "purify":
		_quest_step()
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
	_after_room()
	return text


# --- Sparning (user://run.cfg) -------------------------------------------------

const SAVED_FIELDS := ["oath", "perks", "floor", "realm", "floor_ids", "instability", "rules_visible", "rules_hidden",
		"rules_revealed", "depth", "equipped", "charges", "artifacts", "run_seed", "room_id", "visited",
		"side_index", "quest", "next_auras", "next_rules", "finished", "trait_totals", "found", "battle_pending", "prisoners",
		"barks_used", "first_descent"]


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
	if not d.get("map", {}).is_empty():
		s.map = RoomMap.from_dict(d.map)
	if not d.has("battle_pending") and s.map != null and s.room_id != "":
		# Sparad före 0.20.2: står man i ett stridsrum vet vi inte om det vanns, så striden spelas igen.
		s.battle_pending = is_battle(s.current_room())
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
