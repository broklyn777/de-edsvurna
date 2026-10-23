extends "res://tests/test_case.gd"
## Uppställningen i striden (bara utseende): högst Defense närmast fienderna, lika behåller ordningen.

var _data := GameData.load_all()


func test_highest_defense_stands_in_front() -> void:
	var sim := CombatSim.create(_data, "crypt_1", 7, ["paladin", "imma", "alva", "brokk"])
	var spots := UnitModel.formation(sim.heroes)
	var by_def := sim.heroes.duplicate()
	by_def.sort_custom(func(a: CombatUnit, b: CombatUnit) -> bool: return a.defense_now() > b.defense_now())
	assert_eq(by_def[0].id, "brokk", "Brokk har högst Defense")
	for i in by_def.size() - 1:
		assert_true(spots[by_def[i].id].x >= spots[by_def[i + 1].id].x - 20.0,
				"%s står inte bakom %s" % [by_def[i].id, by_def[i + 1].id])
	assert_eq(spots["brokk"], CombatSim.HERO_SLOTS[0] + UnitModel.PARTY_LIFT)


func test_formation_is_visual_only_and_ties_keep_order() -> void:
	var sim := CombatSim.create(_data, "crypt_1", 7, ["paladin", "imma", "alva"])
	var before := sim.heroes.map(func(u: CombatUnit) -> Vector2: return u.position)
	for u in sim.heroes:
		u.defense = 3.0
		u.base_stats.defense = 3.0
	var spots := UnitModel.formation(sim.heroes)
	for i in sim.heroes.size():
		assert_eq(spots[sim.heroes[i].id], CombatSim.HERO_SLOTS[i] + UnitModel.PARTY_LIFT, "lika Defense: samma ordning")
		assert_eq(sim.heroes[i].position, before[i], "stridens positioner rörs inte")
