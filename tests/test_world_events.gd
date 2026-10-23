extends "res://tests/test_case.gd"
## Den levande världen (WorldEvents): följderna i borgen slår till och vänds, gåvorna kommer en gång, handelsmannen,
## händelserna startar, löper ut och lyckas (en åt gången), sparas och läses, gamla profiler, och hemkomstens repliker
## (rätt person, konkret, ingen upprepning, tröst och råd efter förluster).

var _data := GameData.load_all()
const TMP := "user://test_world_events.cfg"
const PARTY := ["paladin", "imma", "brokk", "alva"]


func _profile(visited := ["crypt", "chapel", "grove"]) -> Profile:
	var p := Profile.new()
	p.intro_done = true
	p.set_hero_name("Tran")
	for id in ["imma", "brokk", "alva"]:
		p.recruit(_data, id)
	p.set_party(["imma", "brokk", "alva"])
	for r in visited:
		p.descents[r] = 1
	p.world.next = 99  # inga händelser om testet inte vill det
	return p


func _before(p: Profile) -> Dictionary:
	var out := {}
	for r in _data.realms:
		out[r] = LivingMap.growth(p, r)
	return out


func _speakers(p: Profile) -> Array:
	return p.homecoming.get("remarks", []).map(func(r: Dictionary) -> String: return r.speaker)


func _keys(p: Profile) -> Array:
	return p.homecoming.get("remarks", []).map(func(r: Dictionary) -> String: return r.key)


# --- Följder -------------------------------------------------------------------------

func test_grove_at_three_makes_the_smith_dearer_and_it_turns_back() -> void:
	var p := _profile()
	p.silver = Profile.FORGE_COST
	p.forge("paladin", "sword", "")
	var base := p.artifact_level_cost("paladin")
	p.growth = {"grove": 3}
	assert_true(WorldEvents.has_cost(p, "grove"))
	assert_eq(p.artifact_level_cost("paladin"), roundi(base * (1.0 + WorldEvents.SMITH_GROVE)), "+15 %")
	assert_true(WorldEvents.smith_reason(_data, p).contains("lunden"), "Hedda säger varför")
	assert_true(WorldEvents.cost_line(p, _data, "grove") != "", "kampanjkartans rad")
	p.growth = {"grove": 1}
	assert_eq(p.artifact_level_cost("paladin"), base, "tillbaka när lunden trycks tillbaka")
	assert_eq(WorldEvents.smith_reason(_data, p), "")
	# En Realm man aldrig har besökt kostar inget.
	var q := _profile(["crypt"])
	q.growth = {"grove": 4}
	assert_true(not WorldEvents.has_cost(q, "grove"))


func test_crypt_workers_send_amber_only_when_it_is_calm() -> void:
	var p := _profile()
	p.growth = {"crypt": 2, "chapel": 1, "grove": 1}
	var rep := WorldEvents.after_descent(p, _data, "chapel", "boss", 3, false, _before(p))
	assert_true(String(rep.tor) != "", "Tor skickar bärnsten")
	assert_eq(int(p.materials.get(rep.tor, 0)), WorldEvents.TOR_AMBER)
	p.growth.crypt = 3
	rep = WorldEvents.after_descent(p, _data, "chapel", "boss", 3, false, _before(p))
	assert_eq(String(rep.tor), "", "arbetarna vägrar gå ned på steg 3")


func test_chapel_cost_and_blessing_change_heal_charges() -> void:
	var p := _profile()
	var heal := ""
	for a in _data.heroes.alva.abilities:
		if WorldEvents._is_heal(_data, a):
			heal = a
	assert_true(heal != "", "Alva har en helning")
	var full := int(_data.abilities[heal].charges)
	p.growth = {"chapel": 3}
	var s := RunState.new_run(p, _data)
	assert_eq(int(s.charges.alva[heal]), full - 1, "en Charge mindre när kapellet står på 3")
	assert_eq(s.world_heal_mod, -1)
	p.growth = {"chapel": 1}
	p.world.bless_runs = 1
	s = RunState.new_run(p, _data)
	assert_eq(int(s.charges.alva[heal]), full + 1, "välsignelsen ger en till")
	WorldEvents.begin_run(p, s)
	assert_eq(int(p.world.bless_runs), 0, "förbrukas när körningen börjar")
	assert_eq(int(RunState.new_run(p, _data).charges.alva[heal]), full)


