extends "res://tests/test_case.gd"
## 0.31 Varslade attacker (docs/plan/varslade-attacker.md steg 1): laddning, släpp, brott, Vacklande, skyddet mot evigt
## lås och makrovillkoren.

var _data := GameData.load_all().duplicate(true)
## Samma data med en laddning på två turer (en tur går åt till laddningen innan slaget).
var _data2 := _two_turns()


func _two_turns() -> Dictionary:
	var d := _data.duplicate(true)
	d.abilities.lich_doom.windup.turns = 2
	return d


## Benfurstens sal med Benfursten under 50 % liv, så att Dödsdom är hans val. Ingen begin(): testerna styr turerna själva.
func _boss(data: Dictionary = _data, seed_value := 3) -> CombatSim:
	var sim := CombatSim.create(data, "crypt_3", seed_value, ["paladin", "brokk", "alva", "eira"])
	var lich := _lich(sim)
	lich.hp = lich.max_hp * 0.4
	lich.cooldowns.clear()
	lich.intent = {}
	return sim


func _lich(sim: CombatSim) -> CombatUnit:
	for e in sim.enemies:
		if e.kind == "bone_lich":
			return e
	return null


func _turn(sim: CombatSim, u: CombatUnit) -> Array[Dictionary]:
	sim.drain_events()
	sim.current = u
	sim.ai_act()
	return sim.drain_events()


func _types(events: Array[Dictionary]) -> Array:
	return events.map(func(e: Dictionary) -> String: return e.type)


func test_benfursten_doom_has_a_windup() -> void:
	var w: Dictionary = _data.abilities.lich_doom.windup
	assert_eq(int(w.turns), 1)
	assert_true(w.broken_by.has("silenced") and w.broken_by.has("stagger"))
	assert_true(_data.auras.has("staggered"), "Vacklande finns")


func test_one_turn_windup_releases_on_the_next_turn() -> void:
	var sim := _boss()
	var lich := _lich(sim)
	sim._choose_intent(lich)
	assert_true(sim.is_charging(lich), "Dödsdom laddas")
	assert_eq(sim.charge_left(lich), 1, "slår nästa gång han står på tur")
	var ev := _turn(sim, lich)
	assert_true(_types(ev).has("windup_release") and not _types(ev).has("windup_tick"))
	assert_true(ev.any(func(e: Dictionary) -> bool: return e.type == "action" and e.ability == "lich_doom"))


func test_turn_time_rechoice_never_fires_a_windup_unannounced() -> void:
	var sim := _boss()
	var lich := _lich(sim)
	lich.intent = {"ability": "bone_storm", "targets": []}
	lich.cooldowns["bone_storm"] = 3.0  # avsikten blev ogiltig (Benstorm kastades av vreden)
	var ev := _turn(sim, lich)
	assert_true(not ev.any(func(e: Dictionary) -> bool: return e.type == "action" and e.ability == "lich_doom"),
			"Dödsdom kommer inte utan varning")


func test_charge_costs_a_turn_and_releases_after_it() -> void:
	var sim := _boss(_data2)
	var lich := _lich(sim)
	sim._choose_intent(lich)
	assert_true(sim.is_charging(lich), "Dödsdom laddas")
	assert_eq(sim.charge_left(lich), 2, "en tur att ladda, sedan slaget")
	assert_true(_types(sim.drain_events()).has("windup_start"))
	var ev := _turn(sim, lich)
	assert_true(_types(ev).has("windup_tick"))
	assert_true(not _types(ev).has("action"), "laddningen kostar turen, ingen handling")
	assert_eq(sim.charge_left(lich), 1)
	assert_eq(lich.intent.ability, "lich_doom", "avsikten står kvar under laddningen")
	ev = _turn(sim, lich)
	assert_true(_types(ev).has("windup_release"))
	var acted := ev.filter(func(e: Dictionary) -> bool: return e.type == "action" and e.unit == lich.id)
	assert_eq(acted.size(), 1)
	assert_eq(acted[0].ability, "lich_doom", "Dödsdom släpps")
	assert_true(not sim.is_charging(lich))
	assert_true(lich.cooldown_left("lich_doom") > 0.0, "nedkylningen börjar när den släpps")


func _release_damage(defend: bool) -> float:
	var sim := _boss()
	var lich := _lich(sim)
	sim._choose_intent(lich)
	var target := sim.unit(lich.intent.targets[0])
	if defend:
		sim._add_aura(target, target, "defend")
	var total := 0.0
	for e in _turn(sim, lich):
		if e.type == "damage" and e.get("target", "") == target.id and e.get("ability", "") == "lich_doom":
			total += float(e.amount)
	return total


func test_defend_dampens_the_release() -> void:
	var open := _release_damage(false)
	var guarded := _release_damage(true)
	assert_true(open > 0.0, "slaget träffar")
	assert_true(guarded < open * 0.8, "Försvara dämpar Dödsdom (%s mot %s)" % [guarded, open])


