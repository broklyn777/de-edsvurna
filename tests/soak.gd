extends SceneTree
## Buggjakt med botar (0.30.15): hela körningar genom RunState, Profile och CombatSim med slumpade val och fasta frön.
## Spelets flöde (Run, rumskartan, striden, lägret) är skrivet en gång till här utan noder, med samma anrop i samma
## ordning: steg, anfall, backa, föremål (alla val), helgedomar, lägereld (vila och trofébyte), skatter, fångar,
## trappan, bossen, ge upp och gå hem. Körningen sparas och läses in mitt i och fortsätter från den inlästa. Körfel fångas
## av en Logger (som run_tests.gd) och invarianterna prövas efter varje drag.
##   godot --headless --path . --script res://tests/soak.gd -- --runs=50
##   godot --headless --path . --script res://tests/soak.gd -- --runs=1000 --from=1001
##   godot --headless --path . --script res://tests/soak.gd -- --seed=17 --verbose       (återskapa ett frö)
##   SOAK=nivaer godot --headless --path . --script res://tests/soak.gd -- --runs=200  (nivån efter första nedstigningen)
##   SOAK=karriar godot --headless --path . --script res://tests/soak.gd -- --runs=80 --descents=18  (svårighetskurvan)
## Varje fel skrivs med frö, drag och vad som hände; samma frö ger samma körning.

const Bot := preload("res://tests/combat_bot.gd")
const RunScript := preload("res://scripts/game/run.gd")
const MAX_ACTIONS := 2000
const MAX_BATTLE_STEPS := 1500
## Egna filer per process: flera buggtester (andra arbetskopior av projektet) delar user:// och skrev förr över varandra.
var TMP_RUN := "user://soak_run_%d.cfg" % OS.get_process_id()
var TMP_PROFILE := "user://soak_progress_%d.cfg" % OS.get_process_id()

var data: Dictionary
var catcher := ErrorCatcher.new()
var verbose := false
## Fel: [{seed, step, kind, msg, cfg}]
var errors: Array = []
var stats := {"runs": 0, "cleared": 0, "lost": 0, "forfeit": 0, "left": 0, "actions": 0, "battles": 0, "saves": 0,
		"objects": 0, "shrines": 0, "campfires": 0, "rescues": 0, "treasures": 0, "descends": 0, "bosses": 0}

# Körningens läge (det Run håller i spelet).
var profile: Profile
var state: RunState
var rng := RandomNumberGenerator.new()  # spelets rng (Run.rng)
var pick := RandomNumberGenerator.new()  # botens val
var cfg := {}
var seed_now := 0
var step_now := 0
var macros := {}
var ended := ""
var arrived := false  # pjäsen kom just fram till rutan (rumskartans _arrive)
var silver_floor := 0  # silvret får inte bli lägre än så här (boten spenderar inget)
var collection_floor: Array = []
var run_fights := 0  # strider i körningen (karriärläget)
var run_ups := 0  # nivåer (alla hjältar) i körningen (prototyp NIVAER)
var run_upfights := 0  # vunna strider där minst en hjälte steg i nivå
var run_pal_ups := 0  # Paladinens nivåer i körningen
var lost_at := ""  # var körningen förlorades (karriärläget)
var human := false  # SOAK=karriar_mansklig: boten tränar, smider, sätter material och väljer troféer som en spelare
## HUMAN_OFF=sockets,trophies,campfire,train: stänger av en del av det mänskliga beteendet (för att se vad som bär).
var human_off: Array = OS.get_environment("HUMAN_OFF").split(",", false)
var run_turns := 0  # turer i körningens strider (alla figurers), för speltiden
var run_steps := 0  # steg i grottan
## Den levande världen (WorldEvents): hur ofta händelserna startar och hur de slutar, följder och gåvor. VARLD=av stänger av.
var world_stats := {"started": {}, "results": {}, "costs_on": {}, "gifts": {}, "tor": 0}


## Samlar skriptfel och motorfel medan ett drag körs.
class ErrorCatcher extends Logger:
	var errors: Array[String] = []
	var active := false

	func _log_error(function: String, file: String, line: int, code: String, rationale: String,
			_editor_notify: bool, _error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if not active:
			return
		var what := rationale if rationale != "" else code
		errors.append("%s (%s:%d %s)" % [what, file.get_file(), line, function])

	func _log_message(_message: String, _error: bool) -> void:
		pass


func _init() -> void:
	data = GameData.load_all()
	var runs := 50
	var from := 1
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--runs="):
			runs = int(arg.get_slice("=", 1))
		elif arg.begins_with("--from="):
			from = int(arg.get_slice("=", 1))
		elif arg.begins_with("--seed="):
			from = int(arg.get_slice("=", 1))
			runs = 1
		elif arg == "--verbose":
			verbose = true
	OS.add_logger(catcher)
	if OS.get_environment("NIVAER") != "":
		HeroStats.set_variant(OS.get_environment("NIVAER"))
		print("Nivåskala: %s" % ("idag (0.19)" if HeroStats.legacy else "kurvan"))
	if OS.get_environment("DJUPSTEG") != "":
		CombatSim.depth_step = float(OS.get_environment("DJUPSTEG"))
		print("Djupsteg: +%.1f %% per djup" % (CombatSim.depth_step * 100.0))
	if OS.get_environment("SOAK") == "karriar":
		var n := 18
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--descents="):
				n = int(arg.get_slice("=", 1))
		_career_report(from, runs, n)
		quit()
		return
	if OS.get_environment("SOAK") == "karriar_mansklig":
		var n := 40
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--descents="):
				n = int(arg.get_slice("=", 1))
		human = true
		_human_report(from, runs, n)
		quit()
		return
	if OS.get_environment("SOAK") == "nivaer":
		_levels_report(from, runs)
		quit()
		return
	var t0 := Time.get_ticks_msec()
	for s in range(from, from + runs):
		_soak(s)
		if (s - from + 1) % 50 == 0:
			print("… %d körningar, %d fel, %.0f s" % [s - from + 1, errors.size(), (Time.get_ticks_msec() - t0) / 1000.0])
	_report(Time.get_ticks_msec() - t0)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP_RUN))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP_PROFILE))
	quit(1 if not errors.is_empty() else 0)


# --- En körning ---------------------------------------------------------------

func _soak(s: int) -> void:
	seed_now = s
	step_now = 0
	ended = ""
	pick.seed = s * 7919 + 3
	rng.seed = s * 104729 + 11
	cfg = _roll_config()
	_setup_profile()
	_guard("start_run", _start_run)
	if state == null:
		return
	stats.runs += 1
	var bot_after := 600 if cfg.policy == "random" else 0
	while ended == "" and step_now < MAX_ACTIONS:
		step_now += 1
		stats.actions += 1
		_guard("drag", _tick.bind(step_now > bot_after))
		if ended == "" and state != null:
			_check_state()
	if ended == "":
		_fail("fastnar", "körningen tog inte slut på %d drag (våning %d, ruta %d, quest %s)" % [MAX_ACTIONS, state.floor,
				state.pos, JSON.stringify(state.quest)])
		ended = "stuck"
	_home()
	if verbose:
		print("frö %d: %s efter %d drag" % [s, ended, step_now])


## Slumpar körningens upplägg ur fröet: Realm, djup 1–3, instabilitet 0–3, sällskap 1–4, kall, perks, nivåer, artefakter,
## troféer, och ibland profilens första nedstigning.
func _roll_config() -> Dictionary:
	var c := {}
	c.first = pick.randf() < 0.2
	c.realm = "crypt" if c.first else String(data.realms.keys()[pick.randi() % data.realms.size()])
	c.depth = 1 if c.first else pick.randi_range(1, 3)
	c.instability = 0 if c.first else pick.randi_range(0, 3)
	var vows: Array = [""] + data.vows.keys().filter(func(k: String) -> bool: return not k.begins_with("_"))
	c.vow = "" if c.first else String(vows[pick.randi() % vows.size()])  # 0.30.17: löftet
	c.oath = data.oaths.keys()[pick.randi() % data.oaths.size()]
	var companions: Array = data.heroes.keys().filter(func(h: String) -> bool: return h != "paladin")
	c.party = []
	var size := pick.randi_range(1, 3)
	while c.party.size() < size:
		var h: String = companions[pick.randi() % companions.size()]
		if not c.party.has(h):
			c.party.append(h)
	c.level = maxi(1, HeroStats.expected_level(c.depth) + pick.randi_range(-2, 4))
	c.policy = ["random", "bot", "bot_careful", "bot_greedy"][pick.randi() % 4]
	c.p_random_action = [0.0, 0.25, 1.0][pick.randi() % 3]  # andel slumpade handlingar i striden
	c.descents = pick.randi_range(0, 3)
	# Den levande kartan: fördärvet per Realm (0–4; 4 i kryptan = den förvridna bossen).
	c.growth = {}
	for r in data.realms:
		c.growth[r] = pick.randi_range(0, LivingMap.GROWTH_MAX)
	return c


