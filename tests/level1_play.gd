extends "res://tests/text_play.gd"
## ChatGPT:s tillägg (provspel 4–5) för en ny profil från nivå 1 och introts steg. 0.30.46: kortets variationsrader,
## första nedstigningen och kartans rader (nu i klartext) sköts av text_play.gd själv.

# Adapter for genuine new-profile play. No changes to game rules or rewards.
func _new_profile(seed_value: int) -> void:
	for f in ["meta.json", "profile.cfg", "run.cfg", "log.txt"]:
		if FileAccess.file_exists(_path(f)):
			DirAccess.remove_absolute(_path(f))
	profile = Profile.new()
	profile.hero_name = "Arn"
	profile.room_moments = false
	profile.hero(data, "paladin")
	macros = data.macros.duplicate(true)
	macros.paladin.lines = []
	for h in macros:
		if h != "paladin":
			macros[h].lines = RunScript.starter_lines(data, h, macros[h].lines)
	meta = {"mode": "home", "seed": seed_value, "descent": 0}
	rng.seed = seed_value
	out.append("NY PROFIL: nivå 1, ensam, 60 silver, inga fynd eller klarade djup.")
	out.append(Intro.quest_text(data, profile))

func _home_cmd(w: PackedStringArray) -> void:
	if w[0] == "talk":
		var st := Intro.current(data, profile)
		for l in Intro.lines(st):
			out.append(String(l.who) + ": " + String(l.text).replace("{namn}", profile.hero_name))
		Intro.talked(data, profile)
		if st.get("event", "") == "talked":
			Intro.notify(data, profile, "talked")
		out.append(Intro.quest_text(data, profile))
		return
	if w[0] == "oath":
		profile.oath = w[1]
		Intro.notify(data, profile, "oath_chosen")
		out.append("Ed vald: " + profile.oath)
		return
	if w[0] == "forge":
		var id := _hero_id(w[1])
		if profile.party.has(id) and profile.forge(id, w[2], w[3]):
			out.append("Artefakt smidd för " + id)
			Intro.notify(data, profile, "forged")
		else:
			out.append("Kunde inte smida (silver, ägande eller oförändrat val).")
		return
	if w[0] == "read":
		for l in Intro.at_lines(data, profile, "alrik") if Intro.at_lines(data, profile, "alrik") != null else []:
			out.append(str(l))
		Intro.notify(data, profile, "library_read")
		return
	if w[0] == "practice":
		var enc := w[1] if w.size() > 1 else "intro_yard"
		var s := RunState.new_practice(profile, data, enc)
		var opts := s.practice_opts(data)
		opts.levels = profile.levels_for(data, s.party)
		var sim := CombatSim.create(data, enc, rng.randi(), s.party, s.hero_traits(data), s.charges, s.artifacts, s.depth, opts)
		sim.begin()
		var n := 0
		while sim.outcome == "" and n < 3000:
			n += 1
			if not sim.needs_input():
				sim.ai_act()
			else:
				var d := MacroRunner.decide(sim, sim.current, macros.get(sim.current.id, {"lines": []}))
				if not (d.ok and sim.act(d.action, d.target, d.ability) == ""):
					sim.act("attack")
			sim.drain_events()
		out.append("ÖVNING " + enc + ": " + sim.outcome + " efter " + str(sim.turn_no) + " turer. Ingen XP eller belöning.")
		if sim.outcome == "victory" and enc == "intro_yard":
			Intro.notify(data, profile, "practice_won")
		return
	super._home_cmd(w)
	if w[0] == "smith":
		Intro.notify(data, profile, "sword_level", int(profile.artifact("paladin").get("level", 0)))

func _macro_cmd(w: PackedStringArray) -> void:
	super._macro_cmd(w)
	if w.size() > 2 and w[2] == "add":
		Intro.notify(data, profile, "macro_line")

func _start_run() -> void:
	if not RunState.can_start(profile):
		out.append("Sällskapet kan inte gå ned.")
		return
	if not profile.intro_done and Intro.current(data, profile).get("id", "") not in ["descent", "crypt"]:
		out.append("Gör klart introsteget först: " + Intro.quest_text(data, profile))
		return
	super._start_run()

func _after_camp() -> void:
	super._after_camp()
	if state != null and meta.mode == "grotto" and state.join_waiting(data, profile) != "":
		out.append("IMMA ANSLUTER efter första striden, enligt spelets ordinarie regler.")
		for l in Intro.speech(data.intro.imma_joins.lines):
			out.append(String(l.who) + ": " + String(l.text).replace("{namn}", profile.hero_name))
