extends "res://tests/test_case.gd"
## Väktarsteg 2 (docs/plan/bossbank.md): varje roterande väktare ställer en egen fråga. Midnattsklockan (tre slag till
## midnatt, bryts bara när Benfolket är dött), Kistornas råd (egenskaperna går i arv), Inkvisitorns domstol (Skuld på
## den som provocerar, Dom vid tre staplar) och Abbedissans kör (bara kronans bärare tar full skada). Väktarnas troféer
## efter två segrar, och Svens replik vid porten.

var _data := GameData.load_all().duplicate(true)
const PARTY := ["paladin", "brokk", "alva", "eira"]


func _sim(enc: String, seed_value := 3) -> CombatSim:
	return CombatSim.create(_data, enc, seed_value, PARTY)


func _enemy(sim: CombatSim, kind: String, n := 1) -> CombatUnit:
	var seen := 0
	for e in sim.enemies:
		if e.kind == kind:
			seen += 1
			if seen == n:
				return e
	return null


func _hero(sim: CombatSim, id: String) -> CombatUnit:
	for h in sim.heroes:
		if h.id == id:
			return h
	return null


func _turn(sim: CombatSim, u: CombatUnit) -> Array[Dictionary]:
	sim.drain_events()
	sim.current = u
	sim.ai_act()
	return sim.drain_events()


func _types(events: Array[Dictionary]) -> Array:
	return events.map(func(e: Dictionary) -> String: return e.type)


# --- Mötenas egna egenskaper ---------------------------------------------------

func test_overrides_only_apply_in_the_guardian_encounter() -> void:
	var g := _enemy(_sim("crypt_g1"), "bell_ringer")
	assert_true(g.traits.has("midnight_rule"), "Klockaren som väktare har Tre slag till midnatt")
	assert_true(not g.traits.has("bell_toll_trait"), "och inte sitt vanliga Klockslag")
	assert_eq(String(g.rules[0].ability), "midnight_doom")
	# Samma fiende i elitgruppen är som förut.
	var e := _enemy(_sim("crypt_e5"), "bell_ringer")
	assert_true(e != null and not e.traits.has("midnight_rule") and e.traits.has("bell_toll_trait"))
	# Två Kistbärare med olika egenskaper ("typ#n").
	var c := _sim("crypt_g2")
	assert_true(_enemy(c, "coffin_bearer", 1).traits.has("council_lid"))
	assert_true(_enemy(c, "coffin_bearer", 2).traits.has("council_wake"))
	assert_true(not _enemy(c, "coffin_bearer", 2).traits.has("council_lid"))


func test_every_guardian_has_a_warning_help_and_trophy() -> void:
	for realm_id in ["crypt", "chapel"]:
		for enc_id in _data.realms[realm_id].guardians:
			var enc: Dictionary = _data.encounters[enc_id]
			assert_true(String(enc.get("warning", "")) != "", "%s: varning på kortet" % enc_id)
			assert_true(_data.help.entries.has(enc.get("help", "")), "%s: hjälpruta" % enc_id)
			assert_true(_data.help.order.has(enc.help), "%s: hjälprutan finns i handboken" % enc_id)
			var t: Dictionary = _data.traits.get(enc.get("trophy", ""), {})
			assert_true(t.get("trophy", false) and t.get("rarity", "") == "boss", "%s: en regelbrytande trofé" % enc_id)
			assert_eq(String(t.get("guardian", "")), enc_id)
			assert_true(String(t.get("lesson", "")).contains("{bärare}"), "%s: troféns lärdom" % enc_id)


# --- 1. Midnattsklockan --------------------------------------------------------

func test_bell_strikes_count_and_wake_the_fallen() -> void:
	var sim := _sim("crypt_g1")
	var bell := _enemy(sim, "bell_ringer")
	var runner := _enemy(sim, "bone_runner")
	runner.hp = 1.0
	sim._kill(runner)
	sim._choose_intent(bell)
	assert_true(sim.is_charging(bell) and bell.charging.ability == "midnight_bell", "klockan laddas en tur")
	var ev := _turn(sim, bell)
	assert_true(runner.alive, "slaget väcker de fallna ur Benfolket")
	assert_eq(int(bell.stacks.get("midnight", 0)), 1, "första slaget")
	var said := ev.filter(func(e: Dictionary) -> bool: return e.type == "stack_said")
	assert_true(not said.is_empty() and said[0].text == "SLAG 1 AV 3", "ordet över Klockaren")