func _setup_profile() -> void:
	profile = Profile.new()
	if cfg.first:
		# Som --intro-step=descent: en ny profil fram till nedstigningen, med svärdet från smedjan (Rättfärdigt slag).
		while Intro.current(data, profile).get("id", "") not in ["", "descent"]:
			Intro.talked(data, profile)
			Intro.notify(data, profile, Intro.current(data, profile).get("event", ""), 3)
		Intro.talked(data, profile)
		if profile.artifact("paladin").is_empty():
			profile.silver = Profile.FORGE_COST
			profile.forge("paladin", "sword", "holy_smite")
		profile.realm = "crypt"
		macros = Bot.new_profile_macros(data)
	else:
		profile.intro_done = true
		profile.intro_step = Intro.steps(data).size()
		profile.oath = cfg.oath
		profile.bonus_points = pick.randi_range(0, 4)
		var perks: Array = data.oaths[cfg.oath].get("perks", []).map(func(p: Variant) -> String:
				return String(p.get("id", "")) if p is Dictionary else String(p))
		for i in 6:
			profile.buy_perk(data, cfg.oath, perks[pick.randi() % perks.size()])
		profile.recruit(data, Profile.STARTER, 1.0)  # efter introt bor Imma alltid i borgen (Profile.load_from)
		for h in cfg.party:
			profile.recruit(data, h, 1.0)
		profile.set_party(cfg.party)
		for h in ["paladin"] + Array(cfg.party):
			var hero := profile.hero(data, h)
			hero.level = maxi(1, cfg.level + pick.randi_range(-1, 1))
			if pick.randf() < 0.5:
				var types: Array = data.artifacts.keys()
				var abilities: Array = [""] + data.heroes[h].get("abilities", [])
				profile.artifacts[h] = Forge.normalize({"type": types[pick.randi() % types.size()],
						"ability": abilities[pick.randi() % abilities.size()], "level": pick.randi_range(1, 10)})
		# Några troféer ur Realmens fiender, och en del bärs (Profile.worn).
		var trophies := []
		for kind in data.enemies:
			var t: String = data.enemies[kind].get("trophy", "")
			if t != "" and not data.enemies[kind].get("boss", false):
				trophies.append(t)
		for i in pick.randi_range(0, 5):
			var t: String = trophies[pick.randi() % trophies.size()]
			profile.add_trophy(t)
			if pick.randf() < 0.6:
				profile.wear((["paladin"] + Array(cfg.party))[pick.randi() % (cfg.party.size() + 1)], t)
		profile.realm = cfg.realm
		profile.depth = cfg.depth
		profile.best_depth = cfg.depth
		profile.instability = cfg.instability
		profile.vow = cfg.vow
		profile.descents = {cfg.realm: cfg.descents}
		profile.growth = cfg.growth.duplicate()
		for r in data.realms:
			if pick.randf() < 0.5:
				profile.descents[r] = maxi(int(profile.descents.get(r, 0)), 1)  # andra Realms man har sett
		profile.silver = pick.randi_range(0, 500)
		macros = data.macros.duplicate(true)
	silver_floor = profile.silver
	collection_floor = profile.collection.duplicate()


## Run.start_run utan scenbyten.
func _start_run() -> void:
	state = RunState.new_run(profile, data)
	state.instability = profile.instability
	var rules := RunState.roll_rules(data, profile.instability, rng)
	state.rules_visible = rules.visible.duplicate()
	state.rules_hidden = rules.hidden.duplicate()
	state.start_expedition(data, rng.randi() % 1000000 + 1)
	if OS.get_environment("VARLD") != "av":
		WorldEvents.begin_run(profile, state)
	state.first_descent = profile.total_descents() == 0 or Intro.current(data, profile).get("id", "") == "descent"
	var seen := int(profile.descents.get(state.realm, 0))
	profile.descents[state.realm] = seen + 1
	profile.count_home_runs()
	_check_floor()
	arrived = true


## Ett drag: det rumskartan, kortet eller en ruta skulle låta spelaren göra.
func _tick(use_bot: bool) -> void:
	# Imma (eller någon annan) som väntar ansluter när sällskapet är tillbaka på rumskartan (Run.imma_sneaks).
	if state.joins_next != "":
		_take_hint(state.join_waiting(data, profile))
	if state.at_group():
		if state.came_from >= 0 and _wants_back(use_bot):
			_log("backar från ruta %d" % state.pos)
			state.back()
			arrived = false
			return
		_fight()
		return
	if arrived:
		arrived = false
		if _arrive():
			return
	# GÅ HEM (bara efter introt, som rumskartan).
	if profile.intro_done and not cfg.get("no_leave", false) and pick.randf() < 0.002:
		_log("går hem")
		stats.left += 1
		ended = "left"
		_end_descent()
		RunState.delete_saved(TMP_RUN)
		return
	# Spara och läs in mitt i (som när appen stängs och öppnas igen).
	if pick.randf() < 0.12 and not cfg.get("no_save", false):
		_save_and_load()
	# Lägereld man står vid: troféerna kan bytas när som helst.
	var r := state.current_room()
	if r.get("kind", "") == "campfire" and pick.randf() < 0.1 and not human:
		_swap_trophies()
	var target := _choose_step(use_bot)
	if target < 0:
		_no_step()
		return
	var walk := state.step(target)
	run_steps += walk.size()
	if walk.is_empty():
		_fail("steg", "step(%d) gav ingen väg fast can_step var tom" % target)
		ended = "error"
		return
	arrived = true


func _wants_back(use_bot: bool) -> bool:
	var r := state.current_room()
	if r.get("boss", false) or r.get("kind", "") == "object":
		return pick.randf() < 0.05
	if cfg.policy == "random" and not use_bot:
		return pick.randf() < 0.35
	if cfg.policy == "bot_careful":
		return not Bot._bot_wants_fight(state, r, "careful") and pick.randf() < 0.8
	return not Bot._bot_wants_fight(state, r, "greedy" if cfg.policy == "bot_greedy" else "simple") and pick.randf() < 0.8


## Nästa ruta: botens väg (combat_bot.gd) eller en slumpad ruta man kan gå till. -1 om ingen finns.
func _choose_step(use_bot: bool) -> int:
	if state.floor_cleared():
		return -1
	if cfg.policy != "random" or use_bot:
		var policy: String = {"bot_careful": "careful", "bot_greedy": "greedy"}.get(cfg.policy, "simple")
		var t := Bot._bot_target(data, state, policy)
		if t >= 0 and state.can_step(t) == "":
			return t
	var options := []
	var fresh := []
	for i in state.map.cells.size():
		if state.can_step(i) == "":
			options.append(i)
			if not state.visited.has(i):
				fresh.append(i)
	if options.is_empty():
		return -1
	if not fresh.is_empty() and pick.randf() < 0.7:
		return fresh[pick.randi() % fresh.size()]
	return options[pick.randi() % options.size()]


## Inget steg finns: våningen är klar (trappan eller bossen), eller så är körningen låst.
func _no_step() -> void:
	if state.floor_cleared():
		if state.is_last_floor():
			_after_camp()
		else:
			_descend()
		return
	_fail("fastlåst", "inget giltigt drag: ruta %d, våning %d, quest %s, besökta %d, sedda grupper %s" % [state.pos,
			state.floor, JSON.stringify(state.quest), state.visited.size(),
			str(state.seen.filter(func(i: int) -> bool: return state.map.has_group(i)))])
	ended = "error"


## Rutans innehåll när pjäsen kommer fram (room_map_screen._arrive och _show_room). Sant om draget gick åt.
func _arrive() -> bool:
	var r := state.current_room()
	var kind: String = r.get("kind", "empty")
	var fresh: bool = not r.get("done", false) and not r.get("rescued", false)
	if kind == "stairs" and state.floor_cleared():
		if pick.randf() < 0.9:
			_descend()
		return true
	if kind == "object" and r.get("again", false):
		_use_object()
		return true
	if not kind in ["treasure", "shrine", "campfire", "prisoner", "object"] or (kind != "campfire" and not fresh):
		return false
	match kind:
		"campfire":
			stats.campfires += 1
			if human and not human_off.has("campfire"):
				if not r.get("done", false):
					_campfire()
				_human_swap()
				return true
			var choice := pick.randi() % 3
			if choice == 0 and not r.get("done", false):
				_campfire()
			elif choice == 1:
				_swap_trophies()
		"treasure":
			_treasure()
		"prisoner":
			_rescue()
		"shrine":
			stats.shrines += 1
			var opts := state.shrine_options(data, rng)
			var o: Dictionary = opts[pick.randi() % opts.size()]
			_log("helgedom: " + RunState.shrine_text(data, o))
			state.apply_shrine(data, rng, o)
			_after_quest_check(false)
		"object":
			_use_object()
	return true


func _descend() -> void:
	if not state.floor_cleared() or state.is_last_floor():
		return
	stats.descends += 1
	_log("trappan ned")
	state.next_floor(data)
	_check_floor()
	arrived = true


func _campfire() -> void:
	var before := state.charges.duplicate(true)
	var gained := state.campfire(data)
	_log("lägereld: +%d Charges" % gained)
	for h in state.charges:
		for a in state.charges[h]:
			if int(state.charges[h][a]) < int(before.get(h, {}).get(a, 0)):
				_fail("charges", "lägerelden sänkte %s/%s" % [h, a])


