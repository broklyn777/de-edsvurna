extends "res://tests/test_case.gd"
## 0.31 (docs/plan/spindlar.md): Sidenlunden och Spindelfolket – kedjan Snärjd → gift → blind → blödning, Slukaren,
## Strypvävaren med Spindelskräck, Vävmodern, troféerna och Lundens föremål.

var _data := GameData.load_all()

const SPIDERS := ["snare_spider", "venom_spider", "dust_spider", "barb_spider", "sleep_weaver", "devourer_spider",
		"old_knot", "web_mother"]


func _sim(encounter: String, traits := {}, opts := {}, seed_value := 3) -> CombatSim:
	return CombatSim.create(_data, encounter, seed_value, ["paladin", "brokk", "alva", "eira"], traits, {}, {}, 1, opts)


func _enemy(sim: CombatSim, kind: String) -> CombatUnit:
	for e in sim.enemies:
		if e.kind == kind:
			return e
	return null


## Den första träffen från src mot tgt (försöker igen om den undveks). Returnerar händelsens calc.
func _hit(sim: CombatSim, src: CombatUnit, tgt: CombatUnit, ability_id := "x", kind := "attack") -> Dictionary:
	for i in 40:
		sim.drain_events()
		sim._deal_damage(src, tgt, 1.0, "physical", ability_id, false, true, kind, true)
		for e in sim.drain_events():
			if e.type == "damage" and e.source == src.id and e.target == tgt.id:
				return e.calc
	return {}


## Fästtråd slår till i hälften av betten: biter tills målet är snärjt.
func _snare(sim: CombatSim, spider: CombatUnit, tgt: CombatUnit) -> void:
	for i in 30:
		if tgt.auras.has("snared"):
			return
		_hit(sim, spider, tgt, "snare_bite")


func _factor(calc: Dictionary, name: String) -> float:
	for m in calc.get("mods", []):
		if m.name == name:
			return float(m.f)
	return 1.0


func test_spiders_have_data_trophies_family_and_a_realm() -> void:
	for kind in SPIDERS:
		var d: Dictionary = _data.enemies[kind]
		assert_eq(d.get("family", ""), "spider_kin", "%s hör till Spindelfolket" % kind)
		assert_eq(d.visual.model, "spindel", "%s använder spindelmodellen" % kind)
		for t in d.traits:
			assert_true(_data.traits.has(t), "%s: egenskapen %s finns" % [kind, t])
			assert_true(String(_data.traits[t].get("text", "")).length() <= 110, "%s: texten går att läsa på mobilen" % t)
		assert_true(_data.traits[d.trophy].get("trophy", false), "%s lämnar en trofé" % kind)
		assert_true(_data.traits[d.trophy].has("answers"), "%s: trofén säger vad den svarar på" % kind)
		assert_true(_data.abilities.has(d.attack_ability), "%s har ett grundanfall" % kind)
		for rule in d.get("rules", []):
			assert_true(_data.abilities.has(rule.ability), "%s: förmågan %s finns" % [kind, rule.ability])
		if d.has("elite"):
			assert_true(_data.traits[d.elite.trophy].get("trophy", false))
			assert_true(_data.traits[d.elite.trait].get("rarity", "") == "elite", "%s: elitvariantens trofé är elit" % kind)
		if d.has("counter"):
			assert_true(_data.traits[d.counter.trait].get("counter", false), "%s: motdraget är märkt" % kind)
	var grove: Dictionary = _data.realms.grove
	var all: Array = grove.floors.duplicate()
	for pool in grove.pools + grove.elite_pools:
		all.append_array(pool)
	for enc_id in all:
		assert_true(_data.encounters.has(enc_id), enc_id)
		for kind in _data.encounters[enc_id].enemies:
			assert_true(SPIDERS.has(kind), "%s: bara spindlar i Lunden" % enc_id)
	for obj in grove.objects:
		assert_true(_data.objects.has(obj), obj)
	assert_true(_data.enemies.web_mother.get("boss", false), "Vävmodern är bossen")
	assert_eq(_data.enemies.old_knot.get("rank", ""), "miniboss")