func test_third_strike_is_midnight_and_breaks_only_when_the_kin_are_dead() -> void:
	var sim := _sim("crypt_g1")
	var bell := _enemy(sim, "bell_ringer")
	bell.stacks["midnight"] = 2.0
	sim._choose_intent(bell)
	assert_true(sim.is_charging(bell) and bell.charging.ability == "midnight_doom", "efter två slag: Midnatt")
	assert_eq(sim.charge_left(bell), 2, "två turer att svara på")
	assert_true(sim.charging_all(bell), "mot hela sällskapet")
	var kin: Array = sim.enemies.filter(func(e: CombatUnit) -> bool: return e != bell and e.family == "bone_kin")
	assert_true(kin.size() >= 2)
	for k in kin:
		assert_true(sim.is_channeling(k), "%s håller Midnatt vid liv" % k.name)
	assert_true(not sim.is_channeling(_enemy(sim, "grave_priest")), "Gravprästen är inte Benfolket")
	# Tystad bryter inte Midnatt (bara de döda gör det).
	sim._add_aura(_hero(sim, "paladin"), bell, "silenced")
	assert_true(sim.is_charging(bell), "Tystad biter inte på Midnatt")
	bell.auras.erase("silenced")
	for i in kin.size():
		kin[i].hp = 1.0
		sim._kill(kin[i])
		if i < kin.size() - 1:
			assert_true(sim.is_charging(bell), "en ur Benfolket lever: Midnatt laddas vidare")
	assert_true(not sim.is_charging(bell), "alla ur Benfolket döda: Midnatt bryts")
	assert_true(bell.auras.has("staggered"), "Klockaren vacklar")
	assert_eq(int(bell.stacks.get("midnight", 0)), 0, "klockan börjar om från första slaget")


func test_midnight_released_hits_everyone_and_resets() -> void:
	var sim := _sim("crypt_g1")
	var bell := _enemy(sim, "bell_ringer")
	bell.stacks["midnight"] = 2.0
	sim._choose_intent(bell)
	var ev := _turn(sim, bell)
	assert_true(_types(ev).has("windup_tick"), "första turen laddar")
	ev = _turn(sim, bell)
	assert_true(_types(ev).has("windup_release"))
	var hit := {}
	for e in ev:
		if e.type == "damage" and e.ability == "midnight_doom":
			hit[e.target] = true
	assert_eq(hit.size(), 4, "Midnatt träffar hela sällskapet")
	assert_eq(int(bell.stacks.get("midnight", 0)), 0, "räkningen börjar om")


func test_midnight_needs_the_kin_to_start() -> void:
	var sim := _sim("crypt_g1")
	var bell := _enemy(sim, "bell_ringer")
	bell.stacks["midnight"] = 2.0
	for e in sim.enemies:
		if e != bell and e.family == "bone_kin":
			e.hp = 1.0
			sim._kill(e)
	sim._choose_intent(bell)
	assert_true(bell.charging.get("ability", "") == "midnight_bell", "utan Benfolket ringer klockan och väcker dem i stället")


# --- 2. Kistornas råd ----------------------------------------------------------

func test_council_traits_pass_to_the_survivors() -> void:
	var sim := _sim("crypt_g2")
	var caller := _enemy(sim, "grave_caller")
	var lid := _enemy(sim, "coffin_bearer", 1)
	var wake := _enemy(sim, "coffin_bearer", 2)
	lid.hp = 1.0
	sim._kill(lid)
	var ev := sim.drain_events()
	assert_true(caller.traits.has("council_lid") and wake.traits.has("council_lid"), "Kistlocket går i arv")
	var passed := ev.filter(func(e: Dictionary) -> bool: return e.type == "trait_passed")
	assert_eq(passed.size(), 1)
	assert_eq(passed[0].to.size(), 2)
	# Gravväckaren tar nu mindre skada (Kistlocket); den sista ärver allt.
	var paladin := _hero(sim, "paladin")
	var with_lid := sim.expected_damage(paladin, caller, "attack")
	caller.traits.erase("council_lid")
	var without := sim.expected_damage(paladin, caller, "attack")
	caller.traits.append("council_lid")
	assert_near(with_lid / without, float(_data.traits.council_lid.modify.damage_taken_mult), 0.01, "Kistlocket verkar hos arvingen")
	wake.hp = 1.0
	sim._kill(wake)
	assert_true(caller.traits.has("council_wake") and caller.traits.has("council_lid") and caller.traits.has("council_power"),
			"den sista bär alla tre")