## Lägerelden: flytta troféer mellan hjältarna (camp_screen i läget "campfire").
func _swap_trophies() -> void:
	var inv: Array = state.trophies.duplicate()
	for i in pick.randi_range(1, 3):
		var hero: String = state.party[pick.randi() % state.party.size()]
		if inv.is_empty() or pick.randf() < 0.2:
			state.equip(hero, "")
		else:
			state.equip(hero, inv[pick.randi() % inv.size()])
	profile.keep_worn(state.equipped, state.party)


func _treasure() -> void:
	stats.treasures += 1
	var t := state.treasure(data, rng)
	profile.silver += roundi(t.silver * state.silver_mult(data))
	if t.trophy != "":
		profile.add_trophy(t.trophy)
		state.take_trophy(t.trophy)
	_roll_finds("treasure" if not state.current_room().get("guarded", false) else "portal_battle")
	_log("skatt: %d silver %s" % [t.silver, t.trophy])


## Run.rescue_prisoner.
func _rescue() -> void:
	var r := state.current_room()
	var hero_id: String = r.get("hero", "")
	if hero_id == "" or r.get("rescued", false):
		return
	stats.rescues += 1
	r.rescued = true
	state.prisoners.erase(str(state.floor))
	var avg := 0.0
	for id in state.party:
		avg += float(profile.hero(data, id).level)
	avg /= maxi(state.party.size(), 1)
	profile.recruit(data, hero_id, avg)
	_take_hint(hero_id)
	if state.party.size() < state.party_slots:
		state.party.append(hero_id)
		state.add_charges_for(data, hero_id)
		profile.set_party(state.party.slice(1))
	_log("befriar %s" % hero_id)


## Realmens föremål: ett slumpat val bland de som går (room_map_screen visar inte de avstängda).
func _use_object() -> void:
	stats.objects += 1
	var options := state.object_options(data).filter(func(o: Dictionary) -> bool: return not o.get("disabled", false))
	if options.is_empty():
		return
	var o: Dictionary = options[pick.randi() % options.size()]
	var res := state.use_object(data, String(o.id), rng)
	if int(res.silver) > 0:
		profile.silver += roundi(res.silver * state.silver_mult(data))
	_log("föremål %s: %s" % [state.current_room().get("obj", ""), o.id])
	if res.fight and not state.at_group():
		_fail("föremål", "%s gav en strid men rutan har ingen grupp" % o.id)


# --- Striden -------------------------------------------------------------------

## 0.30.25: en levande hjälte som inte har fått agera på fyra varv är låst av kontroll (Snärjd, Sover, Frusen i kedja;
## provspelet i Sidenlunden). Rapporteras en gång per strid.
## 0.30.32: två mått. Svält: hjälten har inte stått på tur alls (Snärjd längst ned, eller knuffad); en tur som Frusen eller
## Sover tog räknas här, för då stod hen på tidslinjen. Kedja: fler än MAX_SKIPS egna turer i rad tagna av en status
## (Frusen tinar senast på tredje försöket, Sover släpper efter två). Förr räknades tagna turer som overksamhet mot
## 4 × levande, och en vanlig frysning på två turer gav varning när figurer dog och någon knuffades ned på tidslinjen.
const MAX_SKIPS := 3
func _check_control(sim: CombatSim, events: Array, acted: Dictionary, encounter: String) -> void:
	var skips: Dictionary = acted.get("_skips", {})
	acted["_skips"] = skips
	var pending: Dictionary = acted.get("_pending", {})  # turen började; tas den av en status kommer status_skip
	acted["_pending"] = pending
	for e in events:
		var u := sim.unit(e.get("unit", ""))
		if u == null or u.team != 0:
			continue
		if e.type in ["turn_start", "revive"]:
			if pending.get(u.id, false) or e.type == "revive":
				skips[u.id] = 0  # förra turen fick hen agera
			pending[u.id] = e.type == "turn_start"
			acted[u.id] = sim.turn_no
		elif e.type == "status_skip":
			pending[u.id] = false
			skips[u.id] = int(skips.get(u.id, 0)) + 1
	if acted.get("_reported", false):
		return
	var alive := sim.units.filter(func(u: CombatUnit) -> bool: return u.alive).size()
	for h in sim.heroes:
		if not h.alive:
			continue
		if not acted.has(h.id):
			acted[h.id] = sim.turn_no
		var idle: int = sim.turn_no - int(acted[h.id])
		if idle > maxi(4 * alive, 16) or int(skips.get(h.id, 0)) > MAX_SKIPS:
			acted["_reported"] = true
			_fail("kontroll", "%s har inte fått agera på %d turer (%d egna turer tagna) i %s (statusar %s)" % [h.id, idle,
					int(skips.get(h.id, 0)), encounter, ", ".join(h.auras.keys())])
			return


func _fight() -> void:
	state.fight()
	if not state.battle_pending:
		_fail("strid", "fight() på en grupp gav ingen strid")
		ended = "error"
		return
	stats.battles += 1
	run_fights += 1
	if state.current_room().get("boss", false):
		stats.bosses += 1
	if state.current_room().get("elite", false) and not profile.elites_met.has(state.encounter()):
		profile.elites_met.append(state.encounter())
	# Ibland stängs appen mitt i striden: körningen läses in och striden börjar om (Run._resume_run).
	if pick.randf() < 0.05 and not cfg.get("no_save", false):
		_save_and_load()
		if not state.battle_pending:
			_fail("spara", "battle_pending försvann vid inläsningen")
	var opts := state.battle_opts()
	opts.levels = profile.levels_for(data, state.party)
	state.apply_vow(data, opts)
	var sim := CombatSim.create(data, state.encounter(), seed_now * 1000 + step_now, state.party, state.hero_traits(data),
			state.charges, state.artifacts, state.depth, opts)
	sim.begin()
	var guard := 0
	var acted := {}  # 0.30.25: när varje hjälte senast agerade (kedjad kontroll)
	var forfeit_ok: bool = pick.randf() < 0.03 and not cfg.get("no_forfeit", false)
	while sim.outcome == "" and guard < MAX_BATTLE_STEPS:
		guard += 1
		if not sim.needs_input():
			sim.ai_act()
		else:
			if forfeit_ok and pick.randf() < 0.05:
				sim.forfeit()
				break
			_hero_turn(sim)
		_check_battle(sim)
		_check_control(sim, sim.drain_events(), acted, state.encounter())
	if sim.outcome == "":
		var who := ", ".join(sim.units.map(func(u: CombatUnit) -> String:
				return "%s %s/%s%s" % [u.id, str(snappedf(u.hp, 0.1)), str(snappedf(u.max_hp, 0.1)), "" if u.alive else " död"]))
		_fail("strid", "striden %s tog inte slut på %d drag (tur %d): %s; regler %s" % [state.encounter(), MAX_BATTLE_STEPS,
				sim.turn_no, who, str(opts.get("rules", []))])
		ended = "error"
		return
	var won := sim.outcome == "victory"
	run_turns += sim.turn_no
	_award(sim, won)
	state.store_charges(sim)
	_log("strid %s: %s på %d turer%s" % [state.encounter(), sim.outcome, sim.turn_no, " (gav upp)" if sim.forfeited else ""])
	_battle_finished(won, sim.forfeited)


## En hjältes tur: makrot (som AUTO) eller en slumpad giltig handling (som en spelare som trycker).
func _hero_turn(sim: CombatSim) -> void:
	var u := sim.current
	if pick.randf() < float(cfg.p_random_action):
		var choices := []
		for action in ["attack", "defend", "provoke"]:
			if sim.can_act(u, action) == "":
				choices.append([action, ""])
		for ab in u.abilities:
			if sim.can_act(u, "ability", ab) == "":
				choices.append(["ability", ab])
		if not choices.is_empty():
			var c: Array = choices[pick.randi() % choices.size()]
			var targets := sim.valid_targets(u, c[0], c[1])
			var target: String = targets[pick.randi() % targets.size()] if not targets.is_empty() else ""
			if sim.act(c[0], target, c[1]) == "":
				return
	var decision := MacroRunner.decide(sim, u, macros.get(u.id, data.macros.get(u.id, {"lines": []})))
	if decision.ok and sim.act(decision.action, decision.target, decision.ability) == "":
		return
	if sim.act("attack") != "" and sim.act("defend") != "":
		_fail("strid", "%s kunde varken anfalla eller försvara sig (tur %d)" % [u.id, sim.turn_no])
		sim.forfeit()


## Run.award_battle: statistik, fynd och erfarenhet efter en vunnen strid (även till de som stupade).
func _award(sim: CombatSim, won: bool) -> void:
	for u in sim.heroes:
		var h := profile.hero(data, u.id)
		h.battles = int(h.battles) + 1
		h.wins = int(h.wins) + (1 if won else 0)
	if won:
		var r := state.current_room()
		state.vow_after_battle(data, sim)
		_roll_finds("boss" if r.get("boss", false) else RunState.fight_kind(r))
		var ups := profile.grant_xp(data, state.party, HeroStats.battle_xp(RunState.fight_kind(r), state.depth, r.get("boss", false)))
		for id in ups:
			run_ups += ups[id].size()
		run_upfights += 1 if not ups.is_empty() else 0
		run_pal_ups += ups.get("paladin", []).size()


