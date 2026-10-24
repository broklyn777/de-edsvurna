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
## Realm (Siralim): "crypt", "chapel" eller "grove" (data/realms.json) och dess våningar.
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
## 0.30.17: körningens löfte (data/vows.json, docs/plan/loften.md): "" = inget. Brutet blir det den ödmjuka formen;
## vow_used = den ödmjuka formens gång per körning är förbrukad. commons_fought räknar vanliga grupper på våningen.
var vow := ""
var vow_broken := false
var vow_used := false
var vow_breaks_on := ""
var vow_max_commons := 0
var commons_fought := 0
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
## 0.28.2: rutor som ett föremål har avslöjat (syns som besökta men är inte gångna; gruppen spärrar först när den setts).
var revealed: Array = []
## 0.28.2: nästa strid är starkare (glasfönstret); 1.0 = som vanligt.
var next_stat_mult := 1.0
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
## 0.24: replikerna som redan har sagts den här körningen (Dialog.bark upprepar dem inte). Replikminnet: nycklar
## (Dialog.line_key), inte texter.
var barks_used: Array = []
## Replikernas budget (levande repliker steg 3, vårt val): högst BARK_BUDGET per nedstigning, aldrig i två rum i rad
## (rooms_entered räknar nya rutor och våningar; bark_room = rummet med den senaste repliken). Starka lägen (STRONG_BARKS)
## går före både budgeten och spärren. Vanliga lägen sägs med BARK_CHANCE. Tystnad hellre än upprepning.
const BARK_BUDGET := 5
const STRONG_BARKS := ["boss", "fallen", "alone", "rare_find", "rescue", "new_realm"]
const BARK_CHANCE := {"cave": 0.6, "elite": 0.6, "back": 0.4, "treasure": 0.5, "stairs": 0.6, "hard_fight": 0.7,
		"campfire": 0.8}
var barks_said := 0
var bark_room := -10
var rooms_entered := 0
## 0.24: profilens första nedstigning (FIRST_DESCENT_RAMP).
var first_descent := false
## 0.25.1: den som ansluter när sällskapet är tillbaka på rumskartan (Imma som smiter efter den första striden), eller "".
## Segerskärmen visar bara dem som var med i striden; anslutningen görs först på kartan (join_waiting).
var joins_next := ""
## 0.23: fångar på våningarna, floor (som text) -> {hero, first}. Den första är tidig och obevakad.
var prisoners := {}
## Den levande kartan (prov, LivingMap): Realmens fördärv 0–4 när körningen började, och den förvridna bossens möte
## ("" om den inte har vaknat). Vunna strider i körningen och om den sista våningens quest (Realm Quest) är klar.
var growth := LivingMap.GROWTH_START
var twisted := ""
var wins := 0
var realm_quest_done := false
## Krönikan (Chronicle.begin): profilen när körningen började och det som bara striden vet (vem som föll, sällsynta fynd).
var chron := {}
## Den levande världen (WorldEvents.apply_to_run): Charges på helningsförmågorna (+1/−1), och händelsernas styrka i
## Realmen (bossen efter en svart mässa, alla grupper när gravklockan fick ringa).
var world_heal_mod := 0
var world_boss_mult := 1.0
var world_stat_mult := 1.0
## Pilgrimens rykte (WorldEvents.begin_run): den första våningens questmål syns från start.
var world_rumour := false


## En ny körning från basen: Kallet och sällskapet från Kryptporten, artefakterna från Smeden.
static func new_run(profile: Profile, data: Dictionary) -> RunState:
	var s := RunState.new()
	s.oath = profile.oath
	s.perks = profile.active_perks(data, profile.oath)
	s.party = profile.party.duplicate()
	s.artifacts = profile.artifacts.duplicate(true)
	s.depth = profile.depth
	s.set_realm(data, profile.realm)
	s.set_growth(data, LivingMap.growth(profile, profile.realm))
	s.fill_charges(data)
	WorldEvents.apply_to_run(s, profile, data)
	if profile.intro_done:
		s.set_vow(data, profile.vow)
	s.owned_heroes = profile.recruited.size() + 1
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


