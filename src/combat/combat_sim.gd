class_name CombatSim
extends RefCounted
## Turordningsstrid utan noder, med Siralims tidslinje: snabbheten avgör startplatsen, den som har
## agerat läggs längst ned och kön roterar. Det finns inga rundor.
##
## Flöde: create() → begin() → så länge outcome == "":
##   needs_input() → hjälten som har turen väntar på act(action, target, ability) – från spelaren
##                   eller från ett makro (MacroRunner.decide)
##   annars        → ai_act() låter AI:n agera (fiender, och hjältar när auto är på)
## Töm händelserna med drain_events() och spela upp dem.
##
## Händelser (Dictionary med "type"):
##   battle_start {} – innan första turen (Siralims "när striden börjar")
##   turn_start {unit}
##   action {unit, action, ability, targets}
##   damage {source, target, amount, absorbed, crit, school, kind, ability, direct} – amount är förlorat liv,
##          absorbed det Barrier tog. Bara skada på livet sätter igång egenskaper (Siralim).
##   dodge {source, target, ability} – målet undvek en attack
##   immune {source, target, ability} – målet kan inte skadas just nu (t.ex. Kultens sköld)
##   rule {rule} – en våningsregel slog till första gången i striden (dolda regler avslöjas då)
##   elite {unit} – en elitvariant finns i striden (före battle_start)
##   heal {source, target, amount, effective, overheal, crit, ability}
##   revive {unit}
##   charge_restored {unit, ability, amount}
##   limit {unit, kind} – en egenskap stoppades av gränsen per tur
##
## Skada har en typ ("kind": attack, spell, indirect) skild från skolan (physical, holy, fire,
## shadow). Ett följdanfall från en egenskap är en attack om inget annat sägs.
##   aura_applied {unit, aura, refreshed} / aura_removed {unit, aura}
##   death {unit}
##   trait {unit, trait} – en egenskap slog till (händelser den orsakar bär fältet "trait")
##   release {unit, trait, stack, amount} – en förmåga förbrukade en egenskaps uppladdade staplar
##   outcome {result: victory|defeat}
##   acted {unit, action, ability, targets} – efter att handlingen verkat (artefakter lyssnar på den)
##
## Artefakter (som i Siralim): en per hjälte. Typen höjer en stat och avgör när förmågan i den slår
## till: svärd vid Anfall, stav vid Förmåga, sköld vid Försvara, hjälm vid Provocera, stövlar i
## början av turen. Byggs som en egenskap ("artifact_<hjälte>") med effekten "cast", som kastar
## förmågan utan att kosta Charges. Händelsen har action "artifact".

## Siralims skadeformler (wiki: Combat, bekräftade):
##   Attack   = (max(Attack − Defense, 0) + 1 % · Attack) × modifierare + tillägg
##   Spell    = max(Potency − Defense, 0) × modifierare + tillägg, Potency = Int × nivåns procent
##   Indirect = skada × modifierare − 20 % · Defense (ingen krit, inget undvikande)
## Ökningar adderas, minskningar multipliceras och varje minskning stannar vid 80 %.
## "power" i förmågorna är modifieraren. Spells nivå ("tier") ger Potency och hur mycket Defense
## som ignoreras: [Potency, ignorerad Defense].
const SPELL_TIERS := {"small": [0.9, 0.0], "moderate": [1.1, 0.1], "large": [1.2, 0.2],
		"massive": [1.3, 0.3], "devastating": [1.5, 0.4]}
const ATTACK_FLOOR := 0.01
const INDIRECT_DEFENSE := 0.2
const REDUCTION_CAP := 0.2
## VAL: Siralim har ingen publicerad spridning; vi slår ±10 % på Attack, Int och helningar.
const VARIANCE := 0.1
## VAL (formeln är inte publicerad, se docs/research/siralim.md §12): krit och undvikande räknas
## på kvoten mellan egen och målets Speed.
const CRIT_CHANCE_PER_DOUBLING := 0.1
const CRIT_CHANCE_MAX := 0.5
const DODGE_PER_DOUBLING := 0.1
const DODGE_MAX := 0.3
## Med egenskaper ("dodge_add") kan undvikandet bli högst så här stort.
const DODGE_TRAIT_MAX := 0.75
## Realm Depth (Siralim): fiendernas Health, Attack, Intelligence och Defense växer med en andel per
## djup över 1 (3 %; balans v2 2026-10-26 prövade 5, 8 och 15 %: allt över 3 % gav väggen vid djup 4–6 hos karriärbotarna,
## eftersom fienderna och hjältarna nu delar styrkekurvan och 3 % håller kvoten från förr på djup 4–9; 3 % i 0.30.33, 8 % före det,
## som lades ovanpå fiendernivåerna och gav väggen vid djup 5–6, docs/provspel/djupsteg-matning.md; docs/balans/balanslogg.md). Speed skalar inte (tidslinjen ska vara densamma). Mötet kan ha en egen "stat_mult"
## (våning 2 och 3 är starkare än 1, som i Siralim där fienderna skalar snabbare än laget).
const DEPTH_STEP := 0.03
## Botarnas mätning (DJUPSTEG=0.03 i soak/balance): ändrar steget utan att ändra spelets värde.
static var depth_step := DEPTH_STEP
const SCALED_STATS := ["health", "attack", "intelligence", "defense"]
## 0.26: talen börjar små som i Siralim (grundvärdena delades med 10). Health, Attack, Intelligence och Defense har därför
## en decimal (förut heltal, samma upplösning i förhållande till värdet); Speed är kvar i heltal. Skada och helning
## räknas med decimaler och avrundas en gång till heltal på slutet.
const STAT_STEP := 0.1


static func snap_stat(v: float) -> float:
	return roundf(v * 10.0) / 10.0
## Elitvarianter (0.17, som Siralims sällsynta varelser): chans och styrka.
const ELITE_CHANCE := 0.05
const ELITE_PER_DEPTH := 0.01
const ELITE_PER_INSTABILITY := 0.03
const ELITE_MAX := 0.3
const ELITE_HEALTH := 1.25
const ELITE_POWER := 1.1
## Våningsreglernas styrka (data/floor_rules.json beskriver dem).
const RISEN_DEAD_HP := 0.1
const VIGILANT_CHANCE := 0.3
const CURSED_GROUND := 0.02
## Säkerhetsgräns för hur djupt egenskaper kan sätta igång varandra.
const MAX_TRAIT_CHAIN := 10
## Som i Siralim: per figur och pågående tur får egenskaper utlösa högst så många attacker,
## besvärjelser och mottagna helningar, plus en övergripande gräns.
const TURN_LIMIT := 5
## 0.23: fiendernas styrka efter sällskapets storlek (1–4 hjältar). Vårt val, mätt med botarna. 0.30.21 (VD): bara när
## profilen äger färre än fyra hjältar; den som har fyra och väljer färre möter fiender som mot fyra
## (opts "full_party", även antalet fiender).
## Prototyp (sallskap-fem): fem hjältar (Trollberget och senare, eller fem i en lägre Realm) mot ×PARTY_SCALE[5].
const PARTY_SCALE := {1: 0.45, 2: 0.54, 3: 0.64, 4: 1.0, 5: 1.0}
## Balans v1 (VD 2026-10-25): fem hjältar i en Realm byggd för fyra (kryptan, kapellet, lunden) på det djupaste djupet
## (RunState.full_party_size, opts "five_in_four"): fiendernas Health, Attack och Intelligence gånger så här mycket, eftersom
## de mötena saknar Trollbergets "extra". Mätt med balanssimuleringen.
const FIVE_IN_FOUR := 1.4
static var five_in_four := FIVE_IN_FOUR  # balanssimuleringens prov (FEM_I_FYRA)
## Största sällskapet striden har platser och skalning för.
const MAX_HEROES := 5
const TURN_PROC_LIMIT := 60
## Handlingar en hjälte kan göra på sin tur ("ability" kräver vilken förmåga).
const ACTIONS := ["attack", "ability", "defend", "provoke", "skip"]
## Platser på slagfältet (sim-enheter, se UnitModel.to_world). Bara utseende.
const HERO_SLOTS := [Vector2(-95, 10), Vector2(-150, -75), Vector2(-165, 95), Vector2(-230, 15),
		Vector2(-240, -110), Vector2(-250, 130)]
const ENEMY_SLOTS := [Vector2(105, 5), Vector2(160, -80), Vector2(170, 90), Vector2(235, 0),
		Vector2(280, -150), Vector2(290, 150)]  # 5:e och 6:e längre ut (sallskap-fem: färre överlappande namn)

var data: Dictionary
var units: Array[CombatUnit] = []
var heroes: Array[CombatUnit] = []
var enemies: Array[CombatUnit] = []
var turn_no := 0
## Tidslinjen efter den som har turen: kön av levande figurer, i ordning.
var order: Array[String] = []
var current: CombatUnit
var outcome := ""
var events: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()
## När sant spelar AI:n även hjältarna.
var auto := false
## Realm Depth (1 och uppåt).
var depth := 1
## Djupet fiendernas nivå och stats räknas på: depth + opts "depth_offset" (realms.json "depth_offset", 0.30.25; Trollbergets
## djup 1 är djup 4). Motdrag och elitvarianter följer depth.
var enemy_depth := 1
## Våningsregler (data/floor_rules.json) som gäller i striden, och de som har slagit till.
var rules: Array = []
var rules_triggered: Array = []
## Auror som sällskapet får när striden börjar (Helgedomens gåva).
var _start_auras: Array = []

var _by_id := {}
var _trait_ctx := ""
## Händelsen som satte igång den egenskap som körs just nu (för "origin_target_has_aura").
var _origin := {}
var _trait_depth := 0
## Medan en förmåga förbrukar laddningar: {unit, ability, mult} för skadebonusen.
var _release_bonus := {}
## unit_id -> {attack, spell, heal} under den pågående turen.
var _turn_counts := {}
var _turn_procs := 0
## Vad varje egenskap har gjort i striden (för kvittot): trait_id -> {unit, procs, damage, heal}.
var trait_stats := {}
## 0.30: förmåga → {unit, aura, count, extra} för träffar som fick en kombinationsbonus.
var combo_stats := {}
## 0.27: senaste figuren per lag som kastade en besvärjelse (pick "caster"), och väckningar per lag (Sista klangen).
var _last_caster := {}
var _team_revives := {}
## 0.28: helningar per lag under den pågående turen (Ordensregeln).
var _team_heals := {}
## strid-langd: hur många turer varje fiende har helat med varje förmåga eller egenskap ("källa:förmåga" → {n, turn}).
var _enemy_heals_by := {}


## party: hjältar som ersätter mötets förvalda; traits: hero_id -> [trait_id, …] som ersätter
## hjältens förvalda egenskaper; charges: hero_id -> {ability_id: kvar} (annars fulla);
## artifacts: hero_id -> {type, ability}; depth: Realm Depth som skalar fienderna.
## opts: {"rules": [regel-id], "instability": n, "elite_chance": andel (annars elite_chance()),
##   "force_elites": n (de n första vanliga fienderna blir elit – Elit-rum och Nemesis), "nemesis": true
##   (den första eliten heter Nemesis), "stat_bonus": extra skalning (Portalens strid),
##   "start_auras": [aura] som sällskapet börjar med (Helgedomens gåva), "boss_traits": [trait] som bossen (annars
##   den första fienden) får (sigillen som lämnades, RunState.boss_seals), "first_descent_elite": faktorn som redan
##   ligger i stat_bonus för elitgruppen på första nedstigningen (byts mot mötets "first_descent_stat_mult"),
##   "levels": {hero_id: {level, personality}} (0.19) – hjältarnas nivåer; då har fienderna en nivå efter
##   djupet och "floor" (0–2, HeroStats.enemy_level), också i Speed}.
static func create(game_data: Dictionary, encounter_id: String, seed_value := 1,
		party: Array = [], traits := {}, charges := {}, artifacts := {}, depth := 1, opts := {}) -> CombatSim:
	var sim := CombatSim.new()
	sim.data = game_data
	sim.depth = maxi(depth, 1)
	sim.enemy_depth = sim.depth + maxi(int(opts.get("depth_offset", 0)), 0)
	sim.rules = opts.get("rules", []).duplicate()
	for r in sim.rules:
		if game_data.get("floor_rules", {}).get(r, {}).get("omen", false):
			sim.omen = String(r)
	if opts.get("counter", false) and big_fight_exhaustion > 0:
		sim.exhaustion_turn = big_fight_exhaustion
	sim.no_heal = bool(opts.get("no_heal", false))
	sim._start_auras = opts.get("start_auras", []).duplicate()
	var forced := int(opts.get("force_elites", 0))
	var enc_def: Dictionary = game_data.encounters[encounter_id]
	# 0.27: en elitgrupp (elitfiender i rollen) får ingen påtvingad elitvariant; Nemesis blir den första elitfienden.
	if enc_def.get("elite_group", false):
		forced = 0
	var counter := counter_for(game_data, encounter_id, maxi(depth, 1), opts, party_scale_size(opts, party.size() if not party.is_empty()
			else enc_def.party.size()))
	if not artifacts.is_empty():
		# Artefakternas egenskaper skapas för den här striden, utan att röra den delade datan.
		sim.data = game_data.duplicate()
		sim.data.traits = game_data.traits.duplicate()
	sim.rng.seed = seed_value
	var enc: Dictionary = game_data.encounters[encounter_id]
	var hero_ids: Array = party if not party.is_empty() else enc.party
	for i in hero_ids.size():
		var hero := CombatUnit.from_data(hero_ids[i], game_data.heroes[hero_ids[i]], 0)
		hero.position = HERO_SLOTS[i]
		if opts.has("levels"):
			var lv: Dictionary = opts.levels.get(hero.id, {})
			hero.level = float(lv.get("level", 1))
			hero.personality = lv.get("personality", game_data.heroes[hero.id].get("personality", ""))
			var st := HeroStats.level_stats(game_data, hero.id, int(hero.level), hero.personality,
					float(lv.get("carry", 0.0)))
			hero.max_hp = st.health
			hero.hp = st.health
			hero.attack = st.attack
			hero.intelligence = st.intelligence
			hero.defense = st.defense
			hero.speed = st.speed
			hero.base_stats = st.duplicate()
		if traits.has(hero.id):
			hero.traits = traits[hero.id].duplicate()
		hero.traits = expand_traits(game_data, hero.traits)
		for ability_id in hero.abilities:
			var full := int(game_data.abilities[ability_id].get("charges", 0))
			hero.charges[ability_id] = int(charges.get(hero.id, {}).get(ability_id, full))
		if artifacts.has(hero.id):
			sim.equip_artifact(hero, artifacts[hero.id])
		if sim.rules.has("chaos_wind"):
			var atk := hero.attack
			hero.attack = hero.defense
			hero.defense = atk
			hero.base_stats.attack = hero.attack
			hero.base_stats.defense = hero.defense
		sim._add(hero)
		sim.heroes.append(hero)
	# 0.23: ett mindre sällskap möter svagare fiender (Health, Attack och Intelligence; vårt val).
	var scale_size := party_scale_size(opts, sim.heroes.size())
	var party_mult := float(PARTY_SCALE[scale_size]) * (FIVE_CAPPED_SCALE if scale_size >= 5 and max_enemies <= 5 else 1.0)
	if scale_size >= 5 and opts.get("five_in_four", false):
		party_mult *= five_in_four
	var counts := {}
	var lineup := enemy_lineup(game_data, encounter_kinds(enc, scale_size), scale_size)
	var elites := elite_rolls(game_data, encounter_id, lineup, seed_value, opts, sim.depth)
	# Bryt två av tre sigill (RunState.boss_seals): bossen (annars ledaren, den första) får sigillens egenskaper.
	var seal_at := -1
	if not opts.get("boss_traits", []).is_empty():
		seal_at = 0
		for i in lineup.size():
			if game_data.enemies[lineup[i]].get("boss", false):
				seal_at = i
				break
	for i in lineup.size():
		var kind: String = lineup[i]
		counts[kind] = counts.get(kind, 0) + 1
		var e := CombatUnit.from_data("%s_%d" % [kind, counts[kind]], game_data.enemies[kind], 1)
		e.kind = kind
		e.position = ENEMY_SLOTS[i]
		apply_override(e, unit_override(enc, kind, counts[kind]))
		var bonus := float(opts.get("stat_bonus", 1.0))
		var mult := enemy_mult(enc, sim.enemy_depth)
		# Elitgruppen på den första nedstigningen (RunState.FIRST_DESCENT_ELITE): mötets egen styrka ersätter stat_mult
		# och den allmänna faktorn.
		if opts.has("first_descent_elite") and enc.has("first_descent_stat_mult"):
			bonus /= float(opts.first_descent_elite)
			mult = float(enc.first_descent_stat_mult) * depth_mult(sim.enemy_depth)
		scale_unit(e, mult * bonus * realm_depth_mult(opts, sim.enemy_depth))
		if party_mult != 1.0:
			e.max_hp = snap_stat(e.max_hp * party_mult)
			e.hp = e.max_hp
			e.attack = snap_stat(e.attack * party_mult)
			e.intelligence = snap_stat(e.intelligence * party_mult)
			e.base_stats.health = e.max_hp
			e.base_stats.attack = e.attack
			e.base_stats.intelligence = e.intelligence
		if opts.has("levels"):
			e.level = HeroStats.enemy_level(sim.enemy_depth, int(opts.get("floor", 0)))
			var lm := HeroStats.enemy_level_mult(sim.enemy_depth, int(opts.get("floor", 0)))
			scale_unit(e, lm)
			e.speed = roundf(e.speed * lm)
			e.base_stats.speed = e.speed
		if opts.get("counter", false) and (big_fight_hp != 1.0 or big_fight_power != 1.0):
			e.max_hp = snap_stat(e.max_hp * big_fight_hp)
			e.hp = e.max_hp
			e.attack = snap_stat(e.attack * big_fight_power)
			e.intelligence = snap_stat(e.intelligence * big_fight_power)
			e.base_stats.health = e.max_hp
			e.base_stats.attack = e.attack
			e.base_stats.intelligence = e.intelligence
		if elites[i]:
			make_elite(e, game_data.enemies[kind].elite)
			if forced > 0 and opts.get("nemesis", false):
				e.name = "Nemesis: " + e.name
				e.nemesis = true
			forced -= 1
		elif enc_def.get("elite_group", false) and opts.get("nemesis", false) and game_data.enemies[kind].get("rank", "") \
				in ["elite", "miniboss"] and not sim.enemies.any(func(x: CombatUnit) -> bool: return x.nemesis):
			e.name = "Nemesis: " + e.name
			e.nemesis = true
		if not counter.is_empty() and counter.index == i:
			e.counter = counter.trait
			e.traits.append(counter.trait)
		if i == seal_at:
			for t in opts.boss_traits:
				if game_data.traits.has(t) and not e.traits.has(t):
					e.traits.append(t)
		e.traits = expand_traits(game_data, e.traits)
		sim._add(e)
		sim.enemies.append(e)
	return sim


## Väktarsteg 2 (docs/plan/bossbank.md): ett möte kan ge sina fiender egna egenskaper och regler som bara gäller i det
## mötet ("overrides" i encounters.json), så att Klockaren som väktare ringer i Midnattsklockan men inte i en elitgrupp.
## Nyckeln är fiendetypen, eller "typ#n" för den n:e av samma typ (två Kistbärare med olika egenskaper).
## {"traits": [läggs till], "remove_traits": [tas bort], "rules": [ersätter], "name": "…"}.
static func unit_override(enc: Dictionary, kind: String, n: int) -> Dictionary:
	var ov: Dictionary = enc.get("overrides", {})
	return ov.get("%s#%d" % [kind, n], ov.get(kind, {}))


static func apply_override(e: CombatUnit, ov: Dictionary) -> void:
	if ov.is_empty():
		return
	for t in ov.get("remove_traits", []):
		e.traits.erase(t)
	for t in ov.get("traits", []):
		if not e.traits.has(t):
			e.traits.append(t)
	if ov.has("rules"):
		e.rules = ov.rules
	if ov.has("name"):
		e.name = ov.name


