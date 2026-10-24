extends "res://tests/test_case.gd"
## Gorms konkreta råd efter en förlust (LossTips) och helgedomens val som säger vad de gör (RunState.shrine_detail,
## aura_brief): reglerna, ordningen, siffrorna ur systemen och att inget råd ges när inget stämmer.

var _data := GameData.load_all()
const PARTY := ["paladin", "imma", "brokk", "alva"]


func _profile(silver := 0, level := 1) -> Profile:
	var p := Profile.new()
	p.intro_done = true
	for id in ["imma", "brokk", "alva"]:
		p.recruit(_data, id)
	p.set_party(["imma", "brokk", "alva"])
	for id in PARTY:
		p.hero(_data, id).level = level
	p.silver = silver
	return p


func _ctx(depth := 1, fl := 0, charges := {}, campfire := false, lost_to := "crypt_1") -> Dictionary:
	return {"party": PARTY, "depth": depth, "floor": fl, "charges": charges, "lost_to": lost_to, "campfire_left": campfire}


func _kinds(tips: Array) -> Array:
	return tips.map(func(t: Dictionary) -> String: return t.kind)


func test_no_tip_when_nothing_fits() -> void:
	assert_eq(LossTips.pick(_profile(), _data, _ctx()), [], "inget silver, inga material, nivån räcker, Charges kvar")


func test_empty_charges_name_hero_ability_and_campfire() -> void:
	var tips := LossTips.pick(_profile(), _data, _ctx(1, 2, {"alva": {"healing_light": 0, "renew": 2}}, true, "crypt_3"))
	assert_eq(_kinds(tips), ["charges"])
	var text := String(tips[0].text)
	assert_true(text.begins_with("Syster Alva hade 0 Charges kvar på Helande ljus"), text)
	assert_true(text.contains("lägereld kvar på våningen"), text)
	assert_true(text.contains("bossen"), "kryptans sista möte har en boss: " + text)
	assert_true(text.contains("+%d Charges" % RunState.CAMPFIRE_CHARGES), text)


func test_charges_only_for_party_and_abilities_with_charges() -> void:
	var tips := LossTips.pick(_profile(), _data, _ctx(1, 0, {"eira": {"healing_light": 0}}))
	assert_eq(tips, [], "Eira var inte med")
	var ctx := _ctx(1, 0, {"brokk": {"stone_wall": 0, "war_cry": 0}, "alva": {"healing_light": 0}})
	tips = LossTips.pick(_profile(), _data, ctx)
	assert_eq(String(tips[0].hero), "brokk", "den med flest tomma förmågor")
	assert_true(String(tips[0].text).contains(" och "), String(tips[0].text))


func test_lower_depth_when_party_lags_behind() -> void:
	var p := _profile(0, 4)
	var tips := LossTips.pick(p, _data, _ctx(3, 1))
	assert_eq(_kinds(tips), ["depth"])
	var foe := HeroStats.enemy_level(3, 1)
	var lower := HeroStats.enemy_level(2, 1)
	assert_true(foe - 4.0 >= LossTips.LEVEL_GAP)
	var text := String(tips[0].text)
	assert_true(text.begins_with("Gå tillbaka till djup 2"), text)
	assert_true(text.contains(HeroStats.shown(foe)) and text.contains(HeroStats.shown(lower)) and text.contains("snitt är 4"), text)
	# Jämnt med fienderna, eller på djup 1: inget sådant råd.
	assert_eq(LossTips.pick(_profile(0, 13), _data, _ctx(3, 1)), [])
	assert_eq(LossTips.pick(_profile(0, 1), _data, _ctx(1, 2)), [], "djup 1 har inget lägre djup")


func test_level_up_artifact_with_cost_and_silver() -> void:
	var p := _profile(500)
	p.forge("brokk", "shield", "stone_wall")
	p.silver = 120
	p.artifacts.brokk.level = 3
	var tips := LossTips.pick(p, _data, _ctx())
	assert_eq(_kinds(tips), ["level"])
	var cost := p.artifact_level_cost("brokk")
	assert_eq(cost, Forge.level_cost(3))
	assert_eq(String(tips[0].text), "Smid Brokks sköld till nivå 4 hos Hedda. Det kostar %d silver, ni har 120." % cost)
	p.silver = cost - 1
	assert_eq(LossTips.pick(p, _data, _ctx()), [], "silvret räcker inte")


