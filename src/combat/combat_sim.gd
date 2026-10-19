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
## djup över 1 (8 %). Speed skalar inte (tidslinjen ska vara densamma). Mötet kan ha en egen "stat_mult"
## (våning 2 och 3 är starkare än 1, som i Siralim där fienderna skalar snabbare än laget).
const DEPTH_STEP := 0.08
const SCALED_STATS := ["health", "attack", "intelligence", "defense"]
## Elitvarianter (0.17, som Siralims sällsynta varelser): chans och styrka.
const ELITE_CHANCE := 0.06
const ELITE_PER_DEPTH := 0.01
const ELITE_PER_INSTABILITY := 0.03
const ELITE_MAX := 0.3
const ELITE_HEALTH := 1.4
const ELITE_POWER := 1.2
## Resistant: debuffar på figuren verkar till hälften (skadeökning, DoT, ändrad Defense).
const RESISTANT := 0.5
## Säkerhetsgräns för hur djupt egenskaper kan sätta igång varandra.
const MAX_TRAIT_CHAIN := 10
## Som i Siralim: per figur och pågående tur får egenskaper utlösa högst så många attacker,
## besvärjelser och mottagna helningar, plus en övergripande gräns.
const TURN_LIMIT := 5
const TURN_PROC_LIMIT := 60
## Handlingar en hjälte kan göra på sin tur ("ability" kräver vilken förmåga).
const ACTIONS := ["attack", "ability", "defend", "provoke", "skip"]
## Platser på slagfältet (sim-enheter, se UnitModel.to_world). Bara utseende.
const HERO_SLOTS := [Vector2(-95, 10), Vector2(-150, -75), Vector2(-165, 95), Vector2(-230, 15),
		Vector2(-240, -110), Vector2(-250, 130)]
const ENEMY_SLOTS := [Vector2(105, 5), Vector2(160, -80), Vector2(170, 90), Vector2(235, 0),
		Vector2(245, -120), Vector2(250, 125)]

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
## Våningsregler (data/floor_rules.json) som gäller i striden, och de som har slagit till.
var rules: Array = []
var rules_triggered: Array = []

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


## party: hjältar som ersätter mötets förvalda; traits: hero_id -> [trait_id, …] som ersätter
## hjältens förvalda egenskaper; charges: hero_id -> {ability_id: kvar} (annars fulla);
## artifacts: hero_id -> {type, ability}; depth: Realm Depth som skalar fienderna.
## opts: {"rules": [regel-id], "instability": n, "elite_chance": andel (annars elite_chance())}.
static func create(game_data: Dictionary, encounter_id: String, seed_value := 1,
		party: Array = [], traits := {}, charges := {}, artifacts := {}, depth := 1, opts := {}) -> CombatSim:
	var sim := CombatSim.new()
	sim.data = game_data
	sim.depth = maxi(depth, 1)
	sim.rules = opts.get("rules", []).duplicate()
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
	var counts := {}
	for i in enc.enemies.size():
		var kind: String = enc.enemies[i]
		counts[kind] = counts.get(kind, 0) + 1
		var e := CombatUnit.from_data("%s_%d" % [kind, counts[kind]], game_data.enemies[kind], 1)
		e.kind = kind
		e.position = ENEMY_SLOTS[i]
		scale_unit(e, enemy_mult(enc, sim.depth))
		# Elitvarianter slumpas med ett eget frö, så att striden i övrigt blir densamma.
		var chance: float = opts.get("elite_chance", elite_chance(sim.depth, int(opts.get("instability", 0))))
		var elite_rng := RandomNumberGenerator.new()
		elite_rng.seed = seed_value * 7919 + i
		if game_data.enemies[kind].has("elite") and elite_rng.randf() < chance:
			make_elite(e, game_data.enemies[kind].elite)
		e.traits = expand_traits(game_data, e.traits)
		sim._add(e)
		sim.enemies.append(e)
	return sim


