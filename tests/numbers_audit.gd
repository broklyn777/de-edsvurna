extends RefCounted
## Granskningen av siffrorna (0.23.3): kör seedade strider med AuditSim och räknar om varje skada, helning och
## undvikande med numbers_reference.gd ur läget precis före träffen. Jämför med siffran spelet visade och med
## texten som DamageExplain skriver. Används av tests/test_numbers_audit.gd (ett urval) och av
## tests/numbers_audit_report.gd (många strider).
##
## Det enda som tas från spelets egen uträkning är tärningsslagen (variationen, om det blev krit och om ett
## anfall undveks), modifierarnas namn (för att para ihop dem) och vilken effekt i en egenskap som körde.
## Allt annat – Defense just nu, modifierarna, krit-chansen, undvikandet, formeln, avrundningen, Barriären och
## livet efteråt – räknas här på nytt ur figurernas stats och statusar och ur datan.

const Ref := preload("res://tests/numbers_reference.gd")
const AuditSim := preload("res://tests/audit_sim.gd")
const Bot := preload("res://tests/combat_bot.gd")

## Statusar som granskningen sätter på slumpade figurer under striden (utöver dem förmågorna ger).
const AUDIT_STATUSES := ["vulnerable", "weak", "protected", "berserk", "bleeding", "burning", "poisoned", "leeching",
		"mending", "agile", "savage", "stone", "marked", "salted", "shelled", "blighted", "renew", "defend", "provoke",
		"warded", "holy_shield", "inspired", "blessing", "silenced", "scorned", "rebirth"]
const EPS := 0.011

var data: Dictionary
var counts := {"damage": 0, "dodge": 0, "heal": 0, "immune": 0, "shelled": 0, "blighted": 0, "battles": 0,
		"fixed_unchecked": 0, "explain": 0, "enemies": 0, "heroes": 0}
var mismatches: Array[String] = []
## Samma sorts fel räknas en gång per nyckel, med ett exempel (rapporten blir läsbar).
var by_key := {}
## Modifierarna som förekom i de omräknade träffarna (namn -> antal), för rapporten.
var mods_seen := {}
## Fasta belopp som inte räknades om (sort -> antal), för rapporten.
var unchecked := {}


func _init(game_data: Dictionary) -> void:
	data = game_data


func _fail(key: String, text: String) -> void:
	if not by_key.has(key):
		by_key[key] = {"n": 0, "example": text}
		mismatches.append(text)
	by_key[key].n += 1


# --- Strider ---------------------------------------------------------------

## En strid: realm (crypt/chapel), våning (0–2), djup, sällskap, artefakter, statusar och regler.
func run_battle(encounter: String, floor_i: int, depth: int, seed_value: int, party: Array, artifacts := {},
		statuses := false, rules: Array = [], level := 0, traits := {}, bonus := 1.0, extra := {}) -> void:
	var opts := {"rules": rules, "floor": floor_i}
	opts.merge(extra)
	if bonus != 1.0:
		opts.stat_bonus = bonus
	if level > 0:
		opts.levels = Bot.party_levels(data, level, party)
		# Personligheter: varannan hjälte får en, så att tillväxten 40/20 % prövas.
		var names: Array = data.personalities.keys()
		for i in party.size():
			if i % 2 == 1:
				opts.levels[party[i]].personality = names[(seed_value + i) % names.size()]
	var base := CombatSim.create(data, encounter, seed_value, party, traits, {}, artifacts, depth, opts)
	check_units(base, encounter, depth, floor_i, party, artifacts, opts)
	var sim: CombatSim = AuditSim.adopt(base)
	var srng := RandomNumberGenerator.new()
	srng.seed = seed_value * 31 + 7
	sim.begin()
	var guard := 0
	while sim.outcome == "" and guard < 400:
		guard += 1
		if statuses and srng.randf() < 0.35:
			var who: CombatUnit = sim.units[srng.randi() % sim.units.size()]
			var by: CombatUnit = sim.units[srng.randi() % sim.units.size()]
			if who.alive and by.alive:
				sim._add_aura(by, who, AUDIT_STATUSES[srng.randi() % AUDIT_STATUSES.size()])
		if not sim.needs_input():
			sim.ai_act()
		else:
			var macro: Dictionary = Bot.TUNED_MACROS.get(sim.current.id, data.macros.get(sim.current.id, {"lines": []}))
			var d := MacroRunner.decide(sim, sim.current, macro)
			if not d.ok or sim.act(d.action, d.target, d.ability) != "":
				if sim.act("attack") != "":
					sim.act("defend")
		for r in sim.records:
			check_record(sim, r)
		sim.records.clear()
		sim.drain_events()
	counts.battles += 1


## Uppställningarna som granskas: alla tre Realms, djup 1–3, alla tre våningarna (huvudmötet och rummens möten),
## olika sällskap (2–4 hjältar, alla följeslagare), med och utan nivåer, artefakter, statusar och regler.
static func setups(data: Dictionary) -> Array:
	var parties := [["paladin", "brokk", "alva", "eira"], ["paladin", "imma", "solveig", "hulda"],
			["paladin", "ronja", "lirien", "ragnhild"], ["paladin", "tove", "sefir"], ["paladin", "imma"], ["paladin"]]
	# Portalen, första nedstigningen (Paladinen och Imma, 0.24) och båda.
	var bonuses := [1.0, 1.0, Ref.battle_bonus(false, true), Ref.battle_bonus(true, false), Ref.battle_bonus(true, true)]
	var rule_sets := [[], ["mirror_bones", "cursed_ground"], ["withered_grace", "heavy_air"], ["risen_dead"]]
	var out := []
	var i := 0
	for realm in ["crypt", "chapel", "grove"]:
		var r: Dictionary = data.realms[realm]
		for depth in [1, 2, 3]:
			for floor_i in 3:
				for variant in 4:
					var pool: Array = r.pools[floor_i]
					var encounter: String = r.floors[floor_i] if variant % 2 == 0 else pool[variant % pool.size()]
					var party: Array = parties[(i + variant) % parties.size()]
					out.append({"i": i, "encounter": encounter, "floor": floor_i, "depth": depth, "party": party,
							"artifacts": audit_artifacts(party, i) if variant >= 2 else {},
							"statuses": variant % 2 == 1 or variant == 2, "rules": rule_sets[i % rule_sets.size()],
							"level": 0 if variant == 0 else roundi(HeroStats.new_level(5 * (depth - 1) + 2 + floor_i)),
							"traits": audit_traits(data, party, i), "bonus": bonuses[i % bonuses.size()]})
					i += 1
	return out


