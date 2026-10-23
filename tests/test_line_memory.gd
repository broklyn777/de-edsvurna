extends "res://tests/test_case.gd"
## Replikminnet (levande repliker steg 1–3, docs/research/levande-repliker.md §5): grottans repliker minns mellan
## körningarna (Profile.said), nyheter i borgen vilar efter ett par gånger, och en nedstigning har en budget.

var _data := GameData.load_all()


func _profile(n: int) -> Profile:
	var p := Profile.new()
	p.intro_done = true
	p.descents = {"crypt": n}
	return p


## En testdata med en talare och en egen pool, så att vilan går att räkna exakt.
func _toy(lines: Array) -> Dictionary:
	return {"dialog": {"barks": {"imma": {"cave": lines}}, "pairs": []}}


func test_line_key_uses_id_or_a_stable_hash() -> void:
	assert_eq(Dialog.line_key({"id": "imma_cave_1", "text": "x"}), "imma_cave_1")
	assert_eq(Dialog.line_key("Mörkt här."), Dialog.line_key("Mörkt här."), "samma text ger samma nyckel")
	assert_true(Dialog.line_key("Mörkt här.") != Dialog.line_key("Ljust här."))
	assert_eq(Dialog.line_key({"text": "Mörkt här."}), Dialog.line_key("Mörkt här."), "en replik utan id: texten")


func test_barks_remember_across_descents() -> void:
	var lines := []
	for i in 6:
		lines.append({"id": "l%d" % i, "text": "rad %d" % i})
	var data := _toy(lines)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var p := _profile(1)
	var order: Array = []
	# Sex repliker, vila min(10, 2 × 6) = 10: varje nedstigning säger en ny tills alla är sagda.
	for n in range(1, 7):
		p.descents = {"crypt": n}
		var b := Dialog.bark(data, "cave", ["paladin", "imma"], [], rng, p, false)
		var t: String = b.lines[0].text
		assert_true(not order.has(t), "nedstigning %d: ny replik (%s)" % [n, t])
		order.append(t)
	# Nedstigning 7–10: alla vilar, tystnad. Nedstigning 11: den första har vilat 10.
	for n in range(7, 11):
		p.descents = {"crypt": n}
		assert_true(Dialog.bark(data, "cave", ["paladin", "imma"], [], rng, p, false).is_empty(), "nedstigning %d: tyst" % n)
	p.descents = {"crypt": 11}
	var b11 := Dialog.bark(data, "cave", ["paladin", "imma"], [], rng, p, false)
	assert_eq(b11.lines[0].text, order[0], "den som vilat längst")
	p.descents = {"crypt": 12}
	assert_true(not Dialog.bark(data, "cave", ["paladin", "imma"], [], rng, p, true).is_empty(), "starka lägen tystnar inte")


func test_silence_when_all_lines_rest() -> void:
	var data := _toy([{"id": "a", "text": "A"}, {"id": "b", "text": "B"}, {"id": "c", "text": "C"}])
	var rng := RandomNumberGenerator.new()
	var p := _profile(5)
	for k in ["a", "b", "c"]:
		p.note_said(k, 4)  # vila 6 för en pool på 3; alla sades förra nedstigningen
	assert_true(Dialog.bark(data, "cave", ["paladin", "imma"], [], rng, p, false).is_empty(), "vanligt läge: tystnad")
	var b := Dialog.bark(data, "cave", ["paladin", "imma"], [], rng, p, true)
	assert_true(not b.is_empty(), "starkt läge: den som vilat längst")
	p.descents = {"crypt": 10}
	assert_true(not Dialog.bark(data, "cave", ["paladin", "imma"], [], rng, p, false).is_empty(), "efter vilan igen")


func test_optional_fields_once_cooldown_chance() -> void:
	var rng := RandomNumberGenerator.new()
	var p := _profile(1)
	var once := _toy([{"id": "o", "text": "O", "once": true}])
	assert_true(not Dialog.bark(once, "cave", ["imma"], [], rng, p).is_empty())
	p.descents = {"crypt": 50}
	assert_true(Dialog.bark(once, "cave", ["imma"], [], rng, p).is_empty(), "once: aldrig igen")
	var cd := _toy([{"id": "c", "text": "C", "cooldown": 3}, {"id": "d", "text": "D", "cooldown": 3}])
	p.note_said("c", 49)
	p.note_said("d", 48)
	assert_true(Dialog.bark(cd, "cave", ["imma"], [], rng, p, false).is_empty(), "cooldown 3: båda vilar")
	p.descents = {"crypt": 51}
	assert_eq(Dialog.bark(cd, "cave", ["imma"], [], rng, p, false).lines[0].text, "D", "D har vilat 3")
	var never := _toy([{"id": "z", "text": "Z", "chance": 0.0}])
	assert_true(Dialog.bark(never, "cave", ["imma"], [], rng, p).is_empty(), "chance 0")