# --- Publikt API ------------------------------------------------------------

## Chansen att en vanlig fiende är en elitvariant: 6 % och mer med djup och instabilitet, högst 30 %.
static func elite_chance(at_depth: int, instability := 0) -> float:
	return minf(ELITE_CHANCE + ELITE_PER_DEPTH * (maxi(at_depth, 1) - 1) + ELITE_PER_INSTABILITY * instability,
			ELITE_MAX)


## Gör fienden till sin elitvariant: eget namn, mer liv och skada, och elitens egenskap (samma som
## dess trofé, som i Siralim där trofén ger monstrets egenskap).
static func make_elite(e: CombatUnit, def: Dictionary) -> void:
	e.elite = true
	e.name = def.get("name", e.name)
	e.max_hp = roundf(e.max_hp * ELITE_HEALTH)
	e.hp = e.max_hp
	e.attack = roundf(e.attack * ELITE_POWER)
	e.intelligence = roundf(e.intelligence * ELITE_POWER)
	e.base_stats.health = e.max_hp
	e.base_stats.attack = e.attack
	e.base_stats.intelligence = e.intelligence
	if def.has("trait"):
		e.traits.append(def.trait)


## Hur mycket fiendernas stats växer på djupet: 1 + 8 % per djup över 1.
static func depth_mult(depth: int) -> float:
	return 1.0 + DEPTH_STEP * (maxi(depth, 1) - 1)


## Mötets skalning (våningen) gånger djupets.
static func enemy_mult(enc: Dictionary, depth: int) -> float:
	return float(enc.get("stat_mult", 1.0)) * depth_mult(depth)


## Skalar Health, Attack, Intelligence och Defense (inte Speed). Anropas före begin().
static func scale_unit(u: CombatUnit, mult: float) -> void:
	if is_equal_approx(mult, 1.0):
		return
	u.max_hp = roundf(u.max_hp * mult)
	u.hp = u.max_hp
	u.attack = roundf(u.attack * mult)
	u.intelligence = roundf(u.intelligence * mult)
	u.defense = roundf(u.defense * mult)
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
	hero.artifact = {"type": art.type, "ability": art.get("ability", "")}
	# Siralims artefakter höjer en stat; vi höjer med en andel ("stat_mult") eller ett tal ("stat_add").
	var stat: String = kind.stat
	var value := hero.max_hp if stat == "health" else float(hero.get(stat))
	value = value * float(kind.get("stat_mult", 1.0)) + float(kind.get("stat_add", 0.0))
	if stat == "health":
		hero.max_hp = roundf(value)
		hero.hp = hero.max_hp
	else:
		hero.set(stat, value)
	hero.base_stats[stat] = value
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
			"artifact": true, "trigger": trigger, "chance": kind.chance, "when": when,
			"effects": [{"type": "cast", "ability": ability_id}]}
	hero.traits.append(trait_id)


func begin() -> void:
	var alive: Array[CombatUnit] = units.duplicate()
	alive.sort_custom(func(a: CombatUnit, b: CombatUnit) -> bool:
		return a.speed > b.speed or (a.speed == b.speed and a.team < b.team))
	# Överraskning! (Siralims Surprise!): figurer med "start_first" börjar överst.
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
	return u.auras.keys().any(func(a: String) -> bool: return data.auras[a].get("silence", false))


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
	var choice := _hero_choice(current) if current.team == 0 else _enemy_choice(current)
	_perform(current, choice.ability, choice.action, choice.get("target", ""))
	_end_turn()


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
		u.turns_taken += 1
		_turn_counts.clear()
		_turn_procs = 0
		_emit({"type": "turn_start", "unit": u.id})
		_tick_turn_start(u)
		_check_outcome()
		if u.alive:
			return
		current = null