## 0.29.5: Övningsgårdens strid. En elitgrupp (realms.json "elite_pools") får samma nivå och motdrag som i grottan
## (våning 1: tier 1, våning 2: tier 2); Realmens vanliga möten som förut.
func practice_opts(data: Dictionary) -> Dictionary:
	var opts := {"rules": active_rules(), "instability": instability, "floor": floor}
	var pools: Array = data.get("realms", {}).get(realm, {}).get("elite_pools", [])
	for i in pools.size():
		if (pools[i] as Array).has(practice_encounter):
			opts.floor = mini(i + 1, 2)
			opts.counter = true
	return opts


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


## Trollberget (vårt val): en Realm med "requires" {realm, depth} i realms.json öppnas på kampanjkartan först när den
## Realmen är klarad på det djupet (Profile.realm_depth). Utan "requires" är Realmen alltid öppen.
static func realm_open(profile: Profile, data: Dictionary, realm_id: String) -> bool:
	var req: Dictionary = data.get("realms", {}).get(realm_id, {}).get("requires", {})
	return req.is_empty() or int(profile.realm_depth.get(String(req.realm), 0)) >= int(req.get("depth", 1))


## Raden som kampanjkartan visar under en stängd Realm.
static func realm_lock_text(data: Dictionary, realm_id: String) -> String:
	var req: Dictionary = data.realms[realm_id].get("requires", {})
	if req.is_empty():
		return ""
	var other: Dictionary = data.realms.get(String(req.realm), {})
	return "Öppnas när %s är klarat på djup %d" % [String(other.get("short", req.realm)).to_lower(), int(req.get("depth", 1))]


func set_realm(data: Dictionary, realm_id: String) -> void:
	if data.get("realms", {}).has(realm_id):
		realm = realm_id
		floor_ids = data.realms[realm_id].floors


## Den levande kartan: Realmens fördärv för körningen. På steg 4 tar den förvridna bossen den vanligas plats.
func set_growth(data: Dictionary, g: int) -> void:
	growth = clampi(g, 0, LivingMap.GROWTH_MAX)
	twisted = ""
	var enc := LivingMap.twisted_encounter(data, realm)
	if growth >= LivingMap.GROWTH_MAX and enc != "" and data.encounters.has(enc):
		floor_ids = floor_ids.duplicate()
		floor_ids[floor_ids.size() - 1] = enc
		twisted = enc


## Roterande väktare (docs/plan/mot-upprepning.md §1, VD 2026-10-24): Realmens bossplats växlar med djupet så att man
## inte möter samma boss i slutet av varje djup. realms.json "guardians" är en lista möten; cykeln är [huvudbossen] +
## guardians och djup d tar cykel[(d − 1) % storlek]. Med två väktare: huvudbossen på djup 1, 4, 7 …, den första väktaren
## på 2, 5, 8 … och den andra på 3, 6, 9 …. Samma djup ger alltid samma väktare. "" = huvudbossen (inga väktare).
## Väktarnas fiender är inte bossar: bosstroféer, Profile.boss_wins, smörjelsen och berättarrutan hör till huvudbossen.
static func guardian_for(data: Dictionary, realm_id: String, at_depth: int) -> String:
	var list: Array = data.get("realms", {}).get(realm_id, {}).get("guardians", [])
	if list.is_empty():
		return ""
	var i := posmod(maxi(at_depth, 1) - 1, list.size() + 1)
	return "" if i == 0 else String(list[i - 1])


## Mötet på den sista våningens bossruta: den förvridna bossen (fördärv 4) går före, sedan djupets väktare, annars
## huvudbossen (det sista mötet i floor_ids).
func boss_encounter(data: Dictionary) -> String:
	var main: String = floor_ids[floor_ids.size() - 1]
	if twisted != "":
		return main
	var g := guardian_for(data, realm, depth)
	return g if g != "" and data.encounters.has(g) else main


## Sant när bossrutan leds av en roterande väktare (inte huvudbossen).
func guardian_room(r: Dictionary) -> bool:
	return r.get("boss", false) and r.get("guardian", false)


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
		if hero_id == "paladin" and vow_trait(data) != "":
			list.append(vow_trait(data))
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
	if vow_kept(data):
		m += float(data.vows[vow].get("silver", 0.0))
	return m


