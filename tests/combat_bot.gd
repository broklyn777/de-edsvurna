extends RefCounted
## Simulerade spelare för balanstester i turordningsstriden.
##   BASIC – anfaller alltid det förvalda målet
##   MACRO – hjältarna kör startmakrona i data/macros.json (det Auto gör från början)
##   TUNED – startmakrona med små förbättringar (TUNED_MACROS nedan): visar att makrobygget spelar roll

enum Skill { BASIC, MACRO, TUNED }

## Startmakrona förbättrade för att svara på fiendernas egenskaper (0.14): döda Gravprästen först
## (Gravpakt), besvärjelser mot Benrustning, Pilregn mot många, Krigsrop i första turen, och Brokk
## provocerar bara med mycket liv. I kapellet (0.16): Kultisterna först (biskopen är immun så länge de
## lever), Ljusets dom mot Gasten som undviker attacker. Med rumskartan (0.18) och Siralims Charges
## helar Alva snålare (Helande ljus under 35 %, Förnyelse under 60 %) så att Charges räcker hela körningen. Försök som sparade Charges förlorade oftare – att spendera är oftast rätt.
const TUNED_MACROS := {
	"paladin": {"name": "Paladinen+", "lines": [
		{"subject": "any_ally", "cond": "hp_below", "value": 35, "action": "ability", "ability": "holy_shield", "target": "that"},
		{"subject": "any_enemy", "cond": "has_trait", "value": "cultist_ward", "action": "ability", "ability": "holy_smite", "target": "that"},
		{"subject": "any_enemy", "cond": "has_trait", "value": "grave_pact", "action": "ability", "ability": "holy_smite", "target": "that"},
		{"subject": "any_enemy", "cond": "lowest_hp", "action": "ability", "ability": "holy_smite", "target": "that"},
		{"subject": "any_enemy", "cond": "lowest_hp", "action": "attack", "target": "that"}]},
	"brokk": {"name": "Brokk+", "lines": [
		{"subject": "self", "cond": "own_turn", "value": 1, "action": "ability", "ability": "war_cry"},
		{"subject": "self", "cond": "hp_below", "value": 50, "action": "ability", "ability": "stone_wall"},
		{"subject": "self", "cond": "hp_above", "value": 50, "action": "test_next"},
		{"subject": "self", "cond": "lacks_status", "value": "provoke", "action": "provoke"},
		{"subject": "self", "cond": "hp_below", "value": 50, "action": "defend"},
		{"subject": "any_enemy", "cond": "has_trait", "value": "cultist_ward", "action": "attack", "target": "that"},
		{"subject": "any_enemy", "cond": "has_trait", "value": "grave_pact", "action": "attack", "target": "that"},
		{"subject": "any_enemy", "cond": "lowest_hp", "action": "attack", "target": "that"}]},
	"alva": {"name": "Syster Alva+", "lines": [
		{"subject": "any_ally", "cond": "has_status", "value": "blighted", "action": "ability", "ability": "healing_light", "target": "that"},
		{"subject": "any_ally", "cond": "hp_below", "value": 35, "action": "ability", "ability": "healing_light", "target": "that"},
		{"subject": "any_ally", "cond": "lacks_status", "value": "mending", "action": "test_next"},
		{"subject": "any_ally", "cond": "hp_below", "value": 60, "action": "ability", "ability": "renew", "target": "that"},
		{"subject": "any_enemy", "cond": "has_trait", "value": "grave_pact", "action": "ability", "ability": "judgement", "target": "that"},
		{"subject": "any_enemy", "cond": "has_trait", "value": "bone_armor", "action": "ability", "ability": "judgement", "target": "that"},
		{"subject": "any_enemy", "cond": "has_trait", "value": "wraith_ethereal", "action": "ability", "ability": "judgement", "target": "that"},
		{"subject": "any_enemy", "cond": "lowest_hp", "action": "attack", "target": "that"}]},
	"eira": {"name": "Jägaren Eira+", "lines": [
		{"subject": "enemy_3", "cond": "is_alive", "action": "ability", "ability": "arrow_rain"},
		{"subject": "any_enemy", "cond": "has_trait", "value": "cultist_ward", "action": "attack", "target": "that"},
		{"subject": "any_enemy", "cond": "has_trait", "value": "grave_pact", "action": "attack", "target": "that"},
		{"subject": "any_enemy", "cond": "has_status", "value": "marked", "action": "attack", "target": "that"},
		{"subject": "any_enemy", "cond": "lowest_hp", "action": "ability", "ability": "hunters_mark", "target": "that"},
		{"subject": "any_enemy", "cond": "is_alive", "action": "attack", "target": "that"}]},
	# 0.23: förbättrade makron för de nya följeslagarna.
	"imma": {"name": "Imma+", "lines": [
		{"subject": "any_enemy", "cond": "has_buff", "action": "attack", "target": "that"},
		{"subject": "any_ally", "cond": "hp_below", "value": 40, "action": "ability", "ability": "smoke_arrow", "target": "that"},
		{"subject": "any_enemy", "cond": "highest_defense", "action": "ability", "ability": "spark_arrow", "target": "that"},
		{"subject": "any_enemy", "cond": "lowest_hp", "action": "attack", "target": "that"}]},
	"ronja": {"name": "Ronja+", "lines": [
		{"subject": "any_enemy", "cond": "has_status", "value": "marked", "action": "ability", "ability": "falcon_dive", "target": "that"},
		{"subject": "any_enemy", "cond": "lowest_hp", "action": "attack", "target": "that"}]},
	"lirien": {"name": "Lirien+", "lines": [
		{"subject": "any_ally", "cond": "hp_below", "value": 40, "action": "test_next"},
		{"subject": "any_enemy", "cond": "highest_attack", "action": "ability", "ability": "lullaby", "target": "that"},
		{"subject": "ally_1", "cond": "lacks_status", "value": "inspired", "action": "ability", "ability": "battle_song", "target": "that"},
		{"subject": "any_enemy", "cond": "lowest_hp", "action": "attack", "target": "that"}]},
	"hulda": {"name": "Hulda+", "lines": [
		{"subject": "any_ally", "cond": "hp_below", "value": 45, "action": "ability", "ability": "leaf_shield", "target": "that"},
		{"subject": "all_enemies", "cond": "lacks_status", "value": "poisoned", "action": "ability", "ability": "spore_ring", "target": "that"},
		{"subject": "any_enemy", "cond": "lowest_hp", "action": "attack", "target": "that"}]},
	"ragnhild": {"name": "Ragnhild+", "lines": [
		{"subject": "any_enemy", "cond": "has_buff", "action": "ability", "ability": "dispel_lie", "target": "that"},
		{"subject": "all_enemies", "cond": "is_alive", "action": "ability", "ability": "light_wave", "target": "that"},
		{"subject": "any_enemy", "cond": "lowest_hp", "action": "attack", "target": "that"}]},
	"tove": {"name": "Tove+", "lines": [
		{"subject": "self", "cond": "has_debuff", "action": "ability", "ability": "still_water", "target": "self"},
		{"subject": "any_ally", "cond": "hp_below", "value": 50, "action": "test_next"},
		{"subject": "self", "cond": "lacks_status", "value": "agile", "action": "ability", "ability": "wind_step", "target": "self"},
		{"subject": "any_enemy", "cond": "lowest_hp", "action": "attack", "target": "that"}]},
}


