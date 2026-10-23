extends "res://tests/test_case.gd"
## 0.17: våningsregler och instabilitet, elitvarianter, bossräknaren och de nya troféerna.

var _data := GameData.load_all()


func _sim(rules: Array = [], encounter := "crypt_1", traits := {}, opts := {}) -> CombatSim:
	var o := {"rules": rules, "elite_chance": 0.0}
	o.merge(opts, true)
	var sim := CombatSim.create(_data, encounter, 7, [], traits, {}, {}, 1, o)
	sim.begin()
	sim.drain_events()
	return sim


func _hit(sim: CombatSim, src: CombatUnit, tgt: CombatUnit, kind := "attack") -> float:
	sim.rng.seed = 3
	var before := tgt.hp
	sim._deal_damage(src, tgt, 1.0, "physical", src.attack_ability, false, true, kind, true)
	return before - tgt.hp


# --- Instabilitet -------------------------------------------------------------

func test_instability_rolls_visible_and_hidden_rules() -> void:
	var rng := RandomNumberGenerator.new()
	for level in range(0, RunState.MAX_INSTABILITY + 1):
		for seed_value in 20:
			rng.seed = seed_value
			var r := RunState.roll_rules(_data, level, rng)
			assert_eq(r.visible.size(), level, "synliga på nivå %d" % level)
			assert_eq(r.hidden.size(), level, "dolda på nivå %d" % level)
			var all: Array = r.visible + r.hidden
			for id in all:
				assert_eq(all.count(id), 1, "ingen regel två gånger")
				assert_true(int(_data.floor_rules[id].get("min_instability", 0)) <= level, "%s kräver högre nivå" % id)
			for id in r.visible:
				assert_true(not _data.floor_rules[id].get("hidden_only", false), "%s får bara vara dold" % id)


func test_rules_give_more_silver_and_trophies() -> void:
	var s := RunState.new()
	assert_near(s.silver_mult(_data), 1.0)
	s.rules_visible = ["heavy_air"]
	s.rules_hidden = ["risen_dead"]
	assert_near(s.silver_mult(_data), 1.65)
	assert_true(RunState.trophy_chance(1, 2) > RunState.trophy_chance(1, 0))
	var p := Profile.new()
	assert_eq(p.win_battle(0, 1, 1.65), roundi(Profile.FLOOR_REWARD[0] * 1.65))
	assert_eq(s.known_rules(), ["heavy_air"], "den dolda är okänd tills den slår till")
	s.rules_revealed = ["risen_dead"]
	assert_eq(s.known_rules(), ["heavy_air", "risen_dead"])


func test_rule_event_comes_once() -> void:
	var sim := _sim(["heavy_air"])
	var paladin := sim.unit("paladin")
	_hit(sim, paladin, sim.unit("skeleton_archer_1"))
	_hit(sim, paladin, sim.unit("skeleton_archer_1"))
	var events := sim.drain_events().filter(func(e: Dictionary) -> bool: return e.type == "rule")
	assert_eq(events.size(), 1)
	assert_eq(sim.rules_triggered, ["heavy_air"])


# --- Varje regel ----------------------------------------------------------------

func test_risen_dead_revives_each_enemy_once() -> void:
	var sim := _sim(["risen_dead"])
	var w := sim.unit("skeleton_warrior_1")
	sim._kill(w)
	assert_true(w.alive, "vaknar")
	assert_near(w.hp, w.max_hp * CombatSim.RISEN_DEAD_HP, 1e-9)
	sim._kill(w)
	assert_true(not w.alive, "bara en gång")
	sim._kill(sim.unit("paladin"))
	assert_true(not sim.unit("paladin").alive, "gäller inte hjältarna")


func test_sealed_words_seals_used_abilities() -> void:
	var sim := _sim(["sealed_words"])
	var paladin := sim.unit("paladin")
	sim._perform(paladin, "holy_smite", "ability", "")
	assert_eq(sim.can_act(paladin, "ability", "holy_smite"), "sealed")
	assert_eq(sim.can_act(paladin, "ability", "holy_shield"), "", "andra förmågor går fortfarande")


func test_heavy_air_and_withered_grace() -> void:
	var sim := _sim(["heavy_air", "withered_grace"])
	var wraith_like := sim.unit("skeleton_archer_1")
	assert_eq(sim._dodge_for(sim.unit("brokk"), wraith_like, 0.1, {"kind": "attack"}), 0.0, "ingen undviker")
	var brokk := sim.unit("brokk")
	brokk.hp = 10.0
	sim._heal(sim.unit("alva"), brokk, 10.0, "healing_light")
	assert_eq(brokk.hp, 16.0, "helning −40 %")


