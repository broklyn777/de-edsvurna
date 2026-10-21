extends "res://tests/test_case.gd"
## 0.27: grottan (docs/plan/0.27-grottan.md §1): generatorns regler över många frön, dimman, stegen, grupperna som
## spärrar, questen som låser trappan och bossen, lägereld, helgedom och sparad körning.

var _data := GameData.load_all()


func _state(realm := "crypt", seed_value := 5) -> RunState:
	var s := RunState.new()
	s.set_realm(_data, realm)
	s.fill_charges(_data)
	s.start_expedition(_data, seed_value)
	return s


## En grotta med en bestämd quest (generatorn direkt).
func _grotto(seed_value: int, floor_i: int, quest: Dictionary, realm := "crypt", prisoner := {}) -> Grotto:
	var r: Dictionary = _data.realms[realm]
	return Grotto.generate(seed_value, floor_i, floor_i == 1, r.pools, r.floors[2], r.floors[floor_i], quest, prisoner)


func test_grottos_meet_the_rules_for_many_seeds() -> void:
	var quests := [{"type": "hunt", "goal": 1}, {"type": "clear", "goal": 2}, {"type": "collect", "goal": 2},
			{"type": "collect", "goal": 3}]
	for seed_value in range(1, 301):
		var quest: Dictionary = quests[seed_value % quests.size()]
		var floor_i := seed_value % 2
		var prisoner := {"hero": "brokk", "first": true, "guarded": true} if seed_value % 5 == 0 else {}
		var g := _grotto(seed_value, floor_i, quest, "crypt" if seed_value % 3 else "chapel", prisoner)
		var problems := g.problems(quest)
		assert_true(problems.is_empty(), "frö %d: %s" % [seed_value, str(problems)])
		assert_eq(g.cells.size(), 64, "8×8")
		var p := Grotto.xy(g.start)
		assert_true(p.x == 0 or p.y == 0 or p.x == 7 or p.y == 7, "start vid en kant")
		assert_true(Grotto.dist(g.start, g.goal) >= 5, "målet minst 5 steg bort")
		assert_eq(g.cell(g.goal).kind, "end" if floor_i == 1 else "stairs")
		var groups := g.group_cells().filter(func(i: int) -> bool: return i != g.goal)
		for i in groups:
			assert_true(Grotto.dist(i, g.start) >= 2, "ingen grupp bredvid start (frö %d)" % seed_value)
			var near := Grotto.neighbors(i).filter(func(n: int) -> bool: return groups.has(n))
			for n in near:
				assert_true(Grotto.neighbors(n).filter(func(x: int) -> bool: return groups.has(x) and x != i).is_empty(),
						"högst två grupper intill varandra (frö %d)" % seed_value)
		for e in g.indices("elite"):
			assert_true(Grotto.dist(e, g.start) >= 4, "eliten minst 4 steg från start")
		var elite: int = g.indices("elite")[0]
		assert_true(g.indices("campfire").any(func(f: int) -> bool: return Grotto.dist(f, elite) <= 3), "lägereld nära eliten")
		if prisoner.is_empty():
			assert_true(g.indices("prisoner").is_empty())
		else:
			assert_eq(g.indices("prisoner").size(), 1, "fången finns")


func test_same_seed_gives_the_same_grotto() -> void:
	var q := {"type": "collect", "goal": 3}
	assert_eq(_grotto(42, 0, q).to_dict(), _grotto(42, 0, q).to_dict())
	assert_true(_grotto(42, 0, q).to_dict() != _grotto(43, 0, q).to_dict(), "ett annat frö ger en annan grotta")