# --- Publikt API ------------------------------------------------------------

## 0.27 (Siralims motdrag, docs/plan/0.27-fiender.md §6): vilken fiende i mötet som bär ett motdrag, som
## {index, kind, trait}, eller {} om ingen. VAL: högst ett per grupp, bara i elitgrupper och bossmöten ("counter" i
## opts, satt av grottan för elit-, Nemesis- och bossrutor) och först från ett visst djup ("min_depth"). Fiendens eget
## motdrag ("counter" i enemies.json) går före elitvariantens; den första i uppställningen som har ett vinner.
static func counter_for(game_data: Dictionary, encounter_id: String, at_depth: int, opts: Dictionary,
		party_size: int) -> Dictionary:
	if not opts.get("counter", false):
		return {}
	var enc: Dictionary = game_data.encounters[encounter_id]
	var forced := 0 if enc.get("elite_group", false) else int(opts.get("force_elites", 0))
	var lineup := enemy_lineup(game_data, encounter_kinds(enc, party_size), party_size)
	for i in lineup.size():
		var d: Dictionary = game_data.enemies[lineup[i]]
		var c: Dictionary = d.get("counter", {})
		if forced > 0 and d.has("elite"):
			forced -= 1
			c = d.elite.get("counter", {})
		if not c.is_empty() and at_depth >= int(c.get("min_depth", 1)):
			return {"index": i, "kind": lineup[i], "trait": c.trait}
	return {}


## 0.27: hur många av figurens familj (Siralims Race) som lever, figuren själv oräknad.
func family_count(u: CombatUnit) -> int:
	if u.family == "":
		return 0
	return units.filter(func(x: CombatUnit) -> bool:
		return x != u and x.alive and x.team == u.team and x.family == u.family).size()


func _family(u: CombatUnit) -> Array[CombatUnit]:
	var out: Array[CombatUnit] = []
	if u.family == "":
		return out
	for x in units:
		if x != u and x.alive and x.team == u.team and x.family == u.family:
			out.append(x)
	return out

## 0.23.3: högst så många fler fiender än hjältar (vårt val). Fyra fiender mot två hjältar fick dubbelt så många turer
## som sällskapet även med svagare stats.
const EXTRA_ENEMIES := 1
## Sällskap om fem (VD): högst fem fiender på slagfältet, också mot fem hjältar (ENEMY_SLOTS har sex platser; botarna kan
## pröva andra tak med GROTTA_TAK). Mot fem hjältar och fem fiender slår FIVE_CAPPED_SCALE på fiendernas stats, så att
## Trollberget med fem inte blir lättare än med fyra förut.
static var max_enemies := 5
const FIVE_CAPPED_SCALE := 1.0


## Storleken fienderna skalas och ställs upp mot: hjältarna som är med, eller opts "full_party" (true = fyra, ett tal =
## så många, RunState.full_party_size()). Med "full_party" gäller den storleken åt båda hållen (VD): färre hjältar möter
## fiender som mot den (en bedrift), och fem hjältar i en Realm byggd för fyra (kryptan, kapellet) möter fiender som mot
## fyra, utan mötenas "extra".
static func party_scale_size(opts: Dictionary, heroes: int) -> int:
	var size := heroes
	var full = opts.get("full_party", false)
	if full is bool and full:
		size = 4
	elif (full is int or full is float) and int(full) > 0:
		size = int(full)
	return clampi(size, 1, MAX_HEROES)


## Mötets fiender, med "extra" (encounters.json) när sällskapet är fem: Trollbergets grupper är byggda för fem.
static func encounter_kinds(enc: Dictionary, party_size: int) -> Array:
	var kinds: Array = enc.enemies.duplicate()
	if party_size >= 5:
		kinds.append_array(enc.get("extra", []))
	return kinds


## Fienderna som möter ett sällskap av den storleken. Ett litet sällskap möter färre: först tas dubbletter bort
## bakifrån, sedan de sista i listan. Den första (våningens ledare) och bossar blir alltid kvar, och så en fiende som
## en annan behöver (som Kultisten som gör biskopen immun).
static func enemy_lineup(game_data: Dictionary, kinds: Array, party_size: int) -> Array:
	var out := kinds.duplicate()
	var cap := mini(maxi(party_size, 1) + EXTRA_ENEMIES, max_enemies)
	for only_duplicates in [true, false]:
		var i := out.size() - 1
		while out.size() > cap and i > 0:
			var kind: String = out[i]
			var duplicate := out.count(kind) > 1
			if (duplicate or not only_duplicates) and _can_drop(game_data, out, i):
				out.remove_at(i)
			i -= 1
	return out


static func _can_drop(game_data: Dictionary, kinds: Array, i: int) -> bool:
	var kind: String = kinds[i]
	if game_data.enemies[kind].get("boss", false):
		return false
	if kinds.count(kind) > 1:
		return true
	for j in kinds.size():
		if j == i:
			continue
		for t in game_data.enemies[kinds[j]].get("traits", []):
			if game_data.traits.get(t, {}).get("modify", {}).get("immune_while_ally_kind", "") == kind:
				return false
	return true


## Chansen att en vanlig fiende är en elitvariant: 5 % och mer med djup och instabilitet, högst 30 %.
## Vilka i uppställningen som blir elitvarianter (sant/falskt per plats). Slumpas med ett eget frö, så att striden i
## övrigt blir densamma: "elite_seed" i opts (grottan ger varje ruta ett, så att kortet visar samma fiender som striden,
## RunState.group_preview), annars stridens frö. "force_elites" gör de n första som har en variant till elit (inte i
## en elitgrupp).
static func elite_rolls(game_data: Dictionary, encounter_id: String, lineup: Array, seed_value: int, opts: Dictionary,
		at_depth: int) -> Array:
	var forced := 0 if game_data.encounters[encounter_id].get("elite_group", false) else int(opts.get("force_elites", 0))
	var chance: float = opts.get("elite_chance", elite_chance(at_depth, int(opts.get("instability", 0))))
	var base := int(opts.get("elite_seed", seed_value))
	var out: Array = []
	for i in lineup.size():
		var elite_rng := RandomNumberGenerator.new()
		elite_rng.seed = base * 7919 + i
		var roll := elite_rng.randf()
		var yes: bool = game_data.enemies[lineup[i]].has("elite") and (forced > 0 or roll < chance)
		if yes:
			forced -= 1
		out.append(yes)
	return out


static func elite_chance(at_depth: int, instability := 0) -> float:
	return minf(ELITE_CHANCE + ELITE_PER_DEPTH * (maxi(at_depth, 1) - 1) + ELITE_PER_INSTABILITY * instability,
			ELITE_MAX)


## Gör fienden till sin elitvariant: eget namn, mer liv och skada, och elitens egenskap (samma som
## dess trofé, som i Siralim där trofén ger monstrets egenskap).
static func make_elite(e: CombatUnit, def: Dictionary) -> void:
	e.elite = true
	e.name = def.get("name", e.name)
	e.max_hp = snap_stat(e.max_hp * ELITE_HEALTH)
	e.hp = e.max_hp
	e.attack = snap_stat(e.attack * ELITE_POWER)
	e.intelligence = snap_stat(e.intelligence * ELITE_POWER)
	e.base_stats.health = e.max_hp
	e.base_stats.attack = e.attack
	e.base_stats.intelligence = e.intelligence
	if def.has("trait"):
		e.traits.append(def.trait)


## Hur mycket fiendernas stats växer på djupet: 1 + 8 % per djup över 1.
static func depth_mult(depth: int) -> float:
	return 1.0 + depth_step * (maxi(depth, 1) - 1)


## Balans v1: Realmens eget djupsteg (opts "realm_depth_step", realms.json "depth_step") per fiendedjup över 1 (med
## depth_offset, så att också Trollbergets djup 1 räknas), gånger depth_mult. Trollberget är brantare per djup än Realms
## byggda för fyra.
static func realm_depth_mult(opts: Dictionary, depth: int) -> float:
	return 1.0 + float(opts.get("realm_depth_step", 0.0)) * (maxi(depth, 1) - 1)


## Mötets skalning (våningen) gånger djupets.
static func enemy_mult(enc: Dictionary, depth: int) -> float:
	return float(enc.get("stat_mult", 1.0)) * depth_mult(depth)


## Skalar Health, Attack, Intelligence och Defense (inte Speed). Anropas före begin().
static func scale_unit(u: CombatUnit, mult: float) -> void:
	if is_equal_approx(mult, 1.0):
		return
	u.max_hp = snap_stat(u.max_hp * mult)
	u.hp = u.max_hp
	u.attack = snap_stat(u.attack * mult)
	u.intelligence = snap_stat(u.intelligence * mult)
	u.defense = snap_stat(u.defense * mult)
	for stat in SCALED_STATS:
		u.base_stats[stat] = u.stat(stat) if stat != "health" else u.max_hp


## Lägger till dolda delar ("parts") av egenskaper, t.ex. en kronas nackdel.
static func expand_traits(game_data: Dictionary, list: Array) -> Array:
	var out := []
	for trait_id in list:
		out.append(trait_id)
		for part in game_data.traits[trait_id].get("parts", []):
			out.append(part)
	return out

## Ger hjälten artefakten: typens stat och en egenskap som kastar förmågan när handlingen görs.
## Anropas före begin().
func equip_artifact(hero: CombatUnit, art: Dictionary) -> void:
	var kind: Dictionary = data.artifacts.get(art.get("type", ""), {})
	if kind.is_empty():
		return
	hero.artifact = Forge.normalize(art)
	# Siralims artefakter höjer en stat (typen), och bärnstenen och Nether Stone fler (0.20, Forge).
	var values := {}
	for stat in HeroStats.STATS:
		values[stat] = hero.max_hp if stat == "health" else float(hero.get(stat))
	var parts := Forge.stat_parts(data, hero.artifact, values)
	for stat in HeroStats.STATS:
		var value: float = values[stat]
		for part in parts:
			value += float(parts[part].get(stat, 0.0))
		if stat == "health":
			hero.max_hp = snap_stat(value)
			hero.hp = hero.max_hp
		else:
			hero.set(stat, value)
		hero.base_stats[stat] = value
	# Trick och Nether Stone ger egna (dolda) egenskaper; en sten kan också ge en troféegenskap.
	var effects := Forge.effect_traits(data, hero.artifact, hero.id)
	for trait_id in effects.traits:
		data.traits[trait_id] = effects.traits[trait_id]
		hero.traits.append(trait_id)
	for trait_id in effects.trait_ids:
		if not hero.traits.has(trait_id):
			hero.traits.append(trait_id)
	var ability_id: String = hero.artifact.ability
	if ability_id == "" or not data.abilities.has(ability_id):
		return
	var trait_id := "artifact_" + hero.id
	var when := {"unit": "self"}
	var trigger := "turn_start"
	if kind.trigger != "turn_start":
		trigger = "acted"
		when.action = kind.trigger
	data.traits[trait_id] = {"name": "%s: %s" % [kind.name, data.abilities[ability_id].name], "hidden": true,
			"artifact": true, "trigger": trigger, "when": when,
			"chance": minf(Forge.CHANCE_MAX, float(kind.chance) * Forge.level_mult(hero.artifact.level)),
			"effects": [{"type": "cast", "ability": ability_id}]}
	hero.traits.append(trait_id)


func begin() -> void:
	var alive: Array[CombatUnit] = units.duplicate()
	alive.sort_custom(func(a: CombatUnit, b: CombatUnit) -> bool:
		return a.speed > b.speed or (a.speed == b.speed and a.team < b.team))
	# Förvarningen (Siralims Surprise!): figurer med "start_first" börjar överst.
	var first := alive.filter(func(u: CombatUnit) -> bool:
		return u.traits.any(func(t: String) -> bool: return data.traits[t].get("start_first", false)))
	for u in first:
		alive.erase(u)
	alive = first + alive
	order.clear()
	for u in alive:
		order.append(u.id)
	for e in enemies:
		if e.elite:
			_emit({"type": "elite", "unit": e.id})
	# Siralim: traits och buffar ges innan striden börjar, sedan börjar turerna.
	_emit({"type": "battle_start"})
	for aura_id in _start_auras:
		for h in heroes:
			_add_aura(h, h, aura_id)
	if _rule("fog_weakness"):
		_rule_hit("fog_weakness")
		for h in heroes:
			_add_aura(h, h, "weak")
	for e in enemies:
		_choose_intent(e)
	_next_turn()


## Förmågans fulla antal Charges (0 = obegränsad).
func full_charges(ability_id: String) -> int:
	return int(ability(ability_id).get("charges", 0))


func ability(ability_id: String) -> Dictionary:
	return data.abilities[ability_id]


func unit(unit_id: String) -> CombatUnit:
	return _by_id.get(unit_id)


func drain_events() -> Array[Dictionary]:
	var out := events
	events = []
	return out


func needs_input() -> bool:
	return outcome == "" and current != null and current.team == 0 and not auto


## Förmågan bakom en handling för en enhet.
func action_ability(u: CombatUnit, action: String, ability_id := "") -> String:
	match action:
		"attack":
			return u.attack_ability
		"ability":
			return ability_id
		"provoke":
			return "provoke"
		"skip":
			return "skip"
	return "defend"


## Tystad (Siralims Silenced): figuren kan inte använda förmågor, bara Anfall, Försvara och Provocera.
func is_silenced(u: CombatUnit) -> bool:
	return not u.resistant and has_flag(u, "silence")


## Hånad (Siralims Scorned): kan inte anfalla. Resistent: kan, men gör 50 % mindre skada.
func is_scorned(u: CombatUnit) -> bool:
	return not u.resistant and has_flag(u, "scorn")


## Frusen eller sover: figuren förlorar turen (0.22).
func cannot_act(u: CombatUnit) -> String:
	for flag in ["freeze", "sleep"]:
		var id := flag_aura(u, flag)
		if id != "":
			return id
	return ""


## Sant om figuren inte kan skadas just nu: en egenskap med "immune_while_ally_kind" (immun så länge
## en levande allierad av den typen finns, som Siralims Myrtle) eller "immune_while_allies" (så länge
## minst så många andra i laget lever).
func is_immune(u: CombatUnit) -> bool:
	for m in _modifiers(u, "modify_damage_taken", {"target": u.id}):
		if m.has("immune_while_ally_kind") and _allies(u).any(func(x: CombatUnit) -> bool:
				return x != u and x.kind == m.immune_while_ally_kind):
			return true
		if m.has("immune_while_allies") and _allies(u).size() - 1 >= int(m.immune_while_allies):
			return true
	return false


## Tom sträng om handlingen går att göra, annars en orsak (dead, none, charges, cooldown, silenced).
func can_act(u: CombatUnit, action: String, ability_id := "") -> String:
	if u == null or not u.alive:
		return "dead"
	var id := action_ability(u, action, ability_id)
	if id == "" or not data.abilities.has(id):
		return "none"
	if action == "ability" and u.team == 0 and not u.abilities.has(id):
		return "none"
	if u.charges.has(id) and full_charges(id) > 0 and u.charges[id] <= 0:
		return "charges"
	if action == "ability" and is_silenced(u):
		return "silenced"
	if action == "attack" and is_scorned(u):
		return "scorned"
	if action == "ability" and u.team == 0 and no_heal and is_heal_ability(id):
		return "vowed"
	if action == "ability" and u.sealed.has(id):
		return "sealed"
	if action in ["defend", "provoke"] and _rule("no_guard"):
		return "forbidden"
	if u.cooldown_left(id) > 0.0:
		return "cooldown"
	return ""


## Vilka mål spelaren kan välja för handlingen (tom lista = inget mål behövs).
func valid_targets(u: CombatUnit, action: String, ability_id := "") -> Array[String]:
	var out: Array[String] = []
	match ability(action_ability(u, action, ability_id)).get("target", "self"):
		"enemy":
			for x in _taunting_enemies(u):
				out.append(x.id)
		"ally":
			for x in _allies(u):
				out.append(x.id)
	return out


## Förvalt mål om spelaren inte pekar ut något.
func default_target(u: CombatUnit, action: String, ability_id := "") -> String:
	var ab := ability(action_ability(u, action, ability_id))
	if not ab.get("target", "") in ["enemy", "ally"]:
		return ""
	var picked := _pick_targets(u, ab)
	return picked[0] if not picked.is_empty() else ""


## Hjälten som har turen gör en handling. Returnerar "" eller en orsak till att det inte gick.
func act(action: String, target_id := "", ability_id := "") -> String:
	if outcome != "" or current == null:
		return "over"
	var reason := can_act(current, action, ability_id)
	if reason == "forbidden":
		_rule_hit("no_guard")
	if reason != "":
		return reason
	_perform(current, action_ability(current, action, ability_id), action, target_id)
	_end_turn()
	return ""


## AI:n agerar för den som har turen.
func ai_act() -> void:
	if outcome != "" or current == null:
		return
	var released := current.team == 1 and is_charging(current)
	if released and _windup_turn(current):
		_end_turn()
		return
	var choice := _hero_choice(current) if current.team == 0 else _enemy_choice(current)
	if current.team == 1 and _interrupted(current, choice.ability, released):
		_end_turn()
		return
	_perform(current, choice.ability, choice.action, choice.get("target", ""))
	_end_turn()


## Toruns "Inte färdigt än" (docs/ideer/chat-femte-foljeslagaren.md): en motståndare som står beredd (en status med
## "interrupt", Stå beredd) och bär en egenskap med "interrupt" avbryter en fiendes helning eller en varslad attack som
## släpps nu. Fiendens tur går åt och förmågan får sin nedkylning; beredskapen förbrukas. Kostnaden är Toruns egen tur
## (hon står beredd i stället för att slå) och förmågans nedkylning. Gränser, så att Tystad behövs: hon avbryter inte
## när hon själv är Tystad, sover eller är frusen; inte laddningar som bara bryts på annat sätt (Midnatt, "broken_by"
## tom); och en boss eller en Resistent fiende tappar inte laddningen, den skjuts bara upp en tur. Tystad hindrar
## dessutom laddningen innan den börjar, gäller flera förmågor och ger Vacklande när den bryter en laddning.
## Sant om handlingen avbröts.
func _interrupted(e: CombatUnit, ability_id: String, released: bool) -> bool:
	var windup := released and not windup_of(ability_id).is_empty()
	if windup and (windup_of(ability_id).get("broken_by", []) as Array).is_empty():
		return false
	if not windup and not is_heal_ability(ability_id):
		return false
	if is_silenced(e) and ability_id != e.attack_ability:
		return false  # _perform spärrar den ändå
	for h in _enemies(e):
		var ready := flag_aura(h, "interrupt")
		if ready == "" or cannot_act(h) != "" or is_silenced(h) or not has_interrupt_trait(h):
			continue
		_remove_aura(h, ready, "used")
		var delayed: bool = windup and (e.resistant or bool(data.enemies.get(e.kind, {}).get("boss", false)))
		if delayed:
			e.charging = {"ability": ability_id, "left": 1, "max": 1, "taken": 0.0}
		else:
			var cooldown: float = ability(ability_id).get("cooldown", 0.0)
			if cooldown > 0.0:
				e.cooldowns[ability_id] = cooldown + 1.0
			if windup:
				_reset_windup_stack(e, ability_id)
		_emit({"type": "interrupt", "unit": h.id, "target": e.id, "ability": ability_id,
				"kind": "windup" if windup else "heal", "delayed": delayed})
		return true
	return false


func has_interrupt_trait(u: CombatUnit) -> bool:
	return traits_of(u).any(func(t: String) -> bool: return data.traits.get(t, {}).get("interrupt", false))


## Sant om fiendens avsikt är en helning (makrovillkoret "tänker hela", för Torun).
func intends_heal(u: CombatUnit) -> bool:
	return u != null and u.alive and u.team == 1 and not u.intent.is_empty() \
			and is_heal_ability(String(u.intent.get("ability", "")))


