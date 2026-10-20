extends "res://tests/test_case.gd"
## Kallen vid Kallets altare (docs/research/siralim.md §13): kärnan och varje perk, plus motorns nya delar
## (scope party, actor, cast/revive/barrier/restore_charge, battle_start).

var _data := GameData.load_all()


## En strid där Paladinen bär Kallet och perkarna. Datan kopieras så att testerna kan ändra chanser.
func _sim(traits: Array, encounter := "crypt_1", begin := true) -> CombatSim:
	var sim := CombatSim.create(_data, encounter, 7, [], {"paladin": traits})
	sim.data = _data.duplicate()
	sim.data.traits = _data.traits.duplicate(true)
	for t in sim.data.traits.values():
		if t.has("chance"):
			t.chance = 1.0  # testerna prövar effekten, inte slumpen
	if begin:
		sim.begin()
		sim.drain_events()
	return sim


func _by(events: Array, ability_id: String, type := "damage") -> Array:
	return events.filter(func(e: Dictionary) -> bool: return e.type == type and e.get("ability", "") == ability_id)


func _no_luck(sim: CombatSim) -> void:
	for u in sim.units:
		u.crit_chance = -1.0
		u.speed = 10.0  # lika fart: inget undvikande


# --- Data och Kallets altare -------------------------------------------------------

func test_every_oath_has_core_and_perks_in_data() -> void:
	for oath_id in _data.oaths:
		assert_true(_data.traits.has(oath_id), "kärnan %s finns" % oath_id)
		for p in _data.oaths[oath_id].perks:
			var t: Dictionary = _data.traits[p.id]
			assert_eq(t.get("oath", ""), oath_id, p.id)
			assert_true(t.get("perk", false), p.id)
			assert_true(int(p.cost) > 0)
	assert_eq(_data.oaths.keys(), Profile.OATHS)


func test_altar_buys_perks_with_points_and_resets_for_free() -> void:
	var p := Profile.new()
	assert_eq(p.perk_points(), Profile.PERK_POINTS_START)
	assert_true(p.buy_perk(_data, "oath_ward", "ward_rest_up"))
	assert_true(not p.buy_perk(_data, "oath_ward", "ward_rest_up"), "en perk köps en gång")
	assert_true(not p.buy_perk(_data, "oath_ward", "dawn_anointment"), "bara Kallets egna perks")
	assert_true(not p.buy_perk(_data, "oath_ward", "ward_titanic_rage"), "poängen räcker inte")
	assert_eq(p.points_used(_data, "oath_ward"), Profile.perk_cost(_data, "oath_ward", "ward_rest_up"))
	assert_eq(p.silver, Profile.START_SILVER, "perks kostar inget silver")
	assert_eq(p.reset_perks(_data, "oath_ward"), Profile.perk_cost(_data, "oath_ward", "ward_rest_up"))
	assert_eq(p.owned_perks("oath_ward"), [])
	assert_true(p.buy_perk(_data, "oath_ward", "ward_titanic_rage"), "poängen kom tillbaka")


func test_perk_points_come_from_realm_quests() -> void:
	var p := Profile.new()
	p.clear_depth(2)
	assert_eq(p.perk_points(), Profile.PERK_POINTS_START, "djupet ger inga poäng längre")
	var r := p.complete_quest("crypt", 1)
	assert_true(r.point)
	assert_eq(p.perk_points(), Profile.PERK_POINTS_START + 1)
	assert_true(not p.complete_quest("crypt", 1).point, "samma Realm och djup ger ingen ny poäng")
	assert_true(p.complete_quest("chapel", 1).point)
	assert_eq(p.perk_points(), Profile.PERK_POINTS_START + 2)
	p.perks = {"oath_dawn": ["dawn_guiding_light", "dawn_greater_healing"]}
	p.quests_done = []
	assert_eq(p.active_perks(_data, "oath_dawn"), ["dawn_guiding_light"], "bara så många som poängen räcker till")