## Troféerna som erbjuds efter att våningen är vunnen: elittroféer från besegrade elitvarianter
## (alltid), sedan från monstren i striden och påfyllnad ur samma Realm. Bosstroféer bara om bossen
## är besegrad BOSS_WINS_FOR_TROPHY gånger (unlocked_bosses). Elittroféerna och den första vanliga är
## säkra, resten kommer med trophy_chance(depth, instabilitet).
func trophy_offer(data: Dictionary, rng: RandomNumberGenerator, elites: Array = [],
		unlocked_bosses: Array = []) -> Array[String]:
	var sure: Array[String] = []
	# Den levande kartan: den förvridna bossen lämnar alltid sin trofé (den visar sig bara på steg 4).
	for kind in CombatSim.enemy_lineup(data, data.encounters[encounter()].enemies, party.size()):
		var tt: String = data.enemies[kind].get("trophy", "")
		if data.enemies[kind].get("twisted", false) and tt != "" and not trophies.has(tt):
			sure.append(tt)
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
	var chance := minf(1.0, trophy_chance(depth, instability) + LivingMap.trophy_bonus(growth))
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
	# trofeplats: en trofé som sitter i en artefakt bärs inte samtidigt (byts hos Smeden).
	if trophy_id != "" and artifacts.values().any(func(a: Dictionary) -> bool: return String(a.get("trophy", "")) == trophy_id):
		return
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
## Benfursten en riktig utmaning. Mätt med botarna (BALANS=forsta), docs/formler.md §9. elit-balans: 0,81 → 0,83 när
## bossmötena blev mildare (BALANS=grotta: första nedstigningen 71–79 %).
const FIRST_DESCENT_RAMP := [0.70, 0.88, 0.83]
## 0.28 (vårt val): elitgruppen på våning 1 är mildare på profilens första nedstigning, eftersom en Jakt på Nemesis kan
## tvinga en ny spelare att möta den. Mötet kan ha en egen styrka, "first_descent_stat_mult" (ersätter stat_mult,
## CombatSim), annars gäller den här faktorn.
const FIRST_DESCENT_ELITE := 0.8
## 0.30.19 (vårt val): samma mildring för ett sällskap med högst två hjältar, också efter den första nedstigningen.
## Karriärbotarna (docs/provspel/svarighetskurva.md) förlorade 74 % av den andra nedstigningen, de flesta vid våning 1:s
## elitgrupp eller Nemesis, med Paladinen och Imma på nivå 5 mot djup 2.
const SMALL_PARTY_ELITE := 0.8
## 0.30.21: hur många hjältar profilen äger (Paladinen + lärjungarna). Med fyra eller fler balanseras striderna mot
## fyra oavsett hur många man tar med (CombatSim "full_party"); färre är spelarens eget val.
var owned_heroes := 0
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
## Rensa kräver en elitgrupp på den första våningen och två på den andra (elit-balans, vårt val: våning 1 ska inte
## tvinga fram två elitstrider innan sällskapet hunnit växa).
static func roll_quest(rng: RandomNumberGenerator, floor_i := 1) -> Dictionary:
	var type: String = QUEST_TYPES[rng.randi() % QUEST_TYPES.size()]
	var q := {"type": type, "progress": 0, "done": false}
	match type:
		"hunt":
			q.goal = 1
		"clear":
			q.goal = 1 if floor_i == 0 else 2
		"collect":
			q.goal = rng.randi_range(2, 3)
	return q


## Trollberget: en Realm kan ge questen ett eget namn (realms.json "quests" per typ, start_floor lägger det i "title"),
## som då står i stället för typens ord.
static func quest_text(q: Dictionary) -> String:
	var title := String(q.get("title", ""))
	match q.get("type", ""):
		"hunt":
			return "%s: besegra Nemesis (%d/%d)" % [title if title != "" else "Jakt", q.progress, q.goal]
		"clear":
			return "%s: besegra %d %s (%d/%d)" % [title if title != "" else "Rensa", q.goal, "elitgrupp" if q.goal == 1 else "elitgrupper", q.progress, q.goal]
		"collect":
			return "%s: ta %d bevakade föremål (%d/%d)" % [title if title != "" else "Samla", q.goal, q.progress, q.goal]
	return ""


