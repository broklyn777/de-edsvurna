extends Node
## Turordningsstriden. Kopplar ihop stridslogiken (CombatSim) med 3D-kryptan, tidslinjen,
## sällskapets ramar och handlingsknapparna.
##
## Simulatorn räknar ut en tur i taget. battle.gd spelar upp turens händelser – rörelser,
## träffar, siffror, egenskaper som slår till – och väntar en kort stund innan nästa tur.
##
## Utvecklarargument (efter `--`):
##   --demo        hjältarna kör sina makron hela striden (Auto)
##   --turns=<n>   spola fram så många turer innan bilden visas
##   --seed=<n>    fast slumpfrö

## Hur länge en tur får verka efter sista effekten innan nästa tur börjar (sekunder).
const BEAT := 0.45
## Vapnet i handen (visual.weapons.grip_r/grip_l) -> ljudet när figuren slår.
const WEAPON_CUES := {"Greatsword": "atk_sword", "Longsword": "atk_sword", "Shortsword": "atk_sword",
		"Spear": "atk_sword", "Greataxe": "atk_axe", "Handaxe": "atk_axe", "Maul": "atk_blunt",
		"Mace": "atk_blunt", "Flail": "atk_blunt", "Staff": "atk_blunt"}
## Extra tid mellan effekter i en kedja, så att man hinner se dem i ordning.
const CHAIN_STEP := 0.22
const ERROR_TEXT := {"cooldown": "Inte redo än", "dead": "Hjälten har stupat", "none": "Ingen sådan förmåga",
		"charges": "Inga Charges kvar", "silenced": "Tystad – förmågor går inte",
		"sealed": "Förseglad (Förseglade ord)", "forbidden": "Inga bönder: ingen kan försvara eller provocera"}

## Autoload-noden Run (hämtas via sökväg så att skriptet kompilerar även utan autoloads).
var run: Node
var data: Dictionary
var sim: CombatSim
var sfx: Sfx
var world: CryptWorld
var fx_layer: Node2D
var models := {}
var frames := {}
var timeline: Timeline
var action_bar: ActionBar
var overlay: BattleOverlay
var auto_chip: ChipButton
var macro_log: MacroLog
var speed_chip: ChipButton
## Ge upp (0.20.1, Siralims Forfeit), med en bekräftelse.
var forfeit_chip: ChipButton
## Skadeloggen och uträkningen bakom siffrorna (0.21).
var log_chip: ChipButton
var settings_chip: ChipButton
var order_chip: ChipButton  # 0.30: "Spara som order" efter ett eget val som makrot inte hade gjort
var _order := {}  # {hero, line, until_ms}
var _orders_offered := {}  # hjälte:rad som redan har erbjudits i striden
var damage_log: DamageLog
## Siffror som just visats: [{pos, at_ms, e}] – ett tryck nära en visar dess uträkning.
var _recent_numbers: Array = []
var _calc_open := false
var _dev_calc := false
var _dev_statuses := false
var _dev_exhaust := 0
var _dev_order := false
var _dev_combo := false  # 0.30: --combo förblindar fienderna vid start och kör ALLA AUTO (kombinationens ruta)
## --combo-first: som --combo, men Paladinen agerar först, så att rutan "Kombination!" kommer i första turen. Rutan visas
## bara en gång per profil: använd en ny profil, t.ex. --intro-step=crypt --combo-first --floor=0 --frames=260.
var _dev_combo_first := false
var _dev_inspect := ""
var _dev_log := false
var _dev_ask_forfeit := false
## Effekter som väntar på att vapnet eller projektilen ska träffa: [{left, call}].
var _later: Array[Dictionary] = []

var started := false
var _countdown := 1.2
var _wait := 0.0
var _cursor := 0.0
var _speed := 1.0
## Handlingen ("attack", "ability" …) som väntar på mål, och vilken förmåga.
var _choosing := ""
var _choosing_ability := ""
## Auto: hjältar med standardhandling Makro kör sitt makro varje tur.
## 0.29.5: vilka hjältar som kör sitt makro (AUTO) i den här striden; alla börjar på MANUELL. Stora knappen växlar mellan
## MANUELL, AUTO (följeslagarna) och ALLA AUTO (även Paladinen); ett tryck på en hjältes ram byter just den hjälten.
var _auto_heroes := {}
## 0.29.5: makroredigeraren ovanpå striden (striden står still medan den är öppen).
var _macro_editor: Control = null
var macro_chip: ChipButton
const AUTO_LABELS := ["MANUELL", "AUTO", "ALLA AUTO"]
var _targets: Array[String] = []
## Inspect (Siralim): tryck och håll på en figur för att se dess egenskaper. Kostar ingen tur.
const INSPECT_HOLD_MS := 450
var _press_pos := Vector2.ZERO
var _press_ms := -1
var _press_unit := ""
var _inspecting := false
var _default_target := ""
var _hitstop_until := 0
var _slowmo_until := 0
var _center := {}


func _ready() -> void:
	run = get_node("/root/Run")
	Engine.time_scale = 1.0
	data = GameData.load_all()
	# 0.24.2: paladinens namn i ramen, tidslinjen och fiendernas avsikter.
	data.heroes.paladin.name = run.profile.hero_name
	data.heroes.paladin.short = run.profile.hero_name
	var seed_value := randi()
	var warp_turns := 0
	var demo := false
	for arg in OS.get_cmdline_user_args():
		if arg == "--demo":
			demo = true
		elif arg.begins_with("--turns="):
			warp_turns = int(arg.get_slice("=", 1))
		elif arg.begins_with("--seed="):
			seed_value = int(arg.get_slice("=", 1))
		elif arg.begins_with("--exhaust="):
			_dev_exhaust = int(arg.get_slice("=", 1))  # 0.30.20: striden börjar på den turen (skärmdumpar av utmattningen)
		elif arg == "--statuses":
			_dev_statuses = true  # sätter några statusar vid start (skärmdumpar av ikonerna)
		elif arg == "--settings":
			SettingsBox.open.call_deferred(self, true)  # 0.30: inställningarna öppna (skärmdumpar)
		elif arg == "--combo" or arg == "--offer-order" or arg == "--combo-first":
			_dev_combo = true
			_dev_combo_first = arg == "--combo-first"
			_dev_order = arg == "--offer-order"  # visar "Spara som order" för Rättfärdigt slag (skärmdumpar)
			for id in ["timeline", "statuses", "charges"]:
				if not run.profile.help_seen.has(id):
					run.profile.help_seen.append(id)
		elif arg == "--show-calc":
			_dev_calc = true  # visar uträkningen för en av hjältarnas träffar (skärmdumpar)
		elif arg == "--damage-log":
			_dev_log = true  # öppnar skadeloggen efter några turer (skärmdumpar)
		elif arg == "--ask-forfeit":
			_dev_ask_forfeit = true  # visar frågan om att ge upp när striden har börjat (skärmdumpar)
		elif arg.begins_with("--inspect="):
			_dev_inspect = arg.get_slice("=", 1)  # Inspect när striden har börjat (skärmdumpar)
	var state: RunState = run.state
	if state.charges.is_empty():
		state.fill_charges(data)
	var opts: Dictionary = state.battle_opts() if state.map != null and not state.practice \
			else state.practice_opts(data)
	opts.levels = run.profile.levels_for(data, state.party)  # 0.19: hjältarnas nivåer
	if not state.practice:
		state.apply_vow(data, opts)  # 0.30.17: Jag helar inte
	sim = CombatSim.create(data, state.encounter(), seed_value, state.party, state.hero_traits(data), state.charges,
			state.artifacts, state.depth, opts)
	data = sim.data  # med artefakternas egenskaper
	_build_scene()
	_build_ui()
	_update_rules_text()
	get_viewport().size_changed.connect(_layout)
	_start_music()
	_layout()
	# 0.25: hjälprutorna (tidslinjen i den första striden, Ge upp när kryptan börjar bli svår); inte i demo-läget.
	_help_ok = not demo and warp_turns == 0
	if _help_ok and not _dev_combo:
		var ids := ["timeline"]
		if not state.practice and run.profile.total_descents() >= 2:
			ids.append("forfeit")
		HelpBox.offer(self, ids, true)
	if warp_turns > 0:
		sim.begin()
		for i in warp_turns:
			if sim.outcome != "":
				break
			if sim.needs_input():
				var d := MacroRunner.decide(sim, sim.current, run.macro_for(sim.current.id))
				if d.ok:
					sim.act(d.action, d.target, d.ability)
				else:
					sim.act("defend")
			else:
				sim.ai_act()
		sim.drain_events()
		for u in sim.units:
			if not u.alive:
				models[u.id].die()
		if sim.outcome != "":
			_on_outcome.call_deferred(sim.outcome)  # spolat till slutet: visa resultatet direkt
		started = true
		_countdown = 0.0
	_set_auto_mode(2 if demo or _dev_combo else 0)
	if "--battle-macros" in OS.get_cmdline_user_args():
		_open_macro_editor.call_deferred()  # 0.29.5: redigeraren i striden (skärmdumpar)