## Kallen med alla perks (perk-nivåerna som flera poster, som Profile.active_perks) och troféer på följeslagarna.
static func audit_traits(data: Dictionary, party: Array, i: int) -> Dictionary:
	var oaths := [[], ["oath_vengeance", "vengeance_wrath", "vengeance_wrath", "vengeance_zeal", "vengeance_execution",
			"vengeance_divine_toll", "vengeance_reckoning", "vengeance_hand_of_light"],
			["oath_dawn", "dawn_anointment", "dawn_holy_might", "dawn_holy_might", "dawn_holy_might", "dawn_guiding_light",
			"dawn_revelation", "dawn_greater_healing", "dawn_greater_healing"],
			["oath_ward", "ward_titanic_rage", "ward_titanic_rage", "ward_in_formation", "ward_best_offense",
			"ward_best_offense", "ward_rest_up", "ward_war_machine"]]
	var trophies := ["bone_finger", "quick_shot", "deadeye", "bow_sinew", "first_strike", "phantasm", "sareas_plot",
			"lich_crown", "rosary", "warden_helm", "grave_pact", "warden_thorns", "wraith_veil", "prayer_beads"]
	var out := {}
	var oath: Array = oaths[i % oaths.size()]
	if not oath.is_empty():
		out["paladin"] = oath
	for k in party.size():
		var id: String = party[k]
		if id != "paladin" and (i + k) % 2 == 0:
			out[id] = data.heroes[id].get("traits", []) + [trophies[(i + k) % trophies.size()]]
	return out


## Artefakter med nivåer, bärnsten, trick och Nether Stones (stat, trick och troféegenskap).
static func audit_artifacts(party: Array, i: int) -> Dictionary:
	var kinds := [
		{"type": "sword", "ability": "holy_smite", "level": 10, "stat_slots": ["amber_red", "amber_orange", "amber_yellow"],
			"trick_slots": ["whetstone", "jagged_rock"], "nether": {"affixes": [{"kind": "stat", "stat": "attack", "pct": 0.08,
			"q": 1.0}, {"kind": "trick", "trick": "slippery_stone", "q": 1.2}, {"kind": "trait", "trait": "wraith_veil", "q": 1.0}]}},
		{"type": "shield", "ability": "healing_light", "level": 5, "stat_slots": ["amber_grey", "amber_teal"],
			"trick_slots": ["armor_scrap"]},
		{"type": "staff", "ability": "judgement", "level": 1},
		{"type": "boots", "ability": "arrow_rain", "level": 10, "stat_slots": ["amber_violet", "amber_rose", "amber_bronze"],
			"trick_slots": ["slate_inspired", "curio_vulnerable"], "nether": {"affixes": [{"kind": "stat", "stat": "speed",
			"pct": 0.1, "q": 1.25}, {"kind": "stat", "stat": "health", "pct": 0.06, "q": 0.75}]}},
		{"type": "helm", "ability": "renew", "level": 3, "stat_slots": ["amber_green"], "trick_slots": ["arcane_sigil"]},
	]
	var out := {}
	for k in party.size():
		out[party[k]] = kinds[(i + k) % kinds.size()]
	return out


# --- Fienderna och hjältarna (§1, §9) ----------------------------------------

func check_units(sim: CombatSim, encounter: String, depth: int, floor_i: int, party: Array, artifacts: Dictionary,
		opts: Dictionary) -> void:
	var enc: Dictionary = data.encounters[encounter]
	var kinds: Array = sim.enemies.map(func(x: CombatUnit) -> String: return x.kind)
	var want_kinds := Ref.lineup(data.enemies, data.traits, enc.enemies, party.size())
	if kinds != want_kinds:
		_fail("lineup", "%s med %d hjältar: fiender %s, väntat %s (mötet %s)" % [encounter, party.size(), str(kinds),
				str(want_kinds), str(enc.enemies)])
	for e in sim.enemies:
		var want := Ref.enemy_stats(data.enemies[e.kind].stats, float(enc.get("stat_mult", 1.0)), depth, party.size(),
				Ref.enemy_level(depth, floor_i), e.elite, opts.has("levels"), float(opts.get("stat_bonus", 1.0)))
		var got := {"health": e.max_hp, "attack": e.attack, "intelligence": e.intelligence, "defense": e.defense,
				"speed": e.speed}
		for s in want:
			if absf(float(got[s]) - float(want[s])) > EPS:
				_fail("enemy_" + s, "Fiende %s (%s, djup %d, våning %d, %d hjältar%s): %s %s, väntat %s" % [e.kind,
						encounter, depth, floor_i + 1, party.size(), ", elit" if e.elite else "", s, got[s], want[s]])
		if opts.has("levels") and absf(e.level - Ref.enemy_level(depth, floor_i)) > EPS:
			_fail("enemy_level", "Fiende %s: nivå %s, väntat %s" % [e.kind, e.level, Ref.enemy_level(depth, floor_i)])
		counts.enemies += 1
	for h in sim.heroes:
		var lv: Dictionary = opts.get("levels", {}).get(h.id, {"level": 1, "personality": ""})
		var want := hero_stats(h.id, int(lv.level), lv.get("personality", ""), artifacts.get(h.id, {}))
		var got := {"health": h.max_hp, "attack": h.attack, "intelligence": h.intelligence, "defense": h.defense,
				"speed": h.speed}
		for s in want:
			if absf(float(got[s]) - float(want[s])) > EPS:
				_fail("hero_" + s, "Hjälte %s nivå %d: %s i striden %s, väntat %s" % [h.id, lv.level, s, got[s], want[s]])
		counts.heroes += 1