func _roll_finds(kind: String) -> void:
	var finds := Forge.roll_finds(data, kind, state.depth, state.depth > profile.best_depth, state.instability, rng,
			profile.next_stone_id, state.growth)
	for f in finds:
		if f.kind == "nether":
			profile.next_stone_id += 1
		state.found[f.kind] = int(state.found.get(f.kind, 0)) + int(f.get("count", 1))
	profile.add_finds(finds)
	profile.start_find_quest(finds)


## Run.battle_finished och lägret efter en seger (camp_screen: välj en trofé, VIDARE).
func _battle_finished(victory: bool, forfeited: bool) -> void:
	if not victory:
		var lr := state.current_room()
		lost_at = "v%d %s" % [state.floor + 1, "boss" if lr.get("boss", false) else ("Nemesis" if lr.get("nemesis", false)
				else ("elit" if lr.get("elite", false) else ("föremål" if lr.get("kind", "") == "object" else "vanlig")))]
		stats.forfeit += 1 if forfeited else 0
		stats.lost += 1
		_end_descent()
		RunState.delete_saved(TMP_RUN)
		ended = "forfeit" if forfeited else "lost"
		return
	profile.silver += roundi(state.battle_silver(state.depth) * state.silver_mult(data))
	if state.current_room().get("kind", "") == "end" and state.is_last_floor():
		for kind in data.encounters[state.encounter()].enemies:
			if data.enemies[kind].get("boss", false):
				profile.defeat_boss(kind)
		if data.encounters[state.encounter()].get("guardian", false):
			profile.defeat_guardian(state.encounter())
	RunScript.mark_sneak(data, profile, state)
	var offer := state.trophy_offer(data, rng, state.last_elites, profile.unlocked_boss_trophies(),
			profile.unlocked_guardians())
	var done_now := state.battle_won()
	match state.current_room().get("kind", ""):
		"prisoner":
			_rescue()
		"treasure":
			_treasure()
		"item":
			done_now = state.collect_item() or done_now
		"object":
			var w := state.object_won()
			profile.silver += roundi(w.silver * state.silver_mult(data))
	_after_quest_check(done_now)
	for t in offer:
		profile.add_trophy(t)
	# Lägret: välj en av troféerna (eller ingen) och ge den kanske till någon.
	if human and not offer.is_empty() and not human_off.has("trophies"):
		var best: String = offer[0]
		for t in offer:
			if _trophy_score(t) > _trophy_score(best):
				best = t
		state.take_trophy(best)  # efter striden väljer man bara; den bärs först efter en lägereld
	elif not offer.is_empty() and pick.randf() < 0.8:
		var chosen: String = offer[pick.randi() % offer.size()]
		if pick.randf() < 0.5:
			state.equip(state.party[pick.randi() % state.party.size()], chosen)
		state.take_trophy(chosen)
	_after_camp()


## Run.after_camp: tillbaka till grottan, eller hem när bossen är besegrad.
func _after_camp() -> void:
	profile.keep_worn(state.equipped, state.party)
	if state.floor_cleared() and state.is_last_floor():
		profile.clear_depth(state.depth, state.realm)
		_end_descent()
		state.finished = true
		RunState.delete_saved(TMP_RUN)
		stats.cleared += 1
		ended = "cleared"
		return
	arrived = false


## Run._after_quest_check.
func _after_quest_check(just_done: bool) -> void:
	if just_done or (state.quest.get("done", false) and not state.quest.get("rewarded", false)):
		state.quest.rewarded = true
		if not state.is_last_floor():
			profile.floor_quest_silver(state.depth)
			return
		profile.complete_quest(state.realm, state.depth)


## Run.end_descent: den levande kartan efter en nedstigning, och dess invarianter.
func _end_descent() -> void:
	if state.practice or state.first_descent or state.finished:
		return
	var before := {}
	for r in data.realms:
		before[r] = LivingMap.growth(profile, r)
	var list := LivingMap.after_descent(profile, data, state.realm, state.wins, state.realm_quest_done)
	if OS.get_environment("VARLD") != "av":
		var outcome := "boss" if state.floor_cleared() and state.is_last_floor() else "loss"
		var w := WorldEvents.after_descent(profile, data, state.realm, WorldEvents.outcome_for(state, data, outcome), state.wins,
				state.realm_quest_done, before)
		if not w.event_start.is_empty():
			world_stats.started[w.event_start.id] = int(world_stats.started.get(w.event_start.id, 0)) + 1
		if not w.event_end.is_empty():
			var key := "%s:%s" % [w.event_end.id, w.event_end.result]
			world_stats.results[key] = int(world_stats.results.get(key, 0)) + 1
		for r in w.costs_on:
			world_stats.costs_on[r] = int(world_stats.costs_on.get(r, 0)) + 1
		for g in w.gifts:
			world_stats.gifts[g.realm] = int(world_stats.gifts.get(g.realm, 0)) + 1
		if String(w.tor) != "":
			world_stats.tor += 1
		if WorldEvents.active(profile).size() > 0 and int(WorldEvents.active(profile).left) <= 0:
			_fail("levande värld", "händelsen har gått ut men pågår: %s" % str(WorldEvents.active(profile)))
	if state.wins == 0 and not list.is_empty():
		_fail("levande karta", "fördärvet ändrades utan en vunnen strid: %s" % str(list))
	for r in data.realms:
		var g := int(profile.growth.get(r, LivingMap.GROWTH_START))
		if g < 0 or g > LivingMap.GROWTH_MAX:
			_fail("levande karta", "%s har fördärv %d" % [r, g])
		if r == state.realm and state.wins > 0 and g > int(before[r]):
			_fail("levande karta", "%s växte fast man gick dit (%d → %d)" % [r, before[r], g])
		if r != state.realm and g < int(before[r]):
			_fail("levande karta", "%s sjönk fast ingen gick dit (%d → %d)" % [r, before[r], g])
	if state.twisted != "" and LivingMap.growth(profile, state.realm) >= LivingMap.GROWTH_MAX and state.wins > 0:
		_fail("levande karta", "den förvridna bossen är kvar efter en nedstigning dit")


## Hem till borgen: introts hemkomst (base_screen) och kontrollen av berättelsen.
func _home() -> void:
	if profile.intro_done or state == null:
		return
	var had_imma := state.party.has("imma") or state.joins_next == "imma"
	if Intro.current(data, profile).get("event", "") == "came_home" and profile.total_descents() > 0 \
			and profile.recruited.has("imma"):
		Intro.notify(data, profile, "came_home")
		if Intro.current(data, profile).get("id", "") != "crypt":
			_fail("intro", "efter hemkomsten står introt på %s, inte crypt" % Intro.current(data, profile).get("id", ""))
		if not profile.recruited.has("imma"):
			_fail("intro", "Imma är inte rekryterad efter hemkomsten")
		if not had_imma:
			# Gorms och Immas hemkomstsamtal förutsätter att Imma smet efter och att Benfursten möttes.
			_fail("berättelse", "hemkomst (%s) innan Imma anslöt: Gorm och Imma talar ändå om nedstigningen" % ended)


# --- Sparning och kontroller ----------------------------------------------------

## Sparar körningen och profilen, läser in dem igen och fortsätter från de inlästa.
func _save_and_load() -> void:
	stats.saves += 1
	if state.save(TMP_RUN) != OK:
		_fail("spara", "RunState.save misslyckades")
		return
	var loaded := RunState.load_from(TMP_RUN)
	if loaded == null:
		_fail("spara", "RunState.load_from gav null")
		return
	var diff := _first_diff(_normal(state.to_dict()), _normal(loaded.to_dict()))
	if diff != "":
		_fail("spara", "körningen ändrades vid sparning: " + diff)
	state = loaded
	var p_before := _profile_view(profile)
	profile.save(TMP_PROFILE)
	var p := Profile.load_from(TMP_PROFILE)
	if p == null:
		_fail("spara", "Profile.load_from gav null")
		return
	var p_diff := _first_diff(p_before, _profile_view(p))
	if p_diff != "":
		_fail("spara", "profilen ändrades vid sparning: " + p_diff)
	profile = p


## Det i profilen som ska överleva en sparning.
func _profile_view(p: Profile) -> Dictionary:
	return _normal({"silver": p.silver, "collection": p.collection, "recruited": Array(p.recruited), "party": Array(p.party),
			"heroes": p.heroes, "worn": p.worn, "artifacts": p.artifacts, "materials": p.materials, "stones": p.stones,
			"intro_step": p.intro_step, "intro_done": p.intro_done, "descents": p.descents, "quests_done": p.quests_done,
			"oath": p.oath, "perks": p.perks, "elites_met": p.elites_met, "find_quest": p.find_quest,
			"boss_wins": p.boss_wins, "best_depth": p.best_depth})


## JSON-jämförbar kopia (typade arrayer och heltal som flyttal ska inte räknas som skillnad).
func _normal(v: Variant) -> Variant:
	if v is Dictionary:
		var out := {}
		for k in v:
			out[str(k)] = _normal(v[k])
		return out
	if v is Array:
		return Array(v).map(func(x: Variant) -> Variant: return _normal(x))
	if v is float and is_equal_approx(v, roundf(v)):
		return int(v)
	return v


