extends "res://tests/test_case.gd"
## Elitbalansen (grenen elit-balans): svaren på elitgrupperna – Skrivarens penna, Dimmans slöja, Klockrepet,
## Spegelskölden – och första nedstigningens egna elitstyrka.

var _data := GameData.load_all()


func _sim(encounter: String, traits := {}, opts := {}) -> CombatSim:
	return CombatSim.create(_data, encounter, 3, ["paladin", "brokk", "alva", "eira"], traits, {}, {}, 1, opts)


func _with(hero_id: String, trophy: String) -> Dictionary:
	return {hero_id: _data.heroes[hero_id].get("traits", []) + [trophy]}


func _enemy(sim: CombatSim, kind: String) -> CombatUnit:
	for e in sim.enemies:
		if e.kind == kind:
			return e
	return null


func _hero(sim: CombatSim, id: String) -> CombatUnit:
	for h in sim.heroes:
		if h.id == id:
			return h
	return null


## Faktorn med namnet i den första träffen från src mot tgt (1.0 om den saknas).
func _hit_factor(sim: CombatSim, src: CombatUnit, tgt: CombatUnit, name: String) -> float:
	for i in 40:
		sim.drain_events()
		sim._deal_damage(src, tgt, 1.0, "physical", "strike", false, true, "attack", true)
		for e in sim.drain_events():
			if e.type == "damage" and e.source == src.id and e.target == tgt.id:
				for m in e.calc.get("mods", []):
					if m.name == name:
						return float(m.f)
				return 1.0
	return 1.0


func test_scribe_quill_turns_off_noted_for_the_party() -> void:
	var name: String = _data.traits.noted.name
	var sim := _sim("crypt_e4")
	var scribe := _enemy(sim, "bone_scribe")
	var paladin := _hero(sim, "paladin")
	scribe.hit_log["paladin:strike"] = 2
	assert_near(_hit_factor(sim, paladin, scribe, name), 0.5, 0.001, "utan pennan: −50 % efter två träffar")
	sim = _sim("crypt_e4", _with("eira", "scribe_quill"))
	scribe = _enemy(sim, "bone_scribe")
	scribe.hit_log["paladin:strike"] = 2
	assert_near(_hit_factor(sim, _hero(sim, "paladin"), scribe, name), 1.0, 0.001, "pennan hos Eira gäller hela sällskapet")


func test_mist_veil_bearer_cannot_be_put_to_sleep() -> void:
	var sim := _sim("crypt_e3", _with("paladin", "mist_veil"))
	var mist := _enemy(sim, "grave_mist")
	sim._add_aura(mist, _hero(sim, "paladin"), "sleeping")
	sim._add_aura(mist, _hero(sim, "brokk"), "sleeping")
	assert_true(not _hero(sim, "paladin").auras.has("sleeping"), "bäraren somnar inte")
	assert_true(_hero(sim, "brokk").auras.has("sleeping"), "de andra somnar")


func test_bell_rope_follows_the_enemies_to_the_top() -> void:
	var sim := _sim("crypt_e5", _with("brokk", "bell_rope"))
	sim.begin()
	sim.drain_events()
	sim._emit({"type": "timeline_move", "unit": _enemy(sim, "bell_ringer").id, "dir": "top", "steps": 2})
	var moved := sim.drain_events().any(func(e: Dictionary) -> bool:
		return e.type == "timeline_move" and e.unit == "brokk" and e.dir == "top")
	assert_true(moved, "Brokk flyttas överst när en fiende gör det")


func test_mirror_shield_returns_sixty_percent_of_a_spell() -> void:
	var t: Dictionary = _data.traits.mirror_shield
	assert_near(float(t.effects[0].pct_of_event), 0.6)
	assert_true("60 %" in t.text, "texten säger vad den gör")


func test_first_descent_elite_uses_the_encounters_own_strength() -> void:
	for enc_id in ["crypt_e1", "chapel_e1"]:
		var enc: Dictionary = _data.encounters[enc_id]
		var bonus := 0.8
		var sim := CombatSim.create(_data, enc_id, 3, ["paladin", "imma"], {}, {}, {}, 1,
				{"stat_bonus": bonus, "first_descent_elite": bonus})
		var plain := CombatSim.create(_data, enc_id, 3, ["paladin", "imma"], {}, {}, {}, 1, {})
		var e := sim.enemies[0]
		var p := plain.enemies[0]
		assert_near(e.attack, CombatSim.snap_stat(p.attack / float(enc.stat_mult) * float(enc.first_descent_stat_mult)), 0.15,
				"%s: first_descent_stat_mult ersätter stat_mult" % enc_id)
