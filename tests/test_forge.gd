extends "res://tests/test_case.gd"
## 0.20: artefaktnivåer, platser, material, uttag, Nether Stones och fynd per djup.

var _data := GameData.load_all()


func _profile() -> Profile:
	var p := Profile.new()
	p.silver = 10000
	p.forge("brokk", "shield", "healing_light")
	return p


func test_slots_open_in_the_original_order() -> void:
	var opened := []
	for l in range(1, Forge.LEVEL_MAX + 1):
		if Forge.unlock_text(l) != "":
			opened.append([l, Forge.unlock_text(l)])
	assert_eq(opened, [[2, "Stat-plats 1"], [3, "Trick-plats 1"], [5, "Stat-plats 2"], [7, "Trick-plats 2"],
			[9, "Stat-plats 3"], [10, "Nether-plats"]])
	assert_eq(Forge.next_unlock(3), 5)
	assert_eq(Forge.next_unlock(10), 0)
	assert_true(not Forge.stat_slot_open(1, 0) and Forge.stat_slot_open(2, 0) and not Forge.stat_slot_open(4, 1))


func test_old_artifacts_become_level_one() -> void:
	var a := Forge.normalize({"type": "sword", "ability": "holy_smite"})
	assert_eq(a.level, 1)
	assert_eq(a.stat_slots, ["", "", ""])
	assert_eq(a.trick_slots, ["", ""])
	assert_eq(a.nether, {})


func test_leveling_costs_silver_and_reports_what_opens() -> void:
	var p := _profile()
	var silver := p.silver
	assert_eq(p.level_artifact("brokk"), "Stat-plats 1")
	assert_eq(p.silver, silver - Forge.LEVEL_COST[1])
	assert_eq(p.level_artifact("brokk"), "Trick-plats 1")
	assert_eq(p.level_artifact("brokk"), "", "nivå 4 stärker bara")
	p.silver = 0
	assert_eq(p.level_artifact("brokk"), null, "för lite silver")
	assert_eq(p.level_artifact("alva"), null, "ingen artefakt")


func test_amber_costs_five_and_is_destroyed_when_taken_out() -> void:
	var p := _profile()
	p.materials = {"amber_grey": 7, "amber_red": 5}
	assert_true(not p.socket("brokk", "stat", 0, "amber_grey"), "platsen är stängd på nivå 1")
	p.level_artifact("brokk")
	assert_true(p.socket("brokk", "stat", 0, "amber_grey"))
	assert_eq(p.materials.amber_grey, 2)
	assert_true(not p.socket("brokk", "stat", 0, "amber_grey"), "redan där")
	assert_true(p.socket("brokk", "stat", 0, "amber_red"), "byte förstör den gamla")
	assert_true(not p.materials.has("amber_red"))
	assert_eq(p.materials.amber_grey, 2, "den gamla kommer inte tillbaka")
	assert_true(p.socket("brokk", "stat", 0, ""), "uttag")
	assert_eq(p.artifact("brokk").stat_slots[0], "")


func test_stones_survive_being_swapped() -> void:
	var p := _profile()
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	p.stones = [Forge.roll_stone(_data, 1, 0, rng, 1), Forge.roll_stone(_data, 1, 0, rng, 2)]
	assert_true(not p.socket_stone("brokk", "n1"), "Nether-platsen öppnas på nivå 10")
	p.artifacts.brokk.level = 10
	assert_true(p.socket_stone("brokk", "n1"))
	assert_true(p.socket_stone("brokk", "n2"))
	assert_eq(p.stones.size(), 1)
	assert_eq(p.stones[0].id, "n1", "den gamla stenen ligger kvar i förrådet")
	assert_true(p.socket_stone("brokk", ""))
	assert_eq(p.stones.size(), 2)


func test_levels_strengthen_stats_and_the_breakdown_matches_combat() -> void:
	var art := {"type": "helm", "ability": "", "level": 9, "stat_slots": ["amber_green", "amber_orange", "amber_red"],
			"trick_slots": ["whetstone", ""], "nether": {"id": "n1", "rarity": "magic", "number": 180,
			"affixes": [{"kind": "stat", "stat": "attack", "pct": 0.1, "q": 1.2}]}}
	var levels := {"paladin": {"level": 4, "personality": "modig"}}
	var sim := CombatSim.create(_data, "crypt_1", 1, [], {}, {}, {"paladin": art}, 1, {"levels": levels})
	var pal := sim.unit("paladin")
	var b := HeroStats.breakdown(_data, "paladin", 4, "modig", art)
	assert_eq(b.health.total, pal.max_hp)
	assert_near(b.attack.total, pal.attack, 0.001)
	assert_true(b.health.material > 0.0 and b.attack.material > 0.0 and b.attack.nether > 0.0)
	var low := HeroStats.breakdown(_data, "paladin", 4, "modig", {"type": "helm", "ability": ""})
	assert_true(b.health.artifact > low.health.artifact, "nivå 9 stärker typens stat")
	assert_true(pal.traits.has("artifact_paladin_t0"), "Brynstenen ger en egenskap")