## 0.25: hjälprutorna visas bara när en människa spelar (inte --demo eller --turns).
var _help_ok := false


func _help_charges() -> void:
	HelpBox.offer(self, ["charges"], true)


func _help_statuses() -> void:
	HelpBox.offer(self, ["statuses"], true)


func _build_scene() -> void:
	sfx = Sfx.new()
	add_child(sfx)
	world = CryptWorld.new()
	world.style = data.realms.get(run.state.realm, {}).get("style", "crypt")
	add_child(world)
	for u in sim.units:
		var vis: Dictionary = (data.heroes[u.id] if u.team == 0 else data.enemies[u.kind]).visual
		if u.elite:
			# Elitvarianten: egen färg, glöd och lite större, så att den syns direkt.
			var elite: Dictionary = data.enemies[u.kind].elite
			vis = vis.duplicate()
			vis.tint = elite.get("tint", "#ffd36a")
			vis.glow = elite.get("glow", "#a06a00")
			vis.scale = float(vis.get("scale", 1.0)) * 1.15
			# 0.31 (spindlarna): en figur som färgas per material får elitens egna färger och glöd.
			if elite.has("colors"):
				vis.colors = elite.colors
			if elite.has("emit"):
				vis.emit = elite.emit
		var m := UnitModel.new()
		world.add_child(m)
		m.setup(u, sim, vis)
		m.sfx = sfx
		models[u.id] = m
	for team in [0, 1]:
		var sum := Vector3.ZERO
		var n := 0
		for u in sim.units:
			if u.team == team:
				sum += models[u.id].position
				n += 1
		_center[team] = sum / maxf(n, 1)
	_update_facing()

	var fx_canvas := CanvasLayer.new()
	fx_canvas.layer = 0
	add_child(fx_canvas)
	fx_layer = Node2D.new()
	fx_canvas.add_child(fx_layer)
	var markers := Markers.new()
	markers.battle = self
	fx_layer.add_child(markers)
	fx_layer.add_child(Fx.Overheads.new(sim, world, models))


func _build_ui() -> void:
	var ui := CanvasLayer.new()
	ui.layer = 1
	add_child(ui)
	timeline = Timeline.new()
	timeline.setup(sim)
	ui.add_child(timeline)
	for h in sim.heroes:
		var f := PartyFrame.new()
		f.setup(h, sim)
		f.tapped.connect(_on_frame_tapped)
		ui.add_child(f)
		frames[h.id] = f
	action_bar = ActionBar.new()
	action_bar.setup(sim)
	action_bar.visible = false
	action_bar.chosen.connect(_on_action_chosen)
	ui.add_child(action_bar)
	auto_chip = ChipButton.new()
	auto_chip.setup("MANUELL", 124)
	auto_chip.pressed.connect(_toggle_auto)
	ui.add_child(auto_chip)
	macro_log = MacroLog.new()
	macro_log.setup()
	ui.add_child(macro_log)
	speed_chip = ChipButton.new()
	speed_chip.setup("1×", 64)
	speed_chip.pressed.connect(_toggle_speed)
	ui.add_child(speed_chip)
	forfeit_chip = ChipButton.new()
	forfeit_chip.setup("GE UPP", 104)
	forfeit_chip.pressed.connect(_ask_forfeit)
	ui.add_child(forfeit_chip)
	log_chip = ChipButton.new()
	log_chip.setup("SKADELOGG", 140)
	log_chip.pressed.connect(_open_damage_log)
	ui.add_child(log_chip)
	order_chip = ChipButton.new()
	order_chip.setup("", 560)
	order_chip.visible = false
	order_chip.pressed.connect(_save_order)
	ui.add_child(order_chip)
	macro_chip = ChipButton.new()
	macro_chip.setup("MAKRON", 140)
	macro_chip.pressed.connect(_open_macro_editor)
	ui.add_child(macro_chip)
	settings_chip = ChipButton.new()
	settings_chip.setup("LJUD", 140)
	settings_chip.pressed.connect(func() -> void: SettingsBox.open(self, true))  # 0.30: pausar striden
	ui.add_child(settings_chip)
	overlay = BattleOverlay.new()
	overlay.restart_requested.connect(_continue)
	overlay.forfeit_answered.connect(_on_forfeit_answer)
	ui.add_child(overlay)
	damage_log = DamageLog.new()
	damage_log.data = data
	damage_log.hero_ids = sim.heroes.map(func(h: CombatUnit) -> String: return h.id)
	ui.add_child(damage_log)
	overlay.mode = "countdown"


func _layout() -> void:
	var vs := get_viewport().get_visible_rect().size
	timeline.position = Vector2((vs.x - timeline.size.x) / 2.0 + 40, 4)
	var y := 12.0
	for h in sim.heroes:
		frames[h.id].position = Vector2(12, y)
		y += frames[h.id].size.y + 8
	action_bar.position = Vector2(vs.x - action_bar.size.x - 18, vs.y - action_bar.size.y - 8)
	auto_chip.position = Vector2(vs.x - auto_chip.size.x - 12, 12)
	macro_log.position = Vector2(12, vs.y - macro_log.size.y - 12)
	speed_chip.position = Vector2(auto_chip.position.x - speed_chip.size.x - 8, 12)
	forfeit_chip.position = Vector2(speed_chip.position.x - forfeit_chip.size.x - 8, 12)
	log_chip.position = Vector2(vs.x - log_chip.size.x - 12, 64)
	macro_chip.position = Vector2(vs.x - macro_chip.size.x - 12, 116)
	settings_chip.position = Vector2(vs.x - settings_chip.size.x - 12, 168)
	order_chip.position = macro_log.position + Vector2(0, -order_chip.size.y - 8)
	overlay.size = vs