func _first_diff(a: Variant, b: Variant, path := "") -> String:
	if a is Dictionary and b is Dictionary:
		for k in a:
			if not b.has(k):
				return "%s/%s saknas efter" % [path, k]
			var d := _first_diff(a[k], b[k], "%s/%s" % [path, k])
			if d != "":
				return d
		for k in b:
			if not a.has(k):
				return "%s/%s finns bara efter" % [path, k]
		return ""
	if a is Array and b is Array:
		if a.size() != b.size():
			return "%s: %d mot %d element" % [path, a.size(), b.size()]
		for i in a.size():
			var d := _first_diff(a[i], b[i], "%s[%d]" % [path, i])
			if d != "":
				return d
		return ""
	# Flyttal jämförs med en relativ tolerans: ConfigFile skriver dem med färre decimaler (t.ex. Nether Stones kvalitet
	# 1.31107497 → 1.311075), vilket inte märks i spelet.
	if (a is float or a is int) and (b is float or b is int):
		return "" if absf(float(a) - float(b)) <= 0.0001 * maxf(1.0, absf(float(a))) else "%s: %s → %s" % [path, a, b]
	return "" if JSON.stringify(a) == JSON.stringify(b) else "%s: %s → %s" % [path, JSON.stringify(a), JSON.stringify(b)]


## Varje ny våning: grottans egna regler (Grotto.problems) ska hålla.
func _check_floor() -> void:
	var probs := state.map.problems(state.quest)
	if not probs.is_empty():
		_fail("grotta", "våning %d bryter mot reglerna: %s" % [state.floor, ", ".join(probs)])


## Efter varje drag på kartan.
func _check_state() -> void:
	if profile.silver < silver_floor:
		_fail("silver", "silvret sjönk från %d till %d" % [silver_floor, profile.silver])
	silver_floor = maxi(silver_floor, profile.silver)
	for t in collection_floor:
		if not profile.collection.has(t):
			_fail("samling", "trofén %s försvann ur samlingen" % t)
	collection_floor = profile.collection.duplicate()
	if state.party.is_empty() or state.party[0] != "paladin":
		_fail("sällskap", "Paladinen är inte först: %s" % str(state.party))
	if state.party.size() > RunState.PARTY_SIZE:
		_fail("sällskap", "för stort sällskap: %s" % str(state.party))
	var unique := {}
	for h in state.party:
		if unique.has(h):
			_fail("sällskap", "%s finns två gånger" % h)
		unique[h] = true
		if not state.charges.has(h):
			_fail("charges", "%s saknar Charges" % h)
	for h in state.charges:
		for a in state.charges[h]:
			var n := int(state.charges[h][a])
			var full := int(data.abilities[a].get("charges", 0))
			if n < 0:
				_fail("charges", "%s/%s har %d Charges" % [h, a, n])
			elif full > 0 and n > full + 12:
				_fail("charges", "%s/%s har %d Charges (fullt %d)" % [h, a, n, full])
	for h in state.equipped:
		if not state.trophies.has(state.equipped[h]):
			_fail("trofé", "%s bär %s som inte finns bland körningens troféer" % [h, state.equipped[h]])
	if state.map != null:
		if not state.visited.has(state.pos):
			_fail("karta", "pjäsen står på en obesökt ruta %d" % state.pos)
		if int(state.quest.get("progress", 0)) > int(state.quest.get("goal", 0)):
			_fail("quest", "progress över målet: %s" % JSON.stringify(state.quest))


## Under striden, efter varje handling.
func _check_battle(sim: CombatSim) -> void:
	for u in sim.units:
		for stat in ["hp", "max_hp", "attack", "intelligence", "defense", "speed", "barrier"]:
			var v: float = u.get(stat)
			if is_nan(v) or is_inf(v):
				_fail("stats", "%s.%s är %s (%s, tur %d)" % [u.id, stat, str(v), state.encounter(), sim.turn_no])
			elif v < -0.001 and stat != "defense":
				_fail("stats", "%s.%s är negativ: %s (%s, tur %d)" % [u.id, stat, str(v), state.encounter(), sim.turn_no])
		if u.hp > u.max_hp + 0.01:
			_fail("stats", "%s har %s liv av %s" % [u.id, str(u.hp), str(u.max_hp)])
		if u.max_hp <= 0.0:
			_fail("stats", "%s har max_hp %s" % [u.id, str(u.max_hp)])
		if u.alive and u.hp <= 0.0 and sim.outcome == "":
			_fail("stats", "%s lever med %s liv (tur %d)" % [u.id, str(u.hp), sim.turn_no])
		for a in u.charges:
			if int(u.charges[a]) < 0:
				_fail("charges", "%s/%s har %d Charges i striden" % [u.id, a, int(u.charges[a])])


# --- Hjälpare ------------------------------------------------------------------

## Kör ett drag och gör körfel till fel med frö och drag.
func _guard(what: String, f: Callable) -> void:
	catcher.errors.clear()
	catcher.active = true
	f.call()
	catcher.active = false
	for e in catcher.errors:
		_fail("körfel", "%s: %s" % [what, e])
	if not catcher.errors.is_empty() and ended == "":
		ended = "error"


func _fail(kind: String, msg: String) -> void:
	errors.append({"seed": seed_now, "step": step_now, "kind": kind, "msg": msg, "cfg": _cfg_text()})
	if verbose:
		print("  FEL [%s] drag %d: %s" % [kind, step_now, msg])


func _log(msg: String) -> void:
	if verbose:
		print("  %4d v%d r%d: %s" % [step_now, state.floor if state else -1, state.pos if state else -1, msg])


func _cfg_text() -> String:
	if cfg.is_empty():
		return ""
	return "%s djup %d inst %d %s sällskap %s nivå %d %s%s" % [cfg.realm, cfg.depth, cfg.instability,
			profile.oath if profile else cfg.oath,
			str(["paladin"] + Array(cfg.party)) if not cfg.first else "[paladin]", cfg.level if not cfg.first else 1, cfg.policy,
			(" FÖRSTA NEDSTIGNINGEN" if cfg.first else "") + (" löfte " + String(cfg.vow) if String(cfg.get("vow", "")) != "" else "")]


func _report(ms: int) -> void:
	print("")
	print("=== Soak: %d körningar på %.0f s ===" % [stats.runs, ms / 1000.0])
	print("  klarade %d, förlorade %d (gav upp %d), gick hem %d; %d drag, %d strider, %d bossar, %d sparningar" % [
			stats.cleared, stats.lost, stats.forfeit, stats.left, stats.actions, stats.battles, stats.bosses, stats.saves])
	print("  föremål %d, helgedomar %d, lägereldar %d, befrielser %d, skatter %d, trappor %d" % [stats.objects,
			stats.shrines, stats.campfires, stats.rescues, stats.treasures, stats.descends])
	_print_errors()


func _print_errors() -> void:
	if errors.is_empty():
		print("  Inga fel.")
		return
	# Samma sorts fel (sort + början av texten) visas en gång, med antal och de första fröna.
	var groups := {}
	for e in errors:
		var key := "%s|%s" % [e.kind, String(e.msg).substr(0, 60)]
		if not groups.has(key):
			groups[key] = {"n": 0, "seeds": [], "first": e}
		groups[key].n += 1
		if groups[key].seeds.size() < 5 and not groups[key].seeds.has(e.seed):
			groups[key].seeds.append(e.seed)
	var keys := groups.keys()
	keys.sort_custom(func(a: String, b: String) -> bool: return groups[a].n > groups[b].n)
	print("  %d fel i %d sorter:" % [errors.size(), keys.size()])
	for k in keys:
		var g: Dictionary = groups[k]
		printerr("  [%s] ×%d frön %s – %s (drag %d; %s)" % [g.first.kind, g.n, str(g.seeds), g.first.msg, g.first.step,
				g.first.cfg])
	print("  Återskapa: godot --headless --path . --script res://tests/soak.gd -- --seed=<frö> --verbose")


# --- SOAK=nivaer: nivån efter första nedstigningen och den andra med just den nivån ----------------------------