func test_fastening_thread_snares_and_sinks_the_target() -> void:
	var sim := _sim("grove_1b")  # Snärjspindel och Dammspindel
	var spider := _enemy(sim, "snare_spider")
	var brokk := sim.unit("brokk")
	sim.order.assign(sim.units.map(func(u: CombatUnit) -> String: return u.id))
	_snare(sim, spider, brokk)
	assert_true(brokk.auras.has("snared"), "bettet snärjer")
	assert_eq(sim.order[-1], "brokk", "den snärjda hamnar längst ned")
	var alva := sim.unit("alva")
	_hit(sim, sim.unit("paladin"), _enemy(sim, "dust_spider"))
	assert_true(not alva.auras.has("snared"), "bara bettet")


func test_venom_thread_poisons_whoever_gets_snared() -> void:
	var sim := _sim("grove_1a")  # Snärjspindel och Gifttand
	var venom := _enemy(sim, "venom_spider")
	var eira := sim.unit("eira")
	_snare(sim, _enemy(sim, "snare_spider"), eira)
	assert_true(eira.auras.has("poisoned"), "snärjd → förgiftad")
	assert_eq(eira.auras.poisoned.source, venom.id, "giftet är Gifttandens (dess Attack)")
	sim._kill(venom)
	var alva := sim.unit("alva")
	_snare(sim, _enemy(sim, "snare_spider"), alva)
	assert_true(alva.auras.has("snared") and not alva.auras.has("poisoned"), "utan Gifttanden bara snärjd")


func test_dust_blinds_only_the_poisoned_and_bites_them_first() -> void:
	var sim := _sim("grove_1c")  # Gifttand och Dammspindel
	var dust := _enemy(sim, "dust_spider")
	var brokk := sim.unit("brokk")
	_hit(sim, dust, brokk, "dust_bite")
	assert_true(not brokk.auras.has("blind"), "inte utan gift")
	sim._add_aura(_enemy(sim, "venom_spider"), brokk, "poisoned")
	_hit(sim, dust, brokk, "dust_bite")
	assert_true(brokk.auras.has("blind"), "förgiftad → förblindad")
	assert_eq(float(brokk.auras.blind.remaining), 2.0, "räcker över hjältens nästa tur")
	# pick_aura: Dammbettet går mot den förgiftade även om någon annan har lägre liv.
	sim.unit("alva").hp = 1.0
	assert_eq(sim._pick_targets(dust, _data.abilities.dust_bite), ["brokk"], "Dammbettet tar den förgiftade")
	sim._remove_aura(brokk, "poisoned", "test")
	assert_eq(sim._pick_targets(dust, _data.abilities.dust_bite), ["alva"], "utan gift: lägst liv")


func test_barbs_make_a_blinded_attacker_bleed() -> void:
	var sim := _sim("grove_2d")  # Snärjspindel och Hullingspindel
	var barb := _enemy(sim, "barb_spider")
	var paladin := sim.unit("paladin")
	_hit(sim, paladin, barb)
	assert_true(not paladin.auras.has("bleeding"), "seende anfall går fri")
	sim._add_aura(barb, paladin, "blind")
	_hit(sim, paladin, barb)
	assert_true(paladin.auras.has("bleeding"), "förblindad som anfaller: blöder")
	var alva := sim.unit("alva")
	sim._add_aura(barb, alva, "blind")
	_hit(sim, alva, barb, "x", "spell")
	assert_true(not alva.auras.has("bleeding"), "bara anfall")


func test_devourer_doubles_on_the_snared_heals_and_releases() -> void:
	var sim := _sim("grove_e2")  # Slukaren, Snärjspindel, Dammspindel
	var dev := _enemy(sim, "devourer_spider")
	var brokk := sim.unit("brokk")
	var calc := _hit(sim, dev, brokk, "devour_bite")
	assert_near(_factor(calc, "Sluka"), 1.0, 1e-9, "inte mot en fri hjälte")
	sim._add_aura(_enemy(sim, "snare_spider"), brokk, "snared")
	dev.hp = 10.0
	calc = _hit(sim, dev, brokk, "devour_bite")
	assert_near(_factor(calc, "Sluka"), 2.0, 1e-9, "dubbel skada mot den snärjda")
	assert_true(not brokk.auras.has("snared"), "snärjningen släpper")
	assert_near(dev.hp, minf(dev.max_hp, 10.0 + roundf(float(calc.lost) * 0.5)), 1.0, "helar hälften")
	sim._add_aura(_enemy(sim, "snare_spider"), sim.unit("eira"), "snared")
	assert_eq(sim._pick_targets(dev, _data.abilities.devour_bite), ["eira"], "avsikten visar offret")