func test_old_profiles_keep_their_perk_points() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "best_depth", 4)
	var path := "user://test_progress_legacy.cfg"
	cfg.save(path)
	var p := Profile.load_from(path)
	assert_eq(p.perk_points(), Profile.PERK_POINTS_START + 2, "4 klarade djup gav 2 poäng före 0.18")
	p.save(path)
	assert_eq(Profile.load_from(path).perk_points(), Profile.PERK_POINTS_START + 2, "och behåller dem efter sparning")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func test_run_brings_oath_and_its_perks() -> void:
	var p := Profile.new()
	p.buy_perk(_data, "oath_dawn", "dawn_anointment")
	p.buy_perk(_data, "oath_ward", "ward_rest_up")
	p.choose_oath("oath_dawn")
	var state := RunState.new_run(p, _data)
	assert_eq(state.hero_traits(_data).paladin, ["oath_dawn", "dawn_anointment"], "bara den valda kallets perks")


# --- Domens kall ----------------------------------------------------------------

func test_vengeance_zeal_hits_harder_for_a_provoking_ally() -> void:
	var amounts := []
	for traits in [["oath_vengeance"], ["oath_vengeance", "vengeance_zeal"]]:
		var sim := _sim(traits)
		_no_luck(sim)
		var alva := sim.unit("alva")
		sim._add_aura(alva, alva, "provoke")
		sim.rng.seed = 11
		sim.drain_events()
		sim._deal_damage(sim.unit("skeleton_archer_1"), alva, 20.0, "physical", "bone_arrow", false, true)
		# 0.26: talen är små, så jämför före avrundningen (heltalet kan skilja ±1).
		amounts.append(float(_by(sim.drain_events(), "oath_vengeance")[0].calc.before_defense))
	assert_near(amounts[1] / amounts[0], 1.5, 0.05, "Iver: +50 %")


func test_vengeance_wrath_only_for_defending_ally() -> void:
	var sim := _sim(["oath_vengeance", "vengeance_wrath"])
	var probe := {"ability": "oath_vengeance", "origin_target": "alva"}
	var paladin := sim.unit("paladin")
	assert_eq(sim._modify(paladin, "modify_damage", probe, "damage_mult", 1.0), 1.0)
	sim._add_aura(sim.unit("alva"), sim.unit("alva"), "defend")
	assert_eq(sim._modify(paladin, "modify_damage", probe, "damage_mult", 1.0), 1.5)


func test_vengeance_reckoning_makes_the_provoker_attack() -> void:
	var sim := _sim(["oath_vengeance", "vengeance_reckoning"])
	var brokk := sim.unit("brokk")
	sim._add_aura(brokk, brokk, "provoke")
	var hits := _by(sim.drain_events(), "vengeance_reckoning")
	hits.append_array(_by(sim.drain_events(), "vengeance_reckoning", "dodge"))
	assert_eq(hits.size(), 1)
	assert_eq(hits[0].source, "brokk", "den som provocerar anfaller (actor: event_unit)")


func test_vengeance_hand_of_light_and_divine_toll() -> void:
	var sim := _sim(["oath_vengeance", "vengeance_hand_of_light", "vengeance_divine_toll"])
	_no_luck(sim)
	sim.unit("eira").hp = 100.0
	sim._deal_damage(sim.unit("skeleton_archer_1"), sim.unit("alva"), 50.0, "physical", "bone_arrow", false, true)
	var events := sim.drain_events()
	assert_true(_by(events, "vengeance_hand_of_light", "heal").size() >= 3, "hela sällskapet helas")
	var toll := events.filter(func(e: Dictionary) -> bool: return e.type == "action" and e.action == "artifact")
	assert_eq(toll.size(), 1, "Helig smäll kastas gratis")
	assert_eq(toll[0].ability, "holy_smite")
	assert_eq(toll[0].targets, ["skeleton_archer_1"], "mot samma fiende")
	assert_eq(sim.unit("paladin").charges.holy_smite, int(_data.abilities.holy_smite.charges), "kostar inga Charges")