func test_fog_and_steps() -> void:
	var s := _state()
	assert_eq(s.visited, [s.map.start], "bara startrutan är känd")
	assert_eq(s.pos, s.map.start)
	var far := -1
	for i in 64:
		if Grotto.dist(i, s.pos) == 3:
			far = i
			break
	assert_eq(s.can_step(far), "far", "bara ett steg i taget till okända rutor")
	var n: int = Grotto.neighbors(s.pos).filter(func(x: int) -> bool: return not s.map.has_group(x))[0]
	assert_eq(s.step(n), [n] as Array[int])
	assert_true(s.visited.has(n))
	# En besökt ruta: pjäsen går dit själv genom kända rutor.
	var walk := s.step(s.map.start)
	assert_eq(walk.back(), s.map.start)
	assert_eq(s.pos, s.map.start)


## Lägger en grupp bredvid start och returnerar rutan.
func _group_next_to_start(s: RunState) -> int:
	var n: int = Grotto.neighbors(s.map.start)[0]
	s.map.cells[n] = {"kind": "battle", "encounter": _data.realms.crypt.pools[0][0], "tier": 0}
	return n


func test_a_seen_group_blocks_its_neighbours_until_beaten() -> void:
	var s := _state()
	var g := _group_next_to_start(s)
	assert_eq(s.step(g).size(), 1)
	assert_true(s.at_group(), "kortet visas, striden har inte börjat")
	assert_true(not s.battle_pending)
	var other: int = Grotto.neighbors(g).filter(func(x: int) -> bool: return x != s.map.start)[0]
	assert_eq(s.can_step(other), "group", "man kan bara backa eller slåss")
	assert_true(s.back())
	assert_eq(s.pos, s.map.start)
	assert_true(s.seen.has(g))
	assert_true(s.map.blocked(other, s.visited, s.seen), "gruppen spärrar de obesökta rutorna intill sig")
	# Strid och seger: spärren försvinner.
	s.step(g)
	s.fight()
	assert_true(s.battle_pending)
	s.battle_won()
	assert_true(not s.map.has_group(g))
	assert_true(not s.map.blocked(other, s.visited, s.seen))
	assert_eq(s.can_step(other), "")


func test_the_goal_is_locked_until_the_quest_is_done() -> void:
	var s := _state()
	# Allt utom målet besökt och inga grupper: målet syns men är låst.
	for i in 64:
		if i != s.map.goal:
			s.map.cells[i].erase("encounter")
			if not s.visited.has(i):
				s.visited.append(i)
	assert_eq(s.can_step(s.map.goal), "locked")
	s.quest.done = true
	assert_eq(s.can_step(s.map.goal), "")
	s.step(s.map.goal)
	assert_true(s.floor_cleared(), "trappan nådd med questen klar")
	s.next_floor(_data)
	assert_eq(s.floor, 1)
	assert_eq(s.map.cell(s.map.goal).kind, "end", "bossen på den andra våningen")
	assert_true(not s.quest.get("done", false), "en ny quest per våning")


func test_quests_lead_to_fights() -> void:
	var seen := {}
	for seed_value in range(1, 40):
		var s := _state("crypt", seed_value)
		var q: Dictionary = s.quest
		seen[q.type] = true
		match q.type:
			"hunt":
				var nem := s.map.cells.filter(func(c: Dictionary) -> bool: return c.get("nemesis", false))
				assert_eq(nem.size(), 1, "en Nemesis")
				s.pos = s.map.cells.find(nem[0])
				s.battle_won()
				assert_true(s.quest.done, "Nemesis besegrad")
			"clear":
				var elites := s.map.indices("elite")
				assert_eq(int(q.goal), 1, "Rensa på våning 1 kräver en elitgrupp")
				assert_true(elites.size() >= int(q.goal))
				for e in elites.slice(0, int(q.goal)):
					s.pos = e
					s.battle_won()
				assert_true(s.quest.done, "elitgrupperna besegrade")
			"collect":
				var items := s.map.indices("item")
				assert_eq(items.size(), int(q.goal))
				for i in items:
					s.pos = i
					assert_true(not s.collect_item(), "vakten först")
					s.battle_won()
					s.collect_item()
				assert_true(s.quest.done, "alla föremål")
	assert_eq(seen.size(), 3, "alla tre sorterna förekommer")