## Hjältens stats ur basen, nivån, personligheten och artefakten (bärnsten och Nether Stone), oberoende.
func hero_stats(hero_id: String, level: int, personality: String, art: Dictionary) -> Dictionary:
	var parts := hero_parts(hero_id, level, personality, art)
	var out := {}
	for s in parts:
		var v := 0.0
		for k in parts[s]:
			v += float(parts[s][k])
		out[s] = Ref.stat_round(v) if s == "health" else v
	return out


## Per källa: {stat: {base, levels, personality, artifact, material, nether}}.
func hero_parts(hero_id: String, level: int, personality: String, art: Dictionary) -> Dictionary:
	var base: Dictionary = data.heroes[hero_id].stats
	var pers: Dictionary = data.personalities.get(personality, {})
	var out := {}
	var before := {}
	for s in ["health", "attack", "intelligence", "defense", "speed"]:
		var g := 0.4 if pers.get("up", "") == s else (0.2 if pers.get("down", "") == s else 0.3)
		var b := float(base[s])
		var neutral := Ref.level_stat(b, level, 0.3, s)
		var with_p := Ref.level_stat(b, level, g, s)
		out[s] = {"base": b, "levels": neutral - b, "personality": with_p - neutral, "artifact": 0.0, "material": 0.0,
				"nether": 0.0}
		before[s] = with_p
	if art.is_empty() or not data.artifacts.has(art.get("type", "")):
		return out
	var kind: Dictionary = data.artifacts[art.type]
	var lvl := clampi(int(art.get("level", 1)), 1, 10)
	var m := Ref.art_level_mult(lvl)
	var st: String = kind.stat
	out[st].artifact = before[st] * (float(kind.get("stat_mult", 1.0)) - 1.0) * m + float(kind.get("stat_add", 0.0)) * m
	var slots: Array = art.get("stat_slots", [])
	for i in slots.size():
		# Platserna öppnas på nivå 2, 5 och 9; en sten i en stängd plats räknas inte (Forge.normalize kortar listan).
		if i >= 3 or slots[i] == null or slots[i] == "":
			continue
		for s in data.materials.amber[slots[i]].stats:
			out[s].material += before[s] * 0.06 * float(data.materials.amber[slots[i]].stats[s]) * m
	for affix in art.get("nether", {}).get("affixes", []):
		if affix.kind == "stat":
			out[affix.stat].nether += before[affix.stat] * float(affix.pct)
	for k in ["artifact", "material", "nether"]:
		out.health[k] = Ref.stat_round(out.health[k])
	return out


# --- En post -----------------------------------------------------------------

func check_record(sim: CombatSim, r: Dictionary) -> void:
	if r.event.is_empty():
		return  # träffen blev ingenting (målet var redan dött) – inget visades
	if r.kind == "heal":
		if r.event.type == "blighted":
			counts.blighted += 1
		else:
			check_heal(sim, r)
		return
	match r.event.type:
		"damage":
			check_damage(sim, r)
		"dodge":
			check_dodge(sim, r)
		"immune":
			counts.immune += 1
			check_immune(sim, r)
		"shelled":
			counts.shelled += 1
			var t: Dictionary = r.units[r.target]
			if not t.auras.has("shelled") or not r.direct or r.units[r.source].team == t.team:
				_fail("shelled", "Skyddsskal tog en träff som det inte skulle: %s" % str(r.event))


## Defense just nu, ur datan: auror med defense_mult, golv 20 % av startvärdet.
func _defense(u: Dictionary) -> float:
	var f := []
	for id in u.auras:
		var d: Dictionary = data.auras.get(id, {})
		if d.has("defense_mult"):
			var stacks := int(u.auras[id].get("stacks", 1))
			f.append(1.0 + (float(d.defense_mult) - 1.0) * stacks)
	return Ref.defense_now(float(u.defense), float(u.base_stats.get("defense", u.defense)), f)


func _stat(u: Dictionary, s: String) -> float:
	match s:
		"health":
			return float(u.max_hp)
		"defense":
			return _defense(u)
		"intelligence":
			# 0.27: Dimmig (Gravdimmans motdrag) sänker Intelligence.
			var m := 1.0
			for id in u.auras:
				m *= float(data.auras.get(id, {}).get("int_mult", 1.0))
			return float(u.intelligence) * m
	return float(u[s])


## 0.27: levande ur samma familj, figuren själv oräknad (oberoende av CombatSim.family_count).
func _kin(units: Dictionary, u: Dictionary) -> int:
	if String(u.get("family", "")) == "":
		return 0
	var n := 0
	for id in units:
		var x: Dictionary = units[id]
		if id != u.id and x.alive and x.team == u.team and x.get("family", "") == u.family:
			n += 1
	return n


func _has_flag(u: Dictionary, flag: String) -> bool:
	for id in u.auras:
		if data.auras.get(id, {}).has(flag) and data.auras[id][flag]:
			return true
	return false


## Egenskaperna som verkar för figuren: egna, plus sällskapets ("scope": "party") från levande allierade.
## En perk med flera nivåer räknas en gång per post; samma perk från en annan bärare räknas inte igen.
func _traits(units: Dictionary, uid: String) -> Array:
	var u: Dictionary = units[uid]
	var out: Array = u.traits.duplicate()
	var shared := []
	for id in units:
		var x: Dictionary = units[id]
		if id == uid or not x.alive or x.team != u.team:
			continue
		var before := shared.duplicate()
		for t in x.traits:
			if _tdef(t).get("scope", "") == "party" and not u.traits.has(t) and not before.has(t):
				shared.append(t)
	return out + shared