func test_vengeance_execution_when_ally_dies() -> void:
	var sim := _sim(["oath_vengeance", "vengeance_execution"])
	sim._kill(sim.unit("alva"))
	var hits := _by(sim.drain_events(), "vengeance_execution")
	assert_eq(hits.size(), sim.enemies.size(), "alla fiender träffas")
	assert_true(hits.all(func(e: Dictionary) -> bool: return e.kind == "indirect" and e.school == "holy"))


# --- Gryningens kall ----------------------------------------------------------------

func test_dawn_core_turns_healing_into_barrier() -> void:
	var sim := _sim(["oath_dawn"])
	var brokk := sim.unit("brokk")
	brokk.hp = 10.0
	sim._heal(sim.unit("alva"), brokk, 20.0, "healing_light")
	assert_eq(brokk.barrier, roundf(20.0 * _data.traits.oath_dawn.effects[0].pct_of_event), "en andel av helningen")
	assert_true(brokk.auras.has("barrier"))


func test_dawn_greater_healing_applies_to_whole_party() -> void:
	var sim := _sim(["oath_dawn", "dawn_greater_healing"])
	var brokk := sim.unit("brokk")
	brokk.hp = 10.0
	sim._heal(sim.unit("alva"), brokk, 20.0, "healing_light")
	assert_eq(brokk.hp, 40.0, "Alvas helning +50 % (scope party)")


func test_dawn_guiding_light_at_battle_start() -> void:
	var sim := _sim(["oath_dawn", "dawn_guiding_light"], "crypt_1", false)
	sim.begin()
	for h in sim.heroes:
		assert_eq(h.barrier, roundf(h.max_hp * 0.15), h.id)


func test_dawn_anointment_blesses_the_healed() -> void:
	var sim := _sim(["oath_dawn", "dawn_anointment"])
	var eira := sim.unit("eira")
	sim._heal(sim.unit("alva"), eira, 50.0, "healing_light")
	assert_true(eira.auras.has("blessing"))


func test_dawn_revelation_revives_at_paladins_turn() -> void:
	var sim := _sim(["oath_dawn", "dawn_revelation"])
	var alva := sim.unit("alva")
	sim._kill(alva)
	sim.drain_events()
	sim._emit({"type": "turn_start", "unit": "paladin"})
	assert_true(alva.alive)
	assert_eq(alva.hp, roundf(alva.max_hp * 0.3))


func test_dawn_holy_might_counts_buffs() -> void:
	var sim := _sim(["oath_dawn", "dawn_holy_might"])
	var eira := sim.unit("eira")
	sim._add_aura(eira, eira, "renew")
	sim._add_barrier(eira, eira, 50.0)
	var mods := sim._modifiers(eira, "modify_damage", {"source": "eira", "kind": "attack"})
	assert_eq(mods.size(), 1)
	assert_eq(sim._buff_count(eira), 2)


# --- Väktarens kall ----------------------------------------------------------------

func test_ward_core_strikes_back_with_defense() -> void:
	var sim := _sim(["oath_ward"])
	var brokk := sim.unit("brokk")
	var archer := sim.unit("skeleton_archer_1")
	sim._deal_damage(archer, brokk, 50.0, "physical", "bone_arrow", false, true)
	var back := _by(sim.drain_events(), "oath_ward")
	assert_eq(back.size(), 1)
	assert_eq(back[0].source, "brokk", "den som träffades slår tillbaka (scope party)")
	assert_eq(back[0].target, archer.id)
	var pct: float = _data.traits.oath_ward.effects[0].pct
	assert_eq(back[0].amount, roundf(CombatSim.indirect_damage(brokk.defense_now() * pct, archer.defense_now())))


func test_ward_in_formation_starts_defending_and_chains_bulwark() -> void:
	var sim := _sim(["oath_ward", "ward_in_formation"], "crypt_1", false)
	sim.begin()
	for h in sim.heroes:
		if h != sim.current:  # den som har första turen har redan slutat försvara sig, som i Siralim
			assert_true(h.auras.has("defend"), h.id)
	assert_true(sim.unit("brokk").auras.has("inspired"), "Brokks Stenhård sätter igång av försvaret")