func _levels_report(from: int, runs: int) -> void:
	var rows := {"won": [], "lost": []}
	var second := {"won": 0, "n": 0, "by": {}}
	for s in range(from, from + runs):
		seed_now = s
		step_now = 0
		pick.seed = s * 7919 + 3
		rng.seed = s * 104729 + 11
		cfg = {"first": true, "realm": "crypt", "depth": 1, "instability": 0, "oath": "oath_vengeance", "party": [],
				"level": 1, "policy": "bot", "p_random_action": 0.0, "descents": 0, "no_forfeit": true}
		_setup_profile()
		_run_quiet()
		var first_result := ended
		var lv := {}
		for h in ["paladin", "imma"]:
			lv[h] = int(profile.hero(data, h).level) if profile.heroes.has(h) else 0
		rows["won" if first_result == "cleared" else "lost"].append(lv)
		# Hemkomsten, sedan den andra nedstigningen med samma profil (Alva i ett fånge-rum), utan att svärdet höjs.
		_home()
		var key := "P%d I%d" % [lv.paladin, lv.imma]
		cfg.first = false
		_run_quiet()
		second.n += 1
		second.won += 1 if ended == "cleared" else 0
		var b: Dictionary = second.by.get(key, {"n": 0, "won": 0})
		b.n += 1
		b.won += 1 if ended == "cleared" else 0
		second.by[key] = b
	print("=== Nivån efter första nedstigningen (kryptan, ny profils makron, svärd med Rättfärdigt slag, %d frön) ===" % runs)
	for k in ["won", "lost"]:
		var list: Array = rows[k]
		if list.is_empty():
			continue
		var by := {}
		for lv in list:
			var key := "Paladinen %d, Imma %d" % [lv.paladin, lv.imma]
			by[key] = int(by.get(key, 0)) + 1
		print("  %s: %d körningar – %s" % ["vunnen" if k == "won" else "förlorad", list.size(), str(by)])
	print("=== Andra nedstigningen med just de nivåerna: %d %% vinst (%d av %d) ===" % [roundi(100.0 * second.won / maxi(second.n, 1)),
			second.won, second.n])
	var keys: Array = second.by.keys()
	keys.sort()
	for k in keys:
		print("  %s: %d %% (%d av %d)" % [k, roundi(100.0 * second.by[k].won / second.by[k].n), second.by[k].won, second.by[k].n])
	_print_errors()


## En körning med botens val (för nivårapporten).
func _run_quiet() -> void:
	ended = ""
	step_now = 0
	_guard("start_run", _start_run)
	while ended == "" and step_now < MAX_ACTIONS:
		step_now += 1
		_guard("drag", _tick.bind(true))
	if ended == "":
		ended = "stuck"


## Makroförslaget när en ny sorts hjälte ansluter (LÄGG TILL RADEN), bara i karriärläget (cfg.hints).
func _take_hint(hero_id: String) -> void:
	if hero_id == "" or not cfg.get("hints", false):
		return
	var hint: Dictionary = data.heroes.get(hero_id, {}).get("macro_hint", {})
	if hint.is_empty():
		return
	if not macros.has(hero_id):
		macros[hero_id] = {"name": data.heroes[hero_id].name, "lines": []}
	for line in macros[hero_id].lines:
		if line.get("cond", "") == hint.line.cond and line.get("action", "") == hint.line.action \
				and line.get("ability", "") == hint.line.get("ability", ""):
			return
	macros[hero_id].lines.insert(0, hint.line.duplicate(true))


# --- SOAK=karriar: svårighetskurvan, en profil i taget genom många nedstigningar ------------------------------

## Djupet: ett djupare efter en klarad körning, ett grundare efter två förluster i rad. Realm: växlar varje gång.
## Hemma: smedjan (svärdet till nivå 3, sedan en artefakt till den som saknar, sedan den lägsta artefakten), den
## billigaste perken, och sällskapet = de tre följeslagarna med högst nivå. Startmakron (en ny profils rader) med
## makroförslagen när någon ansluter; MACRO-boten, inga slumpade handlingar, ingen GE UPP och ingen GÅ HEM.
func _career_report(from: int, runs: int, descents: int) -> void:
	var rows: Array = []  # per nedstigning: lista med {level, depth, won, fights, silver, heroes, lost_at, realm, best}
	for i in descents:
		rows.append([])
	var t0 := Time.get_ticks_msec()
	for s in range(from, from + runs):
		seed_now = s
		pick.seed = s * 7919 + 3
		rng.seed = s * 104729 + 11
		cfg = {"first": true, "realm": "crypt", "depth": 1, "instability": 0, "oath": "oath_vengeance", "party": [],
				"level": 1, "policy": "bot", "p_random_action": 0.0, "descents": 0, "no_forfeit": true, "no_leave": true,
				"no_save": true, "hints": true, "vow": ""}
		_setup_profile()
		var losses := 0
		for d in descents:
			var realm: String = String(data.realms.keys()[d % data.realms.size()]) if d > 0 else "crypt"  # 0.31: alla Realms i tur
			# Den levande kartan: KARRIAR_REALM=lagst väljer den lugnaste Realmen (undviker fördärvet), =hogst den värsta.
			var how := OS.get_environment("KARRIAR_REALM")
			if d >= data.realms.size() and how in ["lagst", "hogst"]:
				var keys: Array = data.realms.keys()
				var order: Array = data.realms.keys()
				keys.sort_custom(func(a: String, b: String) -> bool:
						var ga := LivingMap.growth(profile, a)
						var gb := LivingMap.growth(profile, b)
						if ga != gb:
							return ga < gb if how == "lagst" else ga > gb
						return order.find(a) < order.find(b))
				realm = keys[0]
			profile.realm = realm
			var growth_before := LivingMap.growth(profile, realm)
			var before := profile.silver
			var best_before := profile.best_depth
			var party := Array(profile.party)
			var lv := 0.0
			var art := 0.0  # balanssim: artefaktnivå (0 utan) och burna troféer per hjälte i sällskapet
			var worn_n := 0.0
			for h in party:
				lv += float(profile.hero(data, h).level)
				art += float(profile.artifact(h).get("level", 0))
				worn_n += 1.0 if String(profile.worn.get(h, "")) != "" else 0.0
			lv /= maxf(party.size(), 1)
			art /= maxf(party.size(), 1)
			worn_n /= maxf(party.size(), 1)
			run_fights = 0
			run_ups = 0
			run_upfights = 0
			run_pal_ups = 0
			lost_at = ""
			cfg.first = d == 0
			_run_quiet()
			_home()
			var won := ended == "cleared"
			rows[d].append({"level": lv, "art": art, "worn": worn_n, "depth": profile.depth, "won": won, "fights": run_fights,
					"silver": profile.silver - before, "heroes": party.size(), "lost_at": lost_at if not won else "",
					"realm": realm, "best": best_before, "recruited": profile.recruited.size(),
					"ups": run_ups, "upfights": run_upfights, "pal_ups": run_pal_ups,
					"pal_level": int(profile.hero(data, "paladin").level),
					"growth": growth_before if d > 0 else -1, "twisted": state.twisted != "",
					"map": data.realms.keys().map(func(r: String) -> int: return LivingMap.growth(profile, r))})
			if OS.get_environment("LEVANDE") == "av":
				profile.growth = {}  # jämförelse: kartan står still
				profile.growth_rest = {}
			if verbose:
				print("frö %d nedstigning %d: %s djup %d nivå %.1f %s %s strider %d silver +%d" % [s, d + 1, realm,
						profile.depth, lv, str(party), ended, run_fights, profile.silver - before])
			# Djupet för nästa gång.
			if won:
				losses = 0
				profile.choose_depth(profile.depth + 1)
			else:
				losses += 1
				if losses >= 2:
					profile.choose_depth(profile.depth - 1)
					losses = 0
			_career_home()
		if (s - from + 1) % 10 == 0:
			print("… %d profiler, %.0f s" % [s - from + 1, (Time.get_ticks_msec() - t0) / 1000.0])
	_career_print(rows, runs, descents)
	_print_errors()


## Hemma mellan nedstigningarna: smedjan, perken och sällskapet.
func _career_home() -> void:
	if not profile.intro_done and Intro.needs_talk(data, profile):
		Intro.talked(data, profile)  # borgen spelar Gorms samtal när man kommer hem ("auto")
	var guard := 0
	while guard < 40:
		guard += 1
		var sword := profile.artifact("paladin")
		if not sword.is_empty() and int(sword.level) < 3:
			if profile.level_artifact("paladin") == null:
				break
			Intro.notify(data, profile, "sword_level", int(profile.artifact("paladin").level))
			continue
		var party: Array = Array(profile.party)
		var bare := party.filter(func(h: String) -> bool: return profile.artifact(h).is_empty())
		if not bare.is_empty():
			var h: String = bare[0]
			var abilities: Array = data.heroes[h].get("abilities", [])
			if profile.silver < Profile.FORGE_COST or not profile.forge(h, "sword", abilities[0] if not abilities.is_empty() else ""):
				break
			continue
		var lowest := ""
		for h in party:
			var a := profile.artifact(h)
			if not a.is_empty() and int(a.level) < Forge.LEVEL_MAX and (lowest == "" or int(a.level) < int(profile.artifact(lowest).level)):
				lowest = h
		if lowest == "" or profile.level_artifact(lowest) == null:
			break
	# Den billigaste perken som går att köpa, tills poängen är slut.
	var perks: Array = data.oaths[profile.oath].get("perks", []).map(func(p: Variant) -> String:
			return String(p.get("id", "")) if p is Dictionary else String(p))
	for i in 10:
		var best := ""
		var cost := 99
		for perk in perks:
			var c := Profile.perk_cost(data, profile.oath, perk)
			if c >= 0 and c < cost and profile.perk_rank(profile.oath, perk) < Profile.perk_ranks(data, perk):
				best = perk
				cost = c
		if best == "" or not profile.buy_perk(data, profile.oath, best):
			break
	# Sällskapet: de tre följeslagarna med högst nivå (Värdshuset).
	if profile.intro_done or profile.recruited.size() > 1:
		var list: Array = Array(profile.recruited).duplicate()
		list.sort_custom(func(a: String, b: String) -> bool:
				return int(profile.hero(data, a).level) > int(profile.hero(data, b).level))
		profile.set_party(list.slice(0, profile.max_companions()))


