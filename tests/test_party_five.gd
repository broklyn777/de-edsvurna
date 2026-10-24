extends "res://tests/test_case.gd"
## Prototyp (sallskap-fem): den femte platsen öppnas när huvudbossen är besegrad på djup 4 i både kryptan och kapellet.
## Kryptan och kapellet är balanserade mot fyra; Trollberget mot fem när profilen har öppnat den femte platsen.

var _data := GameData.load_all()


func _profile(owned: int) -> Profile:
	var p := Profile.new()
	for id in ["imma", "alva", "brokk", "eira", "solveig", "tove"].slice(0, owned - 1):
		p.recruit(_data, id)
	return p


const UNLOCKED := {"crypt": 4, "chapel": 4}


func test_four_slots_before_both_main_bosses_on_depth_four() -> void:
	var p := _profile(6)
	assert_eq(p.party_slots(), 4)
	assert_eq(p.max_companions(), 3)
	p.set_party(["imma", "alva", "brokk", "eira"])
	assert_eq(p.party.size(), 4, "Paladinen + 3")
	p.realm_depth = {"chapel": 1}
	assert_true(RunState.realm_open(p, _data, "mountain"), "Trollberget öppnas långt före")
	assert_eq(p.party_slots(), 4, "kapellet på djup 1 räcker inte")
	p.realm_depth = {"crypt": 6, "chapel": 3}
	assert_eq(p.party_slots(), 4, "kapellet bara på djup 3")
	p.realm_depth = {"crypt": 4, "chapel": 3, "mountain": 5}
	assert_eq(p.party_slots(), 4)
	p.realm_depth = UNLOCKED.duplicate()
	assert_eq(p.party_slots(), 5, "båda huvudbossarna på djup 4")
	p.set_party(["imma", "alva", "brokk", "eira", "solveig"])
	assert_eq(p.party.size(), 5, "Paladinen + 4")


func test_party_slots_survive_save_and_load() -> void:
	var p := _profile(6)
	p.realm_depth = UNLOCKED.duplicate()
	p.slots_seen = 5
	p.set_party(["imma", "alva", "brokk", "eira"])
	var path := "user://test_party_five.cfg"
	p.save(path)
	var q := Profile.load_from(path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	assert_eq(q.party_slots(), 5)
	assert_eq(q.slots_seen, 5)
	assert_eq(q.party.size(), 5)
	var s := RunState.new_run(q, _data)
	assert_eq(s.party_slots, 5)
	var back := RunState.from_dict(s.to_dict())
	assert_eq(back.party_slots, 5, "körningen sparar platserna")


func test_locked_slot_shows_from_four_owned_heroes() -> void:
	assert_eq(_profile(3).next_slot_lock(), "", "inget att längta efter med tre")
	var p := _profile(4)
	assert_eq(p.next_slot_lock(), "Besegra Benfursten och Den fallne biskopen på djup 4")
	p.realm_depth = UNLOCKED.duplicate()
	assert_eq(p.next_slot_lock(), "", "öppen: ingen låst plats (ingen sjätte än)")


func test_unlock_moment_once() -> void:
	var p := _profile(4)
	assert_eq(p.earned_slots(), 4)
	p.realm_depth = UNLOCKED.duplicate()
	assert_true(p.earned_slots() > p.slots_seen, "ögonblicket väntar")
	p.force_slots = 0
	assert_true(_data.dialog.party_slot.lines.size() >= 2, "berättaren och Gorm")


func test_crypt_and_chapel_stay_balanced_for_four() -> void:
	for realm_id in ["crypt", "chapel"]:
		var s := RunState.new()
		s.set_realm(_data, realm_id)
		assert_eq(s.realm_party, 4, realm_id)
		s.owned_heroes = 6
		s.party_slots = 5
		assert_eq(s.full_party_size(), 4, "%s: fiender som mot fyra" % realm_id)
		s.owned_heroes = 3
		assert_eq(s.full_party_size(), 0, "%s: äger tre, fienderna efter sällskapet som förut" % realm_id)
		s.owned_heroes = 6
		var enc: String = _data.realms[realm_id].floors[0]
		var party := ["paladin", "brokk", "alva", "eira"]
		var before := CombatSim.create(_data, enc, 3, party, {}, {}, {}, 1, {"full_party": true})
		var now := CombatSim.create(_data, enc, 3, party, {}, {}, {}, 1, {"full_party": s.full_party_size()})
		assert_eq(now.enemies.size(), before.enemies.size(), realm_id)
		for i in now.enemies.size():
			assert_near(now.enemies[i].max_hp, before.enemies[i].max_hp, 1e-6, "%s: samma fiender som förut" % realm_id)


func test_mountain_is_balanced_for_five() -> void:
	var s := RunState.new()
	s.set_realm(_data, "mountain")
	assert_eq(s.realm_party, 5)
	for owned in [1, 4, 5, 12]:
		s.owned_heroes = owned
		for slots in [4, 5]:
			s.party_slots = slots
			assert_eq(s.full_party_size(), 5, "Trollberget är alltid byggt för fem (äger %d, %d platser)" % [owned, slots])
	var p := _profile(6)
	p.realm_depth = {"chapel": 1}
	assert_true(RunState.realm_too_big(p, _data, "mountain"), "varningen på kampanjkartan")
	assert_true(not RunState.realm_too_big(p, _data, "crypt"))
	p.realm_depth = UNLOCKED.duplicate()
	assert_true(not RunState.realm_too_big(p, _data, "mountain"), "ingen varning med fem platser")
	var four := ["paladin", "brokk", "alva", "eira"]
	var enc := "troll_g2"
	var old := CombatSim.create(_data, enc, 3, four, {}, {}, {}, 1, {})
	var vs_five := CombatSim.create(_data, enc, 3, four + ["imma"], {}, {}, {}, 1, {"full_party": 5})
	assert_eq(old.enemies.size(), 4, "fyra hjältar möter mötets fiender som förut")
	assert_eq(vs_five.enemies.size(), 6, "fem möter också mötets \"extra\"")
	assert_eq(vs_five.heroes.size(), 5)
	var feat := CombatSim.create(_data, enc, 3, four, {}, {}, {}, 1, {"full_party": 5})
	assert_eq(feat.enemies.size(), 6, "fyra av fem: fiender som mot fem (en bedrift)")


func test_capped_variant_keeps_five_enemies() -> void:
	var keep := CombatSim.max_enemies
	CombatSim.max_enemies = 5
	var sim := CombatSim.create(_data, "troll_g2", 3, ["paladin", "brokk", "alva", "eira", "imma"], {}, {}, {}, 1,
			{"full_party": 5})
	CombatSim.max_enemies = keep
	assert_eq(sim.enemies.size(), 5)
	assert_eq(sim.enemies[0].kind, "troll_mother", "ledaren står kvar")


func test_five_heroes_get_their_own_places() -> void:
	var sim := CombatSim.create(_data, "troll_3", 3, ["paladin", "brokk", "alva", "eira", "imma"], {}, {}, {}, 1,
			{"full_party": 5})
	var spots := {}
	for u in sim.units:
		spots[u.position] = true
	assert_eq(spots.size(), sim.units.size(), "ingen står på en annans plats")