## Villkoren i en modify-egenskap, mot läget före träffen.
func _when(units: Dictionary, owner: String, when: Dictionary, probe: Dictionary) -> bool:
	for key in when:
		var want: Variant = when[key]
		var t: Dictionary = units.get(probe.get("target", ""), {})
		match key:
			"target_has_aura":
				if t.is_empty() or not t.auras.has(want):
					return false
			"target_has_any_aura":
				if t.is_empty() or not want.any(func(a: String) -> bool: return t.auras.has(a)):
					return false
			"target_hp_below":
				if t.is_empty() or float(t.hp) / float(t.max_hp) >= float(want):
					return false
			"origin_target_has_aura":
				var o: Dictionary = units.get(probe.get("origin_target", ""), {})
				if o.is_empty() or not o.auras.has(want):
					return false
			"source_attacks_below":
				var s: Dictionary = units.get(probe.get("source", ""), {})
				if s.is_empty() or int(s.attacks_done) >= int(want):
					return false
			# 0.28
			"self_family":
				if String(units[owner].get("family", "")) != want:
					return false
			"ally_has_trait":
				var found := false
				for id in units:
					var u: Dictionary = units[id]
					if id != owner and u.alive and u.team == units[owner].team and Array(u.get("traits", [])).has(want):
						found = true
				if not found:
					return false
			"self_not_acted":
				if String(units[owner].get("last_ability", "")) != "":
					return false
			"source_new_ability":
				var s: Dictionary = units.get(probe.get("source", ""), {})
				if s.is_empty() or probe.get("from_trait", false) or String(s.get("last_ability", "")) == "" \
						or probe.get("ability", "") == s.last_ability:
					return false
			_:
				if not probe.has(key):
					return false
				var got: Variant = probe[key]
				if want is String and want == "self":
					if got != owner:
						return false
				elif typeof(got) != typeof(want) or got != want:
					return false
	return true


func _modify_list(units: Dictionary, owner: String, trigger: String, probe: Dictionary) -> Array:
	var out := []
	if not units[owner].alive:
		return out
	for t in _traits(units, owner):
		var d: Dictionary = _tdef(t)
		if d.get("trigger", "") == trigger and d.has("modify") and _when(units, owner, d.get("when", {}), probe):
			out.append(d)
	return out


## Artefakternas egenskaper finns bara i strids-kopian av datan; den sätts per strid.
var sim_traits := {}


func _tdef(t: String) -> Dictionary:
	return sim_traits.get(t, data.traits.get(t, {}))