## I början av den egna turen: nedkylningar räknas ned och auror verkar och åldras.
func _tick_turn_start(u: CombatUnit) -> void:
	for key in u.cooldowns.keys():
		u.cooldowns[key] = maxf(0.0, u.cooldowns[key] - 1.0)
	if u.team == 0 and _rule("cursed_ground"):
		_rule_hit("cursed_ground")
		_deal_damage(u, u, roundf(u.max_hp * 0.05), "shadow", "cursed_ground", false, false, "indirect")
		if not u.alive:
			return
	for aura_id in u.auras.keys():
		if not u.auras.has(aura_id):
			continue  # försvann under turstarten (t.ex. en Barriär som tog slut)
		var a: Dictionary = u.auras[aura_id]
		var source := unit(a.source)
		if a.hot > 0.0:
			_heal(source if source else u, u, a.hot, aura_id)
		if a.dot > 0.0:
			_deal_damage(source if source else u, u, a.dot, a.school, aura_id, false, false, "indirect")
		if not u.alive:
			return
		if a.duration > 0.0:
			a.remaining -= 1.0
			if a.remaining <= 0.0:
				u.auras.erase(aura_id)
				_emit({"type": "aura_removed", "unit": u.id, "aura": aura_id})


## Den som har agerat läggs längst ned på tidslinjen. Fiender bestämmer då sin nästa handling.
func _end_turn() -> void:
	_check_outcome()
	if outcome != "":
		return
	if current and current.alive and current.team == 1 and _rule("vigilant_guards") and not _rule("no_guard"):
		_rule_hit("vigilant_guards")
		_add_aura(current, current, "defend")
	if current and current.alive and not order.has(current.id):
		order.push_back(current.id)
		if current.team == 1:
			_choose_intent(current)
	_next_turn()


func _rule(rule_id: String) -> bool:
	return rules.has(rule_id)


## En regel slog till: första gången i striden blir det en händelse (dolda regler avslöjas).
func _rule_hit(rule_id: String) -> void:
	if not rules_triggered.has(rule_id):
		rules_triggered.append(rule_id)
		_emit({"type": "rule", "rule": rule_id})


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


# --- AI ---------------------------------------------------------------------

## Fienden bestämmer sin nästa handling i början av striden och i slutet av sin tur, så att
## spelaren kan se den (som Siralims bossar som låser ett mål).
func _choose_intent(e: CombatUnit) -> void:
	for rule in ([] if is_silenced(e) else e.rules):
		var ability_id: String = rule.ability
		if e.cooldown_left(ability_id) > 0.0 or not _rule_matches(e, rule):
			continue
		if _rule("no_guard") and ability(ability_id).get("effects", []).any(func(f: Dictionary) -> bool:
				return f.get("aura", "") in ["defend", "provoke"]):
			_rule_hit("no_guard")
			continue
		e.intent = {"ability": ability_id, "targets": _pick_targets(e, ability(ability_id))}
		return
	e.intent = {"ability": e.attack_ability, "targets": _pick_targets(e, ability(e.attack_ability))}


func _enemy_choice(e: CombatUnit) -> Dictionary:
	if e.intent.is_empty() or e.cooldown_left(e.intent.ability) > 0.0 \
			or (is_silenced(e) and e.intent.ability != e.attack_ability):
		_choose_intent(e)
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
	if condition.get("dead_ally", false) and _pick_targets(u, {"target": "dead_ally"}).is_empty():
		return false
	return true


# --- Förmågor ---------------------------------------------------------------

