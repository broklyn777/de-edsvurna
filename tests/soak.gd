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
## Varje fel skrivs med frö, drag och vad som hände; samma frö ger samma körning.

const Bot := preload("res://tests/combat_bot.gd")
const RunScript := preload("res://scripts/game/run.gd")
const MAX_ACTIONS := 2000
const MAX_BATTLE_STEPS := 1500
const TMP_RUN := "user://soak_run.cfg"
const TMP_PROFILE := "user://soak_progress.cfg"

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
	c.realm = "crypt" if c.first else ["crypt", "chapel"][pick.randi() % 2]
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
		state.join_waiting(data, profile)
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
	if profile.intro_done and pick.randf() < 0.002:
		_log("går hem")
		stats.left += 1
		ended = "left"
		RunState.delete_saved(TMP_RUN)
		return
	# Spara och läs in mitt i (som när appen stängs och öppnas igen).
	if pick.randf() < 0.12:
		_save_and_load()
	# Lägereld man står vid: troféerna kan bytas när som helst.
	var r := state.current_room()
	if r.get("kind", "") == "campfire" and pick.randf() < 0.1:
		_swap_trophies()
	var target := _choose_step(use_bot)
	if target < 0:
		_no_step()
		return
	var walk := state.step(target)
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
	if state.party.size() <= Profile.MAX_COMPANIONS:
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

func _fight() -> void:
	state.fight()
	if not state.battle_pending:
		_fail("strid", "fight() på en grupp gav ingen strid")
		ended = "error"
		return
	stats.battles += 1
	if state.current_room().get("boss", false):
		stats.bosses += 1
	if state.current_room().get("elite", false) and not profile.elites_met.has(state.encounter()):
		profile.elites_met.append(state.encounter())
	# Ibland stängs appen mitt i striden: körningen läses in och striden börjar om (Run._resume_run).
	if pick.randf() < 0.05:
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
		sim.drain_events()
	if sim.outcome == "":
		var who := ", ".join(sim.units.map(func(u: CombatUnit) -> String:
				return "%s %s/%s%s" % [u.id, str(snappedf(u.hp, 0.1)), str(snappedf(u.max_hp, 0.1)), "" if u.alive else " död"]))
		_fail("strid", "striden %s tog inte slut på %d drag (tur %d): %s; regler %s" % [state.encounter(), MAX_BATTLE_STEPS,
				sim.turn_no, who, str(opts.get("rules", []))])
		ended = "error"
		return
	var won := sim.outcome == "victory"
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
		profile.grant_xp(data, state.party, HeroStats.battle_xp(RunState.fight_kind(r), state.depth, r.get("boss", false)))


func _roll_finds(kind: String) -> void:
	var finds := Forge.roll_finds(data, kind, state.depth, state.depth > profile.best_depth, state.instability, rng,
			profile.next_stone_id)
	for f in finds:
		if f.kind == "nether":
			profile.next_stone_id += 1
		state.found[f.kind] = int(state.found.get(f.kind, 0)) + int(f.get("count", 1))
	profile.add_finds(finds)
	profile.start_find_quest(finds)


## Run.battle_finished och lägret efter en seger (camp_screen: välj en trofé, VIDARE).
func _battle_finished(victory: bool, forfeited: bool) -> void:
	if not victory:
		stats.forfeit += 1 if forfeited else 0
		stats.lost += 1
		RunState.delete_saved(TMP_RUN)
		ended = "forfeit" if forfeited else "lost"
		return
	profile.silver += roundi(state.battle_silver(state.depth) * state.silver_mult(data))
	if state.current_room().get("kind", "") == "end" and state.is_last_floor():
		for kind in data.encounters[state.encounter()].enemies:
			if data.enemies[kind].get("boss", false):
				profile.defeat_boss(kind)
	RunScript.mark_sneak(data, profile, state)
	var offer := state.trophy_offer(data, rng, state.last_elites, profile.unlocked_boss_trophies())
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
	if not offer.is_empty() and pick.randf() < 0.8:
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
			" FÖRSTA NEDSTIGNINGEN" if cfg.first else ""]


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