static func run_fight(data: Dictionary, seed_value: int, skill: Skill, encounter := "crypt_1",
		party: Array = [], traits := {}, charges := {}, artifacts := {}, depth := 1, opts := {}) -> Dictionary:
	var sim := CombatSim.create(data, encounter, seed_value, party, traits, charges, artifacts, depth, opts)
	sim.begin()
	var guard := 0
	var no_match := 0
	while sim.outcome == "" and guard < 500:
		guard += 1
		if not sim.needs_input():
			sim.ai_act()
			continue
		if skill == Skill.BASIC:
			sim.act("attack")
			continue
		var macros: Dictionary = data.macros if skill == Skill.MACRO else TUNED_MACROS
		if skill == Skill.MACRO and opts.has("bot_macros"):
			macros = opts.bot_macros  # 0.23.3: t.ex. en ny profils få rader (new_profile_macros)
		# 0.23: följeslagare utan förbättrade makron kör sina startmakron även för TUNED.
		var macro: Dictionary = macros.get(sim.current.id, data.macros.get(sim.current.id, {"lines": []}))
		# Ett "svar" i balansrapporten (BALANS=elitsvar): en fokusrad före hjältens första Anfall-rad, så att helningar
		# och skydd högre upp går först.
		# Mätningen av Provocera (docs/provspel/provocera-matning.md): NO_PROVOKE=1 tar bort raderna med Provocera.
		if OS.get_environment("NO_PROVOKE") == "1":
			macro = {"lines": macro.get("lines", []).filter(func(l: Dictionary) -> bool:
					return l.get("action", "") != "provoke")}
		var hero_line: Dictionary = opts.get("hero_lines", {}).get(sim.current.id, {})
		if opts.has("focus_line") or not hero_line.is_empty():
			var lines: Array = macro.get("lines", []).duplicate()
			var at := lines.size()
			for i in lines.size():
				if lines[i].get("action", "") == "attack":
					at = i
					break
			lines.insert(at, hero_line if not hero_line.is_empty() else opts.focus_line)
			macro = {"lines": lines}
		var decision := MacroRunner.decide(sim, sim.current, macro)
		if decision.ok:
			sim.act(decision.action, decision.target, decision.ability)
		else:
			no_match += 1
			if sim.act("defend") != "":
				sim.act("attack")  # Inga bönder: Försvara går inte
		var events := sim.drain_events()
		if opts.has("event_log"):
			opts.event_log.append_array(events)
	var alive := sim.heroes.filter(func(h: CombatUnit) -> bool: return h.alive).size()
	return {"outcome": sim.outcome, "turns": sim.turn_no, "alive": alive, "no_match": no_match, "sim": sim}