## Egenskapsstaplar som förmågan förbrukar när den används: {stack, value, max}, eller tom.
func stack_info(u: CombatUnit, ability_id: String) -> Dictionary:
	for trait_id in u.traits:
		var t: Dictionary = data.traits[trait_id]
		var release: Dictionary = t.get("release", {})
		if release.is_empty() or not _release_matches(u, release, ability_id):
			continue
		var cap := 0.0
		for effect in t.get("effects", []):
			if effect.type == "stack":
				cap = _stack_cap(u, effect)
		return {"stack": release.stack, "value": u.stacks.get(release.stack, 0.0), "max": cap}
	return {}


## Tidslinjen framöver: den som har turen och sedan kön, som roterar (för tidslinjen i UI:t).
func upcoming(count: int) -> Array[String]:
	var cycle: Array[String] = []
	for id in order:
		if unit(id).alive:
			cycle.append(id)
	if current and current.alive:
		cycle.append(current.id)
	var out: Array[String] = []
	if current and current.alive:
		out.append(current.id)
	while out.size() < count and not cycle.is_empty():
		for id in cycle:
			if out.size() >= count:
				break
			out.append(id)
	return out


# --- Turer ------------------------------------------------------------------

func _next_turn() -> void:
	current = null
	while outcome == "" and not order.is_empty():
		var u := unit(order.pop_front())
		if not u.alive:
			continue
		current = u
		turn_no += 1
		if turn_no > EXHAUSTION_LOSS:
			_exhausted_loss()
			return
		u.turns_taken += 1
		if u.team == 0 and _rule("chaos_wind") and u.turns_taken == CHAOS_WIND_TURNS + 1:
			_calm_chaos_wind(u)
		_turn_counts.clear()
		_team_heals.clear()
		_turn_procs = 0
		_emit({"type": "turn_start", "unit": u.id})
		_break_snares()
		_tick_turn_start(u)
		if u.alive and turn_no > exhaustion_turn:
			_exhaust(u)
		_check_outcome()
		if u.alive and _wakes_or_thaws(u):
			return
		if u.alive:
			# Frusen eller sover: turen går förlorad, figuren läggs längst ned.
			_emit({"type": "status_skip", "unit": u.id, "aura": cannot_act(u)})
			if is_charging(u):
				_emit({"type": "windup_delayed", "unit": u.id, "ability": u.charging.ability,
						"reason": "frozen" if cannot_act(u) == "frozen" else "sleep", "left": charge_left(u)})
			order.push_back(u.id)
			_sink_snared()
			if u.team == 1:
				_choose_intent(u)
		current = null


## Snärjd: 10 % chans (resistent 30 %) att slita sig loss i början av varje figurs tur.
## 0.30.25: chansen fördubblas för varje misslyckat försök (som Frusen), annars kunde en snärjd hjälte stå
## stilla hela striden (provspelet i Sidenlunden: varaktigheten räknas bara på egna turer, och de kom aldrig).
func _break_snares() -> void:
	for x in units:
		var snare := flag_aura(x, "snare")
		if not x.alive or snare == "":
			continue
		var a: Dictionary = x.auras[snare]
		var chance := float(a.get("break", 0.3 if x.resistant else 0.1))
		if rng.randf() < chance:
			_remove_aura(x, snare, "broke_free")
		else:
			a.break = minf(1.0, chance * 2.0)


## Frusen och Sover i början av den egna turen. Sant om figuren kan agera.
func _wakes_or_thaws(u: CombatUnit) -> bool:
	if u.auras.has("frozen"):
		var a: Dictionary = u.auras.frozen
		if rng.randf() < float(a.get("thaw", 0.25)):
			_remove_aura(u, "frozen", "thawed")
		else:
			a.thaw = minf(1.0, float(a.get("thaw", 0.25)) * 2.0)
	if u.auras.has("sleeping") and u.resistant:
		_remove_aura(u, "sleeping", "woke")
	return cannot_act(u) == ""


## Snärjda figurer hålls längst ned på tidslinjen.
func _sink_snared() -> void:
	for id in order.duplicate():
		var x := unit(id)
		if x and has_flag(x, "snare"):
			order.erase(id)
			order.push_back(id)


## I början av den egna turen: nedkylningar räknas ned och auror verkar och åldras.
func _tick_turn_start(u: CombatUnit) -> void:
	for key in u.cooldowns.keys():
		u.cooldowns[key] = maxf(0.0, u.cooldowns[key] - 1.0)
	if u.team == 0 and _rule("cursed_ground"):
		_rule_hit("cursed_ground")
		_deal_damage(u, u, u.max_hp * CURSED_GROUND, "shadow", "cursed_ground", false, false, "indirect")
		if not u.alive:
			return
	for aura_id in u.auras.keys():
		if not u.auras.has(aura_id):
			continue  # försvann under turstarten (t.ex. en Barriär som tog slut)
		var a: Dictionary = u.auras[aura_id]
		var source := unit(a.source)
		var d: Dictionary = data.auras.get(aura_id, {})
		if d.has("hot_max_hp_pct"):
			var mend := u.max_hp * float(d.hot_max_hp_pct)
			_heal_ctx = {"base": mend, "hot": true}
			_heal(source if source else u, u, mend, aura_id)
		if d.has("bleed_pct"):
			var pct := float(d.resisted_bleed_pct if u.resistant else d.bleed_pct)
			_deal_damage(source if source else u, u, u.hp * pct, "physical", aura_id, false, false, "pure")
			if not u.alive:
				return
		if a.hot > 0.0:
			_heal_ctx = {"base": a.hot, "hot": true}
			_heal(source if source else u, u, a.hot, aura_id)
		if a.dot > 0.0:
			_deal_damage(source if source else u, u, a.dot, a.school, aura_id, false, false, "indirect")
		if not u.alive:
			return
		if a.duration > 0.0:
			a.remaining -= 1.0
			if a.remaining <= 0.0:
				_remove_aura(u, aura_id, "expired")


## Den som har agerat läggs längst ned på tidslinjen. Fiender bestämmer då sin nästa handling.
func _end_turn() -> void:
	_check_outcome()
	if outcome != "":
		return
	if current and current.alive and current.team == 1 and _rule("vigilant_guards") and not _rule("no_guard") \
			and rng.randf() < VIGILANT_CHANCE:
		_rule_hit("vigilant_guards")
		_add_aura(current, current, "defend")
	if current and current.alive:
		for id in current.auras.keys():
			var extra: String = data.auras.get(id, {}).get("end_turn_aura", "")
			if extra != "":
				_add_aura(current, current, extra)
	if current and current.alive and not order.has(current.id):
		if current.next_slot == "top":
			order.push_front(current.id)
		else:
			order.push_back(current.id)
		current.next_slot = ""
		_sink_snared()
		if current.team == 1:
			current.windup_guard = false  # efter en bruten laddning: en vanlig tur först (0.31)
			_choose_intent(current)
	_next_turn()


func _rule(rule_id: String) -> bool:
	return rules.has(rule_id)


## Djupets tecken (0.30.45, mot-upprepning.md §3): en regel för hela nedstigningen som gäller båda sidor. "" = inget.
var omen := ""
const OMEN_CRIT_MULT := 1.25  # Fullmåne: kritiska träffars extra skada (×2 gav kryptan djup 2 −20 enheter, ×1,5 −13)
const OMEN_HEAL_MULT := 1.15  # Helig mark (+25 % gav kapellet djup 1 +13 enheter)
const OMEN_ECHO_EVERY := 3  # Ekande valv: var tredje förmåga kastas två gånger
const OMEN_LOW_HP := 0.5  # Sista kraften: under halva livet …
const OMEN_LOW_HP_MULT := 1.25  # … mer skada
const OMEN_SINGLE_MULT := 1.25  # Trång passage: mot ett mål
const OMEN_MULTI_MULT := 0.75  # Trång passage: mot alla


func omen_name() -> String:
	return String(data.get("floor_rules", {}).get(omen, {}).get("name", omen))


## En användning av en förmåga (inte Anfall, Försvara, Provocera eller ett gratis kast) räknas för tecknen.
func is_omen_ability(u: CombatUnit, action: String, ability_id: String) -> bool:
	if ability_id in ["defend", "provoke", "skip"]:
		return false
	return action == "ability" or (action == "intent" and ability_id != u.attack_ability)


## Ekande valv: figurens nästa förmåga ekar (makrovillkoret "next_ability_echoes"; en varslad attack ekar ändå inte).
func next_ability_echoes(u: CombatUnit) -> bool:
	return omen == "omen_echo_vault" and (u.omen_casts + 1) % OMEN_ECHO_EVERY == 0


## Tyst mässa: lagets första förmåga i striden är ännu inte använd (makrovillkoret "free_ability_unused"). VAL: en per
## lag och strid; en per figur gav kryptan djup 1 +15–20 enheter (fienderna har inga Charges, så bara hjältarna vann på det).
var _quiet_used := {}


func free_ability_unused(u: CombatUnit) -> bool:
	return omen == "omen_quiet_mass" and not _quiet_used.get(u.team, false)


## Trång passage: förmågan träffar alla på en sida.
static func is_multi_target(ab: Dictionary) -> bool:
	return String(ab.get("target", "self")) in ["all_enemies", "all_allies"]


## Tecknens faktorer på en träff (Sista kraften, Trång passage), som rader i uträkningen.
func _omen_damage_fx(src: CombatUnit, ability_id: String, direct: bool) -> Array:
	var out: Array = []
	if omen == "omen_last_strength" and src.max_hp > 0.0 and src.hp < src.max_hp * OMEN_LOW_HP:
		out.append({"f": OMEN_LOW_HP_MULT, "name": omen_name()})
	if omen == "omen_narrow_pass" and direct and data.abilities.has(ability_id):
		out.append({"f": OMEN_MULTI_MULT if is_multi_target(data.abilities[ability_id]) else OMEN_SINGLE_MULT,
				"name": omen_name()})
	return out


## Löftet "Jag helar inte" (0.30.17): hjältarna kan inte välja förmågor som helar.
var no_heal := false


func is_heal_ability(ability_id: String) -> bool:
	for e in data.abilities.get(ability_id, {}).get("effects", []):
		if e.get("type", "") == "heal":
			return true
	return false


## Kaosvind (0.30.16, vårt val): bytet håller i hjältens tre första turer och lägger sig sedan, så att en strid där
## ingen sida hinner skada den andra ändå tar slut (botarna fann eviga strider på instabilitet 3).
const CHAOS_WIND_TURNS := 3


func _calm_chaos_wind(u: CombatUnit) -> void:
	var atk := u.attack
	u.attack = u.defense
	u.defense = atk
	u.base_stats.attack = u.attack
	u.base_stats.defense = u.defense
	_emit({"type": "chaos_calm", "unit": u.id})


## 0.30.20 Utmattning (vårt val; Siralim har ingen turgräns, och där fastnar strider ibland tills man ger upp): från tur
## 100 förlorar den som står på tur en andel av sitt maximala liv i början av turen, som växer med varje tur (förbi
## Barriär och immunitet), så att striden avgörs av sig själv. Tur 300 är en ren förlust, som Ge upp. Botarna: hälften av
## striderna är klara på 15 turer, 99 av 100 på 69, den längsta 190 (karriären, 3 781 strider).
const EXHAUSTION_TURN := 100
const EXHAUSTION_STEP := 0.004
const EXHAUSTION_LOSS := 300


## Turen då utmattningen börjar i just den här striden (EXHAUSTION_TURN, eller big_fight_exhaustion i elit-, Nemesis-
## och bossstrider när den är satt).
var exhaustion_turn := EXHAUSTION_TURN
static var big_fight_exhaustion := 0
## Prov (strid-langd): fiendernas liv och Attack/Intelligence i elit-, Nemesis- och bossstrider.
static var big_fight_hp := 1.0
static var big_fight_power := 1.0
static var big_fight_step := EXHAUSTION_STEP


func exhaustion_pct() -> float:
	var step := EXHAUSTION_STEP if exhaustion_turn == EXHAUSTION_TURN else big_fight_step
	return minf(1.0, step * (turn_no - exhaustion_turn)) if turn_no > exhaustion_turn else 0.0


func _exhaust(u: CombatUnit) -> void:
	if not exhausting:
		exhausting = true
		_emit({"type": "exhaustion_start"})
	var pct := exhaustion_pct()
	var amount := minf(u.hp, roundf(u.max_hp * pct))
	u.hp -= amount
	_emit({"type": "exhaustion", "unit": u.id, "amount": amount, "pct": pct})
	if u.hp <= 0.0:
		_kill(u)


var exhausting := false


func _exhausted_loss() -> void:
	outcome = "defeat"
	current = null
	_emit({"type": "outcome", "result": outcome, "exhausted": true})


## En regel slog till: första gången i striden blir det en händelse (dolda regler avslöjas).
func _rule_hit(rule_id: String) -> void:
	if not rules_triggered.has(rule_id):
		rules_triggered.append(rule_id)
		_emit({"type": "rule", "rule": rule_id})


## Ge upp (0.20.1, Siralims Forfeit): striden räknas som förlorad direkt.
var forfeited := false


func forfeit() -> void:
	if outcome != "":
		return
	forfeited = true
	outcome = "defeat"
	current = null
	_emit({"type": "outcome", "result": outcome, "forfeit": true})


func _check_outcome() -> void:
	if outcome != "":
		return
	if enemies.all(func(e: CombatUnit) -> bool: return not e.alive):
		outcome = "victory"
	elif heroes.all(func(h: CombatUnit) -> bool: return not h.alive):
		outcome = "defeat"
	if outcome != "":
		current = null
		_emit({"type": "outcome", "result": outcome})


# --- Varslade attacker (0.31, docs/plan/varslade-attacker.md) -----------------
# En förmåga med "windup" laddas i fiendens egna turer innan den släpps. Laddningen syns på avsikten, kostar fiendens
# turer och kan brytas (broken_by: "silenced" – Tystad, även på Resistenta; "stagger" – skada ≥ stagger × max-liv under
# laddningen; "channel" – ingen levande allierad av typen channeled_by). Bruten: förmågan får sin nedkylning och fienden
# blir Vacklande (vulnerable_after). Sömn och Frusen skjuter upp den. Skydd mot evigt lås: en fiende vars laddning bröts
# kan inte börja en ny förrän efter sin nästa tur (variation-i-strid.md, topp 5 #3).

const WINDUP_STAGGER_AURA := "staggered"


func windup_of(ability_id: String) -> Dictionary:
	return ability(ability_id).get("windup", {})


func windup_breaks(ability_id: String, reason: String) -> bool:
	var w := windup_of(ability_id)
	if reason == "channel":
		return str(w.get("channeled_by", "")) != "" or w.get("channeled_by_family", false)
	if reason == "absolved":
		return str(w.get("target_aura", "")) != ""
	return (w.get("broken_by", []) as Array).has(reason)


## Väktarsteg 2 (Midnattsklockan): figurer som håller en allierads laddning vid liv, så att den bryts när de alla är
## döda – "channeled_by" (en typ) eller "channeled_by_family" (alla ur laddarens familj). Makrovillkoret "kanaliserar".
func is_channeling(u: CombatUnit) -> bool:
	return channel_of(u) != ""


## Förmågan som figuren håller vid liv ("" om ingen).
func channel_of(u: CombatUnit) -> String:
	if u == null or not u.alive:
		return ""
	for e in units:
		if e == u or e.team != u.team or not is_charging(e):
			continue
		var w := windup_of(e.charging.ability)
		if str(w.get("channeled_by", "")) == u.kind and u.kind != "":
			return e.charging.ability
		if w.get("channeled_by_family", false) and e.family != "" and u.family == e.family:
			return e.charging.ability
	return ""


## Sant om figuren är målet för en motståndares laddning (Inkvisitorns Dom, Benfurstens Dödsdom). Makrovillkoret
## "är måltavla för en laddning".
func is_charge_target(u: CombatUnit) -> bool:
	if u == null or not u.alive:
		return false
	for e in units:
		if e.team != u.team and is_charging(e) and charging_all(e):
			return true
		if e.team != u.team and is_charging(e) and (e.intent.get("targets", []) as Array).has(u.id):
			return true
	return false


func _channel_alive(e: CombatUnit, ability_id: String) -> bool:
	var w := windup_of(ability_id)
	var kind := str(w.get("channeled_by", ""))
	if kind != "" and not _allies(e).any(func(x: CombatUnit) -> bool: return x != e and x.kind == kind):
		return false
	if w.get("channeled_by_family", false) and family_count(e) == 0:
		return false
	return true


func is_charging(u: CombatUnit) -> bool:
	return u != null and u.alive and not u.charging.is_empty()


## Egna turer tills laddningen släpps (släppets tur inräknad): 1 = den slår nästa gång den står på tur.
func charge_left(u: CombatUnit) -> int:
	return int(u.charging.get("left", 0)) if is_charging(u) else 0


## Sant om laddningen går mot hela sällskapet.
func charging_all(u: CombatUnit) -> bool:
	return is_charging(u) and ability(u.charging.ability).get("target", "") in ["enemies", "all_enemies"]


func _can_start_windup(e: CombatUnit, ability_id: String) -> bool:
	if windup_of(ability_id).is_empty():
		return true
	if e.windup_guard:
		return false
	# Väktarsteg 2: en kanaliserad laddning börjar inte utan någon som håller den (Midnatt utan Benfolket).
	if not _channel_alive(e, ability_id):
		return false
	# En Tystad fiende börjar inte en laddning som Tystad bryter (den skulle brytas direkt).
	return not (has_flag(e, "silence") and windup_breaks(ability_id, "silenced"))


func _start_windup(e: CombatUnit, ability_id: String, turns: int) -> void:
	# Turen då den väljer laddningen är redan slut, så "turns" är egna turer tills den slår: 1 = slår nästa tur (en
	# hjälterunda att svara på, samma takt som en vanlig avsikt), 2 = en tur som går åt till laddningen först.
	var left := maxi(turns, 1)
	e.charging = {"ability": ability_id, "left": left, "max": left, "taken": 0.0}
	_emit({"type": "windup_start", "unit": e.id, "ability": ability_id, "left": left,
			"targets": e.intent.get("targets", [])})


## En tur medan fienden laddar. Sant om turen gick åt till laddningen; falskt när förmågan släpps nu.
func _windup_turn(e: CombatUnit) -> bool:
	e.charging.left = int(e.charging.left) - 1
	if int(e.charging.left) > 0:
		_emit({"type": "windup_tick", "unit": e.id, "ability": e.charging.ability, "left": e.charging.left,
				"targets": e.intent.get("targets", [])})
		return true
	_emit({"type": "windup_release", "unit": e.id, "ability": e.charging.ability})
	_reset_windup_stack(e, e.charging.ability)
	e.charging = {}
	return false


## Väktarsteg 2: "reset_stack" – räknaren som ledde fram till laddningen (Klockans slag) börjar om när den släpps eller
## bryts.
func _reset_windup_stack(u: CombatUnit, ability_id: String) -> void:
	var key := str(windup_of(ability_id).get("reset_stack", ""))
	if key != "":
		u.stacks.erase(key)


func _windup_damage(u: CombatUnit, amount: float) -> void:
	u.charging.taken = float(u.charging.taken) + amount
	var w := windup_of(u.charging.ability)
	if windup_breaks(u.charging.ability, "stagger") and float(u.charging.taken) >= float(w.get("stagger", 1.0)) * u.max_hp:
		_break_windup(u, "stagger")


func _check_channels() -> void:
	for e in units:
		if not is_charging(e):
			continue
		if windup_breaks(e.charging.ability, "channel") and not _channel_alive(e, e.charging.ability):
			_break_windup(e, "channel")


func _break_windup(u: CombatUnit, reason: String) -> void:
	var ability_id: String = u.charging.ability
	_reset_windup_stack(u, ability_id)
	u.charging = {}
	u.windup_guard = true
	var cooldown: float = ability(ability_id).get("cooldown", 0.0)
	if cooldown > 0.0:
		u.cooldowns[ability_id] = cooldown + 1.0
	_emit({"type": "windup_broken", "unit": u.id, "ability": ability_id, "reason": reason})
	var mult := float(windup_of(ability_id).get("vulnerable_after", 0.0))
	if mult > 1.0 and data.auras.has(WINDUP_STAGGER_AURA):
		_add_aura(u, u, WINDUP_STAGGER_AURA)
		if u.auras.has(WINDUP_STAGGER_AURA):
			u.auras[WINDUP_STAGGER_AURA].damage_taken_mult = mult
	_choose_intent(u)