func test_campfire_restores_charges_once() -> void:
	var s := _state()
	s.pos = s.map.indices("campfire")[0]
	s.charges.alva.healing_light = 0
	s.charges.alva.renew = int(_data.abilities.renew.charges)
	s.campfire(_data)
	assert_eq(s.charges.alva.healing_light, RunState.CAMPFIRE_CHARGES)
	assert_eq(s.charges.alva.renew, int(_data.abilities.renew.charges), "aldrig över max")
	assert_eq(s.campfire(_data), 0, "en gång per lägereld")


func test_shrine_gifts_and_blessing_lasts_one_battle() -> void:
	var s := _state()
	s.pos = s.map.indices("shrine")[0]
	var rng := RandomNumberGenerator.new()
	var gifts := s.shrine_options(_data, rng)
	assert_eq(gifts.size(), 3)
	var charge: Dictionary = gifts[0]
	var before := int(s.charges[charge.hero][charge.ability])
	s.apply_shrine(_data, rng, charge)
	assert_eq(int(s.charges[charge.hero][charge.ability]), before + 2)
	assert_true(s.current_room().done)
	s.apply_shrine(_data, rng, {"kind": "blessing", "aura": "inspired"})
	var g := s.map.group_cells()[0]
	s.pos = g
	assert_eq(s.battle_opts().start_auras, ["inspired"])
	s.battle_won()
	assert_eq(s.battle_opts().start_auras, [], "bara nästa strid")


func test_elite_and_nemesis_change_the_battle() -> void:
	var s := _state()
	s.pos = s.map.indices("elite")[0]
	var opts := s.battle_opts()
	assert_eq(opts.get("force_elites", 0), 1)
	assert_true(int(opts.floor) >= s.floor, "gruppens tier ger fiendernas nivå")
	assert_eq(RunState.fight_kind(s.current_room()), "elite")


func test_run_is_saved_and_resumed() -> void:
	var s := _state("crypt", 9)
	var g := _group_next_to_start(s)
	s.step(g)
	s.back()
	var path := "user://test_grotto_run.cfg"
	assert_eq(s.save(path), OK)
	var t := RunState.load_from(path)
	assert_eq(t.pos, s.pos)
	assert_eq(t.visited, s.visited)
	assert_eq(t.seen, s.seen)
	assert_eq(t.map.to_dict(), s.map.to_dict())
	assert_eq(t.quest, s.quest)
	assert_true(t.map.blocked(Grotto.neighbors(g).filter(func(x: int) -> bool: return x != s.map.start)[0], t.visited, t.seen),
			"spärren gäller efter sparning")
	# En strid som pågick spelas igen.
	t.step(g)
	t.fight()
	t.save(path)
	assert_true(RunState.load_from(path).battle_pending)
	RunState.delete_saved(path)


func test_a_run_saved_with_the_old_room_map_is_not_resumed() -> void:
	var d := {"map": {"steps": [], "end": {}}, "floor": 1}
	assert_true(RunState.from_dict(d).map == null)


func test_quest_gives_perk_point_once_per_realm_and_depth() -> void:
	var p := Profile.new()
	var silver := p.silver
	var r := p.complete_quest("crypt", 1)
	assert_true(r.point)
	assert_eq(p.silver, silver + Profile.QUEST_SILVER)
	assert_true(not p.complete_quest("crypt", 1).point)


func test_bot_walks_a_whole_run() -> void:
	var Bot := load("res://tests/combat_bot.gd")
	var cleared := 0
	var fights := 0
	for seed_value in range(1, 9):
		var r: Dictionary = Bot.run_expedition(_data, seed_value, Bot.Skill.TUNED, {}, {}, 1, "crypt",
				{"levels": Bot.party_levels(_data, 3), "grow": true})
		fights += int(r.fights)
		cleared += 1 if r.cleared else 0
		if r.cleared:
			assert_true(int(r.fights) >= 5, "en klarad körning har strider (%d)" % r.fights)
	assert_true(cleared > 0, "boten klarar ibland hela grottan")


