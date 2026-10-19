extends "res://tests/test_case.gd"
## Basen (0.12): silver och Smeden i profilen, Övningsgården, artefakter i striden och att
## Paladinens kall slutar verka medan hen är död.

const TMP_PROFILE := "user://test_profile_tmp.cfg"

var _data := GameData.load_all()


func _sim(artifacts := {}, encounter := "crypt_1") -> CombatSim:
	var sim := CombatSim.create(_data, encounter, 7, [], {}, {}, artifacts)
	sim.begin()
	sim.drain_events()
	return sim


## Sätter artefaktens chans till 100 % så att testet blir säkert.
func _always(sim: CombatSim, hero_id: String) -> void:
	sim.data.traits["artifact_" + hero_id].chance = 1.0


func _artifact_casts(events: Array[Dictionary], hero_id: String) -> Array[Dictionary]:
	return events.filter(func(e: Dictionary) -> bool:
		return e.type == "action" and e.action == "artifact" and e.unit == hero_id)


# --- Profilen: silver och Smeden ---------------------------------------------

func test_silver_for_won_battles() -> void:
	var p := Profile.new()
	assert_eq(p.silver, Profile.START_SILVER)
	assert_eq(p.win_battle(0), Profile.FLOOR_REWARD[0])
	p.win_battle(2)
	assert_eq(p.silver, Profile.START_SILVER + Profile.FLOOR_REWARD[0] + Profile.FLOOR_REWARD[2])


func test_forge_costs_silver() -> void:
	var p := Profile.new()
	p.silver = Profile.FORGE_COST + 10
	assert_eq(p.forge_cost("brokk", "shield", "healing_light"), Profile.FORGE_COST)
	assert_true(p.forge("brokk", "shield", "healing_light"))
	assert_eq(p.silver, 10)
	assert_eq([p.artifacts.brokk.type, p.artifacts.brokk.ability, p.artifacts.brokk.level], ["shield", "healing_light", 1])
	assert_eq(p.forge_cost("brokk", "shield", "healing_light"), 0, "samma artefakt kostar inget")
	assert_true(not p.forge("brokk", "shield", "healing_light"), "och smids inte om")
	assert_eq(p.forge_cost("brokk", "shield", "war_cry"), Profile.RESOCKET_COST, "byta förmåga är billigare")
	assert_eq(p.forge_cost("brokk", "helm", "war_cry"), Profile.FORGE_COST, "byta typ = smida nytt")
	p.silver = Profile.RESOCKET_COST - 1
	assert_true(not p.forge("brokk", "shield", "war_cry"), "för lite silver")
	assert_eq(p.artifacts.brokk.ability, "healing_light")


func test_profile_saves_and_loads() -> void:
	var p := Profile.new()
	p.silver = 123
	p.add_trophy("bone_rage")
	p.artifacts = {"eira": {"type": "boots", "ability": "arrow_rain"}}
	p.oath = "oath_ward"
	p.perks = {"oath_ward": ["ward_rest_up"]}
	p.recruited.assign(["brokk", "alva", "solveig"])
	p.party.assign(["paladin", "brokk", "alva", "solveig"])
	p.equip_practice("alva", "bone_rage")
	assert_eq(p.save(TMP_PROFILE), OK)
	var q := Profile.load_from(TMP_PROFILE)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP_PROFILE))
	assert_eq(q.silver, 123)
	assert_eq(q.collection, p.collection)
	assert_eq(q.artifacts, {"eira": Forge.normalize(p.artifacts.eira)}, "äldre artefakter blir nivå 1")
	assert_eq(q.oath, "oath_ward")
	assert_eq(q.owned_perks("oath_ward"), ["ward_rest_up"])
	assert_eq(q.party, p.party)
	assert_eq(q.practice_equipped, {"alva": "bone_rage"})
	assert_eq(Profile.load_from("user://finns_inte.cfg").silver, Profile.START_SILVER, "ny profil har startsilver")


# --- Övningsgården -----------------------------------------------------------

func test_practice_has_full_charges_trophies_and_artifacts() -> void:
	var p := Profile.new()
	p.recruited.assign(["imma", "brokk", "alva", "eira"])
	p.party.assign(["paladin", "brokk", "alva", "eira"])
	var trophy: String = _data.enemies.skeleton_warrior.trophy
	p.add_trophy(trophy)
	p.equip_practice("brokk", trophy)
	p.equip_practice("eira", "inte_i_samlingen")
	p.artifacts = {"brokk": {"type": "shield", "ability": "healing_light"}}
	var s := RunState.new_practice(p, _data, "crypt_3")
	assert_true(s.practice)
	assert_eq(s.encounter(), "crypt_3", "valfritt möte")
	assert_eq(s.equipped, {"brokk": trophy}, "bara troféer ur samlingen")
	assert_eq(s.artifacts, p.artifacts)
	assert_eq(s.charges.paladin.holy_smite, int(_data.abilities.holy_smite.charges), "fulla Charges")
	assert_true(s.hero_traits(_data).brokk.has(trophy))