# --- AI ---------------------------------------------------------------------

## Fienden bestämmer sin nästa handling i början av striden och i slutet av sin tur, så att
## spelaren kan se den (som Siralims bossar som låser ett mål).
func _choose_intent(e: CombatUnit, allow_windup := true) -> void:
	if is_charging(e):
		return  # laddningen håller avsikten tills den släpps eller bryts (0.31)
	for rule in ([] if is_silenced(e) else e.rules):
		var ability_id: String = rule.ability
		if e.cooldown_left(ability_id) > 0.0 or not _rule_matches(e, rule):
			continue
		if not (allow_windup or windup_of(ability_id).is_empty()) or not _can_start_windup(e, ability_id):
			continue
		if _rule("no_guard") and ability(ability_id).get("effects", []).any(func(f: Dictionary) -> bool:
				return f.get("aura", "") in ["defend", "provoke"]):
			_rule_hit("no_guard")
			continue
		var ab := ability(ability_id)
		if rule.has("pick"):
			ab = ab.duplicate()
			ab.pick = rule.pick
		e.intent = {"ability": ability_id, "targets": _pick_targets(e, ab)}
		if not windup_of(ability_id).is_empty():
			_start_windup(e, ability_id, int(rule.get("windup", windup_of(ability_id).get("turns", 1))))
		_intent_chosen(e)
		return
	e.intent = {"ability": e.attack_ability, "targets": _pick_targets(e, ability(e.attack_ability))}
	_intent_chosen(e)


## 0.23: en fiende har valt mål (Ronjas Falkens vakt svarar på det).
func _intent_chosen(e: CombatUnit) -> void:
	var targets: Array = e.intent.get("targets", [])
	if not targets.is_empty() and unit(targets[0]) != null and unit(targets[0]).team != e.team:
		_emit({"type": "intent_chosen", "unit": e.id, "target": targets[0], "ability": e.intent.ability})


func _enemy_choice(e: CombatUnit) -> Dictionary:
	if e.intent.is_empty() or e.cooldown_left(e.intent.ability) > 0.0 \
			or (is_silenced(e) and e.intent.ability != e.attack_ability) \
			or (ability(e.intent.ability).get("target", "") == "dead_ally" and _pick_targets(e, ability(e.intent.ability)).is_empty()):
		# 0.31: liket som avsikten gällde är redan väckt eller uppätet (Gravväckaren och Likätaren tävlar).
		# En varslad attack väljs inte nu: den måste synas en tur i förväg.
		_choose_intent(e, false)
	var target := ""
	for id in e.intent.targets:
		if unit(id).alive:
			target = id
			break
	return {"action": "intent", "ability": e.intent.ability, "target": target}


## Utan makro anfaller hjälten det förvalda målet (makron väljs utanför simulatorn).
func _hero_choice(h: CombatUnit) -> Dictionary:
	return {"action": "attack", "ability": h.attack_ability}


func _rule_matches(u: CombatUnit, rule: Dictionary) -> bool:
	var condition: Dictionary = rule.get("if", {})
	if condition.has("ally_hp_below"):
		if not _allies(u).any(func(a: CombatUnit) -> bool: return a.hp_pct() < condition.ally_hp_below):
			return false
	if condition.has("self_hp_below") and u.hp_pct() >= condition.self_hp_below:
		return false
	if condition.has("enemies_at_least") and _enemies(u).size() < condition.enemies_at_least:
		return false
	if condition.get("dead_ally", false):
		# 0.31: förmågans eget urval (Likmåltid tar bara lik ur den egna familjen), annars vilket lik som helst.
		var probe: Dictionary = ability(rule.ability) if rule.has("ability") \
				and ability(rule.ability).get("target", "") == "dead_ally" else {"target": "dead_ally"}
		if _pick_targets(u, probe).is_empty():
			return false
	# 0.27: familjen (lever minst n andra ur den) och ensam kvar.
	if condition.has("family_at_least") and family_count(u) < int(condition.family_at_least):
		return false
	if condition.has("alone") and (_allies(u).size() == 1) != bool(condition.alone):
		return false
	# 0.28: förra handlingen var grundanfallet (Lansen försvarar sig varannan tur).
	if condition.get("self_last_attacked", false) and (u.last_ability == "" or u.last_ability != u.attack_ability):
		return false
	if condition.has("self_stacks_at_least"):
		var want: Dictionary = condition.self_stacks_at_least
		if u.stacks.get(want.stack, 0.0) < float(want.n):
			return false
	# Väktarsteg 2 (Förhöret): någon motståndare bär minst n staplar av en status.
	if condition.has("enemy_aura_stacks"):
		var w: Dictionary = condition.enemy_aura_stacks
		if not _enemies(u).any(func(x: CombatUnit) -> bool:
				return x.auras.has(w.aura) and int(x.auras[w.aura].get("stacks", 1)) >= int(w.n)):
			return false
	return true


# --- Förmågor ---------------------------------------------------------------

func _perform(u: CombatUnit, ability_id: String, action: String, target_id: String) -> void:
	if ability_id == "skip":
		_emit({"type": "action", "unit": u.id, "action": "skip", "ability": "skip", "targets": []})
		return
	var ab := ability(ability_id)
	# En fiende som är Tystad eller Hånad gör sin avsikt bara om den inte är spärrad (0.22).
	if u.team == 1 and ((ability_id == u.attack_ability and is_scorned(u))
			or (ability_id != u.attack_ability and not ability_id in ["defend", "provoke"] and is_silenced(u))):
		_emit({"type": "status_blocked", "unit": u.id, "aura": "scorned" if ability_id == u.attack_ability else "silenced"})
		return
	var counts := is_omen_ability(u, action, ability_id)
	var free := action == "ability" and u.charges.has(ability_id) and u.auras.has("arcane")
	if counts and free_ability_unused(u):
		_quiet_used[u.team] = true
		if u.charges.has(ability_id) and full_charges(ability_id) > 0:
			_emit({"type": "omen", "omen": omen, "unit": u.id, "ability": ability_id, "what": "free"})
	elif free:
		_remove_aura(u, "arcane", "used")
	elif u.charges.has(ability_id) and full_charges(ability_id) > 0:
		u.charges[ability_id] -= 1
	var targets := _targets_for(u, ab, target_id)
	var cooldown: float = ab.get("cooldown", 0.0)
	if cooldown > 0.0:
		u.cooldowns[ability_id] = cooldown + 1.0  # räknas ned i början av egna turer
	_emit({"type": "action", "unit": u.id, "action": action, "ability": ability_id, "targets": targets})
	_note_team_action(u, action, ability_id)
	_apply_effects(u, ability_id, targets)
	if counts:
		u.omen_casts += 1
		# Ekande valv: var tredje förmåga kastas en gång till, gratis; ett dött mål ger vanliga målregler.
		# VAL: en varslad attack (windup) ekar inte; det stora slaget ska gå att möta en gång.
		if omen == "omen_echo_vault" and u.omen_casts % OMEN_ECHO_EVERY == 0 and u.alive and not is_silenced(u) \
				and windup_of(ability_id).is_empty():
			var again := _targets_for(u, ab, target_id)
			if not again.is_empty():
				_emit({"type": "omen", "omen": omen, "unit": u.id, "ability": ability_id, "what": "echo"})
				_emit({"type": "action", "unit": u.id, "action": "echo", "ability": ability_id, "targets": again})
				_apply_effects(u, ability_id, again)
	# Fiender agerar med "intent": deras grundanfall räknas som Anfall, resten som förmågor.
	if action == "attack" or (action == "intent" and ability_id == u.attack_ability):
		u.attacks_done += 1
	elif action in ["ability", "intent"]:
		u.ability_uses[ability_id] = u.ability_uses.get(ability_id, 0) + 1
		if u.team == 0 and _rule("sealed_words"):
			_rule_hit("sealed_words")
			u.sealed[ability_id] = true
	if ab.get("kind", "") == "spell" and action != "attack":
		_last_caster[u.team] = u.id
	u.prev_ability = u.last_ability
	u.last_ability = ability_id
	if u.alive:
		_emit({"type": "acted", "unit": u.id, "action": action, "ability": ability_id, "targets": targets,
				"ability_kind": ab.get("kind", "attack")})


## 0.30.23 (Trollfolket, Bergakungens Stenhjärta): de två senaste handlingarnas sort per lag (attack, ability, defend,
## provoke), så att en egenskap kan se när laget gör samma sorts handling två gånger i rad.
var _team_actions := {0: [], 1: []}
var _last_attacker := {}


func action_sort(u: CombatUnit, action: String, ability_id: String) -> String:
	if action == "attack" or ability_id == u.attack_ability:
		return "attack"
	return ability_id if ability_id in ["defend", "provoke"] else "ability"


func _note_team_action(u: CombatUnit, action: String, ability_id: String) -> void:
	var list: Array = _team_actions[u.team]
	list.append(action_sort(u, action, ability_id))
	while list.size() > 2:
		list.pop_front()


func team_repeats(team: int) -> bool:
	var list: Array = _team_actions.get(team, [])
	return list.size() == 2 and list[0] == list[1]


## En förmåga som kastas automatiskt (artefakt): kostar inga Charges och sätter ingen nedkylning,
## men räknas mot gränsen per tur. VAL: inget giltigt mål = inget kast.
func _auto_cast(u: CombatUnit, ability_id: String, target_id := "") -> void:
	var ab := ability(ability_id)
	var targets := _targets_for(u, ab, target_id)
	if targets.is_empty() or is_silenced(u) or not _within_limit(u, "spell"):
		return
	_emit({"type": "action", "unit": u.id, "action": "artifact", "ability": ability_id, "targets": targets})
	_apply_effects(u, ability_id, targets)


func _targets_for(u: CombatUnit, ab: Dictionary, target_id: String) -> Array:
	if ab.get("target", "") == "dead_ally":
		return _pick_targets(u, ab)
	var tkind: String = ab.get("target", "self")
	# Förvirrad (0.22): 50 % chans att det skadliga går mot de egna.
	var confuse := flag_aura(u, "confuse")
	if confuse != "" and tkind in ["enemy", "all_enemies"] and rng.randf() < float(data.auras[confuse].confuse):
		var own := _allies(u).filter(func(x: CombatUnit) -> bool: return x != u)
		if own.is_empty():
			own = [u]
		_emit({"type": "confused", "unit": u.id})
		if tkind == "all_enemies":
			return own.map(func(x: CombatUnit) -> String: return x.id)
		return [own[rng.randi() % own.size()].id]
	# Förblindad: kan inte välja mål; ett slumpat bland dem som går att anfalla.
	if tkind == "enemy" and has_flag(u, "blind"):
		var pool := _taunting_enemies(u)
		if not pool.is_empty():
			return [pool[rng.randi() % pool.size()].id]
	var chosen := unit(target_id) if target_id != "" else null
	var kind: String = ab.get("target", "self")
	if kind == "enemy" and chosen and not ab.get("ignore_taunt", false) and not _taunting_enemies(u).has(chosen):
		chosen = null  # en provocerande fiende måste anfallas först
	if chosen and chosen.alive and ((kind == "enemy" and chosen.team != u.team) or (kind == "ally" and chosen.team == u.team)):
		return [chosen.id]
	return _pick_targets(u, ab)


func _apply_effects(caster: CombatUnit, ability_id: String, targets: Array) -> void:
	var ab := ability(ability_id)
	var can_crit: bool = not ab.get("no_crit", false)
	var releases := _take_releases(caster, ability_id)
	if ab.get("target", "") == "dead_ally" and targets.is_empty():
		return  # 0.31: inget lik kvar, ingen måltid (och ingen helning)
	for effect in ab.get("effects", []):
		# 0.23: en effekt kan gälla kastaren själv ("target": "self") fast förmågan riktas mot någon annan.
		var effect_targets: Array = [caster.id] if effect.get("target", "") == "self" else targets
		for target_id in effect_targets:
			var t := unit(target_id)
			if t == null or (not t.alive and not effect.type in ["revive", "consume_corpse"]):
				continue
			# En effekt kan ha en chans (0.22: t.ex. 25 % att Blöda); slås per mål.
			if effect.has("chance") and rng.randf() >= float(effect.chance):
				continue
			# 0.30.23 (Trollmors Vaggvisa): bara mål vars senaste handling var en förmåga.
			if effect.get("if_target_cast", false) and not last_was_ability(t):
				continue
			match effect.type:
				"damage":
					var amount := _amount(caster, effect)
					# 0.23: mer skada mot ett mål med en viss status (Ronjas Dykattack mot Märkta).
					for aura_id in effect.get("bonus_if_aura", {}):
						if t.auras.has(aura_id):
							amount *= float(effect.bonus_if_aura[aura_id])
					_deal_damage(caster, t, amount, effect.get("school", ab.get("school", "physical")),
							ability_id, can_crit, true, ab.get("kind", "attack"), _scaled(effect))
				"barrier":
					_add_barrier(caster, t, _amount(caster, effect))
				"raise_stat":
					_raise_stat(t, effect)
				"heal":
					if effect.has("pct_max_hp"):
						# 0.28 (Abbedissans Mässan): en andel av målets eget liv.
						_heal_ctx = {"base": t.max_hp * float(effect.pct_max_hp), "pct_max_hp": float(effect.pct_max_hp)}
						_heal(caster, t, t.max_hp * float(effect.pct_max_hp), ability_id)
					else:
						_heal(caster, t, _heal_amount(caster, effect), ability_id)
				"aura":
					_add_aura(caster, t, effect.aura, float(effect.get("duration", 0.0)))
				"revive":
					_revive(t, float(effect.get("pct", 0.5)))
				"dispel", "purge", "to_top", "to_bottom", "step_down":
					_status_effect(effect, t)
				"family_to_top":
					_group_to_top(_family(t))
				"drain_charge":
					_drain_charge(t)
				"consume_corpse":
					_consume_corpse(caster, t)
				"self_damage":
					_self_damage(caster, float(effect.get("pct_max_hp", 0.1)), ability_id)
				# Väktarsteg 2: Klockans slag räknas, väcker familjen; Domen tar bort Skulden den dömde för.
				"stack":
					_add_stack(t, effect, {})
					if effect.has("say"):
						_emit({"type": "stack_said", "unit": t.id, "stack": effect.stack,
								"text": str(effect.say).replace("{n}", str(int(t.stacks.get(effect.stack, 0.0))))})
				"revive_family":
					var woken := 0
					for x in units:
						if woken >= int(effect.get("max", 99)):
							break
						if not x.alive and not x.consumed and x.team == t.team and x != t and t.family != "" \
								and x.family == t.family:
							_revive(x, float(effect.get("pct", 0.5)))
							woken += 1 if x.alive else 0
				"remove_aura":
					if t.auras.has(effect.aura):
						_remove_aura(t, effect.aura, "consumed")
	_release_bonus = {}
	for r in releases:
		_run_release(caster, r, targets)


## 0.31 (Likätaren, docs/plan/drakvalvet-fiender.md §1): liket äts upp och kan aldrig väckas. Det räknas fortfarande
## som fallet (Gravpakt). Händelsen corpse_consumed (unit, by) sätter igång Gravhunger.
func _consume_corpse(by: CombatUnit, t: CombatUnit) -> void:
	if t.alive or t.consumed:
		return
	t.consumed = true
	_emit({"type": "corpse_consumed", "unit": t.id, "by": by.id})


## 0.31 (Blodsvurens Blodhugget): utföraren betalar en andel av sitt max liv, förbi Barriär. VAL: dödar aldrig (golv
## 1 liv) och sätter inte igång något som lyssnar på skada.
func _self_damage(u: CombatUnit, pct: float, ability_id: String) -> void:
	if not u.alive:
		return
	var amount := minf(roundf(u.max_hp * pct), maxf(u.hp - 1.0, 0.0))
	if amount <= 0.0:
		return
	u.hp -= amount
	_emit({"type": "self_damage", "unit": u.id, "amount": amount, "ability": ability_id})


## 0.30.23: senaste handlingen var en förmåga (inte grundanfallet, Försvara eller Provocera).
func last_was_ability(u: CombatUnit) -> bool:
	return u.last_ability != "" and u.last_ability != u.attack_ability and not u.last_ability in ["defend", "provoke"]


## 0.30.23 (Broms Tull): målet tappar en Charge ur den förmåga som har flest kvar.
func _drain_charge(t: CombatUnit) -> void:
	var best := ""
	for id in t.charges:
		if int(t.charges[id]) > 0 and (best == "" or int(t.charges[id]) > int(t.charges[best])):
			best = id
	if best == "":
		return
	t.charges[best] = int(t.charges[best]) - 1
	_emit({"type": "charge_drained", "unit": t.id, "ability": best})


## En effekts belopp: "power" (modifierare mot stats, räknas i formeln), "min"/"max" eller
## "stat" + "pct" (en andel av en stat, t.ex. Defense) som fast belopp.
func _amount(u: CombatUnit, effect: Dictionary) -> float:
	if effect.has("min"):
		return rng.randf_range(effect.min, effect.max)
	if effect.has("stat"):
		return u.stat(effect.stat) * float(effect.get("pct", 1.0))
	return float(effect.get("power", 1.0))


func _scaled(effect: Dictionary) -> bool:
	return not (effect.has("min") or effect.has("stat") or effect.has("pct_of_event"))


## Helning: Int × power (Siralim: helning är en andel av Intelligence), eller ett fast belopp.
func _heal_amount(u: CombatUnit, effect: Dictionary) -> float:
	if not _scaled(effect):
		var fixed := _amount(u, effect)
		_heal_ctx = {"base": fixed, "stat": effect.get("stat", ""), "pct": float(effect.get("pct", 0.0)),
				"stat_value": u.stat(effect.stat) if effect.has("stat") else 0.0}
		return fixed
	var roll := _roll()
	var power := float(effect.get("power", 1.0))
	_heal_ctx = {"base": u.stat("intelligence") * roll * power, "stat": "intelligence",
			"stat_value": u.stat("intelligence"), "roll": roll, "power": power}
	return _heal_ctx.base


## Uträkningen bakom senaste helningens grundbelopp (0.21), läses av _heal.
var _heal_ctx := {}
## Uträkningen bakom senaste grundskadan (0.21), läses av _deal_damage.
var _formula_ctx := {}
## 0.28: nästa grundskada struntar i Defense (Lansspetsen).
var _ignore_defense := false
## Namnen på auror som förbrukades av _consume_empower (0.21).
var _empower_names: Array[String] = []


func _roll() -> float:
	return rng.randf_range(1.0 - VARIANCE, 1.0 + VARIANCE)


# --- Formler (statiska så att de kan testas var för sig) -----------------------

static func attack_damage(attack: float, defense: float, power := 1.0) -> float:
	return (maxf(attack - defense, 0.0) + ATTACK_FLOOR * attack) * power


static func spell_damage(potency: float, defense: float, power := 1.0, ignore_defense := 0.0) -> float:
	return maxf(potency - defense * (1.0 - ignore_defense), 0.0) * power


## Indirect: Defense dras av efter modifierarna, och bara 20 % av den.
static func indirect_damage(amount: float, defense: float) -> float:
	return maxf(amount - INDIRECT_DEFENSE * defense, 0.0)


## Ökningar adderas (+75 % och +75 % = +150 %), minskningar multipliceras, och varje minskning
## stannar vid 80 % (Siralim).
static func combine_mods(factors: Array) -> float:
	var increase := 0.0
	var reduce := 1.0
	for f in factors:
		if f >= 1.0:
			increase += f - 1.0
		else:
			reduce *= maxf(f, REDUCTION_CAP)
	return (1.0 + increase) * reduce