func _perform(u: CombatUnit, ability_id: String, action: String, target_id: String) -> void:
	if ability_id == "skip":
		_emit({"type": "action", "unit": u.id, "action": "skip", "ability": "skip", "targets": []})
		return
	var ab := ability(ability_id)
	if u.charges.has(ability_id) and full_charges(ability_id) > 0:
		u.charges[ability_id] -= 1
	var targets := _targets_for(u, ab, target_id)
	var cooldown: float = ab.get("cooldown", 0.0)
	if cooldown > 0.0:
		u.cooldowns[ability_id] = cooldown + 1.0  # räknas ned i början av egna turer
	_emit({"type": "action", "unit": u.id, "action": action, "ability": ability_id, "targets": targets})
	_apply_effects(u, ability_id, targets)
	# Fiender agerar med "intent": deras grundanfall räknas som Anfall, resten som förmågor.
	if action == "attack" or (action == "intent" and ability_id == u.attack_ability):
		u.attacks_done += 1
	elif action in ["ability", "intent"]:
		u.ability_uses[ability_id] = u.ability_uses.get(ability_id, 0) + 1
		if u.team == 0 and _rule("sealed_words"):
			_rule_hit("sealed_words")
			u.sealed[ability_id] = true
	if u.alive:
		_emit({"type": "acted", "unit": u.id, "action": action, "ability": ability_id, "targets": targets})


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
	var chosen := unit(target_id) if target_id != "" else null
	var kind: String = ab.get("target", "self")
	if kind == "enemy" and chosen and not _taunting_enemies(u).has(chosen):
		chosen = null  # en provocerande fiende måste anfallas först
	if chosen and chosen.alive and ((kind == "enemy" and chosen.team != u.team) or (kind == "ally" and chosen.team == u.team)):
		return [chosen.id]
	return _pick_targets(u, ab)