func test_costs_switch_on_and_off_in_the_report() -> void:
	var p := _profile()
	p.growth = {"grove": 3}
	var rep := WorldEvents.after_descent(p, _data, "crypt", "boss", 3, false, {"grove": 2})
	assert_eq(rep.costs_on, ["grove"])
	p.growth = {"grove": 2}
	rep = WorldEvents.after_descent(p, _data, "grove", "boss", 3, false, {"grove": 3})
	assert_eq(rep.costs_off, ["grove"])


# --- Gåvor och handelsmannen ----------------------------------------------------------

func test_pushing_a_realm_back_gives_a_gift_once() -> void:
	var p := _profile()
	p.growth = {"crypt": 0}
	var silver := p.silver
	var rep := WorldEvents.after_descent(p, _data, "crypt", "boss", 3, true, {"crypt": 2})
	assert_eq(rep.gifts.size(), 1)
	assert_eq(rep.gifts[0].id, "workers_find")
	assert_eq(p.silver, silver + WorldEvents.WORKERS_SILVER)
	assert_eq(int(p.materials.get(rep.gifts[0].amber, 0)) >= WorldEvents.WORKERS_AMBER, true)
	rep = WorldEvents.after_descent(p, _data, "crypt", "boss", 3, true, {"crypt": 1})
	assert_true(rep.gifts.is_empty(), "bara en gång tills Realmen har vuxit igen")
	# Lunden: en handelsman. Kapellet: en välsignelse.
	p.growth = {"grove": 1, "chapel": 1}
	rep = WorldEvents.after_descent(p, _data, "grove", "boss", 3, false, {"grove": 2, "chapel": 2})
	assert_true(WorldEvents.merchant_here(p))
	p.growth.chapel = 0
	var bless := int(p.world.get("bless_runs", 0))
	rep = WorldEvents.after_descent(p, _data, "chapel", "boss", 3, true, {"chapel": 2})
	assert_true(WorldEvents.rumour_pending(p), "kapellet: pilgrimens rykte")
	assert_eq(int(p.world.get("bless_runs", 0)), bless, "ingen välsignelse längre")


func test_merchant_stays_and_sells_one_of_each_until_the_next_descent() -> void:
	var p := _profile()
	p.world.merchant = {"grateful": false}
	p.silver = 500
	var goods := WorldEvents.merchant_goods(p, _data)
	assert_true(WorldEvents.merchant_buy(p, _data, "amber"))
	assert_true(WorldEvents.merchant_here(p), "han stannar efter ett köp")
	assert_true(WorldEvents.merchant_sold(p, "amber"))
	assert_true(not WorldEvents.merchant_buy(p, _data, "amber"), "en av varje")
	assert_eq(int(p.materials[goods.amber]), WorldEvents.MERCHANT_AMBER)
	# Sparas och läses i Profile.world.
	assert_eq(p.save(TMP), OK)
	var q := Profile.load_from(TMP)
	assert_true(WorldEvents.merchant_here(q) and WorldEvents.merchant_sold(q, "amber") and not WorldEvents.merchant_sold(q, "trick"))
	assert_true(WorldEvents.merchant_buy(p, _data, "trick"))
	assert_eq(p.silver, 500 - WorldEvents.MERCHANT_AMBER_PRICE - WorldEvents.MERCHANT_TRICK_PRICE)
	assert_true(not WorldEvents.merchant_here(p), "allt sålt: han går")
	# Den tacksamma (karavanen) delar koden: han stannar efter ett köp och går när nästa nedstigning börjar.
	p.world.merchant = {"grateful": true}
	assert_true(WorldEvents.merchant_buy(p, _data, "trick"))
	assert_true(WorldEvents.merchant_here(p))
	var s := RunState.new_run(p, _data)
	s.start_expedition(_data, 3)
	WorldEvents.begin_run(p, s)
	assert_true(not WorldEvents.merchant_here(p), "han går när paladinen går ned igen")