## Lägger våningens grotta och quest ur fröet. Grupperna kommer ur Realmens pooler (tier 0–2 efter våning och avstånd).
func start_floor(data: Dictionary) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = run_seed * 977 + floor * 31 + 13
	quest = roll_quest(rng, floor)
	var titles: Dictionary = data.realms[realm].get("quests", {})
	if titles.has(quest.type):
		quest.title = titles[quest.type]
	commons_fought = 0
	trail_taken = false
	var pools: Array = data.realms[realm].get("pools", [])
	if pools.is_empty():
		pools = [floor_ids]
	var boss := boss_encounter(data)
	var guard: String = floor_ids[mini(floor, floor_ids.size() - 2)] if floor_ids.size() > 1 else ""
	map = Grotto.generate(run_seed * 101 + floor * 7 + 1, floor, is_last_floor(), pools, boss, guard, quest,
			prisoners.get(str(floor), {}), data.realms[realm].get("elite_pools", []), data.realms[realm].get("objects", []))
	if is_last_floor() and boss != floor_ids[floor_ids.size() - 1]:
		map.cells[map.goal].guardian = true  # en roterande väktare leder bossstriden (kortet, förlusttipsen)
	pos = map.start
	visited = [map.start]
	rooms_entered += 1
	seen = []
	revealed = []
	came_from = -1
	battle_pending = false
	_roll_hints(rng)


## 0.30.22 Ledtråd (docs/plan/nya-grottor.md A, Siralims quests som pekar ut en plats): varje mål för questen (Nemesis,
## elitgrupperna, föremålen) får ett rykte på kartan, en ring över ett 3×3-område där målet står. Exakt ruta stannar
## under dimman. [{center, target}]
var quest_hints: Array = []


func quest_targets() -> Array[int]:
	var out: Array[int] = []
	if map == null:
		return out
	var type: String = quest.get("type", "")
	for i in map.cells.size():
		var c: Dictionary = map.cells[i]
		if (type == "hunt" and c.get("nemesis", false)) or (type == "clear" and c.get("elite", false) and c.has("encounter")) \
				or (type == "collect" and c.get("kind", "") == "item"):
			out.append(i)
	return out


func _roll_hints(rng: RandomNumberGenerator) -> void:
	quest_hints = []
	for t in quest_targets():
		var p := Grotto.xy(t)
		var c := Vector2i(clampi(p.x + rng.randi_range(-1, 1), 1, Grotto.SIZE - 2),
				clampi(p.y + rng.randi_range(-1, 1), 1, Grotto.SIZE - 2))
		quest_hints.append({"center": Grotto.idx(c), "target": t})


## Pilgrimens rykte (den levande världen, kapellet trycktes tillbaka): varje mål för den här våningens quest syns
## genom dimman från start, inte bara ringen runt det. Ringarna försvinner då av sig själva (active_hints).
func apply_rumour() -> void:
	if map == null:
		return
	world_rumour = true
	for t in quest_targets():
		if not visited.has(t) and not revealed.has(t):
			revealed.append(t)


## Ryktena som fortfarande gäller: målet är varken hittat eller klart.
func active_hints() -> Array:
	if map == null or quest.get("done", false):
		return []
	return quest_hints.filter(func(h: Dictionary) -> bool:
		var t := int(h.target)
		var c := map.cell(t)
		return not (visited.has(t) or seen.has(t) or revealed.has(t) or c.get("beaten", false) or c.get("done", false)))


## 0.30.22 Spåren (nya-grottor.md B, vårt val): den som går ned när questen är klar får en del av erfarenheten och
## silvret från de vanliga grupper som står kvar ("ni lärde er av spåren"), så att det inte alltid lönar sig att rensa allt.
## 0,75: botarna i kryptan vinner lika ofta direkt som när de rensar allt (0,5 för lite, 1,0 för mycket).
const TRAIL_SHARE := 0.75
var trail_taken := false


func take_trail(data: Dictionary) -> Dictionary:
	if trail_taken or map == null or practice:
		return {}
	trail_taken = true
	var groups := 0
	var silver := 0.0
	for c in map.cells:
		if c.get("kind", "") == "battle" and c.has("encounter") and not c.get("beaten", false) and is_common_group(c):
			groups += 1
			silver += Profile.reward(int(c.get("tier", floor)), depth) * BATTLE_SILVER
	if groups == 0:
		return {}
	return {"groups": groups, "xp": roundi(HeroStats.battle_xp("battle", depth) * TRAIL_SHARE * groups),
			"silver": silver * TRAIL_SHARE}


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
		rooms_entered += 1
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
	if battle_pending and is_common_group(current_room()):
		commons_fought += 1
		if vow_breaks_on == "commons" and not vow_broken and commons_fought > vow_max_commons:
			vow_broken = true