func _apply_effects(caster: CombatUnit, ability_id: String, targets: Array) -> void:
	var ab := ability(ability_id)
	var can_crit: bool = not ab.get("no_crit", false)
	var releases := _take_releases(caster, ability_id)
	for effect in ab.get("effects", []):
		for target_id in targets:
			var t := unit(target_id)
			if t == null or (not t.alive and effect.type != "revive"):
				continue
			match effect.type:
				"damage":
					_deal_damage(caster, t, _amount(caster, effect), effect.get("school", ab.get("school", "physical")),
							ability_id, can_crit, true, ab.get("kind", "attack"), _scaled(effect))
				"heal":
					_heal(caster, t, _heal_amount(caster, effect), ability_id)
				"aura":
					_add_aura(caster, t, effect.aura, float(effect.get("duration", 0.0)))
				"revive":
					_revive(t, float(effect.get("pct", 0.5)))
	_release_bonus = {}
	for r in releases:
		_run_release(caster, r, targets)


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
		return _amount(u, effect)
	return u.intelligence * _roll() * float(effect.get("power", 1.0))


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
	match kind:
		"spell":
			var tier: Array = SPELL_TIERS.get(data.abilities.get(ability_id, {}).get("tier", ""), [1.0, 0.0])
			return spell_damage(src.intelligence * tier[0] * _roll(), tgt.defense_now(), power, tier[1])
		"indirect":
			return src.attack * _roll() * power
	return attack_damage(src.attack * _roll(), tgt.defense_now(), power)


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
	if kind == "attack" and src.team != tgt.team and rng.randf() < _dodge_for(src, tgt, ratio, probe):
		_emit({"type": "dodge", "source": src.id, "target": tgt.id, "ability": ability_id})
		return
	if is_immune(tgt):
		_emit({"type": "immune", "source": src.id, "target": tgt.id, "ability": ability_id})
		return
	var factors: Array = []
	if direct:
		factors.append(_consume_empower(src, probe))
	# VAL (Troligt i Siralim): bara attacker kan bli kritiska.
	var crit: bool = kind == "attack" and can_crit and (rng.randf() < crit_chance_for(src.crit_chance, ratio)
			or _modify(src, "modify_damage", probe, "force_crit", false))
	var raw := _formula(src, tgt, kind, amount, ability_id) if scaled else amount
	var additional := 0.0
	for m in _modifiers(src, "modify_damage", probe):
		if m.has("damage_mult"):
			factors.append(float(m.damage_mult))
		if m.has("damage_mult_per_aura"):
			factors.append(1.0 + float(m.damage_mult_per_aura) * _buff_count(src))
		if m.has("damage_mult_per_dead_ally"):
			factors.append(1.0 + float(m.damage_mult_per_dead_ally) * _dead_allies(src))
		if m.has("damage_mult_per_use"):
			factors.append(1.0 + float(m.damage_mult_per_use) * src.ability_uses.get(ability_id, 0))
		if m.has("damage_mult_per_hit_taken"):
			factors.append(1.0 + float(m.damage_mult_per_hit_taken) * src.times_hit)
		if m.has("additional_from_stat"):
			additional += src.stat(m.additional_from_stat.stat) * float(m.additional_from_stat.pct)
	for a in src.auras.values():
		if a.get("damage_mult", 1.0) != 1.0:
			factors.append(a.damage_mult)
	for m in _modifiers(tgt, "modify_damage_taken", probe):
		if m.has("damage_taken_mult"):
			factors.append(float(m.damage_taken_mult))
	factors.append_array(tgt.damage_taken_factors())
	if tgt.damage_taken_mult != 1.0:
		factors.append(tgt.damage_taken_mult)
	if _release_bonus.get("unit", "") == src.id and _release_bonus.ability == ability_id:
		factors.append(_release_bonus.mult)
	var dmg := raw * combine_mods(factors) * ((1.0 + crit_bonus(ratio)) if crit else 1.0)
	if kind == "indirect":
		dmg = indirect_damage(dmg, tgt.defense_now())
	var total := maxf(1.0, roundf(dmg)) + roundf(additional)
	var absorbed := minf(tgt.barrier, total)
	if absorbed > 0.0:
		tgt.barrier -= absorbed
		if tgt.barrier <= 0.0 and tgt.auras.has("barrier"):
			tgt.auras.erase("barrier")
			_emit({"type": "aura_removed", "unit": tgt.id, "aura": "barrier"})
	var lost := total - absorbed
	tgt.hp = maxf(0.0, tgt.hp - lost)
	if direct and lost > 0.0:
		tgt.times_hit += 1
	_emit({"type": "damage", "source": src.id, "target": tgt.id, "amount": lost, "absorbed": absorbed,
			"crit": crit, "school": school, "kind": kind, "ability": ability_id, "direct": direct})
	if tgt.hp <= 0.0:
		_kill(tgt)
	# Speglande ben (våningsregel): en del av skadan från hjältarnas direkta träffar studsar tillbaka.
	if direct and lost > 0.0 and src.team == 0 and tgt.team == 1 and src.alive and _rule("mirror_bones"):
		_rule_hit("mirror_bones")
		_deal_damage(tgt, src, roundf(lost * 0.2), school, "mirror_bones", false, false, "indirect")


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
	for aura_id in src.auras.keys():
		var d: Dictionary = data.auras[aura_id]
		if not d.has("next_attack_mult"):
			continue
		mult *= float(d.next_attack_mult)
		if d.has("school"):
			probe.school = d.school
		src.auras.erase(aura_id)
		_emit({"type": "aura_removed", "unit": src.id, "aura": aura_id})
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
	u.alive = true
	u.hp = roundf(u.max_hp * pct)
	u.revives += 1
	u.stacks.clear()
	if not order.has(u.id) and u != current:
		order.push_back(u.id)
	_emit({"type": "revive", "unit": u.id})


## VAL (som Siralim, där bara attacker blir kritiska): helningar blir aldrig kritiska.
func _heal(src: CombatUnit, tgt: CombatUnit, base: float, ability_id: String) -> void:
	if not tgt.alive:
		return
	var crit := false
	var factors: Array = []
	for m in _modifiers(src, "modify_heal", {"source": src.id, "target": tgt.id, "ability": ability_id}):
		if m.has("heal_mult"):
			factors.append(float(m.heal_mult))
	if _rule("withered_grace"):
		_rule_hit("withered_grace")
		factors.append(0.6)
	var amount := roundf(base * combine_mods(factors))
	var effective := minf(amount, tgt.max_hp - tgt.hp)
	tgt.hp += effective
	_emit({"type": "heal", "source": src.id, "target": tgt.id, "amount": amount,
			"effective": effective, "overheal": amount - effective, "crit": crit, "ability": ability_id})