func test_vigilant_guards_defend_after_their_turn() -> void:
	var defended := 0
	for seed_value in 40:
		var sim := _sim(["vigilant_guards"])
		sim.rng.seed = seed_value
		var w := sim.unit("skeleton_warrior_1")
		w.auras.erase("defend")
		sim.current = w
		sim._end_turn()
		defended += 1 if w.auras.has("defend") else 0
	assert_true(defended > 4 and defended < 24, "ungefär 30 %% försvarar sig (%d/40)" % defended)


func test_cursed_ground_and_fog_of_weakness() -> void:
	var sim := _sim(["cursed_ground", "fog_weakness"])
	for h in sim.heroes:
		assert_true(h.auras.has("weak"), "%s börjar Försvagad" % h.name)
	var brokk := sim.unit("brokk")
	var hp := brokk.hp
	brokk.defense = 0.0  # 0.26: 2 % av livet är litet, så Defense och Försvagad tar annars allt (inget golv på 1)
	sim._remove_aura(brokk, "weak", "test")
	sim._tick_turn_start(brokk)
	assert_true(brokk.hp < hp, "förbannad mark")


func test_mirror_bones_reflects_hero_damage() -> void:
	var sim := _sim(["mirror_bones"])
	var paladin := sim.unit("paladin")
	var hp := paladin.hp
	_hit(sim, paladin, sim.unit("skeleton_archer_1"))
	assert_true(paladin.hp < hp)
	sim.drain_events()
	_hit(sim, sim.unit("skeleton_archer_1"), sim.unit("brokk"))
	var reflected := sim.drain_events().filter(func(e: Dictionary) -> bool:
		return e.type == "damage" and e.ability == "mirror_bones")
	assert_eq(reflected.size(), 0, "fiendernas träffar studsar inte")


func test_no_guard_forbids_defend_and_provoke() -> void:
	var sim := _sim(["no_guard"], "crypt_2")
	var brokk := sim.unit("brokk")
	assert_eq(sim.can_act(brokk, "defend"), "forbidden")
	assert_eq(sim.can_act(brokk, "provoke"), "forbidden")
	var warden := sim.unit("grave_warden_1")
	warden.hp = 1.0
	sim.unit("ember_skeleton_1").hp = 1.0  # bara för att någon allierad ska vara skadad
	sim._choose_intent(warden)
	assert_true(warden.intent.ability != "warden_provoke", "fiender provocerar inte heller")


func test_chaos_wind_swaps_attack_and_defense() -> void:
	var sim := _sim(["chaos_wind"])
	var brokk := sim.unit("brokk")
	assert_eq(brokk.attack, float(_data.heroes.brokk.stats.defense))
	assert_eq(brokk.defense, float(_data.heroes.brokk.stats.attack))


## 0.30.16: Kaosvinden lägger sig när hjälten börjar sin fjärde tur, så att striden inte kan bli evig.
func test_chaos_wind_calms_after_three_turns() -> void:
	var sim := _sim(["chaos_wind"])
	sim.begin()
	var calmed := false
	for i in 400:
		if sim.outcome != "":
			break
		if sim.needs_input():
			sim.act("attack", sim.default_target(sim.current, "attack"))
		else:
			sim.ai_act()
		for e in sim.drain_events():
			if e.type == "chaos_calm" and e.unit == "brokk":
				calmed = true
		if calmed:
			break
	var brokk := sim.unit("brokk")
	assert_true(calmed, "Kaosvinden lade sig för Brokk")
	assert_true(brokk.turns_taken == CombatSim.CHAOS_WIND_TURNS + 1)
	assert_eq(brokk.attack, float(_data.heroes.brokk.stats.attack))
	assert_eq(brokk.defense, float(_data.heroes.brokk.stats.defense))


# --- Elitvarianter och troféjakt ----------------------------------------------------

func test_elite_chance_grows_with_depth_and_instability() -> void:
	assert_near(CombatSim.elite_chance(1, 0), CombatSim.ELITE_CHANCE)
	assert_true(CombatSim.elite_chance(3, 0) > CombatSim.elite_chance(1, 0))
	assert_true(CombatSim.elite_chance(1, 2) > CombatSim.elite_chance(3, 0))
	assert_near(CombatSim.elite_chance(30, 3), CombatSim.ELITE_MAX)
	var rate := 0
	var total := 0
	for seed_value in range(1, 201):
		var sim := CombatSim.create(_data, "crypt_1", seed_value)
		for e in sim.enemies:
			total += 1
			rate += 1 if e.elite else 0
	assert_true(rate > 0 and float(rate) / total < 0.15, "ungefär 5 %% elit (fick %d/%d)" % [rate, total])