# --- Bildruta ---------------------------------------------------------------

func _process(delta: float) -> void:
	if damage_log.open or _macro_editor != null:
		Engine.time_scale = 0.0  # striden står still medan loggen eller makroredigeraren är öppen
		return
	if overlay.mode == "confirm":
		Engine.time_scale = 0.0  # striden står still medan frågan visas
		return
	var now_ms := Time.get_ticks_msec()
	if order_chip.visible and (now_ms > int(_order.get("until_ms", 0)) or sim.outcome != ""):
		order_chip.visible = false
		_order = {}
	if _press_ms >= 0 and not _inspecting and _press_unit != "" and now_ms - _press_ms >= INSPECT_HOLD_MS:
		_inspecting = true
		_show_inspect(_press_unit)
	if now_ms < _hitstop_until:
		Engine.time_scale = 0.05 * _speed
	elif now_ms < _slowmo_until:
		Engine.time_scale = 0.3
	else:
		Engine.time_scale = _speed

	if not started:
		_countdown -= delta / maxf(Engine.time_scale, 0.01)
		if _countdown <= 0.0:
			started = true
			overlay.show_big("STRID!")
			sfx.play("go", -2.0, 0.0)
			var pal_unit := sim.unit("paladin")
			var pal_speed := pal_unit.speed if pal_unit != null else 0.0
			if _dev_combo_first and pal_unit != null:
				pal_unit.speed = 9999.0  # överst på tidslinjen; snabbheten återställs när ordningen är lagd
			sim.begin()
			# Speltiden: striden räknas från första turen (inte i Övningsgården).
			if not run.state.practice and run.state.map != null:
				run.playtime.start_battle(Playtime.battle_kind(run.state.current_room(), run.state.is_last_floor()))
			if _dev_combo_first and pal_unit != null:
				pal_unit.speed = pal_speed
			if _dev_exhaust > 0:
				sim.turn_no = _dev_exhaust
			if _dev_statuses:
				_give_dev_statuses()
			if _dev_combo:
				var by: CombatUnit = sim.unit("imma") if sim.unit("imma") != null else sim.heroes[0]
				for en in sim.enemies:
					sim._add_aura(by, en, "blind")
				if _dev_order:
					_set_auto_mode(0)
					_offer_order(sim.unit("paladin"), "ability", sim.enemies[0].id, "holy_smite")
				# Paladinens makro slår Rättfärdigt slag, så att kombinationen syns (bara skärmdumpar, sparas inte).
				var pal: Dictionary = {} if _dev_order else run.macro_for("paladin")
				pal.lines = [{"subject": "any_enemy", "cond": "lowest_hp", "action": "ability", "ability": "holy_smite",
						"target": "that"}]
			if _dev_inspect != "":
				_show_inspect.call_deferred(_dev_inspect)
			_play_events()
		return

	if _dev_ask_forfeit and sim.turn_no >= 2:
		_dev_ask_forfeit = false
		_ask_forfeit()
	_tick_later(delta)
	_update_facing()
	_update_frames()
	if sim.outcome != "":
		return
	if _wait > 0.0:
		_wait -= delta
		return
	if sim.needs_input():
		if _auto_heroes.get(sim.current.id, false) and not action_bar.visible:
			_run_macro()
			return
		if not action_bar.visible or action_bar.unit != sim.current:
			action_bar.show_for(sim.current)
			_choosing = ""
			_targets.clear()
		return
	action_bar.visible = false
	sim.ai_act()
	_play_events()


func _update_facing() -> void:
	for u in sim.units:
		if u.alive:
			models[u.id].face(_center[1 - u.team])


func _update_frames() -> void:
	for h in sim.heroes:
		frames[h.id].active = sim.current == h and started
		frames[h.id].targetable = _choosing != "" and _targets.has(h.id)


# --- Inmatning --------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1, KEY_2, KEY_3, KEY_4, KEY_5:
				if action_bar.visible:
					_on_action_chosen(ActionBar.MAIN[event.keycode - KEY_1], "")
			KEY_ENTER, KEY_KP_ENTER:
				if _choosing != "":
					_do(_choosing, _default_target)
			KEY_A:
				_toggle_auto()
			KEY_R:
				_restart()
	elif event is InputEventMouseMotion and _press_ms >= 0 and event.position.distance_to(_press_pos) > 30.0:
		_press_unit = ""  # fingret flyttades: ingen Inspect
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press_pos = event.position
			_press_ms = Time.get_ticks_msec()
			_press_unit = _unit_at(event.position, sim.units.filter(func(u: CombatUnit) -> bool: return u.alive)
					.map(func(u: CombatUnit) -> String: return u.id))
			return
		_press_ms = -1
		if _calc_open:
			_calc_open = false
			overlay.hide_calc()
			return
		if _choosing == "" and _show_calc_near(event.position):
			return
		if _inspecting:
			_inspecting = false
			overlay.hide_inspect()
			return
		if _choosing == "":
			return
		var best := _unit_at(event.position, _targets)
		if best != "":
			_do(_choosing, best)


## Ett tryck nära en siffra som just visats öppnar dess uträkning (0.21).
func _show_calc_near(pos: Vector2) -> bool:
	var now := Time.get_ticks_msec()
	var best: Dictionary = {}
	var best_d := 70.0
	for n in _recent_numbers:
		if now - int(n.at_ms) > 3500:
			continue
		var d: float = pos.distance_to(n.pos)
		if d < best_d:
			best_d = d
			best = n
	if best.is_empty():
		return false
	overlay.show_calc(DamageExplain.title(data, best.e), DamageExplain.lines(data, best.e))
	_calc_open = true
	return true


func _remember_number(e: Dictionary) -> void:
	if not e.has("calc"):
		return
	var p := world.project(models[e.target].head_position()) + Vector2(0, -56)
	_recent_numbers.append({"pos": p, "at_ms": Time.get_ticks_msec(), "e": e})
	if _recent_numbers.size() > 16:
		_recent_numbers.pop_front()
	damage_log.add(e)
	if _dev_calc and e.type == "damage" and sim.unit(e.source).team == 0 and e.calc.get("scaled", false) \
			and e.calc.get("kind", "") == "attack" and sim.turn_no >= 4:
		_dev_calc = false
		overlay.show_calc(DamageExplain.title(data, e), DamageExplain.lines(data, e))
		_calc_open = true
	if _dev_log and damage_log.entries.size() >= 10:
		_dev_log = false
		damage_log.show_log()
		damage_log._open_rows[damage_log.entries.size() - 1] = true
		damage_log._open_rows[damage_log.entries.size() - 3] = true


