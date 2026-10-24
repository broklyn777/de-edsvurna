extends "res://tests/test_case.gd"
## Kartprov (NodeMap): nodkartan i Slay the Spires stil över grottans innehåll.

const QUESTS := ["hunt", "clear", "collect", "seals"]


func _state(data: Dictionary, realm: String, seed_value: int, quest := "") -> RunState:
	RunState.dev_quest = quest
	var s := RunState.new()
	s.use_nodes = true
	s.set_realm(data, realm)
	s.fill_charges(data)
	s.start_expedition(data, seed_value)
	RunState.dev_quest = ""
	return s


func test_maps_follow_the_rules() -> void:
	var data := GameData.load_all()
	for realm in ["crypt", "chapel"]:
		for q in QUESTS:
			for seed_value in range(1, 13):
				var s := _state(data, realm, seed_value, q)
				var g := s.map
				assert_true(s.is_last_floor(), "en karta per nedstigning, med bossen")
				var probs := NodeMap.problems(g, s.quest)
				assert_eq(probs.size(), 0, "%s %s frö %d: %s" % [realm, q, seed_value, ", ".join(probs)])
				var rows := NodeMap.rows(g)
				assert_eq(rows.size(), NodeMap.MID_ROWS + 3, "rader")
				var n := NodeMap.all_nodes(g).size()
				assert_true(n >= 30 and n <= 70, "ungefär 35–50 noder (%d)" % n)
				assert_true(g.cells[g.goal].get("boss", false), "bossen överst")
				for r in range(1, NodeMap.MID_ROWS + 1):
					assert_true(rows[r].size() >= 1 and rows[r].size() <= NodeMap.COLS, "1–7 noder per rad")
				for r in range(1, NodeMap.ELITE_MIN_ROW):
					for i in rows[r]:
						assert_true(g.cells[i].kind != "elite", "ingen elit på de två första raderna")
				for i in rows[NodeMap.MID_ROWS + 1]:
					assert_eq(g.cells[i].kind, "campfire", "lägereldar före bossen")
				var from_start := NodeMap.ahead(g, g.start)
				for i in NodeMap.all_nodes(g):
					assert_true(from_start.has(i), "varje nod går att nå")
					assert_true(NodeMap.ahead(g, i).has(g.goal), "bossen går att nå från varje nod")
					var ups := NodeMap.up(g, i)
					if i != g.goal:
						assert_true(ups.size() >= 1, "minst en väg upp")
					if NodeMap.row_of(g, i) >= 1:
						assert_true(ups.size() <= 3, "högst tre vägar upp")
					for j in ups:
						assert_eq(NodeMap.row_of(g, j), NodeMap.row_of(g, i) + 1, "en väg går en rad upp")
						assert_true(not (g.cells[i].kind == "campfire" and g.cells[j].kind == "campfire"), "inga två lägereldar i rad")


func test_every_content_cell_is_a_node_and_quest_targets_lie_on_a_route() -> void:
	var data := GameData.load_all()
	for q in QUESTS:
		for seed_value in range(1, 16):
			var s := _state(data, "crypt", seed_value, q)
			var g := s.map
			for i in g.cells.size():
				if g.cells[i].kind != "empty":
					assert_true(NodeMap.is_node(g, i), "rutan %s är en nod" % g.cells[i].kind)
			for t in s.quest_targets():
				assert_true(NodeMap.is_node(g, t), "questens mål ligger på en nod")
			assert_true(NodeMap.best_gain(g, g.start, s.quest) >= int(s.quest.goal), "en väg klarar questen (%s)" % q)


func test_grid_runs_have_no_node_map() -> void:
	var data := GameData.load_all()
	var s := RunState.new()
	s.set_realm(data, "crypt")
	s.fill_charges(data)
	s.start_expedition(data, 4)
	assert_true(not s.node_mode(), "grottan som vanligt utan flaggan")
	assert_true(not NodeMap.enabled(), "flaggan är av i projektet")


