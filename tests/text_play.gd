extends RefCounted
## Textspel (provspel för agenter och människor utan skärm): spelets riktiga logik (Profile, RunState, Grotto, CombatSim,
## MacroRunner) ett drag i taget. Varje anrop läser läget ur en mapp, visar skärmen som text, tar ETT kommando, sparar
## och slutar. Allt som visas och varje kommando skrivs också till <mapp>/log.txt (för provspelsloggen).
## Flödet är samma som tests/soak.gd (Run utan noder): grottan, kortet, striden med makron (AUTO), lägret, hem.
## Körs med tests/textplay_cli.gd:
##   godot --headless --path . --script res://tests/textplay_cli.gd -- --dir=/tmp/tp new     (en profil mitt i spelet)
##   godot --headless --path . --script res://tests/textplay_cli.gd -- --dir=/tmp/tp look
##   godot --headless --path . --script res://tests/textplay_cli.gd -- --dir=/tmp/tp go d5
## Kommandon: help visar dem för läget man står i.

const RunScript := preload("res://scripts/game/run.gd")
const COLS := "abcdefgh"

var data: Dictionary
var dir := ""
var profile: Profile
var state: RunState
var meta := {}
var macros := {}
var rng := RandomNumberGenerator.new()
var out: Array[String] = []


## Kör ett kommando mot läget i mappen och returnerar skärmens text ("" och ett fel i texten om inget läge finns).
func execute(at_dir: String, cmd: String) -> String:
	data = GameData.load_all()
	dir = at_dir
	out = []
	DirAccess.make_dir_recursive_absolute(dir)
	cmd = cmd.strip_edges()
	if cmd == "":
		cmd = "look"
	show_legend = cmd in ["look", "start", "help"]
	if cmd.begins_with("new"):
		_new_profile(int(cmd.get_slice(" ", 1)) if cmd.contains(" ") else 7)
	elif not _load():
		return "Inget sparat läge i %s. Börja med kommandot new." % dir
	else:
		_command(cmd)
	_screen()
	_save()
	var text := "\n".join(out)
	var log_path := dir.path_join("log.txt")
	var f := FileAccess.open(log_path, FileAccess.READ_WRITE if FileAccess.file_exists(log_path) else FileAccess.WRITE)
	if f:
		f.seek_end()
		f.store_string("\n>>> %s\n%s\n" % [cmd, text])
		f.close()
	return text


# --- Läget på disk -------------------------------------------------------------

func _path(name: String) -> String:
	return dir.path_join(name)


func _load() -> bool:
	if not FileAccess.file_exists(_path("meta.json")):
		return false
	meta = JSON.parse_string(FileAccess.get_file_as_string(_path("meta.json")))
	profile = Profile.load_from(_path("profile.cfg"))
	macros = meta.get("macros", data.macros.duplicate(true))
	rng.seed = int(meta.get("seed", 1))
	rng.state = int(meta.get("rng", 1))
	if meta.get("mode", "home") != "home":
		state = RunState.load_from(_path("run.cfg"))
		if state == null:
			meta.mode = "home"
		else:
			state.owned_heroes = profile.recruited.size() + 1
			state.party_slots = profile.party_slots()
	if profile != null:
		data.heroes.paladin.name = profile.hero_name  # Run.apply_name
	return profile != null