func test_ward_rest_up_restores_a_charge() -> void:
	var sim := _sim(["oath_ward", "ward_rest_up"])
	var alva := sim.unit("alva")
	alva.charges.healing_light = 3
	sim._add_aura(alva, alva, "defend")
	assert_eq(alva.charges.healing_light, 4)
	assert_eq(_by(sim.drain_events(), "", "charge_restored").size(), 0)
	alva.charges.healing_light = int(_data.abilities.healing_light.charges)
	alva.charges.renew = int(_data.abilities.renew.charges)
	alva.charges.judgement = int(_data.abilities.judgement.charges)
	alva.auras.clear()
	sim._add_aura(alva, alva, "defend")
	assert_eq(alva.charges.healing_light, int(_data.abilities.healing_light.charges), "aldrig över fullt")


func test_ward_titanic_rage_and_best_offense() -> void:
	var sim := _sim(["oath_ward", "ward_titanic_rage", "ward_best_offense"])
	_no_luck(sim)
	var brokk := sim.unit("brokk")
	var warrior := sim.unit("skeleton_archer_1")  # utan Benrustning
	sim._deal_damage(brokk, warrior, 10.0, "physical", "axe_chop", true, true)
	var plain: float = sim.drain_events().filter(func(e: Dictionary) -> bool: return e.type == "damage")[0].amount
	assert_eq(plain, 10.0 + roundf(brokk.defense * 0.3), "Bästa försvaret: + 30 % av Defense")
	sim._add_aura(warrior, warrior, "defend")
	sim.drain_events()
	sim._deal_damage(brokk, warrior, 10.0, "physical", "axe_chop", true, true)
	var raged: float = sim.drain_events().filter(func(e: Dictionary) -> bool: return e.type == "damage")[0].amount
	assert_eq(raged, roundf(10.0 * 1.5 * 0.65) + roundf(brokk.defense * 0.3), "Titanisk vrede mot en som försvarar sig")


# --- Perk-nivåer och lånade perks (0.15) ------------------------------------------

func test_only_numeric_perks_have_ranks() -> void:
	for oath_id in _data.oaths:
		for p in _data.oaths[oath_id].perks:
			var ranks := int(p.get("ranks", 1))
			if ranks > 1:
				assert_true(_data.traits[p.id].has("modify") and not _data.traits[p.id].has("effects"),
						"%s har nivåer men är ingen ren siffra" % p.id)
	assert_eq(Profile.perk_ranks(_data, "vengeance_reckoning"), 1, "regelbrytare har en nivå")


func test_ranks_are_bought_one_at_a_time() -> void:
	var p := Profile.new()
	p.bonus_points = 1  # 3 poäng
	assert_true(p.buy_perk(_data, "oath_vengeance", "vengeance_wrath"))
	assert_true(p.buy_perk(_data, "oath_vengeance", "vengeance_wrath"), "nivå 2")
	assert_true(p.buy_perk(_data, "oath_vengeance", "vengeance_wrath"), "nivå 3")
	assert_true(not p.buy_perk(_data, "oath_vengeance", "vengeance_wrath"), "bara tre nivåer")
	assert_eq(p.perk_rank("oath_vengeance", "vengeance_wrath"), 3)
	assert_eq(p.points_used(_data, "oath_vengeance"), 3)
	assert_eq(p.active_perks(_data, "oath_vengeance").count("vengeance_wrath"), 3)


func test_ranks_add_up_in_combat() -> void:
	var sim := _sim(["oath_dawn", "dawn_greater_healing", "dawn_greater_healing"])
	var probe := {"source": "alva", "target": "brokk", "ability": "healing_light"}
	assert_near(sim._modify(sim.unit("paladin"), "modify_heal", probe, "heal_mult", 1.0), 2.25, 0.001,
			"_modify multiplicerar posterna")
	var factors := []
	for m in sim._modifiers(sim.unit("alva"), "modify_heal", probe):
		factors.append(float(m.heal_mult))
	assert_eq(factors.size(), 2, "två nivåer räknas även för en annan i sällskapet")
	assert_near(CombatSim.combine_mods(factors), 2.0, 0.001, "ökningar adderas: +50 % och +50 %")


