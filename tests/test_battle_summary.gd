extends "res://tests/test_case.gd"
## 0.30: "Det här avgjorde striden" – sällskapets egenskaper och kombinationer, med var delen kommer ifrån.

var _data := GameData.load_all()


func test_only_the_party_counts_and_each_row_has_a_source() -> void:
	var sim := CombatSim.create(_data, "crypt_1", 7, ["paladin", "imma"])
	sim.trait_stats = {
		"oath_vengeance": {"unit": "paladin", "procs": 4, "damage": 30.0, "heal": 0.0},
		"rosary": {"unit": "imma", "procs": 2, "damage": 0.0, "heal": 12.0},
		"bone_wall": {"unit": sim.enemies[0].id, "procs": 9, "damage": 0.0, "heal": 0.0},
	}
	sim.combo_stats = {"holy_smite": {"unit": "paladin", "aura": "blind", "count": 2, "extra": 14.0}}
	var rows := BattleSummary.deciders(sim)
	assert_eq(rows.size(), 3, "fiendens egenskap räknas inte")
	assert_eq(BattleSummary.tag(_data, "oath_dawn_light"), "KALL", "kallets dolda hjälpegenskap hör till kallet")
	assert_eq(rows[0].tag, "KALL")
	assert_eq(rows[0].text, "30 skada · 4 gånger")
	var tags := rows.map(func(r: Dictionary) -> String: return r.tag)
	assert_true(tags.has("TROFÉ") and tags.has("KOMBINATION"))
	var combo: Dictionary = rows.filter(func(r: Dictionary) -> bool: return r.tag == "KOMBINATION")[0]
	assert_eq(combo.name, "Förblindad → Rättfärdigt slag")
	assert_eq(combo.text, "+14 skada · 2 gånger")


func test_a_combo_hit_is_counted_by_the_simulator() -> void:
	var sim := CombatSim.create(_data, "crypt_1", 7, ["paladin", "imma"])
	var e := sim.enemies[0]
	sim._add_aura(sim.unit("imma"), e, "blind")
	sim._deal_damage(sim.unit("paladin"), e, 1.6, "holy", "holy_smite", false, true, "attack", true)
	assert_eq(sim.combo_stats.holy_smite.count, 1)
	assert_true(sim.combo_stats.holy_smite.extra > 0.0, "bonusens del av skadan")


func test_the_oath_counts_once_under_the_paladin() -> void:
	var sim := CombatSim.create(_data, "crypt_1", 7, ["paladin", "imma"])
	sim.trait_stats = {
		"oath_dawn": {"unit": "imma", "procs": 8, "damage": 0.0, "heal": 0.0},
		"oath_dawn_light": {"unit": "paladin", "procs": 8, "damage": 0.0, "heal": 49.0},
	}
	var rows := BattleSummary.deciders(sim)
	assert_eq(rows.size(), 1)
	assert_eq(rows[0].who, sim.heroes[0].name)
	assert_eq(rows[0].text, "49 helning · 16 gånger")


## 0.30.16: troféer som kunde ta en trofés plats: inte den själv, de med samma roll först, och vem som bär dem.
func test_alternatives_prefer_same_role() -> void:
	var data := GameData.load_all()
	var owned := ["bone_finger"]
	var heal_id := ""
	var dmg_id := ""
	for id in data.traits:
		var t: Dictionary = data.traits[id]
		if not t.get("trophy", false) or id == "bone_finger":
			continue
		var r := BattleSummary.roles(t)
		if heal_id == "" and r.has("helning") and not r.has("skada"):
			heal_id = id
		if dmg_id == "" and r.has("skada") and not r.has("helning"):
			dmg_id = id
	owned.append(heal_id)
	owned.append(dmg_id)
	var alts := BattleSummary.alternatives(data, "bone_finger", owned, {"imma": dmg_id}, {"imma": "Imma"})
	assert_eq(alts.size(), 2, "alla utom den själv")
	assert_eq(alts[0].id, dmg_id, "samma roll (skada) först")
	assert_eq(alts[0].wearer, "Imma")
	assert_eq(alts[1].wearer, "")