func test_weaver_puts_the_snared_to_sleep() -> void:
	var sim := _sim("grove_e1")
	var weaver := _enemy(sim, "sleep_weaver")
	var alva := sim.unit("alva")
	_hit(sim, weaver, alva, "weaver_bite")
	assert_true(not alva.auras.has("sleeping"), "inte en fri hjälte")
	sim._add_aura(_enemy(sim, "snare_spider"), alva, "snared")
	_hit(sim, weaver, alva, "weaver_bite")
	assert_true(alva.auras.has("sleeping"), "den snärjda somnar")
	_hit(sim, _enemy(sim, "venom_spider"), alva, "venom_bite")
	assert_true(not alva.auras.has("sleeping"), "och vaknar av nästa träff")


func test_old_knot_strangles_the_top_hero_and_carries_arachnophobia() -> void:
	var sim := _sim("grove_e3", {}, {"counter": true})  # Strypvävaren, Gifttand, Dammspindel
	var knot := _enemy(sim, "old_knot")
	sim.order.assign(sim.units.map(func(u: CombatUnit) -> String: return u.id))
	assert_true(knot.traits.has("arachnophobia"), "motdraget sitter på Strypvävaren")
	var top := ""
	for id in sim.order:
		if sim.unit(id).team == 0:
			top = id
			break
	sim._emit({"type": "turn_start", "unit": knot.id})
	assert_true(sim.unit(top).auras.has("bleeding"), "den överst på tidslinjen stryps (0.30.25: Blöder, ingen snara)")
	var venom := _enemy(sim, "venom_spider")
	var hero := sim.unit(top)
	sim._add_aura(venom, hero, "snared")
	sim.drain_events()
	sim._deal_damage(venom, hero, 5.0, "nature", "poisoned", false, false, "indirect")
	var dmg: Array = sim.drain_events().filter(func(e: Dictionary) -> bool: return e.type == "damage")
	assert_near(_factor(dmg[0].calc, "Spindelskräck"), 2.0, 1e-9, "giftet gör dubbelt på den snärjda")
	assert_true(not _enemy(_sim("grove_e3"), "old_knot").traits.has("arachnophobia"), "motdraget bara när det är på")


func test_web_mother_poisons_whoever_breaks_free() -> void:
	var sim := _sim("grove_3")
	var mother := _enemy(sim, "web_mother")
	assert_true(mother.resistant, "bossen är resistent")
	var eira := sim.unit("eira")
	sim._add_aura(mother, eira, "snared")
	sim._remove_aura(eira, "poisoned", "test")  # Gifttanden förgiftade redan när hon snärjdes
	sim._remove_aura(eira, "snared", "expired")
	assert_true(not eira.auras.has("poisoned"), "när snaran tar slut: inget gift")
	sim._remove_aura(eira, "unbound", "test")  # 0.30.25: Fri efter snaran skyddar annars mot nästa
	sim._add_aura(mother, eira, "snared")
	sim._remove_aura(eira, "poisoned", "test")
	sim._remove_aura(eira, "snared", "broke_free")
	assert_true(eira.auras.has("poisoned"), "den som sliter sig loss förgiftas")
	for h in sim.heroes:
		sim._remove_aura(h, "unbound", "test")
	sim._apply_effects(mother, "cocoon_storm", sim.heroes.filter(func(h: CombatUnit) -> bool: return h.alive).map(
			func(h: CombatUnit) -> String: return h.id))
	assert_true(sim.heroes.all(func(h: CombatUnit) -> bool: return not h.alive or h.auras.has("snared")), "Kokongstormen snärjer alla")