func check_damage(sim: CombatSim, r: Dictionary) -> void:
	counts.damage += 1
	sim_traits = sim.data.traits
	var e: Dictionary = r.event
	var c: Dictionary = e.get("calc", {})
	var units: Dictionary = r.units
	var src: Dictionary = units[r.source]
	var tgt: Dictionary = units[r.target]
	var label := "%s → %s (%s, %s)" % [src.id, tgt.id, r.ability, e.kind]
	var kind: String = e.kind
	# Förvandling (Benlichens krona): ett följdanfall från en egenskap blir en helig besvärjelse.
	var expected_kind: String = r.kind_in
	var from_trait: bool = r.trait_ctx != ""
	if src.alive:
		for t in _traits(units, src.id):
			var d: Dictionary = _tdef(t)
			if d.get("trigger", "") == "convert_damage" and _when(units, src.id, d.get("when", {}),
					{"source": src.id, "kind": expected_kind, "from_trait": from_trait, "direct": r.direct}):
				expected_kind = d.convert.get("kind", expected_kind)
	if kind != expected_kind:
		_fail("kind", "%s: typen blev %s, väntat %s" % [label, kind, expected_kind])
	var probe := {"source": src.id, "target": tgt.id, "ability": r.ability, "direct": r.direct, "kind": kind,
			"from_trait": from_trait, "origin_target": r.origin.get("target", "")}
	# Grundskadan. 0.28: Lansspetsen struntar i Defense.
	var def := _defense(tgt)
	if kind == "attack" and r.scaled and _modify_list(units, src.id, "modify_damage", probe).any(
			func(d: Dictionary) -> bool: return d.modify.get("ignore_defense", false)):
		def = 0.0
	var raw := 0.0
	var roll := float(c.get("roll", 1.0))
	if r.scaled:
		if roll < Ref.ROLL_MIN - 1e-9 or roll > Ref.ROLL_MAX + 1e-9:
			_fail("roll", "%s: variationen %s utanför 0,90–1,10" % [label, roll])
		_check_power(r, label)
		match kind:
			"spell":
				var tier: String = data.abilities.get(r.ability, {}).get("tier", "")
				raw = Ref.spell(_stat(src, "intelligence"), tier, roll, def, r.amount)
			"indirect":
				raw = Ref.indirect_raw(_stat(src, "attack"), roll, r.amount)
			_:
				raw = Ref.attack(_stat(src, "attack"), roll, def, r.amount)
		if kind != "indirect" and absf(float(c.get("defense", -1.0)) - def) > EPS:
			_fail("defense", "%s: Defense i uträkningen %s, väntat %s" % [label, c.get("defense"), def])
	else:
		raw = r.amount
		_check_fixed(sim, r, label)
	if absf(float(c.get("raw", -1.0)) - raw) > 0.01:
		_fail("raw_" + kind, "%s: grundskada %s, väntat %s" % [label, c.get("raw"), raw])
	# Modifierarna.
	var factors := []
	var additional := 0.0
	if r.direct:
		var em := 1.0
		for id in src.auras:
			if data.auras.get(id, {}).has("next_attack_mult"):
				em *= float(data.auras[id].next_attack_mult)
		if em != 1.0:
			factors.append(em)
	var buffs := 0
	for id in src.auras:
		# Nästa-anfall-auror förbrukas före räkningen (de räknas inte som buffar i samma träff).
		if data.auras.get(id, {}).get("buff", false) and not (r.direct and data.auras[id].has("next_attack_mult")):
			buffs += 1
	var dead := 0
	for id in units:
		if units[id].team == src.team and not units[id].alive:
			dead += 1
	for d in _modify_list(units, src.id, "modify_damage", probe):
		var m: Dictionary = d.modify
		if m.has("damage_mult"):
			factors.append(float(m.damage_mult))
		if m.has("damage_mult_per_aura"):
			factors.append(1.0 + float(m.damage_mult_per_aura) * buffs)
		if m.has("damage_mult_per_dead_ally"):
			factors.append(1.0 + float(m.damage_mult_per_dead_ally) * dead)
		if m.has("damage_mult_per_use"):
			factors.append(1.0 + float(m.damage_mult_per_use) * int(src.ability_uses.get(r.ability, 0)))
		if m.has("damage_mult_per_hit_taken"):
			factors.append(1.0 + float(m.damage_mult_per_hit_taken) * int(src.times_hit))
		if m.has("damage_mult_per_family"):
			factors.append(1.0 + float(m.damage_mult_per_family) * _kin(units, src))
		if m.has("damage_mult_per_missing_tenth"):
			# 0.31 (Blodpakt): per hel tiondel liv som saknas, högst "max".
			var tenths := floori((1.0 - float(src.hp) / maxf(float(src.max_hp), 1.0)) * 10.0 + 0.0001)
			var bonus := minf(float(m.damage_mult_per_missing_tenth) * maxi(tenths, 0), float(m.get("max", 0.5)))
			if bonus > 0.0:
				factors.append(1.0 + bonus)
		if m.has("additional_from_stat"):
			additional += _stat(src, m.additional_from_stat.stat) * float(m.additional_from_stat.pct)
	if src.resistant and r.direct and ((kind == "attack" and _has_flag(src, "scorn"))
			or (r.ability != src.attack_ability and _has_flag(src, "silence"))):
		factors.append(0.5)
	for id in src.auras:
		var d: Dictionary = data.auras.get(id, {})
		if d.has("damage_mult"):
			factors.append(1.0 + (float(d.damage_mult) - 1.0) * int(src.auras[id].get("stacks", 1)))
	for d in _modify_list(units, tgt.id, "modify_damage_taken", probe):
		if d.modify.has("damage_taken_mult"):
			factors.append(float(d.modify.damage_taken_mult))
		if d.modify.has("damage_taken_mult_per_family"):
			factors.append(1.0 - float(d.modify.damage_taken_mult_per_family) * _kin(units, tgt))
		if d.modify.has("damage_taken_less_per_repeat"):
			var seen := int(tgt.get("hit_log", {}).get("%s:%s" % [src.id, r.ability], 0))
			factors.append(1.0 - minf(float(d.modify.damage_taken_less_per_repeat) * seen,
					float(d.modify.get("repeat_max", 0.75))))
	for id in tgt.auras:
		var d: Dictionary = data.auras.get(id, {})
		if d.has("damage_taken_mult"):
			factors.append(1.0 + (float(d.damage_taken_mult) - 1.0) * int(tgt.auras[id].get("stacks", 1)))
	if float(tgt.damage_taken_mult) != 1.0:
		factors.append(float(tgt.damage_taken_mult))
	if r.release.get("unit", "") == src.id and r.release.get("ability", "") == r.ability:
		factors.append(float(r.release.mult))
	# 0.30: förmågans bonus mot en status som målet har (Rättfärdigt slag mot Förblindad).
	var vs := CombatSim.bonus_vs_for(data.abilities.get(r.ability, {}), tgt.auras)
	if bool(r.get("direct", true)) and not vs.is_empty():
		factors.append(float(vs.mult))
	factors = factors.filter(func(f: float) -> bool: return f != 1.0)
	var got_f: Array = c.get("mods", []).map(func(x: Dictionary) -> float: return float(x.f)).filter(
			func(f: float) -> bool: return f != 1.0)
	var a := factors.duplicate()
	var b := got_f.duplicate()
	a.sort()
	b.sort()
	var same := a.size() == b.size()
	if same:
		for i in a.size():
			same = same and absf(float(a[i]) - float(b[i])) < 1e-6
	if not same:
		_fail("mods_" + r.ability, "%s: modifierare %s, väntat %s (%s)" % [label, str(b), str(a),
				", ".join(c.get("mods", []).map(func(x: Dictionary) -> String: return "%s %s" % [x.name, x.f]))])
	var mods := Ref.mods(factors)
	for x in c.get("mods", []):
		mods_seen[x.name] = int(mods_seen.get(x.name, 0)) + 1
	if additional > 0.0:
		mods_seen["tillägg: " + str(c.get("additional_name", ""))] = int(mods_seen.get("tillägg: " + str(c.get("additional_name", "")), 0)) + 1
	if absf(float(c.get("mod_total", -1.0)) - mods) > 1e-6:
		_fail("mod_total", "%s: modifierarna gav ×%s, väntat ×%s" % [label, c.get("mod_total"), mods])
	# Krit.
	var can_crit: bool = kind == "attack" and r.can_crit
	var crit_chance := 0.0
	var crit_extra := 0.0
	var force := false
	if can_crit:
		var add := 0.0
		for d in _modify_list(units, src.id, "modify_damage", probe):
			add += float(d.modify.get("crit_add", 0.0))
			force = force or d.modify.get("force_crit", false)
		crit_chance = Ref.crit_chance(float(src.crit_chance), float(src.speed), float(tgt.speed)) + add
		for id in src.auras:
			if data.auras.get(id, {}).has("crit_extra"):
				crit_extra = float(data.auras[id].crit_extra)
		if _has_flag(src, "stone"):
			crit_chance = crit_chance * 0.5 if src.resistant else 0.0
			crit_extra = crit_extra * 0.5 if src.resistant else 0.0
			force = false
	if absf(float(c.get("crit_chance", 0.0)) - crit_chance) > 1e-6:
		_fail("crit_chance", "%s: krit-chans %s, väntat %s" % [label, c.get("crit_chance"), crit_chance])
	if e.crit and not can_crit:
		_fail("crit_kind", "%s: krit på något som inte kan krita" % label)
	if e.crit and crit_chance <= 0.0 and crit_extra <= 0.0 and not force:
		_fail("crit_zero", "%s: krit trots 0 %% chans" % label)
	var cb := Ref.crit_bonus(float(src.speed), float(tgt.speed)) if e.crit else 0.0
	if absf(float(c.get("crit_bonus", 0.0)) - cb) > 1e-6:
		_fail("crit_bonus", "%s: krit-bonus %s, väntat %s" % [label, c.get("crit_bonus"), cb])
	# Undvikandet som inte blev av.
	if kind == "attack" and src.team != tgt.team:
		var dch := _dodge_chance(r, src, tgt, probe)
		if absf(float(c.get("dodge_chance", 0.0)) - dch) > 1e-6:
			_fail("dodge_chance_hit", "%s: chans att undvika %s, väntat %s" % [label, c.get("dodge_chance"), dch])
	# Summan.
	var dmg := raw * mods * (1.0 + cb)
	if kind == "indirect":
		dmg = Ref.indirect_after(dmg, def)
	var total := roundf(dmg) + roundf(additional)  # 0.26: inget golv på 1
	# Exakt på ,5 kan flyttalen landa på vilken sida som helst (18,4999… eller 18,5): båda räknas som rätt.
	var guarded := float(c.get("guarded", 0.0))
	if absf(dmg - floorf(dmg) - 0.5) < 1e-6 and absf(float(e.amount) + float(e.absorbed) + guarded - total + 1.0) < EPS:
		total -= 1.0
	# 0.28: livvakten (en levande ur målets familj med guard_family) tar sin andel av den färdiga skadan.
	var guard_pct := 0.0
	if src.team != tgt.team:
		for id in units:
			var x: Dictionary = units[id]
			if id != tgt.id and x.alive and x.team == tgt.team and String(tgt.get("family", "")) != "" \
					and x.get("family", "") == tgt.family and guard_pct == 0.0:
				for t in x.traits:
					guard_pct = maxf(guard_pct, float(_tdef(t).get("guard_family", 0.0)))
	var want_guard := roundf(total * guard_pct) if total > 0.0 else 0.0
	if absf(want_guard - guarded) > EPS:
		_fail("guarded", "%s: livvakten tog %s, väntat %s" % [label, guarded, want_guard])
	total -= want_guard
	var absorbed := minf(float(tgt.barrier), total)
	var lost := total - absorbed
	if absf(float(e.amount) - lost) > EPS or absf(float(e.absorbed) - absorbed) > EPS:
		_fail("amount_" + kind, "%s: visade %s (Barriär %s), väntat %s (Barriär %s; grund %s × %s × krit %s, Defense %s mot spelets %s)" % [label,
				e.amount, e.absorbed, lost, absorbed, raw, mods, 1.0 + cb, def, c.get("defense")])
	var hp_after := maxf(0.0, float(tgt.hp) - lost)
	if r.has("after_hp") and absf(float(r.after_hp) - hp_after) > EPS:
		_fail("hp_after", "%s: livet efteråt %s, väntat %s" % [label, r.after_hp, hp_after])
	check_explain_damage(e, raw, def, mods, cb, lost, absorbed, kind, r.scaled, label)


