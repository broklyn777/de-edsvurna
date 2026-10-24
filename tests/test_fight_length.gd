extends "res://tests/test_case.gd"
## strid-langd (textspelet: Benskrivaren 55 turer, Kistornas råd 87): fiendernas helningar mattas och Kistbäraren
## försvarar sig först under 35 % liv. Antecknats tak (50 %) prövas i test_enemies_crypt.gd.

var _data := GameData.load_all()


func _sim(encounter: String) -> CombatSim:
	return CombatSim.create(_data, encounter, 3, ["paladin", "brokk", "alva", "eira"], {}, {}, {}, 1, {})


func _enemy(sim: CombatSim, kind: String) -> CombatUnit:
	for e in sim.enemies:
		if e.kind == kind:
			return e
	return null


func _heal_once(sim: CombatSim, src: CombatUnit, tgt: CombatUnit, base: float, ability: String) -> float:
	tgt.hp = 1.0
	sim.turn_no += 1  # en ny tur: samma helning i samma tur (Mässan på flera) räknas en gång
	sim.drain_events()
	sim._heal(src, tgt, base, ability)
	for e in sim.drain_events():
		if e.type == "heal":
			return float(e.amount)
	return -1.0


func test_enemy_heals_fade_per_repeat_down_to_the_floor() -> void:
	assert_near(CombatSim.heal_fade, 0.15, 1e-9)
	var sim := _sim("crypt_g2")
	var bearer := _enemy(sim, "coffin_bearer")
	var amounts := []
	for n in 6:
		amounts.append(_heal_once(sim, bearer, bearer, 100.0, "council_wake"))
	assert_eq(amounts, [100.0, 85.0, 70.0, 55.0, 40.0, 40.0], "15 % mindre per gång, minst 40 %")
	assert_near(_heal_once(sim, bearer, bearer, 100.0, "grave_mend"), 100.0, 1e-9, "en annan förmåga börjar om")


func test_one_cast_on_many_counts_once() -> void:
	var sim := _sim("crypt_g2")
	var a := _enemy(sim, "coffin_bearer")
	var b: CombatUnit = sim.enemies.filter(func(e: CombatUnit) -> bool: return e != a)[0]
	a.hp = 1.0
	b.hp = 1.0
	sim.drain_events()
	sim._heal(a, a, 100.0, "grave_mend")
	sim._heal(a, b, 100.0, "grave_mend")
	var amounts: Array = sim.drain_events().filter(func(e: Dictionary) -> bool: return e.type == "heal").map(
			func(e: Dictionary) -> float: return float(e.amount))
	assert_eq(amounts, [100.0, 100.0], "samma tur: ingen mattning mellan målen")


func test_hero_heals_do_not_fade() -> void:
	var sim := _sim("crypt_1")
	var alva := sim.unit("alva")
	for n in 4:
		assert_near(_heal_once(sim, alva, sim.unit("brokk"), 50.0, "healing_light"), 50.0, 1e-9)


func test_coffin_bearer_defends_only_below_35_percent() -> void:
	var rule: Dictionary = _data.enemies.coffin_bearer.rules[0]
	assert_eq(rule.ability, "defend")
	assert_near(float(rule["if"].self_hp_below), 0.35, 1e-9)