func test_chapel_gift_is_a_rumour_that_shows_the_first_quest_targets() -> void:
	var p := _profile()
	p.growth = {"chapel": 1}
	WorldEvents.after_descent(p, _data, "chapel", "boss", 3, true, {"chapel": 2})
	assert_true(WorldEvents.rumour_pending(p))
	assert_true(WorldEvents.rumour_line(p, _data) != "", "kampanjkartans rad")
	# Vilken Realm som helst: här kryptan.
	p.realm = "crypt"
	var s := RunState.new_run(p, _data)
	s.start_expedition(_data, 11)
	var targets := s.quest_targets()
	assert_true(not targets.is_empty())
	assert_true(not s.active_hints().is_empty(), "före ryktet bara ringar")
	WorldEvents.begin_run(p, s)
	assert_true(s.world_rumour)
	for t in targets:
		assert_true(s.revealed.has(t), "målet syns genom dimman")
	assert_true(s.active_hints().is_empty(), "ringarna behövs inte längre")
	assert_true(not WorldEvents.rumour_pending(p), "förbrukas när körningen börjar")
	assert_true(RunState.from_dict(s.to_dict()).world_rumour, "sparas med körningen")
	var s2 := RunState.new_run(p, _data)
	s2.start_expedition(_data, 11)
	WorldEvents.begin_run(p, s2)
	assert_true(not s2.world_rumour and s2.revealed.is_empty(), "bara en körning")


func test_merchant_sells_once_and_the_grateful_one_is_cheaper() -> void:
	var p := _profile()
	p.world.merchant = {"grateful": false}
	p.silver = 10
	assert_true(not WorldEvents.merchant_buy(p, _data, "amber"), "silvret räcker inte")
	assert_true(WorldEvents.merchant_here(p), "han väntar")
	p.silver = 200
	var goods := WorldEvents.merchant_goods(p, _data)
	assert_true(WorldEvents.merchant_buy(p, _data, "amber"))
	assert_eq(p.silver, 200 - WorldEvents.MERCHANT_AMBER_PRICE)
	assert_eq(int(p.materials[goods.amber]), WorldEvents.MERCHANT_AMBER)
	assert_true(WorldEvents.merchant_here(p), "han stannar efter ett köp")
	p.world.merchant = {"grateful": true}
	assert_eq(WorldEvents.merchant_price(p, "trick"), WorldEvents.MERCHANT_TRICK_PRICE / 2)


# --- Händelser -----------------------------------------------------------------------

func test_events_start_after_a_while_never_two_at_once() -> void:
	var p := _profile()
	p.world.erase("next")
	assert_eq(WorldEvents.pick_event(p, _data, WorldEvents.FIRST_AT - 1), "", "inte för tidigt")
	var id := WorldEvents.pick_event(p, _data, WorldEvents.FIRST_AT)
	assert_true(id != "")
	WorldEvents.start(p, _data, id, WorldEvents.FIRST_AT)
	assert_eq(WorldEvents.pick_event(p, _data, 50), "", "aldrig två samtidigt")
	var nxt := int(p.world.next)
	assert_true(nxt >= WorldEvents.FIRST_AT + WorldEvents.GAP_MIN and nxt <= WorldEvents.FIRST_AT + WorldEvents.GAP_MAX, str(nxt))
	# Händelser i Realms man inte har besökt startar inte.
	var q := _profile(["crypt"])
	q.world.erase("next")
	q.world.last = {"bell_tolls": 0}
	for i in 5:
		var e := WorldEvents.pick_event(q, _data, 10 + i)
		assert_true(e == "" or e == "bell_tolls", e)


func test_event_succeeds_when_you_go_there() -> void:
	var p := _profile()
	WorldEvents.start(p, _data, "cult_feast", 4)
	assert_true(WorldEvents.in_event(p, _data, "chapel"))
	assert_true(WorldEvents.map_line(p, _data).contains("två nedstigningar"), WorldEvents.map_line(p, _data))
	var silver := p.silver
	var rep := WorldEvents.after_descent(p, _data, "chapel", "boss", 5, false, _before(p))
	assert_eq(rep.event_end.result, "won")
	assert_eq(p.silver, silver + 60)
	assert_true(WorldEvents.active(p).is_empty())
	assert_eq(int(p.world.won.cult_feast), 1)