# --- Löften (0.30.17) ---------------------------------------------------------

func set_vow(data: Dictionary, vow_id: String) -> void:
	var v: Dictionary = data.get("vows", {}).get(vow_id, {})
	vow = vow_id if not v.is_empty() else ""
	vow_broken = false
	vow_used = false
	vow_breaks_on = String(v.get("breaks_on", ""))
	vow_max_commons = int(v.get("max_commons", 0))


## Löftets egenskap hos Paladinen i nästa strid: den hållna formen, den ödmjuka efter ett brott (om den inte är förbrukad).
func vow_trait(data: Dictionary) -> String:
	if vow == "":
		return ""
	var v: Dictionary = data.vows[vow]
	if not vow_broken:
		return String(v.get("held", ""))
	return "" if vow_used else String(v.get("humble", ""))


## Det som bara stridsmotorn behöver veta (Jag helar inte).
func apply_vow(data: Dictionary, opts: Dictionary) -> void:
	if vow != "" and not vow_broken and data.vows[vow].get("no_heal", false):
		opts.no_heal = true


## Efter en vunnen strid: bryts löftet av att någon föll, och förbrukades den ödmjuka formen? Ger "broke" om det brast nu.
func vow_after_battle(data: Dictionary, sim: CombatSim) -> String:
	if vow == "":
		return ""
	if vow_broken:
		var humble := String(data.vows[vow].get("humble", ""))
		if humble != "" and int(sim.trait_stats.get(humble, {}).get("procs", 0)) > 0:
			vow_used = true
		return ""
	if vow_breaks_on == "death" and sim.heroes.any(func(u: CombatUnit) -> bool: return u.deaths > 0):
		vow_broken = true
		return "broke"
	return ""


## Löftets namn som det står nu: "Ingen ska falla", eller den ödmjuka formen efter ett brott.
func vow_name(data: Dictionary) -> String:
	if vow == "":
		return ""
	var v: Dictionary = data.vows[vow]
	return String(v.get("humble_name", v.name)) if vow_broken else String(v.name)


func vow_kept(data: Dictionary) -> bool:
	return vow != "" and not vow_broken


## En vanlig grupp för Raka vägen: inte elit, Nemesis, boss eller en grupp som vaktar questens föremål.
static func is_common_group(r: Dictionary) -> bool:
	return not (r.get("elite", false) or r.get("nemesis", false) or r.get("boss", false) or r.get("kind", "") == "item")


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
	# 0.28.2: föremålens strider (sarkofagen, klockorna) och glasfönstrets beredda grupp.
	var mult := float(r.get("stat_mult", 1.0)) * next_stat_mult
	if mult != 1.0:
		opts.stat_bonus = mult
	if first_descent:
		opts.stat_bonus = first_descent_mult(tier) * mult
		if party.size() == 1:
			opts.stat_bonus *= FIRST_FIGHT_ALONE
		if floor == 0 and (r.get("elite", false) or r.get("nemesis", false)):
			opts.stat_bonus *= FIRST_DESCENT_ELITE
			opts.first_descent_elite = FIRST_DESCENT_ELITE
		elif r.get("elite", false) or r.get("nemesis", false):
			opts.first_descent_elite = 1.0  # våning 2: bara mötets egen styrka, om den finns
	if owned_heroes >= 4:
		opts.full_party = true
	elif not first_descent and party.size() <= 2 and floor == 0 and (r.get("elite", false) or r.get("nemesis", false)):
		opts.stat_bonus = float(opts.get("stat_bonus", 1.0)) * SMALL_PARTY_ELITE
	# Den levande kartan: Realmens fördärv (steg 2–4) gör alla grupper starkare, som en mildare instabilitet.
	var grown := LivingMap.stat_mult(growth)
	if grown != 1.0 and not first_descent:
		opts.stat_bonus = float(opts.get("stat_bonus", 1.0)) * grown
		opts.growth = growth
	# Den levande världen: en händelse som inte stoppades (bossen efter mässan, fler döda när klockan ringde).
	var world := world_stat_mult * (world_boss_mult if r.get("boss", false) else 1.0)
	if world != 1.0:
		opts.stat_bonus = float(opts.get("stat_bonus", 1.0)) * world
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
	next_stat_mult = 1.0
	r.beaten = true
	wins += 1
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
		if is_last_floor():
			realm_quest_done = true


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
	out.append({"kind": "blessing", "aura": SHRINE_AURAS[rng.randi() % SHRINE_AURAS.size()]})
	out.append({"kind": "chaos"})
	return out