func test_silence_breaks_the_charge_even_on_a_resistant_boss() -> void:
	var sim := _boss()
	var lich := _lich(sim)
	assert_true(lich.resistant, "Benfursten är Resistent")
	sim._choose_intent(lich)
	sim.drain_events()
	sim._add_aura(sim.unit("paladin"), lich, "silenced")
	assert_true(not sim.is_charging(lich), "Tystad bryter laddningen")
	var broken := sim.drain_events().filter(func(e: Dictionary) -> bool: return e.type == "windup_broken")
	assert_eq(broken.size(), 1)
	assert_eq(broken[0].reason, "silenced")
	assert_true(lich.auras.has("staggered"), "bruten fiende blir Vacklande")
	assert_near(lich.auras.staggered.damage_taken_mult, 1.25, 1e-9)
	assert_true(lich.cooldown_left("lich_doom") > 0.0, "förmågan får sin nedkylning")
	assert_true(lich.intent.ability != "lich_doom", "en ny avsikt i stället")
	sim._tick_turn_start(lich)
	assert_true(not lich.auras.has("staggered"), "Vacklande varar till fiendens nästa tur")


func test_enough_damage_staggers_the_charge() -> void:
	var sim := _boss()
	var lich := _lich(sim)
	sim._choose_intent(lich)
	var p := sim.unit("paladin")
	sim._deal_damage(p, lich, lich.max_hp * 0.05, "physical", "test", false, false, "pure")
	assert_true(sim.is_charging(lich), "lite skada räcker inte")
	sim._deal_damage(p, lich, lich.max_hp * 0.27, "physical", "test", false, false, "pure")
	assert_true(not sim.is_charging(lich), "30 % av max-livet under laddningen bryter den")
	assert_true(sim.drain_events().any(func(e: Dictionary) -> bool:
			return e.type == "windup_broken" and e.reason == "stagger"))


func test_a_broken_enemy_cannot_be_locked_forever() -> void:
	# Utan nedkylning: bara skyddet hindrar att den börjar och bryts om och om igen.
	var data := _data.duplicate(true)
	data.abilities.lich_doom.cooldown = 0
	var sim := _boss(data)
	var lich := _lich(sim)
	var p := sim.unit("paladin")
	var actions := 0
	var charges := 0
	for i in 8:
		sim._choose_intent(lich)
		if sim.is_charging(lich):
			charges += 1
			lich.auras.erase("staggered")
			sim._add_aura(p, lich, "silenced")
			lich.auras.erase("silenced")  # tystnaden släpper, laddningen är bruten
			assert_true(lich.windup_guard)
			sim._choose_intent(lich)
			assert_true(not sim.is_charging(lich), "ingen ny laddning förrän efter nästa tur")
		if _turn(sim, lich).any(func(e: Dictionary) -> bool: return e.type == "action" and e.unit == lich.id):
			actions += 1
	assert_true(charges >= 4, "den försöker igen (%d)" % charges)
	assert_eq(actions, 8, "varje tur blev en riktig handling trots att varje laddning bröts")


func test_sleep_delays_the_charge() -> void:
	var sim := _boss()
	var lich := _lich(sim)
	lich.resistant = false
	sim._choose_intent(lich)
	sim._add_aura(sim.unit("paladin"), lich, "sleeping")
	sim.order = [lich.id]
	sim.drain_events()
	sim._next_turn()
	assert_true(_types(sim.drain_events()).has("windup_delayed"))
	assert_eq(sim.charge_left(lich), 1, "turen som gick förlorad räknas inte")


func test_macro_conditions_see_the_charge() -> void:
	var sim := _boss(_data2)
	var lich := _lich(sim)
	var p := sim.unit("paladin")
	var charging := {"subject": "any_enemy", "cond": "is_charging", "value": 0, "action": "defend", "target": "that"}
	var soon := {"subject": "any_enemy", "cond": "charge_left_at_most", "value": 1, "action": "defend", "target": "that"}
	assert_eq(MacroRunner.match_line(sim, p, charging), null, "ingen laddar än")
	sim._choose_intent(lich)
	assert_eq(MacroRunner.match_line(sim, p, charging), lich)
	assert_eq(MacroRunner.match_line(sim, p, soon), null, "två turer kvar")
	_turn(sim, lich)
	assert_eq(MacroRunner.match_line(sim, p, soon), lich, "slår nästa tur")
	var plan := MacroRunner.decide(sim, p, {"lines": [soon, {"subject": "any_enemy", "cond": "is_alive", "value": 0,
			"action": "attack", "target": "that"}]})
	assert_eq(plan.action, "defend")
	assert_eq(MacroRunner.condition_name(sim.data, "charge_left_at_most", 2), "laddar, slår om högst 2 turer")