func test_event_expires_and_the_realm_grows() -> void:
	var p := _profile()
	p.growth = {"chapel": 1}
	WorldEvents.start(p, _data, "cult_feast", 4)
	var rep := WorldEvents.after_descent(p, _data, "crypt", "boss", 5, false, _before(p))
	assert_true(rep.event_end.is_empty(), "en nedstigning kvar")
	assert_eq(int(WorldEvents.active(p).left), 1)
	rep = WorldEvents.after_descent(p, _data, "crypt", "boss", 2, false, _before(p))
	assert_eq(rep.event_end.result, "lost", "biskopen föll inte")
	assert_eq(LivingMap.growth(p, "chapel"), 2, "kapellet hoppar upp ett steg")
	# Den som gick dit men inte fällde bossen har redan trängt tillbaka Realmen: den växer inte av händelsen.
	var q := _profile()
	q.growth = {"chapel": 1}
	WorldEvents.start(q, _data, "cult_feast", 4)
	q.world.event.left = 1
	WorldEvents.after_descent(q, _data, "chapel", "loss", 2, false, _before(q))
	assert_eq(LivingMap.growth(q, "chapel"), 1)
	assert_eq(String(q.world.boss_realm), "chapel", "men biskopen är starkare")
	# Biskopen är starkare nästa körning i kapellet, och bara den.
	p.realm = "chapel"
	var s := RunState.new_run(p, _data)
	assert_eq(s.world_boss_mult, 1.12)
	p.realm = "crypt"
	assert_eq(RunState.new_run(p, _data).world_boss_mult, 1.0)
	p.realm = "chapel"
	WorldEvents.begin_run(p, s)
	assert_eq(RunState.new_run(p, _data).world_boss_mult, 1.0, "förbrukas")


func test_boss_mult_reaches_the_boss_battle_only() -> void:
	var p := _profile()
	p.realm = "chapel"
	var s := RunState.new_run(p, _data)
	s.start_expedition(_data, 11)
	s.world_boss_mult = 1.12
	var plain := s.battle_opts()
	assert_eq(float(plain.get("stat_bonus", 1.0)), 1.0, "vanliga grupper som förut")


func test_bell_needs_four_wins_and_gives_a_stone() -> void:
	var p := _profile()
	WorldEvents.start(p, _data, "bell_tolls", 4)
	var rep := WorldEvents.after_descent(p, _data, "crypt", "loss", 3, false, _before(p))
	assert_true(rep.event_end.is_empty(), "tre strider räcker inte")
	var stones := p.stones.size()
	rep = WorldEvents.after_descent(p, _data, "crypt", "loss", 4, false, _before(p))
	assert_eq(rep.event_end.result, "won")
	assert_eq(p.stones.size(), stones + 1)


func test_two_fronts_half_grows_the_other() -> void:
	var p := _profile()
	p.growth = {"crypt": 1, "grove": 1}
	WorldEvents.start(p, _data, "two_fronts", 4)
	WorldEvents.after_descent(p, _data, "crypt", "boss", 5, false, _before(p))
	var rep := WorldEvents.after_descent(p, _data, "chapel", "boss", 5, false, _before(p))
	assert_eq(rep.event_end.result, "half")
	assert_eq(LivingMap.growth(p, "grove"), 2, "lunden växte")
	assert_eq(LivingMap.growth(p, "crypt"), 1, "kryptan stoppades")


func test_caravan_lost_raises_smith_prices_for_a_while() -> void:
	var p := _profile()
	WorldEvents.start(p, _data, "caravan", 4)
	for i in 2:
		WorldEvents.after_descent(p, _data, "crypt", "boss", 5, false, _before(p))
	assert_true(WorldEvents.smith_mult(p) > 1.0)
	p.descents.crypt = int(p.descents.crypt) + 5
	assert_eq(WorldEvents.smith_mult(p), 1.0, "går över")


func test_world_is_saved_and_old_profiles_load() -> void:
	var p := _profile()
	WorldEvents.start(p, _data, "pilgrims", 4)
	p.world.merchant = {"grateful": true}
	p.save(TMP)
	var back := Profile.load_from(TMP)
	assert_eq(String(WorldEvents.active(back).id), "pilgrims")
	assert_true(WorldEvents.merchant_here(back))
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "silver", 5)
	cfg.save(TMP)
	var old := Profile.load_from(TMP)
	assert_true(old.world.is_empty())
	assert_eq(WorldEvents.smith_mult(old), 1.0)
	assert_eq(WorldEvents.heal_charge_mod(old), 0)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP))


func test_run_state_saves_the_world_mods() -> void:
	var s := RunState.new()
	s.world_boss_mult = 1.12
	s.world_heal_mod = -1
	var back := RunState.from_dict(s.to_dict())
	assert_eq(back.world_boss_mult, 1.12)
	assert_eq(back.world_heal_mod, -1)


# --- Hemkomsten ----------------------------------------------------------------------