## Att styrkan (power) i en skalad träff kommer från förmågan eller egenskapen, med bonus mot en status.
func _check_power(r: Dictionary, label: String) -> void:
	var options := []
	var tgt: Dictionary = r.units[r.target]
	var ab: Dictionary = data.abilities.get(r.ability, {})
	for eff in ab.get("effects", []):
		if eff.type == "damage" and eff.has("power"):
			var p := float(eff.power)
			for aura_id in eff.get("bonus_if_aura", {}):
				if tgt.auras.has(aura_id):
					p *= float(eff.bonus_if_aura[aura_id])
			options.append(p)
	var tr: Dictionary = sim_traits.get(r.ability, {})
	for eff in tr.get("effects", []):
		if eff.type == "damage" and eff.has("power"):
			options.append(float(eff.power))
	if options.is_empty():
		return  # t.ex. ett anfall från en våningsregel (inga fler sorter i dag)
	for p in options:
		if absf(float(p) - float(r.amount)) < 1e-6:
			return
	_fail("power_" + r.ability, "%s: styrka %s, väntat en av %s" % [label, r.amount, str(options)])


## Fasta belopp: Blöder, Brinner, Förgiftad, följdanfall för en andel, en andel av en stat, regler.
func _check_fixed(sim: CombatSim, r: Dictionary, label: String) -> void:
	var tgt: Dictionary = r.units[r.target]
	var src: Dictionary = r.units[r.source]
	var want := NAN
	var aura: Dictionary = data.auras.get(r.ability, {})
	if aura.has("bleed_pct"):
		want = float(tgt.hp) * float(aura.resisted_bleed_pct if tgt.resistant else aura.bleed_pct)
	elif aura.has("dot_stat") and tgt.auras.has(r.ability):
		# Belopp per tur = 30 % av källans stat när statusen lades, gånger staplar.
		want = float(tgt.auras[r.ability].dot)
		var by: Dictionary = r.units.get(tgt.auras[r.ability].source, {})
		if not by.is_empty():
			var expect := _stat(by, aura.dot_stat) * float(aura.get("dot_pct", 0.3)) \
					* int(tgt.auras[r.ability].get("stacks", 1))
			if absf(expect - want) > EPS:
				_fail("dot_amount_" + r.ability, "%s: %s per tur är %s, väntat %s (30 %% av %s %s)" % [label,
						aura.name, want, expect, by.id, _stat(by, aura.dot_stat)])
	elif aura.has("blight"):
		var p: Dictionary = r.parent
		if not p.is_empty() and p.kind == "heal":
			want = float(p.base) * float(aura.blight)
	elif aura.has("root_thorns"):
		# Rotskott: kastarens Int × 15 % × staplar på den som blev träffad (föräldraträffens mål).
		var p: Dictionary = r.parent
		if not p.is_empty():
			var hit: Dictionary = r.units.get(p.target, {}).get("auras", {}).get(r.ability, {})
			if not hit.is_empty():
				want = _stat(src, "intelligence") * float(aura.root_thorns) * int(hit.get("stacks", 1))
	elif r.ability == "cursed_ground":
		want = float(tgt.max_hp) * 0.02
	elif r.ability == "mirror_bones":
		var p: Dictionary = r.parent
		if not p.is_empty() and not p.event.is_empty() and p.event.type == "damage":
			want = float(p.event.amount) * 0.2
	elif sim_traits.has(r.ability):
		var options := []
		for eff in sim_traits[r.ability].get("effects", []):
			if eff.type != "damage":
				continue
			if eff.has("pct_of_event"):
				var pct := float(eff.pct_of_event) + float(eff.get("pct_per_family", 0.0)) * _kin(r.units, src)
				options.append(float(r.origin.get(eff.get("event_field", "amount"), 0.0)) * pct)
			elif eff.has("stat"):
				options.append(_stat(src, eff.stat) * float(eff.get("pct", 1.0)))
		if not options.is_empty():
			for o in options:
				if absf(float(o) - float(r.amount)) < 0.01:
					return
			_fail("fixed_" + r.ability, "%s: fast belopp %s, väntat en av %s" % [label, r.amount, str(options)])
			return
	if is_nan(want):
		counts.fixed_unchecked += 1
		unchecked[r.ability] = int(unchecked.get(r.ability, 0)) + 1
		return
	if absf(want - float(r.amount)) > EPS:
		_fail("fixed_" + r.ability, "%s: fast belopp %s, väntat %s" % [label, r.amount, want])