func _add_aura(src: CombatUnit, tgt: CombatUnit, aura_id: String, duration_override := 0.0) -> void:
	if not tgt.alive:
		return
	var d: Dictionary = data.auras[aura_id]
	var refreshed := tgt.auras.has(aura_id)
	var duration := duration_override if duration_override > 0.0 else float(d.get("duration", -1))
	if refreshed and tgt.auras[aura_id].remaining > duration:
		duration = tgt.auras[aura_id].remaining
	# DoT som en andel av källans stat (Siralims Burning: 30 % av Int, Poisoned: 30 % av Attack).
	var dot := float(d.get("dot", 0.0))
	if d.has("dot_stat"):
		dot = roundf(src.stat(d.dot_stat) * float(d.get("dot_pct", 0.3)))
	var a := {"remaining": duration, "duration": duration,
			"haste": float(d.get("haste", 0.0)), "damage_taken_mult": float(d.get("damage_taken_mult", 1.0)),
			"defense_mult": float(d.get("defense_mult", 1.0)), "damage_mult": float(d.get("damage_mult", 1.0)),
			"hot": float(d.get("hot", 0.0)), "dot": dot,
			"school": d.get("school", "physical"), "source": src.id}
	if tgt.resistant and d.get("debuff", false):
		for key in ["damage_taken_mult", "defense_mult", "damage_mult"]:
			a[key] = resisted(a[key])
		a.dot = roundf(a.dot * RESISTANT)
	tgt.auras[aura_id] = a
	_emit({"type": "aura_applied", "unit": tgt.id, "aura": aura_id, "refreshed": refreshed})
	if d.get("taunt", false):
		for e in enemies:
			if e.alive and not e.intent.is_empty() and ability(e.intent.ability).get("target", "") == "enemy":
				e.intent.targets = [tgt.id]


## Resistant: en debuffs ändring av en faktor halveras (×1,2 → ×1,1, ×0,65 → ×0,825).
static func resisted(factor: float) -> float:
	return 1.0 + (factor - 1.0) * RESISTANT


func _kill(u: CombatUnit) -> void:
	if not u.alive:  # en egenskap kan ha dödat enheten mitt i en annan träff
		return
	u.alive = false
	u.hp = 0.0
	u.deaths += 1
	u.auras.clear()
	u.barrier = 0.0
	order.erase(u.id)
	_emit({"type": "death", "unit": u.id})
	if outcome != "" and u.team == 1:
		return
	# De döda vaknar (våningsregel) och Kaosets hjärta (trofé): återuppstå en gång.
	if u.team == 1 and u.revives == 0 and _rule("risen_dead"):
		_rule_hit("risen_dead")
		_revive(u, 0.25)
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
		e.trait = _trait_ctx
	events.append(e)
	_count_stats(e)
	if _trait_depth >= MAX_TRAIT_CHAIN or outcome != "" or _turn_procs >= TURN_PROC_LIMIT:
		return
	if e.type == "damage" and e.amount <= 0.0:
		return  # Siralim: bara skada på livet räknas (inte träffar som Barrier tog)
	for owner in units:
		if not owner.alive:
			continue
		for trait_id in traits_of(owner):
			var t: Dictionary = data.traits[trait_id]
			if t.trigger != e.type or e.get("trait", "") == trait_id or not _trait_ready(owner, trait_id, t):
				continue
			if not _when(owner, t.get("when", {}), e):
				continue
			if t.has("chance") and rng.randf() >= float(t.chance):
				continue
			var last: Dictionary = owner.trait_ready.get(trait_id, {})
			var count: int = last.count + 1 if last.get("turn", -1) == turn_no else 1
			owner.trait_ready[trait_id] = {"turn": turn_no, "count": count,
					"ready_at": turn_no + int(t.get("internal_cooldown", 0))}
			_turn_procs += 1
			_run_trait(owner, trait_id, t, e)