func test_lost_event_is_confirmed_by_the_right_person() -> void:
	var p := Profile.new()
	Chronicle.demo_home(p, _data, "event_lost")
	assert_eq(_keys(p)[0], "ev_lost", str(_keys(p)))
	assert_true(_speakers(p)[0] in ["elin", "gorm"])
	assert_true(String(p.homecoming.remarks[0].text).contains("Mässan hölls"))
	assert_true(String(p.homecoming.remarks[0].text).contains("vänd") or String(p.homecoming.remarks[0].text).contains("tillbaka"),
			"säger att det går att vända")
	assert_true(p.homecoming.summary.size() >= 1)
	assert_eq(String(p.chronicle[-1].world.event_end.result), "lost")
	assert_true(Chronicle.entry_body(p, _data, p.chronicle[-1]).contains("hann inte stoppas"))


func test_won_event_and_cost_and_gift_speakers() -> void:
	var p := Profile.new()
	Chronicle.demo_home(p, _data, "event_won")
	assert_eq(_keys(p)[0], "ev_won")
	assert_eq(_speakers(p)[0], "hedda")
	assert_true(WorldEvents.merchant_here(p), "den tacksamma handelsmannen")
	var q := Profile.new()
	Chronicle.demo_home(q, _data, "cost")
	assert_true(_keys(q).has("cost_on"), str(_keys(q)))
	var i := _keys(q).find("cost_on")
	assert_eq(_speakers(q)[i], "hedda", "Hedda säger att järnet inte kommer fram")
	assert_true(String(q.homecoming.remarks[i].text).contains("lunden"))
	var r := Profile.new()
	Chronicle.demo_home(r, _data, "gift")
	assert_true(_keys(r).has("gift"), str(_keys(r)))
	assert_eq(_speakers(r)[_keys(r).find("gift")], "tor")
	var s := Profile.new()
	Chronicle.demo_home(s, _data, "start")
	assert_true(_keys(s).has("ev_start"), str(_keys(s)))
	assert_true(not WorldEvents.active(s).is_empty())


func test_loss_consoles_first_then_world_then_concrete_advice() -> void:
	var p := Profile.new()
	Chronicle.demo_home(p, _data, "loss")
	var keys := _keys(p)
	assert_true(keys[0] in Chronicle.CONSOLE_KEYS, "tröst först: " + str(keys))
	assert_eq(keys[-1], "advice", "rådet sist: " + str(keys))
	var adv: Dictionary = p.homecoming.remarks[-1]
	assert_true(adv.speaker in ["stig", "alrik", "gorm"])
	match String(adv.speaker):
		"stig":
			assert_true(String(adv.text).contains("Glödgraven"), adv.text)
		"alrik":
			assert_true(String(adv.text).contains("Lansspetsen"), adv.text)
	assert_eq(keys.filter(func(k: String) -> bool: return k == "advice").size(), 1, "högst ett råd")
	# Rådet ur datan: Stig nämner mötet, Alrik en ägd trofé som svarar på fienden, Gorm ett lägre djup.
	assert_eq(Chronicle.answering_trophy(p, _data, "crypt_2"), "lance_tip")
	var e: Dictionary = p.chronicle[-1].duplicate()
	var kinds := {}
	for streak in [2, 3, 4]:
		p.chron_stats.loss_streak = streak
		kinds[String(Chronicle.advice_event(p, _data, e).advice)] = true
	assert_true(kinds.has("practice") and kinds.has("trophy"), str(kinds))
	e.depth = 3
	p.chron_stats.loss_streak = 4
	assert_eq(int(Chronicle.advice_event(p, _data, e).djup), 2)
	# Efter en enda förlust inget råd.
	p.chron_stats.loss_streak = 1
	assert_true(Chronicle.advice_event(p, _data, e).is_empty())


func test_loss_with_forfeit_and_home_still_meets_someone() -> void:
	for outcome in ["loss", "forfeit", "home"]:
		var p := _profile(["crypt", "chapel"])
		Chronicle.simulate(p, _data, {"party": PARTY, "outcome": outcome, "map": true})
		assert_true(not p.homecoming.remarks.is_empty(), outcome)
		assert_true(p.homecoming.remarks.size() <= Chronicle.MAX_REMARKS)


static func _crypt_calm_line(l: Dictionary) -> bool:
	if l.key != "map_down" or String(l.get("realm", "crypt")) != "crypt" or l.has("min_streak"):
		return false
	var st: Variant = l.get("step", [0, 1])
	return st is Array and int(st[0]) == 0