func _career_print(rows: Array, runs: int, descents: int) -> void:
	print("")
	print("=== Svårighetskurvan: %d profiler, %d nedstigningar var ===" % [runs, descents])
	print("  ned  djup (snitt, spridning)   nivå   vinst  strider  silver  hjältar  förluster")
	for d in descents:
		var list: Array = rows[d]
		var n := list.size()
		var won := list.filter(func(r: Dictionary) -> bool: return r.won).size()
		var depth_mix := {}
		var where := {}
		var lv := 0.0
		var fights := 0.0
		var silver := 0.0
		var heroes := 0.0
		for r in list:
			depth_mix[r.depth] = int(depth_mix.get(r.depth, 0)) + 1
			lv += r.level
			fights += r.fights
			silver += r.silver
			heroes += r.heroes
			if r.lost_at != "":
				where[r.lost_at] = int(where.get(r.lost_at, 0)) + 1
		var depths := depth_mix.keys()
		depths.sort()
		var mix := " ".join(depths.map(func(k: int) -> String: return "d%d:%d" % [k, depth_mix[k]]))
		var avg_depth := 0.0
		for k in depth_mix:
			avg_depth += float(k) * depth_mix[k]
		var keys := where.keys()
		keys.sort_custom(func(a: String, b: String) -> bool: return where[a] > where[b])
		print("  %3d  %.1f (%s)  %5.1f  %4d %%  %6.1f  %6d  %6.1f   %s" % [d + 1, avg_depth / maxi(n, 1), mix,
				lv / maxi(n, 1), roundi(100.0 * won / maxi(n, 1)), fights / maxi(n, 1), roundi(silver / maxi(n, 1)),
				heroes / maxi(n, 1), ", ".join(keys.slice(0, 4).map(func(k: String) -> String: return "%s %d" % [k, where[k]]))])
	# Per djup och Realm: vinst och nivå, och hur ofta man spelar under sitt bästa djup (slipar).
	print("")
	print("  Per djup och Realm (alla nedstigningar):")
	var by := {}
	var grind := 0
	var total := 0
	for d in descents:
		for r in rows[d]:
			var key := "%s d%d" % [r.realm, r.depth]
			var b: Dictionary = by.get(key, {"n": 0, "won": 0, "lv": 0.0, "art": 0.0, "worn": 0.0})
			b.n += 1
			b.won += 1 if r.won else 0
			b.lv += r.level
			b.art += r.art
			b.worn += r.worn
			by[key] = b
			total += 1
			if r.depth <= r.best and d > 0:
				grind += 1
	var ks := by.keys()
	ks.sort()
	for k in ks:
		print("    %-12s %4d körningar  vinst %3d %%  nivå %.1f  artefakt %.1f  trofé %.2f" % [k, by[k].n,
				roundi(100.0 * by[k].won / by[k].n), by[k].lv / by[k].n, by[k].art / by[k].n, by[k].worn / by[k].n])
	print("  På ett djup som redan är klarat (slipar): %d av %d nedstigningar" % [grind, total])
	_pace_print(rows, descents)
	_living_print(rows, runs, descents)


## Nivåtakten (prototyp, docs/plan/nivaer-och-charges.md): Paladinens nivå efter nedstigningen, nivåer per nedstigning
## (Paladinen och alla hjältar), andelen vunna strider där någon steg i nivå, och strider per Paladinens nivå.
func _pace_print(rows: Array, descents: int) -> void:
	print("")
	print("  Nivåtakten (variant: %s):" % ("i dag (0.19)" if HeroStats.legacy else "kurvan"))
	print("  ned  pal.nivå efter  pal.nivåer  alla nivåer  strider m. nivå  strider/pal.nivå")
	var tot_f := 0.0
	var tot_p := 0.0
	for d in descents:
		var list: Array = rows[d]
		var n := maxi(list.size(), 1)
		var pl := 0.0
		var pu := 0.0
		var au := 0.0
		var uf := 0.0
		var f := 0.0
		for r in list:
			pl += r.pal_level
			pu += r.pal_ups
			au += r.ups
			uf += r.upfights
			f += r.fights
		tot_f += f
		tot_p += pu
		print("  %3d  %13.1f  %10.2f  %11.2f  %13d %%  %15s" % [d + 1, pl / n, pu / n, au / n,
				roundi(100.0 * uf / maxf(f, 1.0)), ("%.1f" % (f / pu)) if pu > 0 else "–"])
	print("  Totalt: %.1f strider per Paladinens nivå" % (tot_f / maxf(tot_p, 1.0)))


## Den levande kartan: vinst per steg i den Realm man gick till, den förvridna bossen och kartans läge per nedstigning.
func _living_print(rows: Array, runs: int, descents: int) -> void:
	print("")
	print("  Den levande kartan (%s, Realm: %s):" % ["av" if OS.get_environment("LEVANDE") == "av" else "på",
			OS.get_environment("KARRIAR_REALM") if OS.get_environment("KARRIAR_REALM") != "" else "rotera"])
	var per := {}
	var twisted := {"n": 0, "won": 0}
	for d in descents:
		for r in rows[d]:
			if int(r.growth) < 0:
				continue
			var b: Dictionary = per.get(int(r.growth), {"n": 0, "won": 0})
			b.n += 1
			b.won += 1 if r.won else 0
			per[int(r.growth)] = b
			if r.twisted:
				twisted.n += 1
				twisted.won += 1 if r.won else 0
	for g in range(0, LivingMap.GROWTH_MAX + 1):
		if per.has(g):
			print("    steg %d: %4d nedstigningar  vinst %3d %%" % [g, per[g].n, roundi(100.0 * per[g].won / per[g].n)])
	print("    med den förvridna bossen: %d nedstigningar, %d klarade (%.2f per profil)" % [twisted.n, twisted.won,
			float(twisted.n) / maxi(runs, 1)])
	var line := "    kartan efter nedstigning (snitt %s):" % "/".join(data.realms.keys())
	for d in descents:
		var sums := []
		for i in data.realms.size():
			sums.append(0.0)
		for r in rows[d]:
			for i in data.realms.size():
				sums[i] += float(r.map[i])
		var parts := []
		for x in sums:
			parts.append("%.1f" % (x / maxi(rows[d].size(), 1)))
		line += " %d:%s" % [d + 1, "/".join(parts)]
	print(line)
	print("")
	print("  Den levande världen (%s): händelser som startade %s" % ["av" if OS.get_environment("VARLD") == "av" else "på",
			str(world_stats.started)])
	print("    utfall %s" % str(world_stats.results))
	print("    följder som började %s, gåvor %s, Tors bärnsten %d gånger, %.2f händelser per profil" % [
			str(world_stats.costs_on), str(world_stats.gifts), world_stats.tor,
			float(world_stats.started.values().reduce(func(a: int, b: int) -> int: return a + b, 0)) / maxi(runs, 1)])


# --- SOAK=karriar_mansklig: en mänskligare karriär (docs/provspel/manskliga-botar.md) -------------------------------

## Speltiden är en uppskattning (playtime.cfg har inga riktiga mätningar än): sekunder per tur i striden (alla figurers,
## AUTO i 1×), per steg i grottan, per strid (in- och utgång, segerskärm) och per nedstigning (borgen, smedjan, kartan).
const T_TURN := 2.5
const T_STEP := 1.2
const T_BATTLE := 10.0
const T_HOME := 120.0
## En spelare som förlorat på djup N och tränat till väntad nivå men förlorar igen tränar 3 nivåer till per nytt försök.
const TRAIN_EXTRA := 3