func _count_stats(e: Dictionary) -> void:
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
				if not x.alive and x.team == owner.team:
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
		_:
			if unit(e.get(where, "")) != null:
				out = [unit(e[where])]
	return out


func _run_trait_effect(owner: CombatUnit, trait_id: String, effect: Dictionary, tgt: CombatUnit, e := {}) -> void:
	var amount := 0.0
	if effect.has("pct_of_event"):
		amount = float(e.get(effect.get("event_field", "amount"), 0.0)) * float(effect.pct_of_event)
	elif effect.has("pct_max_hp"):
		amount = tgt.max_hp * float(effect.pct_max_hp)
	elif effect.has("stat"):
		amount = _amount(owner, effect)  # en andel av en stat, t.ex. Barriär från Intelligence
	elif effect.type == "damage":
		amount = _amount(owner, effect)
	elif effect.type == "heal":
		amount = _heal_amount(owner, effect)
	match effect.type:
		"damage":
			var kind: String = effect.get("kind", "attack")
			if kind != "indirect" and not _within_limit(owner, kind):
				return
			_deal_damage(owner, tgt, amount, effect.get("school", "physical"), trait_id,
					not effect.get("no_crit", false), false, kind, _scaled(effect))
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
			_add_aura(owner, tgt, effect.aura, float(effect.get("duration", 0.0)))
		"stack":
			_add_stack(tgt, effect, e)
		"cast":
			# Utan "target" väljer förmågan själv; annars mot figuren ur händelsen (t.ex. samma fiende).
			# "ability_from_event": samma förmåga som i händelsen (Mirakel kastar den igen).
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
	if not owner.alive:  # en död figurs egenskaper verkar inte (t.ex. brinnande sår från en död)
		return out
	for trait_id in traits_of(owner):
		var t: Dictionary = data.traits[trait_id]
		if t.trigger == trigger and t.has("modify") and _when(owner, t.get("when", {}), probe):
			out.append(t.modify)
	return out


## Villkor för en egenskap. Händelsefält jämförs med "self", "ally", "enemy" eller ett värde.
func _when(owner: CombatUnit, when: Dictionary, e: Dictionary) -> bool:
	for key in when:
		var want: Variant = when[key]
		match key:
			"self_has_aura":
				if not owner.auras.has(want):
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


## Väljer mål efter förmågans "target" och "pick" (lowest, random, first). Hån (taunt) styr
## fiendernas enkelmål.
func _pick_targets(caster: CombatUnit, ab: Dictionary) -> Array:
	var kind: String = ab.get("target", "self")
	match kind:
		"self":
			return [caster.id]
		"dead_ally":
			for x in units:
				if not x.alive and x.team == caster.team:
					return [x.id]
			return []
		"all_enemies":
			return _enemies(caster).map(func(x: CombatUnit) -> String: return x.id)
		"all_allies":
			return _allies(caster).map(func(x: CombatUnit) -> String: return x.id)
	var pool := _enemies(caster) if kind == "enemy" else _allies(caster)
	if pool.is_empty():
		return []
	if kind == "enemy":
		for x in pool:
			if x.auras.keys().any(func(a: String) -> bool: return data.auras[a].get("taunt", false)):
				return [x.id]
	match ab.get("pick", "lowest"):
		"random":
			return [pool[rng.randi() % pool.size()].id]
		"first":
			return [pool[0].id]
	var best := pool[0]
	for x in pool:
		if x.hp_pct() < best.hp_pct():
			best = x
	return [best.id]