static func shrine_text(data: Dictionary, o: Dictionary) -> String:
	match o.kind:
		"charge":
			return "+%d Charges: %s (%s)" % [o.amount, data.abilities[o.ability].name, data.heroes[o.hero].name]
		"blessing":
			return "Sällskapet börjar nästa strid med %s" % data.auras[o.aura].name
	return "Pandemonium: en slumpad effekt, bra eller dålig"


## Pandemoniums utfall (apply_shrine "chaos", samma ordning). Aurans namn ur datan.
## Helgedomens auror (strid-justering) varar hela nästa strid ("battle" i auras.json): förr tickade de bort vid ägarens
## första tur och var nästan värdelösa. Siffrorna är satta så att gåvan väger ungefär som +2 Charges på en förmåga.
const CHAOS_AURA := "shrine_holy_shield"
const SHRINE_AURAS := ["shrine_inspired", "shrine_warded"]


## Gåvans verkan i en rad, ur datan (aurans text och varaktighet, förmågans Charges), för knappen under namnet.
func shrine_detail(data: Dictionary, o: Dictionary) -> String:
	match o.kind:
		"charge":
			var full := int(data.abilities[o.ability].get("charges", 0))
			var now := int(charges.get(o.hero, {}).get(o.ability, 0))
			return "%d av %d kvar blir %d" % [now, full, now + int(o.amount)]
		"blessing":
			return aura_brief(data, o.aura, true)
	return "+1 Charge på allt, %s (%s), −1 Charge eller en våningsregel" % [
		data.auras[CHAOS_AURA].name, aura_brief(data, CHAOS_AURA, true, false)]


## Vad en aura gör, kort och ur datan: texten utan namnet ("tar 25 % mindre skada") och hur länge.
## at_start: auran ges före striden (Helgedomens gåva). Varaktigheten räknas i ägarens turer och tickar i början av
## turen (CombatSim._tick_turn_start), så 1 tur tar slut när var och en står på tur första gången ("fram till egen första tur").
static func aura_brief(data: Dictionary, aura_id: String, at_start := false, with_time := true) -> String:
	var d: Dictionary = data.auras.get(aura_id, {})
	var t := String(d.get("text", d.get("name", aura_id)))
	var colon := t.find(": ")
	if colon >= 0:
		t = t.substr(colon + 2)
	t = t.strip_edges().trim_suffix(".")
	if t.length() > 0:
		t = t[0].to_lower() + t.substr(1)
	var n := int(d.get("duration", -1))
	if with_time and d.get("battle", false):
		return t + (" hela nästa strid" if at_start else " hela striden")
	if not with_time or n <= 0 or t.contains("till nästa tur"):
		return t
	if at_start:
		if n == 1:
			return t + " fram till egen första tur"
		if n == 2:
			return t + " under egen första tur"
		return t + " under egna %d första turer" % (n - 1)
	return t + (", 1 tur" if n == 1 else ", %d turer" % n)


## Tar emot gåvan. Pandemonium slår om: +1 Charge på alla förmågor, Barriär till nästa strid, en
## förlorad Charge eller en våningsregel i nästa strid. Returnerar en text om vad som hände.
func apply_shrine(data: Dictionary, rng: RandomNumberGenerator, o: Dictionary) -> String:
	var text := shrine_text(data, o)
	match o.kind:
		"charge":
			charges[o.hero][o.ability] = int(charges[o.hero][o.ability]) + int(o.amount)
		"blessing":
			next_auras.append(o.aura)
			text += " (%s)" % aura_brief(data, o.aura, true)
		"chaos":
			match rng.randi() % 4:
				0:
					for hero_id in charges:
						for ability_id in charges[hero_id]:
							charges[hero_id][ability_id] = int(charges[hero_id][ability_id]) + 1
					text = "Pandemonium: +1 Charge på alla förmågor!"
				1:
					next_auras.append(CHAOS_AURA)
					text = "Pandemonium: sällskapet börjar nästa strid med %s (%s)!" % [data.auras[CHAOS_AURA].name,
							aura_brief(data, CHAOS_AURA, true)]
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