static func _log(x: float, base: float) -> float:
	return log(x) / log(base)


## VAL: krit-chans = egen chans vid lika fart + 10 procentenheter per fördubbling av fartkvoten
## (egen Speed / målets), mellan 0 och 50 %.
static func crit_chance_for(base: float, ratio: float) -> float:
	return clampf(base + CRIT_CHANCE_PER_DOUBLING * _log(maxf(ratio, 0.01), 2.0), 0.0, CRIT_CHANCE_MAX)


## VAL, passar Siralims två datapunkter (+200 % vid 3× fart, ~+450 % vid 27×): 75 % + 125 % · log₃(kvot),
## minst +50 %.
static func crit_bonus(ratio: float) -> float:
	return maxf(0.5, 0.75 + 1.25 * _log(maxf(ratio, 0.01), 3.0))


## VAL: bara ett snabbare mål kan undvika: 10 % per fördubbling av målets fart mot anfallarens, högst 30 %.
static func dodge_chance(ratio: float) -> float:
	if ratio <= 1.0:
		return 0.0
	return minf(DODGE_PER_DOUBLING * _log(ratio, 2.0), DODGE_MAX)


## Grundskadan före modifierarna enligt typen. power är förmågans modifierare.
func _formula(src: CombatUnit, tgt: CombatUnit, kind: String, power: float, ability_id: String) -> float:
	var roll := _roll()
	var def_now := tgt.defense_now()
	_formula_ctx = {"roll": roll, "power": power, "defense": def_now, "defense_base": tgt.defense,
			"defense_parts": defense_parts(tgt)}
	match kind:
		"spell":
			var tier_id: String = data.abilities.get(ability_id, {}).get("tier", "")
			var tier: Array = SPELL_TIERS.get(tier_id, [1.0, 0.0])
			_formula_ctx.merge({"stat": "intelligence", "stat_value": src.stat("intelligence"), "tier": tier_id,
					"tier_mult": tier[0], "ignore": tier[1]})
			return spell_damage(src.stat("intelligence") * tier[0] * roll, def_now, power, tier[1])
		"indirect":
			_formula_ctx.merge({"stat": "attack", "stat_value": src.stat("attack")})
			return src.stat("attack") * roll * power
	_formula_ctx.merge({"stat": "attack", "stat_value": src.stat("attack")})
	# 0.28 (Lansspetsen): träffen struntar i Defense.
	if _ignore_defense:
		_formula_ctx.defense = 0.0
		_formula_ctx.ignore_defense = true
		return attack_damage(src.stat("attack") * roll, 0.0, power)
	return attack_damage(src.stat("attack") * roll, def_now, power)


## Vad som ändrar figurens Defense just nu: [{name, mult}] (Försvarar ×1,5, Provocerar ×0,65 …).
func defense_parts(u: CombatUnit) -> Array:
	var out := []
	for aura_id in u.auras:
		var m := float(u.auras[aura_id].get("defense_mult", 1.0))
		if m != 1.0:
			out.append({"name": status_name(u, aura_id), "mult": m})
	return out


## Sant om figuren har en status med flaggan (t.ex. "snare", "stone", "blind").
func has_flag(u: CombatUnit, flag: String) -> bool:
	for id in u.auras:
		if data.auras.get(id, {}).get(flag, false):
			return true
	return false


## Egenskaper som gör bäraren immun mot vissa statusar ("immune_auras", t.ex. Den skingrade dimman mot Sover).
func _trait_immune(u: CombatUnit, aura_id: String) -> bool:
	for trait_id in u.traits:
		if aura_id in data.traits.get(trait_id, {}).get("immune_auras", []):
			return true
	return false


## Bär någon levande i enhetens lag en egenskap med nyckeln (t.ex. Skrivarens penna: "ignore_repeat")?
func _team_has_trait_key(u: CombatUnit, key: String) -> bool:
	for a in (heroes if u.team == 0 else enemies):
		if a.alive and a.traits.any(func(t: String) -> bool: return data.traits.get(t, {}).get(key, false)):
			return true
	return false


## Första statusen med flaggan, eller "".
func flag_aura(u: CombatUnit, flag: String) -> String:
	for id in u.auras:
		if data.auras.get(id, {}).has(flag):
			return id
	return ""


## Statusens namn med staplarna ("Gift ×3").
## 0.30: förmågans bonus mot en status ("bonus_vs": {"aura", "mult"}, eller en lista av sådana) om målet har den,
## annars {}. Första statusen i listan som målet har gäller.
func _bonus_vs(ability_id: String, tgt: CombatUnit) -> Dictionary:
	return bonus_vs_for(data.abilities.get(ability_id, {}), tgt.auras)


static func bonus_vs_for(ab: Dictionary, auras: Dictionary) -> Dictionary:
	var raw = ab.get("bonus_vs", [])
	for vs in (raw if raw is Array else [raw]):
		if not vs.is_empty() and auras.has(vs.aura):
			return vs
	return {}


func status_name(u: CombatUnit, aura_id: String) -> String:
	var n: String = data.auras.get(aura_id, {}).get("name", aura_id)
	var stacks := int(u.auras.get(aura_id, {}).get("stacks", 1))
	return n if stacks <= 1 else "%s ×%d" % [n, stacks]


## Medelskadan för en träff (hjältebladet och testerna, 0.21): samma formler och samma modifierare som
## striden (egenskaper som Benrustning, auror som Försvarar och Sårbar), med variationen 1,0 och utan krit.
## Rör ingenting (förbrukar inga auror).
func expected_damage(src: CombatUnit, tgt: CombatUnit, ability_id: String) -> float:
	var ab: Dictionary = data.abilities.get(ability_id, {})
	var kind: String = ab.get("kind", "attack")
	var power := 1.0
	var school: String = ab.get("school", "physical")
	for eff in ab.get("effects", []):
		if eff.type == "damage":
			power = float(eff.get("power", 1.0))
			school = eff.get("school", school)
			break
	var raw := 0.0
	match kind:
		"spell":
			var tier: Array = SPELL_TIERS.get(ab.get("tier", ""), [1.0, 0.0])
			raw = spell_damage(src.stat("intelligence") * tier[0], tgt.defense_now(), power, tier[1])
		"indirect":
			raw = src.stat("attack") * power
		_:
			raw = attack_damage(src.stat("attack"), tgt.defense_now(), power)
	var probe := {"source": src.id, "target": tgt.id, "ability": ability_id, "school": school, "direct": true,
			"kind": kind, "from_trait": false, "origin_target": ""}
	var factors: Array = []
	for m in _modifiers(src, "modify_damage", probe):
		if m.has("damage_mult"):
			factors.append(float(m.damage_mult))
	for a in src.auras.values():
		if a.get("damage_mult", 1.0) != 1.0:
			factors.append(a.damage_mult)
	for m in _modifiers(tgt, "modify_damage_taken", probe):
		if m.has("damage_taken_mult"):
			factors.append(float(m.damage_taken_mult))
	factors.append_array(tgt.damage_taken_factors())
	if tgt.damage_taken_mult != 1.0:
		factors.append(tgt.damage_taken_mult)
	var vs := _bonus_vs(ability_id, tgt)
	if not vs.is_empty():
		factors.append(float(vs.mult))
	var dmg := raw * combine_mods(factors)
	if kind == "indirect":
		dmg = indirect_damage(dmg, tgt.defense_now())
	return dmg


## Medelhelningen för en förmåga (hjältebladet, 0.23.3): Int × styrka med samma modifierare som _heal (t.ex.
## Gryningens Större helning), variationen 1,0. Rör ingenting.
func expected_heal(src: CombatUnit, tgt: CombatUnit, ability_id: String) -> float:
	var power := 0.0
	for eff in ability(ability_id).get("effects", []):
		if eff.type == "heal" and eff.has("power"):
			power = float(eff.power)
			break
	var factors: Array = []
	for m in _modifiers(src, "modify_heal", {"source": src.id, "target": tgt.id, "ability": ability_id}):
		if m.has("heal_mult"):
			factors.append(float(m.heal_mult))
	if _rule("withered_grace"):
		factors.append(0.6)
	if omen == "omen_holy_ground":
		factors.append(OMEN_HEAL_MULT)
	return roundf(src.stat("intelligence") * power * combine_mods(factors))


## scaled: amount är en modifierare som räknas genom formeln; annars ett fast belopp (följdanfall för
## en andel av en träff, DoT, en andel av en stat) som bara Indirect-regeln drar Defense från.
func _deal_damage(src: CombatUnit, tgt: CombatUnit, amount: float, school: String,
		ability_id: String, can_crit: bool, direct := false, kind := "attack", scaled := false) -> void:
	if not tgt.alive:
		return
	var probe := {"source": src.id, "target": tgt.id, "ability": ability_id, "school": school,
			"direct": direct, "kind": kind, "from_trait": _trait_ctx != "",
			"origin_target": _origin.get("target", "")}
	_convert(src, probe)
	school = probe.school
	kind = probe.kind
	var ratio := src.speed / maxf(tgt.speed, 1.0)
	# Uträkningen (0.21): allt som påverkade siffran, så att spelaren kan se varför.
	var calc := {"source": src.id, "target": tgt.id, "source_name": src.name, "target_name": tgt.name,
			"ability": ability_id, "kind": kind, "school": school, "scaled": scaled, "amount_in": amount,
			"source_speed": src.speed, "target_speed": tgt.speed}
	if kind == "attack" and src.team != tgt.team:
		var dodge := _dodge_for(src, tgt, ratio, probe)
		var extra := 0.0
		var agile := flag_aura(tgt, "dodge_extra")
		if agile != "":
			extra = float(data.auras[agile].dodge_extra)
		# Förstenad: kan inte undvika (resistent: halva chansen).
		if has_flag(tgt, "stone"):
			dodge = dodge * 0.5 if tgt.resistant else 0.0
			extra = extra * 0.5 if tgt.resistant else 0.0
		calc.dodge_chance = dodge
		calc.dodge_extra = extra
		# Smidig: en extra, oberoende chans.
		if rng.randf() < dodge or (extra > 0.0 and rng.randf() < extra):
			_emit({"type": "dodge", "source": src.id, "target": tgt.id, "ability": ability_id, "calc": calc})
			return
	if is_immune(tgt):
		_emit({"type": "immune", "source": src.id, "target": tgt.id, "ability": ability_id})
		return
	# Skyddsskal (0.22): upphäver nästa anfall eller besvärjelse.
	if direct and kind in ["attack", "spell"] and tgt.auras.has("shelled") and src.team != tgt.team:
		_remove_aura(tgt, "shelled", "used")
		_emit({"type": "shelled", "source": src.id, "target": tgt.id, "ability": ability_id})
		return
	var fx: Array = []  # [{f, name}]
	if direct:
		var em := _consume_empower(src, probe)
		if em != 1.0:
			fx.append({"f": em, "name": ", ".join(_empower_names)})
	# VAL (Troligt i Siralim): bara attacker kan bli kritiska.
	var crit_add := 0.0  # Taggsten (0.20)
	if kind == "attack" and can_crit:
		for m in _modifiers(src, "modify_damage", probe):
			crit_add += float(m.get("crit_add", 0.0))
	var crit_chance := crit_chance_for(src.crit_chance, ratio) + crit_add if kind == "attack" and can_crit else 0.0
	var crit_extra := 0.0
	var savage := flag_aura(src, "crit_extra")
	if savage != "" and kind == "attack" and can_crit:
		crit_extra = float(data.auras[savage].crit_extra)
	# Förstenad: kan inte krita (resistent: halva chansen).
	if has_flag(src, "stone"):
		crit_chance = crit_chance * 0.5 if src.resistant else 0.0
		crit_extra = crit_extra * 0.5 if src.resistant else 0.0
	var crit: bool = kind == "attack" and can_crit and (rng.randf() < crit_chance
			or (crit_extra > 0.0 and rng.randf() < crit_extra)
			or (not has_flag(src, "stone") and _modify(src, "modify_damage", probe, "force_crit", false)))
	calc.crit_chance = crit_chance
	calc.crit_extra = crit_extra
	_formula_ctx = {}
	_ignore_defense = kind == "attack" and _modify(src, "modify_damage", probe, "ignore_defense", false)
	var raw := _formula(src, tgt, kind, amount, ability_id) if scaled else amount
	_ignore_defense = false
	calc.merge(_formula_ctx)
	calc.raw = raw
	var additional := 0.0
	for x in _modifiers_named(src, "modify_damage", probe):
		var m: Dictionary = x.modify
		if m.has("damage_mult"):
			fx.append({"f": float(m.damage_mult), "name": x.name})
		if m.has("damage_mult_per_aura"):
			fx.append({"f": 1.0 + float(m.damage_mult_per_aura) * _buff_count(src), "name": x.name})
		if m.has("damage_mult_per_dead_ally"):
			fx.append({"f": 1.0 + float(m.damage_mult_per_dead_ally) * _dead_allies(src), "name": x.name})
		if m.has("damage_mult_per_use"):
			fx.append({"f": 1.0 + float(m.damage_mult_per_use) * src.ability_uses.get(ability_id, 0), "name": x.name})
		if m.has("damage_mult_per_hit_taken"):
			fx.append({"f": 1.0 + float(m.damage_mult_per_hit_taken) * src.times_hit, "name": x.name})
		if m.has("damage_mult_per_family") and family_count(src) > 0:
			fx.append({"f": 1.0 + float(m.damage_mult_per_family) * family_count(src), "name": x.name})
		# 0.31 (Blodpakt, Paktkniven): mer skada för varje tiondel liv som saknas, högst "max".
		if m.has("damage_mult_per_missing_tenth"):
			var bonus := missing_tenths_bonus(src, float(m.damage_mult_per_missing_tenth), float(m.get("max", 0.5)))
			if bonus > 0.0:
				fx.append({"f": 1.0 + bonus, "name": x.name})
		if m.has("additional_from_stat"):
			additional += src.stat(m.additional_from_stat.stat) * float(m.additional_from_stat.pct)
			calc.additional_name = x.name
	if src.resistant and direct and ((kind == "attack" and has_flag(src, "scorn"))
			or (ability_id != src.attack_ability and has_flag(src, "silence"))):
		fx.append({"f": 0.5, "name": "%s (resistent)" % status_name(src, flag_aura(src, "scorn" if kind == "attack" else "silence"))})
	for aura_id in src.auras:
		var a: Dictionary = src.auras[aura_id]
		if a.get("damage_mult", 1.0) != 1.0:
			fx.append({"f": float(a.damage_mult), "name": status_name(src, aura_id)})
	var log_key := "%s:%s" % [src.id, ability_id]
	for x in _modifiers_named(tgt, "modify_damage_taken", probe):
		if x.modify.has("damage_taken_mult"):
			fx.append({"f": float(x.modify.damage_taken_mult), "name": x.name})
		# 0.27: Benmur (mindre skada per levande ur familjen) och Antecknat (mindre per tidigare träff av samma sak).
		if x.modify.has("damage_taken_mult_per_family") and family_count(tgt) > 0:
			fx.append({"f": 1.0 - float(x.modify.damage_taken_mult_per_family) * family_count(tgt), "name": x.name})
		if x.modify.has("damage_taken_less_per_repeat") and int(tgt.hit_log.get(log_key, 0)) > 0 \
				and not _team_has_trait_key(src, "ignore_repeat"):
			var less := minf(float(x.modify.damage_taken_less_per_repeat) * int(tgt.hit_log[log_key]),
					float(x.modify.get("repeat_max", 0.75)))
			fx.append({"f": 1.0 - less, "name": x.name})
	for aura_id in tgt.auras:
		var a: Dictionary = tgt.auras[aura_id]
		if a.damage_taken_mult != 1.0:
			fx.append({"f": float(a.damage_taken_mult), "name": status_name(tgt, aura_id)})
	if tgt.damage_taken_mult != 1.0:
		fx.append({"f": tgt.damage_taken_mult, "name": "%s tar" % tgt.name})
	if _release_bonus.get("unit", "") == src.id and _release_bonus.ability == ability_id:
		fx.append({"f": float(_release_bonus.mult), "name": "laddning"})
	# 0.30: förmågor som slår hårdare mot en status (Rättfärdigt slag mot Förblindad, introts kombination).
	var vs := _bonus_vs(ability_id, tgt)
	if direct and not vs.is_empty():
		fx.append({"f": float(vs.mult), "name": "%s mot %s" % [data.abilities[ability_id].name, status_name(tgt, vs.aura)]})
		calc.combo = {"ability": ability_id, "aura": vs.aura, "mult": float(vs.mult),
				"applier": String(tgt.auras[vs.aura].get("source", ""))}
	fx.append_array(_omen_damage_fx(src, ability_id, direct))
	var factors: Array = fx.map(func(x: Dictionary) -> float: return x.f)
	var mods := combine_mods(factors)
	var cb := crit_bonus(ratio) if crit else 0.0
	if crit and omen == "omen_full_moon":
		cb *= OMEN_CRIT_MULT
		calc.crit_omen = OMEN_CRIT_MULT
	var dmg := raw * mods * (1.0 + cb)
	calc.mods = fx
	calc.mod_total = mods
	calc.crit = crit
	calc.crit_bonus = cb
	calc.before_defense = dmg
	if kind == "indirect":
		calc.indirect_defense = INDIRECT_DEFENSE * tgt.defense_now()
		calc.defense = tgt.defense_now()
		calc.defense_base = tgt.defense
		calc.defense_parts = defense_parts(tgt)
		dmg = indirect_damage(dmg, tgt.defense_now())
	# 0.26: avrundas en gång, utan golvet på 1 som fanns förut. Med de små talen gjorde golvet svaga träffar (t.ex. 0,4
	# mot en som försvarar sig) upp till dubbelt så starka, och den första nedstigningen blev 5 procentenheter svårare.
	var total := roundf(dmg) + roundf(additional)
	calc.additional = roundf(additional)
	# 0.28 (Förmannens vakt, Siralims livvakt): en ur målets familj tar en del av den färdiga skadan.
	var guard := _guard_for(src, tgt)
	var guard_pct := _guard_pct(guard) if guard != null else 0.0
	# Moderns famn (strid-justering, Bortbytingen): målet själv skickar en del till den största ur familjen.
	var shelter := ""
	if guard == null and _shelter_kind_ok(tgt, kind):
		guard = _shelter_for(src, tgt)
		if guard != null:
			shelter = _shelter_trait(tgt)
			guard_pct = float(data.traits[shelter].shelter_family)
	var guarded := 0.0
	if guard != null and total > 0.0:
		guarded = roundf(total * guard_pct)
		total -= guarded
		calc.guarded = guarded
		calc.guard_name = guard.name
		if shelter != "":
			calc.shelter = data.traits[shelter].name
	var absorbed := minf(tgt.barrier, total)
	if absorbed > 0.0:
		tgt.barrier -= absorbed
		if tgt.barrier <= 0.0 and tgt.auras.has("barrier"):
			_remove_aura(tgt, "barrier", "broken")
	var lost := total - absorbed
	var life_lost := minf(lost, tgt.hp)  # Leeching räknar bara liv som faktiskt förlorades (vårt val)
	calc.total = total
	calc.absorbed = absorbed
	calc.lost = lost
	tgt.hp = maxf(0.0, tgt.hp - lost)
	if life_lost > 0.0 and is_charging(tgt) and tgt.hp > 0.0:
		_windup_damage(tgt, life_lost)
	# 0.26: en träff som Barriären inte tog räknas som en träff även om den avrundas till 0 (förut gav golvet på 1 alltid
	# minst 1). Då slår Domens kall, Rotskott och andra egenskaper till som förut, utan att den svaga träffen gör mer skada.
	var landed := lost > 0.0 or (absorbed <= 0.0 and dmg + additional > 0.0)
	if direct and landed:
		tgt.times_hit += 1
		if src.team != tgt.team:
			_last_attacker[tgt.id] = src.id  # 0.30.23: Broms Tull
	if landed:
		tgt.hit_log[log_key] = int(tgt.hit_log.get(log_key, 0)) + 1
	var leech := 0.0
	var leech_id := ""
	for aura_id in src.auras:
		if float(src.auras[aura_id].get("leech", 0.0)) > 0.0:
			leech += float(src.auras[aura_id].leech)
			leech_id = aura_id
	# 0.31: en sömn som träffen själv lägger (Den skingrade dimman, Vaggande nät) väcks inte av samma träff.
	var was_asleep := tgt.auras.has("sleeping")
	_emit({"type": "damage", "source": src.id, "target": tgt.id, "amount": lost, "absorbed": absorbed,
			"crit": crit, "school": school, "kind": kind, "ability": ability_id, "direct": direct, "calc": calc,
			"landed": landed})
	if tgt.hp <= 0.0:
		_kill(tgt, src)
	if guarded > 0.0:
		_guard_takes(src, guard, tgt, guarded, ability_id, shelter)
	# Leeching (0.22): en andel av skadan helar anfallaren; helningens uträkning pekar på träffen.
	if leech > 0.0 and life_lost > 0.0 and src.alive and src != tgt:
		_heal_ctx = {"base": life_lost * leech, "leech": true, "from_damage": life_lost, "leech_pct": leech,
				"damage_calc": calc}
		_heal(src, src, life_lost * leech, leech_id)
	# Rotskott (0.23, Hulda): en direkt träff från en fiende slår tillbaka genom rötterna.
	if direct and landed and src.team != tgt.team and src.alive:
		for aura_id in tgt.auras.keys():
			var root := float(data.auras.get(aura_id, {}).get("root_thorns", 0.0))
			var from := unit(tgt.auras.get(aura_id, {}).get("source", ""))
			if root > 0.0 and from != null and from.alive:
				var hit := from.stat("intelligence") * root * int(tgt.auras[aura_id].get("stacks", 1))
				_deal_damage(from, src, hit, "nature", aura_id, false, false, "indirect")
	# Sover: vaknar av skada.
	if landed and tgt.alive and was_asleep and tgt.auras.has("sleeping"):
		_remove_aura(tgt, "sleeping", "woke")
	# Speglande ben (våningsregel): en del av skadan från hjältarnas direkta träffar studsar tillbaka.
	if direct and landed and src.team == 0 and tgt.team == 1 and src.alive and _rule("mirror_bones"):
		_rule_hit("mirror_bones")
		_deal_damage(tgt, src, lost * 0.2, school, "mirror_bones", false, false, "indirect")


