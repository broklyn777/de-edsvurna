extends "res://tests/test_case.gd"
## 0.16: Det fördärvade kapellet – nya debuffar (Tystad, Sårbar, Försvagad), fiendernas egenskaper,
## Den fallne biskopen, de nya troféerna och valet av Realm.

const Bot := preload("res://tests/combat_bot.gd")

var _data := GameData.load_all()


func _sim(encounter := "chapel_1", traits := {}) -> CombatSim:
	var sim := CombatSim.create(_data, encounter, 7, [], traits)
	sim.begin()
	sim.drain_events()
	return sim


## En direkt attack (power 1) utan krit, med samma slumpfrö varje gång.
func _hit(sim: CombatSim, src: CombatUnit, tgt: CombatUnit, kind := "attack") -> float:
	sim.rng.seed = 3
	var before := tgt.hp + tgt.barrier
	sim._deal_damage(src, tgt, 1.0, "physical", src.attack_ability, false, true, kind, true)
	return before - tgt.hp - tgt.barrier


func test_chapel_realm_has_three_floors_and_a_boss() -> void:
	var floors: Array = _data.realms.chapel.floors
	assert_eq(floors.size(), 3)
	var boss: Array = _data.encounters[floors[2]].enemies.filter(func(k: String) -> bool:
		return _data.enemies[k].get("boss", false))
	assert_eq(boss, ["fallen_bishop"])
	for kind in ["cultist", "wraith", "fallen_knight", "witch", "penitent", "fallen_bishop"]:
		var d: Dictionary = _data.enemies[kind]
		assert_true(not d.get("traits", []).is_empty(), "%s har en egenskap" % kind)
		assert_true(_data.traits.has(d.trophy) and _data.traits[d.trophy].get("trophy", false), "%s lämnar en trofé" % kind)
		assert_true(d.visual.has("model"), "%s har ett utseende" % kind)


func test_realm_choice_follows_into_the_run() -> void:
	var p := Profile.new()
	p.realm = "chapel"
	var s := RunState.new_run(p, _data)
	assert_eq(s.encounter(), "chapel_1")
	s.floor = 2
	assert_true(s.is_last_floor())
	var rng := RandomNumberGenerator.new()
	s.depth = 10
	for t in s.trophy_offer(_data, rng):
		var from_chapel := false
		# Påfyllnaden tar också Realmens vanliga fiender ur grupperna (mot upprepning).
		var chapel_encs: Array = _data.realms.chapel.floors.duplicate()
		for pool in RunState.pools_for(_data, "chapel", s.depth):
			chapel_encs.append_array(pool)
		for enc_id in chapel_encs:
			for kind in _data.encounters[enc_id].enemies:
				from_chapel = from_chapel or _data.enemies[kind].trophy == t
		assert_true(from_chapel, "%s kommer från kapellet" % t)
	var path := "user://test_progress_realm.cfg"
	p.save(path)
	assert_eq(Profile.load_from(path).realm, "chapel")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func test_silenced_heroes_cannot_use_abilities_and_macros_skip_the_line() -> void:
	var sim := _sim()
	var paladin := sim.unit("paladin")
	sim._add_aura(sim.unit("witch_1") if sim.unit("witch_1") else paladin, paladin, "silenced")
	assert_eq(sim.can_act(paladin, "ability", "holy_smite"), "silenced")
	assert_eq(sim.can_act(paladin, "attack"), "", "Anfall går fortfarande")
	var macro := {"lines": [
		{"subject": "any_enemy", "cond": "is_alive", "action": "ability", "ability": "holy_smite", "target": "that"},
		{"subject": "any_enemy", "cond": "is_alive", "action": "attack", "target": "that"}]}
	var d := MacroRunner.decide(sim, paladin, macro)
	assert_eq(d.action, "attack", "raden med förmågan hoppas över")
	assert_eq(d.line, 2)
	assert_true(d.skipped[0].contains("tystad"))
	var cond := {"subject": "self", "cond": "is_silenced", "action": "defend"}
	assert_true(MacroRunner.match_line(sim, paladin, cond) != null, "makrovillkoret är tystad")


func test_silenced_enemy_only_attacks() -> void:
	var sim := _sim("chapel_2")
	var witch := sim.unit("witch_1")
	sim._add_aura(sim.unit("alva"), witch, "silenced")
	sim._choose_intent(witch)
	assert_eq(witch.intent.ability, witch.attack_ability)


func test_vulnerable_and_weak() -> void:
	var sim := _sim()
	var penitent := sim.unit("penitent_1")
	var brokk := sim.unit("brokk")
	var plain := _hit(sim, penitent, brokk)
	brokk.hp = brokk.max_hp
	brokk.auras.erase("vulnerable")  # Bödelns märke satte den
	sim._add_aura(penitent, brokk, "vulnerable")
	assert_near(_hit(sim, penitent, brokk), roundf(plain * 1.5), 2.0, "Sårbar: +50 %")
	brokk.auras.erase("vulnerable")
	brokk.hp = brokk.max_hp
	sim._add_aura(penitent, penitent, "weak")
	assert_near(_hit(sim, penitent, brokk), roundf(plain * 0.5), 2.0, "Försvagad: −50 %")