func _give_dev_statuses() -> void:
	var p := sim.heroes[0]
	for id in ["protected", "mending", "leeching"]:
		sim._add_aura(p, p, id)
	sim._add_aura(p, sim.heroes[1], "berserk")
	sim._add_aura(p, sim.heroes[1], "shelled")
	sim._add_aura(sim.enemies[0], sim.heroes[2], "poisoned")
	sim._add_aura(sim.enemies[0], sim.heroes[2], "blind")
	sim._add_aura(p, sim.enemies[0], "bleeding")
	sim._add_aura(p, sim.enemies[0], "vulnerable")
	sim._add_aura(p, sim.enemies[1 % sim.enemies.size()], "snared")
	sim._add_aura(p, sim.enemies[2 % sim.enemies.size()], "frozen")


## 0.29.5: ändra makrona mitt i striden. Den som har turen (eller Paladinen) väljs först; ändringarna gäller direkt.
func _open_macro_editor() -> void:
	if _macro_editor != null or overlay.mode in ["confirm", "victory", "defeat"] or damage_log.open:
		return
	var ed: Control = load(run.MACRO_SCENE).instantiate()
	ed.embedded = true
	ed.focus_hero = sim.current.id if sim.current != null and sim.current.team == 0 else "paladin"
	ed.closed.connect(_macro_editor_closed)
	_macro_editor = ed
	macro_chip.get_parent().add_child(ed)
	run.ui("ui_page", -10.0)


func _macro_editor_closed() -> void:
	_macro_editor = null
	Engine.time_scale = _speed
	# Väntade hjälten på AUTO för att inget passade: pröva det nya makrot direkt.
	if sim.current != null and _auto_heroes.get(sim.current.id, false) and _choosing == "":
		action_bar.visible = false


func _open_damage_log() -> void:
	if overlay.mode == "confirm" or damage_log.open:
		return
	run.ui("ui_page", -10.0)
	damage_log.show_log()


## Figuren närmast punkten bland ids (inom 80 px), eller "".
func _unit_at(pos: Vector2, ids: Array) -> String:
	var best := ""
	var best_d := 80.0
	for id in ids:
		var m: UnitModel = models[id]
		# Träffytan går från fötterna till huvudet, så att hela figuren går att trycka på.
		var feet := world.project(m.global_position)
		var head := world.project(m.head_position())
		var d := _dist_to_segment(pos, feet, head)
		if d < best_d:
			best_d = d
			best = id
	return best


## En våningsregel slog till. Dolda regler avslöjas med en skylt.
func _on_rule(rule_id: String) -> void:
	var state: RunState = run.state
	if state.rules_hidden.has(rule_id) and not state.rules_revealed.has(rule_id):
		state.rules_revealed.append(rule_id)
		overlay.announce("Dold regel: %s!" % data.floor_rules[rule_id].name)
		sfx.play("bone_crush", -6.0, 0.0)
	_update_rules_text()


## 0.30.20: striden har dragit ut för länge; alla tappar liv i början av sin tur tills den avgörs.
func _on_exhaustion_start() -> void:
	overlay.announce("Facklorna falnar – ingen orkar länge till")
	sfx.play("room_lock", -6.0, 0.0)


## En elitvariant är med i striden: skylt och ljudsignal.
func _on_elite(unit_id: String) -> void:
	overlay.announce("Elitfiende: %s!" % sim.unit(unit_id).name)
	sfx.play("elite_appears", -3.0, 0.0)


## Musik och stämning efter Realm; bossmöten får bossmusik och en signal när bossen syns.
func _start_music() -> void:
	var chapel: bool = run.state.realm == "chapel"
	sfx.start_ambience("ambience_chapel" if chapel else "ambience_crypt", -12.0 if chapel else -11.0)
	var boss := sim.enemies.any(func(e: CombatUnit) -> bool: return data.enemies[e.kind].get("boss", false))
	if boss:
		run.audio.play_music("music_boss", -16.0, 1.0)
		get_tree().create_timer(0.6).timeout.connect(sfx.play.bind("boss_appears", -2.0, 0.0))
	else:
		run.audio.play_music("music_chapel" if chapel else "music_crypt", -15.0)


## Raden med våningsreglerna (synliga och avslöjade dolda) uppe till höger.
func _update_rules_text() -> void:
	var state: RunState = run.state
	var names: Array = state.known_rules().map(func(id: String) -> String: return data.floor_rules[id].name)
	var unknown := state.rules_hidden.size() - (state.known_rules().size() - state.rules_visible.size())
	for i in unknown:
		names.append("?")
	overlay.rules_text = ("Regler: " + " · ".join(names)) if not names.is_empty() else ""
	if state.vow != "" and not state.practice:
		var vow_txt := "Löfte: " + state.vow_name(data)
		overlay.rules_text = vow_txt if overlay.rules_text == "" else overlay.rules_text + " · " + vow_txt


## Vilken trofé fienden kan lämna (Inspect): elitens egen, bossens med räknaren, eller den vanliga.
func _trophy_line(u: CombatUnit) -> String:
	var d: Dictionary = data.enemies[u.kind]
	var trophy_id: String = d.get("elite", {}).get("trophy", "") if u.elite else d.get("trophy", "")
	if trophy_id == "":
		return "Lämnar ingen trofé."
	var name: String = data.traits[trophy_id].name
	var owned: bool = run.collection.has(trophy_id)
	if d.get("boss", false):
		var wins := int(run.profile.boss_wins.get(u.kind, 0))
		return "Trofé: %s – kräver %d segrar (%d/%d)%s" % [name, RunState.BOSS_WINS_FOR_TROPHY, mini(wins, 3),
				RunState.BOSS_WINS_FOR_TROPHY, " · i samlingen" if owned else ""]
	return "Trofé: %s%s" % [name, " · i samlingen" if owned else " · ny!"]


## Visar figurens stats och egenskaper (dolda delar och artefaktens egenskap räknas inte).
func _show_inspect(unit_id: String) -> void:
	var u := sim.unit(unit_id)
	var lines: Array[String] = ["Liv %d/%d · Attack %s · Intelligence %s · Defense %s · Speed %s" % [
			maxi(roundi(u.hp), 1 if u.alive else 0), roundi(u.max_hp), HeroStats.shown(u.attack), HeroStats.shown(u.intelligence), HeroStats.shown(u.defense_now()),
			HeroStats.shown(u.speed)]]
	if u.team == 0 and u.personality != "":
		var p: Dictionary = data.personalities[u.personality]
		lines.append("Nivå %d · %s (%s 40 %%, %s 20 %%)" % [int(u.level), p.name, HeroStats.STAT_NAMES[p.up],
				HeroStats.STAT_NAMES[p.down]])
	for trait_id in u.traits:
		var t: Dictionary = data.traits[trait_id]
		if not t.get("hidden", false):
			lines.append("%s: %s" % [t.name, t.text])
	if lines.size() == 1:
		lines.append("Inga egenskaper.")
	lines.append_array(StatusIcons.lines(data, u))  # 0.22: statusarna med text och turer kvar
	if u.team == 1:
		lines.append(_trophy_line(u))
		lines.append("Djup %d · stats ×%.2f" % [sim.depth, CombatSim.enemy_mult(data.encounters[run.state.encounter()], sim.depth)])
	overlay.show_inspect(u.name, lines)