func _dodge_chance(r: Dictionary, src: Dictionary, tgt: Dictionary, probe: Dictionary) -> float:
	if r.rules.has("heavy_air"):
		return 0.0
	var base := Ref.dodge(float(src.speed), float(tgt.speed))
	var add := 0.0
	for d in _modify_list(r.units, tgt.id, "modify_damage_taken", probe):
		add += float(d.modify.get("dodge_add", 0.0))
	var ch := Ref.dodge_with_traits(base, add)
	if _has_flag(tgt, "stone"):
		ch = ch * 0.5 if tgt.resistant else 0.0
	return ch


func check_dodge(sim: CombatSim, r: Dictionary) -> void:
	counts.dodge += 1
	sim_traits = sim.data.traits
	var src: Dictionary = r.units[r.source]
	var tgt: Dictionary = r.units[r.target]
	var c: Dictionary = r.event.get("calc", {})
	var probe := {"source": src.id, "target": tgt.id, "ability": r.ability, "direct": r.direct, "kind": "attack",
			"from_trait": r.trait_ctx != "", "origin_target": r.origin.get("target", "")}
	var ch := _dodge_chance(r, src, tgt, probe)
	var extra := 0.0
	for id in tgt.auras:
		if data.auras.get(id, {}).has("dodge_extra"):
			extra = float(data.auras[id].dodge_extra)
	if _has_flag(tgt, "stone"):
		extra = extra * 0.5 if tgt.resistant else 0.0
	var label := "%s undvek %s (%s)" % [tgt.id, src.id, r.ability]
	if absf(float(c.get("dodge_chance", -1.0)) - ch) > 1e-6:
		_fail("dodge_chance", "%s: chans %s, väntat %s" % [label, c.get("dodge_chance"), ch])
	if ch <= 0.0 and extra <= 0.0:
		_fail("dodge_zero", "%s: undvek trots 0 %% chans" % label)
	if src.team == tgt.team or r.kind_in != "attack":
		_fail("dodge_kind", "%s: bara anfall från fiender kan undvikas" % label)
	var lines := DamageExplain.lines(sim.data, r.event)
	counts.explain += 1
	if lines.is_empty() or not lines[0].begins_with("Chans att undvika: %s" % DamageExplain.pct(ch)):
		_fail("explain_dodge", "%s: förklaringen säger %s, väntat %s" % [label, str(lines), DamageExplain.pct(ch)])


func check_immune(sim: CombatSim, r: Dictionary) -> void:
	var tgt: Dictionary = r.units[r.target]
	var immune := false
	for d in _modify_list(r.units, tgt.id, "modify_damage_taken", {"target": tgt.id}):
		var m: Dictionary = d.modify
		var allies: Array = r.units.values().filter(func(x: Dictionary) -> bool: return x.team == tgt.team and x.alive)
		if m.has("immune_while_ally_kind") and allies.any(func(x: Dictionary) -> bool:
				return x.id != tgt.id and x.kind == m.immune_while_ally_kind):
			immune = true
		if m.has("immune_while_allies") and allies.size() - 1 >= int(m.immune_while_allies):
			immune = true
	if not immune:
		_fail("immune", "%s var immun utan skäl (%s)" % [tgt.id, r.ability])