func test_tricks_change_the_numbers() -> void:
	var whet: Dictionary = Forge._trick_trait(_data, "whetstone", Forge.trick_value(_data, "whetstone", 1))
	assert_near(whet.modify.damage_mult, 1.12, 0.001)
	assert_near(Forge.trick_value(_data, "whetstone", 10), 0.12 * 1.9, 0.001, "nivå 10 = +90 %")
	var scrap: Dictionary = Forge._trick_trait(_data, "armor_scrap", 0.08)
	assert_near(scrap.modify.damage_taken_mult, 0.92, 0.001)
	assert_eq(Forge.trick_text(_data, "jagged_rock", 1), "8 % högre chans till kritiska anfall.")


func test_jagged_rock_raises_crits() -> void:
	var crits := [0, 0]
	for with_rock in [0, 1]:
		var art := {"type": "sword", "ability": "", "level": 10, "trick_slots": ["jagged_rock", "jagged_rock"] if with_rock else ["", ""]}
		for s in 30:
			var sim := CombatSim.create(_data, "crypt_1", s, ["paladin", "brokk"], {}, {}, {"paladin": art})
			sim.begin()
			var turns := 0
			while sim.outcome == "" and turns < 200:
				if sim.needs_input():
					sim.act("attack", sim.enemies[0].id if sim.enemies[0].alive else "", "")
				else:
					sim.ai_act()
				turns += 1
				for e in sim.drain_events():
					if e.type == "damage" and e.source == "paladin" and e.crit:
						crits[with_rock] += 1
	assert_true(crits[1] > crits[0], "Taggsten ger fler krittar (%d mot %d)" % crits)


func test_finds_are_better_on_the_deepest_depth() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var counts := {true: {"trick": 0, "nether": 0, "amber": 0}, false: {"trick": 0, "nether": 0, "amber": 0}}
	for frontier in [true, false]:
		for i in 400:
			for f in Forge.roll_finds(_data, "treasure", 2, frontier, 0, rng, i):
				counts[frontier][f.kind] += int(f.get("count", 1))
	assert_eq(counts[false].trick, 0, "trick bara på det djupaste djupet")
	assert_eq(counts[false].nether, 0)
	assert_true(counts[true].trick > 100 and counts[true].nether > 20)
	assert_true(counts[false].amber > counts[true].amber, "lägre djup ger lite mer av det vanliga")


func test_stones_get_rarer_with_depth_and_instability() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var legendary := {}
	for key in [[1, 0], [5, 3]]:
		var n := 0
		for i in 600:
			var s := Forge.roll_stone(_data, key[0], key[1], rng, i)
			n += 1 if s.rarity in ["rare", "legendary"] else 0
			assert_eq(s.affixes.size(), int(Forge.rarity_of(_data, s).affixes))
			assert_eq(Forge.stone_lines(_data, s).size(), s.affixes.size())
		legendary[key[0]] = n
	assert_true(legendary[5] > legendary[1], "djup och instabilitet ger sällsyntare stenar")


func test_materials_and_stones_are_saved() -> void:
	var path := "user://test_progress_forge.cfg"
	var p := _profile()
	p.level_artifact("brokk")
	p.materials = {"amber_grey": 6, "whetstone": 1}
	p.socket("brokk", "stat", 0, "amber_grey")
	var rng := RandomNumberGenerator.new()
	p.add_finds([{"kind": "nether", "stone": Forge.roll_stone(_data, 2, 1, rng, 9)}])
	p.next_stone_id = 10
	p.save(path)
	var q := Profile.load_from(path)
	assert_eq(q.artifact("brokk").level, 2)
	assert_eq(q.artifact("brokk").stat_slots[0], "amber_grey")
	assert_eq(q.materials.amber_grey, 1)
	assert_eq(q.stones.size(), 1)
	assert_eq(q.next_stone_id, 10)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func test_changing_type_keeps_level_and_slots() -> void:
	var p := _profile()
	p.level_artifact("brokk")
	p.materials = {"amber_grey": 5}
	p.socket("brokk", "stat", 0, "amber_grey")
	assert_true(p.forge("brokk", "helm", "healing_light"))
	assert_eq(p.artifact("brokk").type, "helm")
	assert_eq(p.artifact("brokk").level, 2)
	assert_eq(p.artifact("brokk").stat_slots[0], "amber_grey")