func test_council_wake_heals_and_power_hits_harder() -> void:
	var sim := _sim("crypt_g2")
	var wake := _enemy(sim, "coffin_bearer", 2)
	wake.hp = wake.max_hp * 0.5
	sim.drain_events()
	sim.current = wake
	sim._emit({"type": "turn_start", "unit": wake.id})
	var pct := float(_data.traits.council_wake.effects[0].pct_max_hp)
	assert_near(wake.hp, wake.max_hp * (0.5 + pct), 1.0, "Likvakan helar en andel av livet")
	var caller := _enemy(sim, "grave_caller")
	var brokk := _hero(sim, "brokk")
	var with_power := sim.expected_damage(caller, brokk, caller.attack_ability)
	caller.traits.erase("council_power")
	assert_near(with_power / sim.expected_damage(caller, brokk, caller.attack_ability), float(_data.traits.council_power.modify.damage_mult), 0.01,
			"Gravens kraft")


# --- 3. Inkvisitorns domstol ---------------------------------------------------

func test_guilt_stacks_on_the_provoker_and_cuts_healing() -> void:
	var sim := _sim("chapel_g2")
	var inq := _enemy(sim, "inquisitor")
	var brokk := _hero(sim, "brokk")
	var alva := _hero(sim, "alva")
	sim._add_aura(brokk, brokk, "provoke")
	for i in 3:
		sim._deal_damage(inq, brokk, 1.0, "shadow", inq.attack_ability, false, true, "attack", true)
	assert_eq(int(brokk.auras.guilt.stacks), 3, "tre staplar Skuld")
	# Den som inte provocerar får ingen Skuld.
	sim._deal_damage(inq, alva, 1.0, "shadow", inq.attack_ability, false, true, "attack", true)
	assert_true(not alva.auras.has("guilt"))
	brokk.hp = 10.0
	sim.drain_events()
	sim._heal(alva, brokk, 50.0, "healing_light")
	var heal: Dictionary = sim.drain_events().filter(func(e: Dictionary) -> bool: return e.type == "heal")[0]
	assert_eq(int(heal.amount), 20, "tre staplar: 40 % av helningen (50 → 20)")


func test_three_guilt_makes_the_inquisitor_charge_a_verdict() -> void:
	var sim := _sim("chapel_g2")
	var inq := _enemy(sim, "inquisitor")
	var brokk := _hero(sim, "brokk")
	inq.cooldowns.clear()
	sim._add_aura(inq, brokk, "guilt")
	sim._add_aura(inq, brokk, "guilt")
	sim._choose_intent(inq)
	assert_true(not sim.is_charging(inq) or inq.charging.ability != "inquisitor_verdict", "två staplar räcker inte")
	inq.charging = {}
	inq.cooldowns.clear()
	sim._add_aura(inq, brokk, "guilt")
	sim._choose_intent(inq)
	assert_true(sim.is_charging(inq) and inq.charging.ability == "inquisitor_verdict", "Dom laddas")
	assert_eq(inq.intent.targets, [brokk.id], "mot den som bär Skulden")
	assert_true(sim.is_charge_target(brokk) and not sim.is_charge_target(_hero(sim, "alva")))
	# Rensad Skuld bryter domen.
	sim._strip(brokk, "debuff", 99, "purge")
	assert_true(not sim.is_charging(inq), "rensad Skuld: domen bryts")
	assert_true(sim.drain_events().any(func(e: Dictionary) -> bool:
			return e.type == "windup_broken" and e.reason == "absolved"))


func test_verdict_lands_and_clears_guilt() -> void:
	var sim := _sim("chapel_g2")
	var inq := _enemy(sim, "inquisitor")
	var brokk := _hero(sim, "brokk")
	inq.cooldowns.clear()
	for i in 3:
		sim._add_aura(inq, brokk, "guilt")
	sim._choose_intent(inq)
	var ev := _turn(sim, inq)
	var landed := ev.filter(func(e: Dictionary) -> bool: return e.type == "damage" and e.ability == "inquisitor_verdict")
	assert_true(not landed.is_empty() and landed[0].target == brokk.id, "domen faller på den skyldige")
	assert_true(not brokk.auras.has("guilt"), "domen tar bort Skulden")