func test_steps_go_one_row_up_and_quest_routes_are_kept() -> void:
	var data := GameData.load_all()
	var s := _state(data, "crypt", 6, "collect")
	var g := s.map
	assert_eq(s.pos, g.start)
	for i in NodeMap.all_nodes(g):
		var why := s.can_step(i)
		if NodeMap.row_of(g, i) != 1:
			assert_true(why != "", "bara raden ovanför")
		elif NodeMap.quest_ok(g, i, s.quest):
			assert_eq(why, "", "en nod på rad 1")
		else:
			assert_eq(why, "quest", "en nod där questen inte går att klara")
	# Gå hela vägen: ta en nod som håller questen vid liv, slå grupperna, ta föremålen.
	var guard := 0
	while s.pos != g.goal and guard < 40:
		guard += 1
		var next := -1
		for j in NodeMap.up(g, s.pos):
			if s.can_step(j) == "":
				next = j
				break
		assert_true(next >= 0, "det finns alltid en väg vidare")
		if next < 0:
			return
		s.step(next)
		if s.at_group():
			s.fight()
			s.battle_won()
			if g.cells[s.pos].kind == "item":
				s.collect_item()
	assert_eq(s.pos, g.goal, "målet nås")
	assert_true(s.quest.done, "questen klar på vägen")
	assert_true(s.map.cells[s.pos].get("boss", false), "bossen nås")


func test_back_from_a_group_returns_and_frees_the_choice() -> void:
	var data := GameData.load_all()
	for seed_value in range(1, 30):
		var s := _state(data, "crypt", seed_value)
		var g := s.map
		var target := -1
		for j in NodeMap.up(g, g.start):
			if g.has_group(j) and s.can_step(j) == "":
				target = j
		if target < 0:
			continue
		s.step(target)
		assert_true(s.at_group())
		assert_eq(s.can_step(NodeMap.up(g, g.start)[0] if NodeMap.up(g, g.start)[0] != target else g.start),
				"" if NodeMap.up(g, g.start)[0] == target else "group", "på en grupp: bara backa")
		assert_true(s.back())
		assert_eq(s.pos, g.start)
		assert_true(not s.visited.has(target), "vägen som backades ritas inte")
		assert_eq(s.can_step(target), "", "gruppen går att välja igen")
		return
	assert_true(false, "ingen grupp på rad 1 i 30 frön")


func test_save_and_load_keep_the_map_and_position() -> void:
	var data := GameData.load_all()
	var s := _state(data, "chapel", 9)
	var first := -1
	for j in NodeMap.up(s.map, s.map.start):
		if not s.map.has_group(j) and s.can_step(j) == "":
			first = j
	if first < 0:
		first = NodeMap.up(s.map, s.map.start)[0]
	s.step(first)
	var path := "user://test_node_map_run.cfg"
	assert_eq(s.save(path), OK)
	var t := RunState.load_from(path)
	RunState.delete_saved(path)
	assert_true(t != null and t.node_mode(), "nodkartan sparas")
	assert_eq(t.pos, s.pos, "positionen sparas")
	assert_eq(t.visited, s.visited, "vägen sparas")
	assert_eq(t.use_nodes, true)
	assert_eq(NodeMap.rows(t.map), NodeMap.rows(s.map), "raderna sparas")
	for i in NodeMap.all_nodes(s.map):
		assert_eq(NodeMap.up(t.map, i), NodeMap.up(s.map, i), "vägarna sparas")
		assert_eq(t.can_step(i), s.can_step(i), "samma val efter laddning")


func test_same_seed_gives_same_map() -> void:
	var data := GameData.load_all()
	var a := _state(data, "crypt", 11)
	var b := _state(data, "crypt", 11)
	assert_eq(NodeMap.rows(a.map), NodeMap.rows(b.map))
	assert_eq(a.map.nodes.up, b.map.nodes.up)


func test_quickstart_profile_is_ready_to_compare() -> void:
	var data := GameData.load_all()
	var p := Profile.new()
	preload("res://scripts/game/run.gd").make_quickstart(p, data)
	assert_true(p.intro_done, "introt klart")
	assert_eq(p.party.size(), 4, "fyra hjältar")
	for id in p.party:
		assert_true(int(p.hero(data, id).level) >= 10, "nivå 10")
	assert_eq(p.max_depth(), 3, "djup 1–3 öppna")
	assert_true(p.collection.size() >= 4, "några troféer")
	assert_true(not p.worn.is_empty(), "troféer på hjältarna")
	assert_true(p.artifacts.has("paladin"), "en artefakt")
	var s := RunState.new_run(p, data)
	assert_true(not s.use_nodes, "nodkartan bara i kartprovet (flaggan av här)")
