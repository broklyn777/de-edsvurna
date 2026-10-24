extends "res://tests/test_case.gd"
## Fiendernas roller (docs/provspel/provocera-matning.md, docs/plan/trollens-realm.md "Roller"): varje vanlig grupp blandar
## roller så att spelaren måste välja vem som provoceras och vem som fälls först. Bortbytingen är Trollbergets snabba och
## sköra troll, Grytmodern helar.

const ROLES := ["snabb", "pansar", "slagare", "helare", "förbi"]
const ARMOR_TRAITS := ["bone_armor", "bone_wall", "mirror_ward", "overseer_guard", "rattle"]
## Grupper som medvetet har en roll (en fråga i sig): två pansar som vill ha förmågor.
const ONE_ROLE_OK := ["crypt_3d"]

var _data := GameData.load_all()


## Rollerna ur datan, samma grova regel som mätningen: snabb (Speed ≥ 12, Health ≤ 60), pansar (Defense ≥ 3 eller en
## pansaregenskap), slagare (Attack ≥ 16), helare (helar, väcker eller skyddar en allierad), förbi (en skadande förmåga
## som går förbi Provocera eller träffar alla).
func roles(kind: String) -> Array:
	var e: Dictionary = _data.enemies[kind]
	var s: Dictionary = e.stats
	var out := []
	if float(s.speed) >= 12.0 and float(s.health) <= 60.0:
		out.append("snabb")
	if float(s.defense) >= 3.0 or e.traits.any(func(t: String) -> bool: return ARMOR_TRAITS.has(t)):
		out.append("pansar")
	if float(s.attack) >= 16.0:
		out.append("slagare")
	var abilities: Array = [e.attack_ability]
	for r in e.get("rules", []):
		abilities.append(r.ability)
	for a in abilities:
		var ab: Dictionary = _data.abilities[a]
		for f in ab.get("effects", []):
			if f.type in ["heal", "revive", "barrier"] and ab.get("target", "") in ["ally", "all_allies", "dead_ally"]:
				out.append("helare")
			if f.type == "damage" and (ab.get("ignore_taunt", false) or ab.get("target", "") == "all_enemies"):
				out.append("förbi")
	for t in e.traits:
		for f in _data.traits[t].get("effects", []):
			if f.type in ["heal", "barrier", "revive"] and f.get("target", "") in ["weakest_ally", "allies", "dead_ally"]:
				out.append("helare")
	return out


## Fiendens viktigaste roll (den första i ROLES som den har).
func primary(kind: String) -> String:
	var r := roles(kind)
	for p in ROLES:
		if r.has(p):
			return p
	return "-"


func _common_groups(realm_id: String) -> Array:
	var r: Dictionary = _data.realms[realm_id]
	var out := []
	for pool in r.pools:
		for enc_id in pool:
			if not out.has(enc_id):
				out.append(enc_id)
	out.append(r.floors[0])
	out.append(r.floors[1])
	return out


## Trollberget: varje vanlig grupp har troll med minst två olika huvudroller (förr var alla troll samma kropp).
func test_every_mountain_group_mixes_main_roles() -> void:
	for enc_id in _common_groups("mountain"):
		var kinds := {}
		for kind in _data.encounters[enc_id].enemies:
			kinds[primary(kind)] = true
		assert_true(kinds.size() >= 2, "%s: minst två huvudroller (%s)" % [enc_id, ", ".join(kinds.keys())])


## Kryptan och kapellet: gruppen som helhet har minst två roller (en fiende kan bära två).
func test_every_crypt_and_chapel_group_has_two_roles() -> void:
	for realm_id in ["crypt", "chapel"]:
		for enc_id in _common_groups(realm_id):
			if ONE_ROLE_OK.has(enc_id):
				continue
			var got := {}
			for kind in _data.encounters[enc_id].enemies:
				for r in roles(kind):
					got[r] = true
			assert_true(got.size() >= 2, "%s: minst två roller (%s)" % [enc_id, ", ".join(got.keys())])


func test_the_trolls_cover_all_five_roles() -> void:
	var got := {}
	for kind in ["moss_troll", "porridge_troll", "grumpy_troll", "club_troll", "changeling_troll"]:
		got[primary(kind)] = true
	for role in ROLES:
		assert_true(got.has(role), "något troll är %s" % role)
	assert_eq(primary("club_troll"), "slagare", "Stenkrossaren slår hårt")
	assert_eq(primary("moss_troll"), "pansar", "Mossrygg är pansar")
	assert_eq(primary("porridge_troll"), "helare", "Grytmodern helar")
	assert_eq(primary("changeling_troll"), "snabb", "Bortbytingen är snabb och skör")