# --- 4. Abbedissans kör --------------------------------------------------------

func test_only_the_crown_bearer_takes_full_damage() -> void:
	var sim := _sim("chapel_g1")
	sim.begin()
	var abbess := _enemy(sim, "corrupted_abbess")
	var deacon := _enemy(sim, "corrupted_deacon")
	assert_true(abbess.auras.has("sisters_crown"), "Abbedissan bär kronan från början")
	var paladin := _hero(sim, "paladin")
	var full := sim.expected_damage(paladin, deacon, "attack")
	sim._add_aura(abbess, deacon, "sisters_crown")
	abbess.auras.erase("sisters_crown")
	var crowned := sim.expected_damage(paladin, deacon, "attack")
	assert_near(full / crowned, 0.5, 0.01, "utan kronan: halva skadan")
	# Häxan hör inte till kören och tar alltid full skada.
	var witch := _enemy(sim, "witch")
	if witch != null:
		assert_true(not witch.traits.has("choir_shield"))


func test_crown_moves_after_three_turns_and_on_death() -> void:
	var sim := _sim("chapel_g1")
	sim.begin()
	var abbess := _enemy(sim, "corrupted_abbess")
	sim.drain_events()
	for i in 3:
		sim._tick_turn_start(abbess)
	assert_true(not abbess.auras.has("sisters_crown"), "kronan flyttar efter tre av bärarens turer")
	var bearer: CombatUnit = null
	for e in sim.enemies:
		if e.auras.has("sisters_crown"):
			bearer = e
	assert_true(bearer != null and bearer.traits.has("choir_shield") and bearer != abbess, "till en annan i kören")
	assert_true(sim.drain_events().any(func(e: Dictionary) -> bool: return e.type == "aura_passed"))
	bearer.hp = 1.0
	sim._kill(bearer)
	var next: CombatUnit = null
	for e in sim.enemies:
		if e.alive and e.auras.has("sisters_crown"):
			next = e
	assert_true(next != null and next != bearer, "faller bäraren går kronan vidare")


# --- Makrovillkoren -------------------------------------------------------------

func test_macro_conditions_for_guardians() -> void:
	var sim := _sim("crypt_g1")
	var bell := _enemy(sim, "bell_ringer")
	bell.stacks["midnight"] = 2.0
	sim._choose_intent(bell)
	var line := {"subject": "any_enemy", "cond": "is_channeling", "value": 0, "action": "attack", "target": "that"}
	var hit := MacroRunner.match_line(sim, _hero(sim, "paladin"), line)
	assert_true(hit != null and hit.family == "bone_kin" and hit != bell, "anfall den som håller Midnatt")
	assert_eq(MacroRunner.condition_name(_data, "is_channeling", 0), "håller en laddning vid liv")
	assert_eq(MacroRunner.condition_name(_data, "is_charge_target", 0), "är måltavla för en laddning")
	var self_line := {"subject": "self", "cond": "is_charge_target", "value": 0, "action": "defend"}
	assert_true(MacroRunner.match_line(sim, _hero(sim, "alva"), self_line) != null, "Midnatt gäller alla")


# --- Troféerna ------------------------------------------------------------------

func test_guardian_trophy_after_two_wins() -> void:
	assert_eq(RunState.GUARDIAN_WINS_FOR_TROPHY, 2)
	var p := Profile.new()
	p.defeat_guardian("crypt_g1")
	assert_true(p.unlocked_guardians().is_empty(), "en seger räcker inte")
	assert_true(p.boss_wins.is_empty() and p.bosses_defeated.is_empty(), "väktaren räknas inte som boss")
	p.defeat_guardian("crypt_g1")
	assert_eq(p.unlocked_guardians(), ["crypt_g1"])
	var s := RunState.new()
	s.set_realm(_data, "crypt")
	s.depth = 2
	s.fill_charges(_data)
	s.start_expedition(_data, 5)
	s.floor = RunState.FLOORS_PER_RUN - 1
	s.start_floor(_data)
	s.pos = s.map.goal
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	assert_true(not s.trophy_offer(_data, rng, [], [], []).has("midnight_clapper"), "låst: ingen väktartrofé")
	rng.seed = 4
	var offer := s.trophy_offer(_data, rng, [], [], p.unlocked_guardians())
	assert_true(offer.has("midnight_clapper"), "två segrar: Midnattsklockans kläpp erbjuds")
	# Sparas och läses.
	const TMP := "user://test_guardian_wins.cfg"
	p.save(TMP)
	var back := Profile.load_from(TMP)
	assert_eq(int(back.guardian_wins.get("crypt_g1", 0)), 2)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP))