## Som _career_report, men boten beter sig som en spelare: efter en förlust på djup N går den ned ett djup och tränar
## tills sällskapets snittnivå når fiendernas väntade nivå på N (HeroStats.expected_level), sedan försöker den igen.
## Hemma smider den, höjer artefakter och sätter material (_human_home); troféerna väljs efter sällsynthet
## (Förberedelser och lägereldar). KARRIAR_REALM=crypt/chapel/mountain/grove: Realmen efter första nedstigningen.
func _human_report(from: int, runs: int, descents: int) -> void:
	var realm_fixed := OS.get_environment("KARRIAR_REALM")
	if not data.realms.has(realm_fixed):
		realm_fixed = "crypt"
	var profiles: Array = []  # per profil: {first_try, first_clear, sec_at_clear, train, attempts, best, sec, rows}
	var t0 := Time.get_ticks_msec()
	for s in range(from, from + runs):
		seed_now = s
		pick.seed = s * 7919 + 3
		rng.seed = s * 104729 + 11
		cfg = {"first": true, "realm": "crypt", "depth": 1, "instability": 0, "oath": "oath_vengeance", "party": [],
				"level": 1, "policy": "bot", "p_random_action": 0.0, "descents": 0, "no_forfeit": true, "no_leave": true,
				"no_save": true, "hints": true, "vow": ""}
		_setup_profile()
		var rec := {"first_try": {}, "first_clear": {}, "sec_at_clear": {}, "train": {}, "attempts": {}, "sec": 0.0,
				"fights": 0, "turns": 0, "lost": {}}
		var train_for := 0
		var retries := {}  # försök på N efter att ha tränat till målet
		var losses := 0
		for d in descents:
			profile.realm = realm_fixed if d > 0 else "crypt"
			var depth := profile.depth
			if not rec.first_try.has(depth):
				rec.first_try[depth] = d
			if train_for == 0:
				rec.attempts[depth] = int(rec.attempts.get(depth, 0)) + 1
			else:
				rec.train[train_for] = int(rec.train.get(train_for, 0)) + 1
			if not human_off.has("trophies"):
				_wear_best()
			run_fights = 0
			run_turns = 0
			run_steps = 0
			lost_at = ""
			cfg.first = d == 0
			_run_quiet()
			_home()
			var won := ended == "cleared"
			rec.sec += run_turns * T_TURN + run_steps * T_STEP + run_fights * T_BATTLE + T_HOME
			rec.fights += run_fights
			rec.turns += run_turns
			if not won and lost_at != "":
				var by: Dictionary = rec.lost.get(depth, {})
				by[lost_at] = int(by.get(lost_at, 0)) + 1
				rec.lost[depth] = by
			if won and not rec.first_clear.has(depth):
				rec.first_clear[depth] = d
				rec.sec_at_clear[depth] = rec.sec
			if verbose:
				print("frö %d ned %d: %s djup %d nivå %.1f %s%s strider %d" % [s, d + 1, profile.realm, depth, _party_level(),
						ended, " (tränar för %d)" % train_for if train_for > 0 else "", run_fights])
			# Djupet för nästa gång.
			if won:
				losses = 0
				if train_for == 0:
					profile.choose_depth(depth + 1)
			elif train_for == 0:
				if depth > 1 and human_off.has("train"):
					losses += 1
					if losses >= 2:
						profile.choose_depth(depth - 1)
						losses = 0
				elif depth > 1:
					train_for = depth
					retries[depth] = int(retries.get(depth, -1)) + 1
					profile.choose_depth(depth - 1)
				losses = 0
			else:
				losses += 1
				if losses >= 2 and depth > 1:
					profile.choose_depth(depth - 1)
					losses = 0
			if train_for > 0 and _party_level() >= HeroStats.expected_level(train_for) + TRAIN_EXTRA * int(retries[train_for]):
				profile.choose_depth(train_for)
				train_for = 0
				losses = 0
			_career_home()
			if not human_off.has("sockets"):
				_human_home()
		rec.best = profile.best_depth
		rec.level = _party_level()
		profiles.append(rec)
		if (s - from + 1) % 10 == 0:
			print("… %d profiler, %.0f s" % [s - from + 1, (Time.get_ticks_msec() - t0) / 1000.0])
	_human_print(profiles, runs, descents, realm_fixed)
	_print_errors()


func _party_level() -> float:
	var party := Array(profile.party)
	var lv := 0.0
	for h in party:
		lv += float(profile.hero(data, h).level)
	return lv / maxf(party.size(), 1)


## Hemma, efter _career_home (smedjan och perkarna): bärnsten i lediga Stat-platser efter hjältens roll, trick i
## Trick-platser och den bästa Nether Stone i en tom Nether-plats.
func _human_home() -> void:
	for h in Array(profile.party):
		var art := profile.artifact(h)
		if art.is_empty():
			continue
		var role: String = data.heroes.get(h, {}).get("role", "")
		var wish: Array = ["amber_blue", "amber_green"] if role in ["healer", "support", "control"] \
				else (["amber_grey", "amber_green"] if role == "tank" else ["amber_red", "amber_green"])
		for i in Forge.STAT_SLOT_LEVELS.size():
			if not Forge.stat_slot_open(int(art.level), i) or String(art.stat_slots[i]) != "":
				continue
			var options: Array = wish + data.materials.amber.keys()
			for m in options:
				if int(profile.materials.get(m, 0)) >= Forge.AMBER_PER_SLOT and profile.socket(h, "stat", i, m):
					break
		for i in Forge.TRICK_SLOT_LEVELS.size():
			if not Forge.trick_slot_open(int(art.level), i) or String(art.trick_slots[i]) != "":
				continue
			for m in data.materials.tricks.keys():
				if int(profile.materials.get(m, 0)) >= 1 and profile.socket(h, "trick", i, m):
					break
		if Forge.nether_open(int(art.level)) and art.nether.is_empty() and not profile.stones.is_empty():
			var best: Dictionary = profile.stones[0]
			for st in profile.stones:
				if int(st.get("number", 0)) > int(best.get("number", 0)):
					best = st
			profile.socket_stone(h, String(best.id))


## Elit- och bosstroféer före vanliga.
func _trophy_score(t: String) -> int:
	return {"common": 1, "elite": 2, "boss": 2}.get(data.traits.get(t, {}).get("rarity", "common"), 1)


## Förberedelser: de bästa troféerna ur samlingen, en per hjälte i sällskapet.
func _wear_best() -> void:
	var pool: Array = profile.collection.filter(func(t: String) -> bool:
			return data.traits.has(t) and data.traits[t].get("trophy", false))
	pool.sort_custom(func(a: String, b: String) -> bool: return _trophy_score(a) > _trophy_score(b))
	var i := 0
	for h in Array(profile.party):
		if i >= pool.size():
			break
		profile.wear(h, pool[i])
		i += 1


## Lägerelden: byt till en bättre trofé ur körningens om den finns (den sämst klädda hjälten först).
func _human_swap() -> void:
	for t in state.trophies:
		if state.wearer(t) != "":
			continue
		var worst := ""
		var worst_score := 99
		for h in state.party:
			var cur: String = state.equipped.get(h, "")
			var sc := 0 if cur == "" else _trophy_score(cur)
			if sc < worst_score:
				worst = h
				worst_score = sc
		if worst != "" and _trophy_score(t) > worst_score:
			state.equip(worst, t)
	profile.keep_worn(state.equipped, state.party)


func _human_print(profiles: Array, runs: int, descents: int, realm_id: String) -> void:
	print("")
	print("=== Mänskliga karriärbotar: %s, %d profiler, %d nedstigningar ===" % [realm_id, runs, descents])
	print("  djup  nådde  klarade  ned t.o.m. klar (median)  försök på djupet  träningsned  timmar t.o.m. klar (median)  fast")
	for depth in range(1, 16):
		var tried := profiles.filter(func(r: Dictionary) -> bool: return r.first_try.has(depth))
		if tried.is_empty():
			break
		var cleared := tried.filter(func(r: Dictionary) -> bool: return r.first_clear.has(depth))
		var ned := cleared.map(func(r: Dictionary) -> int: return int(r.first_clear[depth]) + 1)
		var att := cleared.map(func(r: Dictionary) -> int: return int(r.attempts.get(depth, 0)))
		var tr := cleared.map(func(r: Dictionary) -> int: return int(r.train.get(depth, 0)))
		var hrs := cleared.map(func(r: Dictionary) -> float: return float(r.sec_at_clear[depth]) / 3600.0)
		print("  %4d  %5d  %7d  %22s  %16s  %11s  %27s  %4d" % [depth, tried.size(), cleared.size(), _med(ned), _med(att),
				_med(tr), _med(hrs, true), tried.size() - cleared.size()])
	print("  Förluster per djup (var):")
	for depth in range(1, 41):
		var tally := {}
		for r in profiles:
			for k in r.lost.get(depth, {}):
				tally[k] = int(tally.get(k, 0)) + int(r.lost[depth][k])
		if tally.is_empty():
			continue
		var ks := tally.keys()
		ks.sort_custom(func(a: String, b: String) -> bool: return tally[a] > tally[b])
		print("    d%d: %s" % [depth, ", ".join(ks.map(func(k: String) -> String: return "%s %d" % [k, tally[k]]))])
	var best := {}
	for r in profiles:
		best[r.best] = int(best.get(r.best, 0)) + 1
	var keys := best.keys()
	keys.sort()
	print("  Högsta klarade djup: %s" % ", ".join(keys.map(func(k: int) -> String: return "d%d %d" % [k, best[k]])))
	var sec := 0.0
	var fights := 0
	var turns := 0
	for r in profiles:
		sec += float(r.sec)
		fights += int(r.fights)
		turns += int(r.turns)
	print("  Per profil: %.1f timmar, %.0f strider, %.0f turer, nivå %.1f" % [sec / 3600.0 / runs, float(fights) / runs,
			float(turns) / runs, profiles.reduce(func(a: float, r: Dictionary) -> float: return a + float(r.level), 0.0) / runs])


static func _med(list: Array, hours := false) -> String:
	if list.is_empty():
		return "-"
	var l := list.duplicate()
	l.sort()
	var m: Variant = l[l.size() / 2]
	var lo: Variant = l[l.size() / 4]
	var hi: Variant = l[l.size() * 3 / 4]
	if hours:
		return "%.1f (%.1f–%.1f)" % [m, lo, hi]
	return "%d (%d–%d)" % [m, lo, hi]