# --- Realmens föremål (0.28.2) ---------------------------------------------------

## Silvret i en vanlig skatt på den här våningen (föremålens belöningar räknas i sådana, "S").
func treasure_value() -> int:
	return roundi(Profile.reward(floor, depth) * TREASURE_SILVER)


## Valen för föremålet man står på: [{id, label, disabled?}].
func object_options(data: Dictionary) -> Array:
	var r := current_room()
	var def: Dictionary = data.get("objects", {}).get(r.get("obj", ""), {})
	var opts: Array = (def.get("again_options", []) if r.get("again", false) else def.get("options", [])).duplicate(true)
	if r.get("obj", "") == "hourglass" and (_richest_charge().is_empty() or scout_target() < 0):
		for o in opts:
			if o.id == "scout":
				o.disabled = true
	if r.get("obj", "") == "pew" and barricade_target() < 0:
		for o in opts:
			if o.id == "barricade":
				o.disabled = true
	return opts


## Timglaset: närmaste obesökta elitgrupp som inte redan syns, eller −1.
func scout_target() -> int:
	var best := -1
	for i in map.group_cells():
		var c := map.cell(i)
		if map.has_group(i) and (c.get("elite", false) or c.get("nemesis", false) or c.get("kind", "") == "elite") \
				and not visited.has(i) and not revealed.has(i):
			if best < 0 or Grotto.dist(i, pos) < Grotto.dist(best, pos):
				best = i
	return best


## Förmågan med flest Charges kvar i sällskapet: {hero, ability} eller {}.
func _richest_charge() -> Dictionary:
	var out := {}
	var most := 0
	for hero_id in charges:
		for ability_id in charges[hero_id]:
			if int(charges[hero_id][ability_id]) > most:
				most = int(charges[hero_id][ability_id])
				out = {"hero": hero_id, "ability": ability_id}
	return out


## Kyrkbänken: närmaste vanliga grupp man har sett (inte elit, Nemesis, boss eller en vakt), eller −1.
func barricade_target() -> int:
	var best := -1
	for i in seen:
		var c := map.cell(i)
		if map.has_group(i) and c.get("kind", "") == "battle" and not c.get("elite", false) and not c.get("nemesis", false):
			if best < 0 or Grotto.dist(i, pos) < Grotto.dist(best, pos):
				best = i
	return best