func test_forge_when_someone_lacks_artifact() -> void:
	var p := _profile(Profile.FORGE_COST)
	var tips := LossTips.pick(p, _data, _ctx())
	assert_eq(_kinds(tips), ["forge"])
	assert_true(String(tips[0].text).contains("%d silver, ni har %d" % [Profile.FORGE_COST, Profile.FORGE_COST]))


func test_materials_need_an_open_empty_slot() -> void:
	var p := _profile(500)
	p.forge("brokk", "shield", "stone_wall")
	for id in ["imma", "alva", "paladin"]:
		p.forge(id, "sword", "")
	p.silver = 0
	p.materials = {"amber_red": 6, "whetstone": 1}
	assert_eq(LossTips.pick(p, _data, _ctx()), [], "nivå 1: ingen plats är öppen")
	p.artifacts.brokk.level = 2
	var tips := LossTips.pick(p, _data, _ctx())
	assert_eq(_kinds(tips), ["material"])
	assert_true(String(tips[0].text).begins_with("Ni har 7 material"), String(tips[0].text))
	p.artifacts.brokk.stat_slots = ["amber_red", "", ""]
	assert_eq(LossTips.pick(p, _data, _ctx()), [], "platsen är full och trickplatsen är inte öppen än")


func test_at_most_two_in_rule_order() -> void:
	var p := _profile(1000, 4)
	p.forge("brokk", "shield", "stone_wall")
	var tips := LossTips.pick(p, _data, _ctx(3, 1, {"alva": {"healing_light": 0}}))
	assert_eq(_kinds(tips), ["charges", "depth"])


func test_homecoming_after_loss_carries_tips() -> void:
	var p := _profile(0)
	Chronicle.simulate(p, _data, {"party": PARTY, "outcome": "loss", "charges": {"alva": {"healing_light": 0}}})
	var tips: Array = p.homecoming.get("tips", [])
	assert_eq(tips.size(), 1)
	assert_true(String(tips[0]).begins_with("Syster Alva"), str(tips))
	Chronicle.simulate(p, _data, {"party": PARTY, "outcome": "boss", "charges": {"alva": {"healing_light": 0}}})
	assert_true(not p.homecoming.has("tips"), "inga råd efter en seger")


func test_genitive() -> void:
	assert_eq(LossTips.genitive("Brokk"), "Brokks")
	assert_eq(LossTips.genitive("Jonas"), "Jonas")


# --- Helgedomens val ---------------------------------------------------------------

func test_aura_brief_from_data() -> void:
	assert_eq(RunState.aura_brief(_data, "warded", true), "tar 25 % mindre skada fram till egen första tur")
	assert_eq(RunState.aura_brief(_data, "inspired", true), "nästa direkta anfall gör 30 % mer skada under egen första tur")
	assert_eq(RunState.aura_brief(_data, "marked"), "tar 20 % mer skada, 3 turer")
	assert_eq(RunState.aura_brief(_data, "holy_shield", true, false), "tar 40 % mindre skada")
	# Helgedomens gåvor varar hela nästa strid (strid-justering).
	assert_eq(RunState.aura_brief(_data, "shrine_warded", true), "tar 20 % mindre skada hela nästa strid")
	assert_eq(RunState.aura_brief(_data, "shrine_inspired", true), "gör 15 % mer skada hela nästa strid")
	assert_eq(RunState.aura_brief(_data, "shrine_holy_shield", true, false), "tar 30 % mindre skada")
	assert_eq(RunState.aura_brief(_data, "shrine_warded"), "tar 20 % mindre skada hela striden")


func test_every_shrine_option_says_what_it_does() -> void:
	var s := RunState.new()
	s.charges = {"alva": {"healing_light": 3}}
	var rng := RandomNumberGenerator.new()
	for seed in 12:
		rng.seed = seed
		for o in s.shrine_options(_data, rng):
			var d := s.shrine_detail(_data, o)
			assert_true(d.length() > 8, "%s: %s" % [o.kind, d])
			if o.kind == "blessing":
				var text := String(_data.auras[o.aura].text)
				assert_true(d.begins_with(text.substr(text.find(": ") + 2, 6).to_lower()), d)
			elif o.kind == "charge":
				assert_eq(d, "3 av %d kvar blir 5" % int(_data.abilities.healing_light.charges))
			else:
				assert_true(d.contains(String(_data.auras[RunState.CHAOS_AURA].name)), d)