func _on_action_chosen(action: String, ability_id: String) -> void:
	if not sim.needs_input():
		return
	if action == "macro":
		_run_macro()
		return
	var u := sim.current
	var reason := sim.can_act(u, action, ability_id)
	if reason != "":
		action_bar.refuse(ability_id if action == "ability" else action)
		sfx.play("k_error", -6.0, 0.0)
		overlay.message(ERROR_TEXT.get(reason, reason))
		return
	sfx.play("k_click", -10.0, 0.05)
	var key := ability_id if action == "ability" else action
	var targets := sim.valid_targets(u, action, ability_id)
	if targets.is_empty():
		_choosing_ability = ability_id
		_do(action, "")
		return
	if action_bar.selected == key:  # andra trycket på samma knapp: förvalt mål
		_do(action, _default_target)
		return
	_choosing = action
	_choosing_ability = ability_id
	action_bar.selected = key
	_targets = targets
	_default_target = sim.default_target(u, action, ability_id)


func _on_frame_tapped(unit_id: String) -> void:
	if _choosing != "" and _targets.has(unit_id):
		_do(_choosing, unit_id)
		return
	# 0.29.5: ett tryck på ramen växlar hjälten mellan AUTO och MANUELL för resten av striden.
	if sim.outcome == "" and sim.unit(unit_id).alive:
		_auto_heroes[unit_id] = not _auto_heroes.get(unit_id, false)
		run.ui("ui_tap", -10.0)
		_auto_changed()


func _do(action: String, target_id: String) -> void:
	action_bar.visible = false
	var ability_id := _choosing_ability
	_choosing = ""
	_choosing_ability = ""
	_targets.clear()
	_offer_order(sim.current, action, target_id, ability_id)
	if sim.act(action, target_id, ability_id) == "":
		_play_events()


## 0.30 "Spara som order" (förslaget ur makroresearchen, docs/ideer/chat-makron-research.md): när spelaren själv väljer
## något som makrot inte hade valt erbjuds en makrorad som gör samma sak nästa gång. Prototyp för två fall: en helning på
## en skadad allierad ("hela den som har under N % liv") och en förmåga mot en status den slår hårdare mot
## (Rättfärdigt slag mot en Förblindad fiende). Raden läggs överst i hjältens makro.
func _offer_order(u: CombatUnit, action: String, target_id: String, ability_id: String) -> void:
	if action != "ability" or u == null or u.team != 0:
		return
	var ab: Dictionary = data.abilities.get(ability_id, {})
	var tgt := sim.unit(target_id)
	if tgt == null:
		return
	var line := {}
	var heals: bool = ab.get("effects", []).any(func(x: Dictionary) -> bool: return x.get("type", "") == "heal")
	if heals and tgt.team == 0 and tgt.hp_pct() < 0.8:
		var v := clampi(int(ceil((tgt.hp_pct() * 100.0 + 1.0) / 10.0)) * 10, 30, 80)
		line = {"subject": "any_ally", "cond": "hp_below", "value": v, "action": "ability", "ability": ability_id,
				"target": "that"}
	elif ab.has("bonus_vs") and tgt.team != 0 and tgt.auras.has(ab.bonus_vs.aura):
		line = {"subject": "any_enemy", "cond": "has_status", "value": ab.bonus_vs.aura, "action": "ability",
				"ability": ability_id, "target": "that"}
	if line.is_empty():
		return
	var key := "%s:%s:%s" % [u.id, ability_id, line.cond]
	if _orders_offered.has(key):
		return
	var macro: Dictionary = run.macro_for(u.id)
	for l in macro.get("lines", []):
		if l.get("ability", "") == ability_id and l.get("cond", "") == line.cond:
			return  # makrot har redan en sådan rad
	var d := MacroRunner.decide(sim, u, macro)
	if d.ok and d.action == action and d.ability == ability_id and d.target == target_id:
		return  # makrot hade gjort samma sak
	_orders_offered[key] = true
	_order = {"hero": u.id, "line": line, "until_ms": Time.get_ticks_msec() + 9000}
	var what: String = ab.name + (" när någon har under %d %% liv" % line.value if line.cond == "hp_below"
			else " mot %s fiende" % sim.status_name(tgt, line.value))
	order_chip.label = "SPARA SOM ORDER: " + what
	order_chip.size.x = minf(740.0, 40 + 9.5 * order_chip.label.length())
	order_chip.on = true  # guld, som ALLA AUTO: något att trycka på
	order_chip.visible = true
	_layout()


## Lägger raden överst i hjältens makro (ett nytt makro om hen inte har något) och sparar.
func _save_order() -> void:
	if _order.is_empty():
		return
	var id: String = run.assignment.get(_order.hero, "")
	if id == "" or not run.macros.has(id):
		id = run.new_macro_id()
		run.macros[id] = {"name": sim.unit(_order.hero).name, "lines": []}
		run.assignment[_order.hero] = id
	run.macros[id].lines.insert(0, _order.line)
	run.save_macros()
	run.ui("ui_confirm", -8.0)
	macro_log.add({"text": "Sparad överst i %ss makro: %s" % [sim.unit(_order.hero).name,
			MacroRunner.describe_line(sim, _order.line)], "ok": true, "skipped": []})
	_order = {}
	order_chip.visible = false


## Kör makrot för hjälten som har turen och skriver beslutet i loggen. Passar inget stannar Auto
## och spelaren väljer själv.
func _run_macro() -> void:
	var u := sim.current
	var d := MacroRunner.decide(sim, u, run.macro_for(u.id))
	macro_log.add({"text": d.text, "ok": d.ok, "skipped": d.skipped})
	if not d.ok:
		sfx.play("macro_nomatch", -4.0, 0.0)
		overlay.message("Inget makro passade – välj själv")
		action_bar.show_for(u)
		return
	action_bar.visible = false
	_choosing = ""
	_targets.clear()
	if sim.act(d.action, d.target, d.ability) == "":
		_play_events()


## Stora knappen: MANUELL → AUTO → ALLA AUTO → MANUELL (efter läget som syns nu).
func _toggle_auto() -> void:
	_set_auto_mode((_auto_mode() + 1) % AUTO_LABELS.size())
	run.ui("ui_tap", -10.0)


## 0: ingen kör makro, 2: alla, 1: annars (följeslagarna eller en blandning).
func _auto_mode() -> int:
	var on := sim.heroes.filter(func(h: CombatUnit) -> bool: return _auto_heroes.get(h.id, false)).size()
	return 0 if on == 0 else (2 if on == sim.heroes.size() else 1)


func _set_auto_mode(mode: int) -> void:
	for h in sim.heroes:
		_auto_heroes[h.id] = mode == 2 or (mode == 1 and h.id != "paladin")
	_auto_changed()