func test_clapper_interrupts_windups() -> void:
	var sim := CombatSim.create(_data, "crypt_3", 3, PARTY, {"paladin": ["midnight_clapper"]})
	var lich: CombatUnit = null
	for e in sim.enemies:
		if e.kind == "bone_lich":
			lich = e
	lich.hp = lich.max_hp * 0.4
	lich.cooldowns.clear()
	lich.intent = {}
	sim._choose_intent(lich)
	assert_true(sim.is_charging(lich))
	var paladin := _hero(sim, "paladin")
	for i in 3:
		sim.current = paladin
		sim._emit({"type": "acted", "unit": paladin.id, "action": "attack", "ability": "attack", "targets": []})
		if i < 2:
			assert_true(sim.is_charging(lich), "inte förrän tredje gången")
	assert_true(not sim.is_charging(lich), "kläppen bryter laddningen")
	assert_true(paladin.traits.has("midnight_clapper_cost"), "kostnaden följer med")


func test_council_seal_inherits_a_fallen_trophy() -> void:
	var sim := CombatSim.create(_data, "crypt_1", 3, PARTY, {"paladin": ["council_seal"], "eira": ["bone_finger"]})
	var eira := _hero(sim, "eira")
	eira.hp = 1.0
	sim._kill(eira)
	assert_true(_hero(sim, "paladin").traits.has("bone_finger"), "sigillet ärver den fallnas trofé")
	var alva := _hero(sim, "alva")
	var paladin := _hero(sim, "paladin")
	paladin.hp = 10.0
	sim.drain_events()
	sim._heal(alva, paladin, 50.0, "healing_light")
	var heal: Dictionary = sim.drain_events().filter(func(e: Dictionary) -> bool: return e.type == "heal")[0]
	assert_eq(int(heal.amount), 40, "kostnaden: 20 % mindre helning")


func test_wandering_crown_goes_to_the_weakest() -> void:
	var sim := CombatSim.create(_data, "crypt_1", 3, PARTY, {"brokk": ["wandering_crown"]})
	sim.begin()
	var brokk := _hero(sim, "brokk")
	assert_true(brokk.auras.has("wandering_crown"), "bäraren börjar med kronan")
	var eira := _hero(sim, "eira")
	eira.hp = eira.max_hp * 0.2
	brokk.hp = 1.0
	sim._kill(brokk)
	assert_true(eira.auras.has("wandering_crown"), "kronan går till den med lägst liv")


func test_gavel_judges_its_target() -> void:
	var sim := CombatSim.create(_data, "crypt_1", 3, PARTY, {"paladin": ["tribunal_gavel"]})
	var paladin := _hero(sim, "paladin")
	var foe: CombatUnit = sim.enemies[0]
	var cold := sim.expected_damage(paladin, foe, "attack")
	sim._deal_damage(paladin, foe, 1.0, "physical", "attack", false, true, "attack", true)
	assert_true(foe.auras.has("guilt"), "klubban ger Skuld")
	assert_near(sim.expected_damage(paladin, foe, "attack") / cold, 1.25 / 0.85, 0.01, "+25 % mot den skyldige, −15 % annars")


# --- Sven vid porten ----------------------------------------------------------

func test_sven_names_the_guardian_of_the_next_depth() -> void:
	var p := Profile.new()
	p.realm = "crypt"
	p.depth = 2
	var line := Dialog.gate_guard_line(_data, p)
	assert_true(line.contains("Klockaren"), "djup 2 i kryptan: Klockaren (%s)" % line)
	p.depth = 3
	assert_true(Dialog.gate_guard_line(_data, p).contains("Gravväckaren"))
	p.depth = 4
	assert_true(Dialog.gate_guard_line(_data, p).contains("Benfursten"), "huvudbossens djup")
	p.realm = "chapel"
	p.depth = 2
	assert_true(Dialog.gate_guard_line(_data, p).contains("abbedissan"))