## 0.28.2: Realmens föremål – de läggs ut, och valen gör det de lovar.
func test_realm_objects() -> void:
	var data := GameData.load_all()
	var p := Profile.new()
	var s := RunState.new_run(p, data)
	s.start_expedition(data, 77)
	var objs := s.map.indices("object")
	assert_true(objs.size() >= Grotto.OBJECTS_MIN and objs.size() <= Grotto.OBJECTS_MAX, "%d föremål" % objs.size())
	for i in objs:
		assert_true(data.realms.crypt.objects.has(s.map.cells[i].obj))
		assert_true(Grotto.dist(i, s.map.start) >= 2)
	var rng := RandomNumberGenerator.new()
	# Sarkofagen: en starkare grupp på rutan, dubbel skatt efter segern.
	s.pos = objs[0]
	s.map.cells[s.pos] = {"kind": "object", "obj": "sarcophagus"}
	var res := s.use_object(data, "knock", rng)
	assert_true(res.fight and s.at_group(), "en grupp står på rutan")
	assert_near(float(s.battle_opts().get("stat_bonus", 1.0)), 1.15)
	s.battle_won()
	var won := s.object_won()
	assert_eq(won.silver, s.treasure_value() * 2)
	assert_true(s.current_room().done)
	# Gravklockan: efter första segern kan man ringa igen, svårare.
	s.map.cells[s.pos] = {"kind": "object", "obj": "grave_bell"}
	s.use_object(data, "ring", rng)
	s.battle_won()
	s.object_won()
	assert_true(s.current_room().get("again", false), "klockan frågar igen")
	s.use_object(data, "ring_again", rng)
	assert_near(float(s.battle_opts().get("stat_bonus", 1.0)), 1.25)
	s.battle_won()
	assert_eq(s.object_won().silver, s.treasure_value() * 2)
	assert_true(s.current_room().done)
	# Glasfönstret: hela raden syns och nästa strid är starkare.
	s.map.cells[s.pos] = {"kind": "object", "obj": "stained_window"}
	s.use_object(data, "pull", rng)
	var row := Grotto.xy(s.pos).y
	for x in Grotto.SIZE:
		var i := Grotto.idx(Vector2i(x, row))
		assert_true(s.visited.has(i) or s.revealed.has(i))
	assert_near(s.next_stat_mult, 1.15)
	# Kyrkbänken: utan sedd grupp går den inte att använda, med en sedd grupp försvinner gruppen.
	s.map.cells[s.pos] = {"kind": "object", "obj": "pew"}
	s.seen.clear()
	assert_true(s.object_options(data).any(func(o: Dictionary) -> bool: return o.get("disabled", false)))
	var g := s.map.indices("battle").filter(func(i: int) -> bool: return s.map.has_group(i))
	s.seen.append(g[0])
	s.use_object(data, "barricade", rng)
	assert_true(not s.map.has_group(g[0]) and s.map.cells[g[0]].barricaded)


## 0.29.2: Väktarens timglas – en Charge visar närmaste elitgrupp.
func test_hourglass_scouts_an_elite() -> void:
	var data := GameData.load_all()
	var s := RunState.new_run(Profile.new(), data)
	s.start_expedition(data, 5)
	var t := s.scout_target()
	assert_true(t >= 0, "det finns en elitgrupp att visa")
	s.map.cells[s.pos] = {"kind": "object", "obj": "hourglass"}
	var before := 0
	for h in s.charges:
		for a in s.charges[h]:
			before += int(s.charges[h][a])
	var res := s.use_object(data, "scout", RandomNumberGenerator.new())
	var after := 0
	for h in s.charges:
		for a in s.charges[h]:
			after += int(s.charges[h][a])
	assert_eq(after, before - 1, "en Charge")
	assert_true(s.revealed.has(t) and String(res.text).contains("elitgrupp"))