func test_penitent_brands_its_target() -> void:
	var sim := _sim()
	_hit(sim, sim.unit("penitent_1"), sim.unit("alva"))
	assert_true(sim.unit("alva").auras.has("vulnerable"))


func test_wraith_dodges_attacks_but_not_spells() -> void:
	var sim := _sim()
	var wraith := sim.unit("wraith_1")
	var brokk := sim.unit("brokk")
	var probe := {"kind": "attack", "target": wraith.id}
	var ratio := brokk.speed / wraith.speed
	assert_near(sim._dodge_for(brokk, wraith, ratio, probe), CombatSim.dodge_chance(1.0 / ratio) + 0.4, 0.001)
	assert_near(sim._dodge_for(brokk, wraith, ratio, {"kind": "spell", "target": wraith.id}),
			CombatSim.dodge_chance(1.0 / ratio), 0.001, "Eterisk gäller bara attacker")


func test_fallen_knight_ripostes_while_defending() -> void:
	var sim := _sim("chapel_2")
	var knight := sim.unit("fallen_knight_1")
	var paladin := sim.unit("paladin")
	var hp := paladin.hp
	_hit(sim, paladin, knight)
	assert_eq(paladin.hp, hp, "ingen motstöt utan Försvara")
	sim._add_aura(knight, knight, "defend")
	_hit(sim, paladin, knight)
	assert_true(paladin.hp < hp, "motstöt när den försvarar sig")
	hp = paladin.hp
	_hit(sim, paladin, knight, "spell")
	assert_eq(paladin.hp, hp, "besvärjelser slipper")


func test_cultist_shields_the_weakest_ally() -> void:
	var sim := _sim()
	var cultist := sim.unit("cultist_1")
	var penitent := sim.unit("penitent_1")
	penitent.hp = 10.0
	sim._emit({"type": "turn_start", "unit": cultist.id})
	assert_eq(penitent.barrier, roundf(cultist.intelligence * 1.2))


func test_bishop_is_immune_while_a_cultist_lives() -> void:
	var sim := _sim("chapel_3")
	var bishop := sim.unit("fallen_bishop_1")
	var paladin := sim.unit("paladin")
	assert_true(bishop.resistant)
	assert_true(sim.is_immune(bishop))
	assert_eq(_hit(sim, paladin, bishop), 0.0, "Kultens sköld")
	assert_true(sim.drain_events().any(func(e: Dictionary) -> bool: return e.type == "immune"))
	var line := {"subject": "any_enemy", "cond": "not_immune", "action": "attack", "target": "that"}
	assert_eq(MacroRunner.match_line(sim, paladin, line).kind, "cultist", "makrot väljer någon som kan skadas")
	sim._kill(sim.unit("cultist_1"))
	assert_true(sim.is_immune(bishop), "en kultist lever fortfarande")
	sim._kill(sim.unit("cultist_2"))
	assert_true(not sim.is_immune(bishop))
	assert_true(_hit(sim, paladin, bishop) > 0.0)


func test_bishop_mitre_makes_bearer_immune_at_a_cost() -> void:
	var sim := _sim("chapel_1", {"brokk": ["brokk_bulwark", "bishop_mitre"]})
	var brokk := sim.unit("brokk")
	assert_true(sim.is_immune(brokk), "tre andra lever")
	sim._kill(sim.unit("alva"))
	sim._kill(sim.unit("eira"))
	assert_true(not sim.is_immune(brokk), "bara en annan lever")
	var probe := {"source": "paladin", "target": "penitent_1", "kind": "attack", "direct": true}
	assert_near(sim._modify(sim.unit("paladin"), "modify_damage", probe, "damage_mult", 1.0), 0.75, 0.001,
			"hela sällskapet gör 25 % mindre skada")


func test_witch_tongue_silences_enemies() -> void:
	var sim := _sim("chapel_2", {"alva": ["alva_blessing", "witch_tongue"]})
	sim.data = _data.duplicate()
	sim.data.traits = _data.traits.duplicate(true)
	sim.data.traits.witch_tongue.chance = 1.0
	var knight := sim.unit("fallen_knight_1")
	sim._deal_damage(sim.unit("alva"), knight, 1.0, "holy", "judgement", false, true, "spell", true)
	assert_true(sim.is_silenced(knight))


func test_chapel_can_be_won() -> void:
	var wins := 0
	for seed_value in range(1, 11):
		if Bot.run_fight(_data, seed_value, Bot.Skill.TUNED, "chapel_1").outcome == "victory":
			wins += 1
	assert_true(wins >= 5, "TUNED vinner kapellets första våning oftast (vann %d/10)" % wins)