func check_heal(sim: CombatSim, r: Dictionary) -> void:
	counts.heal += 1
	sim_traits = sim.data.traits
	var e: Dictionary = r.event
	var c: Dictionary = e.get("calc", {})
	var src: Dictionary = r.units[r.source]
	var tgt: Dictionary = r.units[r.target]
	var label := "%s helar %s (%s)" % [src.id, tgt.id, r.ability]
	var base := NAN
	var ctx: Dictionary = r.ctx
	var aura: Dictionary = data.auras.get(r.ability, {})
	if ctx.get("leech", false):
		var p: Dictionary = r.parent
		if not p.is_empty() and p.kind == "damage" and not p.event.is_empty():
			var lost := minf(float(p.event.amount), float(p.units[p.target].hp))
			var pct := 0.0
			for id in p.units[p.source].auras:
				pct += float(data.auras.get(id, {}).get("leech", 0.0))
			base = lost * pct
	elif ctx.has("pct_max_hp"):
		base = float(tgt.max_hp) * float(ctx.pct_max_hp)
	elif aura.has("hot_max_hp_pct"):
		base = float(tgt.max_hp) * float(aura.hot_max_hp_pct)
	elif aura.has("hot_stat") and tgt.auras.has(r.ability):
		base = float(tgt.auras[r.ability].hot)
		var by: Dictionary = r.units.get(tgt.auras[r.ability].source, {})
		if not by.is_empty():
			var expect := _stat(by, aura.hot_stat) * float(aura.get("hot_pct", 0.5))
			if absf(expect - base) > EPS:
				_fail("hot_amount", "%s: %s per tur %s, väntat %s" % [label, aura.name, base, expect])
	elif ctx.has("roll"):
		var power := NAN
		for eff in data.abilities.get(r.ability, {}).get("effects", []) + sim_traits.get(r.ability, {}).get("effects", []):
			if eff.type == "heal" and eff.has("power"):
				power = float(eff.power)
		var roll := float(ctx.roll)
		if roll < Ref.ROLL_MIN - 1e-9 or roll > Ref.ROLL_MAX + 1e-9:
			_fail("heal_roll", "%s: variationen %s utanför 0,90–1,10" % [label, roll])
		if not is_nan(power):
			base = _stat(src, "intelligence") * power * roll
	elif sim_traits.has(r.ability):
		for eff in sim_traits[r.ability].get("effects", []):
			if eff.type == "heal" and eff.has("pct_of_event"):
				base = float(r.origin.get(eff.get("event_field", "amount"), 0.0)) * float(eff.pct_of_event)
			elif eff.type == "heal" and eff.has("stat"):
				base = _stat(src, eff.stat) * float(eff.get("pct", 1.0))
	if is_nan(base):
		counts.fixed_unchecked += 1
		unchecked["heal:" + r.ability] = int(unchecked.get("heal:" + r.ability, 0)) + 1
		base = float(r.base)
	elif absf(base - float(r.base)) > 0.01:
		_fail("heal_base_" + r.ability, "%s: grundbelopp %s, väntat %s" % [label, r.base, base])
	var factors := []
	if src.alive:
		for t in _traits(r.units, src.id):
			var d: Dictionary = sim_traits.get(t, {})
			if d.get("trigger", "") == "modify_heal" and d.has("modify") and _when(r.units, src.id, d.get("when", {}),
					{"source": src.id, "target": tgt.id, "ability": r.ability}):
				if d.modify.has("heal_mult"):
					factors.append(float(d.modify.heal_mult))
	if r.rules.has("withered_grace"):
		factors.append(0.6)
	# strid-langd: fiendernas helningar mattas för varje tidigare helning med samma förmåga (formler.md §7).
	var fade := Ref.heal_fade(int(r.get("heals_before", 0)), float(r.get("heal_fade", 0.0)), float(r.get("heal_fade_min", 1.0))) \
			if int(src.team) == 1 else 1.0
	if fade < 1.0:
		factors.append(fade)
	var amount := roundf(base * Ref.mods(factors))
	var effective := minf(amount, float(tgt.max_hp) - float(tgt.hp))
	if absf(float(e.amount) - amount) > EPS or absf(float(e.effective) - effective) > EPS:
		_fail("heal_amount_" + r.ability, "%s: helade %s (%s effektivt), väntat %s (%s)" % [label, e.amount, e.effective,
				amount, effective])
	if r.has("after_hp") and absf(float(r.after_hp) - (float(tgt.hp) + effective)) > EPS:
		_fail("heal_hp_after", "%s: livet efteråt %s, väntat %s" % [label, r.after_hp, float(tgt.hp) + effective])
	var lines := DamageExplain.lines(sim.data, e)
	counts.explain += 1
	var last := "= %s helat" % DamageExplain.num(effective)
	if lines.is_empty() or not lines[-1].begins_with(last):
		_fail("explain_heal", "%s: förklaringen slutar %s, väntat %s" % [label, lines[-1] if not lines.is_empty() else "",
				last])
	var title := DamageExplain.title(sim.data, e)
	if title.find("+%d" % int(effective)) < 0:
		_fail("explain_heal_title", "%s: rubriken %s, väntat +%d" % [label, title, int(effective)])


## Texten i skadeloggen: varje tal den visar ska stämma med omräkningen.
func check_explain_damage(e: Dictionary, raw: float, def: float, mods: float, cb: float, lost: float, absorbed: float,
		kind: String, scaled: bool, label: String) -> void:
	counts.explain += 1
	var lines := DamageExplain.lines(data, e)
	var text := "\n".join(lines)
	var want_last := "= %s skada" % DamageExplain.num(lost)
	if lines.is_empty() or lines[-1] != want_last:
		_fail("explain_last", "%s: sista raden %s, väntat %s" % [label, lines[-1] if not lines.is_empty() else "", want_last])
	var title := DamageExplain.title(data, e)
	if title.find(": %d" % int(lost)) < 0:
		_fail("explain_title", "%s: rubriken %s, väntat %d" % [label, title, int(lost)])
	if scaled and text.find("= %s" % DamageExplain.num(raw)) < 0:
		_fail("explain_raw_" + kind, "%s: grundskadan %s syns inte i\n%s" % [label, DamageExplain.num(raw), text])
	if scaled and kind != "indirect" and text.find("Defense %s" % DamageExplain.num(def)) < 0:
		_fail("explain_def", "%s: Defense %s syns inte i\n%s" % [label, DamageExplain.num(def), text])
	if absf(mods - 1.0) > 1e-9 and text.find("×%s" % DamageExplain.dec(mods)) < 0:
		_fail("explain_mods", "%s: modifierarna ×%s syns inte i\n%s" % [label, DamageExplain.dec(mods), text])
	if cb > 0.0 and text.find("Krit! +%s" % DamageExplain.pct(cb)) < 0:
		_fail("explain_crit", "%s: krit +%s syns inte i\n%s" % [label, DamageExplain.pct(cb), text])
	if absorbed > 0.0 and text.find("Barriären tog %s" % DamageExplain.num(absorbed)) < 0:
		_fail("explain_barrier", "%s: Barriären %s syns inte i\n%s" % [label, DamageExplain.num(absorbed), text])
	# Varje rad med en subtraktion ska gå ihop som den står (inga negativa mellanled).
	for line in lines:
		var rx := RegEx.create_from_string("^\\((\\d+) − (\\d+)\\)")
		var m := rx.search(line)
		if m and int(m.get_string(1)) < int(m.get_string(2)):
			_fail("explain_negative_" + kind, "%s: raden %s visar en negativ skillnad" % [label, line])