# --- Artefakter i striden ----------------------------------------------------

func test_sword_casts_on_attack_without_charges() -> void:
	var sim := _sim({"paladin": {"type": "sword", "ability": "holy_smite"}})
	_always(sim, "paladin")
	var paladin := sim.unit("paladin")
	var before: int = paladin.charges.holy_smite
	sim._perform(paladin, paladin.attack_ability, "attack", "")
	var events := sim.drain_events()
	assert_eq(_artifact_casts(events, "paladin").size(), 1, "svärdet slår till vid Anfall")
	assert_eq(_artifact_casts(events, "paladin")[0].ability, "holy_smite")
	assert_eq(paladin.charges.holy_smite, before, "automatiska kast kostar inga Charges")
	var smite := events.filter(func(e: Dictionary) -> bool: return e.type == "damage" and e.ability == "holy_smite")
	assert_eq(smite.size(), 1, "förmågan gör skada")
	assert_eq(smite[0].get("trait", ""), "artifact_paladin", "och syns som en egenskapskedja")


func test_sword_ignores_other_actions() -> void:
	var sim := _sim({"paladin": {"type": "sword", "ability": "holy_smite"}})
	_always(sim, "paladin")
	var paladin := sim.unit("paladin")
	sim._perform(paladin, "defend", "defend", "")
	sim._perform(paladin, "holy_shield", "ability", "brokk")
	assert_eq(_artifact_casts(sim.drain_events(), "paladin").size(), 0)


func test_shield_heals_when_defending() -> void:
	var sim := _sim({"brokk": {"type": "shield", "ability": "healing_light"}})
	_always(sim, "brokk")
	var alva := sim.unit("alva")
	alva.hp = 100.0
	sim._perform(sim.unit("brokk"), "defend", "defend", "")
	var events := sim.drain_events()
	assert_eq(_artifact_casts(events, "brokk").size(), 1, "skölden slår till vid Försvara")
	assert_true(alva.hp > 100.0, "Helande ljus når den svagaste")


func test_helm_on_provoke_staff_on_ability() -> void:
	var sim := _sim({"brokk": {"type": "helm", "ability": "war_cry"},
			"alva": {"type": "staff", "ability": "judgement"}})
	_always(sim, "brokk")
	_always(sim, "alva")
	sim._perform(sim.unit("brokk"), "provoke", "provoke", "")
	assert_eq(_artifact_casts(sim.drain_events(), "brokk").size(), 1, "hjälmen slår till vid Provocera")
	sim._perform(sim.unit("alva"), "healing_light", "ability", "brokk")
	var events := sim.drain_events()
	assert_eq(_artifact_casts(events, "alva").size(), 1, "staven slår till vid Förmåga")
	sim._perform(sim.unit("alva"), "holy_bolt", "attack", "")
	assert_eq(_artifact_casts(sim.drain_events(), "alva").size(), 0, "men inte vid Anfall")


func test_boots_cast_at_turn_start() -> void:
	var sim := CombatSim.create(_data, "crypt_1", 7, [], {}, {}, {"eira": {"type": "boots", "ability": "arrow_rain"}})
	_always(sim, "eira")
	sim.begin()
	assert_eq(sim.current.id, "eira")
	assert_eq(_artifact_casts(sim.drain_events(), "eira").size(), 1, "stövlarna slår till i början av turen")


func test_artifact_stats() -> void:
	var plain := _sim()
	var sim := _sim({"paladin": {"type": "sword", "ability": ""}, "brokk": {"type": "helm", "ability": ""},
			"alva": {"type": "shield", "ability": ""}, "eira": {"type": "boots", "ability": ""}})
	var a: Dictionary = _data.artifacts
	assert_near(sim.unit("paladin").attack, plain.unit("paladin").attack * a.sword.stat_mult, 0.01, "svärd: Attack")
	assert_eq(sim.unit("brokk").max_hp, roundf(plain.unit("brokk").max_hp * a.helm.stat_mult), "hjälm: liv")
	assert_eq(sim.unit("brokk").hp, sim.unit("brokk").max_hp)
	assert_near(sim.unit("alva").defense, plain.unit("alva").defense + a.shield.stat_add, 0.001, "sköld: Defense")
	assert_eq(sim.unit("eira").speed, plain.unit("eira").speed + a.boots.stat_add, "stövlar: snabbhet")
	assert_true(sim.unit("eira").speed > plain.unit("eira").speed)
	assert_true(not sim.unit("paladin").traits.has("artifact_paladin"), "utan förmåga ingen egenskap")