func test_elites_are_stronger_and_carry_their_trait() -> void:
	var sim := _sim([], "crypt_3", {}, {"elite_chance": 1.0})
	var w := sim.unit("skeleton_warrior_1")
	assert_true(w.elite)
	assert_eq(w.name, _data.enemies.skeleton_warrior.elite.name)
	assert_eq(w.max_hp, CombatSim.snap_stat(CombatSim.snap_stat(_data.enemies.skeleton_warrior.stats.health * float(_data.encounters.crypt_3.stat_mult))
			* CombatSim.ELITE_HEALTH))
	assert_true(w.traits.has("first_strike"))
	assert_true(not sim.unit("bone_lich_1").elite, "bossar blir aldrig elit")
	var plain := _sim([], "crypt_3")
	assert_eq(plain.enemies.filter(func(e: CombatUnit) -> bool: return e.elite).size(), 0)


func test_elite_trophy_is_offered_and_boss_trophy_needs_three_wins() -> void:
	var s := RunState.new()
	s.floor = 2
	var rng := RandomNumberGenerator.new()
	var offer := s.trophy_offer(_data, rng, ["skeleton_warrior"])
	assert_eq(offer[0], "first_strike", "elittrofén först och säkert")
	assert_true(not offer.has("lich_crown"), "bosstrofén är låst")
	s.depth = 10
	assert_true(s.trophy_offer(_data, rng, [], ["bone_lich"]).has("lich_crown"))
	var p := Profile.new()
	for i in RunState.BOSS_WINS_FOR_TROPHY - 1:
		p.defeat_boss("bone_lich")
	assert_eq(p.unlocked_boss_trophies(), [])
	p.defeat_boss("bone_lich")
	assert_eq(p.unlocked_boss_trophies(), ["bone_lich"])
	var path := "user://test_progress_boss.cfg"
	p.save(path)
	assert_eq(int(Profile.load_from(path).boss_wins.bone_lich), 3)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func test_every_elite_has_a_rule_breaking_trophy() -> void:
	var n := 0
	for kind in _data.enemies:
		var elite: Dictionary = _data.enemies[kind].get("elite", {})
		if elite.is_empty():
			continue
		n += 1
		var t: Dictionary = _data.traits[elite.trophy]
		assert_true(t.get("trophy", false) and t.rarity == "elite", "%s är en elittrofé" % elite.trophy)
		assert_true(elite.has("tint") and elite.has("glow"), "%s syns" % kind)
	assert_true(n >= 8, "minst åtta elitvarianter")


# --- De nya troféerna ----------------------------------------------------------------

func test_first_strike_only_on_first_attack() -> void:
	var sim := _sim([], "crypt_1", {"brokk": ["brokk_bulwark", "first_strike"]})
	var brokk := sim.unit("brokk")
	var archer := sim.unit("skeleton_archer_1")
	var first := _hit(sim, brokk, archer)
	archer.hp = archer.max_hp
	brokk.attacks_done = 1
	var second := _hit(sim, brokk, archer)
	assert_near(first, roundf(second * 3.0), 2.0, "+200 % på första anfallet")


func test_surprise_starts_first() -> void:
	var sim := CombatSim.create(_data, "crypt_1", 7, [], {"brokk": ["brokk_bulwark", "surprise"]}, {}, {}, 1,
			{"elite_chance": 0.0})
	sim.begin()
	assert_eq(sim.turn_no, 1)
	assert_eq(sim.current.id, "brokk", "Brokk (Speed 7) börjar överst")


func test_heart_of_chaos_revives_after_an_ability() -> void:
	var sim := _sim([], "crypt_1", {"paladin": ["oath_vengeance", "heart_of_chaos"]})
	var paladin := sim.unit("paladin")
	sim._kill(paladin)
	assert_true(not paladin.alive, "utan förmåga ingen återkomst")
	sim = _sim([], "crypt_1", {"paladin": ["oath_vengeance", "heart_of_chaos"]})
	paladin = sim.unit("paladin")
	sim._perform(paladin, "holy_shield", "ability", "paladin")
	sim._kill(paladin)
	assert_true(paladin.alive)
	assert_eq(paladin.hp, roundf(paladin.max_hp * 0.5))


func test_scatter_shot_hits_the_other_enemies() -> void:
	var sim := _sim([], "crypt_1", {"eira": ["eira_followup", "scatter_shot"]})
	var hp := sim.unit("skeleton_warrior_1").hp
	_hit(sim, sim.unit("eira"), sim.unit("skeleton_archer_1"))
	assert_true(sim.unit("skeleton_warrior_1").hp < hp, "de andra fienderna träffas")


func test_phantasm_grows_with_uses() -> void:
	var sim := _sim([], "crypt_1", {"alva": ["alva_blessing", "phantasm"]})
	var alva := sim.unit("alva")
	var probe := {"source": "alva", "target": "skeleton_archer_1", "ability": "judgement", "direct": true, "kind": "spell"}
	alva.ability_uses["judgement"] = 2
	var factors := []
	for m in sim._modifiers(alva, "modify_damage", probe):
		if m.has("damage_mult_per_use"):
			factors.append(1.0 + m.damage_mult_per_use * alva.ability_uses.judgement)
	assert_eq(factors, [1.4])