## En hel Realm (standard kryptan) i följd med Charges som räcker alla våningarna. Sant om sällskapet klarar den.
static func run_crypt(data: Dictionary, seed_value: int, skill: Skill, traits := {}, artifacts := {},
		depth := 1, floors: Array = RunState.FLOORS, opts := {}) -> bool:
	var state := RunState.new()
	state.fill_charges(data)
	for floor in floors:
		var r := run_fight(data, seed_value, skill, floor, state.party, traits, state.charges, artifacts, depth, opts)
		if r.outcome != "victory":
			return false
		state.store_charges(r.sim)
	return true


## Inställningar för en körning med instabilitet: reglerna slumpas med fröet (samma för alla
## våningar), som när spelaren väljer instabilitet vid Kryptporten.
static func instability_opts(data: Dictionary, seed_value: int, level: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 31 + level
	var rolled := RunState.roll_rules(data, level, rng)
	return {"rules": rolled.visible + rolled.hidden, "instability": level}


## En hel körning på rumskartan (0.18): våning för våning väljer boten väg, går igenom rummen och
## spelar striderna med Charges som räcker hela körningen. policy: "simple" undviker elit och portal
## (slumpar bland resten), "greedy" tar elit, portal och skattkammare först. På helgedomen tas
## Charges om de erbjuds, annars välsignelsen. Returnerar {cleared, fights, quest_done, rooms}.
static func run_expedition(data: Dictionary, seed_value: int, skill: Skill, traits := {}, artifacts := {},
		depth := 1, realm := "crypt", opts := {}, policy := "simple") -> Dictionary:
	var state := RunState.new()
	state.set_realm(data, realm)
	state.depth = depth
	state.instability = int(opts.get("instability", 0))
	state.first_descent = opts.get("first_descent", false)  # 0.24: profilens första nedstigning
	state.rules_visible = opts.get("rules", []).duplicate()
	if opts.has("party"):
		state.party.assign(opts.party)  # 0.23: sällskap med 2–4 hjältar
	state.fill_charges(data)
	# Prototyp (sallskap-fem): opts.owned = hjältar profilen äger, opts.slots = platser (5 = den femte öppen).
	state.owned_heroes = int(opts.get("owned", 0))
	state.party_slots = int(opts.get("slots", Profile.BASE_SLOTS))
	if opts.has("realm_party"):
		state.realm_party = int(opts.realm_party)  # BALANS=fem: Trollberget som förr, balanserat mot fyra
	if opts.has("vow"):
		state.set_vow(data, opts.vow)  # 0.30.17: löftet för hela körningen
	if opts.has("recruited"):
		state.place_prisoners(data, opts.recruited)  # 0.23: botarna befriar lärjungar som i spelet
	if opts.has("growth"):
		state.set_growth(data, int(opts.growth))  # den levande kartan: Realmens fördärv (steg 4 = den förvridna bossen)
	state.start_expedition(data, seed_value)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 13 + 5
	var fights := 0
	var rooms := 0
	var f0_fights := 0  # strider på första våningen (för en ny profil på nivå 1)
	var f0_won := 0
	# Fynd och silver (0.20): opts.finds = true/false (djupaste djupet eller inte) slår fram fynden som i spelet.
	var finds := {"amber": 0, "trick": 0, "nether": 0, "rare": 0}
	var silver := 0
	var loot_rng := RandomNumberGenerator.new()
	loot_rng.seed = seed_value * 7 + 3
	# Nivåer (0.19): opts.levels = startnivåer per hjälte; med opts.grow växer de av erfarenheten.
	var levels: Dictionary = opts.get("levels", {}).duplicate(true)
	var xp_total := 0  # 0.30.22: erfarenhet per hjälte i körningen (strider och spår)
	var by_kind := {}
	# 0.27: grottan. Boten går ett steg i taget mot närmaste okända ruta (mot målet), slåss mot grupperna den kliver på
	# (elitgrupper bara om questen kräver dem), tar skatter, helgedomar, fångar och lägereldar, och går till målet när
	# questen är klar.
	while not state.finished and rooms < 900:
		var r := state.current_room()
		if state.at_group():
			# Läget när boten kliver på en elitruta (BALANS=elitnotning): Charges, nivåer och sällskap just då.
			if opts.has("elite_snaps") and r.get("elite", false) and not r.get("snapped", false):
				r.snapped = true
				opts.elite_snaps.append({"charges": state.charges.duplicate(true), "levels": levels.duplicate(true),
						"party": state.party.duplicate(), "floor": state.floor, "opts": state.battle_opts()})
			if not _bot_wants_fight(state, r, policy):
				state.back()
				rooms += 1
				continue
			state.fight()
			var battle_opts := state.battle_opts()
			for key in opts:
				if not battle_opts.has(key) and not key in ["levels", "grow", "party", "recruited", "first_descent", "joins", "max_fights", "elite_snaps", "vow", "growth", "owned", "slots", "realm_party"]:
					battle_opts[key] = opts[key]
			if not levels.is_empty():
				battle_opts.levels = levels
			var fight_traits := traits
			if state.vow_trait(data) != "":
				fight_traits = traits.duplicate(true)
				var own: Array = fight_traits.get("paladin", data.heroes.paladin.get("traits", [])).duplicate()
				own.append(state.vow_trait(data))
				fight_traits.paladin = own
			state.apply_vow(data, battle_opts)
			var result := run_fight(data, seed_value * 31 + fights, skill, state.encounter(), state.party, fight_traits,
					state.charges, artifacts, depth, battle_opts)
			fights += 1
			# Prototyp (sallskap-fem): strider och segrar per sort (vanlig, elit, väktare, boss).
			var fk := "boss" if r.get("boss", false) and not state.guardian_room(r) else ("väktare" if r.get("boss", false)
					else ("elit" if r.get("elite", false) or r.get("nemesis", false) else "vanlig"))
			var bk: Array = by_kind.get(fk, [0, 0])
			by_kind[fk] = [int(bk[0]) + 1, int(bk[1]) + (1 if result.outcome == "victory" else 0)]
			if state.floor == 0:
				f0_fights += 1
				f0_won += 1 if result.outcome == "victory" else 0
			if result.outcome != "victory":
				return {"cleared": false, "fights": fights, "quest_done": state.quest.get("done", false), "rooms": rooms,
						"lost_at": "f%d_%s" % [state.floor, "end" if r.get("boss", false) else r.kind], "f0_fights": f0_fights,
						"f0_won": f0_won, "levels": levels, "finds": finds, "silver": silver, "by_kind": by_kind}
			silver += state.battle_silver(depth)
			state.vow_after_battle(data, result.sim)
			if opts.has("finds"):
				_count_finds(finds, Forge.roll_finds(data, "boss" if r.get("boss", false) else RunState.fight_kind(r), depth,
						opts.finds, state.instability, loot_rng, 0, state.growth))
			state.store_charges(result.sim)
			if opts.get("grow", false):
				var xp := HeroStats.battle_xp(RunState.fight_kind(r), depth, r.get("boss", false))
				xp_total += xp
				for hero_id in levels:
					HeroStats.add_xp(levels[hero_id], xp)
			# 0.25: opts.joins (t.ex. "imma") ansluter efter den första vunna striden, som Run.imma_sneaks.
			if fights == 1 and opts.has("joins") and not state.party.has(opts.joins):
				state.party.append(opts.joins)
				state.add_charges_for(data, opts.joins)
				if not levels.is_empty():
					levels[opts.joins] = {"level": 2 if int(levels.paladin.level) >= 4 else 1, "xp": 0,
							"personality": data.heroes[opts.joins].get("personality", "")}
			if fights >= int(opts.get("max_fights", 999)):
				return {"cleared": false, "fights": fights, "won": true, "rooms": rooms, "f0_fights": f0_fights,
						"f0_won": f0_won, "levels": levels, "finds": finds, "silver": silver, "by_kind": by_kind}
			state.battle_won()
			match r.kind:
				"prisoner":
					_bot_recruit(data, state, levels, r)
				"treasure":
					silver += int(state.treasure(data, rng).silver)
				"item":
					state.collect_item()
			if state.floor_cleared():
				var t := _bot_trail(data, state, levels, opts)
				xp_total += int(t.get("xp", 0))
				silver += roundi(float(t.get("silver", 0.0)))
				state.next_floor(data)
			continue
		# Rutans innehåll (obevakat).
		if not r.get("done", false):
			match r.get("kind", ""):
				"prisoner":
					_bot_recruit(data, state, levels, r)
				"campfire":
					state.campfire(data)
				"treasure":
					silver += int(state.treasure(data, rng).silver)
					if opts.has("finds"):
						_count_finds(finds, Forge.roll_finds(data, "treasure", depth, opts.finds, state.instability, loot_rng))
				"shrine":
					var gifts := state.shrine_options(data, rng)
					var gift: Dictionary = gifts[0] if gifts[0].kind == "charge" else gifts[1]
					# HELGEDOM=gava (strid-justering): botarna tar auran i stället för Charges, för att jämföra gåvorna.
					if OS.get_environment("HELGEDOM") == "gava":
						for g in gifts:
							if g.kind == "blessing":
								gift = g
					state.apply_shrine(data, rng, gift)
		if state.floor_cleared():
			var t := _bot_trail(data, state, levels, opts)
			xp_total += int(t.get("xp", 0))
			silver += roundi(float(t.get("silver", 0.0)))
			state.next_floor(data)
			continue
		var target := _bot_target(data, state, policy)
		if target < 0 or state.step(target).is_empty():
			break
		rooms += 1
	return {"cleared": state.finished, "fights": fights, "quest_done": state.quest.get("done", false), "rooms": rooms,
			"levels": levels, "f0_fights": f0_fights, "f0_won": f0_won, "finds": finds, "silver": silver,
			"vow_kept": state.vow_kept(data), "xp": xp_total, "by_kind": by_kind}


## 0.30.22: spåren efter de vanliga grupper boten lät vara (RunState.take_trail), när våningen är klar.
static func _bot_trail(data: Dictionary, state: RunState, levels: Dictionary, opts: Dictionary) -> Dictionary:
	var t := state.take_trail(data)
	if not t.is_empty() and opts.get("grow", false):
		for hero_id in levels:
			HeroStats.add_xp(levels[hero_id], int(t.xp))
	return t


## Slåss boten mot gruppen den står på? Elitgrupper bara om questen kräver dem (eller med "greedy").
static func _bot_wants_fight(state: RunState, r: Dictionary, policy: String) -> bool:
	if policy == "greedy" or r.get("boss", false) or r.get("bot_must", false):
		return true
	# 0.30.17: Raka vägen – boten håller löftet och backar från fler vanliga grupper.
	if state.vow_breaks_on == "commons" and not state.vow_broken and RunState.is_common_group(r) \
			and state.commons_fought >= state.vow_max_commons:
		return false
	# "careful": backar från vanliga grupper och bevakade skatter så länge det finns en annan väg (färre strider).
	if policy == "careful" and (r.kind == "battle" or (r.kind == "treasure" and not r.get("elite", false))):
		return false
	# 0.30.22 "direct": backar från vanliga grupper (tar spåren när den går vidare), slåss för questen och skatterna.
	if policy == "direct" and r.kind == "battle" and RunState.is_common_group(r):
		return false
	if not r.get("elite", false):
		return true
	if state.party.size() == 1:
		return false  # en ensam paladin väntar med elitgruppen tills någon har anslutit (kortets varning)
	var q: String = state.quest.get("type", "")
	return r.get("nemesis", false) or q == "clear"


## Nästa ruta för boten: målet när questen är klar, en känd grupp som questen behöver, en lägereld när Charges tar slut,
## annars närmaste okända ruta (mot målet). Saknas okända rutor går den till närmaste sedda grupp.
static func _bot_target(data: Dictionary, state: RunState, policy: String) -> int:
	var m := state.map
	var reach := _bot_reach(state)
	if not state.goal_locked() and (reach.has(m.goal) or _frontier_ok(state, m.goal)) and state.can_step(m.goal) == "":
		return m.goal
	# Kända grupper som questen behöver (och som går att nå).
	for i in state.seen:
		var c := m.cell(i)
		if m.has_group(i) and (c.get("nemesis", false) or (c.kind == "item") \
				or (c.get("elite", false) and state.quest.get("type", "") == "clear")) and state.can_step(i) == "" \
				and _bot_wants_fight(state, c, policy):
			return i
	if _charges_share(data, state) < 0.4:
		for i in state.visited:
			if m.cell(i).kind == "campfire" and not m.cell(i).get("done", false) and state.can_step(i) == "":
				return i
	var best := -1
	var best_cost := 1 << 30
	for i in reach:
		for n in Grotto.neighbors(i):
			if state.visited.has(n) or m.blocked(n, state.visited, state.seen) or (n == m.goal and state.goal_locked()):
				continue
			if m.has_group(n) and state.seen.has(n) and not _bot_wants_fight(state, m.cell(n), policy):
				continue
			var cost: int = reach[i] * 4 + Grotto.dist(n, m.goal)
			if cost < best_cost and state.can_step(n) == "":
				best_cost = cost
				best = n
	if best >= 0:
		return best
	# Allt okänt är spärrat: gå till en sedd grupp och slåss (helst en som boten vill slåss mot).
	var fallback := -1
	for i in state.seen:
		if m.has_group(i) and state.can_step(i) == "":
			if _bot_wants_fight(state, m.cell(i), policy):
				return i
			fallback = i
	if fallback >= 0:
		m.cell(fallback)["bot_must"] = true
	return fallback


static func _frontier_ok(state: RunState, i: int) -> bool:
	return Grotto.neighbors(i).any(func(n: int) -> bool: return state.visited.has(n) and not state.map.has_group(n))


## Avstånd från pjäsen till alla besökta rutor man kan gå genom (utan obesegrade grupper).
static func _bot_reach(state: RunState) -> Dictionary:
	var out := {state.pos: 0}
	var queue: Array[int] = [state.pos]
	while not queue.is_empty():
		var i: int = queue.pop_front()
		for n in Grotto.neighbors(i):
			if out.has(n) or not state.visited.has(n) or state.map.has_group(n):
				continue
			out[n] = out[i] + 1
			queue.append(n)
	return out


static func _charges_share(data: Dictionary, state: RunState) -> float:
	var left := 0
	var full := 0
	for hero_id in state.charges:
		for ability_id in state.charges[hero_id]:
			left += int(state.charges[hero_id][ability_id])
			full += int(data.abilities[ability_id].get("charges", 0))
	return float(left) / maxf(full, 1)


## Andel Charges kvar (0–1) i ett sparat läge.
static func charges_share_of(data: Dictionary, charges: Dictionary) -> float:
	var left := 0
	var full := 0
	for hero_id in charges:
		for ability_id in charges[hero_id]:
			left += int(charges[hero_id][ability_id])
			full += int(data.abilities[ability_id].get("charges", 0))
	return float(left) / maxf(full, 1)


static func _count_finds(counts: Dictionary, finds: Array) -> void:
	for f in finds:
		counts[f.kind] += int(f.get("count", 1))
		counts.rare += 1 if Forge.is_rare_find(f) else 0


## Makrona i en ny profil (0.23.3, som Run._load_macros): Paladinen har introts föreslagna rad, följeslagarna sina
## två första rader.
static func new_profile_macros(data: Dictionary) -> Dictionary:
	var out: Dictionary = data.macros.duplicate(true)
	out.paladin.lines = [{"subject": "any_enemy", "cond": "lowest_hp", "value": 0, "action": "attack", "ability": "",
			"target": "that"}]
	for id in out:
		if id != "paladin":
			out[id].lines = load("res://scripts/game/run.gd").starter_lines(data, id, out[id].lines)
	return out


## Sällskapet på en viss nivå med de förvalda personligheterna (för balansrapporten).
static func party_levels(data: Dictionary, level: int, party: Array = ["paladin", "brokk", "alva", "eira"]) -> Dictionary:
	var out := {}
	for hero_id in party:
		out[hero_id] = {"level": level, "xp": 0, "personality": data.heroes[hero_id].get("personality", "")}
	return out


## En befriad lärjunge ansluter (som Run.rescue_prisoner): nivå 1, eller 2 om sällskapet är på nivå 4+.
static func _bot_recruit(data: Dictionary, state: RunState, levels: Dictionary, r: Dictionary) -> void:
	var hero_id: String = r.get("hero", "")
	if hero_id == "" or r.get("rescued", false):
		return
	r.rescued = true
	if state.party.size() >= state.party_slots:
		return
	state.party.append(hero_id)
	state.add_charges_for(data, hero_id)
	if not levels.is_empty():
		levels[hero_id] = {"level": 2 if HeroStats.party_level(levels) >= 4.0 else 1, "xp": 0,
				"personality": data.heroes[hero_id].get("personality", "")}