func test_anointment_unlocks_on_boss_and_borrows_one_perk() -> void:
	var p := Profile.new()
	assert_true(not p.anoint(_data, "oath_dawn", "ward_war_machine"), "låst innan bossen är besegrad")
	p.defeat_boss("bone_lich")
	p.defeat_boss("bone_lich")
	assert_eq(p.anointment_slots(), 1)
	assert_true(not p.anoint(_data, "oath_dawn", "dawn_anointment"), "inte från samma kall")
	assert_true(p.anoint(_data, "oath_dawn", "ward_war_machine"), "regelbrytare får lånas")
	assert_eq(p.points_used(_data, "oath_dawn"), 2, "kostar poäng ur den lånande Kallets pott")
	assert_true(not p.buy_perk(_data, "oath_dawn", "dawn_anointment"), "poängen är slut")
	assert_true(p.anoint(_data, "oath_dawn", "ward_titanic_rage"), "ett nytt lån ersätter det gamla")
	assert_eq(p.anointed.oath_dawn, "ward_titanic_rage")
	assert_true(p.buy_perk(_data, "oath_dawn", "dawn_anointment"))
	assert_eq(p.active_perks(_data, "oath_dawn"), ["dawn_anointment", "ward_titanic_rage"])
	var state := RunState.new_run(p, _data)
	assert_eq(state.hero_traits(_data).paladin, ["oath_vengeance"], "bara den valda kallet")
	p.choose_oath("oath_dawn")
	state = RunState.new_run(p, _data)
	assert_true(state.hero_traits(_data).paladin.has("ward_titanic_rage"), "lånet följer med i körningen")
	var path := "user://test_progress_anoint.cfg"
	p.save(path)
	var q := Profile.load_from(path)
	assert_eq(q.bosses_defeated, ["bone_lich"])
	assert_eq(q.anointed, {"oath_dawn": "ward_titanic_rage"})
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	assert_eq(p.reset_perks(_data, "oath_dawn"), 2)
	assert_true(not p.anointed.has("oath_dawn"), "återställningen tar också lånet")


## 0.26: talen delades med 10. En mycket svag träff kan avrundas till 0, men den räknas ändå som en träff (förut gav
## golvet på 1 alltid minst 1), så att Domens kall slår tillbaka som förut. En träff som Barriären tog räknas inte.
func test_a_weak_hit_that_rounds_to_zero_still_counts_as_a_hit() -> void:
	assert_eq(float(_data.heroes.paladin.stats.health), 90.0, "Paladinen börjar med 90 liv")
	assert_eq(float(_data.heroes.brokk.stats.health), 115.0)
	var sim := _sim(["oath_vengeance"])
	_no_luck(sim)
	var alva := sim.unit("alva")
	var archer := sim.unit("skeleton_archer_1")
	sim.drain_events()
	sim._deal_damage(archer, alva, 0.3, "physical", "bone_arrow", false, true, "pure")
	var events := sim.drain_events()
	var hit: Array = _by(events, "bone_arrow")
	assert_eq(hit[0].amount, 0.0, "0,3 avrundas till 0")
	assert_true(hit[0].landed, "men räknas som en träff")
	assert_eq(_by(events, "oath_vengeance").size(), 1, "Domens kall slår tillbaka")
	assert_eq(alva.hp, alva.max_hp, "och inget liv försvann")
	var sim2 := _sim(["oath_vengeance"])
	_no_luck(sim2)
	sim2._add_barrier(sim2.unit("alva"), sim2.unit("alva"), 5.0)
	sim2.drain_events()
	sim2._deal_damage(sim2.unit("skeleton_archer_1"), sim2.unit("alva"), 3.0, "physical", "bone_arrow", false, true, "pure")
	assert_eq(_by(sim2.drain_events(), "oath_vengeance").size(), 0, "Barriären tog träffen: ingenting slår till")