func _auto_changed() -> void:
	var mode := _auto_mode()
	auto_chip.label = AUTO_LABELS[mode]
	auto_chip.on = mode > 0
	for h in sim.heroes:
		frames[h.id].auto = _auto_heroes.get(h.id, false)
	# Den som har turen och nu kör auto: makrot tar över direkt.
	if sim.current != null and _auto_heroes.get(sim.current.id, false) and _choosing == "":
		action_bar.visible = false


func _ask_forfeit() -> void:
	if not started or sim.outcome != "" or overlay.mode in ["victory", "defeat", "confirm"]:
		return
	run.ui("ui_tap", -10.0)
	overlay.ask_forfeit(run.state.practice)


func _on_forfeit_answer(yes: bool) -> void:
	Engine.time_scale = _speed
	if not yes:
		return
	forfeit_chip.visible = false
	sim.forfeit()
	_play_events()


func _toggle_speed() -> void:
	_speed = 2.0 if _speed == 1.0 else 1.0
	speed_chip.label = "%d×" % int(_speed)
	speed_chip.on = _speed > 1.0


func _restart() -> void:
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()


## Efter resultatet: vidare till lägret (seger), hem till basen (förlust) eller tillbaka till
## Övningsgården med makrologgen.
func _continue() -> void:
	Engine.time_scale = 1.0
	var state: RunState = run.state
	for id in sim.rules_triggered:
		if not state.rules_revealed.has(id):
			state.rules_revealed.append(id)
	state.last_elites = sim.enemies.filter(func(e: CombatUnit) -> bool: return e.elite).map(
			func(e: CombatUnit) -> String: return e.kind)
	if sim.outcome == "victory" and not run.state.practice:
		run.state.store_charges(sim)
	run.battle_finished(sim.outcome == "victory", receipt(), macro_log.entries)


## Högst tre rader om vad som avgjorde striden (lägret, Övningsgården), samma urval som segerskärmen.
func receipt() -> Array[String]:
	var out: Array[String] = []
	for d in BattleSummary.deciders(sim, 3):
		out.append("%s (%s): %s" % [d.name, d.who, d.text])
	return out


func _exit_tree() -> void:
	UnitModel.free_shared()


# --- Händelser → känsla -----------------------------------------------------

## Spelar upp allt simulatorn har gjort sedan sist och bestämmer hur länge turen får verka.
func _play_events() -> void:
	_cursor = 0.0
	for e in sim.drain_events():
		_handle(e)
	_wait = maxf(_wait, _cursor + BEAT)


func _handle(e: Dictionary) -> void:
	match e.type:
		"turn_start":
			if sim.unit(e.unit).team == 0:
				sfx.play("k_ready", -14.0, 0.0)
		"action":
			_on_action(e)
			# 0.26.2: Charges-rutan första gången en hjälte använder en förmåga.
			if _help_ok and e.get("action", "") == "ability" and sim.unit(e.unit).team == 0:
				_after(_cursor + 0.6, _help_charges)
		"damage":
			_after(_effect_delay(e), _on_damage.bind(e))
		"timeline_move":
			_after(_cursor + 0.1, _float.bind(e.unit, "↑ ÖVERST" if e.dir == "top" else "↓ SIST",
					Color("#bcd2ff"), 20, false))
		"timeline_blocked":
			_after(_cursor + 0.1, _float.bind(e.unit, "SNÄRJD", StatusIcons.DEBUFF, 20, false))
		"dodge":
			_after(_effect_delay(e), _float.bind(e.target, "UNDVEK", Color("#d8e6ff"), 22, false))
			_after(_effect_delay(e), _remember_number.bind(e))
		"immune":
			_after(_effect_delay(e), _float.bind(e.target, "IMMUN", Color("#ffe48a"), 22, false))
		"status_immune":
			if e.get("unbound", false):
				_after(_effect_delay(e), _float.bind(e.unit, "FRI", Color("#bfe8ff"), 20, false))  # 0.30.25
		# 0.28: livvakten tar en del av skadan; Ordensregeln stoppar en helning.
		"guarded":
			_after(_effect_delay(e), _float.bind(e.unit, "VAKT %d" % int(e.amount), Color("#ffc86a"), 20, false))
		"heal_blocked":
			_after(_effect_delay(e), _float.bind(e.unit, "INGEN HELNING", StatusIcons.DEBUFF, 18, false))
		"charge_restored":
			_after(_effect_delay(e), _float.bind(e.unit, "+%d CHARGE" % e.amount, UiStyle.GOLD, 18, false))
		"heal":
			_after(_effect_delay(e), _on_heal.bind(e))
		"aura_applied":
			_after(_effect_delay(e), _on_aura.bind(e))
			if _help_ok and e.get("aura_kind", "") in ["buff", "debuff"]:
				_after(_effect_delay(e) + 0.4, _help_statuses)
		"aura_removed":
			if e.aura == "defend":
				models[e.unit].set_blocking(false)
		"trait":
			_after(_effect_delay(e), _on_trait.bind(e))
		"rule":
			_after(_effect_delay(e), _on_rule.bind(e.rule))
		"exhaustion_start":
			_after(_cursor + 0.1, _on_exhaustion_start)
		"exhaustion":
			_after(_cursor + 0.2, _float.bind(e.unit, "−%d" % int(e.amount), Color("#c9a77a"), 18, false))
		"chaos_calm":
			_after(_cursor + 0.1, _float.bind(e.unit, "KAOSVINDEN LÄGGER SIG", UiStyle.TRAIT_GOLD, 18, true))
		"elite":
			_after(_cursor + 0.6, _on_elite.bind(e.unit))
		"release":
			_after(_effect_delay(e), _on_release.bind(e))
		"death":
			_after(_cursor + 0.05, _on_death.bind(e.unit))
		"revive":
			_after(_cursor + 0.1, _on_revive.bind(e.unit))
		"outcome":
			_after(_cursor + 0.6, _on_outcome.bind(e.result))


## Direkta effekter landar när vapnet träffar; varje steg i en egenskapskedja kommer lite senare.
func _effect_delay(e: Dictionary) -> float:
	if e.has("trait"):
		_cursor += CHAIN_STEP
	return _cursor


func _on_action(e: Dictionary) -> void:
	var ab := sim.ability(e.ability)
	var m: UnitModel = models[e.unit]
	var target_id: String = e.targets[0] if not e.targets.is_empty() else e.unit
	var target_pos: Vector3 = models[target_id].global_position
	if target_id != e.unit:
		m.face(target_pos)
	var school: String = ab.get("school", "physical")
	var cue := _cue(e.unit, e.ability, ab)
	if ab.get("melee", false):
		m.attack(target_pos, 0.9, ab.get("anim", ""))
		_cursor = m.last_impact_delay
		# vapenljudets träff ligger ~0,18 s in i filen: starta det så att träffen landar med slaget
		_after(maxf(_cursor - 0.18, 0.0), sfx.play.bind(cue, -7.0, 0.06))
		cue = ""
	elif ab.get("travel", 0.0) > 0.0:
		m.attack(target_pos, 0.15, ab.get("anim", ""))
		var release := maxf(m.last_impact_delay, 0.15)
		if cue == "bow_shot":  # strängen släpps när pilen far iväg
			_after(maxf(release - 0.05, 0.0), sfx.play.bind(cue, -6.0, 0.05))
			cue = ""
		var travel: float = ab.travel
		var color := UiStyle.school_color(school)
		for id in e.targets:
			_after(release, func() -> void:
				fx_layer.add_child(Fx.Projectile.new(_pos(e.unit), _pos(id), travel, color, 8.0)))
		_cursor = release + travel
	elif e.ability == "defend":
		m.set_blocking(true)
		_cursor = 0.15
	else:
		m.attack(target_pos, 0.1, ab.get("anim", ""))
		_cursor = maxf(m.last_impact_delay, 0.25)
	if cue != "":
		sfx.play(cue, -6.0, 0.05)
	if e.action in ["ability", "artifact"] or (e.action == "intent" and e.ability != sim.unit(e.unit).attack_ability):
		_float(e.unit, ab.name.to_upper(), UiStyle.GOLD if sim.unit(e.unit).team == 0 else Color("#ffb347"), 20, false)