## 0.28: livvakten som tar en del av skadan mot målet: en levande ur målets familj (inte målet) med "guard_family",
## bara mot motståndarnas skada.
func _guard_for(src: CombatUnit, tgt: CombatUnit) -> CombatUnit:
	if src.team == tgt.team:
		return null
	for x in _family(tgt):
		if _guard_pct(x) > 0.0:
			return x
	return null


func _guard_pct(u: CombatUnit) -> float:
	for trait_id in u.traits:
		var pct := float(data.traits[trait_id].get("guard_family", 0.0))
		if pct > 0.0:
			return pct
	return 0.0


## Moderns famn (strid-justering, Bortbytingen): den som bär en egenskap med "shelter_family" skickar den andelen av
## motståndarnas skada till den största levande ur sin familj (högst maximalt liv, större än målet). Ingen sådan: null.
func _shelter_for(src: CombatUnit, tgt: CombatUnit) -> CombatUnit:
	if src.team == tgt.team or _shelter_trait(tgt) == "":
		return null
	var best: CombatUnit = null
	for x in _family(tgt):
		if x.max_hp > tgt.max_hp and (best == null or x.max_hp > best.max_hp):
			best = x
	return best


## Vem som tar emot u:s Moderns famn just nu (Inspect), annars null.
func shelter_keeper(u: CombatUnit) -> CombatUnit:
	for h in units:
		if h.team != u.team:
			return _shelter_for(h, u)
	return null


## "shelter_kind" (t.ex. "attack") begränsar famnen till den sortens skada; förmågor och indirekt skada går då rakt in.
func _shelter_kind_ok(u: CombatUnit, kind: String) -> bool:
	var t := _shelter_trait(u)
	return t != "" and String(data.traits[t].get("shelter_kind", kind)) == kind


func _shelter_trait(u: CombatUnit) -> String:
	for trait_id in u.traits:
		if float(data.traits[trait_id].get("shelter_family", 0.0)) > 0.0:
			return trait_id
	return ""


## Livvaktens andel: tas av Barriären och livet utan nya modifierare (skadan är redan färdigräknad).
## shelter: egenskapen när målet själv skickade skadan (Moderns famn), annars "".
func _guard_takes(src: CombatUnit, guard: CombatUnit, protected: CombatUnit, amount: float, ability_id: String,
		shelter := "") -> void:
	if not guard.alive:
		return
	var absorbed := minf(guard.barrier, amount)
	if absorbed > 0.0:
		guard.barrier -= absorbed
		if guard.barrier <= 0.0 and guard.auras.has("barrier"):
			_remove_aura(guard, "barrier", "broken")
	var lost := amount - absorbed
	guard.hp = maxf(0.0, guard.hp - lost)
	_emit({"type": "guarded", "source": src.id, "unit": guard.id, "protected": protected.id, "amount": lost,
			"absorbed": absorbed, "ability": ability_id, "shelter": shelter})
	if guard.hp <= 0.0:
		_kill(guard)


## Undvikande: från fartkvoten plus egenskaper med "dodge_add" (t.ex. Gastens Eterisk), högst 75 %.
func _dodge_for(src: CombatUnit, tgt: CombatUnit, ratio: float, probe: Dictionary) -> float:
	if _rule("heavy_air"):
		_rule_hit("heavy_air")
		return 0.0
	var chance := dodge_chance(1.0 / ratio)
	for m in _modifiers(tgt, "modify_damage_taken", probe):
		chance += float(m.get("dodge_add", 0.0))
	return minf(chance, maxf(DODGE_TRAIT_MAX, dodge_chance(1.0 / ratio)))


## Buffar figuren har (auror märkta "buff", och Barrier).
func _buff_count(u: CombatUnit) -> int:
	var n := 0
	for aura_id in u.auras:
		if data.auras[aura_id].get("buff", false):
			n += 1
	return n


## 0.31: bonusen för saknat liv, per hel tiondel, högst cap.
static func missing_tenths_bonus(u: CombatUnit, per: float, cap: float) -> float:
	var tenths := floori((1.0 - u.hp / maxf(u.max_hp, 1.0)) * 10.0 + 0.0001)
	return minf(per * maxi(tenths, 0), cap)


## Hur många i figurens lag som har fallit (och inte väckts).
func _dead_allies(u: CombatUnit) -> int:
	var n := 0
	for x in units:
		if x.team == u.team and not x.alive:
			n += 1
	return n


## Auror som förstärker nästa direkta anfall (t.ex. Välsignelse) förbrukas här.
func _consume_empower(src: CombatUnit, probe: Dictionary) -> float:
	var mult := 1.0
	_empower_names.clear()
	for aura_id in src.auras.keys():
		var d: Dictionary = data.auras[aura_id]
		if not d.has("next_attack_mult"):
			continue
		mult *= float(d.next_attack_mult)
		_empower_names.append(d.get("name", aura_id))
		if d.has("school"):
			probe.school = d.school
		_remove_aura(src, aura_id, "used")
	return mult


## Egenskaper som ändrar vad skadan räknas som ("convert_damage"), t.ex. följdanfall → Heliga besvärjelser.
func _convert(src: CombatUnit, probe: Dictionary) -> void:
	if not src.alive:
		return
	for trait_id in traits_of(src):
		var t: Dictionary = data.traits[trait_id]
		if t.trigger == "convert_damage" and _when(src, t.get("when", {}), probe):
			for key in t.convert:
				probe[key] = t.convert[key]


func _revive(u: CombatUnit, pct: float) -> void:
	if u.alive:
		return
	# 0.31: ett uppätet lik (Likmåltid, Den brutna gravspaden) väcks aldrig.
	if u.consumed:
		_emit({"type": "revive_blocked", "unit": u.id, "consumed": true})
		return
	# 0.27, Sista klangen (Klockarens motdrag, Satyr Guardian): motståndarnas lag får bara väcka n gånger per strid.
	for x in units:
		if x.alive and x.team != u.team:
			for trait_id in x.traits:
				var cap := int(data.traits[trait_id].get("limit_enemy_revives", -1))
				if cap >= 0 and int(_team_revives.get(u.team, 0)) >= cap:
					_emit({"type": "revive_blocked", "unit": u.id, "by": x.id, "trait": trait_id})
					return
	_team_revives[u.team] = int(_team_revives.get(u.team, 0)) + 1
	u.alive = true
	u.hp = u.max_hp * pct
	u.revives += 1
	u.stacks.clear()
	if not order.has(u.id) and u != current:
		order.push_back(u.id)
	_emit({"type": "revive", "unit": u.id})


## strid-langd (vårt val, textspelet: Kistornas råd tog 87 turer): fiendernas helningar mattas. Varje gång samma fiende
## helar med samma förmåga eller egenskap helar den HEAL_FADE mindre, ned till HEAL_FADE_MIN (Likvakan, Gravens lagning,
## Mässan). Den första helningen är hel, så fienden behåller sin roll, men en lång strid läker inte ihop av sig själv.
static var heal_fade := 0.15
static var heal_fade_min := 0.4
const HEAL_FADE_NAME := "Mattad helning"


func enemy_heal_fade(src: CombatUnit, ability_id: String) -> float:
	if src == null or src.team != 1 or heal_fade <= 0.0:
		return 1.0
	return maxf(heal_fade_min, 1.0 - heal_fade * enemy_heals_before(src, ability_id))


## Hur många tidigare turer fienden har helat med förmågan. En helning som träffar flera (Mässan) räknas en gång per tur.
func enemy_heals_before(src: CombatUnit, ability_id: String) -> int:
	var rec: Dictionary = _enemy_heals_by.get(src.id + ":" + ability_id, {})
	if rec.is_empty():
		return 0
	return int(rec.n) - (1 if int(rec.turn) == turn_no else 0)


func _count_enemy_heal(src: CombatUnit, ability_id: String) -> void:
	var key := src.id + ":" + ability_id
	var rec: Dictionary = _enemy_heals_by.get(key, {"n": 0, "turn": -1})
	if int(rec.turn) != turn_no:
		rec = {"n": int(rec.n) + 1, "turn": turn_no}
	_enemy_heals_by[key] = rec


## VAL (som Siralim, där bara attacker blir kritiska): helningar blir aldrig kritiska.
func _heal(src: CombatUnit, tgt: CombatUnit, base: float, ability_id: String) -> void:
	if not tgt.alive:
		return
	# 0.28, Ordensregeln (Abbedissans motdrag, Satyr Dominator): motståndarnas lag kan bara helas n gånger per tur.
	for x in units:
		if x.alive and x.team != tgt.team:
			for trait_id in x.traits:
				var cap := int(data.traits[trait_id].get("limit_enemy_heals", -1))
				if cap >= 0 and int(_team_heals.get(tgt.team, 0)) >= cap:
					_emit({"type": "heal_blocked", "unit": tgt.id, "by": x.id, "trait": trait_id})
					return
	# 0.30.23 Trollhud: en status med "no_heal" stoppar helningen (trollens läkning efter en förmåga).
	var sealed := flag_aura(tgt, "no_heal")
	if sealed != "":
		_emit({"type": "heal_blocked", "unit": tgt.id, "aura": sealed})
		return
	_team_heals[tgt.team] = int(_team_heals.get(tgt.team, 0)) + 1
	# Fördärvad (0.22): kan inte helas; helningen gör i stället skada (50 %).
	var blight := flag_aura(tgt, "blight")
	if blight != "":
		_heal_ctx = {}
		_emit({"type": "blighted", "unit": tgt.id})
		_deal_damage(src, tgt, base * float(data.auras[blight].blight), "shadow", blight, false, false, "pure")
		return
	var crit := false
	var fx: Array = []
	for x in _modifiers_named(src, "modify_heal", {"source": src.id, "target": tgt.id, "ability": ability_id}):
		if x.modify.has("heal_mult"):
			fx.append({"f": float(x.modify.heal_mult), "name": x.name})
	var fade := enemy_heal_fade(src, ability_id)
	if fade < 1.0:
		fx.append({"f": fade, "name": HEAL_FADE_NAME})
	if src.team == 1:
		_count_enemy_heal(src, ability_id)
	if _rule("withered_grace"):
		_rule_hit("withered_grace")
		fx.append({"f": 0.6, "name": data.floor_rules.get("withered_grace", {}).get("name", "Vissnad nåd")})
	if omen == "omen_holy_ground":
		fx.append({"f": OMEN_HEAL_MULT, "name": omen_name()})
	# Väktarsteg 2: mindre helning tagen – statusar (Skuld) och egenskaper hos målet ("modify_heal_taken").
	for aura_id in tgt.auras:
		var hm := float(tgt.auras[aura_id].get("heal_taken_mult", 1.0))
		if hm != 1.0:
			fx.append({"f": hm, "name": status_name(tgt, aura_id)})
	for x in _modifiers_named(tgt, "modify_heal_taken", {"source": src.id, "target": tgt.id, "ability": ability_id}):
		if x.modify.has("heal_taken_mult"):
			fx.append({"f": float(x.modify.heal_taken_mult), "name": x.name})
	var mods := combine_mods(fx.map(func(x: Dictionary) -> float: return x.f))
	var amount := roundf(base * mods)
	var effective := minf(amount, tgt.max_hp - tgt.hp)
	tgt.hp += effective
	var calc := {"source": src.id, "target": tgt.id, "source_name": src.name, "target_name": tgt.name,
			"ability": ability_id, "base": base, "mods": fx, "mod_total": mods, "amount": amount, "effective": effective}
	calc.merge(_heal_ctx)
	calc.base = base
	if data.auras.has(ability_id):
		calc.hot = true
	_heal_ctx = {}
	_emit({"type": "heal", "source": src.id, "target": tgt.id, "amount": amount,
			"effective": effective, "overheal": amount - effective, "crit": crit, "ability": ability_id, "calc": calc})


## Statusar (0.22, Siralims buffar och debuffar). En status är en aura med typ (buff/debuff), varaktighet i
## ägarens turer och ett staplingssätt i data/auras.json:
##   "stacking": "refresh" (standard: varaktigheten fylls på) eller "stack" (upp till "max_stacks"; varje stapel
##   ger hela effekten en gång till), "removes": [statusar som den tar bort], "cannot_dispel", "snare" (kan inte
##   flyttas på tidslinjen), "leech" (andel av skadan som helar bäraren), "stun" (förlorar turen) m.fl.
## Resistant (bossar, 0.22 som originalet): bara statusarna med en Resistant-version ändras (se _add_aura).
const FACTOR_KEYS := ["damage_taken_mult", "defense_mult", "damage_mult", "int_mult", "heal_taken_mult"]


func _add_aura(src: CombatUnit, tgt: CombatUnit, aura_id: String, duration_override := 0.0) -> void:
	if not tgt.alive:
		return
	var d: Dictionary = data.auras[aura_id]
	var kind := "buff" if d.get("buff", false) else ("debuff" if d.get("debuff", false) else "")
	if (kind == "debuff" and has_flag(tgt, "debuff_immune")) or _trait_immune(tgt, aura_id):
		_emit({"type": "status_immune", "unit": tgt.id, "aura": aura_id})
		return
	# 0.30.25 Fri: den som just slapp en kontroll kan inte låsas igen förrän efter sin nästa tur.
	if is_control(aura_id) and tgt.auras.has("unbound"):
		_emit({"type": "status_immune", "unit": tgt.id, "aura": aura_id, "unbound": true})
		return
	# En status som tar bort andra (t.ex. Snabb tar bort Långsam).
	for other in d.get("removes", []):
		if tgt.auras.has(other):
			_remove_aura(tgt, other, "replaced")
	var refreshed := tgt.auras.has(aura_id)
	var duration := duration_override if duration_override > 0.0 else float(d.get("duration", -1))
	var stacks := 1
	if refreshed:
		if tgt.auras[aura_id].remaining > duration:
			duration = tgt.auras[aura_id].remaining
		if d.get("stacking", "refresh") == "stack":
			stacks = mini(int(tgt.auras[aura_id].get("stacks", 1)) + 1, int(d.get("max_stacks", 3)))
	# DoT som en andel av källans stat (Siralims Burning: 30 % av Int, Poisoned: 30 % av Attack).
	var dot := float(d.get("dot", 0.0))
	if d.has("dot_stat"):
		dot = src.stat(d.dot_stat) * float(d.get("dot_pct", 0.3))
	# HoT på samma sätt (0.21: Förnyelse växer med kastarens Intelligence i stället för ett fast belopp).
	var hot := float(d.get("hot", 0.0))
	if d.has("hot_stat"):
		hot = src.stat(d.hot_stat) * float(d.get("hot_pct", 0.5))
	var a := {"remaining": duration, "duration": duration, "kind": kind, "stacks": stacks,
			"haste": float(d.get("haste", 0.0)), "leech": float(d.get("leech", 0.0)),
			"hot": hot * stacks, "dot": dot * stacks,
			"school": d.get("school", "physical"), "source": src.id}
	# 0.22, som originalet: bara statusar med en Resistant-version påverkas av Resistent (Blöder, Frusen,
	# Tystad, Hånad, Sover, Snärjd, Förstenad); andra debuffar verkar fullt på bossar.
	for key in FACTOR_KEYS:
		a[key] = 1.0 + (float(d.get(key, 1.0)) - 1.0) * stacks
	if d.has("freeze"):
		a.thaw = float(d.freeze) * (2.0 if tgt.resistant else 1.0)
	# 0.30.32: en kontroll som fylls på medan den sitter behåller chansen att tina eller slita sig loss. Förr började
	# den om från 25 % (Benstorm frös om en frusen hjälte, och i Benfurstens sal stod hen still i 4–5 egna turer).
	if refreshed:
		for key in ["thaw", "break"]:
			if tgt.auras[aura_id].has(key):
				a[key] = maxf(float(a.get(key, 0.0)), float(tgt.auras[aura_id][key]))
	tgt.auras[aura_id] = a
	if d.get("snare", false):
		_sink_snared()  # Snärjd: fast längst ned
	_emit({"type": "aura_applied", "unit": tgt.id, "aura": aura_id, "refreshed": refreshed, "source": src.id,
			"aura_kind": kind, "stacks": stacks})
	if d.get("silence", false) and is_charging(tgt) and windup_breaks(tgt.charging.ability, "silenced"):
		_break_windup(tgt, "silenced")
	if d.get("taunt", false):
		for e in enemies:
			if e.alive and not e.intent.is_empty() and ability(e.intent.ability).get("target", "") == "enemy":
				e.intent.targets = [tgt.id]


## Effekter på statusar och tidslinjen (0.22): dispel (tar bort buffar), purge (tar bort debuffar), to_top, to_bottom.
func _status_effect(effect: Dictionary, t: CombatUnit) -> void:
	match effect.type:
		"dispel":
			# Som originalet: Dispel tar bort både buffar och debuffar ("only" begränsar, t.ex. Skingra lögnen).
			if effect.get("only", "") != "debuff":
				_strip(t, "buff", int(effect.get("count", 99)), "dispel")
			if effect.get("only", "") != "buff":
				_strip(t, "debuff", int(effect.get("count", 99)), "dispel")
		"step_down":
			_step_down(t)
		"purge":
			_strip(t, "debuff", int(effect.get("count", 1)), "purge")
		"to_top":
			_move_on_timeline(t, "top")
		"to_bottom":
			_move_on_timeline(t, "bottom")