func test_no_repeat_within_a_run_still_holds_with_memory() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var p := _profile(3)
	var used: Array = []
	var seen := {}
	for i in 30:
		var b := Dialog.bark(_data, "campfire", ["paladin", "imma", "alva", "brokk"], used, rng, p)
		if b.is_empty():
			break
		var t: String = b.lines[0].text
		assert_true(not seen.has(t), "inget upprepas i körningen: " + t)
		seen[t] = true
	assert_true(seen.size() >= 4, "flera repliker sägs")
	assert_true(used.all(func(k: String) -> bool: return not k.contains(" ")), "used håller nycklar, inte texter")


func test_budget_per_descent() -> void:
	var s := RunState.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var said := 0
	for room in 40:
		s.rooms_entered += 1
		if s.bark_allowed("campfire", rng):
			s.note_bark()
			said += 1
	assert_eq(said, RunState.BARK_BUDGET, "högst fem per nedstigning")
	s.rooms_entered += 2
	assert_true(s.bark_allowed("boss", rng), "starka lägen går före budgeten")
	var t := RunState.new()
	t.rooms_entered = 3
	t.note_bark()
	assert_true(not t.bark_allowed("campfire", rng), "inte i samma rum")
	t.rooms_entered = 4
	assert_true(not t.bark_allowed("campfire", rng), "inte i nästa rum")
	assert_true(t.bark_allowed("fallen", rng), "utom när någon har fallit")
	t.rooms_entered = 5
	var ok := false
	for i in 20:
		ok = ok or t.bark_allowed("campfire", rng)
	assert_true(ok, "två rum senare igen")
	var r := RunState.from_dict(t.to_dict())
	assert_eq([r.barks_said, r.bark_room, r.rooms_entered], [1, 3, 5], "budgeten sparas med körningen")


func test_news_rests_after_two_tellings() -> void:
	var data := {"dialog": {"people": {"gorm": {"idle": [
		{"id": "news", "text": "NYHET", "when": {"min_descents": 1}},
		{"id": "once", "text": "EN GÅNG", "when": {"min_descents": 1}, "once": true},
		{"id": "g1", "text": "G1"}, {"id": "g2", "text": "G2"}, {"id": "g3", "text": "G3"}]}}}}
	var p := _profile(1)
	var said: Array = []
	for turn in 6:
		said.append(Dialog.idle_line(data, p, "gorm", turn))
	assert_eq(said[0], "NYHET", "nyheten först efter hemkomsten")
	assert_true(not said.slice(1).has("NYHET") and not said.slice(1).has("EN GÅNG"), "högst en nyhet per hemkomst")
	for i in range(1, said.size()):
		assert_true(said[i] != said[i - 1], "aldrig samma två gånger i rad")
	p.descents = {"crypt": 2}
	assert_eq(Dialog.idle_line(data, p, "gorm", 0), "EN GÅNG", "nästa hemkomst: den osagda nyheten")
	p.descents = {"crypt": 3}
	assert_eq(Dialog.idle_line(data, p, "gorm", 0), "NYHET", "andra gången")
	for n in range(4, 9):
		p.descents = {"crypt": n}
		var t := Dialog.idle_line(data, p, "gorm", 0)
		assert_true(t != "NYHET" and t != "EN GÅNG", "nyheterna vilar sedan (%s)" % t)


func test_old_profile_loads_with_empty_memory() -> void:
	var path := "user://test_line_memory.cfg"
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "silver", 10)
	cfg.save(path)
	var p := Profile.load_from(path)
	assert_eq([p.said, p.said_times, p.last_idle], [{}, {}, {}], "en gammal profil har inget minne")
	p.note_said("imma_cave_1", 4)
	p.save(path)
	var q := Profile.load_from(path)
	assert_eq(int(q.said.get("imma_cave_1", -1)), 4, "minnet sparas")
	assert_eq(q.times_said("imma_cave_1"), 1)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