func test_mountain_groups_with_the_changeling() -> void:
	var with_him := 0
	for enc_id in _common_groups("mountain"):
		if _data.encounters[enc_id].enemies.has("changeling_troll"):
			with_him += 1
	assert_true(with_him >= 5, "Bortbytingen finns i flera grupper (%d)" % with_him)
	assert_true(_data.encounters.troll_e3.enemies.has("changeling_troll"), "Vaggan: Gråluva och bytingen")


func _sim(encounter: String, traits := {}) -> CombatSim:
	var sim := CombatSim.create(_data, encounter, 3, ["paladin", "brokk", "alva", "eira"], traits, {}, {}, 1, {"elite_chance": 0.0})
	sim.begin()
	sim.drain_events()
	return sim


func _enemy(sim: CombatSim, kind: String) -> CombatUnit:
	for e in sim.enemies:
		if e.kind == kind:
			return e
	return null


func test_changeling_claws_past_provoke_at_the_weakest() -> void:
	var sim := _sim("troll_1a")
	var byting := _enemy(sim, "changeling_troll")
	var moss := _enemy(sim, "moss_troll")
	var alva := sim.unit("alva")
	var brokk := sim.unit("brokk")
	alva.hp = alva.max_hp * 0.3
	sim._add_aura(brokk, brokk, "provoke")
	assert_eq(sim._pick_targets(moss, sim.ability(moss.attack_ability)), [brokk.id], "Mossrygg slår den som provocerar")
	assert_eq(sim._pick_targets(byting, sim.ability(byting.attack_ability)), [alva.id], "bytingen går förbi till den svagaste")
	assert_true(byting.speed > moss.speed and byting.max_hp < moss.max_hp * 0.6, "snabb och skör")
	assert_eq(byting.family, "troll_kin")
	assert_true(byting.traits.has("troll_hide"), "Trollhud")


func test_changeling_wail_can_scorn_the_heroes() -> void:
	var sim := _sim("troll_1a")
	var byting := _enemy(sim, "changeling_troll")
	var scorned := 0
	for i in 40:
		for h in sim.heroes:
			h.auras.erase("scorned")
		sim._apply_effects(byting, "changeling_wail", sim._pick_targets(byting, sim.ability("changeling_wail")))
		for h in sim.heroes:
			scorned += 1 if h.auras.has("scorned") else 0
	assert_true(scorned > 10 and scorned < 90, "ungefär 30 procent (%d av 160)" % scorned)


func test_grytmodern_feeds_the_weakest_troll_unless_scorched() -> void:
	var sim := _sim("troll_1b")
	var mother := _enemy(sim, "porridge_troll")
	var moss := _enemy(sim, "moss_troll")
	moss.hp = moss.max_hp * 0.4
	var targets := sim._pick_targets(mother, sim.ability("porridge_feed"))
	assert_eq(targets, [moss.id], "gröten går till trollet med lägst liv")
	var before := moss.hp
	sim._apply_effects(mother, "porridge_feed", targets)
	assert_true(moss.hp > before, "Mossrygg äter")
	sim._add_aura(moss, moss, "troll_scorched")
	before = moss.hp
	sim._apply_effects(mother, "porridge_feed", targets)
	assert_eq(moss.hp, before, "Svedd hud: gröten hjälper inte")


func test_cradle_steel_strikes_back_for_the_weak() -> void:
	var sim := _sim("troll_1a", {"brokk": ["cradle_steel"]})
	var byting := _enemy(sim, "changeling_troll")
	var alva := sim.unit("alva")
	var hits := func() -> int:
		return sim.drain_events().filter(func(e: Dictionary) -> bool:
			return e.type in ["damage", "dodge"] and e.source == "brokk" and e.get("ability", "") == "cradle_steel").size()
	sim.drain_events()
	sim._deal_damage(byting, alva, 1.0, "physical", "changeling_claw", false, true, "attack", true)
	assert_eq(hits.call(), 0, "Alva har mer än halva livet")
	alva.hp = alva.max_hp * 0.3
	sim.turn_no += 1
	sim._deal_damage(byting, alva, 1.0, "physical", "changeling_claw", false, true, "attack", true)
	assert_eq(hits.call(), 1, "stålet slår tillbaka för den svaga")
	assert_true(_data.traits.cradle_steel.get("trophy", false))
	assert_eq(_data.enemies.changeling_troll.trophy, "cradle_steel")