## Fingerfärdig (0.23, Imma): tar fiendens senaste buff och ger den till den svagaste allierade.
func _steal_buff(thief: CombatUnit, from: CombatUnit) -> void:
	var buffs := from.statuses("buff").filter(func(id: String) -> bool: return not data.auras[id].get("cannot_dispel", false))
	if buffs.is_empty():
		return
	var aura_id: String = buffs[-1]
	var left := float(from.auras[aura_id].get("remaining", 0.0))
	_remove_aura(from, aura_id, "stolen")
	var best: CombatUnit = null
	for a in _allies(thief):
		if best == null or a.hp_pct() < best.hp_pct():
			best = a
	if best:
		_add_aura(thief, best, aura_id, left if left > 0.0 else 0.0)
		_emit({"type": "buff_stolen", "unit": thief.id, "from": from.id, "to": best.id, "aura": aura_id})


## Ett steg ned på tidslinjen (0.23, Ronjas falk). Snärjd står redan längst ned.
func _step_down(u: CombatUnit) -> void:
	var i := order.find(u.id)
	if i < 0 or i >= order.size() - 1 or has_flag(u, "snare"):
		return
	order.remove_at(i)
	order.insert(i + 1, u.id)
	_emit({"type": "timeline_move", "unit": u.id, "dir": "down", "steps": 1})


## Höjer en stat resten av striden (0.23, Toves Spegelhand). Högst tre gånger startvärdet (vårt val).
func _raise_stat(u: CombatUnit, effect: Dictionary) -> void:
	var stat: String = effect.get("stat", "speed")
	var now := float(u.get(stat)) if stat != "health" else u.max_hp
	var cap := float(u.base_stats.get(stat, now)) * 3.0
	# 0.27 (Växande vrede): "additive" lägger till en andel av startvärdet, "max_times" gånger per strid. Räkningen står
	# i staplarna ("raise_<stat>"), som AI-villkoret self_stacks_at_least läser.
	if effect.has("max_times"):
		var key: String = effect.get("count_key", "raise_" + stat)  # 0.31: egen räkning (Gravhunger, bojan)
		if u.stacks.get(key, 0.0) >= float(effect.max_times):
			return
		u.stacks[key] = u.stacks.get(key, 0.0) + 1.0
	var v := minf(now * (1.0 + float(effect.get("pct", 0.1))), cap)
	if effect.get("additive", false):
		v = minf(now + float(u.base_stats.get(stat, now)) * float(effect.get("pct", 0.1)), cap)
	if stat == "health":
		u.max_hp = snap_stat(v)
	else:
		u.set(stat, v)
	_emit({"type": "stat_raised", "unit": u.id, "stat": stat, "value": v})


## Tar bort en status. reason: expired, used, broken, replaced, dispel, purge.
func _remove_aura(u: CombatUnit, aura_id: String, reason: String) -> void:
	if not u.auras.has(aura_id):
		return
	var kind: String = u.auras[aura_id].get("kind", "")
	u.auras.erase(aura_id)
	if aura_id == "barrier":
		u.barrier = 0.0
	_emit({"type": "aura_removed", "unit": u.id, "aura": aura_id, "aura_kind": kind, "reason": reason})
	_check_absolved(u, aura_id)
	if reason == "expired":
		_pass_aura(u, aura_id)
	if is_control(aura_id) and u.alive and data.auras.has("unbound"):
		_add_aura(u, u, "unbound")


## Väktarsteg 2 (Förhöret): en laddning med "target_aura" bryts när målet inte längre bär statusen (Skulden rensades).
func _check_absolved(u: CombatUnit, aura_id: String) -> void:
	for e in units:
		if e.team == u.team or not is_charging(e):
			continue
		if str(windup_of(e.charging.ability).get("target_aura", "")) == aura_id \
				and (e.intent.get("targets", []) as Array).has(u.id):
			_break_windup(e, "absolved")


## Väktarsteg 2 (Systrarnas krona): en status med "pass_to" går vidare när den löper ut eller bäraren faller.
## "trait:<id>" – till en annan levande i laget som bär egenskapen (slumpad); "weakest_ally" – till den allierade med
## lägst liv (inte bäraren). Finns ingen annan stannar den hos bäraren (om hen lever).
func _pass_aura(from: CombatUnit, aura_id: String) -> void:
	var d: Dictionary = data.auras.get(aura_id, {})
	var how := str(d.get("pass_to", ""))
	if how == "" or outcome != "":
		return
	var pool: Array[CombatUnit] = []
	for x in units:
		if x == from or not x.alive or x.team != from.team:
			continue
		if how.begins_with("trait:") and not x.traits.has(how.trim_prefix("trait:")):
			continue
		pool.append(x)
	var to: CombatUnit = null
	if how == "weakest_ally":
		for x in pool:
			if to == null or x.hp_pct() < to.hp_pct():
				to = x
	elif not pool.is_empty():
		to = pool[rng.randi() % pool.size()]
	if to == null and from.alive:
		to = from
	if to == null:
		return
	_add_aura(from if from.alive else to, to, aura_id)
	_emit({"type": "aura_passed", "unit": from.id, "to": to.id, "aura": aura_id})


## Väktarsteg 2 (Kistornas råd): egenskaper med "passes_on_death" går vidare till de levande i laget som själva bär en
## sådan egenskap (rådets medlemmar) när bäraren faller. Ordningen man fäller dem i blir ett val.
func _pass_traits(dead: CombatUnit) -> void:
	var heirs: Array[CombatUnit] = []
	for x in units:
		if x != dead and x.alive and x.team == dead.team and x.traits.any(func(t: String) -> bool:
				return data.traits.get(t, {}).get("passes_on_death", false)):
			heirs.append(x)
	if heirs.is_empty():
		return
	for trait_id in dead.traits.duplicate():
		if not data.traits.get(trait_id, {}).get("passes_on_death", false):
			continue
		var to: Array = []
		for h in heirs:
			if not h.traits.has(trait_id):
				h.traits.append(trait_id)
				to.append(h.id)
		if not to.is_empty():
			_emit({"type": "trait_passed", "unit": dead.id, "to": to, "trait": trait_id})


## 0.30.25: statusar som tar turer (Snärjd, Sover, Frusen). Efter en sådan blir figuren Fri en stund.
func is_control(aura_id: String) -> bool:
	var d: Dictionary = data.auras.get(aura_id, {})
	return d.has("snare") or d.has("sleep") or d.has("freeze")


## Dispel (buffar) och Purge (debuffar): tar bort upp till count statusar av typen, de senaste först.
## Statusar med "cannot_dispel" sitter kvar. Returnerar hur många som togs bort.
func _strip(u: CombatUnit, kind: String, count: int, reason: String) -> int:
	var ids: Array = u.auras.keys().filter(func(id: String) -> bool:
		return u.auras[id].get("kind", "") == kind and not data.auras[id].get("cannot_dispel", false))
	ids.reverse()
	var n := 0
	for id in ids:
		if n >= count:
			break
		_remove_aura(u, id, reason)
		n += 1
	return n


## Flyttar figuren på tidslinjen (0.22, Siralim): "top" = nästa tur, och den som stod överst skickas till
## botten; "bottom" = sist. Snärjd kan inte flyttas upp. En boss som skulle tvingas till botten flyttas bara ett
## steg, och Bottom fungerar inte på fiender i bosstrider. Flyttas en figur till toppen nollställs dess gränser per
## tur (originalet). Vårt val: samma figur kan flyttas till toppen högst MAX_TOP_PER_ROUND gånger per runda, så
## att två effekter inte kan mata varandra i all oändlighet.
const MAX_TOP_PER_ROUND := 1
var _top_moves := {}
var _round_start := 0


func _move_on_timeline(u: CombatUnit, dir: String) -> void:
	if not u.alive:
		return
	if dir == "top" and has_flag(u, "snare"):
		_emit({"type": "timeline_blocked", "unit": u.id, "dir": dir, "reason": "snared"})
		return
	var boss_battle := enemies.any(func(e: CombatUnit) -> bool: return data.enemies.get(e.kind, {}).get("boss", false))
	if dir == "bottom" and u.team == 1 and boss_battle and not data.enemies.get(u.kind, {}).get("boss", false):
		_emit({"type": "timeline_blocked", "unit": u.id, "dir": dir, "reason": "boss_battle"})
		return
	if dir == "top":
		var alive := units.filter(func(x: CombatUnit) -> bool: return x.alive).size()
		if turn_no - _round_start >= alive:
			_round_start = turn_no
			_top_moves.clear()
		if int(_top_moves.get(u.id, 0)) >= MAX_TOP_PER_ROUND:
			_emit({"type": "timeline_blocked", "unit": u.id, "dir": dir, "reason": "limit"})
			return
		_top_moves[u.id] = int(_top_moves.get(u.id, 0)) + 1
		_turn_counts.erase(u.id)  # gränserna per tur nollställs (originalet)
	var boss: bool = u.team == 1 and data.enemies.get(u.kind, {}).get("boss", false)
	if u == current:
		u.next_slot = dir if not (boss and dir == "bottom") else ""
		if dir == "top" and not order.is_empty() and order[0] != u.id:
			_send_down(unit(order[0]))
		_emit({"type": "timeline_move", "unit": u.id, "dir": dir, "steps": 0})
		return
	var i := order.find(u.id)
	if i < 0:
		return
	if dir == "top":
		var prev: String = order[0]
		order.remove_at(i)
		order.insert(0, u.id)
		if prev != u.id:
			_send_down(unit(prev))
	else:
		order.remove_at(i)
		var to := mini(i + 1, order.size()) if boss else order.size()
		order.insert(to, u.id)
	_sink_snared()
	_emit({"type": "timeline_move", "unit": u.id, "dir": dir, "steps": absi(order.find(u.id) - i)})


## 0.27 (Klockaren): flyttar en grupp överst på en gång i sin inbördes ordning. Ingen skickas ned, de andra
## hamnar efter gruppen. Snärjda står kvar.
func _group_to_top(group: Array[CombatUnit]) -> void:
	var moving: Array[String] = []
	if current and group.has(current) and not has_flag(current, "snare"):
		current.next_slot = "top"  # den som står på tur kommer först igen när turen är slut
	for id in order:
		var x := unit(id)
		if group.has(x) and x.alive and not has_flag(x, "snare"):
			moving.append(id)
	if moving.is_empty():
		return
	var before := order.duplicate()
	for id in moving:
		order.erase(id)
	for j in moving.size():
		order.insert(j, moving[j])
	for id in moving:
		_emit({"type": "timeline_move", "unit": id, "dir": "top", "steps": absi(before.find(id) - order.find(id))})


## Den som stod överst när någon flyttades till toppen skickas till botten (en boss bara ett steg).
func _send_down(x: CombatUnit) -> void:
	if x == null:
		return
	var i := order.find(x.id)
	if i < 0:
		return
	order.remove_at(i)
	var boss: bool = x.team == 1 and data.enemies.get(x.kind, {}).get("boss", false)
	order.insert(mini(i + 1, order.size()) if boss else order.size(), x.id)
	_emit({"type": "timeline_move", "unit": x.id, "dir": "bottom", "steps": 0, "pushed": true})


func _kill(u: CombatUnit, by: CombatUnit = null) -> void:
	if not u.alive:  # en egenskap kan ha dödat enheten mitt i en annan träff
		return
	var rebirth := float(data.auras.get(flag_aura(u, "rebirth"), {}).get("rebirth", 0.0))
	var had: Array = u.auras.keys()
	u.alive = false
	u.hp = 0.0
	u.deaths += 1
	u.auras.clear()
	u.barrier = 0.0
	u.charging = {}
	order.erase(u.id)
	var death := {"type": "death", "unit": u.id, "had": had}
	if by != null and by != u:
		death.source = by.id  # 0.31: den som fällde (Den brutna gravspaden)
	_emit(death)
	_check_channels()
	for aura_id in had:
		_pass_aura(u, aura_id)
	_pass_traits(u)
	if outcome != "" and u.team == 1:
		return
	# Pånyttfödd (0.22): återuppstår med 50 % liv; statusen förbrukas.
	if rebirth > 0.0:
		_revive(u, rebirth)
		return
	# De döda vaknar (våningsregel) och Edsbrytarens fall (trofé): återuppstå en gång.
	if u.team == 1 and u.revives == 0 and _rule("risen_dead"):
		_rule_hit("risen_dead")
		_revive(u, RISEN_DEAD_HP)
		return
	for trait_id in u.traits:
		var undying: Dictionary = data.traits[trait_id].get("undying", {})
		if not undying.is_empty() and u.revives == 0 and (not undying.get("requires_ability", false)
				or not u.ability_uses.is_empty()):
			_revive(u, float(undying.get("pct", 0.5)))
			return


# --- Egenskaper (traits) ----------------------------------------------------
# En egenskap lyssnar på en händelsetyp ("trigger") och kör effekter när villkoren i "when"
# stämmer. "modify_*" körs i stället innan siffrorna räknas ut. Händelser som en egenskap
# orsakar bär fältet "trait" och kan sätta igång andra egenskaper, men aldrig samma igen.
# "once_per_turn"/"max_per_turn" begränsar per tur (vems tur som helst); "internal_cooldown"
# räknas i turer (allas).
#
# Perk-nivåer (Siralims perk ranks): en perk med flera nivåer står en gång per nivå i listan, och
# "modify"-delarna räknas en gång per post (ökningar adderas). Bara rena siffror har nivåer.
#
# "scope": "party" (Siralims Specialization): egenskapen gäller som om varje levande allierad bar den,
# så "self" i villkoren betyder var och en av dem. Den verkar bara medan bäraren lever.
# En effekt kan ha "actor": event_unit/event_target/event_source – den i händelsen som utför
# effekten (annars den som bär egenskapen).

func _emit(e: Dictionary) -> void:
	if _trait_ctx != "":
		# Händelser där "trait" är själva innehållet (trait_passed, heal_blocked …) behåller det; egenskapen som
		# skickade dem står då i "ctx_trait" (textspelet: "Jägarinstinkt går vidare" fast det var Kistornas råd).
		if e.has("trait") and e.trait != _trait_ctx:
			e.ctx_trait = _trait_ctx
		else:
			e.trait = _trait_ctx
	events.append(e)
	_count_stats(e)
	if _trait_depth >= MAX_TRAIT_CHAIN or outcome != "" or _turn_procs >= TURN_PROC_LIMIT:
		return
	if e.type == "damage" and e.amount <= 0.0 and not e.get("landed", false):
		return  # Siralim: bara skada på livet räknas (inte träffar som Barrier tog)
	for owner in units:
		# 0.27: en egenskap med "on_own_death" verkar en sista gång när bäraren själv faller (Sista tjänsten).
		var own_death: bool = e.type == "death" and e.get("unit", "") == owner.id
		if not owner.alive and not own_death:
			continue
		for trait_id in (traits_of(owner) if owner.alive else owner.traits):
			var t: Dictionary = data.traits[trait_id]
			if t.trigger != e.type or e.get("trait", "") == trait_id or e.get("ctx_trait", "") == trait_id \
					or not _trait_ready(owner, trait_id, t):
				continue
			if not owner.alive and not t.get("on_own_death", false):
				continue
			if not _when(owner, t.get("when", {}), e):
				continue
			if t.has("chance") and rng.randf() >= float(t.chance):
				continue
			# 0.27: "every": n – bara var n:e gång villkoren stämmer (Klockrepet).
			if t.has("every"):
				var key: String = "every:" + trait_id
				owner.stack_progress[key] = int(owner.stack_progress.get(key, 0)) + 1
				if owner.stack_progress[key] < int(t.every):
					continue
				owner.stack_progress[key] = 0
			var last: Dictionary = owner.trait_ready.get(trait_id, {})
			var count: int = last.count + 1 if last.get("turn", -1) == turn_no else 1
			owner.trait_ready[trait_id] = {"turn": turn_no, "count": count,
					"ready_at": turn_no + int(t.get("internal_cooldown", 0))}
			_turn_procs += 1
			_run_trait(owner, trait_id, t, e)


func _count_stats(e: Dictionary) -> void:
	# 0.30: kombinationer (förmågans bonus mot en status) räknas för segerskärmens "Det här avgjorde striden".
	if e.type == "damage" and e.get("calc", {}).has("combo"):
		var c: Dictionary = e.calc.combo
		var cs: Dictionary = combo_stats.get(c.ability, {"unit": e.source, "aura": c.aura, "count": 0, "extra": 0.0})
		cs.count += 1
		cs.extra += e.amount - e.amount / float(c.mult)
		combo_stats[c.ability] = cs
	var trait_id: String = e.get("trait", "")
	if trait_id == "":
		return
	var st: Dictionary = trait_stats.get(trait_id, {"unit": "", "procs": 0, "damage": 0.0, "heal": 0.0})
	match e.type:
		"trait", "release":
			st.procs += 1
			st.unit = e.unit
		"damage":
			st.damage += e.amount
		"heal":
			st.heal += e.effective
	trait_stats[trait_id] = st


## Siralims gräns: räknar egenskapsutlösta attacker/besvärjelser per figur och mottagna helningar.
## Sant om det får ske.
func _within_limit(u: CombatUnit, kind: String) -> bool:
	var counts: Dictionary = _turn_counts.get(u.id, {})
	var n: int = counts.get(kind, 0)
	if n >= TURN_LIMIT:
		_emit({"type": "limit", "unit": u.id, "kind": kind})
		return false
	counts[kind] = n + 1
	_turn_counts[u.id] = counts
	return true


func _trait_ready(owner: CombatUnit, trait_id: String, t: Dictionary) -> bool:
	var last: Dictionary = owner.trait_ready.get(trait_id, {})
	if last.is_empty():
		return true
	if t.get("once_per_battle", false):
		return false
	var per_turn := 1 if t.get("once_per_turn", false) else int(t.get("max_per_turn", 0))
	if per_turn > 0 and last.turn == turn_no and last.count >= per_turn:
		return false
	return turn_no >= last.ready_at


## Egenskaperna som verkar för figuren: dess egna och de som levande allierade bär för hela
## sällskapet ("scope": "party").
func traits_of(u: CombatUnit) -> Array:
	var out: Array = u.traits
	var shared := []
	for x in units:
		if x == u or not x.alive or x.team != u.team:
			continue
		# En perk med flera nivåer står flera gånger i bärarens lista och räknas lika många gånger;
		# samma egenskap från en annan bärare räknas inte igen.
		var seen := shared.duplicate()
		for trait_id in x.traits:
			if data.traits[trait_id].get("scope", "") == "party" and not out.has(trait_id) and not seen.has(trait_id):
				shared.append(trait_id)
	if shared.is_empty():
		return out
	return out + shared


func _run_trait(owner: CombatUnit, trait_id: String, t: Dictionary, e: Dictionary) -> void:
	var outer := _trait_ctx
	var outer_origin := _origin
	_trait_ctx = trait_id
	_origin = e
	_trait_depth += 1
	_emit({"type": "trait", "unit": owner.id, "trait": trait_id})
	for effect in t.get("effects", []):
		var actor := _actor(owner, effect, e)
		if actor == null:
			continue
		for tgt in _trait_targets(actor, effect.get("target", "self"), e, []):
			_run_trait_effect(actor, trait_id, effect, tgt, e)
	_trait_depth -= 1
	_trait_ctx = outer
	_origin = outer_origin


## Vem som utför effekten: bäraren, eller en figur ur händelsen ("actor"). null om den inte lever.
func _actor(owner: CombatUnit, effect: Dictionary, e: Dictionary) -> CombatUnit:
	var who: String = effect.get("actor", "")
	if who == "":
		return owner
	var u := unit(e.get(who.trim_prefix("event_"), ""))
	return u if u != null and u.alive else null