## Ljudet när handlingen börjar: förmågans "cue", annars vapnet (närstrid och båge) eller skolans
## besvärjelse mot fiender. Träffen har sitt eget ljud ("sound").
func _cue(unit_id: String, ability_id: String, ab: Dictionary) -> String:
	if ab.has("cue"):
		return ab.cue
	var u := sim.unit(unit_id)
	var vis: Dictionary = (data.heroes[u.id] if u.team == 0 else data.enemies[u.kind]).get("visual", {})
	var hands: Dictionary = vis.get("weapons", {})
	var weapon: String = hands.get("grip_r", hands.get("grip_l", ""))
	var school: String = ab.get("school", "physical")
	if ab.get("melee", false):
		if school != "physical" and weapon == "":
			return "spell_" + school
		return WEAPON_CUES.get(weapon, "atk_sword")
	if ability_id == "skip":
		return ""
	if school == "physical":
		return "bow_shot" if hands.get("grip_l", "") in ["Longbow", "Shortbow"] else ""
	if str(ab.get("target", "")).contains("enem"):
		return "spell_" + school
	return ""


func _on_damage(e: Dictionary) -> void:
	var target: UnitModel = models[e.target]
	var p := _pos(e.target)
	var crit: bool = e.crit
	var from_trait: bool = e.has("trait")
	var is_dot: bool = data.auras.has(e.ability)
	var heavy: bool = e.amount >= sim.unit(e.target).max_hp * 0.2
	if not is_dot:
		target.hit(1.8 if heavy else (1.4 if crit else 1.0), models[e.source].global_position)
	var color := UiStyle.school_color(e.school)
	var on_hero: bool = sim.unit(e.target).team == 0
	if on_hero and e.school == "physical":
		color = Color("#ff5a4a")
	var size := 17 if is_dot else (22 if from_trait else (34 if crit else 26))
	var absorbed: float = e.get("absorbed", 0.0)
	if absorbed > 0.0:
		_float(e.target, "(%d)" % int(absorbed), Color("#bfe3ff"), 18, false)
	if e.amount > 0.0 or absorbed <= 0.0:
		_float(e.target, str(int(e.amount)) + ("!" if crit else ""), color, size, crit or heavy)
	_remember_number(e)
	if e.get("calc", {}).has("combo"):
		_on_combo(e)
	if on_hero:
		frames[e.target].on_damage(e.amount)
	if is_dot:
		return
	var ab: Dictionary = data.abilities.get(e.ability, {})
	sfx.play(ab.get("sound", "k_hero_hit"), -2.0 if crit else -6.0, 0.08)
	fx_layer.add_child(_at(Fx.Ring.new(color, 6, 50 if crit else 34, 0.3, 5.0), p))
	if ab.get("melee", false) or from_trait:
		fx_layer.add_child(_at(Fx.Sparks.new(color, 10 if crit else 6, 240.0, 0.35), p))
	if crit or heavy:
		_hitstop(60 if crit else 45)
		world.add_shake(5.0 if crit else 3.0)


## 0.30: en förmåga slog hårdare tack vare en status som en annan satte (introts kombination: Rökpil gör fienden
## Förblindad, Rättfärdigt slag +50 %). Ett guldord ovanför målet, och första gången en ruta med orsak och verkan.
## 0.30.16: för varje TROFÉ-rad på segerskärmen, troféerna man äger i körningen som kunde ta dess plats.
func _decider_alternatives(rows: Array) -> Dictionary:
	var out := {}
	var names := {}
	for h in sim.heroes:
		names[h.id] = h.name
	for i in rows.size():
		if rows[i].tag != "TROFÉ" or not rows[i].has("id"):
			continue
		# I en körning byts troféer bland körningens (vid en lägereld); i Övningsgården väljer man ur hela samlingen.
		var owned: Array = run.profile.collection if run.state.practice else run.state.trophies
		var list := BattleSummary.alternatives(data, rows[i].id, owned, run.state.equipped, names)
		if not list.is_empty():
			out[i] = list
	return out


func _on_combo(e: Dictionary) -> void:
	var c: Dictionary = e.calc.combo
	_float(e.target, "KOMBINATION!", UiStyle.GOLD, 22, true)
	sfx.play("ui_page", -8.0, 0.0)
	if not _help_ok:
		return
	var applier := sim.unit(c.applier) if c.applier != "" else null
	var who: String = applier.name if applier != null and c.applier != e.source else "Någon"
	var aura := sim.status_name(sim.unit(e.target), c.aura)
	var without := int(roundf(float(e.amount) / float(c.mult)))
	HelpBox.offer_custom(self, "combo", {"title": "Kombination!", "text": [
		"%s gjorde %s %s." % [who, sim.unit(e.target).name, aura],
		"%s slår %d %% hårdare mot en %s fiende: %d blev %d." % [data.abilities[c.ability].name,
				roundi((float(c.mult) - 1.0) * 100.0), aura, without, int(e.amount)],
		"Så fungerar hela spelet: förmågor, egenskaper och troféer som sätter igång varandra. Leta efter ord som går igen."]}, true)


func _on_heal(e: Dictionary) -> void:
	if e.effective <= 0.0 and e.amount < 1.0:
		return
	var p := _pos(e.target)
	_float(e.target, "+" + str(int(e.effective)) + ("!" if e.crit else ""), UiStyle.school_color("heal"), 26 if e.crit else 22, e.crit)
	_remember_number(e)
	if sim.unit(e.target).team == 0:
		frames[e.target].on_heal()
	sfx.play("heal_light", -6.0, 0.03)
	models[e.target].flash_color(UiStyle.school_color("heal"))
	fx_layer.add_child(_at(Fx.Ring.new(UiStyle.school_color("heal"), 10, 70, 0.45, 5.0, true), p))


func _on_aura(e: Dictionary) -> void:
	var d: Dictionary = data.auras[e.aura]
	if e.aura == "defend":
		models[e.unit].set_blocking(true)
		return
	var col := UiStyle.TRAIT_GOLD if sim.unit(e.unit).team == 0 else Color("#ffb347")
	_float(e.unit, d.name.to_upper(), col, 18, false)
	fx_layer.add_child(_at(Fx.Ring.new(col, 12, 60, 0.35, 4.0), _pos(e.unit)))