## Gör ett val vid föremålet. Returnerar {text, fight (en strid börjar på rutan), silver (att betala ut)}.
func use_object(data: Dictionary, choice: String, rng: RandomNumberGenerator) -> Dictionary:
	var r := current_room()
	var out := {"text": "", "fight": false, "silver": 0}
	# 0.31: ett föremål kan låna ett annat föremåls val med egen text ("results" i objects.json, Lundens föremål).
	var results: Dictionary = data.get("objects", {}).get(r.get("obj", ""), {}).get("results", {})
	var tier := mini(floor + (1 if Grotto.dist(pos, map.start) >= Grotto.FAR_TIER_DIST else 0), 2)
	var pools: Array = data.realms[realm].get("pools", [floor_ids])
	var pool: Array = pools[clampi(tier, 0, pools.size() - 1)]
	match choice:
		"leave", "stop":
			if choice == "stop":
				r.done = true
				r.again = false
			return out
		"knock", "ring", "ring_again":
			r.encounter = pool[rng.randi() % pool.size()]
			r.tier = tier
			r.beaten = false
			r.stat_mult = {"knock": 1.15, "ring": 1.15 if r.obj == "bell_rope" else 1.0, "ring_again": 1.25}[choice]
			r.obj_reward = {"knock": 2.0, "ring": 0.0 if r.obj == "bell_rope" else 1.0, "ring_again": 2.0}[choice]
			r.again = false
			if not seen.has(pos):
				seen.append(pos)
			out.fight = true
		"valuables", "neighbours":
			var want := func(i: int) -> bool:
				var c := map.cell(i)
				if choice == "valuables":
					return c.get("kind", "") == "treasure" and not c.get("done", false)
				return map.has_group(i) and not c.get("boss", false)
			var found: Array = range(map.cells.size()).filter(func(i: int) -> bool:
				return not visited.has(i) and not revealed.has(i) and want.call(i))
			found.sort_custom(func(a: int, b: int) -> bool: return Grotto.dist(a, pos) < Grotto.dist(b, pos))
			for i in found.slice(0, 2):
				revealed.append(i)
			r.done = true
			out.text = "%s %d %s." % [results.get("found", "Registret pekar ut"), mini(found.size(), 2),
					"skatter" if choice == "valuables" else "grupper"] \
					if not found.is_empty() else results.get("none", "Registret har inget nytt att berätta.")
		"pull":
			var row := Grotto.xy(pos).y
			for x in Grotto.SIZE:
				var i := Grotto.idx(Vector2i(x, row))
				if not visited.has(i) and not revealed.has(i):
					revealed.append(i)
			next_stat_mult = 1.15
			r.done = true
			out.text = results.get("pull", "Ljuset faller över hela raden. Nästa grupp ni möter är beredd (+15 % styrka).")
		"scout":
			var t := scout_target()
			var paid := _richest_charge()
			if t < 0 or paid.is_empty():
				return out
			charges[paid.hero][paid.ability] = int(charges[paid.hero][paid.ability]) - 1
			revealed.append(t)
			var names: Array = data.encounters[map.cells[t].encounter].enemies.map(func(k: String) -> String: return data.enemies[k].name)
			r.done = true
			out.text = "Sanden visar en elitgrupp: %s. (%s gav en Charge av %s.)" % [", ".join(names),
					data.heroes[paid.hero].name, data.abilities[paid.ability].name]
		"barricade":
			var t := barricade_target()
			if t < 0:
				return out
			map.cells[t].beaten = true
			map.cells[t].barricaded = true
			r.done = true
			out.text = "Bänken spärrar vägen för gruppen. Den ger er ingenting – men den är borta."
		"wood":
			out.silver = treasure_value()
			r.done = true
			out.text = "Gedigen ek: +%d silver." % out.silver
	return out


## Efter en seger vid ett föremål: belöningen i silver och vad som händer sedan (klockan kan ringa igen). Returnerar
## {silver, text}.
func object_won() -> Dictionary:
	var r := current_room()
	var out := {"silver": roundi(treasure_value() * float(r.get("obj_reward", 0.0))), "text": ""}
	match r.get("obj", ""):
		"grave_bell":
			if float(r.get("stat_mult", 1.0)) < 1.2:
				r.again = true  # första gången: kan ringa igen
			else:
				r.done = true
		"bell_rope":
			for i in map.group_cells():
				if map.has_group(i) and not visited.has(i) and not revealed.has(i):
					revealed.append(i)
			r.done = true
			out.text = "Klockan har ljudit: nu vet ni var alla grupper står."
		_:
			r.done = true
	r.erase("stat_mult")
	return out


# --- Replikernas budget ---------------------------------------------------------

## Sant om ett läge får ge en replik nu (budgeten, två rum i rad, chansen).
func bark_allowed(kind: String, rng: RandomNumberGenerator) -> bool:
	if STRONG_BARKS.has(kind):
		return true
	if barks_said >= BARK_BUDGET or rooms_entered - bark_room <= 1:
		return false
	return rng.randf() < float(BARK_CHANCE.get(kind, 1.0))


func note_bark() -> void:
	barks_said += 1
	bark_room = rooms_entered


# --- Sparning (user://run.cfg) -------------------------------------------------

const SAVED_FIELDS := ["oath", "perks", "floor", "realm", "floor_ids", "instability", "rules_visible", "rules_hidden",
		"rules_revealed", "depth", "equipped", "charges", "artifacts", "run_seed", "pos", "visited", "seen", "came_from",
		"side_index", "quest", "next_auras", "next_rules", "finished", "trait_totals", "found", "battle_pending", "prisoners",
		"barks_used", "barks_said", "bark_room", "rooms_entered", "first_descent", "joins_next", "revealed", "next_stat_mult", "vow", "vow_broken", "vow_used",
		"vow_breaks_on", "vow_max_commons", "commons_fought", "owned_heroes", "quest_hints", "trail_taken", "growth", "twisted",
		"wins", "realm_quest_done", "chron", "world_heal_mod", "world_boss_mult", "world_stat_mult", "world_rumour"]


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