## self, allies, other_allies (alla utom förmågans mål), enemy (första), enemies (alla),
## random_enemy, weakest_ally, dead_ally (första döda) eller ett fält i händelsen (source, target, unit …).
func _trait_targets(owner: CombatUnit, where: String, e: Dictionary, ability_targets: Array) -> Array[CombatUnit]:
	var out: Array[CombatUnit] = []
	match where:
		"self":
			out = [owner]
		"allies":
			out = _allies(owner)
		"enemies":
			out = _enemies(owner)
		"random_enemy":
			var foes := _enemies(owner)
			if not foes.is_empty():
				out = [foes[rng.randi() % foes.size()]]
		"dead_ally":
			for x in units:
				if not x.alive and not x.consumed and x.team == owner.team:
					out = [x]
					break
		"other_enemies":
			for x in _enemies(owner):
				if x.id != e.get("target", ""):
					out.append(x)
		"other_allies":
			for a in _allies(owner):
				if not ability_targets.has(a.id):
					out.append(a)
		"allies_except_unit":
			for a in _allies(owner):
				if a.id != e.get("unit", ""):
					out.append(a)
		"action_allies":
			# Allierade som handlingen riktades mot (Huldas Rotverk), utom bäraren själv.
			for id in e.get("targets", []):
				var a := unit(id)
				if a and a.alive and a.team == owner.team and a != owner:
					out.append(a)
		"weakest_ally":
			var best: CombatUnit = null
			for a in _allies(owner):
				if best == null or a.hp_pct() < best.hp_pct():
					best = a
			if best:
				out = [best]
		"enemy":
			var foes := _enemies(owner)
			if not foes.is_empty():
				out = [foes[0]]
		# 0.27: familjen (levande, bäraren oräknad) och en slumpad ur den.
		"family":
			out = _family(owner)
		"random_family":
			var kin := _family(owner)
			if not kin.is_empty():
				out = [kin[rng.randi() % kin.size()]]
		# 0.31 (Trådens slut): den fiende som står överst på tidslinjen.
		"top_enemy":
			for id in order:
				var x := unit(id)
				if x and x.alive and x.team != owner.team:
					out = [x]
					break
		_:
			if unit(e.get(where, "")) != null:
				out = [unit(e[where])]
	return out


func _run_trait_effect(owner: CombatUnit, trait_id: String, effect: Dictionary, tgt: CombatUnit, e := {}) -> void:
	# 0.26.3: en andel av en träff (pct_of_event) blir aldrig kritisk igen; träffen den räknas på kan redan ha varit det.
	var amount := 0.0
	if effect.has("pct_of_event"):
		# 0.28 (Spegelsköld): andelen växer med familjen.
		var pct := float(effect.pct_of_event) + float(effect.get("pct_per_family", 0.0)) * family_count(owner)
		amount = float(e.get(effect.get("event_field", "amount"), 0.0)) * pct
	elif effect.has("pct_max_hp"):
		amount = tgt.max_hp * float(effect.pct_max_hp)
	elif effect.type == "heal":
		amount = _heal_amount(owner, effect)  # 0.23.3: även en andel av en stat, så att uträkningen visar den
	elif effect.has("stat"):
		amount = _amount(owner, effect)  # en andel av en stat, t.ex. Barriär från Intelligence
	elif effect.type == "damage":
		amount = _amount(owner, effect)
	if effect.get("per_family", false):
		amount *= family_count(owner)  # 0.27: Sista tjänsten
	match effect.type:
		"damage":
			var kind: String = effect.get("kind", "attack")
			if kind != "indirect" and not _within_limit(owner, kind):
				return
			_deal_damage(owner, tgt, amount, effect.get("school", "physical"), trait_id,
					not effect.get("no_crit", false) and not effect.has("pct_of_event"), false, kind, _scaled(effect))
		"heal":
			if not _within_limit(tgt, "heal"):
				return
			_heal(owner, tgt, amount, trait_id)
		"barrier":
			_add_barrier(owner, tgt, amount)
		"revive":
			if not tgt.alive:
				_revive(tgt, float(effect.get("pct", 0.5)))
		"restore_charge":
			_restore_charge(tgt, int(effect.get("amount", 1)))
		"aura":
			# "event_aura": samma status som i händelsen (Liriens Allsång).
			var aura_id: String = e.get("aura", "") if effect.aura == "event_aura" else effect.aura
			if data.auras.has(aura_id):
				_add_aura(owner, tgt, aura_id, float(effect.get("duration", 0.0)))
		"stack":
			_add_stack(tgt, effect, e)
		"dispel", "purge", "to_top", "to_bottom", "step_down":
			_status_effect(effect, tgt)
		"consume_corpse":
			_consume_corpse(owner, tgt)
		"remove_aura":
			# 0.31 (Sluka): en bestämd status släpper.
			if tgt.auras.has(effect.aura):
				_remove_aura(tgt, effect.aura, "consumed")
		"raise_stat":
			if effect.has("pct_per_family"):
				# 0.28 (Fastan): mer för varje annan ur familjen.
				effect = effect.duplicate()
				effect.pct = float(effect.get("pct", 0.1)) + float(effect.pct_per_family) * family_count(owner)
			_raise_stat(tgt, effect)
		"steal_buff":
			_steal_buff(owner, tgt)
		# Väktarsteg 2 (Rådets sigill): bäraren ärver den fallnas troféegenskaper resten av striden.
		"inherit_trophy":
			var dead := unit(e.get("unit", ""))
			if dead != null and dead != tgt:
				for t in dead.traits:
					if data.traits.get(t, {}).get("trophy", false) and not tgt.traits.has(t):
						tgt.traits.append(t)
						_emit({"type": "trait_passed", "unit": dead.id, "to": [tgt.id], "trait": t})
		# Väktarsteg 2 (Kläppen): bryter en pågående laddning hos målet.
		"interrupt":
			if is_charging(tgt):
				_break_windup(tgt, "bell")
		"cast":
			# Utan "target" väljer förmågan själv; annars mot figuren ur händelsen (t.ex. samma fiende).
			# "ability_from_event": samma förmåga som i händelsen (Häxmästarinnans brutna spira kastar den igen).
			var cast_id: String = e.get("ability", "") if effect.get("ability_from_event", false) else effect.ability
			if data.abilities.has(cast_id):
				_auto_cast(owner, cast_id, tgt.id if effect.has("target") else "")


## Barrier: den starkaste gäller, de staplas inte (Siralim). VAL: högst figurens max liv.
func _add_barrier(src: CombatUnit, tgt: CombatUnit, amount: float) -> void:
	amount = minf(roundf(amount), tgt.max_hp)
	if not tgt.alive or amount <= tgt.barrier:
		return
	tgt.barrier = amount
	_add_aura(src, tgt, "barrier")


## Ger tillbaka Charges på den förmåga som har minst kvar (i andel av fullt).
func _restore_charge(u: CombatUnit, amount: int) -> void:
	var best := ""
	var best_share := 1.0
	for ability_id in u.charges:
		var full := full_charges(ability_id)
		if full <= 0 or u.charges[ability_id] >= full:
			continue
		var share := float(u.charges[ability_id]) / full
		if best == "" or share < best_share:
			best = ability_id
			best_share = share
	if best == "":
		return
	var gained: int = mini(amount, full_charges(best) - u.charges[best])
	u.charges[best] += gained
	_emit({"type": "charge_restored", "unit": u.id, "ability": best, "amount": gained})


## Samlar ihop en egenskapsmodifierare: multiplicerar tal, eller sant om någon egenskap säger sant.
func _modify(owner: CombatUnit, trigger: String, probe: Dictionary, key: String, base: Variant) -> Variant:
	var result: Variant = base
	for m in _modifiers(owner, trigger, probe):
		if not m.has(key):
			continue
		if result is bool:
			result = result or m[key]
		else:
			result *= float(m[key])
	return result


## "modify"-delarna i egenskaperna som gäller för händelsen (egna och sällskapets).
func _modifiers(owner: CombatUnit, trigger: String, probe: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for x in _modifiers_named(owner, trigger, probe):
		out.append(x.modify)
	return out


## Som _modifiers, men med egenskapens namn (för uträkningen, 0.21): [{modify, name}].
func _modifiers_named(owner: CombatUnit, trigger: String, probe: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not owner.alive:  # en död figurs egenskaper verkar inte (t.ex. brinnande sår från en död)
		return out
	for trait_id in traits_of(owner):
		var t: Dictionary = data.traits[trait_id]
		if t.trigger == trigger and t.has("modify") and _when(owner, t.get("when", {}), probe):
			out.append({"modify": t.modify, "name": t.get("name", trait_id)})
	return out


## Villkor för en egenskap. Händelsefält jämförs med "self", "ally", "enemy" eller ett värde.
func _when(owner: CombatUnit, when: Dictionary, e: Dictionary) -> bool:
	for key in when:
		var want: Variant = when[key]
		match key:
			"self_has_aura":
				if not owner.auras.has(want):
					return false
			"self_lacks_aura":
				if owner.auras.has(want):
					return false
			"not_from_trait":
				if want and e.has("trait"):
					return false
			"not_hot":
				# Den delade lågan: en HoT som tickar (Läkning, Förnyelse) räknas inte som att bäraren helar.
				if want and e.get("calc", {}).get("hot", false):
					return false
			"self_has_kind":
				if owner.has_kind(want) != true:
					return false
			"target_lacks_aura":
				var t := unit(e.get("target", ""))
				if t == null or t.auras.has(want):
					return false
			"target_has_kind":
				var t := unit(e.get("target", ""))
				if t == null or not t.has_kind(want):
					return false
			"unit_has_kind":
				var t := unit(e.get("unit", ""))
				if t == null or not t.has_kind(want):
					return false
			"self_hp_below":
				if owner.hp_pct() >= want:
					return false
			"target_hp_below":
				var t := unit(e.get("target", ""))
				if t == null or t.hp_pct() >= want:
					return false
			"target_has_aura":
				var t := unit(e.get("target", ""))
				if t == null or not t.auras.has(want):
					return false
			# 0.31 (Hullingar): den som orsakade händelsen har statusen.
			"source_has_aura":
				var t := unit(e.get("source", ""))
				if t == null or not t.auras.has(want):
					return false
			"target_has_any_aura":
				var t := unit(e.get("target", ""))
				if t == null or not want.any(func(a: String) -> bool: return t.auras.has(a)):
					return false
			"origin_target_has_aura":
				var t := unit(e.get("origin_target", ""))
				if t == null or not t.auras.has(want):
					return false
			"ability_not_basic":
				var who := unit(e.get("unit", ""))
				if who == null or e.get("ability", "") == who.attack_ability:
					return false
			"source_attacks_below":
				var src := unit(e.get("source", ""))
				if src == null or src.attacks_done >= int(want):
					return false
			"target_not_self":
				if e.get("target", "") == owner.id:
					return false
			"min_amount":
				if float(e.get("amount", 0.0)) < want:
					return false
			"min_effective":
				if float(e.get("effective", 0.0)) < want:
					return false
			"action_in":
				if not want.has(e.get("action", "")):
					return false
			# 0.27
			"unit_had_aura":
				if not e.get("had", []).has(want):
					return false
			"unit_in_family":
				var t := unit(e.get("unit", ""))
				if t == null or t == owner or owner.family == "" or t.family != owner.family or t.team != owner.team:
					return false
			# 0.28
			"target_in_family":
				var t := unit(e.get("target", ""))
				if t == null or t == owner or owner.family == "" or t.family != owner.family or t.team != owner.team:
					return false
			"self_family":
				if owner.family != want:
					return false
			# Djupets prägel (Bundna): en annan levande i laget bär egenskapen.
			"ally_has_trait":
				if not _allies(owner).any(func(x: CombatUnit) -> bool: return x != owner and traits_of(x).has(want)):
					return false
			"self_not_acted":
				if owner.last_ability != "":
					return false
			"unit_repeated_ability":
				if not repeated_ability(unit(e.get("unit", "")), e):
					return false
			# 0.30.23 (Trollhud): träffen kom från en förmåga, inte grundanfallet eller en egenskap.
			"source_used_ability":
				var src := unit(e.get("source", ""))
				var used: String = e.get("ability", "")
				if src == null or used == src.attack_ability or not data.abilities.has(used) \
						or used in ["defend", "provoke"]:
					return false
			"source_repeats_team_action":
				var src := unit(e.get("source", ""))
				if src == null or e.get("from_trait", false) or not team_repeats(src.team):
					return false
			"source_new_ability":
				var src := unit(e.get("source", ""))
				if src == null or e.get("from_trait", false) or src.last_ability == "" \
						or e.get("ability", "") == src.last_ability:
					return false
			_:
				if not e.has(key):
					return false
				var got: Variant = e[key]
				if want is String and want == "self":
					if got != owner.id:
						return false
				elif want is String and want in ["ally", "enemy"]:
					var u := unit(got)
					if u == null or (u.team == owner.team) != (want == "ally"):
						return false
				elif typeof(got) != typeof(want) or got != want:
					return false
	return true


# --- Staplar och förlösning -------------------------------------------------
# En egenskap kan ladda upp staplar ("stack"-effekt) som förbrukas när hjälten använder en viss
# förmåga ("release"). Inte samma sak som förmågornas Charges.

func _stack_cap(u: CombatUnit, effect: Dictionary) -> float:
	if effect.has("max_pct_hp"):
		return roundf(u.max_hp * float(effect.max_pct_hp))
	return float(effect.get("max", 5))


func _add_stack(u: CombatUnit, effect: Dictionary, e: Dictionary) -> void:
	var stack: String = effect.stack
	var every := int(effect.get("every", 1))
	if every > 1:
		u.stack_progress[stack] = u.stack_progress.get(stack, 0) + 1
		if u.stack_progress[stack] < every:
			return
		u.stack_progress[stack] = 0
	var amount := float(e.get(effect.amount_from, 0.0)) if effect.has("amount_from") else float(effect.get("amount", 1))
	u.stacks[stack] = minf(_stack_cap(u, effect), u.stacks.get(stack, 0.0) + amount)


## Plockar ut laddningarna som förmågan förbrukar och sätter skadebonusen för den här förmågan.
func _take_releases(caster: CombatUnit, ability_id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var mult := 1.0
	for trait_id in caster.traits:
		var release: Dictionary = data.traits[trait_id].get("release", {})
		var amount: float = caster.stacks.get(release.get("stack", ""), 0.0)
		if not _release_matches(caster, release, ability_id) or amount <= 0.0:
			continue
		caster.stacks[release.stack] = 0.0
		mult *= 1.0 + float(release.get("damage_mult_per", 0.0)) * amount
		out.append({"trait": trait_id, "release": release, "amount": amount})
	_release_bonus = {"unit": caster.id, "ability": ability_id, "mult": mult} if mult != 1.0 else {}
	return out


## En förlösning gäller en viss förmåga ("ability") eller vilken som helst av bärarens förmågor
## ("action": "ability").
func _release_matches(u: CombatUnit, release: Dictionary, ability_id: String) -> bool:
	if release.get("action", "") == "ability":
		return u.abilities.has(ability_id)
	return release.get("ability", "") == ability_id and ability_id != ""


func _run_release(caster: CombatUnit, r: Dictionary, ability_targets: Array) -> void:
	var outer := _trait_ctx
	_trait_ctx = r.trait
	_trait_depth += 1
	_emit({"type": "release", "unit": caster.id, "trait": r.trait, "stack": r.release.stack,
			"amount": r.amount})
	for effect in r.release.get("effects", []):
		var scaled: Dictionary = effect.duplicate()
		if effect.get("per_stack", false):
			for key in ["min", "max", "duration"]:
				if scaled.has(key):
					scaled[key] = float(scaled[key]) * r.amount
		for tgt in _trait_targets(caster, effect.get("target", "self"), {}, ability_targets):
			_run_trait_effect(caster, r.trait, scaled, tgt)
	_trait_depth -= 1
	_trait_ctx = outer


# --- Hjälpfunktioner --------------------------------------------------------

## 0.27: en hjälte med en förmåga som helar (pick "healer").
## 0.28 (Förhör, Inkvisitorns sigill): figuren använde samma förmåga två gånger i rad. Grundanfallet, Försvara och
## Provocera räknas inte.
func repeated_ability(u: CombatUnit, e: Dictionary) -> bool:
	var ability_id: String = e.get("ability", "")
	return u != null and e.get("action", "") in ["ability", "intent"] and ability_id != u.attack_ability \
			and not ability_id in ["defend", "provoke", "skip"] and u.prev_ability == ability_id


func is_healer(u: CombatUnit) -> bool:
	for ability_id in u.abilities:
		if ability(ability_id).get("effects", []).any(func(f: Dictionary) -> bool: return f.get("type", "") == "heal"):
			return true
	return false


func _add(u: CombatUnit) -> void:
	units.append(u)
	_by_id[u.id] = u


## Fiender som får anfallas med enkelmål: de som provocerar, annars alla.
func _taunting_enemies(u: CombatUnit) -> Array[CombatUnit]:
	var all := _enemies(u)
	var taunting: Array[CombatUnit] = []
	for x in all:
		if x.auras.keys().any(func(a: String) -> bool: return data.auras[a].get("taunt", false)):
			taunting.append(x)
	return taunting if not taunting.is_empty() else all


func _allies(u: CombatUnit) -> Array[CombatUnit]:
	var out: Array[CombatUnit] = []
	for x in units:
		if x.alive and x.team == u.team:
			out.append(x)
	return out


func _enemies(u: CombatUnit) -> Array[CombatUnit]:
	var out: Array[CombatUnit] = []
	for x in units:
		if x.alive and x.team != u.team:
			out.append(x)
	return out


## Väljer mål efter förmågans "target" och "pick" (lowest, random, first, healer, highest_attack, caster). Hån (taunt)
## styr fiendernas enkelmål, utom för förmågor med "ignore_taunt" (0.27).
func _pick_targets(caster: CombatUnit, ab: Dictionary) -> Array:
	var kind: String = ab.get("target", "self")
	match kind:
		"self":
			return [caster.id]
		"dead_ally":
			# 0.31: uppätna lik går inte att välja; "family" begränsar till den egna familjen (Likmåltid).
			var kin_only: bool = ab.get("family", false)
			for x in units:
				if not x.alive and not x.consumed and x.team == caster.team \
						and (not kin_only or (caster.family != "" and x.family == caster.family)):
					return [x.id]
			return []
		"all_enemies":
			return _enemies(caster).map(func(x: CombatUnit) -> String: return x.id)
		"all_allies":
			return _allies(caster).map(func(x: CombatUnit) -> String: return x.id)
	var pool := _enemies(caster) if kind == "enemy" else _allies(caster)
	if pool.is_empty():
		return []
	if kind == "enemy" and not ab.get("ignore_taunt", false):
		for x in pool:
			if x.auras.keys().any(func(a: String) -> bool: return data.auras[a].get("taunt", false)):
				return [x.id]
	# 0.31 (spindlarna): "pick_aura" – helst en som har statusen (Slukaren tar den Snärjda), sedan "pick" bland dem.
	if ab.has("pick_aura"):
		var marked := pool.filter(func(x: CombatUnit) -> bool: return x.auras.has(ab.pick_aura))
		if not marked.is_empty():
			pool.assign(marked)
	match ab.get("pick", "lowest"):
		# Väktarsteg 2 (Inkvisitorns Dom): den som bär flest staplar av statusen "pick_aura".
		"aura_stacks":
			var most: CombatUnit = null
			for x in pool:
				var n := int(x.auras.get(ab.get("pick_aura", ""), {}).get("stacks", 0))
				if n > 0 and (most == null or n > int(most.auras[ab.pick_aura].get("stacks", 0))):
					most = x
			if most != null:
				return [most.id]
		"random":
			return [pool[rng.randi() % pool.size()].id]
		"first":
			return [pool[0].id]
		# 0.27 (AI-tillägg 1): den som helar, den med högst Attack, den som senast kastade en besvärjelse.
		"healer":
			var healers: Array[CombatUnit] = []
			for x in pool:
				if is_healer(x):
					healers.append(x)
			if not healers.is_empty():
				pool = healers
		"highest_attack":
			var top := pool[0]
			for x in pool:
				if x.stat("attack") > top.stat("attack"):
					top = x
			return [top.id]
		"caster":
			var c := unit(_last_caster.get(1 - caster.team, ""))
			if c != null and pool.has(c):
				return [c.id]
		# 0.30.23: den som senast skadade kastaren med en direkt träff (Broms Tull).
		"last_attacker":
			var la := unit(_last_attacker.get(caster.id, ""))
			if la != null and pool.has(la):
				return [la.id]
	var best := pool[0]
	for x in pool:
		if x.hp_pct() < best.hp_pct():
			best = x
	return [best.id]