func test_map_down_lines_are_concrete_and_do_not_repeat() -> void:
	var p := _profile(["crypt", "chapel"])
	var pool: Array = _data.dialog.chronicle.lines.filter(_crypt_calm_line)
	var seen: Array = []
	var entry := {"n": 1, "party": PARTY, "realm": "crypt", "outcome": "boss"}
	var ev := {"key": "map_down", "prio": 41, "realm": "crypt", "step": 0, "antal": 1}
	for i in pool.size():
		entry.n = i
		var r := Chronicle.line_for(p, _data, entry, ev)
		assert_true(not seen.has(r.id), "upprepades för tidigt: %s" % r.id)
		seen.append(r.id)
	assert_eq(seen.size(), pool.size())
	# Två gånger i rad i lunden: Svens rad om vägen till byn går före de allmänna.
	var line := Chronicle.line_for(p, _data, {"n": 3, "party": PARTY, "realm": "grove", "outcome": "boss"},
			{"key": "map_down", "prio": 41, "realm": "grove", "step": 1, "antal": 2})
	assert_eq(line.id, "sven_down_grove_streak")
	assert_true(String(line.text).begins_with("Ni har varit i lunden två gånger"), line.text)


func test_ongoing_lines_in_the_keep() -> void:
	var p := _profile()
	p.growth = {"grove": 3}
	assert_true(WorldEvents.ongoing_line(p, _data, "hedda", 0) != "")
	assert_eq(WorldEvents.ongoing_line(p, _data, "alrik", 0), "")
	WorldEvents.start(p, _data, "cult_feast", 4)
	assert_true(WorldEvents.ongoing_line(p, _data, "alrik", 0).contains("högtiden"))


func test_new_lines_have_ids_and_ragnhild_quotes_with_ref() -> void:
	var ids := {}
	for l in _data.dialog.chronicle.lines + _data.dialog.world.ongoing:
		assert_true(not ids.has(l.id), "eget id: %s" % l.id)
		ids[l.id] = true
		if String(l.get("who", "")) == "ragnhild" and String(l.text).begins_with("»"):
			assert_true(l.has("ref"), l.id)
	for id in WorldEvents.event_ids(_data):
		var e := WorldEvents.event_data(_data, id)
		for k in ["name", "realms", "turns", "win", "text", "mark", "win_text", "lose_text"]:
			assert_true(e.has(k), "%s har %s" % [id, k])
		assert_true(_data.dialog.chronicle.lines.any(func(l: Dictionary) -> bool:
				return l.key == "ev_start" and String(l.get("event", "")) == id), "%s har en startreplik" % id)
		assert_true(_data.dialog.chronicle.lines.any(func(l: Dictionary) -> bool:
				return l.key == "ev_lost" and String(l.get("event", "")) == id), "%s har en replik när den inte stoppas" % id)


func test_after_three_losses_only_comfort_and_advice() -> void:
	var q := _profile(["crypt", "chapel"])
	q.chron_stats.loss_streak = 2
	q.growth = {"crypt": 2, "chapel": 2}
	q.add_trophy("lance_tip")
	Chronicle.simulate(q, _data, {"party": PARTY, "outcome": "loss", "map": true, "lost_to": "crypt_2", "wins": 2})
	for k in _keys(q):
		assert_true(k in Chronicle.CONSOLE_KEYS or k == "advice", "bara tröst och råd: " + str(_keys(q)))
	assert_true(_keys(q).has("advice"))


func test_forfeit_is_never_phrased_as_a_loss_and_names_once_per_box() -> void:
	for i in 4:
		var p := _profile(["crypt", "chapel"])
		Chronicle.simulate(p, _data, {"party": PARTY, "outcome": "forfeit", "map": true})
		var r: Dictionary = p.homecoming.remarks[0]
		if r.key == "lost":
			assert_true(String(r.id).ends_with("_forfeit"), r.id)
	# {namn} högst en gång i en hemkomst, i alla demofall.
	for kind in ["fell", "boss3", "rare", "depth", "event_lost", "event_won", "start", "loss", "cost", "gift"]:
		var q := Profile.new()
		q.set_hero_name("Tran")
		Chronicle.demo_home(q, _data, kind)
		var named: Array = q.homecoming.remarks.filter(func(x: Dictionary) -> bool: return String(x.text).contains("Tran"))
		assert_true(named.size() <= 1, "%s: %s" % [kind, str(q.homecoming.remarks)])