func _save() -> void:
	meta.macros = macros
	meta.rng = rng.state
	var f := FileAccess.open(_path("meta.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(meta, " "))
	f.close()
	profile.save(_path("profile.cfg"))
	if state != null and meta.get("mode", "home") != "home":
		state.save(_path("run.cfg"))


## En profil mitt i spelet: fyra hjältar på nivå 10–12, artefakter, troféer, kryptan djup 1–3 och kapellet 1–2 klarade.
func _new_profile(seed_value: int) -> void:
	for f in ["meta.json", "profile.cfg", "run.cfg", "log.txt"]:
		if FileAccess.file_exists(_path(f)):
			DirAccess.remove_absolute(_path(f))
	rng.seed = seed_value
	profile = Profile.new()
	profile.intro_done = true
	profile.intro_step = Intro.steps(data).size()
	profile.hero_name = "Arn"
	profile.oath = "oath_vengeance"
	for h in ["imma", "alva", "brokk", "eira", "solveig", "tove"]:
		profile.recruit(data, h, 10.0)
	profile.set_party(["brokk", "alva", "eira"])
	var levels := {"paladin": 12, "brokk": 11, "alva": 11, "eira": 10, "imma": 9, "solveig": 8, "tove": 7}
	for h in levels:
		var hero := profile.hero(data, h)
		hero.level = levels[h]
		hero.xp = 0
	var arts := {"paladin": ["sword", "holy_smite", 5], "brokk": ["shield", "", 4], "alva": ["staff", "", 4],
			"eira": ["boots", "", 3]}
	for h in arts:
		var a: Array = arts[h]
		var abil: String = a[1]
		if abil == "":
			abil = data.heroes[h].abilities[0]
		profile.artifacts[h] = Forge.normalize({"type": a[0], "ability": abil, "level": a[2]})
	var worn := {"paladin": "", "brokk": "", "alva": "", "eira": ""}
	var have: Array[String] = []
	for kind in ["skeleton_warrior", "grave_warden", "grave_priest", "skeleton_archer", "coffin_bearer", "cultist",
			"wraith", "fallen_knight", "witch", "bone_runner"]:
		have.append(String(data.enemies[kind].trophy))
	for t in have:
		profile.add_trophy(t)
	profile.wear("paladin", String(data.enemies.skeleton_warrior.trophy))
	profile.wear("brokk", String(data.enemies.grave_warden.trophy))
	profile.wear("alva", String(data.enemies.grave_priest.trophy))
	profile.wear("eira", String(data.enemies.skeleton_archer.trophy))
	for k in ["crypt:1", "crypt:2", "crypt:3", "chapel:1", "chapel:2"]:
		profile.quests_done.append(k)
	profile.realm_depth = {"crypt": 3, "chapel": 2}
	profile.best_depth = 3
	profile.descents = {"crypt": 6, "chapel": 3}
	profile.boss_wins = {"bone_lich": 1, "fallen_bishop": 1}
	profile.bosses_defeated.assign(["bone_lich", "fallen_bishop"])
	profile.guardian_wins = {"crypt_g1": 1, "crypt_g2": 1, "chapel_g1": 1}
	for p in ["vengeance_wrath", "vengeance_zeal", "vengeance_divine_toll"]:
		profile.buy_perk(data, "oath_vengeance", p)
	profile.silver = 420
	profile.realm = "crypt"
	profile.depth = 2
	profile.room_moments = false
	macros = data.macros.duplicate(true)
	meta = {"mode": "home", "seed": seed_value, "descent": 0}
	rng.seed = seed_value
	out.append("Ny profil skapad: %s, Domens kall, fyra hjältar på nivå 10–12, kryptan djup 3 och kapellet djup 2 klarade." % profile.hero_name)


# --- Kommandon -----------------------------------------------------------------

func _command(cmd: String) -> void:
	var w := cmd.split(" ", false)
	var c := w[0]
	if c in ["look", "l"]:
		return
	if c == "help":
		_help()
		return
	if c == "hero":
		_hero_sheet(w[1] if w.size() > 1 else "paladin")
		return
	if c == "macro":
		_macro_cmd(w)
		return
	if c == "trophies":
		_list_trophies()
		return
	match String(meta.get("mode", "home")):
		"home":
			_home_cmd(w)
		"grotto":
			_grotto_cmd(w)
		"dialog":
			_dialog_cmd(w)
		"camp":
			_camp_cmd(w)


func _help() -> void:
	out.append("Alltid: look, hero <id>, macro <id> [add <rad> <subjekt> <villkor>[=värde] <handling>[:förmåga] [mål] | del <rad> | move <från> <till>], trophies")
	match String(meta.get("mode", "home")):
		"home":
			out.append("Hemma: realm <crypt|chapel>, depth <n>, party <id,id,id>, smith <id> (höj artefakten), socket <id> <plats> <bärnsten>, arttrophy <id> <trofé>, perk <id>, perkreset, wear <hjälte> <trofé|none>, start")
		"grotto":
			out.append("Grottan: go <ruta> (t.ex. go d5) eller go n|s|e|w, fight, back, swap <hjälte> <trofé|none> (vid lägereld), camp (lägereldens val igen), leave (gå hem)")
		"dialog":
			out.append("Ruta: choose <n>")
		"camp":
			out.append("Efter striden: take <n> (en trofé till körningen) eller skip")


func _hero_id(s: String) -> String:
	s = s.to_lower()
	for id in data.heroes:
		if id == s or String(data.heroes[id].name).to_lower().begins_with(s):
			return id
	return ""


func _trophy_id(s: String) -> String:
	if data.traits.has(s):
		return s
	for t in profile.collection + (Array(state.trophies) if state != null else []):
		if String(data.traits[t].name).to_lower().replace(" ", "_") == s.to_lower() or t == s:
			return t
	return ""


# Hemma ------------------------------------------------------------------------

func _home_cmd(w: PackedStringArray) -> void:
	match w[0]:
		"realm":
			if w.size() > 1 and data.realms.has(w[1]) and RunState.realm_open(profile, data, w[1]):
				profile.realm = w[1]
				profile.depth = mini(profile.depth, int(profile.realm_depth.get(w[1], 0)) + 1)
				out.append("Realm: %s." % data.realms[w[1]].name)
			else:
				out.append("Den Realmen går inte att välja.")
		"depth":
			var d := int(w[1]) if w.size() > 1 else 1
			var top := int(profile.realm_depth.get(profile.realm, 0)) + 1
			if d < 1 or d > top:
				out.append("Djup %d går inte (högst %d i %s)." % [d, top, data.realms[profile.realm].name])
			else:
				profile.depth = d
				out.append("Djup %d valt." % d)
		"party":
			var ids: Array = []
			for s in (w[1] if w.size() > 1 else "").split(","):
				var id := _hero_id(s)
				if id != "" and id != "paladin":
					ids.append(id)
			profile.set_party(ids)
			out.append("Sällskap: %s." % ", ".join(profile.party.map(func(id: String) -> String: return data.heroes[id].name)))
		"smith":
			var id := _hero_id(w[1] if w.size() > 1 else "")
			var cost := profile.artifact_level_cost(id) if id != "" else 0
			if cost <= 0:
				out.append("Ingen artefakt att höja.")
			elif profile.silver < cost:
				out.append("Silvret räcker inte (%d behövs)." % cost)
			else:
				var res: Variant = profile.level_artifact(id)
				out.append("Smeden Hedda höjer %ss artefakt till nivå %d (−%d silver). %s" % [data.heroes[id].name,
						int(profile.artifact(id).level), cost, Forge.unlock_text(int(profile.artifact(id).level))])
		"perk":
			var pid := w[1] if w.size() > 1 else ""
			if profile.buy_perk(data, profile.oath, pid):
				out.append("Perken %s köpt." % data.traits[pid].name)
			else:
				out.append("Det gick inte (poäng eller nivå).")
		"socket":
			# socket <hjälte> <plats 1–2> <bärnsten>: en stat-plats i artefakten (5 bärnsten per plats).
			var id := _hero_id(w[1] if w.size() > 1 else "")
			if id != "" and w.size() > 3 and profile.socket(id, "stat", int(w[2]) - 1, w[3]):
				out.append("%s sitter nu i %ss artefakt." % [data.materials.amber.get(w[3], {}).get("name", w[3]), data.heroes[id].name])
			else:
				out.append("Det gick inte (platsen stängd, eller för lite bärnsten: %d behövs)." % Forge.AMBER_PER_SLOT)
		"arttrophy":
			var id := _hero_id(w[1] if w.size() > 1 else "")
			var t := _trophy_id(w[2]) if w.size() > 2 else ""
			if id != "" and t != "" and profile.set_artifact_trophy(id, t):
				out.append("%s sitter nu i %ss artefakt (troféplatsen)." % [data.traits[t].name, data.heroes[id].name])
			else:
				out.append("Det gick inte (troféplatsen öppnas på nivå %d)." % Forge.TROPHY_LEVEL)
		"trick":
			# trick <hjälte> <plats 1–2> <trick>: en trick-plats i artefakten (tricket förstörs om det tas ut).
			var id := _hero_id(w[1] if w.size() > 1 else "")
			if id != "" and w.size() > 3 and profile.socket(id, "trick", int(w[2]) - 1, w[3]):
				out.append("%s sitter nu i %ss artefakt." % [data.materials.tricks.get(w[3], {}).get("name", w[3]), data.heroes[id].name])
			else:
				out.append("Det gick inte (platsen stängd eller tricket saknas).")
		"perkreset":
			out.append("Perkarna återställda: %d poäng tillbaka." % profile.reset_perks(data, profile.oath))
		"wear":
			var id := _hero_id(w[1] if w.size() > 1 else "")
			var t := "" if w.size() < 3 or w[2] == "none" else _trophy_id(w[2])
			if id == "" or (w.size() > 2 and w[2] != "none" and t == ""):
				out.append("Okänd hjälte eller trofé.")
			else:
				profile.wear(id, t)
				out.append("%s bär nu %s." % [data.heroes[id].name, data.traits[t].name if t != "" else "ingen trofé"])
		"start":
			_start_run()
		_:
			out.append("Okänt kommando här. Skriv help.")


func _start_run() -> void:
	state = RunState.new_run(profile, data)
	state.instability = profile.instability
	var rules := RunState.roll_rules(data, profile.instability, rng)
	state.rules_visible = rules.visible.duplicate()
	state.rules_hidden = rules.hidden.duplicate()
	state.start_expedition(data, rng.randi() % 1000000 + 1)
	WorldEvents.begin_run(profile, state)
	state.first_descent = false
	var seen := int(profile.descents.get(state.realm, 0))
	profile.descents[state.realm] = seen + 1
	profile.count_home_runs()
	meta.mode = "grotto"
	meta.descent = int(meta.get("descent", 0)) + 1
	meta.battles = 0
	out.append("=== Nedstigning %d: %s, djup %d ===" % [meta.descent, data.realms[state.realm].name, state.depth])
	var g := RunState.guardian_for(data, state.realm, state.depth)
	if g != "":
		out.append("(Djupets väktare: %s)" % data.encounters[g].get("name", g))
	_bark("new_realm" if seen == 0 else "cave")


# Grottan ----------------------------------------------------------------------

func _cell_index(s: String) -> int:
	s = s.to_lower()
	if s in ["n", "s", "e", "w"]:
		var p: Vector2i = Grotto.xy(state.pos) + {"n": Vector2i(0, -1), "s": Vector2i(0, 1), "e": Vector2i(1, 0), "w": Vector2i(-1, 0)}[s]
		if p.x < 0 or p.y < 0 or p.x >= Grotto.SIZE or p.y >= Grotto.SIZE:
			return -1
		return Grotto.idx(p)
	if s.length() < 2 or not COLS.contains(s[0]):
		return -1
	var x := COLS.find(s[0])
	var y := int(s.substr(1)) - 1
	if y < 0 or y >= Grotto.SIZE:
		return -1
	return Grotto.idx(Vector2i(x, y))


func _cell_name(i: int) -> String:
	var p := Grotto.xy(i)
	return "%s%d" % [COLS[p.x], p.y + 1]


const STEP_REASONS := {"here": "ni står redan där", "group": "en grupp står i vägen: anfall eller backa",
		"locked": "målet är låst tills questen är klar", "blocked": "en sedd grupp spärrar rutan",
		"far": "för långt bort (inte intill det ni sett)", "path": "ingen väg dit genom kända rutor"}


func _grotto_cmd(w: PackedStringArray) -> void:
	match w[0]:
		"go":
			# go <ruta> [<ruta> …]: flera tryck i rad; stannar när något händer (en grupp, en ruta med val).
			for k in range(1, maxi(w.size(), 2)):
				var i := _cell_index(w[k] if w.size() > k else "")
				var why := state.can_step(i) if i >= 0 else "far"
				if why != "":
					out.append("Det går inte: %s." % STEP_REASONS.get(why, why))
					return
				var was_new := not state.visited.has(i)
				var walk := state.step(i)
				out.append("Ni går till %s%s." % [_cell_name(i), " (%d steg)" % walk.size() if walk.size() > 1 else ""])
				_arrive(was_new)
				if meta.mode != "grotto" or state.at_group():
					return
		"back":
			if state.back():
				out.append("Ni backar till %s. Gruppen står kvar och spärrar rutorna intill sig." % _cell_name(state.pos))
				_bark("back")
			else:
				out.append("Det finns inget att backa från.")
		"fight":
			if not state.at_group():
				out.append("Här finns ingen grupp.")
				return
			_fight()
		"swap":
			if state.current_room().get("kind", "") != "campfire":
				out.append("Troféer byts bara vid en lägereld.")
				return
			var id := _hero_id(w[1] if w.size() > 1 else "")
			var t := "" if w.size() < 3 or w[2] == "none" else _trophy_id(w[2])
			if id == "" or not state.party.has(id) or (w.size() > 2 and w[2] != "none" and not state.trophies.has(t)):
				out.append("Okänd hjälte, eller trofén finns inte bland körningens troféer.")
				return
			state.equip(id, t)
			profile.keep_worn(state.equipped, state.party)
			out.append("%s bär nu %s." % [data.heroes[id].name, data.traits[t].name if t != "" else "ingen trofé"])
		"camp":
			if state.current_room().get("kind", "") == "campfire":
				_campfire_dialog(state.current_room())
		"stairs":
			if state.current_room().get("kind", "") == "stairs" and state.floor_cleared():
				_arrive(false)
		"leave":
			out.append("Ni går hem. Körningen och questens belöning går förlorade; det ni har vunnit finns kvar.")
			_end_descent("home")
		_:
			out.append("Okänt kommando här. Skriv help.")


## Rutans innehåll när pjäsen kommer fram (room_map_screen._arrive).
func _arrive(was_new: bool) -> void:
	var r := state.current_room()
	if state.at_group():
		if r.get("boss", false) or r.get("kind", "") == "end":
			_bark("boss")
		elif r.get("elite", false) or r.get("nemesis", false):
			_bark("elite")
		return
	var kind: String = r.get("kind", "empty")
	var fresh: bool = not r.get("done", false) and not r.get("rescued", false)
	if kind == "stairs" and state.floor_cleared():
		_dialog("Trappan", "Questen är klar. Trappan leder ned till våning %d." % (state.floor + 2),
				[{"label": "GÅ NED", "act": "descend"}, {"label": "STANNA KVAR"}])
		return
	if kind == "object" and r.get("again", false):
		_object_dialog(r)
		return
	if not kind in ["treasure", "shrine", "campfire", "prisoner", "object"] or (kind != "campfire" and not fresh):
		return
	match kind:
		"campfire":
			_campfire_dialog(r)
		"treasure":
			_dialog("Skatt", _treasure(), [{"label": "VIDARE"}])
		"prisoner":
			_rescue()
		"shrine":
			var opts := state.shrine_options(data, rng)
			var options := []
			for o in opts:
				options.append({"label": RunState.shrine_text(data, o) + " – " + state.shrine_detail(data, o), "act": "shrine",
						"shrine": o})
			_dialog("Helgedom", "Välj en gåva – eller låt Pandemonium avgöra.", options)
		"object":
			_object_dialog(r)


func _campfire_dialog(r: Dictionary) -> void:
	if not r.get("done", false):
		_dialog("Lägereld", "Elden sprakar. Att vila ger +%d Charges på varje förmåga, en gång. Troféerna kan ni byta här när som helst (swap <hjälte> <trofé>)." % RunState.CAMPFIRE_CHARGES,
				[{"label": "VILA", "act": "rest"}, {"label": "SENARE"}])
	else:
		out.append("Lägereld: elden brinner fortfarande. Här kan ni byta troféer (swap <hjälte> <trofé>).")


func _object_dialog(r: Dictionary) -> void:
	var def: Dictionary = data.get("objects", {}).get(r.get("obj", ""), {})
	var text: String = def.get("again", def.get("text", "")) if r.get("again", false) else def.get("text", "")
	var options := []
	for o in state.object_options(data):
		if o.get("disabled", false):
			text += " (Ett val går inte: %s)" % String(o.get("disabled_text", ""))
			continue
		options.append({"label": o.label, "act": "object", "obj": o.id})
	if not options.any(func(o: Dictionary) -> bool: return String(o.get("obj", "")) in ["leave", "none", "skip"] or String(o.label).begins_with("LÅT")):
		options.append({"label": "LÅT DET VARA"})
	_dialog(def.get("name", "Föremål"), text, options)


func _dialog(title: String, text: String, options: Array) -> void:
	meta.dialog = {"title": title, "text": text, "options": options}
	meta.mode = "dialog"


func _dialog_cmd(w: PackedStringArray) -> void:
	if w[0] != "choose" or w.size() < 2:
		# Ett annat kommando stänger rutan (som att trycka bredvid den) och gäller i grottan.
		meta.mode = "grotto"
		meta.erase("dialog")
		_grotto_cmd(w)
		return
	var options: Array = meta.dialog.options
	var n := int(w[1]) - 1
	if n < 0 or n >= options.size():
		out.append("Inget sådant val.")
		return
	var o: Dictionary = options[n]
	meta.mode = "grotto"
	meta.erase("dialog")
	out.append("Val: %s" % o.label)
	match String(o.get("act", "")):
		"descend":
			_descend()
		"rest":
			var gained := state.campfire(data)
			out.append("Lägerelden: +%d Charges. Här kan ni byta troféer." % gained)
			_bark("campfire")
		"shrine":
			out.append(state.apply_shrine(data, rng, o.shrine))
			_after_quest_check(false)
		"object":
			var res := state.use_object(data, String(o.obj), rng)
			if int(res.silver) > 0:
				var paid := roundi(res.silver * state.silver_mult(data))
				profile.silver += paid
			if String(res.get("text", "")) != "":
				out.append(String(res.text))
			if res.fight:
				out.append("En grupp står nu på rutan.")
		"hint":
			_add_macro_hint(String(o.hero))
			out.append("Raden lades först i makrot.")


func _descend() -> void:
	var t := state.take_trail(data)
	if not t.is_empty():
		profile.grant_xp(data, state.party, int(t.xp))
		var amount := roundi(float(t.silver) * state.silver_mult(data))
		profile.silver += amount
		out.append("Spåren efter %d grupper ni lät vara: +%d erfarenhet, +%d silver." % [t.groups, t.xp, amount])
	state.next_floor(data)
	out.append("Ni går ned till våning %d." % (state.floor + 1))
	_bark("cave")


func _treasure() -> String:
	var t := state.treasure(data, rng)
	var amount := roundi(t.silver * state.silver_mult(data))
	profile.silver += amount
	var text := "Skattkammaren: +%d silver" % amount
	if t.trophy != "":
		profile.add_trophy(t.trophy)
		state.take_trophy(t.trophy)
		text += " och trofén %s!" % data.traits[t.trophy].name
	var finds := _roll_finds("treasure" if not state.current_room().get("guarded", false) else "portal_battle")
	if not finds.is_empty():
		text += "\nFynd: " + ", ".join(finds.map(func(f: Dictionary) -> String: return Forge.find_text(data, f)))
	_bark("treasure")
	return text


func _roll_finds(kind: String) -> Array:
	var finds := Forge.roll_finds(data, kind, state.depth, state.depth > profile.best_depth, state.instability, rng,
			profile.next_stone_id, state.growth)
	for f in finds:
		if f.kind == "nether":
			profile.next_stone_id += 1
		state.found[f.kind] = int(state.found.get(f.kind, 0)) + int(f.get("count", 1))
	profile.add_finds(finds)
	return finds


func _rescue() -> void:
	var r := state.current_room()
	var hero_id: String = r.get("hero", "")
	if hero_id == "" or r.get("rescued", false):
		return
	r.rescued = true
	state.prisoners.erase(str(state.floor))
	var avg := 0.0
	for id in state.party:
		avg += float(profile.hero(data, id).level)
	avg /= maxi(state.party.size(), 1)
	profile.recruit(data, hero_id, avg)
	state.owned_heroes = profile.recruited.size() + 1
	var h: Dictionary = data.heroes[hero_id]
	var text := "%s befrias! %s." % [h.name, h.get("title", "")]
	if state.party.size() < state.party_slots:
		state.party.append(hero_id)
		state.add_charges_for(data, hero_id)
		profile.set_party(state.party.slice(1))
		text += " Följer med direkt (nivå %d)." % int(profile.hero(data, hero_id).level)
	else:
		text += " Sällskapet är fullt – väntar i Värdshuset."
	_bark("rescue")
	var options: Array = [{"label": "VÄLKOMMEN!"}]
	var hint: Dictionary = data.heroes.get(hero_id, {}).get("macro_hint", {})
	if not hint.is_empty():
		text += "\nNy makrorad? " + String(hint.text)
		options = [{"label": "LÄGG TILL RADEN", "act": "hint", "hero": hero_id}, {"label": "INTE NU"}]
	_dialog("En fånge befrias", text, options)


func _add_macro_hint(hero_id: String) -> void:
	var hint: Dictionary = data.heroes.get(hero_id, {}).get("macro_hint", {})
	if hint.is_empty():
		return
	if not macros.has(hero_id):
		macros[hero_id] = {"name": data.heroes[hero_id].name, "lines": []}
	macros[hero_id].lines.insert(0, hint.line.duplicate(true))


func _after_quest_check(just_done: bool) -> void:
	if just_done or (state.quest.get("done", false) and not state.quest.get("rewarded", false)):
		state.quest.rewarded = true
		if not state.is_last_floor():
			out.append("Questen är klar: +%d silver, och trappan är öppen!" % profile.floor_quest_silver(state.depth))
			_bark("stairs")
			return
		var q := profile.complete_quest(state.realm, state.depth)
		state.realm_quest_done = true
		out.append("Questen är klar: +%d silver%s" % [q.silver, " och en perk-poäng!" if q.point else "!"])


func _bark(kind: String) -> void:
	if not state.bark_allowed(kind, rng):
		return
	var b := Dialog.bark(data, kind, state.party, state.barks_used, rng, profile, RunState.STRONG_BARKS.has(kind))
	if b.is_empty():
		return
	state.note_bark()
	for l in b.get("lines", []):
		var who: String = data.heroes.get(String(l.get("who", "")), {}).get("name", String(l.get("who", "")))
		out.append("  %s: ”%s”" % [who, String(l.get("text", "")).replace("{namn}", profile.hero_name)])


# Striden ----------------------------------------------------------------------

func _fight() -> void:
	state.fight()
	if state.current_room().get("elite", false) and not profile.elites_met.has(state.encounter()):
		profile.elites_met.append(state.encounter())
	var opts := state.battle_opts()
	opts.levels = profile.levels_for(data, state.party)
	state.apply_vow(data, opts)
	meta.battles = int(meta.get("battles", 0)) + 1
	var sim := CombatSim.create(data, state.encounter(), rng.randi(), state.party, state.hero_traits(data),
			state.charges, state.artifacts, state.depth, opts)
	sim.begin()
	var labels := _labels(sim)
	var enc: Dictionary = data.encounters[state.encounter()]
	out.append("=== STRID: %s ===" % String(enc.get("name", state.encounter())))
	out.append("Fiender: " + ", ".join(sim.enemies.map(func(u: CombatUnit) -> String:
			return "%s (nivå %d, %d liv)" % [labels[u.id], roundi(u.level), roundi(u.max_hp)])))
	out.append("Sällskap: " + ", ".join(sim.heroes.map(func(u: CombatUnit) -> String:
			return "%s (%d liv)" % [labels[u.id], roundi(u.max_hp)])))
	var log: Array[String] = []
	var line := ""
	var trait_counts := {}
	var guard := 0
	while sim.outcome == "" and guard < 3000:
		guard += 1
		if not sim.needs_input():
			sim.ai_act()
		else:
			var u := sim.current
			var decision := MacroRunner.decide(sim, u, macros.get(u.id, data.macros.get(u.id, {"lines": []})))
			if not (decision.ok and sim.act(decision.action, decision.target, decision.ability) == ""):
				if sim.act("attack") != "" and sim.act("defend") != "":
					sim.forfeit()
		for e in sim.drain_events():
			var s := _event_text(sim, e, labels, trait_counts)
			if e.type == "action":
				if line != "":
					log.append(line)
				line = "T%d %s" % [sim.turn_no, s]
			elif s.begins_with("!!"):
				if line != "":
					log.append(line)
					line = ""
				log.append(s)
			elif s != "":
				line += " | " + s if line != "" else s
	if line != "":
		log.append(line)
	out.append_array(log)
	var won := sim.outcome == "victory"
	out.append("--- %s efter %d turer ---" % ["SEGER" if won else "FÖRLUST", sim.turn_no])
	out.append("Kvar: " + ", ".join(sim.heroes.map(func(u: CombatUnit) -> String:
			return "%s %d/%d" % [labels[u.id], roundi(u.hp), roundi(u.max_hp)] if u.alive else "%s stupad" % labels[u.id])))
	var enemy_traits: Array = []
	for k in trait_counts:
		enemy_traits.append("%s ×%d" % [k, trait_counts[k]])
	if not enemy_traits.is_empty():
		out.append("Fiendernas egenskaper slog till: " + ", ".join(enemy_traits))
	var rows := BattleSummary.deciders(sim)
	if not rows.is_empty():
		out.append("Det här avgjorde striden:")
		for row in rows:
			out.append("  [%s] %s (%s): %s" % [row.tag, row.name, row.who, row.text])
	# battle.gd: dolda regler som slog till blir kända, och elitfienderna lämnar sina troféer.
	for id in sim.rules_triggered:
		if not state.rules_revealed.has(id):
			state.rules_revealed.append(id)
	state.last_elites = sim.enemies.filter(func(e: CombatUnit) -> bool: return e.elite).map(
			func(e: CombatUnit) -> String: return e.kind)
	_award(sim, won)
	state.store_charges(sim)
	_battle_finished(sim, won)


func _labels(sim: CombatSim) -> Dictionary:
	var count := {}
	for u in sim.units:
		count[u.name] = int(count.get(u.name, 0)) + 1
	var seen := {}
	var out_l := {}
	for u in sim.units:
		if int(count[u.name]) > 1:
			seen[u.name] = int(seen.get(u.name, 0)) + 1
			out_l[u.id] = "%s %d" % [u.name, seen[u.name]]
		else:
			out_l[u.id] = u.name
	return out_l


func _event_text(sim: CombatSim, e: Dictionary, labels: Dictionary, trait_counts: Dictionary) -> String:
	var L := func(id: Variant) -> String: return String(labels.get(String(id), String(id)))
	match String(e.type):
		"action":
			var what := ""
			match String(e.action):
				"attack":
					what = "Anfall"
				"defend":
					what = "Försvarar"
				"provoke":
					what = "Provocerar"
				"skip":
					what = "står över"
				"artifact":
					# Gratis kast: hjältarnas artefakter, och fiendernas egenskaper som kastar (t.ex. Benstorm vid vrede).
					what = ("(artefakt) " if sim.unit(e.unit) != null and sim.unit(e.unit).team == 0 else "(utlöst) ") + String(sim.ability(e.ability).get("name", e.ability))
				_:
					what = String(sim.ability(e.ability).get("name", e.ability))
			var tg: Array = (e.get("targets", []) as Array).map(func(id: String) -> String: return L.call(id))
			return "%s: %s%s" % [L.call(e.unit), what, " → " + ", ".join(tg) if tg.size() in [1, 2] else (" → alla" if tg.size() > 2 else "")]
		"damage":
			return "%s −%d%s%s" % [L.call(e.target), int(e.amount), " KRIT" if e.get("crit", false) else "",
					" (barriär %d)" % int(e.absorbed) if float(e.get("absorbed", 0)) >= 1.0 else ""]
		"heal":
			return "%s +%d" % [L.call(e.target), int(e.amount)] if int(e.amount) > 0 else ""
		"death":
			return "† %s" % L.call(e.unit)
		"revive":
			return "%s reser sig" % L.call(e.unit)
		"dodge":
			return "%s undviker" % L.call(e.target)
		"immune":
			return "%s IMMUN" % L.call(e.target)
		"aura_applied":
			var a: Dictionary = data.auras.get(e.aura, {})
			if e.get("refreshed", false) or not String(a.get("type", "")) in ["buff", "debuff"]:
				return ""
			return "%s: %s" % [L.call(e.unit), a.get("name", e.aura)]
		"trait":
			var t: Dictionary = data.traits.get(e.trait, {})
			var u := sim.unit(e.unit)
			if t.get("hidden", false) or not t.has("name"):
				return ""
			if u != null and u.team == 1:
				trait_counts[t.name] = int(trait_counts.get(t.name, 0)) + 1
				return "‹%s›" % t.name
			return "«%s»" % t.name
		"guarded":
			return "%s skyddar %s" % [L.call(e.unit), L.call(e.protected)]
		"status_skip":
			return "%s står över (%s)" % [L.call(e.unit), String(e.get("reason", e.get("aura", "")))]
		"buff_stolen":
			return "%s stjäl %s från %s" % [L.call(e.unit), data.auras.get(e.aura, {}).get("name", e.aura), L.call(e.from)]
		"windup_start":
			var ab: String = sim.ability(e.ability).get("name", e.ability)
			var warn := String(sim.windup_of(e.ability).get("warn", ""))
			return "!! %s laddar %s – slår om %d %s%s%s" % [L.call(e.unit), ab, int(e.left), "tur" if int(e.left) == 1 else "turer",
					_windup_target(sim, e, labels), " (%s)" % warn if warn != "" else ""]
		"windup_tick":
			return "!! %s laddar %s – slår %s" % [L.call(e.unit), sim.ability(e.ability).get("name", e.ability),
					"nästa tur" if int(e.left) <= 1 else "om %d turer" % int(e.left)]
		"windup_release":
			return "!! %s släpper %s!" % [L.call(e.unit), sim.ability(e.ability).get("name", e.ability)]
		"windup_broken":
			return "!! %s avbröts (%s). %s vacklar." % [sim.ability(e.ability).get("name", e.ability), String(e.reason), L.call(e.unit)]
		"windup_delayed":
			return "!! %s skjuts upp (%s)" % [sim.ability(e.ability).get("name", e.ability), String(e.get("reason", ""))]
		"trait_passed":
			return "!! %s föll; %s går vidare till %s" % [L.call(e.unit), data.traits.get(e.trait, {}).get("name", e.trait),
					", ".join((e.get("to", []) as Array).map(func(id: String) -> String: return L.call(id)))]
		"aura_passed":
			return "" if e.to == e.unit else "!! %s går från %s till %s" % [data.auras.get(e.aura, {}).get("name", e.aura), L.call(e.unit), L.call(e.to)]
		"rule":
			return "!! Våningsregel: %s" % data.floor_rules.get(e.rule, {}).get("name", e.rule)
		"elite":
			return "!! %s är en elitfiende" % L.call(e.unit)
		"chaos_calm":
			return "!! Kaosvinden lägger sig kring %s" % L.call(e.unit)
		"exhaustion_start":
			return "!! Facklorna falnar (utmattning)"
		"corpse_consumed":
			return "%s slukar %s" % [L.call(e.by), L.call(e.unit)]
	return ""


func _windup_target(sim: CombatSim, e: Dictionary, labels: Dictionary) -> String:
	if sim.ability(e.ability).get("target", "") == "all_enemies":
		return " mot hela sällskapet"
	for id in e.get("targets", []):
		var t := sim.unit(id)
		if t != null and t.alive and t.team == 0:
			return " mot " + String(labels.get(id, id))
	return ""


func _award(sim: CombatSim, won: bool) -> void:
	for u in sim.heroes:
		var h := profile.hero(data, u.id)
		h.battles = int(h.battles) + 1
		h.wins = int(h.wins) + (1 if won else 0)
		h.deaths = int(h.deaths) + u.deaths
	if not won:
		return
	var r := state.current_room()
	state.vow_after_battle(data, sim)
	var finds := _roll_finds("boss" if r.get("boss", false) else RunState.fight_kind(r))
	var xp := HeroStats.battle_xp(RunState.fight_kind(r), state.depth, r.get("boss", false))
	var ups := profile.grant_xp(data, state.party, xp)
	out.append("Erfarenhet: +%d var." % xp)
	for id in ups:
		out.append("  %s når nivå %d!" % [data.heroes[id].name, int(ups[id].back())])
	if not finds.is_empty():
		out.append("Fynd: " + ", ".join(finds.map(func(f: Dictionary) -> String:
				return Forge.find_text(data, f) + " (" + Forge.find_effect(data, f) + ")")))
	var standing := sim.heroes.filter(func(h: CombatUnit) -> bool: return h.alive)
	if standing.size() < sim.heroes.size():
		_bark("fallen")
	elif standing.any(func(h: CombatUnit) -> bool: return h.hp < h.max_hp * 0.3):
		_bark("hard_fight")


func _battle_finished(sim: CombatSim, won: bool) -> void:
	if not won:
		out.append("Sällskapet faller. Körningen är förlorad; ni vaknar i borgen.")
		_end_descent("loss")
		return
	var paid := roundi(state.battle_silver(state.depth) * state.silver_mult(data))
	profile.silver += paid
	out.append("+%d silver (nu %d)." % [paid, profile.silver])
	if state.current_room().get("kind", "") == "end" and state.is_last_floor():
		for kind in data.encounters[state.encounter()].enemies:
			if data.enemies[kind].get("boss", false):
				profile.defeat_boss(kind)
		if data.encounters[state.encounter()].get("guardian", false):
			profile.defeat_guardian(state.encounter())
	RunScript.mark_sneak(data, profile, state)
	var offer := state.trophy_offer(data, rng, state.last_elites, profile.unlocked_boss_trophies(), profile.unlocked_guardians())
	var done_now := state.battle_won()
	match state.current_room().get("kind", ""):
		"prisoner":
			_rescue()
			meta.mode = "grotto"  # fångens ruta visas efter lägret
			meta.pending = meta.get("dialog", {})
			meta.erase("dialog")
		"treasure":
			out.append(_treasure())
		"item":
			done_now = state.collect_item() or done_now
			out.append("Föremålet är ert. " + RunState.quest_text(state.quest))
		"object":
			var w := state.object_won()
			var p := roundi(w.silver * state.silver_mult(data))
			profile.silver += p
			out.append(("+%d silver. " % p if p > 0 else "") + String(w.text))
	_after_quest_check(done_now)
	for t in offer:
		profile.add_trophy(t)
	meta.offer = Array(offer)
	meta.mode = "camp"


func _camp_cmd(w: PackedStringArray) -> void:
	var offer: Array = meta.get("offer", [])
	if w[0] == "take" and w.size() > 1 and int(w[1]) >= 1 and int(w[1]) <= offer.size():
		var t: String = offer[int(w[1]) - 1]
		state.take_trophy(t)
		out.append("Ni tar med er %s. (Den kan bäras från nästa lägereld.)" % data.traits[t].name)
	elif w[0] == "skip" or offer.is_empty():
		out.append("Ni tar ingen trofé.")
	else:
		out.append("Välj take <n> eller skip.")
		return
	meta.erase("offer")
	_after_camp()


func _after_camp() -> void:
	profile.keep_worn(state.equipped, state.party)
	meta.mode = "grotto"
	if not meta.get("pending", {}).is_empty():
		meta.dialog = meta.pending
		meta.mode = "dialog"
	meta.erase("pending")
	if state.floor_cleared() and state.is_last_floor():
		var t := state.take_trail(data)
		if not t.is_empty():
			profile.grant_xp(data, state.party, int(t.xp))
			profile.silver += roundi(float(t.silver) * state.silver_mult(data))
		profile.clear_depth(state.depth, state.realm)
		out.append("=== Djupet är klarat! Ni går hem till borgen. ===")
		_end_descent("boss")


func _end_descent(outcome: String) -> void:
	var before := {}
	for r in data.realms:
		before[r] = LivingMap.growth(profile, r)
	var changes := LivingMap.after_descent(profile, data, state.realm, state.wins, state.realm_quest_done)
	var world := WorldEvents.after_descent(profile, data, state.realm, outcome, state.wins, state.realm_quest_done, before)
	for c in changes:
		if c is Dictionary:
			out.append("Kartan: fördärvet i %s %s (%d → %d)." % [data.realms[String(c.realm)].name,
					"viker" if int(c.to) < int(c.from) else "växer", int(c.from), int(c.to)])
	for l in WorldEvents.summary(profile, data, world):
		out.append("Medan ni var borta: " + String(l))
	var line := WorldEvents.map_line(profile, data)
	if line != "":
		out.append("Kampanjkartan: " + line)
	profile.keep_worn(state.equipped, state.party)
	state.finished = true
	meta.mode = "home"
	meta.erase("dialog")
	meta.erase("offer")
	if FileAccess.file_exists(_path("run.cfg")):
		DirAccess.remove_absolute(_path("run.cfg"))
	state = null


# --- Makron och troféer ---------------------------------------------------------

func _macro_cmd(w: PackedStringArray) -> void:
	var id := _hero_id(w[1] if w.size() > 1 else "")
	if id == "":
		out.append("macro <hjälte> …")
		return
	if not macros.has(id):
		macros[id] = {"name": data.heroes[id].name, "lines": []}
	var lines: Array = macros[id].lines
	if w.size() > 2:
		match w[2]:
			"del":
				var n := int(w[3]) - 1 if w.size() > 3 else -1
				if n >= 0 and n < lines.size():
					out.append("Tog bort rad %d: %s" % [n + 1, MacroRunner.describe_line(data, lines[n])])
					lines.remove_at(n)
			"move":
				var a := int(w[3]) - 1
				var b := int(w[4]) - 1
				if a >= 0 and a < lines.size() and b >= 0 and b < lines.size():
					var l: Variant = lines[a]
					lines.remove_at(a)
					lines.insert(b, l)
			"add":
				# add <rad> <subjekt> <villkor>[=värde] <handling>[:förmåga] [mål]
				if w.size() < 7:
					out.append("add <rad> <subjekt> <villkor>[=värde] <handling>[:förmåga] [mål]")
					return
				var line := {"subject": w[4], "cond": w[5].get_slice("=", 0), "action": w[6].get_slice(":", 0),
						"ability": w[6].get_slice(":", 1) if w[6].contains(":") else "", "target": w[7] if w.size() > 7 else "that"}
				if w[5].contains("="):
					var v := w[5].get_slice("=", 1)
					line.value = int(v) if v.is_valid_int() else v
				var at := clampi(int(w[3]) - 1, 0, lines.size())
				lines.insert(at, line)
				out.append("La till rad %d: %s" % [at + 1, MacroRunner.describe_line(data, line)])
	out.append("Makro för %s:" % data.heroes[id].name)
	for i in lines.size():
		out.append("  %d. %s" % [i + 1, MacroRunner.describe_line(data, lines[i])])
	out.append("  Förmågor: " + ", ".join((data.heroes[id].abilities as Array).map(func(a: String) -> String:
			return "%s (%s)" % [a, data.abilities[a].name])))


func _list_trophies() -> void:
	var worn_by := {}
	var src: Dictionary = state.equipped if state != null else profile.worn
	for h in src:
		worn_by[src[h]] = data.heroes[h].name
	var list: Array = state.trophies if state != null else profile.collection
	out.append("Troféer (%s):" % ("körningens" if state != null else "samlingen"))
	for t in list:
		var td: Dictionary = data.traits[t]
		out.append("  %s – %s [%s]%s: %s" % [t, td.name, td.get("rarity", "common"), " (bärs av %s)" % worn_by[t] if worn_by.has(t) else "",
				td.get("text", "")])


func _hero_sheet(s: String) -> void:
	var id := _hero_id(s)
	if id == "":
		return
	var h := profile.hero(data, id)
	var p: Dictionary = data.personalities.get(String(h.personality), {})
	out.append("%s, %s – nivå %d (%d/%d erfarenhet), personlighet %s" % [data.heroes[id].name, data.heroes[id].get("title", ""),
			int(h.level), int(h.xp), HeroStats.xp_to_next(int(h.level)), p.get("name", "")])
	var traits: Array = [profile.oath] if id == "paladin" else data.heroes[id].get("traits", [])
	for t in traits:
		out.append("  Egen: %s – %s" % [data.traits[t].name, data.traits[t].get("text", "")])
	if profile.worn.has(id):
		out.append("  Trofé: %s – %s" % [data.traits[profile.worn[id]].name, data.traits[profile.worn[id]].get("text", "")])
	var art := profile.artifact(id)
	if not art.is_empty():
		out.append("  Artefakt: %s nivå %d, förmåga %s; stat-platser %s; troféplats %s" % [data.artifacts[art.type].name,
				int(art.level), data.abilities.get(art.ability, {}).get("name", "–"),
				str(art.stat_slots), data.traits.get(art.trophy, {}).get("name", "tom" if Forge.trophy_open(int(art.level)) else "stängd")])
	for a in data.heroes[id].abilities:
		out.append("  Förmåga %s: %s" % [data.abilities[a].name, data.abilities[a].get("text", data.abilities[a].get("desc", ""))])


# --- Skärmen -------------------------------------------------------------------

func _screen() -> void:
	out.append("")
	match String(meta.get("mode", "home")):
		"home":
			_home_screen()
		"grotto":
			_grotto_screen()
		"dialog":
			_grotto_screen()
			out.append("")
			out.append("[%s] %s" % [String(meta.dialog.title).to_upper(), meta.dialog.text])
			for i in meta.dialog.options.size():
				out.append("  %d) %s" % [i + 1, meta.dialog.options[i].label])
		"camp":
			out.append("LÄGRET – välj en trofé till körningen:")
			var offer: Array = meta.get("offer", [])
			if offer.is_empty():
				out.append("  (ingen trofé den här gången – skip)")
			for i in offer.size():
				var td: Dictionary = data.traits[offer[i]]
				out.append("  %d) %s [%s] – %s" % [i + 1, td.name, td.get("rarity", "common"), td.get("text", "")])


func _home_screen() -> void:
	out.append("BORGEN – %s, silver %d, perk-poäng %d/%d (%s)" % [profile.hero_name, profile.silver,
			profile.points_used(data, profile.oath), profile.perk_points(), data.traits[profile.oath].name])
	out.append("Vald nedstigning: %s, djup %d (klarat: %s)" % [data.realms[profile.realm].name, profile.depth,
			", ".join(profile.realm_depth.keys().map(func(r: String) -> String: return "%s %d" % [data.realms[r].name, profile.realm_depth[r]]))])
	var g := RunState.guardian_for(data, profile.realm, profile.depth)
	out.append("Djupets slut: %s" % (data.encounters[g].get("name", g) if g != "" else "huvudbossen"))
	if WorldEvents.map_line(profile, data) != "":
		out.append("Kampanjkartan: " + WorldEvents.map_line(profile, data))
	out.append("Sällskap:")
	for id in profile.party:
		out.append("  " + _hero_line(id))
	var home: Array = profile.recruited.filter(func(id: String) -> bool: return not profile.party.has(id))
	if not home.is_empty():
		out.append("Värdshuset: " + ", ".join(home.map(func(id: String) -> String:
				return "%s (%s, nivå %d)" % [id, data.heroes[id].name, int(profile.hero(data, id).level)])))
	var perks: Array = []
	for p in data.oaths[profile.oath].get("perks", []):
		var pid: String = p.id if p is Dictionary else p
		perks.append("%s %s (%d p)%s" % [pid, data.traits[pid].name, Profile.perk_cost(data, profile.oath, pid),
				" ×%d" % profile.perk_rank(profile.oath, pid) if profile.perk_rank(profile.oath, pid) > 0 else ""])
	out.append("Perks: " + "; ".join(perks))
	var mats: Array = []
	for k in profile.materials:
		if int(profile.materials[k]) > 0:
			mats.append("%s ×%d" % [k, int(profile.materials[k])])
	if not mats.is_empty() or not profile.stones.is_empty():
		out.append("Förråd: %s%s" % [", ".join(mats), " och %d Nether Stones" % profile.stones.size() if not profile.stones.is_empty() else ""])


func _hero_line(id: String) -> String:
	var h := profile.hero(data, id)
	var art := profile.artifact(id)
	var t: String = profile.worn.get(id, "")
	return "%s (%s) nivå %d%s%s" % [data.heroes[id].name, id, int(h.level),
			", trofé " + String(data.traits[t].name) if t != "" else ", ingen trofé",
			", %s nivå %d (nästa %d silver)" % [String(data.artifacts[art.type].name).to_lower(), int(art.level), profile.artifact_level_cost(id)] if not art.is_empty() else ""]


var show_legend := false


func _grotto_screen() -> void:
	var m := state.map
	out.append("%s djup %d – våning %d av %d. Quest: %s%s" % [data.realms[state.realm].name, state.depth, state.floor + 1,
			RunState.FLOORS_PER_RUN, RunState.quest_text(state.quest), " (KLAR)" if state.quest.get("done", false) else ""])
	var hint_cells := {}
	for h in state.active_hints():
		var c := Grotto.xy(int(h.center))
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				hint_cells[Grotto.idx(c + Vector2i(dx, dy))] = true
	out.append("     a  b  c  d  e  f  g  h")
	for y in Grotto.SIZE:
		var row := "%d  " % (y + 1)
		for x in Grotto.SIZE:
			row += " " + _cell_symbol(m, Grotto.idx(Vector2i(x, y)), hint_cells)
		out.append(row)
	if show_legend:
		out.append("(@ ni, .. besökt, ## kan nås med ett tryck, ~~ dimma, xx spärrad, rr rykte om questens mål; G grupp, E elit, N Nemesis, B boss/väktare, > trappa, T skatt, H helgedom, L lägereld, Q quest-föremål, P fånge, O föremål; ! = en grupp vaktar, liten bokstav = använd/besegrad, * = låst)")
	var parts: Array = []
	for hero_id in state.party:
		var left := 0
		var full := 0
		for a in state.charges.get(hero_id, {}):
			left += int(state.charges[hero_id][a])
			full += int(data.abilities[a].get("charges", 0))
		var t: String = state.equipped.get(hero_id, "")
		parts.append("%s nv %d, Charges %d/%d%s" % [data.heroes[hero_id].name, int(profile.hero(data, hero_id).level), left, full,
				", " + String(data.traits[t].name) if t != "" else ""])
	out.append("Sällskap: " + " · ".join(parts))
	out.append("Silver %d. Fynd: bärnsten %d, trick %d, Nether %d." % [profile.silver, int(state.found.get("amber", 0)),
			int(state.found.get("trick", 0)), int(state.found.get("nether", 0))])
	if not state.known_rules().is_empty():
		out.append("Regler: " + ", ".join(state.known_rules().map(func(r: String) -> String: return data.floor_rules[r].name)))
	var r := state.current_room()
	if state.at_group():
		out.append("")
		_card(r)
		out.append("→ fight eller back")
		return
	var kind: String = r.get("kind", "empty")
	var name: String = {"start": "Start", "stairs": "Trappan", "end": "Bossens sal", "battle": "Besegrad grupp", "elite": "Besegrad elit",
			"treasure": "Skattkammare", "shrine": "Helgedom", "campfire": "Lägereld", "item": "Quest-föremål", "prisoner": "Fånge",
			"object": String(data.get("objects", {}).get(r.get("obj", ""), {}).get("name", "Föremål"))}.get(kind, "Tom ruta")
	out.append("Ni står på %s: %s." % [_cell_name(state.pos), name])
	if state.goal_locked():
		var what := "Trappan" if not m.last_floor else ("Väktaren" if m.cell(m.goal).get("guardian", false) else "Bossen")
		out.append("%s (%s) syns men är låst tills questen är klar.%s" % [what, _cell_name(m.goal),
				" De röda ringarna (rr) visar ungefär var målen finns." if not state.active_hints().is_empty() else ""])
	else:
		var route := m.path(state.pos, m.goal, state.visited)
		out.append("Questen är klar: %s (%s) är öppen. %s" % ["bossen" if m.last_floor else "trappan", _cell_name(m.goal),
				("Väg: " + " ".join(Array(route).map(func(i: int) -> String: return _cell_name(i)))) if not route.is_empty() else "Ingen känd väg dit än."])
	var seen_groups: Array = state.seen.filter(func(i: int) -> bool: return m.has_group(i))
	for i in seen_groups:
		var c := m.cell(i)
		out.append("  Sedd grupp på %s: %s" % [_cell_name(i), _group_title(c) + " – " + state.lineup_text(data, i)])


func _cell_symbol(m: Grotto, i: int, hint_cells: Dictionary) -> String:
	if i == state.pos:
		return "@@"
	var known := state.visited.has(i) or i == m.goal or state.revealed.has(i)
	if not known:
		if m.blocked(i, state.visited, state.seen):
			return "xx"
		if hint_cells.has(i):
			return "r#" if state.can_step(i) == "" else "rr"
		return "##" if state.can_step(i) == "" else "~~"
	var c := m.cell(i)
	var kind: String = c.get("kind", "empty")
	var group := m.has_group(i)
	var used: bool = c.get("done", false) or c.get("rescued", false) or (c.has("encounter") and c.get("beaten", false))
	var ch: String = {"start": "s", "stairs": ">", "end": "B", "battle": "G", "elite": "E", "treasure": "T", "shrine": "H",
			"campfire": "L", "item": "Q", "prisoner": "P", "object": "O", "empty": "."}.get(kind, ".")
	if c.get("nemesis", false):
		ch = "N"
	if c.get("elite", false) and kind == "battle":
		ch = "E"
	if used and kind not in ["stairs", "end", "start"]:
		ch = ch.to_lower() if ch != "." else "."
	var mod := "."
	if group and kind in ["treasure", "item", "prisoner", "object"]:
		mod = "!"
	if i == m.goal and state.goal_locked():
		mod = "*"
	if kind == "campfire" and c.get("done", false):
		ch = "l"
	return ch + mod


func _group_title(r: Dictionary) -> String:
	var title := "ELITGRUPP" if r.get("elite", false) else ("BOSS" if r.get("boss", false) else "FIENDEGRUPP")
	if r.get("nemesis", false):
		title = "NEMESIS"
	if state.guardian_room(r):
		title = "VÄKTARE"
	return title


## Gruppens kort (room_map_screen._draw_panel).
func _card(r: Dictionary) -> void:
	var enc: Dictionary = data.encounters[r.encounter]
	out.append("[%s] (%s)" % [_group_title(r), String(enc.get("name", r.encounter))])
	var kinds := state.lineup(data, r.encounter)
	var lines: Array[String] = [state.lineup_text(data, state.pos)]
	if state.guardian_room(r):
		var leader: String = data.enemies[kinds[0]].name if not kinds.is_empty() else ""
		var text := "%s: %s vaktar djupet i bossens ställe." % [enc.get("name", ""), leader]
		lines.push_front(text)
		if String(enc.get("warning", "")) != "":
			lines.insert(1, String(enc.warning))
		var gt := RunState.guardian_trophy(data, r.encounter)
		if gt != "" and data.traits.has(gt):
			lines.append("Väktarens trofé: %s (%s)" % [data.traits[gt].name,
					RunState.guardian_progress(int(profile.guardian_wins.get(r.encounter, 0)))])
	var guards: String = {"treasure": "Vaktar en skatt.", "item": "Vaktar ett av questens föremål.",
			"prisoner": "Vaktar en fånge."}.get(r.kind, "")
	if guards != "":
		lines.append(guards)
	var traits: Array = []
	var trophies: Array = []
	var seen_k := {}
	for k in kinds:
		if seen_k.has(k):
			continue
		seen_k[k] = true
		for t in data.enemies[k].get("traits", []):
			var td: Dictionary = data.traits.get(t, {})
			if not td.get("hidden", false) and td.has("name") and not traits.has(td.name):
				traits.append(td.name)
				lines.append("  · %s (%s): %s" % [td.name, data.enemies[k].name, td.get("text", "")])
		var tr: String = data.enemies[k].get("trophy", "")
		if tr != "" and data.traits.has(tr) and not trophies.has(data.traits[tr].name) and not data.enemies[k].get("boss", false):
			trophies.append(data.traits[tr].name)
	var extras := state.variant_extras(data, state.pos)
	for t in extras.traits:
		if data.traits.has(t) and not traits.has(data.traits[t].name):
			traits.append(data.traits[t].name)
			lines.append("  · %s (elitvariant): %s" % [data.traits[t].name, data.traits[t].get("text", "")])
	for t in extras.trophies:
		if data.traits.has(t) and not trophies.has(data.traits[t].name):
			trophies.append(data.traits[t].name)
	if not trophies.is_empty():
		lines.append("Kan lämna: " + ", ".join(trophies))
	if r.get("elite", false) or r.get("nemesis", false):
		lines.append("Varning: en elitfiende är starkare än vanligt och har en egen regelbrytande egenskap. Backa och byt makro, eller troféer vid en lägereld, om det behövs.")
	elif state.rare_warning(data, state.pos) != "":
		lines.append(state.rare_warning(data, state.pos))
	var c_opts := {"counter": r.get("elite", false) or r.get("nemesis", false) or r.get("boss", false),
			"force_elites": 1 if r.get("elite", false) or r.get("nemesis", false) else 0}
	var counter := CombatSim.counter_for(data, r.encounter, state.depth, c_opts, state.lineup_size())
	if not counter.is_empty():
		var who: Dictionary = data.enemies[counter.kind]
		var who_name: String = who.name
		if who.get("elite", {}).get("counter", {}).get("trait", "") == counter.trait:
			who_name = who.elite.name
		var td: Dictionary = data.traits[counter.trait]
		lines.append("Motdrag – %s: %s." % [who_name, td.get("card", td.get("text", ""))])
	out.append_array(lines)