func test_staff_boosts_healing() -> void:
	var plain := _sim()
	var sim := _sim({"alva": {"type": "staff", "ability": ""}})
	assert_near(sim.unit("alva").intelligence, plain.unit("alva").intelligence * _data.artifacts.staff.stat_mult, 0.01,
			"staven: Intelligence")
	var healed := []
	for s in [plain, sim]:
		s.rng.seed = 3
		healed.append(s._heal_amount(s.unit("alva"), {"type": "heal", "power": 1.0}))
	assert_near(healed[1], healed[0] * _data.artifacts.staff.stat_mult, 0.01, "helning följer Intelligence")


func test_artifacts_do_not_touch_shared_data() -> void:
	_sim({"brokk": {"type": "shield", "ability": "healing_light"}})
	assert_true(not _data.traits.has("artifact_brokk"), "egenskapen finns bara i stridens kopia")


func test_artifact_cast_counts_against_turn_limit() -> void:
	var sim := _sim({"brokk": {"type": "shield", "ability": "war_cry"}})
	_always(sim, "brokk")
	var brokk := sim.unit("brokk")
	for i in CombatSim.TURN_LIMIT + 2:
		sim._perform(brokk, "defend", "defend", "")
	assert_eq(_artifact_casts(sim.drain_events(), "brokk").size(), CombatSim.TURN_LIMIT, "Siralims gräns per tur")


func test_macro_condition_has_artifact() -> void:
	var sim := _sim({"brokk": {"type": "shield", "ability": "healing_light"}})
	var line := {"subject": "any_ally", "cond": "has_artifact", "value": "shield", "action": "defend"}
	assert_eq(MacroRunner.match_line(sim, sim.unit("paladin"), line), sim.unit("brokk"))
	line.cond = "lacks_artifact"
	assert_eq(MacroRunner.match_line(sim, sim.unit("paladin"), line), sim.unit("paladin"))
	assert_eq(MacroRunner.condition_name(_data, "has_artifact", "shield"), "bär sköld")


# --- Paladinens död ----------------------------------------------------------

func test_oath_stops_while_paladin_dead_and_returns_on_revive() -> void:
	var sim := _sim()
	var archer := sim.unit("skeleton_archer_1")
	var paladin := sim.unit("paladin")
	var vengeance := func() -> int:
		return sim.drain_events().filter(func(e: Dictionary) -> bool:
			return e.type == "damage" and e.ability == "oath_vengeance").size()
	sim._kill(paladin)
	sim.drain_events()
	sim._deal_damage(archer, sim.unit("alva"), 50.0, "physical", "bone_arrow", false, true)
	assert_eq(vengeance.call(), 0, "Kallet verkar inte medan Paladinen är död")
	sim._revive(paladin, 0.5)
	sim.turn_no += 1  # ny tur, så att "en gång per tur" inte spelar in
	sim._deal_damage(archer, sim.unit("alva"), 50.0, "physical", "bone_arrow", false, true)
	assert_eq(vengeance.call(), 1, "Kallet verkar igen när Paladinen väcks")


func test_party_oath_stops_while_paladin_dead() -> void:
	var sim := CombatSim.create(_data, "crypt_1", 7, [], {"paladin": ["oath_ward", "ward_war_machine"]})
	sim.begin()
	var paladin := sim.unit("paladin")
	var brokk := sim.unit("brokk")
	sim._add_aura(brokk, brokk, "provoke")
	assert_true(brokk.auras.has("defend"), "Krigsmaskin gäller hela sällskapet")
	brokk.auras.clear()
	sim._kill(paladin)
	sim._add_aura(brokk, brokk, "provoke")
	assert_true(not brokk.auras.has("defend"), "Kallet verkar inte medan Paladinen är död")
	sim._revive(paladin, 0.5)
	brokk.auras.clear()
	sim._add_aura(brokk, brokk, "provoke")
	assert_true(brokk.auras.has("defend"), "och verkar igen när hen väcks")


func test_dead_units_modifiers_stop() -> void:
	var sim := _sim()
	var solveig_like := sim.unit("paladin")
	sim.data = _data.duplicate()
	sim.data.traits = _data.traits.duplicate()
	sim.data.traits["test_double"] = {"name": "Dubbel", "trigger": "modify_damage", "modify": {"damage_mult": 2.0}}
	solveig_like.traits.append("test_double")
	assert_eq(sim._modify(solveig_like, "modify_damage", {}, "damage_mult", 1.0), 2.0)
	sim._kill(solveig_like)
	assert_eq(sim._modify(solveig_like, "modify_damage", {}, "damage_mult", 1.0), 1.0,
			"en död figurs egenskaper ändrar inga siffror (t.ex. brännskada som tickar efter döden)")
