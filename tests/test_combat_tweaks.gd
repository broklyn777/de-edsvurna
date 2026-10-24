extends "res://tests/test_case.gd"
## Strid-justering: Helgedomens gåvor varar hela nästa strid, Bortbytingens Moderns famn, Häxans förbannelse förbi
## Provocera och Benfurstens Dödsdom även över 50 % liv.

var _data := GameData.load_all()


func _sim(encounter: String, opts := {}, seed_value := 3) -> CombatSim:
	return CombatSim.create(_data, encounter, seed_value, ["paladin", "brokk", "alva", "eira"], {}, {}, {}, 1, opts)


func _enemy(sim: CombatSim, kind: String) -> CombatUnit:
	for e in sim.enemies:
		if e.kind == kind:
			return e
	return null


## Den första träffen från src mot tgt (försöker igen om Smyget undvek den).
func _hit(sim: CombatSim, src: CombatUnit, tgt: CombatUnit, kind := "attack") -> Dictionary:
	var out := {"calc": {}, "guarded": []}
	for i in 40:
		sim.drain_events()
		sim._deal_damage(src, tgt, 1.0, "physical", "x", false, true, kind, true)
		for e in sim.drain_events():
			if e.type == "damage" and e.source == src.id and e.target == tgt.id:
				out.calc = e.calc
			if e.type == "guarded":
				out.guarded.append(e)
		if not out.calc.is_empty():
			return out
	return out


# --- 1. Helgedomens gåvor ---------------------------------------------------------

func test_shrine_gifts_last_the_whole_battle() -> void:
	var sim := _sim("crypt_1", {"start_auras": ["shrine_warded", "shrine_inspired"]})
	sim.begin()
	for i in 40:
		if sim.outcome != "":
			break
		if sim.needs_input():
			sim.act("attack", "", sim.current.attack_ability)
		else:
			sim.ai_act()
	var paladin := sim.unit("paladin")
	if paladin.alive:
		assert_true(paladin.auras.has("shrine_warded"), "Värnad finns kvar efter många turer")
		assert_true(paladin.auras.has("shrine_inspired"), "Styrka förbrukas inte av anfallen")


func test_shrine_gifts_change_the_numbers() -> void:
	var sim := _sim("crypt_1")
	var paladin := sim.unit("paladin")
	var foe: CombatUnit = sim.enemies[0]
	sim._add_aura(paladin, paladin, "shrine_inspired")
	var calc: Dictionary = _hit(sim, paladin, foe).calc
	var found := false
	for m in calc.get("mods", []):
		if m.name == "Styrka" and is_equal_approx(float(m.f), 1.15):
			found = true
	assert_true(found, "Styrka: +15 %% skada i uträkningen (%s)" % [calc.get("mods", [])])
	sim._add_aura(paladin, paladin, "shrine_warded")
	assert_true(paladin.damage_taken_factors().has(0.8), "Värnad: 20 % mindre skada")
	assert_true(_data.auras.shrine_warded.get("cannot_dispel", false), "går inte att skingra eller stjäla")


func test_shrine_offers_the_battle_long_auras() -> void:
	var s := RunState.new()
	s.charges = {"alva": {"healing_light": 3}}
	var rng := RandomNumberGenerator.new()
	var seen := {}
	for seed in 20:
		rng.seed = seed
		for o in s.shrine_options(_data, rng):
			if o.kind == "blessing":
				seen[o.aura] = true
				assert_true(s.shrine_detail(_data, o).ends_with("hela nästa strid"), s.shrine_detail(_data, o))
	assert_eq(seen.keys().size(), 2)
	assert_true(seen.has("shrine_warded") and seen.has("shrine_inspired"))
	assert_true(_data.auras[RunState.CHAOS_AURA].get("battle", false), "Pandemoniums sköld följer samma regel")


# --- 2. Moderns famn ---------------------------------------------------------------

func test_mothers_embrace_sends_half_to_the_bigger_troll() -> void:
	var sim := _sim("troll_1e")
	var changeling := _enemy(sim, "changeling_troll")
	var mother := _enemy(sim, "porridge_troll")
	assert_true(changeling.traits.has("mothers_embrace"))
	assert_true(mother.max_hp > changeling.max_hp)
	assert_eq(sim.shelter_keeper(changeling), mother, "Inspect visar vem som tar emot")
	var before := mother.hp
	var hit := _hit(sim, sim.unit("eira"), changeling)
	var calc: Dictionary = hit.calc
	var total := float(calc.total) + float(calc.guarded)
	assert_eq(float(calc.guarded), roundf(total * 0.5), "hälften av den färdiga skadan")
	assert_near(mother.hp, before - float(calc.guarded), 1e-9, "det större trollet tar sin del")
	assert_eq(hit.guarded.size(), 1)
	assert_eq(hit.guarded[0].shelter, "mothers_embrace", "händelsen säger att det var Moderns famn")
	assert_true(DamageExplain.lines(sim.data, {"type": "damage", "calc": calc, "kind": "attack"}).any(
			func(l: String) -> bool: return l.find("Moderns famn") >= 0), "skadeloggen visar det")
	assert_true(not _hit(sim, sim.unit("eira"), changeling, "spell").calc.has("guarded"), "förmågor träffar fullt")
	# Inte åt andra hållet, och inte när det större trollet har fallit.
	assert_true(not _hit(sim, sim.unit("eira"), mother).calc.has("guarded"), "trollet själv skickar inget")
	sim._kill(mother)
	assert_true(not _hit(sim, sim.unit("eira"), changeling).calc.has("guarded"), "ensam tar han allt")


func test_mothers_embrace_needs_a_bigger_troll() -> void:
	var sim := _sim("troll_1e")
	var changeling := _enemy(sim, "changeling_troll")
	var mother := _enemy(sim, "porridge_troll")
	mother.max_hp = changeling.max_hp
	assert_true(not _hit(sim, sim.unit("eira"), changeling).calc.has("guarded"), "lika stora: ingen famn")


# --- 3 och 4. Häxan och Benfursten -------------------------------------------------------

func test_witch_hex_ignores_taunt() -> void:
	assert_true(_data.abilities.witch_hex.get("ignore_taunt", false))


func test_lich_charges_doom_above_half_life() -> void:
	var sim := _sim("crypt_3")
	var lich := _enemy(sim, "bone_lich")
	lich.hp = lich.max_hp
	lich.cooldowns.clear()
	lich.cooldowns["bone_storm"] = 2.0
	lich.intent = {}
	sim._choose_intent(lich)
	assert_eq(lich.intent.ability, "lich_doom", "laddar Dödsdom när Benstormen vilar")
	assert_eq(int(lich.charging.max), 2, "två turer i förväg över 50 % liv")
	lich.charging = {}
	lich.intent = {}
	lich.cooldowns.clear()
	sim._choose_intent(lich)
	assert_eq(lich.intent.ability, "bone_storm", "Benstormen går först över 50 % liv")
	lich.charging = {}
	lich.intent = {}
	lich.hp = lich.max_hp * 0.4
	sim._choose_intent(lich)
	assert_eq(lich.intent.ability, "lich_doom")
	assert_eq(int(lich.charging.max), 1, "under 50 %: en tur i förväg som förut")