func test_spider_trophies_build_the_chain_for_the_party() -> void:
	var sim := _sim("grove_1a", {"paladin": ["thread_spool"], "eira": ["venom_fang"], "alva": ["dust_tuft"]})
	var paladin := sim.unit("paladin")
	var snare := _enemy(sim, "snare_spider")
	_hit(sim, paladin, snare)
	assert_true(snare.auras.has("snared"), "Snärjtrådenn snärjer första gången")
	assert_true(snare.auras.has("poisoned") and sim.unit(snare.auras.poisoned.source).id == "eira", "Gifttanden förgiftar")
	_hit(sim, sim.unit("alva"), snare)
	assert_true(snare.auras.has("blind"), "Dammkörteln förblindar den förgiftade")
	var venom := _enemy(sim, "venom_spider")
	_hit(sim, paladin, venom)
	assert_true(not venom.auras.has("snared"), "Snärjtrådenn bara en gång per strid")


func test_knot_eye_trophy_starts_last_and_mother_silk_costs_attacks() -> void:
	var sim := _sim("crypt_1", {"brokk": ["knot_eye"]})
	sim.begin()
	var heroes_in_order: Array = sim.order.filter(func(id: String) -> bool: return sim.unit(id).team == 0)
	assert_true(heroes_in_order.is_empty() or heroes_in_order[-1] == "brokk" or sim.current.id == "brokk",
			"bäraren börjar längst ned")
	sim = _sim("crypt_1", {"brokk": ["mother_silk"]})
	var calc := _hit(sim, sim.unit("eira"), sim.enemies[0])
	assert_near(_factor(calc, "Moderns silke"), 0.85, 1e-9, "sällskapets anfall gör 15 % mindre")


func test_grove_objects_use_their_own_text() -> void:
	var p := Profile.new()
	p.party = ["paladin", "brokk"]
	p.realm = "grove"
	var s := RunState.new_run(p, _data)
	s.start_expedition(_data, 5)
	assert_eq(s.realm, "grove")
	var r := s.current_room()
	r.obj = "dew_web"
	var out := s.use_object(_data, "pull", RandomNumberGenerator.new())
	assert_true(String(out.text).begins_with("Daggen"), "Daggnätets egen text")
	r.obj = "silk_trail"
	r.erase("done")
	out = s.use_object(_data, "neighbours", RandomNumberGenerator.new())
	assert_true(String(out.text).begins_with("Spåret"), "Silkesspårets egen text")


func test_every_spider_has_a_signature_action_with_its_own_intent() -> void:
	for kind in SPIDERS:
		var d: Dictionary = _data.enemies[kind]
		var own: Array = d.get("rules", []).filter(func(r: Dictionary) -> bool: return r.ability != d.attack_ability)
		assert_true(not own.is_empty(), "%s har en egen handling" % kind)
		for r in own:
			var ab: Dictionary = _data.abilities[r.ability]
			assert_true(ab.has("text") and ab.has("sound"), "%s: %s har text och ljud" % [kind, r.ability])
	var sim := _sim("grove_1a")
	var snare := _enemy(sim, "snare_spider")
	sim._choose_intent(snare)
	assert_eq(snare.intent.ability, "web_shot", "Snärjspindeln börjar med Nätskott")
	sim._apply_effects(snare, "web_shot", snare.intent.targets)
	assert_true(sim.unit(snare.intent.targets[0]).auras.has("snared"), "nätet snärjer")
	var venom := _enemy(sim, "venom_spider")
	var calc := _hit(sim, venom, sim.unit(snare.intent.targets[0]), "venom_strike")
	assert_eq(float(calc.get("combo", {}).get("mult", 1.0)), 1.5, "Gifthugget slår hårdare mot den snärjda")
	sim = _sim("grove_e3")
	var knot := _enemy(sim, "old_knot")
	sim._kill(_enemy(sim, "venom_spider"))
	sim._choose_intent(knot)
	assert_eq(knot.intent.ability, "cocoon_revive", "Strypvävaren väcker en fallen spindel")