## En egenskap slog till: namnet lyser upp över hjälten och i ramen.
func _on_trait(e: Dictionary) -> void:
	var t: Dictionary = data.traits[e.trait]
	if frames.has(e.unit):
		frames[e.unit].on_trait()
	if t.get("quiet", false):
		return
	_float(e.unit, t.name.to_upper(), UiStyle.TRAIT_GOLD, 22, true)
	sfx.play("k_ready", -5.0, 0.1)
	fx_layer.add_child(_at(Fx.Ring.new(UiStyle.TRAIT_GOLD, 12, 70, 0.4, 5.0), _pos(e.unit)))


func _on_release(e: Dictionary) -> void:
	var t: Dictionary = data.traits[e.trait]
	var amount: String = ("+%d" % int(e.amount)) if e.amount > 10.0 else ("×%d" % int(e.amount))
	_float(e.unit, "%s %s" % [t.name.to_upper(), amount], UiStyle.TRAIT_GOLD, 26, true)
	if frames.has(e.unit):
		frames[e.unit].on_trait()
	sfx.play("k_ready", -1.0, 0.0)
	fx_layer.add_child(_at(Fx.Ring.new(UiStyle.TRAIT_GOLD, 16, 120, 0.5, 8.0, true), _pos(e.unit)))


func _on_death(unit_id: String) -> void:
	sfx.play("death", -3.0)
	models[unit_id].die()
	_hitstop(50)


func _on_revive(unit_id: String) -> void:
	models[unit_id].revive()
	sfx.play("renew", -2.0, 0.0)
	_float(unit_id, "VÄCKT!", Color("#c9b8ff"), 24, true)
	fx_layer.add_child(_at(Fx.Ring.new(Color("#c9b8ff"), 10, 110, 0.6, 6.0, true), _pos(unit_id)))


func _on_outcome(result: String) -> void:
	run.playtime.end_battle(result == "victory", sim.turn_no, sim.forfeited)  # speltiden: striden är slut
	action_bar.visible = false
	forfeit_chip.visible = false
	macro_chip.visible = false
	settings_chip.visible = false
	# 0.29.5: skadeloggen går att öppna på resultatskärmen (det är då man vill läsa den): knappen och loggen ovanpå rutan.
	log_chip.get_parent().move_child(log_chip, -1)
	damage_log.get_parent().move_child(damage_log, -1)
	var alive := sim.heroes.filter(func(h: CombatUnit) -> bool: return h.alive).size()
	if result == "victory":
		_slowmo_until = Time.get_ticks_msec() + 1200
		run.audio.stop_music(0.8)
		sfx.play("jingle_victory", -1.0, 0.0)
		world.add_shake(10.0)
		var last: bool = run.state.is_last_floor() and run.state.current_room().get("kind", "end") == "end"
		var title := ("%s RENSAD!" % run.data.realms[run.state.realm].short.to_upper()) if last else "SEGER!"
		if run.state.practice:
			title = "ÖVNINGEN VUNNEN"
		overlay.set_result("victory", "%d turer   ·   %d av %d står kvar" % [sim.turn_no, alive, sim.heroes.size()], title)
		# 0.30: det som avgjorde striden står till vänster, med vilken del av bygget det kom ifrån.
		overlay.deciders = BattleSummary.deciders(sim)
		overlay.alternatives = _decider_alternatives(overlay.deciders)
		if run.state.practice:
			overlay.alt_hint = "Byt troféer i Övningsgården."
		if "--alt-open" in OS.get_cmdline_user_args() and not overlay.alternatives.is_empty():
			overlay.alt_open = overlay.alternatives.keys()[0]  # skärmdumpar av listan
		# 0.19: erfarenhet och nivåuppgångar syns och hörs på segerskärmen.
		overlay.level_ups = run.award_battle(sim, true)
		if not overlay.level_ups.is_empty():
			get_tree().create_timer(1.3).timeout.connect(sfx.play.bind("trophy_elite", -3.0, 0.0))
		# 0.20: fynden syns till höger med eget ljud; ett sällsynt fynd får en egen liten scen.
		overlay.data = data
		overlay.finds = run.last_finds
		run.play_find_sound(run.last_finds, 1.7)
		run.show_rare_finds(run.last_finds, 2.6)
	else:
		run.award_battle(sim, false)
		run.audio.stop_music(1.5)
		sfx.play("jingle_defeat", -1.0, 0.0)
		if sim.forfeited:
			overlay.set_result("defeat", "Körningen är förlorad – Realmen börjar om från våning 1"
					if not run.state.practice else "Övningen avslutad", "NI GAV UPP")
		else:
			overlay.set_result("defeat", "Sällskapet föll efter %d turer" % sim.turn_no)


# --- Hjälpfunktioner --------------------------------------------------------

func _pos(unit_id: String) -> Vector2:
	return world.project(models[unit_id].chest_position())


func _at(node: Node2D, p: Vector2) -> Node2D:
	node.position = p
	return node


func _float(unit_id: String, text: String, color: Color, size: int, big: bool) -> void:
	var p := world.project(models[unit_id].head_position()) + Vector2(randf_range(-14, 14), -46)
	fx_layer.add_child(_at(Fx.FloatingText.new(text, color, size, big, 1.1 if big else 0.9), p))


func _after(delay: float, call: Callable) -> void:
	if delay <= 0.0:
		call.call()
	else:
		_later.append({"left": delay, "call": call})


func _tick_later(delta: float) -> void:
	for item in _later.duplicate():
		item.left -= delta
		if item.left <= 0.0:
			_later.erase(item)
			item.call.call()


func _hitstop(ms: int) -> void:
	_hitstop_until = maxi(_hitstop_until, Time.get_ticks_msec() + ms)


static func _dist_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.001), 0.0, 1.0)
	return p.distance_to(a + ab * t)


## Ringar på golvet: guld under den som har turen, och markeringar under möjliga mål.
class Markers extends Node2D:
	var battle: Node
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var sim: CombatSim = battle.sim
		if sim.current and battle.started and sim.outcome == "":
			_ring(sim.current.id, Color(UiStyle.GOLD, 0.8 + 0.2 * sin(_t * 6.0)), 46.0, 4.0)
		for id in battle._targets:
			var is_default: bool = id == battle._default_target
			var c := Color("#ff5a4a") if sim.unit(id).team == 1 else UiStyle.school_color("heal")
			_ring(id, Color(c, 0.55 + 0.45 * sin(_t * 9.0)), 40.0 + (6.0 if is_default else 0.0), 5.0 if is_default else 3.0)

	func _ring(unit_id: String, color: Color, radius: float, width: float) -> void:
		var m: UnitModel = battle.models[unit_id]
		var feet: Vector2 = battle.world.project(m.global_position)
		draw_set_transform(feet, 0, Vector2(1, 0.42))
		draw_arc(Vector2.ZERO, radius, 0, TAU, 48, color, width, true)
		draw_set_transform(Vector2.ZERO)
